local Perks = require("game.perks")
local data = require("data.perks")

local function seeded(seed)
    return function()
        seed = (seed * 48271) % 2147483647
        return (seed - 1) / 2147483646
    end
end

local function allUnlocked()
    local result = {}
    for _, card in ipairs(data.cards) do
        result[card.id] = true
    end
    return result
end

local function selectCard(state, source, id, tick)
    local hand = source and Perks.offer(state, "chest", source) or Perks.offer(state, "opening")
    assert(hand and Perks.choose(state, hand.token, id, tick), "fixture card should be available")
end

local function nearly(a, b)
    return math.abs(a - b) < 1e-9
end

do
    local state = Perks.new(function() error("no random roll is required for an empty deck") end)
    local stats = { damage = 1 }
    assert(not Perks.offer(state, "opening") and not Perks.offer(state, "chest", 1))
    assert(Perks.stats(state, stats, 0) == stats, "empty or locked state leaves base modifiers unchanged")
    assert(not Perks.handle(state, { kind = "pickup", tick = 1, item = "coin" }))
end

do
    local opts = { unlocked = allUnlocked(), choice_count = 2, max_owned = 2 }
    local state, replay = Perks.new(seeded(51), opts), Perks.new(seeded(51), opts)
    opts.choice_count = 1
    opts.max_owned = 0
    for id in pairs(opts.unlocked) do opts.unlocked[id] = nil end

    local first, second = Perks.offer(state, "opening"), Perks.offer(replay, "opening")
    assert(#first.options == 2 and #second.options == 2, "run snapshots deck configuration")
    assert(first.options[1].id == second.options[1].id and first.options[2].id == second.options[2].id)
    assert(first.options[1].id ~= first.options[2].id, "seeded choices are drawn without replacement")
    assert(Perks.offer(state, "opening") == first and not Perks.offer(state, "chest", 1), "pending choice is exclusive")
    local picked = first.options[1].id
    local omitted
    for _, card in ipairs(data.cards) do
        if card.id ~= picked and card.id ~= first.options[2].id then omitted = card.id end
    end
    assert(not Perks.choose(state, first.token, omitted, 0), "the selected card must have been offered")
    assert(not Perks.choose(state, first.token + 1, picked, 0), "an unrelated token has no effect")
    assert(Perks.choose(state, first.token, picked, 0) and state.unlocked[picked], "selection leaves unlock configuration unchanged")
    assert(not Perks.choose(state, first.token, picked, 0) and not Perks.offer(state, "opening"))

    local skipped = assert(Perks.offer(state, "chest", 1))
    assert(Perks.offer(state, "chest", 1.0) == skipped, "integer and float IDs identify the same chest")
    assert(not Perks.skip(state, skipped.token + 1) and Perks.skip(state, skipped.token))
    assert(not Perks.skip(state, skipped.token) and not Perks.offer(state, "chest", 1.0), "skipped source cannot be reused")
    local chest = assert(Perks.offer(state, "chest", 2))
    for _, option in ipairs(chest.options) do
        assert(option.id ~= picked, "already-selected card cannot be offered again")
    end
    assert(Perks.choose(state, chest.token, chest.options[1].id, 12))
    assert(#state.owned == 2 and not Perks.offer(state, "chest", 3), "owned limit caps the run")
    assert(Perks.offer(replay, "opening") == second, "another run retains its own pending hand")
end

do
    local state = Perks.new(seeded(11), { unlocked = allUnlocked(), choice_count = #data.cards })
    -- Pick the multiplier first to check operation order independently of selection order.
    selectCard(state, nil, "cinder_refrain", 5)
    selectCard(state, 1, "tidal_dial", 5)
    selectCard(state, 2, "reed_stride", 5)
    local base = { damage = 1.4, crit_chance = 0.1, cooldown = 0.8, area = 1.2, projectile_speed = 1, duration = 1 }
    local output = { stale = 77 }
    assert(Perks.stats(state, base, 4, true).damage == base.damage, "cards have no effect before selection")
    local moving = Perks.stats(state, base, 5, true, output)
    assert(moving == output and not moving.stale)
    assert(nearly(moving.damage, 1.52) and nearly(moving.area, 1.36) and nearly(moving.projectile_speed, 1.14))
    assert(nearly(moving.crit_chance, 0.16) and nearly(moving.cooldown, 0.704))
    local stationary = Perks.stats(state, base, 5, false)
    assert(stationary.crit_chance == base.crit_chance and stationary.cooldown == base.cooldown)
    assert(base.damage == 1.4 and base.area == 1.2, "building effective stats never mutates the passive snapshot")
    assert(nearly(Perks.stats(state, base, 124, false).duration, 1.1))
    assert(Perks.stats(state, base, 125, false).duration == 1, "cycle off window starts at the boundary")
    assert(nearly(Perks.stats(state, base, 365, false).duration, 1.1), "cycle restarts relative to selection tick")

    Perks.handle(state, { kind = "kill", tick = 9, origin = "perk" })
    assert(nearly(Perks.stats(state, base, 9, false).damage, 1.52), "derived kills do not reenter card triggers")
    Perks.handle(state, { kind = "kill", tick = 10, origin = "weapon" })
    assert(nearly(Perks.stats(state, base, 10, false).damage, 1.52 * 1.2), "additive bonuses apply before multipliers")
    Perks.handle(state, { kind = "kill", tick = 40, origin = "weapon" })
    assert(nearly(Perks.stats(state, base, 45, false).damage, 1.52 * 1.2))
    assert(nearly(Perks.stats(state, base, 46, false).damage, 1.52), "kill buff expires at the exact tick and cannot refresh during cooldown")
    Perks.handle(state, { kind = "kill", tick = 106, origin = "weapon" })
    assert(nearly(Perks.stats(state, base, 106, false).damage, 1.52 * 1.2), "next kill at the cooldown boundary grants a new window")
end

do
    local opts = { unlocked = { golden_balm = true, spring_mark = true } }
    local state = Perks.new(seeded(25), opts)
    selectCard(state, nil, "golden_balm", 7)
    selectCard(state, 3, "spring_mark", 7)
    assert(not Perks.handle(state, { kind = "pickup", tick = 6, item = "coin" }), "old pickup predates selection")
    assert(not Perks.handle(state, { kind = "pickup", tick = 8, item = "healing" }))
    local heal = assert(Perks.handle(state, { kind = "pickup", tick = 8, item = "coin" }))[1]
    assert(heal.kind == "heal" and heal.origin == "perk" and heal.perk_id == "golden_balm" and heal.amount == 5)
    heal.amount = 0
    assert(not Perks.handle(state, { kind = "pickup", tick = 8, item = "coin" }), "same-tick pickups respect cooldown")
    assert(not Perks.handle(state, { kind = "pickup", tick = 98, item = "coin", origin = "perk" }))
    local renewed = assert(Perks.handle(state, { kind = "pickup", tick = 98, item = "coin" }))[1]
    assert(renewed.amount == 5, "output actions are independent from the card definition")

    local revive = assert(Perks.handle(state, { kind = "lethal", tick = 110 }))[1]
    assert(revive.kind == "revive" and revive.origin == "perk" and revive.health_fraction > 0)
    assert(not Perks.handle(state, { kind = "lethal", tick = 111 }), "revive is used once per run")
    local restarted = Perks.new(seeded(25), opts)
    selectCard(restarted, nil, "spring_mark", 0)
    assert(Perks.handle(restarted, { kind = "lethal", tick = 1 }), "new run resets its one-shot effect")
end

print("Lua perk eligibility, source consumption, modifier order and windows, and non-recursive triggers passed")
