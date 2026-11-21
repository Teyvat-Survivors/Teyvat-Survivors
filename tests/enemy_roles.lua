local Enemies = require("game.enemies")
local waves = require("data.waves")
local stages = require("data.stages")

local function testConfig(spawns, types)
    return {
        capacity = 6, spawnDistance = 3, despawnDistance = 30, contactIntervalTicks = 5,
        types = types, spawns = spawns,
    }
end

local function newRun()
    return { tick = 0, player = { x = 0, y = 0, radius = 0.4, health = 100 } }
end

local function step(system, run, tick)
    run.tick = tick
    Enemies.step(system, run, 1 / 60)
end

local function near(a, b)
    return math.abs(a - b) < 1e-8
end

do
    local system = Enemies.new(testConfig({
        { tick = 1, kind = "drift", count = 1 },
        { tick = 1, kind = "gale_runner", count = 1 },
    }, waves.types), function() return 0.25 end)
    local run = newRun()
    step(system, run, 1)
    local chaser, runner = system.active[1], system.active[2]
    assert(runner.y < chaser.y and near(runner.x, 0) and near(chaser.x, 0),
        "runner closes the same initial gap faster in the seeded direction")
    assert(runner.kind == "gale_runner" and not runner.isElite and not runner.isTerminal)
end

do
    local config = testConfig({
        { tick = 1, kind = "ram", count = 1 },
        { tick = 9, kind = "drift", count = 1 },
    }, {
        ram = {
            radius = 0.8, speed = 3, health = 14, contactDamage = 13, elite = true, xp = 4,
            charge = { range = 10, speed = 300, windupTicks = 2, chargeTicks = 2, cooldownTicks = 3 },
        },
        drift = waves.types.drift,
    })
    local run = newRun()
    local system = Enemies.new(config, function() return 0 end)
    step(system, run, 1)
    local ram = system.active[1]
    assert(ram.isElite and ram.xp == 4 and ram.motion == "windup" and ram.motionEndsTick == 3)
    run.player.y = 0.4
    step(system, run, 2)
    assert(ram.x == 3 and ram.y == 0 and ram.motion == "windup")
    step(system, run, 3)
    assert(ram.x == -2 and ram.y == 0 and ram.motion == "charging" and ram.motionEndsTick == 5,
        "windup locks the aim before the charge starts")
    assert(run.player.health == 87 and system.nextContactTick == 8,
        "swept contact catches a player between the charge start and end")
    step(system, run, 4)
    assert(ram.x == -7 and ram.motion == "charging")
    for tick = 5, 7 do
        step(system, run, tick)
        assert(ram.motion == "approach" and ram.nextChargeTick == 8)
    end
    step(system, run, 8)
    assert(ram.motion == "windup" and ram.motionEndsTick == 10)
    assert(Enemies.damage(ram, 100))
    Enemies.compact(system)
    step(system, run, 9)
    assert(system.active[1] == ram and ram.kind == "drift" and ram.id == 2)
    assert(not ram.isElite and ram.charge == nil and ram.motion == nil and ram.motionEndsTick == nil)
    assert(ram.xp == nil and ram.nextChargeTick == nil and ram.chargeX == nil and ram.chargeY == nil,
        "recycled records clear elite flags, charge state and rewards")
end

do
    local config = testConfig({}, {
        boss = {
            radius = 1, speed = 2, health = 100, contactDamage = 4,
            frenzy = { healthFraction = 0.5, speed = 8, contactDamage = 9 },
        },
    })
    config.despawnDistance = 6
    local run = newRun()
    local system = Enemies.new(config, function() return 0 end)
    local boss = Enemies.begin_finale(system, run.player, "boss")
    step(system, run, 1)
    assert(boss.isTerminal and boss.phase == 1 and near(boss.x, 3 - 2 / 60))
    assert(not Enemies.damage(boss, 49))
    step(system, run, 2)
    assert(boss.phase == 1)
    assert(not Enemies.damage(boss, 1))
    step(system, run, 3)
    assert(boss.phase == 2 and near(boss.x, 3 - 4 / 60 - 8 / 60))
    assert(boss.contactDamage == 9 and boss.speed == 8)
    run.player.x = 25
    step(system, run, 4)
    assert(system.active[1] == boss, "a finale enemy stays active beyond ordinary culling distance")
    run.player.x = boss.x
    step(system, run, 5)
    assert(run.player.health == 91, "the next contact uses phase two damage")
    local nextBoss = Enemies.begin_finale(system, run.player, "boss")
    assert(nextBoss == boss and nextBoss.id == 2 and nextBoss.phase == 1 and nextBoss.speed == 2,
        "recycled finale starts in its original phase")
end

do
    local config = testConfig({
        { tick = 1, kind = "drift", count = 1 },
        { tick = 1, kind = "ram", count = 1 },
    }, {
        drift = waves.types.drift,
        ram = {
            radius = 0.8, speed = 3, health = 14, contactDamage = 13,
            charge = { range = 10, speed = 300, windupTicks = 2, chargeTicks = 2, cooldownTicks = 3 },
        },
    })
    local turns = { 0.25, 0.75, 0.25 }
    local system = Enemies.new(config, function() return table.remove(turns, 1) end, true)
    local run = newRun()
    run.player.y = 0.4
    step(system, run, 1)
    local drift, ram = system.active[1], system.active[2]
    assert(drift.x < 0 and drift.y == 0 and drift.laneDirection == 1)
    assert(ram.x == 3 and ram.y == 0 and ram.laneDirection == -1 and ram.motion == "windup")
    run.player.y = -0.4
    step(system, run, 3)
    assert(ram.x == -2 and ram.y == 0 and ram.motion == "charging")
    assert(run.player.health == 87, "crossing the player still inflicts contact damage")
    step(system, run, 4)
    run.player.x = -4
    local before = drift.x
    local ramBefore = ram.x
    step(system, run, 5)
    assert(drift.x > before and drift.y == 0 and ram.x < ramBefore and ram.y == 0,
        "ordinary and charging enemies keep their direction when crossed")
    local boss = Enemies.begin_finale(system, run.player, "drift")
    before = boss.x
    run.player.x = before - 1
    step(system, run, 6)
    assert(boss.isTerminal and boss.x > before and boss.y == 0)
end

do
    local stage = stages.windward
    local seen = {}
    for _, wave in ipairs(stage.waves.spawns) do
        seen[wave.kind] = seen[wave.kind] or wave.tick
    end
    assert(seen.gale_runner == 50 * 60 and seen.ember_ram == 100 * 60)
    assert(stage.waves.types.ember_ram.elite and stage.waves.types.tempest.frenzy)
    assert(stage.duration_ticks == 108000 and stage.straight_lane)
end

print("Lua runner, elite charge and cooldown, swept contact, pooled reset and finale phase passed")
