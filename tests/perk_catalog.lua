local Run = require("game.run")
local Perks = require("game.perks")
local Enemies = require("game.enemies")
local cards = require("data.perks").cards
local weapons = require("data.weapons")
local STEP = Run.step_seconds

local function near(actual, expected)
    assert(math.abs(actual - expected) < 1e-9, tostring(actual) .. " expected " .. tostring(expected))
end

local function arena(distance, count, contactDamage)
    return {
        id = "perk-catalog", duration_ticks = 1000, terminal_kind = "target", terminal_timeout_ticks = 5,
        waves = {
            capacity = 6, spawnDistance = distance, despawnDistance = 32, contactIntervalTicks = 30,
            types = { target = { health = 200, radius = 0.25, speed = 0, contactDamage = contactDamage or 0 } },
            spawns = count > 0 and { { tick = 1, kind = "target", count = count } } or {},
        },
    }
end

local function withCards(ids, stage, weapon)
    local run = Run.new(57, stage or arena(0, 0), weapon)
    local unlocked = {}
    for _, id in ipairs(ids) do unlocked[id] = true end
    assert(Run.enable_perks(run, { unlocked = unlocked }))
    for index, id in ipairs(ids) do
        local choice = index == 1 and run.perks.choice or Perks.offer(run.perks, "chest", index)
        assert(choice and Run.choose_perk(run, choice.token, id))
    end
    return run
end

local function advance(run, tick)
    while run.tick < tick do
        assert(Run.update(run, STEP) == 1, "fixture must advance normally to its scripted tick")
    end
end

