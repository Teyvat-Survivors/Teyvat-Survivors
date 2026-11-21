local Enemies = require("game.enemies")
local Weapons = require("game.weapons")
local Progress = require("game.progress")
local Perks = require("game.perks")
local Loot = require("game.loot")
local Build = require("game.build")
local Characters = require("game.characters")
local Modes = require("game.modes")
local WeaponData = require("data.weapons")
local stages = require("data.stages")
local baseStats = require("data.powerups").base_stats

local Run = {}

local STEP = 1 / 60
local MAX_FRAME_TIME = 0.25
local DEFAULT_BOUNDS = { min_x = -96, max_x = 96, min_y = -96, max_y = 96 }
local SEED_MODULUS = 2147483647

Run.step_seconds = STEP

local function finite(value)
    return type(value) == "number" and value > -math.huge and value < math.huge
end

local function constrain(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function stageBounds(bounds)
    bounds = bounds or DEFAULT_BOUNDS
    assert(finite(bounds.min_x) and finite(bounds.max_x) and bounds.min_x < bounds.max_x and
        finite(bounds.min_y) and finite(bounds.max_y) and bounds.min_y < bounds.max_y, "invalid stage bounds")
    return { min_x = bounds.min_x, max_x = bounds.max_x, min_y = bounds.min_y, max_y = bounds.max_y }
end

local function stageFeatures(definitions)
    local features = {}
    for i, definition in ipairs(definitions or {}) do
        assert(finite(definition.x) and finite(definition.y) and finite(definition.radius) and
            definition.radius > 0 and finite(definition.amount) and definition.amount > 0, "invalid stage feature")
        if definition.kind == "hazard" then
            assert(finite(definition.first_tick) and definition.first_tick >= 1 and definition.first_tick % 1 == 0 and
                finite(definition.interval_ticks) and definition.interval_ticks >= 1 and
                definition.interval_ticks % 1 == 0, "invalid stage hazard timing")
        else
            assert(definition.kind == "healing", "unknown stage feature")
        end
        features[i] = { definition = definition, spent = false, next_tick = definition.first_tick }
    end
    return features
end

local function stepStageFeatures(run)
    local player = run.player
    for _, feature in ipairs(run.stage_features) do
        local definition = feature.definition
        local due = definition.kind == "hazard" and run.tick == feature.next_tick
        if due then
            feature.next_tick = run.tick + definition.interval_ticks
        end
        if due or (definition.kind == "healing" and not feature.spent and player.health < player.max_health) then
            local x, y = player.x - definition.x, player.y - definition.y
            if x * x + y * y <= (player.radius + definition.radius) ^ 2 then
                if due then
                    player.health = math.max(0, player.health - definition.amount)
                    if player.health == 0 then return end
                else
                    player.health = math.min(player.max_health, player.health + definition.amount)
                    feature.spent = true
                end
            end
        end
    end
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
    local armor = source and source.armor or 0
    assert(finite(armor) and armor >= 0, "invalid base armor")
    result.armor = armor
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
            character = run.character_id,
            tick = run.tick,
            kills = run.kills,
            level = run.progress.level,
            coins = math.floor(run.loot.coins * run.base_stats.coin_multiplier * Modes.coinMultiplier(run.mode)),
            cycles_completed = run.mode.endless and math.floor(run.tick / run.stage.duration_ticks) or nil,
        }
        emit(run, "finished")
    end
end

local function projectStats(run)
    local stats = Build.stats(run.build)
    if run.character then
        for name, bonus in pairs(Characters.bonuses(run.character, run.progress.level)) do
            stats[name] = stats[name] + bonus
        end
    end
    local player, base = run.player, run.base_stats
    local maxHealth = math.max(1, base.max_health + stats.max_health_bonus)
    player.speed = base.speed * stats.speed
    player.armor = base.armor + stats.armor
    player.health = math.max(0, math.min(maxHealth, player.health + maxHealth - player.max_health))
    player.max_health = maxHealth
    stats.damage = stats.damage * base.damage_multiplier
    run.base_weapon_modifiers, run.weapon_modifiers = stats, stats
end

local function newRun(seed, stage, weapon_id, base_stats, character, options)
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
    local source_stage = stage
    local mode = Modes.resolve(options)
    stage = Modes.stage(source_stage, mode)
    local base = copyBaseStats(base_stats)
    local bounds = stageBounds(stage.bounds)
    local run = {
        base_stats = base,
        stage = stage,
        source_stage = source_stage,
        mode = mode,
        cycle = mode.endless and 1 or nil,
        cycle_tick = mode.endless and 0 or nil,
        character = character,
        character_id = character and character.id,
        starting_weapon_id = weapon_id,
        kills = 0,
        seed = seed,
        random_state = seed,
        tick = 0,
        accumulator = 0,
        paused = false,
        events = {},
        bounds = bounds,
        stage_features = stageFeatures(stage.features),
        player = {
            x = constrain(0, bounds.min_x, bounds.max_x),
            y = constrain(0, bounds.min_y, bounds.max_y),
            radius = 0.42, speed = base.speed, armor = base.armor,
            facing_x = 1, facing_y = 0,
            health = base.max_health, max_health = base.max_health,
        },
    }
    local function randomUnit()
        return Run.random(run)
    end
    run.enemies = Enemies.new(stage.waves, randomUnit)
    local starters = character and Characters.loadout(character, randomUnit) or { weapon_id or "wind_blade" }
    run.build = Build.new(randomUnit, WeaponData, starters, stage.build_rules)
    run.weapon_systems = {}
    for i, id in ipairs(starters) do
        run.weapon_systems[i] = Weapons.new(id, randomUnit)
    end
    run.weapons = run.weapon_systems[1]
    run.evolutions = {}
    run.progress = Progress.new()
    projectStats(run)
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
            Loot.defeat(run.loot, enemy, run.tick)
            if run.perk_event then run.perk_event("kill") end
        end
    end
    return run
