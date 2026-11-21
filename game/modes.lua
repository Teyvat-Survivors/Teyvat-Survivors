local Modes = {}

local function flag(options, key)
    local value = options[key]
    assert(value == nil or type(value) == "boolean", "invalid mode flag: " .. key)
    return value == true
end

function Modes.resolve(options)
    assert(options == nil or type(options) == "table", "mode options must be a table")
    options = options or {}
    local difficulty = options.difficulty
    if difficulty == nil then difficulty = "normal" end
    assert(difficulty == "normal" or difficulty == "hard", "unknown difficulty")
    return {
        difficulty = difficulty,
        mirrored = flag(options, "mirrored"),
        quick = flag(options, "quick"),
        endless = flag(options, "endless"),
        limit_break = flag(options, "limit_break"),
    }
end

local function copy(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return result
end

local function quickTick(tick)
    assert(type(tick) == "number" and tick >= 1 and tick < math.huge and tick % 1 == 0, "invalid stage tick")
    return math.ceil(tick / 2)
end

function Modes.stage(source, mode)
    local hard = mode.difficulty == "hard"
    if not hard and not mode.mirrored and not mode.quick then return source end
    local stage = copy(source)
    stage.waves = copy(source.waves)
    stage.waves.enemyHealthMultiplier = (hard and 1.3 or 1) * (mode.mirrored and 1.15 or 1)
    stage.waves.enemyDamageMultiplier = (hard and 1.2 or 1) * (mode.mirrored and 1.1 or 1)
    stage.waves.mirrorHorizontal = mode.mirrored
    if mode.mirrored and source.bounds then
        local bounds = source.bounds
        stage.bounds = {
            min_x = -bounds.max_x, max_x = -bounds.min_x,
            min_y = bounds.min_y, max_y = bounds.max_y,
        }
    end
    if mode.quick then
        stage.duration_ticks = math.max(math.min(source.duration_ticks, 2), quickTick(source.duration_ticks))
        stage.terminal_timeout_ticks = quickTick(source.terminal_timeout_ticks)
        stage.waves.spawns = {}
        for i, wave in ipairs(source.waves.spawns) do
            local adjusted = copy(wave)
            adjusted.tick = quickTick(wave.tick)
            if wave.tick < source.duration_ticks then
                adjusted.tick = math.min(adjusted.tick, stage.duration_ticks - 1)
            else
                adjusted.tick = math.max(adjusted.tick, stage.duration_ticks)
            end
            stage.waves.spawns[i] = adjusted
        end
    end
    if source.features and (mode.mirrored or mode.quick) then
        stage.features = {}
        for i, feature in ipairs(source.features) do
            local adjusted = copy(feature)
            if mode.mirrored then adjusted.x = -feature.x end
            if mode.quick and feature.kind == "hazard" then
                adjusted.first_tick = quickTick(feature.first_tick)
                adjusted.interval_ticks = quickTick(feature.interval_ticks)
            end
            stage.features[i] = adjusted
        end
    end
    return stage
end

function Modes.pressure(cycle)
    return 1 + math.min(2, (cycle - 1) * 0.18)
end

function Modes.coinMultiplier(mode)
    return mode.mirrored and 1.5 or 1
end

return Modes
