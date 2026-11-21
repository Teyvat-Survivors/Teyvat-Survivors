local data = require("data.perks")
local Perks = {}
local cardsById = {}

for _, card in ipairs(data.cards) do
    cardsById[card.id] = card
end

local function validTick(tick)
    return type(tick) == "number" and tick >= 0 and tick < math.huge and tick % 1 == 0
end

function Perks.new(randomUnit, options)
    assert(type(randomUnit) == "function", "perks require a random source")
    options = options or {}
    local maxOwned = options.max_owned or data.max_owned
    local choiceCount = options.choice_count or data.choice_count
    local rerollLimit = options.rerolls or data.rerolls
    assert(validTick(maxOwned) and validTick(choiceCount) and choiceCount > 0 and validTick(rerollLimit),
        "invalid perk limits")
    local unlocked = {}
    for _, card in ipairs(data.cards) do
        if options.unlocked and options.unlocked[card.id] == true then
            unlocked[card.id] = true
        end
    end
    return {
        randomUnit = randomUnit, unlocked = unlocked, maxOwned = maxOwned, choiceCount = choiceCount,
        owned = {}, spentSources = {}, token = 0, rerolls = rerollLimit, rerollLimit = rerollLimit,
    }
end

local function sourceKey(kind, id)
    if kind == "opening" then
        return "opening"
    end
    assert(kind == "chest" and validTick(id) and id > 0, "perk chest requires a positive source ID")
    return id
end

local function owns(state, cardId)
    for _, entry in ipairs(state.owned) do
        if entry.id == cardId then
            return true
        end
    end
    return false
end

local function eligiblePool(state)
    local pool = {}
    for _, card in ipairs(data.cards) do
        if state.unlocked[card.id] and not owns(state, card.id) then
            pool[#pool + 1] = card
        end
    end
    return pool
end

local function draw(state, pool, options)
    while #options < state.choiceCount and #pool > 0 do
        local unit = state.randomUnit()
        assert(type(unit) == "number" and unit >= 0 and unit < 1, "invalid perk random roll")
        local card = table.remove(pool, math.floor(unit * #pool) + 1)
        options[#options + 1] = { id = card.id, label = card.label }
    end
end

local function publish(state, key, options)
    state.token = state.token + 1
    state.choice = { token = state.token, source = key, options = options }
    return state.choice
end

function Perks.offer(state, kind, id)
    local key = sourceKey(kind, id)
    if state.choice then
        return state.choice.source == key and state.choice or nil
    end
    if state.spentSources[key] or #state.owned >= state.maxOwned then
        return nil
    end
    local options = {}
    draw(state, eligiblePool(state), options)
    if #options == 0 then
        return nil
    end
    state.spentSources[key] = true
    return publish(state, key, options)
end

function Perks.reroll(state, token)
    local choice = state.choice
    if not choice or choice.token ~= token or state.rerolls == 0 then
        return nil
    end
    local seen, fresh, repeats = {}, {}, {}
    for _, option in ipairs(choice.options) do
        seen[option.id] = true
    end
    for _, card in ipairs(eligiblePool(state)) do
        local pool = seen[card.id] and repeats or fresh
        pool[#pool + 1] = card
    end
    if #fresh == 0 then
        return nil
    end
    local options = {}
    draw(state, fresh, options)
    draw(state, repeats, options)
    state.rerolls = state.rerolls - 1
    return publish(state, choice.source, options)
end

function Perks.choose(state, token, cardId, tick)
    assert(validTick(tick), "invalid perk selection tick")
    local choice = state.choice
    if not choice or choice.token ~= token or not state.unlocked[cardId] or owns(state, cardId) then
        return false
    end
    for _, option in ipairs(choice.options) do
        if option.id == cardId then
            local trigger = cardsById[cardId].trigger
            state.owned[#state.owned + 1] = {
                id = cardId, selectedTick = tick, readyTick = tick + (trigger and trigger.delay_ticks or 0),
            }
            state.choice = nil
            return true
        end
    end
    return false
end

function Perks.skip(state, token)
    if not state.choice or state.choice.token ~= token then
        return false
    end
    state.choice = nil
    return true
end

local neutral = { crit_chance = 0, armor = 0, echo_shots = 0, pierce = 0, bounces = 0 }
local function offCycle(card, entry, tick)
    return card.cycle and tick >= entry.selectedTick and
        (tick - entry.selectedTick) % card.cycle.period_ticks >= card.cycle.active_ticks
end

local function active(entry, card, tick, moving)
    if tick < entry.selectedTick or (card.movement_only and not moving) then
        return false
    end
    if (card.window_ticks and tick - entry.selectedTick >= card.window_ticks) or offCycle(card, entry, tick) then
        return false
    end
    if card.trigger and card.trigger.duration_ticks then
        return entry.activeFrom and tick >= entry.activeFrom and tick < entry.activeUntil
    end
    return true
end

local function addStats(output, additions, factor)
    for key, value in pairs(additions) do
        output[key] = (output[key] or neutral[key] or 1) + value * factor
    end
end

-- Apply card bonuses to a fresh copy of the current build. Additions precede multipliers.
function Perks.stats(state, base, tick, moving, output, context)
    assert(validTick(tick), "invalid perk stat tick")
    if #state.owned == 0 then
        return base
    end
    output = output or {}
    assert(output ~= base, "perk output must not alias build stats")
    for key in pairs(output) do
        output[key] = nil
    end
    for key, value in pairs(base) do
        output[key] = value
    end
    for _, entry in ipairs(state.owned) do
        local card = cardsById[entry.id]
        if active(entry, card, tick, moving) then
            if card.add then addStats(output, card.add, 1) end
            local growth = card.growth
            if growth and context then
                local factor = math.max(0, math.min(growth.cap, context[growth.basis] or 0))
                addStats(output, growth.add, factor)
            end
        end
    end
    for _, entry in ipairs(state.owned) do
        local card = cardsById[entry.id]
        local modifiers = active(entry, card, tick, moving) and card.multiply
            or (offCycle(card, entry, tick) and card.off_multiply)
        if modifiers then
            for key, value in pairs(modifiers) do
                output[key] = (output[key] or neutral[key] or 1) * value
            end
        end
    end
    return output
end

-- Effects send actions back to the caller, without dispatching nested events.
function Perks.handle(state, event)
    if event.origin == "perk" then
        return nil
    end
    assert(validTick(event.tick), "invalid perk event tick")
    local actions
    for _, entry in ipairs(state.owned) do
        local trigger = cardsById[entry.id].trigger
        if trigger and trigger.kind == event.kind and (not trigger.item or trigger.item == event.item)
            and (not trigger.requires_slow or event.slowed) and not entry.consumed and event.tick >= entry.readyTick then
            entry.consumed = trigger.once
            entry.readyTick = event.tick + (trigger.cooldown_ticks or 0)
            if trigger.duration_ticks then
                entry.activeFrom, entry.activeUntil = event.tick, event.tick + trigger.duration_ticks
            end
            if trigger.action then
                local action = { perk_id = entry.id, origin = "perk", tick = event.tick }
                for key, value in pairs(trigger.action) do
                    action[key] = value
                end
                if action.amount_scale then
                    action.amount = action.amount + (event.amount or 0) * action.amount_scale
                end
                if action.center == "event" then
                    action.x, action.y = event.x, event.y
                end
                actions = actions or {}
                actions[#actions + 1] = action
            end
        end
    end
    return actions
end

return Perks
