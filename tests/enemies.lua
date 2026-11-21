local Enemies = require("game.enemies")
local waves = require("data.waves")
local fixedStep = 1 / 60

local function testingConfig(spawns)
    return {
        capacity = 4,
        spawnDistance = 10,
        despawnDistance = 20,
        contactIntervalTicks = 3,
        types = {
            drift = { radius = 1, speed = 3, health = 4, contactDamage = 5 },
            sentinel = { radius = 2, speed = 2, health = 12, contactDamage = 9 },
        },
        spawns = spawns,
    }
end

local function newRun()
    return {tick = 0, player = {x = 2, y = 3, radius = 0.5, health = 100}}
end

local function step(system, run, tick)
    run.tick = tick
    Enemies.step(system, run, fixedStep)
end

local function seedRandom(seed)
    return function()
        seed = (seed * 48271) % 2147483647
        return seed / 2147483647
    end
end

do
    local system = Enemies.new(testingConfig({
        {tick = 2, kind = "drift", count = 1},
        {tick = 5, kind = "drift", count = 1},
        {tick = 5, kind = "sentinel", count = 1},
    }), function() return 0 end)
    local run = newRun()
    step(system, run, 1)
    assert(#system.active == 0, "no enemy spawns before the first scheduled tick")
    step(system, run, 2)
    assert(#system.active == 1, "the first enemy spawns on the scheduled tick")
    assert(system.active[1].y == 3, "chase follows the direct line to the player")
    assert(math.abs(system.active[1].x - (12 - 3 * fixedStep)) < 1e-9, "chase advances by speed times timestep")
    step(system, run, 3)
    step(system, run, 4)
    assert(#system.active == 1, "there are no extra spawns between waves")
    step(system, run, 5)
    assert(#system.active == 3 and system.active[3].kind == "sentinel", "same-tick wave groups are processed in order")
end

do
    local config = testingConfig({{tick = 1, kind = "drift", count = 2}})
    config.spawnDistance = 0
    local system = Enemies.new(config)
    local run = newRun()
    step(system, run, 1)
    assert(run.player.health == 95, "overlapping enemies cause one contact hit")
    step(system, run, 2)
    step(system, run, 3)
    assert(run.player.health == 95, "contact cooldown suppresses consecutive hits")
    step(system, run, 4)
    assert(run.player.health == 90, "contact can hit again on the exact allowed tick")
    run.player.health = 2
    step(system, run, 7)
    assert(run.player.health == 0, "contact damage clamps health at zero")
end

do
    local config = testingConfig({
        {tick = 1, kind = "drift", count = 3},
        {tick = 2, kind = "sentinel", count = 1},
    })
    local system = Enemies.new(config, function() return 0 end)
    local run = newRun()
    step(system, run, 1)
    local active = system.active
    local first, defeated, last = active[1], active[2], active[3]
    assert(not Enemies.damage(defeated, 1) and defeated.health == 3, "nonlethal hits do not defeat")
    assert(Enemies.damage(defeated, 20) and defeated.health == 0, "a lethal hit defeats once")
    assert(not Enemies.damage(defeated, 1), "repeated damage does not defeat twice")
    Enemies.compact(system)
    assert(system.active == active and #active == 2 and active[1] == first and active[2] == last, "compact retains active order")
    step(system, run, 2)
    local recycled = active[3]
    assert(recycled == defeated and recycled.id == 4, "pooled records receive a new monotonic ID")
    assert(recycled.kind == "sentinel" and recycled.health == 12 and recycled.radius == 2, "pooled record takes the new type")
    assert(recycled.speed == 2 and recycled.contactDamage == 9, "pooled record resets movement and damage")
    assert(math.abs(recycled.x - (12 - 2 * fixedStep)) < 1e-9 and recycled.y == 3, "pooled record resets position")
end

do
    local config = testingConfig({
        {tick = 1, kind = "drift", count = 6},
        {tick = 2, kind = "sentinel", count = 2},
    })
    local system = Enemies.new(config)
    local run = newRun()
    step(system, run, 1)
    assert(#system.active == 4 and system.totalSkipped == 2, "spawns are bounded by active capacity")
    run.player.x = 100
    step(system, run, 2)
    assert(#system.active == 2 and system.active[1].id == 5, "out-of-range enemies are recycled before new spawns")
    step(system, run, 3)
    assert(#system.active == 2 and system.totalSpawned == 6, "skipped spawns do not build a future backlog")
end

do
    local first = Enemies.new(waves, seedRandom(42))
    local second = Enemies.new(waves, seedRandom(42))
    local different = Enemies.new(waves, seedRandom(123))
    local firstRun, secondRun, differentRun = newRun(), newRun(), newRun()
    local expectedSpawns = {[120] = 3, [360] = 8, [600] = 15, [900] = 25}
    local expectedTotal = 0
    for tick = 1, 900 do
        step(first, firstRun, tick)
        step(second, secondRun, tick)
        step(different, differentRun, tick)
        expectedTotal = expectedSpawns[tick] or expectedTotal
        assert(first.totalSpawned == expectedTotal and second.totalSpawned == expectedTotal, "spawn regression at fixed tick " .. tick)
        assert(#first.active == #second.active and firstRun.player.health == secondRun.player.health, "same seed replays active count and damage")
        for index, enemy in ipairs(first.active) do
            local replayed = second.active[index]
            assert(enemy.id == replayed.id and enemy.x == replayed.x and enemy.y == replayed.y, "same seed replays all enemy positions")
        end
        if tick == 120 then
            assert(first.active[1].x ~= different.active[1].x, "a different seed can change the spawn position")
        end
    end
end

print("Lua enemy tracking, scheduled waves, contact cooldown, and recycle passed")
