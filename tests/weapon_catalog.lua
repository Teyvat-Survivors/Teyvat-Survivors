local Enemies = require("game.enemies")
local Progress = require("game.progress")
local Run = require("game.run")
local Weapons = require("game.weapons")
local catalog = require("data.weapons")
local STEP = 1 / 60

local function close(actual, expected)
    return math.abs(actual - expected) < 1e-8
end

local function enemy(id, x, y)
    return { id = id, x = x, y = y, radius = 0.15, health = 200 }
end

local function evolve(id, rank, targets, random)
    local weapon = Weapons.new(id, random or function() return 0 end)
    for expected = 2, rank do
        assert(Weapons.upgrade(weapon) == expected)
    end
    return weapon, {
        tick = 0,
        player = { x = 0, y = 0, facing_x = 1, facing_y = 0, health = 100, max_health = 100 },
        enemies = { active = targets },
    }
end

local function advance(weapon, run, ticks)
    for _ = 1, ticks or 1 do
        run.tick = run.tick + 1
        Weapons.step(weapon, run, STEP)
    end
end

local function each(id, verify)
    for rank, stats in ipairs(catalog[id].levels) do
        verify(rank, stats)
    end
end

each("mist_cut", function(rank, stats)
    local front, side, rear = enemy(1, 2.4, 0), enemy(2, 0, 2.4), enemy(3, -2.4, 0)
    local weapon, run = evolve("mist_cut", rank, { rear, side, front })
    advance(weapon, run)
    assert(front.health == 200 - stats.damage and close(front.x, 2.4 + stats.knockback))
    assert(side.health == 200 and rear.health == 200, "cone excludes lateral and rear targets")
end)

