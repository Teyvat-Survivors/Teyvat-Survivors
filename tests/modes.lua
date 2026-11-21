local Run = require("game.run")
local Profile = require("game.profile")
local stages = require("data.stages")

local function fixture()
    return {
        id = "mode_test",
        duration_ticks = 10,
        terminal_kind = "boss",
        terminal_timeout_ticks = 6,
        bounds = { min_x = -12, max_x = 8, min_y = -9, max_y = 9 },
        features = {
            { kind = "hazard", x = 6, y = 4, radius = 0.5, amount = 2, first_tick = 5, interval_ticks = 7 },
        },
        waves = {
            capacity = 10, spawnDistance = 8, despawnDistance = 40, contactIntervalTicks = 5,
            types = {
                drift = { radius = 0.8, speed = 0, health = 500, contactDamage = 4 },
                boss = { radius = 1, speed = 0, health = 1000, contactDamage = 7 },
            },
            spawns = {
                { tick = 2, kind = "drift", count = 1 },
                { tick = 9, kind = "drift", count = 1 },
            },
        },
    }
end

local function advance(run, target)
    while run.tick < target and not run.result do
        local stepped = Run.update(run, Run.step_seconds)
        assert(stepped == 1)
    end
end

local function close(actual, expected)
    assert(math.abs(actual - expected) < 1e-9, tostring(actual) .. " != " .. tostring(expected))
end

do
    local stage = fixture()
    local normal = Run.new(71, stage)
    local hard = Run.new(71, stage, nil, nil, { difficulty = "hard" })
    local mirror = Run.new(71, stage, nil, nil, { mirrored = true })
    local both = Run.new(71, stage, nil, nil, { difficulty = "hard", mirrored = true })
    assert(normal.stage == stage and not normal.mode.endless and Run.new().stage == stages.windward)
    for _, run in ipairs({ normal, hard, mirror, both }) do
        advance(run, 2)
        assert(run.stage.duration_ticks == 10 and run.stage.waves.spawns[1].tick == 2)
    end
    local n, h = normal.enemies.active[1], hard.enemies.active[1]
    local m, hm = mirror.enemies.active[1], both.enemies.active[1]
    close(n.health, 500)
    close(h.health, n.health * 1.3)
    close(h.contactDamage, n.contactDamage * 1.2)
    close(h.x, n.x)
    close(m.health, n.health * 1.15)
    close(m.contactDamage, n.contactDamage * 1.1)
    close(m.x, -n.x)
    close(m.y, n.y)
    close(hm.health, n.health * 1.3 * 1.15)
    assert(mirror.stage.bounds.min_x == -8 and mirror.stage.bounds.max_x == 12)
    assert(mirror.stage.features[1].x == -6 and stage.features[1].x == 6)
    normal.loot.coins, hard.loot.coins, mirror.loot.coins, both.loot.coins = 20, 20, 20, 20
    for _, run in ipairs({ normal, hard, mirror, both }) do
        advance(run, 16)
        assert(run.result and run.terminal_id and run.result.outcome == "finale_survived")
    end
    assert(normal.result.coins == 20 and hard.result.coins == 20)
    assert(mirror.result.coins == 30 and both.result.coins == 30)
    assert(not Run.finish_endless(Run.new(71, stage)))
end

do
    local stage = fixture()
    local options = { quick = true, mirrored = true }
    local quick = Run.new(5, stage, nil, nil, options)
    options.quick = false
    assert(quick.mode.quick and quick.mode.mirrored and quick.stage.duration_ticks == 5)
    assert(quick.stage.terminal_timeout_ticks == 3 and quick.stage.features[1].first_tick == 3)
    assert(quick.stage.features[1].interval_ticks == 4 and quick.stage.features[1].x == -6)
    assert(quick.stage.waves.spawns[1].tick == 1 and quick.stage.waves.spawns[2].tick == 4)
    assert(stage.duration_ticks == 10 and stage.waves.spawns[2].tick == 9 and stage.features[1].first_tick == 5)
    assert(quick.weapons.id == Run.new(5, stage).weapons.id)
    advance(quick, 4)
    assert(quick.enemies.totalSpawned == 2 and not quick.terminal_id)
    advance(quick, 8)
    assert(quick.result.tick == 8 and quick.result.outcome == "finale_survived")
    local replay = Run.restart(quick)
    assert(replay.source_stage == stage and replay.stage.duration_ticks == 5 and replay.mode.quick and replay.mode.mirrored)
    local character = assert(Run.for_character("wind_scout", 5, stage, nil, nil, { quick = true }))
    assert(character.mode.quick and Run.restart(character).character_id == "wind_scout")
    assert(not pcall(Run.new, 1, stage, nil, nil, { difficulty = "invalid" }))
    assert(not pcall(Run.new, 1, stage, nil, nil, { quick = 1 }))
end

do
    local stage = fixture()
    local function newEndless()
        return Run.new(42, stage, nil, nil, { endless = true, mirrored = true })
    end
    local run, replay = newEndless(), newEndless()
    for _, tick in ipairs({ 2, 9, 12, 19, 22, 23 }) do
        advance(run, tick)
        advance(replay, tick)
        assert(run.result == nil and run.terminal_id == nil)
        assert(#run.enemies.active == #replay.enemies.active)
        for index, enemy in ipairs(run.enemies.active) do
            local mirrored = replay.enemies.active[index]
            assert(enemy.id == mirrored.id and enemy.x == mirrored.x and enemy.y == mirrored.y)
            close(enemy.health, mirrored.health)
        end
    end
    assert(run.cycle == 3 and run.cycle_tick == 3 and run.enemies.totalSpawned == 5)
    assert(run.enemies.active[1].id == 1 and run.enemies.active[5].id == 5)
    close(run.enemies.active[1].maxHealth, 500 * 1.15)
    close(run.enemies.active[3].maxHealth, 500 * 1.15 * 1.18)
    close(run.enemies.active[5].maxHealth, 500 * 1.15 * 1.36)
    for _, enemy in ipairs(run.enemies.active) do assert(not enemy.isTerminal and enemy.kind == "drift") end
    local events = Run.take_events(run)
    assert(#events == 2 and events[1].kind == "cycle_started" and events[1].tick == 11 and events[2].tick == 21)
    run.loot.coins = 9
    assert(Run.finish_endless(run) and not Run.finish_endless(run))
    assert(run.result.outcome == "retired" and run.result.tick == 23 and run.result.cycles_completed == 2)
    assert(run.result.coins == 13 and Run.update(run, 1) == 0)
    events = Run.take_events(run)
    assert(#events == 1 and events[1].kind == "finished")
    local restart = Run.restart(run)
    assert(restart.cycle == 1 and restart.cycle_tick == 0 and restart.enemies.totalSpawned == 0)
    assert(restart.mode.endless and restart.mode.mirrored and restart.result == nil)
    local profile = Profile.load()
    local runId = assert(Profile.begin_run(profile))
    assert(Profile.settle(profile, runId, run.result))
    assert(profile.coins == 13 and profile.completed_runs == 1 and profile.wins == 0)
    assert(not Profile.settle(profile, runId, run.result))
end

print("Lua hard difficulty, mirrored risk and coin reward, quick clock, endless wrapping and voluntary settlement passed")
