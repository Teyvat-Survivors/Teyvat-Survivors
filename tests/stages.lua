local Run = require("game.run")
local stages = require("data.stages")

local function fixture(features, bounds)
    return {
        id = "test_terrain",
        duration_ticks = 1000,
        terminal_kind = "drift",
        terminal_timeout_ticks = 10,
        waves = {
            capacity = 1, spawnDistance = 4, despawnDistance = 8, contactIntervalTicks = 5,
            types = { drift = { radius = 1, speed = 1, health = 3, contactDamage = 0 } },
            spawns = {},
        },
        features = features,
        bounds = bounds,
    }
end

local function advance(run, steps, dx, dy)
    for _ = 1, steps do
        Run.update(run, Run.step_seconds, dx, dy)
    end
end

do
    local bounds = { min_x = -1, max_x = 2, min_y = -2, max_y = 1 }
    local stage = fixture({}, bounds)
    local run = Run.new(11, stage)
    advance(run, 60, 1, 1)
    assert(run.player.x == 2 and run.player.y == 1)
    advance(run, 120, -1, -1)
    assert(run.player.x == -1 and run.player.y == -2)
    local reopened = Run.restart(run)
    assert(reopened.stage == stage and reopened.player.x == 0 and reopened.player.y == 0)
    local offset = Run.new(11, fixture({}, { min_x = 2, max_x = 3, min_y = -4, max_y = -2 }))
    assert(offset.player.x == 2 and offset.player.y == -2, "starting position is clamped to an offset region")
    assert(not pcall(Run.new, 11, fixture({}, { min_x = 2, max_x = 1, min_y = -2, max_y = 1 })))
end

do
    local stage = fixture({
        { kind = "healing", x = 0, y = 0, radius = 1, amount = 40 },
        { kind = "healing", x = 10, y = 0, radius = 1, amount = 40 },
    })
    local run = Run.new(5, stage)
    advance(run, 1)
    assert(run.player.health == 100 and not run.stage_features[1].spent)
    run.player.health = 75
    advance(run, 1)
    assert(run.player.health == 100 and run.stage_features[1].spent and not run.stage_features[2].spent)
    run.player.health = 30
    advance(run, 1)
    assert(run.player.health == 30, "an already consumed spring does not heal again")
    advance(run, 100, 1, 0)
    assert(run.player.health == 70 and run.stage_features[2].spent)
    assert(stage.features[1].spent == nil, "the immutable feature definition gains no run state")
    local reopened = Run.restart(run, 7)
    assert(not reopened.stage_features[1].spent and not reopened.stage_features[2].spent)
end

do
    local stage = fixture({
        { kind = "hazard", x = 0, y = 0, radius = 1, amount = 30, first_tick = 3, interval_ticks = 4 },
    })
    local run = Run.new(5, stage)
    advance(run, 2)
    assert(run.player.health == 100 and run.stage_features[1].next_tick == 3)
    Run.set_paused(run, true)
    advance(run, 5)
    assert(run.tick == 2 and run.player.health == 100)
    Run.set_paused(run, false)
    run.player.x = 10
    advance(run, 1)
    assert(run.player.health == 100 and run.stage_features[1].next_tick == 7, "out-of-range pulses preserve cadence")
    run.player.x = 0
    advance(run, 3)
    assert(run.player.health == 100)
    advance(run, 1)
    assert(run.player.health == 70 and run.stage_features[1].next_tick == 11)
    run.player.health = 5
    advance(run, 4)
    assert(run.player.health == 0 and run.result.outcome == "defeated" and run.result.tick == 11)
    assert(Run.update(run, 0.25) == 0)
    assert(Run.restart(run).stage_features[1].next_tick == 3)
end

local function accelerate(run, x_radius, y_radius)
    local frames = math.ceil((run.stage.duration_ticks + run.stage.terminal_timeout_ticks) / 15) + 500
    for _ = 1, frames do
        if run.result then return end
        local choice = run.progress.choices
        if run.loot and run.loot.choices then
            assert(Run.choose_treasure(run, run.loot.choices.token, "coins"))
        elseif choice then
            local selected = choice.options[1].key or choice.options[1].id
            for _, option in ipairs(choice.options) do
                local id = option.key or option.id
                if id == "weapon" or id == "weapon:wind_blade" then selected = id end
            end
            assert(Run.choose(run, choice.token, selected))
        else
            local angle = run.tick * 0.002
            local dx = x_radius * math.cos(angle) - run.player.x
            local dy = y_radius * math.sin(angle) - run.player.y
            Run.update(run, 0.25, dx, dy)
        end
    end
end

assert(stages.windward.duration_ticks == 108000 and not stages.windward.features)
assert(stages.moon_reeds.waves.spawns[1].tick == 360 and stages.moon_reeds.waves.spawns[2].kind == "gale_runner")
assert(stages.cinder_ridge.waves.spawns[1].tick == 600 and stages.cinder_ridge.waves.spawns[2].kind == "ember_ram")
for _, profile in ipairs({
    { stage = stages.windward, route_x = 41, route_y = 41, seed = 31 },
    { stage = stages.moon_reeds, route_x = 48, route_y = 28, seed = 47 },
    { stage = stages.cinder_ridge, route_x = 27, route_y = 18, seed = 71 },
}) do
    local run = Run.new(profile.seed, profile.stage)
    accelerate(run, profile.route_x, profile.route_y)
    assert(run.result and run.terminal_id and run.result.tick >= profile.stage.duration_ticks,
        ("%s must reach its finale (%d ticks, %d health)"):format(profile.stage.id, run.tick, run.player.health))
    assert(run.result.stage == profile.stage.id and run.enemies.totalSpawned > 50 and run.result.kills > 20)
    assert(run.result.outcome == "finale_survived" or run.result.outcome == "finale_defeated")
    print(("Lua stage %s completed at tick %d (%s, %d defeats)"):format(
        profile.stage.id, run.result.tick, run.result.outcome, run.result.kills))
end