each("sky_needle", function(rank, stats)
    local far, near = enemy(1, 25, 0), enemy(2, 6, 0)
    local weapon, run = evolve("sky_needle", rank, { near, far })
    advance(weapon, run, stats.delay_ticks)
    local field = assert(weapon.fields[1])
    assert(field.x == 25 and far.health == 200, "delayed mark stays on the seeded target location")
    advance(weapon, run)
    assert(far.health == 200 - stats.damage and near.health == 200)
    advance(weapon, run)
    assert(#weapon.fields == 0)
end)

each("cloud_scout", function(rank, stats)
    local path = enemy(1, 5, 0)
    local weapon, run = evolve("cloud_scout", rank, { path })
    advance(weapon, run)
    run.player.x = 100
    advance(weapon, run, stats.turn_ticks)
    local field = assert(weapon.fields[1])
    assert(close(field.x, (stats.turn_ticks - 1) * stats.drift_per_tick))
    assert(close(field.y, stats.drift_per_tick), "scout keeps its own seeded trajectory and changes course")
    assert(path.health < 200, "scout strikes independently of player movement")
end)

each("moon_tide", function(rank, stats)
    local angle = stats.orbit_phase + 2 * math.pi * stats.delay_ticks / stats.orbit_period_ticks
    local path = enemy(1, stats.orbit_radius * math.cos(angle), stats.orbit_radius * math.sin(angle))
    local weapon, run = evolve("moon_tide", rank, { path })
    advance(weapon, run)
    assert(close(weapon.fields[1].x, -stats.orbit_radius) and path.health == 200)
    advance(weapon, run, stats.delay_ticks)
    assert(path.health == 200 - stats.damage, "the counter-phase orbit first strikes after its delay")
end)

for _, id in ipairs({ "prism_cross", "willow_twins", "needle_ring" }) do
    each(id, function(rank, stats)
        local cue = enemy(1, 10, 0)
        local weapon, run = evolve(id, rank, { cue })
        advance(weapon, run)
        assert(#weapon.projectiles == stats.shots)
        local targets = {}
        for i, shot in ipairs(weapon.projectiles) do
            local angle = (i - (stats.shots + 1) / 2) * (stats.angle_step or 0)
            if id == "prism_cross" then
                angle = (i - 1) * 2 * math.pi / stats.shots
            elseif id == "willow_twins" then
                angle = angle + math.pi
            end
            assert(close(shot.dx, math.cos(angle)) and close(shot.dy, math.sin(angle)))
            targets[i] = enemy(i + 1, shot.dx * 6, shot.dy * 6)
        end
        run.enemies.active = targets
        advance(weapon, run, math.ceil(7 / (stats.speed * STEP)))
        for _, target in ipairs(targets) do
            assert(close(target.health, 200 - stats.damage), "each independent projectile hits one intended route")
        end
    end)
end

each("storm_lane", function(rank, stats)
    local front = enemy(1, 5, stats.line_half_width + 0.14)
    local side = enemy(2, 5, stats.line_half_width + 0.16)
    local rear = enemy(3, -5, 0)
    local weapon, run = evolve("storm_lane", rank, { rear, side, front })
    advance(weapon, run)
    assert(front.health == 200 - stats.damage, "lane includes target radius on the perpendicular axis")
    assert(side.health == 200 and rear.health == 200)
end)

each("ember_breath", function(rank, stats)
    local front, rear = enemy(1, 3, 0), enemy(2, -3, 0)
    local weapon, run = evolve("ember_breath", rank, { rear, front })
    advance(weapon, run)
    run.player.facing_x = -1
    advance(weapon, run, stats.duration_ticks)
    assert(front.health == 200 - stats.damage * stats.max_hits_per_target and rear.health == 200,
        "channeled cone keeps its cast direction, repeat cadence, and cap")
    assert(#weapon.fields == 0)
end)

each("trail_mine", function(rank, stats)
    local chargedX = stats.travel_distance + 0.4
    local blast = enemy(1, chargedX - stats.rear_offset, 0)
    local weapon, run = evolve("trail_mine", rank, { blast })
    advance(weapon, run)
    run.player.x = chargedX
    advance(weapon, run)
    assert(#weapon.fields == 0 and blast.health == 200, "trap waits for movement to stop")
    advance(weapon, run)
    assert(close(weapon.fields[1].x, chargedX - stats.rear_offset))
    run.player.x = 40
    advance(weapon, run, stats.delay_ticks)
    assert(blast.health == 200 - stats.damage and close(weapon.fields[1].x, blast.x),
        "released trap detonates at its rear position")
end)

each("pebble_chain", function(rank, stats)
    local targets = {
        enemy(1, 2, 0), enemy(2, 2, 2), enemy(3, 4, 2), enemy(4, 4, 4), enemy(5, 6, 4),
    }
    local weapon, run = evolve("pebble_chain", rank, targets)
    run.weapon_modifiers = { projectile_speed = 1000 }
    advance(weapon, run)
    for index, target in ipairs(targets) do
        local expected = index <= 1 + stats.pierce and 200 - stats.damage or 200
        assert(target.health == expected, "ricochet bends toward the nearest unhit target until its cap")
    end
end)

each("blossom_bomb", function(rank, stats)
    for _, roll in ipairs({ 0.03, 0.97 }) do
        local direct, splash = enemy(1, 5, 0), enemy(2, 6.4, 0)
        local rolls = 0
        local weapon, run = evolve("blossom_bomb", rank, { splash, direct }, function()
            rolls = rolls + 1
            return roll
        end)
        advance(weapon, run, math.ceil(5 / (stats.speed * STEP)))
        assert(direct.health == 200 - stats.damage and rolls == 1)
        local expected = roll < stats.blast_chance and 200 - stats.damage * stats.blast_multiplier or 200
        assert(close(splash.health, expected), "explosion chance is tested at landing")
    end
end)

each("last_stand", function(rank, stats)
    for _, health in ipairs({ 100, stats.low_health_fraction * 100 }) do
        local closeTarget = enemy(1, 2, 0)
        local weapon, run = evolve("last_stand", rank, { closeTarget })
        run.player.health = health
        advance(weapon, run)
        local scale = health == 100 and 1 or stats.low_health_multiplier
        assert(close(closeTarget.health, 200 - stats.damage * scale), "health threshold includes equality")
    end
end)

each("horizon_shatter", function(rank, stats)
    local distant, elite, terminal = enemy(1, 150, 120), enemy(2, -185, 140), enemy(3, 200, 190)
    elite.isElite, terminal.isTerminal = true, true
    local weapon, run = evolve("horizon_shatter", rank, { distant, elite, terminal })
    advance(weapon, run)
    assert(distant.health == 0 and elite.health == 200 - stats.elite_damage and terminal.health == 200,
        "arena-wide purge clears normal units, injures elites, and preserves the finale")
    assert(weapon.next_fire_tick == 1 + stats.cooldown_ticks)
end)

do
    local stage = {
        id = "catalog_fixture", duration_ticks = 500, terminal_kind = "dummy", terminal_timeout_ticks = 10,
        build_rules = { choice_count = 60 },
        waves = {
            capacity = 4, spawnDistance = 2, despawnDistance = 30, contactIntervalTicks = 30, spawns = {},
            types = { dummy = { health = 500, radius = 0.15, speed = 0, contactDamage = 0 } },
        },
    }
    local run = Run.new(19, stage, "mist_cut")
    Progress.drop(run.progress, { id = 101, x = 0, y = 0, xp = run.progress.xpNeeded })
    Run.update(run, STEP)
    assert(Run.choose(run, run.progress.choices.token, "weapon:ember_breath"))
    local dummy = Enemies.begin_finale(run.enemies, run.player, "dummy")
    dummy.x, dummy.y = 2, 0
    Run.update(run, STEP)
    assert(#run.weapon_systems == 2)
    assert(dummy.health == 500 - catalog.mist_cut.levels[1].damage - catalog.ember_breath.levels[1].damage,
        "two distinct equipped attacks use the ordinary fixed-step entry")
end

print("Lua weapon catalog: each new weapon and level, projectile and field extremes, and coexistence passed")
