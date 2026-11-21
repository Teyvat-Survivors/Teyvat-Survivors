local Data = require("data.loot")
local Loot = require("game.loot")
local Progress = require("game.progress")
local Weapons = require("game.weapons")

local function enemy(id, kind, x, y)
    return { id = id, kind = kind or "drift", x = x or 0, y = y or 0, health = 0 }
end

local function chooseRoll(value)
    return function() return value end
end

local function newRun(roll)
    local random = chooseRoll(roll)
    return {
        player = { x = 0, y = 0, radius = 0.5, health = 40, max_health = 100 },
        loot = Loot.new(random),
        progress = Progress.new(random),
        weapons = Weapons.new(),
    }
end

do
    local cases = {
        { roll = 0, kind = "none" },
        { roll = 0.49999, kind = "none" },
        { roll = 0.50, kind = "coin" },
        { roll = 0.80999, kind = "coin" },
        { roll = 0.81, kind = "healing" },
        { roll = 0.94999, kind = "healing" },
        { roll = 0.95, kind = "magnet" },
        { roll = 0.99999, kind = "magnet" },
    }
    for _, case in ipairs(cases) do
        local attempts = 0
        local system = Loot.new(function()
            attempts = attempts + 1
            return case.roll
        end)
        local defeated = enemy(1)
        local item = Loot.defeat(system, defeated)
        assert((item and item.kind or "none") == case.kind, "weighted drops select the exact boundary category")
        assert(not Loot.defeat(system, defeated) and attempts == 1, "every defeat rolls and drops at most once")
        defeated.id = 2
        Loot.defeat(system, defeated)
        assert(attempts == 2, "a recycled enemy table with a fresh ID is eligible again")
    end
end

