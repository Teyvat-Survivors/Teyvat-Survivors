local Run = require("game.run")
local Weapons = require("game.weapons")
local data = require("data.weapons")

local function target(id, x, y)
    return { id = id, x = x, y = y, radius = 0.25, health = 100 }
end

local function advance(run, weapons, ticks)
    for _ = 1, ticks do
        run.tick = run.tick + 1
        for _, weapon in ipairs(weapons) do
            Weapons.step(weapon, run, Run.step_seconds)
        end
    end
end

local function close(a, b)
    return math.abs(a - b) < 1e-9
end

do
    local stats = data.dew_aura.levels[1]
    local edge = target(1, stats.radius + 0.25, 0)
    local outside = target(2, edge.x + 0.01, 0)
    local run = { tick = 0, player = { x = 0, y = 0 }, enemies = { active = { edge, outside, edge } } }
    local aura = Weapons.new("dew_aura")
    advance(run, { aura }, 1)
    assert(edge.health == 100 - stats.damage and outside.health == 100, "aura hits its inclusive edge once")

    run.player.x = -10
    advance(run, { aura }, 1)
    assert(aura.fields[1].x == -10, "aura follows between pulses")
    advance(run, { aura }, stats.interval_ticks - 1)
    assert(edge.health == 100 - stats.damage, "leaving the aura stops damage")
    run.player.x = 0
    advance(run, { aura }, stats.interval_ticks)
    assert(edge.health == 100 - 2 * stats.damage, "reentering the aura permits the next scheduled pulse")
    advance(run, { aura }, stats.duration_ticks - 2 * stats.interval_ticks)
    assert(#aura.fields == 0 and run.tick == 1 + stats.duration_ticks, "aura expires on the exact tick")
end

do
    local victim = target(1, 2, 0)
    local run = { tick = 0, player = { x = 0, y = 0 }, enemies = { active = { victim } } }
    local fixed = Weapons.new("ember_field", function() return 0.99 end)
    local aura = Weapons.new("dew_aura")
    local fixedStats, auraStats = data.ember_field.levels[1], data.dew_aura.levels[1]
    advance(run, { fixed, aura }, 1)
    assert(victim.health == 100 - fixedStats.damage - auraStats.damage, "overlapping skills have independent damage")
    assert(fixed.fields[1].hit_ids[1] == 1 and aura.fields[1].hit_ids[1] == 1)
    run.player.x = -10
    advance(run, { fixed, aura }, auraStats.interval_ticks)
    assert(fixed.fields[1].x == 2 and aura.fields[1].x == -10, "target field holds its original center")
    assert(victim.health == 100 - 2 * fixedStats.damage - auraStats.damage, "only the remaining overlap can pulse")
end

do
    local orbit = Weapons.new("jade_satellite")
    assert(Weapons.upgrade(orbit) == 2)
    local stats = data.jade_satellite.levels[orbit.level]
    local start = target(1, stats.orbit_radius, 0)
    local side = target(2, 0, stats.orbit_radius)
    local run = { tick = 0, player = { x = 0, y = 0 }, enemies = { active = { start, side } } }
    advance(run, { orbit }, 1)
    assert(start.health == 100 - stats.damage and side.health == 100, "orbital pulse begins at a fixed phase")
    advance(run, { orbit }, stats.orbit_period_ticks / 4 - 1)
    assert(side.health == 100)
    advance(run, { orbit }, 1)
    assert(side.health == 100 - stats.damage, "quarter-turn pulse hits at the data-driven cadence")
    assert(close(orbit.fields[1].x, 0) and close(orbit.fields[1].y, stats.orbit_radius))

    run.player.x, run.player.y = 3, -5
    advance(run, { orbit }, 1)
    local angle = 2 * math.pi * (stats.orbit_period_ticks / 4 + 1) / stats.orbit_period_ticks
    assert(close(orbit.fields[1].x, 3 + stats.orbit_radius * math.cos(angle)))
    assert(close(orbit.fields[1].y, -5 + stats.orbit_radius * math.sin(angle)))
end

do
    local stats = data.step_quake.levels[1]
    local victim = target(1, 0, 0)
    local run = { tick = 0, player = { x = 0, y = 0 }, enemies = { active = { victim } } }
    local quake = Weapons.new("step_quake")
    advance(run, { quake }, 2)
    assert(#quake.fields == 0 and victim.health == 100, "stationary time cannot charge the burst")
    run.player.x = stats.travel_distance / 2
    advance(run, { quake }, 1)
    assert(#quake.fields == 0)
    run.player.x = 0
    advance(run, { quake }, 1)
    assert(victim.health == 100 - stats.damage, "out-and-back movement accumulates the full path length")

    run.player.x, victim.x = stats.travel_distance, stats.travel_distance
    advance(run, { quake }, stats.cooldown_ticks - 1)
    assert(#quake.fields == 0 and victim.health == 100 - stats.damage, "one charge can wait through cooldown")
    advance(run, { quake }, 1)
    assert(victim.health == 100 - 2 * stats.damage, "stored charge releases when cooldown completes")
    advance(run, { quake }, stats.cooldown_ticks)
    assert(#quake.fields == 0 and victim.health == 100 - 2 * stats.damage, "release consumes the charge")
end

do
    local run = Run.new(9, nil, "dew_aura")
    Run.update(run, Run.step_seconds)
    local aura = assert(run.weapons.fields[1], "a player-centered field starts without targets")
    Run.set_paused(run, true)
    assert(Run.update(run, 10, 1, 0) == 0 and run.tick == 1)
    assert(run.weapons.fields[1] == aura and aura.x == 0, "pause freezes the field clock and center")
    Run.set_paused(run, false)
    Run.update(run, Run.step_seconds, 1, 0)
    assert(run.tick == 2 and aura.x == run.player.x and aura.x > 0, "field resumes with ordinary simulation ticks")
    assert(#Run.restart(run).weapons.fields == 0, "restart creates a fresh field collection")
end

print("Lua fixed and following fields, orbit phase, travel charge, overlap and pause passed")
