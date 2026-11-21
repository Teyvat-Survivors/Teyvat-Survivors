local Weapons = require("game.weapons")
local levels = require("data.weapons").wind_blade.levels
local starter = levels[1]
local stepSeconds = 1 / 60

local function enemy(id, x, y, health, radius)
    return { id = id, x = x, y = y, health = health, radius = radius or 1 }
end

local function newRun(enemies)
    return {
        tick = 0,
        player = { x = 0, y = 0, health = 80 },
        enemies = { active = enemies },
    }, Weapons.new()
end

local function step(run, weapons, onKill)
    run.tick = run.tick + 1
    Weapons.step(weapons, run, stepSeconds, onKill)
end

local function near(actual, expected)
    return math.abs(actual - expected) < 1e-9
end

do
    local west = enemy(1, -starter.range * 0.3, -starter.range * 0.4, 90)
    local east = enemy(2, starter.range * 0.3, starter.range * 0.4, 90)
    local dead = enemy(3, 2, 0, 0)
    local run, weapons = newRun({ east, dead, west })
    step(run, weapons)
    local shot = assert(weapons.projectiles[1])
    assert(near(shot.dx, -0.6) and near(shot.dy, -0.8), "equal distance favors the lower enemy ID")
    assert(near(shot.x, shot.dx * starter.speed * stepSeconds), "direction controls travel")
    assert(near(shot.y, shot.dy * starter.speed * stepSeconds))
end

do
    local first = enemy(1, starter.speed * stepSeconds / 2, 0, 90)
    local run, weapons = newRun({ enemy(2, starter.range + 1, 0, 90) })
    step(run, weapons)
    assert(weapons.next_fire_tick == 1 and #weapons.projectiles == 0, "out-of-range target does not consume cooldown")

    run.enemies.active = { first }
    step(run, weapons)
    local nextFire = run.tick + starter.cooldown_ticks
    assert(first.health == 90 - starter.damage, "sweep hits between the start and end positions")
    assert(weapons.next_fire_tick == nextFire, "cooldown starts on successful fire")
    while run.tick < nextFire - 1 do
        step(run, weapons)
    end
    assert(first.health == 90 - starter.damage, "the projectile and cooldown cannot repeat damage")
    step(run, weapons)
    assert(first.health == 90 - starter.damage * 2, "weapon fires at the scheduled tick")
end

do
    local middle = starter.speed * stepSeconds / 2
    local one = enemy(1, middle, 0, starter.damage)
    local two = enemy(2, middle, 0, starter.damage)
    local beyond = enemy(3, middle + 1, 0, 90)
    local run, weapons = newRun({ beyond, two, one })
    local kills = {}

    local function onKill(target)
        kills[#kills + 1] = target.id
        assert(target.x == middle and target.y == 0 and target.health == 0)
    end

    step(run, weapons, onKill)
    assert(one.health == 0 and two.health == 0 and beyond.health == 90, "pierce hits two contacts, ordered by entry then ID")
    assert(#weapons.projectiles == 0, "spent projectile is recycled")
    assert(kills[1] == 1 and kills[2] == 2 and #kills == 2, "each kill is reported once in matching contact order")
    step(run, weapons, onKill)
    assert(#kills == 2 and #run.enemies.active == 3, "kills neither repeat nor mutate the enemy collection")
    assert(run.player.health == 80, "attack system does not change player health")
end

do
    local target = enemy(1, 0, 0, 90, 100)
    local run, weapons = newRun({ target, target })
    for _ = 1, 5 do
        step(run, weapons)
    end
    local shot = assert(weapons.projectiles[1])
    assert(shot.dx == 1 and shot.dy == 0, "overlapping target uses a fallback direction")
    assert(target.health == 90 - starter.damage, "a shot overlapping the target across ticks and duplicate entries hits only once")
    assert(shot.remaining_hits == starter.pierce, "duplicate contacts do not spend pierce")
end

do
    local target = enemy(1, starter.range, 0, 90)
    local run, weapons = newRun({ target })
    step(run, weapons)
    assert(#weapons.projectiles == 1, "the exact targeting range is inclusive")
    target.x = starter.range + 20
    for _ = 1, math.ceil(starter.range / (starter.speed * stepSeconds)) do
        step(run, weapons)
    end
    assert(#weapons.projectiles == 0 and target.health == 90, "projectile stops at its travel range")
end

do
    local target = enemy(1, starter.range * 0.75, 0, 90)
    local run, weapons = newRun({ target })
    step(run, weapons)
    local shot = assert(weapons.projectiles[1])
    local fireTick = weapons.next_fire_tick

    for level = 2, #levels do
        assert(Weapons.upgrade(weapons) == level, "upgrade advances one level")
    end
    assert(Weapons.upgrade(weapons) == nil and weapons.level == #levels, "weapon cannot exceed its configured cap")
    assert(shot.damage == starter.damage and weapons.next_fire_tick == fireTick, "upgrade preserves shots and cooldown already started")
    assert(Weapons.new().level == 1, "weapon levels are isolated by run")

    while run.tick < fireTick do
        step(run, weapons)
    end
    assert(weapons.projectiles[1].damage == levels[#levels].damage, "subsequent projectiles use the upgraded damage")
end

print("Lua automatic targeting, swept hits, pierce, cooldown, cleanup and growth passed")
