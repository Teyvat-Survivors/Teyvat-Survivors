local Build = require("game.build")
local Passives = require("data.passives")

local weapons = {
    wind_blade = { label = "风刃", levels = { {}, {}, {} }, weight = 10 },
    seed_dart = { levels = { {}, {} }, weight = 3 },
    moon_burst = { levels = { {} }, weight = 0 },
}

local function seeded(seed)
    return function()
        seed = (seed * 48271) % 2147483647
        return (seed - 1) / 2147483646
    end
end

local function keys(choice)
    local membership = {}
    local ordered = {}
    for i, option in ipairs(choice.options) do
        assert(not membership[option.key], "an upgrade menu cannot repeat a candidate")
        membership[option.key] = option
        ordered[i] = option.key
    end
    return membership, table.concat(ordered, ",")
end

local function selectOption(build, key)
    local offered = Build.offer(build)
    local result = Build.choose(build, offered.token, key)
    assert(result, "expected an eligible option " .. key)
    return result
end

local function near(actual, expected)
    return math.abs(actual - expected) < 1e-9
end

do
    local build = Build.new(seeded(3), weapons, "wind_blade", {
        weapon_slots = 1, passive_slots = 2, choice_count = 20,
    })
    local first = Build.offer(build)
    assert(Build.offer(build) == first, "reading an existing choice does not spend a new token")
    local options = keys(first)
    assert(options["weapon:wind_blade"].level == 2, "a full rack can upgrade its owned weapon")
    assert(not options["weapon:seed_dart"], "full rack refuses a new weapon")
    assert(not options["weapon:moon_burst"], "a zero-weight weapon is excluded")
    assert(not Build.choose(build, first.token, "weapon:moon_burst"))
    assert(Build.choose(build, first.token, "weapon:wind_blade").level == 2)

    local second = Build.offer(build)
    assert(second.token > first.token and not Build.choose(build, first.token, "weapon:wind_blade"))
    assert(Build.choose(build, second.token, "weapon:wind_blade").level == 3)
    assert(not keys(Build.offer(build))["weapon:wind_blade"], "a capped item leaves the pool")

    assert(selectOption(build, "passive:amber_cloak").level == 1)
    assert(selectOption(build, "passive:sprout_tea").level == 1)
    options = keys(Build.offer(build))
    assert(not options["passive:gust_seal"], "full passive slots refuse unowned items")
    assert(options["passive:sprout_tea"] and options["passive:amber_cloak"])
    assert(selectOption(build, "passive:amber_cloak").level == 2)

    local stats = Build.stats(build)
    assert(near(stats.max_health_bonus, 20) and stats.armor == 2 and near(stats.speed, 1.075),
        "owned passive levels stack over starting stats")
    assert(stats.damage == 1 and stats.pierce == 0, "unaffected stats retain neutral values")
end

do
    local build = Build.new(seeded(13), weapons, "wind_blade", {
        passive_slots = 0, weapon_slots = 2, choice_count = 3,
    })
    local choice = Build.offer(build)
    assert(keys(choice)["weapon:seed_dart"].level == 1, "an open slot can equip a new weapon")
    assert(not Build.reroll(build, choice.token) and build.remaining.reroll == Passives.rules.reroll,
        "reroll is free when all eligible choices are already shown")
    local equipped = Build.choose(build, choice.token, "weapon:seed_dart")
    assert(equipped.kind == "weapon" and equipped.id == "seed_dart" and equipped.level == 1)
    assert(build.weapons.wind_blade == 1 and build.weapons.seed_dart == 1,
        "acquisition preserves prior weapon levels")
    assert(keys(Build.offer(build))["weapon:seed_dart"].level == 2,
        "a weapon acquired in a previous choice can be strengthened")
end

do
    local rankOdds = {
        alpha = { levels = { {} }, weight = 1 },
        beta = { levels = { {} }, weight = 9 },
    }
    local function pick(fraction)
        local build = Build.new(function() return fraction end, rankOdds, nil, {
            passive_slots = 0, weapon_slots = 1, choice_count = 1,
        })
        return Build.offer(build).options[1].id
    end
    assert(pick(0) == "alpha" and pick(0.099) == "alpha" and pick(0.1) == "beta" and pick(0.999) == "beta",
        "weighted selection obeys cumulative intervals")
end

do
    local first, replay = Build.new(seeded(25), weapons, "wind_blade"), Build.new(seeded(25), weapons, "wind_blade")
    for _ = 1, 5 do
        local a, b = Build.offer(first), Build.offer(replay)
        local _, sequenceA = keys(a)
        local _, sequenceB = keys(b)
        assert(a.token == b.token and sequenceA == sequenceB, "the same seed and choices replay exactly")
        local key = a.options[1].key
        assert(Build.choose(first, a.token, key))
        assert(Build.choose(replay, b.token, key))
    end
end

do
    local build = Build.new(seeded(2), weapons, "wind_blade", { reroll = 1, skip = 1 })
    local old = Build.offer(build)
    local oldKeys = keys(old)
    assert(not Build.reroll(build, old.token + 1) and build.remaining.reroll == 1)
    local fresh = Build.reroll(build, old.token)
    assert(fresh and fresh.token > old.token and build.remaining.reroll == 0)
    local foundNew = false
    for _, option in ipairs(fresh.options) do
        foundNew = foundNew or not oldKeys[option.key]
    end
    assert(foundNew and not Build.reroll(build, fresh.token), "reroll replaces at least one option and spends a charge")
    assert(not Build.choose(build, old.token, old.options[1].key))
    assert(not Build.skip(build, old.token) and build.remaining.skip == 1)
    local skipped = Build.skip(build, fresh.token)
    assert(skipped.kind == "skip" and skipped.experience_fraction == Passives.rules.skip_experience_fraction)
    assert(not build.choices and build.remaining.skip == 0 and build.weapons.wind_blade == 1,
        "skip settles a choice without selecting an item")
    assert(not Build.skip(build, Build.offer(build).token), "skip charges are bounded")
end

do
    local build = Build.new(seeded(6), weapons, "wind_blade", { choice_count = 20, banish = 1 })
    local hand = Build.offer(build)
    assert(not Build.banish(build, hand.token, "weapon:unknown"))
    local action = Build.banish(build, hand.token, "weapon:wind_blade")
    assert(action.kind == "banish" and action.item_kind == "weapon" and action.id == "wind_blade")
    assert(build.weapons.wind_blade == 1 and not build.choices,
        "banishing consumes a choice while preserving an already acquired weapon")
    local nextHand = Build.offer(build)
    assert(not keys(nextHand)["weapon:wind_blade"] and not Build.banish(build, nextHand.token, "weapon:seed_dart"),
        "banished items leave future pools and the charge is consumed")
end

do
    local build = Build.new(seeded(35), {}, nil, { weapon_slots = 0, passive_slots = 0 })
    local choice = Build.offer(build)
    assert(#choice.options == 1 and choice.options[1].key == "reward:heal", "an empty pool offers a fallback")
    assert(not Build.reroll(build, choice.token) and build.remaining.reroll == Passives.rules.reroll)
    assert(not Build.banish(build, choice.token, "reward:heal") and build.remaining.banish == Passives.rules.banish)
    local reward = Build.choose(build, choice.token, "reward:heal")
    assert(reward.kind == "reward" and reward.id == "heal" and reward.amount == Passives.rules.fallback_heal)
    assert(not build.choices and not Build.choose(build, choice.token, "reward:heal"))
end

print("Lua passive levels, slot limits, weighted choices, and bounded upgrade actions passed")