do
    local run = newRun(0.6)
    local edge = run.player.radius + Data.pickup_radius
    local source = enemy(1, "drift", edge + 0.0001)
    local item = Loot.defeat(run.loot, source)
    source.x, source.id = 0, 2
    assert(item.x == edge + 0.0001 and item.enemyId == 1, "pooled source changes never move or reassign a drop")
    Loot.step(run.loot, run)
    assert(run.loot.coins == 0 and #run.loot.pickups == 1, "coins outside collection range remain")
    run.player.x = 0.0002
    Loot.step(run.loot, run)
    Loot.step(run.loot, run)
    assert(run.loot.coins == Data.coin_value and #run.loot.pickups == 0, "coin pickup awards the configured amount once")

    local exact = enemy(3, "drift", edge)
    run.player.x = 0
    Loot.defeat(run.loot, exact)
    Loot.step(run.loot, run)
    assert(run.loot.coins == 2 * Data.coin_value, "the collection boundary is included")
end

do
    local run = newRun(0.85)
    run.player.healing_multiplier = 1.5
    Loot.defeat(run.loot, enemy(1))
    Loot.step(run.loot, run)
    assert(run.player.health == 40 + Data.healing_value * 1.5, "recovery multiplier changes healing pickup potency")
    run.player.health = run.player.max_health - 1
    Loot.defeat(run.loot, enemy(2))
    Loot.step(run.loot, run)
    assert(run.player.health == run.player.max_health, "healing is bounded by maximum health")
    Loot.defeat(run.loot, enemy(3))
    run.player.health = 0
    Loot.step(run.loot, run)
    assert(run.player.health == 0 and #run.loot.pickups == 1, "pickup cannot revive a defeated player")
end

do
    local run = newRun(0.98)
    local gem = Progress.drop(run.progress, enemy(1, "drift", 12))
    assert(not gem.attracted)
    Loot.defeat(run.loot, enemy(2))
    Loot.step(run.loot, run)
    assert(gem.attracted and #run.loot.pickups == 0, "magnet consumable activates an existing distant gem")
end

do
    local run = newRun(0)
    local liveElite = enemy(1, "sentinel")
    liveElite.health = 4
    assert(not Loot.defeat(run.loot, liveElite), "a living elite cannot award treasure")
    assert(not Loot.defeat(run.loot, enemy(2)), "ordinary enemies are not treasure sources")
    liveElite.health = 0
    assert(Loot.defeat(run.loot, liveElite).kind == "treasure" and not Loot.defeat(run.loot, liveElite),
        "an eligible elite grants exactly one treasure")
    Loot.defeat(run.loot, enemy(3, "sentinel"))
    assert(not Loot.hasChoice(run.loot), "treasure must be collected before opening")
    Loot.step(run.loot, run)
    local first = run.loot.choices
    assert(first and #first.options == 2 and #run.loot.pickups == 1, "one open treasure offers eligible upgrade and coin rewards")
    assert(not Loot.choose(run.loot, run, first.token + 1, "coins"), "stale treasure input has no effect")
    assert(not Loot.choose(run.loot, run, first.token, "invalid"), "invalid treasure option has no effect")
    assert(Loot.choose(run.loot, run, first.token, "upgrade") and run.weapons.level == 2, "upgrade reward applies to the owned weapon")
    Loot.step(run.loot, run)
    local second = run.loot.choices
    assert(second.token > first.token and not Loot.choose(run.loot, run, first.token, "coins"),
        "another treasure cannot be consumed by a repeated tap")
    assert(Loot.choose(run.loot, run, second.token, "coins") and run.loot.coins == Data.treasure_coin_value,
        "selecting coins awards exactly one payout")
    assert(not Loot.choose(run.loot, run, second.token, "coins") and run.loot.coins == Data.treasure_coin_value)
end

do
    local run = newRun(0)
    run.loot_upgrade_slots_full = true
    Loot.defeat(run.loot, enemy(1, "sentinel"))
    Loot.step(run.loot, run)
    local full = run.loot.choices
    assert(#full.options == 1 and full.options[1].id == "coins" and not Loot.choose(run.loot, run, full.token, "upgrade"),
        "full upgrade slots yield a currency fallback")
    assert(Loot.choose(run.loot, run, full.token, "coins"))
    run.loot_upgrade_slots_full = false
    run.weapons.level = Weapons.max_level(run.weapons)
    Loot.defeat(run.loot, enemy(2, "sentinel"))
    Loot.step(run.loot, run)
    local maxed = run.loot.choices
    assert(#maxed.options == 1 and maxed.options[1].id == "coins", "a max-level weapon also yields a currency fallback")
end

print("Lua weighted drops, pickup range, healing, magnet and treasure choices passed")

do
    local Run = require("game.run")
    local stage = {
        id = "loot-test",
        duration_ticks = 200,
        terminal_timeout_ticks = 30,
        terminal_kind = "hazard",
        waves = {
            capacity = 4, spawnDistance = 0, despawnDistance = 20, contactIntervalTicks = 1,
            types = {
                drift = { radius = 0.6, speed = 0, health = 1, contactDamage = 0 },
                sentinel = { radius = 0.9, speed = 0, health = 1, contactDamage = 0 },
                hazard = { radius = 0.8, speed = 0, health = 1000, contactDamage = 1000 },
            },
            spawns = {
                { tick = 1, kind = "drift", count = 1 },
                { tick = 60, kind = "sentinel", count = 1 },
                { tick = 90, kind = "hazard", count = 1 },
            },
        },
    }

    for _ = 1, 2 do
        local run = Run.new(5, stage)
        local step = Run.step_seconds
        run.player.health = 40
        run.player.healing_multiplier = 1.5
        assert(Run.update(run, step) == 1 and run.kills == 1,
            "normal run update auto-attacks and defeats the scheduled normal enemy")
        assert(run.player.health == 40 + Data.healing_value * 1.5 and #run.loot.pickups == 0,
            "seed 5's first real kill rolls and collects a healing consumable")
        for _ = 2, 60 do
            Run.update(run, step)
        end
        local choice = run.loot.choices
        assert(run.tick == 60 and run.kills == 2 and choice and #choice.options == 2,
            "scheduled elite defeat produces and opens an eligible treasure")
        assert(Run.update(run, step * 2) == 0 and run.tick == 60, "open treasure pauses simulation")
        assert(Run.choose_treasure(run, choice.token, "coins"), "the public entry resolves the chosen treasure reward")
        assert(run.loot.coins == Data.treasure_coin_value and not Run.choose_treasure(run, choice.token, "coins"),
            "repeated public selection cannot pay twice")
        while not run.result and run.tick < 90 do
            if run.progress.choices then
                assert(Run.choose(run, run.progress.choices.token, run.progress.choices.options[1].key))
            end
            Run.update(run, step)
        end
        assert(run.result and run.result.outcome == "defeated" and run.result.coins == Data.treasure_coin_value,
            "real combat death settles the single treasure payout")
        local fresh = Run.restart(run)
        assert(fresh.loot.coins == 0 and #fresh.loot.pickups == 0 and not Loot.hasChoice(fresh.loot),
            "restart clears loot and treasure state")
    end
    local upgrade = Run.new(5, stage)
    for _ = 1, 60 do Run.update(upgrade, Run.step_seconds) end
    local chest = assert(upgrade.loot.choices)
    assert(Run.choose_treasure(upgrade, chest.token, "upgrade") and upgrade.weapons.level == 2)
    assert(upgrade.build.weapons[upgrade.weapons.id] == 2, "treasure rank is reflected in the build inventory")
end

print("Seeded run from real weapon kills through healing, elite treasure choice and coin settlement passed")
