local Run = require("game.run")
local Progress = require("game.progress")
local Data = require("data.progress")
local Passives = require("data.passives")
local WeaponData = require("data.weapons")

local function newRun(seed, rules)
    local fixture = {
        id = "progress_test",
        duration_ticks = 1000,
        terminal_kind = "fixture",
        terminal_timeout_ticks = 20,
        build_rules = rules or { choice_count = 30 },
        waves = {
            capacity = 4,
            spawnDistance = 8,
            despawnDistance = 40,
            contactIntervalTicks = 30,
            spawns = {},
            types = { fixture = { health = 100, radius = 0.5, speed = 0, contactDamage = 6 } },
        },
    }
    return Run.new(seed or 1, fixture)
end

local function drop(run, id, x, xp)
    return Progress.drop(run.progress, { id = id, x = x or 0, y = 0, xp = xp })
end

local function collect(run, value)
    drop(run, 100, 0, value)
    Progress.step(run.progress, run, 0.05)
end

local function optionKeys(choice)
    local keys, seen = {}, {}
    for i, option in ipairs(choice.options) do
        assert(not seen[option.key], "a choice cannot repeat a candidate")
        seen[option.key] = true
        keys[i] = option.key
    end
    return seen, table.concat(keys, ",")
end

local function choose(run, key)
    assert(Run.choose(run, run.progress.choices.token, key), "expected to select " .. key)
end

local function near(actual, expected)
    return math.abs(actual - expected) < 1e-9
end

