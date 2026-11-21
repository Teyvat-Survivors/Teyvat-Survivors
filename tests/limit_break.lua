local Data = require("data.progress")
local Evolutions = require("game.evolutions")
local Progress = require("game.progress")
local Run = require("game.run")
local Weapons = require("game.weapons")
local WeaponData = require("data.weapons")

local fixedStep = Run.step_seconds
local limit = Data.limit_break

local function stage(weaponSlots)
    return {
        id = "limit_break_test",
        duration_ticks = 5000,
        terminal_timeout_ticks = 10,
        terminal_kind = "target",
        evolution = { earliest_tick = 1, chest_types = { elite = true } },
        build_rules = { weapon_slots = weaponSlots or 1, passive_slots = 0, choice_count = 1 },
        waves = {
            capacity = 4, spawnDistance = 4, despawnDistance = 30, contactIntervalTicks = 5,
            spawns = { { tick = 1, kind = "target", count = 1 } },
            types = { target = { radius = 0.7, speed = 0, health = 100000, contactDamage = 0 } },
        },
    }
end

local function grantExperience(run, amount)
    assert(Progress.drop(run.progress, {
        id = 10000 + run.tick, x = run.player.x, y = run.player.y, xp = amount or run.progress.xpNeeded,
    }))
    assert(Run.update(run, fixedStep) == 1)
    return run.progress.choices
end

local function chooseCurrent(run, expected)
    local choice = assert(run.progress.choices)
    assert(choice.options[1].key == expected)
    assert(Run.choose(run, choice.token, expected))
    return choice
end

do
    local ordinary = Run.new(7, stage())
    local growth = Run.new(7, stage(), nil, nil, { limit_break = true })
    assert(not ordinary.mode.limit_break and not ordinary.build.limit_ranks and growth.mode.limit_break)
    assert(not pcall(Run.new, 7, stage(), nil, nil, { limit_break = "enabled" }))

    for _, run in ipairs({ ordinary, growth }) do
        for rank = 2, Weapons.max_level(run.weapons) do
            grantExperience(run)
            chooseCurrent(run, "weapon:wind_blade")
            assert(run.weapons.level == rank, "ordinary ranks take priority")
        end
        grantExperience(run)
    end
    assert(ordinary.progress.choices.options[1].kind == "reward", "normal mode retains its fallback")

    local choice = assert(growth.progress.choices)
    assert(choice.options[1].key == "limit:wind_blade" and choice.options[1].level == 1)
    local rank = growth.weapons.level
    assert(Run.update(growth, fixedStep * 2) == 0, "a limit choice uses the existing level-up pause")
    assert(not Run.choose(growth, choice.token + 1, "limit:wind_blade"), "a stale token cannot boost")
    assert(Run.choose(growth, choice.token, "limit:wind_blade") and growth.build.limit_ranks.wind_blade == 1)
    assert(not Run.choose(growth, choice.token, "limit:wind_blade") and growth.weapons.level == rank)

    local scheduled = growth.weapons.next_fire_tick
    while growth.tick < scheduled do
        Run.update(growth, fixedStep)
    end
    local raw = WeaponData.wind_blade.levels[rank].cooldown_ticks
    assert(growth.weapons.next_fire_tick == scheduled + math.ceil(raw * 0.95),
        "ordinary simulation schedules the next actual shot sooner after a boost")

    for boost = 2, limit.max_weapon_rank do
        grantExperience(growth)
        chooseCurrent(growth, "limit:wind_blade")
        assert(growth.build.limit_ranks.wind_blade == boost)
    end
    grantExperience(growth)
    assert(growth.progress.choices.options[1].kind == "reward", "fully boosted weapons return to healing fallback")
    chooseCurrent(growth, "reward:heal")
    scheduled = growth.weapons.next_fire_tick
    while growth.tick < scheduled do
        Run.update(growth, fixedStep)
    end
    assert(growth.weapons.next_fire_tick == scheduled + math.ceil(raw * 0.8),
        "four awarded ranks cap cadence benefit at twenty percent")

    local fresh = Run.restart(growth)
    assert(fresh.mode.limit_break and fresh.progress.level == 1 and not fresh.build.limit_ranks.wind_blade,
        "restart preserves the mode and resets accrued boosts")