local function gem(run, x, value)
    local pickup = { x = x, y = 0, value = value, attracted = false }
    run.progress.pickups[#run.progress.pickups + 1] = pickup
    return pickup
end

do
    local ids = {}
    for _, card in ipairs(cards) do
        assert(not ids[card.id], "perk IDs are unique")
        ids[card.id] = true
    end
    assert(#cards >= 22)
    local run = Run.new(76, arena(0, 0))
    local opts = { unlocked = ids, rerolls = 1 }
    assert(Run.enable_perks(run, opts))
    local first = run.perks.choice
    local sameSeed = Run.restart(run)
    assert(sameSeed.perks.choice.options[1].id == first.options[1].id)
    assert(Run.update(run, 0.25) == 0 and not Run.reroll_perk(run, first.token + 1))
    assert(Run.reroll_perk(run, first.token) and Run.reroll_perk(sameSeed, sameSeed.perks.choice.token))
    local nextHand = run.perks.choice
    assert(nextHand.source == first.source and nextHand.token > first.token and run.perks.rerolls == 0)
    for i, option in ipairs(nextHand.options) do
        assert(option.id == sameSeed.perks.choice.options[i].id, "reroll is deterministic")
        for _, old in ipairs(first.options) do
            assert(option.id ~= old.id, "a stocked deck produces new options")
        end
    end
    assert(not Run.choose_perk(run, first.token, first.options[1].id) and not Run.reroll_perk(run, nextHand.token))
    assert(Run.choose_perk(run, nextHand.token, nextHand.options[1].id))
    assert(Run.restart(run).perks.rerolls == 1)

    local exhausted = Run.new(76, arena(0, 0))
    assert(Run.enable_perks(exhausted, { unlocked = { iron_ledger = true } }))
    assert(not Run.reroll_perk(exhausted, exhausted.perks.choice.token) and exhausted.perks.rerolls == 1)

    local limited = Run.new(76, arena(0, 0))
    assert(Run.enable_perks(limited, {
        unlocked = { iron_ledger = true, gem_catalyst = true, long_tide = true }, choice_count = 2,
    }))
    local old = limited.perks.choice
    assert(Run.reroll_perk(limited, old.token))
    local new = limited.perks.choice
    assert(new.options[1].id ~= old.options[1].id and new.options[1].id ~= old.options[2].id)
    assert(new.options[1].id ~= new.options[2].id)
end

do
    local run = withCards({ "long_tide", "petal_dial", "vacant_star" })
    run.progress.level = 5
    advance(run, 1)
    near(run.weapon_modifiers.duration, 1.27)
    near(run.weapon_modifiers.range, 1.14)
    near(run.weapon_modifiers.area, 1.23)
    near(run.weapon_modifiers.damage, 1 + 0.09 * (run.build.rules.weapon_slots - 1))
    advance(run, 72)
    near(run.weapon_modifiers.area, 1)
    run.progress.level = 30
    advance(run, 270)
    near(run.weapon_modifiers.range, 1.21)
    near(run.weapon_modifiers.duration, 1.45)
    near(run.base_weapon_modifiers.duration, 1)

    local sowing = withCards({ "sowing_clock" })
    advance(sowing, 149)
    near(sowing.weapon_modifiers.experience, 1.17)
    advance(sowing, 150)
    near(sowing.weapon_modifiers.experience, 1)
    near(sowing.weapon_modifiers.damage, 1.12)
    near(sowing.weapon_modifiers.cooldown, 1.07)
end

do
    local run = withCards({ "gem_catalyst", "orbit_recall" }, arena(2, 1))
    run.weapons.next_fire_tick = 900
    gem(run, 0, 5)
    local edge = gem(run, 4.5, 5)
    advance(run, 1)
    assert(run.progress.xp == 0 and edge.attracted, "resonance converts gems to attacks and extends magnet reach")
    near(run.enemies.active[1].health, 200 - (2 + 5 * 0.68) - 6)

    local compass = withCards({ "wayfarer_compass" })
    local nearGem, farGem = gem(compass, 10, 1), gem(compass, 18, 1)
    advance(compass, 143)
    assert(not nearGem.attracted)
    advance(compass, 144)
    assert(nearGem.attracted and not farGem.attracted, "timed attraction respects its radius")
end

do
    local run = withCards({ "iron_ledger", "fountain_grace" }, arena(0, 1, 10))
    run.weapons.next_fire_tick = 900
    run.player.health = 50
    run.loot.pickups[1] = { kind = "healing", x = 0, y = 0 }
    advance(run, 1)
    assert(run.player.armor == 2)
    near(run.player.health, 50 - 8 + 12 * 1.3)
    near(run.enemies.active[1].health, 200 - (4 + 8 * 0.32) - (3 + 12 * 1.3 * 0.45))

    local derived = withCards({ "golden_balm", "fountain_grace" }, arena(2, 1))
    derived.weapons.next_fire_tick = 900
    derived.player.health = 50
    derived.loot.pickups[1] = { kind = "coin", x = 0, y = 0 }
    advance(derived, 1)
    near(derived.player.health, 50 + 5 * 1.3)
    assert(derived.enemies.active[1].health == 200, "perk-derived healing cannot trigger another card")
end

do
    local run = withCards({ "snowbell", "rime_wake" }, arena(2, 2))
    run.weapons.next_fire_tick = 900
    advance(run, 74)
    local dead, survivor = run.enemies.active[1], run.enemies.active[2]
    dead.x, dead.y, survivor.x, survivor.y = 1, 0, 2.8, 0
    assert(not dead.slowUntilTick)
    advance(run, 75)
    assert(dead.slowUntilTick > run.tick and dead.slowFactor == 0, "timed card uses the real stasis system")
    assert(Enemies.damage(dead, dead.health))
    run.on_defeat(dead)
    near(survivor.health, 191)
end

do
    local run = withCards({ "mirror_braid", "ashen_arrival", "cinder_refrain" }, arena(5, 1))
    advance(run, 1)
    local main, echo = table.unpack(run.weapons.projectiles)
    assert(main and echo and not main.origin and echo.origin == "perk")
    near(echo.damage, main.damage * 0.56)
    assert(main.hit_ids ~= echo.hit_ids)
    local victim = run.enemies.active[1]
    victim.x, victim.y, victim.health = main.x, main.y + 1.6, 7
    main.remaining_distance, echo.remaining_distance = 0, 0
    advance(run, 2)
    assert(run.kills == 1 and #run.enemies.active == 0, "normal expiry pulses once through the normal kill pipeline")
    advance(run, 3)
    near(run.weapon_modifiers.damage, 1)

    local opening = withCards({ "first_chord" }, arena(5, 1))
    advance(opening, 1)
    assert(#opening.weapons.projectiles == 2)
    advance(opening, 419)
    assert(opening.weapon_modifiers.echo_shots == 1)
    advance(opening, 420)
    assert(not opening.weapon_modifiers.echo_shots)
end

do
    local rebound = withCards({ "shell_turn" }, arena(5, 1), "echo_shard")
    advance(rebound, 1)
    local shard, shardStats = rebound.weapons.projectiles[1], weapons.echo_shard.levels[1]
    assert(shard.remaining_hits == shardStats.pierce + 2 and shard.remaining_bounces == shardStats.bounces + 1)
    local returning = withCards({ "pearl_trail" }, arena(5, 1), "willow_return")
    advance(returning, 1)
    local blade, bladeStats = returning.weapons.projectiles[1], weapons.willow_return.levels[1]
    near(blade.return_distance, bladeStats.range * bladeStats.return_ratio * 1.4)
    local critical = withCards({ "jade_refraction" }, arena(1, 1), "frost_pulse")
    critical.weapons.randomUnit = function() return 0 end
    advance(critical, 1)
    near(critical.enemies.active[1].health, 200 - weapons.frost_pulse.levels[1].damage * 1.5 * 1.18)
end

print("Lua 22-card perk catalog, reroll, and live effect family regressions passed")
