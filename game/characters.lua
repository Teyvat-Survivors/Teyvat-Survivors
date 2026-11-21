local roster = require("data.characters")
local Characters = {}

local byId = {}
for _, definition in ipairs(roster) do
    byId[definition.id] = definition
end

local function available(definition, unlocked)
    return not definition.unlock or (unlocked and unlocked[definition.unlock] == true)
end

function Characters.select(id, unlocked)
    local definition = byId[id]
    if not definition then
        return nil, "unknown_character"
    end
    if not available(definition, unlocked) then
        return nil, "locked_character"
    end
    return definition
end

function Characters.list(unlocked)
    local options = {}
    for _, definition in ipairs(roster) do
        if available(definition, unlocked) then
            options[#options + 1] = { id = definition.id, label = definition.label }
        end
    end
    return options
end

function Characters.loadout(definition, randomUnit)
    if definition.random_starters then
        local choices = definition.random_starters
        local draw = randomUnit()
        assert(type(draw) == "number" and draw >= 0 and draw < 1, "random starter needs a draw in [0, 1)")
        local starters = {}
        for i, id in ipairs(definition.starters or {}) do
            starters[i] = id
        end
        starters[#starters + 1] = choices[math.floor(draw * #choices) + 1]
        return starters
    end
    return definition.starters
end

local function addStats(target, changes, steps)
    for name, value in pairs(changes or {}) do
        target[name] = (target[name] or 0) + value * steps
    end
end

function Characters.bonuses(definition, level)
    local bonuses = {}
    addStats(bonuses, definition.bonuses, 1)
    for _, growth in ipairs(definition.growth or {}) do
        if level >= growth.at then
            local steps = growth.every and 1 + math.floor((level - growth.at) / growth.every) or 1
            addStats(bonuses, growth.bonuses, math.min(steps, growth.steps or 1))
        end
    end
    return bonuses
end

function Characters.combatModifiers(definition, run, moving, output)
    local base, combat = run.base_weapon_modifiers, definition.combat
    if not combat or (combat.at and run.progress.level < combat.at) then
        return base
    end

    local active = (combat.when == "moving" and moving)
        or (combat.when == "still" and not moving)
        or (combat.when == "wounded" and run.player.health <= run.player.max_health * combat.threshold)
        or (combat.when == "lean" and #run.weapon_systems <= combat.threshold)
    if not active then
        return base
    end

    for name, value in pairs(base) do
        output[name] = value
    end
    for name, bonus in pairs(combat.bonuses) do
        output[name] = output[name] + bonus
    end
    return output
end

return Characters