end

do
    local standardTotal = 0
    for _, needed in ipairs(Data.experience_to_next) do
        standardTotal = standardTotal + needed
    end
    local normalMax = #Data.experience_to_next + 1
    local ordinary = Run.new(13, stage())
    local growth = Run.new(13, stage(), nil, nil, { limit_break = true, endless = true })
    grantExperience(ordinary, standardTotal + 10000)
    grantExperience(growth, standardTotal + limit.first_threshold - 1)
    assert(ordinary.progress.level == normalMax and ordinary.progress.xp == 0 and not ordinary.progress.xpNeeded)
    assert(growth.progress.level == normalMax and growth.progress.xpNeeded == limit.first_threshold
        and growth.progress.xp == limit.first_threshold - 1, "limit mode keeps excess experience at the normal cap")
    while growth.progress.choices do
        local choice = growth.progress.choices
        assert(Run.choose(growth, choice.token, choice.options[1].key))
    end

    grantExperience(growth, 1)
    assert(growth.progress.level == normalMax + 1 and growth.progress.xpNeeded == limit.first_threshold + limit.threshold_step)
    local choice = growth.progress.choices
    assert(Run.choose(growth, choice.token, choice.options[1].key))
    grantExperience(growth, 1000000)
    assert(growth.progress.level == normalMax + limit.extra_levels and growth.progress.xp == 0
        and not growth.progress.xpNeeded, "the extended level curve has a bounded end even in endless mode")
    assert(not Progress.drop(growth.progress, { id = 1, x = 0, y = 0 }),
        "a capped run stops generating XP pickups")
end

do
    local function setup()
        local run = Run.new(17, stage(2), nil, nil, { limit_break = true })
        local frost = Weapons.new("frost_pulse")
        frost.level = Weapons.max_level(frost)
        run.weapons.level = Weapons.max_level(run.weapons)
        run.weapon_systems[2] = frost
        run.build.weapons.frost_pulse, run.build.weapons.wind_blade = frost.level, run.weapons.level
        return run
    end
    local first, replay = setup(), setup()
    local a, b = grantExperience(first), grantExperience(replay)
    local key = a.options[1].key
    assert(key == b.options[1].key and a.token == b.token, "eligible capped weapons are offered deterministically")
    assert(key == "limit:frost_pulse" or key == "limit:wind_blade")
    assert(not Run.banish(first, a.token, key), "a boost cannot be banished as an inventory item")
    assert(Run.reroll(first, a.token), "another owned capped weapon is eligible for reroll")
    local changed = first.progress.choices
    assert(changed.options[1].key ~= key and not Run.choose(first, a.token, key))
    assert(Run.choose(first, changed.token, changed.options[1].key))
    local selected, original = changed.options[1].id, a.options[1].id
    assert(first.build.limit_ranks[selected] == 1 and not first.build.limit_ranks[original],
        "a boost applies to its own weapon only")

    local stillGrowing = setup()
    stillGrowing.weapon_systems[2].level = stillGrowing.weapon_systems[2].level - 1
    stillGrowing.build.weapons.frost_pulse = stillGrowing.weapon_systems[2].level
    local regular = grantExperience(stillGrowing)
    assert(regular.options[1].key == "weapon:frost_pulse", "a remaining ordinary rank blocks all over-cap choices")
end

do
    local run = Run.new(23, stage(), nil, nil, { limit_break = true })
    run.build.passives.gust_seal = require("data.passives").items.gust_seal.max_level
    run.weapons.level = Weapons.max_level(run.weapons)
    run.build.weapons.wind_blade = run.weapons.level
    run.build.limit_ranks.wind_blade = limit.max_weapon_rank
    local chest = { chest_type = "elite", dropped_tick = 1 }
    assert(Evolutions.apply(run, chest, "gale_script"))
    assert(not run.build.limit_ranks.wind_blade and not run.build.limit_ranks.gale_script,
        "a consumed ingredient's boost never transfers to the result")
end

print("Lua limit break gating, deterministic options, actual cooldown, caps, evolution and restart passed")
