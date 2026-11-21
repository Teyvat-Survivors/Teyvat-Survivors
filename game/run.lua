local Enemies = require("game.enemies")
local Weapons = require("game.weapons")
local Progress = require("game.progress")
local waves = require("data.waves")

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

function Run.new(seed)
    if seed == nil then
        seed = 1
    end
    assert(
        type(seed) == "number" and seed >= 1 and seed < SEED_MODULUS and seed % 1 == 0,
        "run seed must be an integer from 1 to 2147483646"
    )
    local run = {
        seed = seed,
        random_state = seed,
        tick = 0,
        accumulator = 0,
        paused = false,
        events = {},
        player = { x = 0, y = 0, speed = 6, radius = 0.42, health = 100, max_health = 100 },
    }
    run.enemies = Enemies.new(waves, function()
        return Run.random(run)
    end)
    run.weapons = Weapons.new()
    run.progress = Progress.new(function()
        return Run.random(run)
    end)
    run.on_defeat = function(enemy)
        Progress.drop(run.progress, enemy)
    end
    return run
end

function Run.choose(run, token, option)
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
        run.events[#run.events + 1] = { kind = paused and "paused" or "resumed", tick = run.tick }
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
    if run.paused or Progress.hasChoice(run.progress) then
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
        Enemies.step(run.enemies, run, STEP)
        Weapons.step(run.weapons, run, STEP, run.on_defeat)
        Enemies.compact(run.enemies)
        Progress.step(run.progress, run, STEP)
        if Progress.hasChoice(run.progress) then
            run.accumulator = 0
            return completed
        end
    end
    return steps
end

return Run