end

function Run.new(seed, stage, weapon_id, base_stats, options)
    return newRun(seed, stage, weapon_id, base_stats, nil, options)
end

function Run.for_character(id, seed, stage, base_stats, unlocked, options)
    local character, reason = Characters.select(id, unlocked)
    if not character then
        return nil, reason
    end
    return newRun(seed, stage, nil, base_stats, character, options)
end

function Run.restart(run, seed)
    if seed == nil then seed = run.seed end
    local fresh = newRun(seed, run.source_stage, run.starting_weapon_id, run.base_stats, run.character, run.mode)
    if run.perks then
        Run.enable_perks(fresh, {
            unlocked = run.perks.unlocked,
            max_owned = run.perks.maxOwned,
            choice_count = run.perks.choiceCount,
        })
    end
    return fresh
end

function Run.finish_endless(run)
    if run.result or not run.mode.endless then return false end
    finish(run, "retired")
    return true
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
        projectStats(run)
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
    local previousLevel = run.progress.level
    Progress.settleChoice(run.progress, run, action.experience_fraction)
    if run.progress.level ~= previousLevel then
        projectStats(run)
    end
    return true
end

function Run.banish(run, token, option)
    if run.result or not Build.banish(run.build, token, option) then
        return false
    end
    Progress.settleChoice(run.progress, run)
    return true
end

function Run.enable_perks(run, options)
    if run.tick ~= 0 or run.perks then return false end
    run.perks = Perks.new(function() return Run.random(run) end, options)
    run.perk_stats = {}
    run.perk_event = function(kind, item)
        local actions = Perks.handle(run.perks, { kind = kind, item = item, tick = run.tick })
        for _, action in ipairs(actions or {}) do
            local player = run.player
            if action.kind == "heal" and player.health > 0 then
                player.health = math.min(player.max_health, player.health + action.amount)
            elseif action.kind == "revive" and player.health == 0 then
                player.health = player.max_health * action.health_fraction
                emit(run, "revived")
            end
        end
    end
    Perks.offer(run.perks, "opening")
    return true
end

function Run.choose_perk(run, token, card_id)
    return not run.result and run.perks ~= nil and Perks.choose(run.perks, token, card_id, run.tick)
end

function Run.skip_perk(run, token)
    return not run.result and run.perks ~= nil and Perks.skip(run.perks, token)
end

function Run.choose_treasure(run, token, option)
    local choice = run.loot.choices
    if run.result or not Loot.choose(run.loot, run, token, option) then
        return false
    end
    if option == "upgrade" then
        run.build.weapons[run.weapons.id] = run.weapons.level
    end
    if run.perks and choice.chest.chest_type == "perk" then
        Perks.offer(run.perks, "chest", choice.chest.enemyId)
    end
    return true
end

local function settleDefeat(run)
    if run.player.health == 0 then
        if run.perk_event then run.perk_event("lethal") end
        if run.player.health == 0 then
            finish(run, "defeated")
            return true
        end
    end
    return false
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
    if run.result or run.paused or Progress.hasChoice(run.progress) or Loot.hasChoice(run.loot)
        or (run.perks and run.perks.choice) then
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
        local bounds = run.bounds
        player.x = constrain(player.x + x * player.speed * STEP, bounds.min_x, bounds.max_x)
        player.y = constrain(player.y + y * player.speed * STEP, bounds.min_y, bounds.max_y)
        stepStageFeatures(run)
        if settleDefeat(run) then
            return completed
        end
        if run.mode.endless then
            run.cycle_tick = run.cycle_tick + 1
            if run.cycle_tick > run.stage.duration_ticks then
                run.cycle = run.cycle + 1
                run.cycle_tick = 1
                Enemies.begin_cycle(run.enemies, run.tick - 1, Modes.pressure(run.cycle))
                emit(run, "cycle_started")
            end
        elseif run.tick == run.stage.duration_ticks then
            local terminal = Enemies.begin_finale(run.enemies, player, run.stage.terminal_kind)
            run.terminal_id = terminal.id
            emit(run, "finale_started")
        end
        Enemies.step(run.enemies, run, STEP)
        if settleDefeat(run) then
            return completed
        end
        if run.perks then
            run.weapon_modifiers = Perks.stats(
                run.perks, run.base_weapon_modifiers, run.tick, x ~= 0 or y ~= 0, run.perk_stats)
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
        local previousLevel = run.progress.level
        Progress.step(run.progress, run, STEP)
        if run.progress.level ~= previousLevel then
            projectStats(run)
        end
        if Progress.hasChoice(run.progress) then
            run.accumulator = 0
            return completed
        end
    end
    return steps
end

return Run
