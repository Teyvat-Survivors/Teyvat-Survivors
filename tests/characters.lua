local Characters = require("game.characters")
local Run = require("game.run")
local Data = require("data.progress")
local Roster = require("data.characters")

local function near(actual, expected)
    assert(math.abs(actual - expected) < 1e-9, tostring(actual) .. " expected " .. tostring(expected))
end

local stage = {
    id = "character_test", duration_ticks = 1000, terminal_timeout_ticks = 1, terminal_kind = "fixture",
    build_rules = { choice_count = 32 },
    waves = {
        capacity = 4, spawnDistance = 8, despawnDistance = 40, contactIntervalTicks = 30, spawns = {},
        types = { fixture = { health = 1000, radius = 0.5, speed = 0, contactDamage = 0 } },
    },
}

local function grantLevels(run, to)
    local tally = 0
    for i = run.progress.level, to - 1 do
        tally = tally + Data.experience_to_next[i]
    end
    run.on_defeat({ id = 100, x = run.player.x, y = run.player.y, xp = tally })
    assert(Run.update(run, Run.step_seconds) == 1 and run.progress.level == to)
    assert(run.progress.choices, "character progression uses the usual upgrade pause")
end

do
    local unlocks = { paired_wayfinder = true, unwritten = true }
    local visible = Characters.list()
    local complete = Characters.list(unlocks)
    assert(#visible == #Roster - 2 and #complete == #Roster, "unlocks make hidden characters selectable")
    local seen = {}
    for _, option in ipairs(complete) do
        assert(not seen[option.id] and #option.label > 0)
        seen[option.id] = true
        local started = assert(Run.for_character(option.id, 42, stage, nil, unlocks))
        assert(started.character_id == option.id and started.weapons and started.player.health == started.player.max_health)
        assert(started.build.weapons[started.weapons.id] == 1)
    end
    local denied, reason = Run.for_character("unwritten", 42, stage)
    assert(not denied and reason == "locked_character")
    denied, reason = Run.for_character("typo", 42, stage)
    assert(not denied and reason == "unknown_character")
end

do
    local baseline = Run.new(1, stage, "frost_pulse")
    assert(not baseline.character_id and baseline.weapons.id == "frost_pulse" and baseline.player.speed == 6)
    assert(Run.restart(baseline).weapons.id == "frost_pulse")
    local guard = assert(Run.for_character("ridge_guard", 2, stage))
    assert(guard.weapons.id == "stone_ward" and guard.player.max_health == 125 and guard.player.armor == 2)
    assert(Run.update(guard, Run.step_seconds, 1) == 1 and guard.player.ward.charges > 0,
        "a defensive starter activates in the ordinary Run loop")
    near(guard.player.x, (6 * 0.86) * Run.step_seconds)

    grantLevels(guard, 3)
    assert(guard.player.armor == 2, "growth is absent before its threshold")
    while guard.progress.choices do
        local choice = guard.progress.choices
        assert(Run.choose(guard, choice.token, "weapon:wind_blade"))
    end
    grantLevels(guard, 4)
    assert(guard.player.armor == 3, "growth is applied on the real level transition")
    local capped = assert(Run.for_character("ridge_guard", 2, stage))
    grantLevels(capped, 11)
    assert(capped.player.armor == 5, "growth catches up across a multi-level gain and respects the step cap")
    assert(Characters.bonuses(capped.character, 99).armor == 5)
end

do
    local base = { speed = 7, max_health = 123, armor = 1, damage_multiplier = 1.2 }
    local run = assert(Run.for_character("willow_dancer", 13, stage, base))
    near(run.player.speed, 7.7)
    assert(run.player.max_health == 123 and run.player.armor == 1)
    near(run.weapon_modifiers.damage, 1.2)
    near(run.weapon_modifiers.projectile_speed, 1.15)
    grantLevels(run, 3)
    near(run.weapon_modifiers.damage, 1.2 * 1.065)
    assert(Run.choose(run, run.progress.choices.token, "passive:gust_seal"))
    near(run.weapon_modifiers.damage, 1.2 * 1.155)
    base.speed = 100
    local restarted = Run.restart(run)
    assert(restarted.character_id == run.character_id and restarted.weapons.id == "willow_return")
    assert(restarted.progress.level == 1 and next(restarted.build.passives) == nil)
    near(restarted.player.speed, 7.7)
    near(restarted.weapon_modifiers.damage, 1.2)
end

do
    local unlocks = { paired_wayfinder = true, unwritten = true }
    local dual = assert(Run.for_character("paired_wayfinder", 8, stage, nil, unlocks))
    assert(#dual.weapon_systems == 2 and dual.weapon_systems[1] == dual.weapons)
    assert(dual.weapons.id == "ridge_dart" and dual.weapon_systems[2].id == "dew_aura")
    assert(dual.build.weapons.ridge_dart == 1 and dual.build.weapons.dew_aura == 1)
    local target = { id = 5, x = 0.5, y = 0, radius = 0.6, health = 150, speed = 0, contactDamage = 0 }
    dual.enemies.active[1] = target
    Run.update(dual, Run.step_seconds)
    assert(target.health < 150 and dual.weapon_systems[1].next_fire_tick > 1 and dual.weapon_systems[2].next_fire_tick > 1,
        "both starting weapons fire and apply combat behavior")

    local original = assert(Run.for_character("unwritten", 1, stage, nil, unlocks))
    local replay = Run.restart(original)
    local newSeed = Run.restart(original, 20000)
    assert(original.weapons.id == replay.weapons.id and newSeed.weapons.id ~= replay.weapons.id)
    assert(replay.character_id == original.character_id and not Run.for_character("unwritten", 1, stage))
end

do
    local brief = {}
    for key, value in pairs(stage) do brief[key] = value end
    brief.duration_ticks = 2
    local survivor = assert(Run.for_character("echo_fugitive", 1, brief))
    Run.update(survivor, 0.1)
    assert(survivor.result.outcome == "finale_survived" and survivor.result.character == "echo_fugitive",
        "the ordinary settlement records character identity for future unlock conditions")
end

print("Lua character selection, normal starter attacks, growth caps, and seeded hidden loadouts passed")