do
    local run = newRun()
    local state = run.progress
    local source = { id = 1, x = Data.magnet_radius + 1, y = 0, xp = 3 }
    local gem = Progress.drop(state, source)
    source.x, source.y, source.id, source.xp = 0, 20, 99, 20
    assert(gem.x == Data.magnet_radius + 1 and gem.y == 0 and gem.enemyId == 1 and gem.value == 3,
        "pooled enemy reuse must not alter an existing gem")
    Progress.step(state, run, 0.05)
    assert(gem.x == Data.magnet_radius + 1 and not gem.attracted and state.xp == 0,
        "the gem is still outside magnet range")
    run.player.x = 1.5
    Progress.step(state, run, 0.05)
    assert(gem.attracted and gem.x == Data.magnet_radius + 1 - Data.magnet_speed * 0.05 and #state.pickups == 1,
        "a nearby gem moves towards the player at the configured speed")
    run.player.x = -1
    Progress.step(state, run, 1)
    assert(#state.pickups == 0 and state.xp == 3, "an attracted gem stays targeted and is collected only once")
    assert(not drop(run, 2, 0, 0), "zero-experience defeats do not make gems")
    Progress.step(state, run, 1)
    assert(state.xp == 3, "expired gems cannot be collected twice")
end

do
    local run = newRun()
    local state = run.progress
    run.player.health = 45
    local before = state.xpNeeded - 1
    collect(run, before)
    assert(state.level == 1 and state.xp == before and not Progress.hasChoice(state),
        "experience below the first threshold does not level up")
    assert(drop(run, 1) and drop(run, 2, 0, Data.experience_to_next[2] + 1))
    assert(Run.update(run, Run.step_seconds * 1.5) == 1 and run.tick == 1)
    assert(state.level == 3 and state.xp == Data.experience_per_enemy and state.pending == 2,
        "one tick can collect multiple gems and retain overflow")
    local firstChoice = state.choices
    assert(optionKeys(firstChoice)["passive:amber_cloak"])

    local nextGem = drop(run, 3, Data.magnet_radius / 2, 3)
    assert(Run.update(run, 1) == 0 and run.tick == 1)
    assert(not nextGem.attracted and state.xp == Data.experience_per_enemy,
        "the whole battle and gem updates pause while the player chooses")
    assert(not Run.choose(run, firstChoice.token, "missing"), "a missing option has no effect")
    assert(not Run.choose(run, firstChoice.token + 1, "passive:amber_cloak"), "a mismatched token has no effect")
    assert(state.choices == firstChoice and state.pending == 2 and run.player.health == 45,
        "invalid choices cannot consume a pending level or mutate the player")
    choose(run, "passive:amber_cloak")
    local armor = Passives.items.amber_cloak.per_level
    assert(run.player.health == 45 + armor.max_health_bonus and run.player.max_health == 100 + armor.max_health_bonus)
    assert(run.player.armor == armor.armor)
    local secondChoice = state.choices
    assert(state.pending == 1 and secondChoice.token > firstChoice.token, "each queued choice has a fresh token")
    assert(not Run.choose(run, firstChoice.token, "passive:amber_cloak"), "a duplicate tap cannot choose the next level")
    assert(Run.update(run, 1) == 0 and run.tick == 1, "a queued decision keeps the simulation paused")
    choose(run, "passive:sprout_tea")
    local tea = Passives.items.sprout_tea.per_level
    assert(near(run.player.speed, 6 * (1 + tea.speed)) and state.pending == 0 and not Progress.hasChoice(state))
    local x = run.player.x
    assert(Run.update(run, Run.step_seconds, 1, 0) == 1)
    assert(near(run.player.x - x, 6 * (1 + tea.speed) * Run.step_seconds))
    Progress.step(state, run, 1)
    assert(state.xp == Data.experience_per_enemy + 3, "gem pickups resume after the last pending choice")
end

do
    local first, replay = newRun(19), newRun(19)
    for _ = 1, 3 do
        collect(first, first.progress.xpNeeded)
        collect(replay, replay.progress.xpNeeded)
        local a, b = first.progress.choices, replay.progress.choices
        local _, keysA = optionKeys(a)
        local _, keysB = optionKeys(b)
        assert(a.token == b.token and keysA == keysB, "seeded replays see the same option order")
        choose(first, "passive:sprout_tea")
        choose(replay, "passive:sprout_tea")
    end
end

local function damage(run, contact)
    local enemy = { id = 1, x = 0.5, y = 0, radius = 0.6, health = 100, speed = 0, contactDamage = contact or 0 }
    run.enemies.active[1] = enemy
    Run.update(run, Run.step_seconds)
    return 100 - enemy.health
end

do
    local baseline, grown = newRun(), newRun()
    collect(grown, grown.progress.xpNeeded)
    choose(grown, "weapon:wind_blade")
    local levelOneDamage, levelTwoDamage = damage(baseline), damage(grown)
    assert(grown.weapons.level == 2 and grown.build.weapons.wind_blade == 2 and levelTwoDamage > levelOneDamage,
        "a chosen weapon upgrade must strengthen subsequent real projectile damage")
    assert(levelOneDamage == WeaponData.wind_blade.levels[1].damage)
    assert(levelTwoDamage == WeaponData.wind_blade.levels[2].damage)
end

do
    local run = newRun()
    collect(run, run.progress.xpNeeded)
    choose(run, "passive:gust_seal")
    collect(run, run.progress.xpNeeded)
    choose(run, "passive:amber_cloak")
    collect(run, run.progress.xpNeeded)
    choose(run, "weapon:frost_pulse")
    assert(run.weapon_systems[1] == run.weapons and #run.weapon_systems == 2)
    assert(run.weapon_systems[2].id == "frost_pulse" and run.build.weapons.frost_pulse == 1)
    local expected = (WeaponData.wind_blade.levels[1].damage + WeaponData.frost_pulse.levels[1].damage)
        * (1 + Passives.items.gust_seal.per_level.damage)
    assert(near(damage(run, 6), expected), "both equipped weapons use the active passive damage bonus")
    assert(run.player.health == run.player.max_health - (6 - Passives.items.amber_cloak.per_level.armor),
        "passive armor reduces actual enemy contact damage")
    assert(run.weapon_systems[2].next_fire_tick > run.tick)
end

do
    local run = newRun()
    collect(run, run.progress.xpNeeded)
    choose(run, "passive:tuning_fork")
    collect(run, run.progress.xpNeeded)
    choose(run, "passive:dawn_book")
    local gem = drop(run, 2, Data.magnet_radius + 0.2, 5)
    assert(not gem.attracted)
    Run.update(run, Run.step_seconds)
    assert(gem.attracted, "the equipped passive extends real gem magnet radius")
    Progress.step(run.progress, run, 1)
    assert(near(run.progress.xp, 5 * (1 + Passives.items.dawn_book.per_level.experience)),
        "the equipped experience passive affects actual collected gems")
end

do
    local run = newRun(7, { choice_count = 3 })
    local state = run.progress
    collect(run, state.xpNeeded + Data.experience_to_next[2])
    local old = state.choices.token
    assert(Run.reroll(run, old) and state.choices.token > old and state.pending == 2)
    assert(not Run.skip(run, old), "rerolled token cannot act on the replacement menu")
    assert(Run.skip(run, state.choices.token) and state.pending == 1)
    assert(near(state.xp, state.xpNeeded * Passives.rules.skip_experience_fraction))
    local option = state.choices.options[1].key
    local token = state.choices.token
    assert(Run.banish(run, token, option) and run.build.banished[option] and not state.choices)
    assert(not Run.banish(run, token, option) and state.pending == 0)
end

do
    local run = newRun(1, { passive_slots = 0, weapon_slots = 1 })
    local state = run.progress
    local total = 0
    for _, threshold in ipairs(Data.experience_to_next) do
        total = total + threshold
    end

    drop(run, 1, Data.magnet_radius + 1, 12)
    collect(run, total + 20)
    assert(state.level == #Data.experience_to_next + 1 and state.xpNeeded == nil and state.xp == 0,
        "experience saturates at maximum level and drops its remainder")
    assert(not drop(run, 2) and #state.pickups == 0, "max-level runs discard and stop spawning gems")
    for _ = 2, #WeaponData.wind_blade.levels do
        choose(run, "weapon:wind_blade")
    end
    assert(state.choices.options[1].key == "reward:heal", "a capped weapon leaves only the empty-pool fallback")
    run.player.health = 30
    choose(run, "reward:heal")
    assert(run.player.health == 30 + Passives.rules.fallback_heal)
    while state.choices do
        choose(run, "reward:heal")
    end
    assert(run.player.health <= run.player.max_health and state.pending == 0, "each queued reward settles once")
end

print("Lua experience, gem attraction, queued choices, passive stats, and multi-weapon growth passed")
