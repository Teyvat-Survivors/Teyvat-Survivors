local Weapons = require("game.weapons")
local data = require("data.weapons")
local STEP = 1 / 60

local function close(a, b)
    return math.abs(a - b) < 1e-8
end

local function enemy(id, x, y, health)
    return { id = id, x = x, y = y, radius = 0.15, health = health or 200 }
end

local function fixture(id, level, enemies, randomUnit)
    local weapon = Weapons.new(id, randomUnit)
    for _ = 2, level do
        assert(Weapons.upgrade(weapon))
    end
    return weapon, { tick = 0, player = { x = 0, y = 0 }, enemies = { active = enemies } }
end

local function step(weapon, run, ticks)
    for _ = 1, ticks or 1 do
        run.tick = run.tick + 1
        Weapons.step(weapon, run, STEP)
    end
end

for level, stats in ipairs(data.ridge_dart.levels) do
    local west, south = enemy(1, -2, 0), enemy(2, 0, -3)
    local weapon, run = fixture("ridge_dart", level, { west, south })
    run.player.facing_x, run.player.facing_y = 0, -3
    step(weapon, run)
    local shot = assert(weapon.projectiles[1])
    assert(close(shot.x, 0) and close(shot.y, -stats.speed * STEP), "directional shot follows facing")
    assert(weapon.next_fire_tick == 1 + stats.cooldown_ticks)
    step(weapon, run, math.ceil(4 / (stats.speed * STEP)))
    assert(west.health == 200 and south.health == 200 - stats.damage)
end

do
    local weapon, run = fixture("ridge_dart", 1, { enemy(1, -3, 0) })
    step(weapon, run)
    assert(weapon.projectiles[1].dx == 1, "unset facing defaults east")
end

for level, stats in ipairs(data.star_spark.levels) do
    for _, reverse in ipairs({ false, true }) do
        local east, north = enemy(2, 4, 0), enemy(7, 0, 5)
        local dead, far = enemy(1, 0, 1, 0), enemy(8, stats.range + 1, 0)
        local active = reverse and { north, far, east, dead } or { east, dead, north, far }
        local rolls = 0
        local weapon, run = fixture("star_spark", level, active, function()
            rolls = rolls + 1
            return 0.75
        end)
        step(weapon, run)
        assert(weapon.projectiles[1].dy == 1 and rolls == 1, "eligible targets are ordered by ID before a random pick")
        step(weapon, run, math.ceil(6 / (stats.speed * STEP)))
        assert(north.health == 200 - stats.damage and east.health == 200)
        assert(#weapon.projectiles == 0, "spent single-shot projectile expires")
    end
end

for level, stats in ipairs(data.petal_fan.levels) do
    local anchor = enemy(1, 9, 0)
    local weapon, run = fixture("petal_fan", level, { anchor })
    step(weapon, run)
    assert(#weapon.projectiles == stats.shots, "configured spread count")
    local targets = {}
    for index, shot in ipairs(weapon.projectiles) do
        local angle = (index - (stats.shots + 1) / 2) * stats.angle_step
        assert(close(shot.dx, math.cos(angle)) and close(shot.dy, math.sin(angle)))
        targets[index] = enemy(index + 1, shot.dx * 6, shot.dy * 6)
    end
    run.enemies.active = targets
    step(weapon, run, math.ceil(7 / (stats.speed * STEP)))
    for index, target in ipairs(targets) do
        assert(target.health == 200 - stats.damage, "independent spread projectile " .. index)
    end
    assert(#weapon.projectiles == 0)
end

for level, stats in ipairs(data.stone_lob.levels) do
    local landing, obstacle = enemy(1, 6, 0), enemy(2, 3, 0)
    local weapon, run = fixture("stone_lob", level, { landing })
    step(weapon, run)
    local shot = assert(weapon.projectiles[1])
    assert(shot.height > 0 and close(shot.x, stats.speed * STEP), "lob has an airborne flight path")
    run.enemies.active = { landing, obstacle }
    local landingTick = math.ceil(6 / (stats.speed * STEP))
    step(weapon, run, landingTick - 2)
    assert(landing.health == 200 and obstacle.health == 200 and #weapon.projectiles == 1)
    step(weapon, run)
    assert(landing.health == 200 - stats.damage and obstacle.health == 200, "lob damages on landing only")
    assert(close(shot.x, 6) and shot.height == 0 and #weapon.projectiles == 0)
end

for level, stats in ipairs(data.echo_shard.levels) do
    local wallEnemy = enemy(1, 0.22, 0)
    local weapon, run = fixture("echo_shard", level, { wallEnemy, wallEnemy })
    run.bounds = { min_x = -0.35, max_x = 0.35, min_y = -0.35, max_y = 0.35 }
    step(weapon, run)
    local shot = assert(weapon.projectiles[1])
    assert(shot.dx == -1 and shot.remaining_bounces == stats.bounces - 1)
    assert(close(shot.x, 2 * run.bounds.max_x - stats.speed * STEP), "reflection consumes the remaining tick travel")
    shot.speed = 1200
    step(weapon, run)
    local stop = stats.bounces % 2 == 1 and run.bounds.min_x or run.bounds.max_x
    assert(close(shot.x, stop) and #weapon.projectiles == 0, "shot expires after its bounce budget")
    assert(wallEnemy.health == 200 - stats.damage, "reflections cannot hit the same enemy again")

    local corner, scene = fixture("echo_shard", level, { enemy(1, -4, -4) })
    scene.bounds = { min_x = -1, max_x = 1, min_y = -1, max_y = 1 }
    scene.player.x, scene.player.y = 0.9, 0.9
    scene.player.facing_x, scene.player.facing_y = 1, 1
    step(corner, scene)
    local cornerShot = assert(corner.projectiles[1])
    assert(cornerShot.dx < 0 and cornerShot.dy < 0 and cornerShot.remaining_bounces == stats.bounces - 1,
        "one corner hit reflects both axes and spends one bounce")
end

for level, stats in ipairs(data.willow_return.levels) do
    local crossing = enemy(1, 2, 0)
    local weapon, run = fixture("willow_return", level, { crossing })
    local turnTick = math.ceil(stats.range / (stats.speed * STEP))
    step(weapon, run, turnTick)
    local shot = assert(weapon.projectiles[1])
    assert(shot.returning and crossing.health == 200 - stats.damage)
    run.player.y = 1
    step(weapon, run)
    assert(shot.dx < 0 and shot.dy > 0, "return follows current player position")
    run.player.x = -100
    local returnTicks = math.ceil(stats.range * stats.return_ratio / (stats.speed * STEP))
    step(weapon, run, returnTicks)
    assert(#weapon.projectiles == 0 and crossing.health == 200 - stats.damage, "return has finite travel and shares hit history")

    local catching, scene = fixture("willow_return", level, { enemy(1, 2, 0) })
    step(catching, scene, turnTick)
    local returning = assert(catching.projectiles[1])
    scene.player.x, scene.player.y = returning.x, returning.y
    step(catching, scene)
    assert(#catching.projectiles == 0, "returning shot expires when caught")
end

print("Lua directional, seeded random, spread, lob, rebound, and return projectiles passed at each level")
