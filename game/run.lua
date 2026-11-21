local Enemies = require("game.enemies")
local Weapons = require("game.weapons")
local Progress = require("game.progress")
local Loot = require("game.loot")
local Build = require("game.build")
local WeaponData = require("data.weapons")
local stages = require("data.stages")
local baseStats = require("data.powerups").base_stats

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

local function copyBaseStats(source)
    local result = {}
    for key, base in pairs(baseStats) do
        local value = source and source[key] or base
        assert(finite(value) and value > 0, "invalid profile modifier: " .. key)
        result[key] = value
    end
    return result
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
            coins = math.floor(run.loot.coins * run.base_stats.coin_multiplier),
        }
        emit(run, "finished")
    end
end

function Run.new(seed, stage, weapon_id, profile_stats)
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
    local base = copyBaseStats(profile_stats)
    local run = {
        base_stats = base,
        stage = stage,
        kills = 0,
        seed = seed,
        random_state = seed,
        tick = 0,
        accumulator = 0,
        paused = false,
        events = {},
        bounds = { min_x = -WORLD_EDGE, max_x = WORLD_EDGE, min_y = -WORLD_EDGE, max_y = WORLD_EDGE },
        player = {
            x = 0, y = 0, radius = 0.42, speed = base.speed, armor = 0,
            facing_x = 1, facing_y = 0,
            health = base.max_health, max_health = base.max_health,
        },
    }
    local function randomUnit()
        return Run.random(run)
    end
    run.enemies = Enemies.new(stage.waves, randomUnit)
    run.weapons = Weapons.new(weapon_id, randomUnit)
    run.weapon_systems = { run.weapons }
    run.build = Build.new(randomUnit, WeaponData, run.weapons.id, stage.build_rules)
    run.weapon_modifiers = Build.stats(run.build)
    run.weapon_modifiers.damage = base.damage_multiplier
    run.progress = Progress.new()
    local lootSeed = (seed * 16807) % SEED_MODULUS
    run.loot = Loot.new(function()
        lootSeed = (lootSeed * 48271) % SEED_MODULUS
        return (lootSeed - 1) / (SEED_MODULUS - 1)
    end)
    run.on_defeat = function(enemy)
        run.kills = run.kills + 1
        if enemy.id == run.terminal_id then
            finish(run, "finale_defeated")
        else
            Progress.drop(run.progress, enemy)
            Loot.defeat(run.loot, enemy)
        end
    end
    return run
end

function Run.restart(run, seed)
    if seed == nil then seed = run.seed end
    return Run.new(seed, run.stage, run.weapons.id, run.base_stats)
end

local function applyWeaponRank(run, id, rank)
    for _, weapon in ipairs(run.weapon_systems) do
        if weapon.id == id then
            weapon.level = rank
            return
        end
    end
    local weapon = Weapons.new(id, function() return Run.random(run) end)
    run.weapon_systems[#run.weapon_systems + 1] = weapon
end

local function applyPassives(run)
    local stats = Build.stats(run.build)
    local player = run.player
    local maxHealth = run.base_stats.max_health + stats.max_health_bonus
    player.speed = run.base_stats.speed * stats.speed
    player.armor = stats.armor
    player.health = math.min(maxHealth, player.health + (maxHealth - player.max_health))
    player.max_health = maxHealth
    stats.damage = stats.damage * run.base_stats.damage_multiplier
    run.weapon_modifiers = stats
end

function Run.choose(run, token, option)
    if run.result then
        return false
    end
    local action = Build.choose(run.build, token, option)
    if not action then
        return false
    end
    if action.kind == "weapon" then
        applyWeaponRank(run, action.id, action.level)
    elseif action.kind == "passive" then
        applyPassives(run)
    else
        local player = run.player
        player.health = math.min(player.max_health, player.health + action.amount)
    end
    Progress.settleChoice(run.progress, run)
    return true
end

function Run.reroll(run, token)
    if run.result then
        return false
    end
    local choice = Build.reroll(run.build, token)
    if not choice then
        return false
    end
    run.progress.choices = choice
    return true
end

function Run.skip(run, token)
    if run.result then
        return false
    end
    local action = Build.skip(run.build, token)
    if not action then
        return false
    end
    Progress.settleChoice(run.progress, run, action.experience_fraction)
    return true
end

function Run.banish(run, token, option)
    if run.result or not Build.banish(run.build, token, option) then
        return false
    end
    Progress.settleChoice(run.progress, run)
    return true
end

function Run.choose_treasure(run, token, option)
    if run.result or not Loot.choose(run.loot, run, token, option) then
        return false
    end
    if option == "upgrade" then
        run.build.weapons[run.weapons.id] = run.weapons.level
    end
    return true
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
    if run.result or run.paused or Progress.hasChoice(run.progress) or Loot.hasChoice(run.loot) then
        return 0
    end
    local x, y = movement(move_x, move_y)
    local accumulated = run.accumulator + math.min(seconds, MAX_FRAME_TIME)
    local steps = math.floor((accumulated + 1e-10) / STEP)
    run.accumulator = math.max(0, accumulated - steps * STEP)
    for completed = 1, steps do
        run.tick = run.tick + 1
        local player = run.player
        if x ~= 0 or y ~= 0 then
            player.facing_x, player.facing_y = x, y
        end
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
        for _, weapon in ipairs(run.weapon_systems) do
            Weapons.step(weapon, run, STEP, run.on_defeat)
            if run.result then break end
        end
        Enemies.compact(run.enemies)
        if run.result then
            return completed
        end
        if run.terminal_id and run.tick >= run.stage.duration_ticks + run.stage.terminal_timeout_ticks then
            finish(run, "finale_survived")
            return completed
        end
        run.loot_upgrade_slots_full = #run.weapon_systems >= run.build.rules.weapon_slots
        Loot.step(run.loot, run)
        if Loot.hasChoice(run.loot) then
            run.accumulator = 0
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
