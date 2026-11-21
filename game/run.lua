local Enemies = require("game.enemies")
local Weapons = require("game.weapons")
local Progress = require("game.progress")
local stages = require("data.stages")

local Run = {}

local STEP = 1 / 60
local MAX_FRAME_TIME = 0.25
local WORLD_EDGE = 96
local SEED_MODULUS = 2147483647

Run.step_seconds = STEP

local function finite(value)
    return type(value) == "number" and value > -math.huge and value < math.huge
end

local function constrain(value)
    return math.max(-WORLD_EDGE, math.min(WORLD_EDGE, value))
end

local function movement(x, y)
    x, y = x + 0.0, y + 0.0
    local largest = math.max(math.abs(x), math.abs(y))
    if largest > 1 then
        x, y = x / largest, y / largest
    end
    local length = math.sqrt(x * x + y * y)
    if length > 1 then
        return x / length, y / length
    end
    return x, y
end

local function emit(run, kind)
    run.events[#run.events + 1] = { kind = kind, tick = run.tick }
end

local function finish(run, outcome)
    if not run.result then
        run.result = {
            outcome = outcome,
            stage = run.stage.id,
            tick = run.tick,
            kills = run.kills,
            level = run.progress.level,
        }
        emit(run, "finished")
    end
end

function Run.new(seed, stage, weapon_id)
    if seed == nil then
        seed = 1
    end
    assert(
        type(seed) == "number" and seed >= 1 and seed < SEED_MODULUS and seed % 1 == 0,
        "run seed must be an integer from 1 to 2147483646"
    )
    stage = stage or stages.windward
    assert(stage.duration_ticks >= 1 and stage.duration_ticks % 1 == 0, "invalid stage duration")
    assert(stage.terminal_timeout_ticks >= 1 and stage.terminal_timeout_ticks % 1 == 0, "invalid finale duration")
    assert(stage.waves.capacity > 0 and stage.waves.types[stage.terminal_kind], "invalid finale enemy")
    local run = {
        stage = stage,
        kills = 0,
        seed = seed,
        random_state = seed,
        tick = 0,
        accumulator = 0,
        paused = false,
        events = {},
        player = { x = 0, y = 0, speed = 6, radius = 0.42, health = 100, max_health = 100 },
    }
    run.enemies = Enemies.new(stage.waves, function()
        return Run.random(run)
    end)
    run.weapons = Weapons.new(weapon_id, function()
        return Run.random(run)
    end)
    run.progress = Progress.new(function()
        return Run.random(run)
    end)
    run.on_defeat = function(enemy)
        run.kills = run.kills + 1
        if enemy.id == run.terminal_id then
            finish(run, "finale_defeated")
        else
            Progress.drop(run.progress, enemy)
        end
    end
    return run
end

function Run.restart(run, seed)
    if seed == nil then seed = run.seed end
    return Run.new(seed, run.stage, run.weapons.id)
end

function Run.choose(run, token, option)
    if run.result then
        return false
    end
    return Progress.choose(run.progress, run, token, option)
end

function Run.random(run)
    run.random_state = (run.random_state * 48271) % SEED_MODULUS
    return (run.random_state - 1) / (SEED_MODULUS - 1)
end

function Run.set_paused(run, paused)
    assert(type(paused) == "boolean", "pause state must be a boolean")
    if run.paused ~= paused then
        run.paused = paused
        emit(run, paused and "paused" or "resumed")
    end
end

function Run.take_events(run)
    local events = run.events
    run.events = {}
    return events
end

function Run.update(run, seconds, move_x, move_y)
    if move_x == nil then move_x = 0 end
    if move_y == nil then move_y = 0 end
    assert(finite(seconds) and seconds >= 0, "frame time must be finite and nonnegative")
    assert(finite(move_x) and finite(move_y), "movement must be finite")
    if run.result or run.paused or Progress.hasChoice(run.progress) then
        return 0
    end
    local x, y = movement(move_x, move_y)
    local accumulated = run.accumulator + math.min(seconds, MAX_FRAME_TIME)
    local steps = math.floor((accumulated + 1e-10) / STEP)
    run.accumulator = math.max(0, accumulated - steps * STEP)
    for completed = 1, steps do
        run.tick = run.tick + 1
        local player = run.player
        player.x = constrain(player.x + x * player.speed * STEP)
        player.y = constrain(player.y + y * player.speed * STEP)
        if run.tick == run.stage.duration_ticks then
            local terminal = Enemies.begin_finale(run.enemies, player, run.stage.terminal_kind)
            run.terminal_id = terminal.id
            emit(run, "finale_started")
        end
        Enemies.step(run.enemies, run, STEP)
        if player.health == 0 then
            finish(run, "defeated")
            return completed
        end
        Weapons.step(run.weapons, run, STEP, run.on_defeat)
        Enemies.compact(run.enemies)
        if run.result then
            return completed
        end
        if run.terminal_id and run.tick >= run.stage.duration_ticks + run.stage.terminal_timeout_ticks then
            finish(run, "finale_survived")
            return completed
        end
        Progress.step(run.progress, run, STEP)
        if Progress.hasChoice(run.progress) then
            run.accumulator = 0
            return completed
        end
    end
    return steps
end

return Run
