local Weapons = require("game.weapons")
local data = require("data.weapons")
local STEP = 1 / 60

local function target(id, x, health)
    return { id = id, x = x, y = 0, radius = 0.25, health = health }
end

local function scene(enemies, modifiers)
    return { tick = 0, player = { x = 0, y = 0 }, enemies = { active = enemies }, weapon_modifiers = modifiers }
end

local function advance(weapon, run, ticks, onKill)
    for _ = 1, ticks do
        run.tick = run.tick + 1
        Weapons.step(weapon, run, STEP, onKill)
    end
end

local function forbidRandom()
    error("guaranteed or disabled critical attacks need no random number")
end

do
    local stats = data.frost_pulse.levels[1]
    local boundary = stats.radius + 0.25
    local inside = target(1, boundary, 100)
    local outside = target(2, boundary + 0.01, 100)
    local run = scene({ outside, inside, inside }, { knockback = 0 })
    local weapon = Weapons.new("frost_pulse", forbidRandom)
    advance(weapon, run, 1)
    assert(inside.health == 100 - stats.damage and inside.x == boundary, "inclusive area hits each enemy once")
    assert(outside.health == 100, "pulse cannot hit outside its radius")
    assert(weapon.next_fire_tick == 1 + stats.cooldown_ticks, "pulse cooldown is scheduled in ticks")
end

do
    local stats = data.frost_pulse.levels[1]
    local living = target(1, stats.radius + 1, 100)
    local fatal = target(2, stats.radius + 1, 10)
    local run = scene({ fatal, living }, { damage = 2, area = 1.5, crit_chance = 2, cooldown = 0, knockback = 2 })
    local weapon = Weapons.new("frost_pulse", forbidRandom)
    local kills = 0
    advance(weapon, run, 1, function(enemy)
        assert(enemy.id == fatal.id and enemy.x == stats.radius + 1, "lethal hit does not knock back")
        kills = kills + 1
    end)
    assert(kills == 1 and living.health == 100 - stats.damage * 3, "critical cap applies to scaled damage")
    assert(math.abs(living.x - (stats.radius + 1 + stats.knockback * 2)) < 1e-9, "area, damage and knockback combine")
    assert(weapon.next_fire_tick == 2, "cooldown cannot drop below one tick")
end

do
    local enemy = target(1, 1, 100)
    enemy.laneDirection = -1
    local run = scene({ enemy })
    run.player.y = -1
    advance(Weapons.new("frost_pulse", forbidRandom), run, 1)
    assert(enemy.health < 100 and enemy.x > 1 and enemy.y == 0,
        "off-axis hits project their knockback onto the lane")
end

do
    local stats = data.ember_field.levels[1]
    local near = target(1, 7, 100)
    local late = target(2, 8, 100)
    local run = scene({ near, near }, { crit_chance = -2 })
    local weapon = Weapons.new("ember_field", forbidRandom)
    advance(weapon, run, 1)
    assert(#weapon.fields == 1 and weapon.fields[1].x == near.x, "field is placed on the closest target")
    assert(near.health == 100 - stats.damage, "field pulses on its cast tick")
    advance(weapon, run, stats.interval_ticks - 1)
    assert(near.health == 100 - stats.damage, "field waits for the full pulse interval")
    advance(weapon, run, 1 + stats.interval_ticks)
    assert(near.health == 100 - stats.damage * stats.max_hits_per_target, "field repeats until per-target cap")
    run.enemies.active = { near, late }
    advance(weapon, run, stats.interval_ticks)
    assert(near.health == 100 - stats.damage * stats.max_hits_per_target and late.health == 100 - stats.damage, "target cap is independent for each enemy")
    advance(weapon, run, stats.duration_ticks - 3 * stats.interval_ticks)
    assert(#weapon.fields == 0 and late.health == 100 - stats.damage, "expiration suppresses another pulse")
end

do
    local stats = data.ember_field.levels[1]
    local victim = target(1, 4, 100)
    local run = scene({ victim }, { duration = stats.interval_ticks / stats.duration_ticks })
    local rolls = 0
    local weapon = Weapons.new("ember_field", function()
        rolls = rolls + 1
        return 0.1
    end)
    advance(weapon, run, 1 + stats.interval_ticks)
    assert(rolls == 1 and victim.health == 100 - stats.damage * stats.crit_multiplier, "expiry tick takes precedence over pulse scheduling")
    assert(#weapon.fields == 0)
end

do
    local stats = data.ember_field.levels[1]
    local low, high = target(2, 6, 100), target(3, 6, 100)
    local run = scene({ high, low })
    local rolls = { 0.1, 0.75 }
    local weapon = Weapons.new("ember_field", function() return table.remove(rolls, 1) end)
    advance(weapon, run, 1)
    assert(#rolls == 0 and low.health < high.health, "rolls on simultaneous equal-distance contacts are ordered by enemy ID")
    assert(Weapons.max_level(weapon) == 2 and Weapons.upgrade(weapon) == 2 and not Weapons.upgrade(weapon), "each weapon uses its own level cap")
end

do
    local stats = data.wind_blade.levels[1]
    local sentinel = target(1, stats.range * 1.9, 1)
    local beyond = target(2, stats.range * 2 + 2, 1)
    local run = scene({ beyond, sentinel }, { range = 2, projectile_speed = 1000, pierce = 2 })
    local weapon = Weapons.new("wind_blade", forbidRandom)
    local kills = 0
    advance(weapon, run, 3, function(enemy)
        assert(enemy.id == sentinel.id)
        kills = kills + 1
    end)
    assert(kills == 1 and sentinel.health == 0 and beyond.health == 1, "fast projectile sweeps to its scaled range and kills once")
    assert(#weapon.projectiles == 0, "shot expires at the end of its range")
end

print("Lua area, critical damage, knockback, field cadence, cap and expiry passed")
