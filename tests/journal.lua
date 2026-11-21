local Profile = require("game.profile")
local Characters = require("game.characters")
local Run = require("game.run")

local function hasOption(options, id)
    for _, option in ipairs(options) do
        if option.id == id then return true end
    end
    return false
end

local function finish(profile, stage, outcome, weapons, character)
    local id = assert(Profile.begin_run(profile))
    assert(Profile.settle(profile, id, {
        stage = stage, outcome = outcome, coins = 5, weapons = weapons, character = character,
    }))
    return id
end

local profile = Profile.load()
local flags = Profile.unlocks(profile)
assert(flags.stages.windward and not flags.stages.moon_reeds and not flags.stages.cinder_ridge)
assert(next(flags.perks) == nil and not hasOption(Characters.list(flags.characters), "paired_wayfinder"))

local first = finish(profile, "windward", "defeated", { wind_blade = true }, "wind_scout")
assert(Profile.unlocks(profile).perks.reed_stride and not Profile.unlocks(profile).stages.moon_reeds)
local collection = Profile.collection(profile)
assert(collection.stages.windward and collection.weapons.wind_blade and collection.characters.wind_scout)
collection.weapons.frost_pulse = true
assert(not Profile.collection(profile).weapons.frost_pulse)

local old = Profile.export(profile)
old.journal = nil
assert(Profile.unlocks(Profile.load(old)).perks.reed_stride)
assert(not Profile.unlocks(Profile.load(old)).stages.moon_reeds)
profile = Profile.load(Profile.export(profile))
assert(not Profile.settle(profile, first, {
    stage = "windward", outcome = "finale_defeated", coins = 5, weapons = { frost_pulse = true },
}))
assert(profile.coins == 5 and not Profile.collection(profile).weapons.frost_pulse)
assert(not Profile.unlocks(profile).stages.moon_reeds)

local invalid = assert(Profile.begin_run(profile))
local ok, reason = Profile.settle(profile, invalid, {
    stage = "windward", outcome = "finale_defeated", coins = 5, weapons = { unknown_weapon = true },
})
assert(not ok and reason == "invalid_result" and profile.active_run_id == invalid and profile.coins == 5)
assert(not Profile.unlocks(profile).stages.moon_reeds)
assert(Profile.abandon_run(profile, invalid))

finish(profile, "moon_reeds", "finale_defeated", nil, "wind_scout")
assert(not Profile.unlocks(profile).stages.cinder_ridge, "skipping a stage cannot award its unlock")
finish(profile, "windward", "finale_survived", { stone_ward = true, frost_pulse = true }, "ridge_guard")
flags = Profile.unlocks(profile)
assert(flags.stages.moon_reeds and not flags.stages.cinder_ridge)
assert(flags.perks.tidal_dial and flags.perks.cinder_refrain)
assert(hasOption(Characters.list(flags.characters), "paired_wayfinder"))
assert(Run.for_character("paired_wayfinder", 1, nil, nil, flags.characters))
assert(not Run.for_character("unwritten", 1, nil, nil, flags.characters))
local run = Run.new(1)
assert(Run.enable_perks(run, { unlocked = flags.perks }))
assert(run.perks.choice and hasOption(run.perks.choice.options, "tidal_dial"))
assert(not hasOption(run.perks.choice.options, "spring_mark"))

finish(profile, "moon_reeds", "finale_defeated", { ridge_dart = true }, "paired_wayfinder")
finish(profile, "cinder_ridge", "finale_defeated", { ridge_dart = true }, "paired_wayfinder")
local saved = Profile.export(profile)
profile = Profile.load(saved)
saved.journal.earned.windward_clear = nil
saved.journal.collection.weapons.ridge_dart = nil
assert(Profile.collection(profile).weapons.ridge_dart)
flags = Profile.unlocks(profile)
assert(flags.stages.cinder_ridge and flags.characters.unwritten and flags.perks.spring_mark)
local achievements = Profile.achievements(profile)
assert(#achievements == #require("data.journal").milestones)
for index, entry in ipairs(achievements) do
    if index <= 5 then assert(entry.earned) end
    entry.earned = false
end
flags.perks.spring_mark = nil
assert(Profile.unlocks(profile).perks.spring_mark)

local broken = Profile.export(profile)
broken.journal.collection.weapons.wind_blade = "yes"
assert(not pcall(Profile.load, broken))

local stage = {
    id = "receipt_fixture",
    duration_ticks = 60,
    terminal_kind = "target",
    terminal_timeout_ticks = 20,
    waves = {
        capacity = 4, spawnDistance = 0, despawnDistance = 20, contactIntervalTicks = 3,
        types = { target = { health = 9999, radius = 1, speed = 0, contactDamage = 9999 } },
        spawns = { { kind = "target", tick = 5, count = 1 } },
    },
}
run = assert(Run.for_character("paired_wayfinder", 2, stage, nil, Profile.unlocks(profile).characters))
-- A prior union consumed both weapons. The inventory stores the finished union.
run.build.weapons = { rime_confluence = 1 }
run.evolutions.rime_confluence = true
Run.update(run, 0.25)
assert(run.result and run.result.weapons.rime_confluence and run.result.character == "paired_wayfinder")
assert(run.result.weapons.wind_blade and run.result.weapons.frost_pulse)
local finished = assert(Profile.begin_run(profile))
assert(Profile.settle(profile, finished, run.result))
assert(Profile.collection(profile).weapons.rime_confluence and not Profile.collection(profile).stages.receipt_fixture)

local function stageVictory(profile, stageId, characterId, level)
    local stage = {
        id = stageId, duration_ticks = 8, terminal_kind = "target", terminal_timeout_ticks = 3,
        build_rules = { choice_count = 32 },
        waves = {
            capacity = 2, spawnDistance = 7, despawnDistance = 20, contactIntervalTicks = 4,
            types = { target = { health = 9999, radius = 1, speed = 0, contactDamage = 0 } },
            spawns = {},
        },
    }
    local id = assert(Profile.begin_run(profile))
    local unlocks = Profile.unlocks(profile)
    local trial = assert(Run.for_character(characterId, 17, stage, Profile.stats(profile), unlocks.characters, {
        weapon_unlocks = unlocks.weapons,
    }))
    if level and level > 1 then
        local total = 0
        for i = 1, level - 1 do total = total + require("data.progress").experience_to_next[i] end
        trial.on_defeat({ id = 40, x = 0, y = 0, xp = total })
        Run.update(trial, Run.step_seconds)
        while trial.progress.choices do
            local choice = trial.progress.choices
            assert(Run.choose(trial, choice.token, choice.options[1].key))
        end
    end
    Run.update(trial, 0.25)
    assert(trial.result and trial.result.outcome == "finale_survived" and trial.result.character == characterId)
    assert(Profile.settle(profile, id, trial.result))
end

do
    local profile = Profile.load()
    stageVictory(profile, "windward", "frost_scribe")
    assert(not Profile.unlocks(profile).characters.storm_watcher, "windward victory requires the specific scout")
    stageVictory(profile, "windward", "wind_scout")
    local flags = Profile.unlocks(profile)
    assert(flags.characters.storm_watcher and flags.characters.prism_keeper)
    local lanternRole = assert(Run.for_character("lantern_attendant", 17, nil, nil, flags.characters, {
        weapon_unlocks = flags.weapons,
    }))
    assert(lanternRole.weapons.id == "lantern_fanfare")
    stageVictory(profile, "moon_reeds", "ridge_guard")
    assert(Profile.unlocks(profile).characters.moon_navigator)
    stageVictory(profile, "cinder_ridge", "sky_keeper", 7)
    assert(not Profile.unlocks(profile).characters.far_shore_traveller, "a lower-level victory does not meet the gate")
    stageVictory(profile, "cinder_ridge", "sky_keeper", 8)
    local saved = Profile.export(profile)
    profile = Profile.load(saved)
    flags = Profile.unlocks(profile)
    assert(flags.characters.far_shore_traveller and flags.characters.resonance_dancer)
    assert(flags.characters.cloud_cartographer and Profile.collection(profile).characters.sky_keeper)
end

do
    local saved = Profile.export(Profile.load())
    local roster = require("data.characters")
    local discovery = saved.journal.collection
    for i = 1, 7 do discovery.characters[roster[i].id] = true end
    discovery.weapons = {
        wind_blade = true, frost_pulse = true, ember_field = true, ridge_dart = true,
        star_spark = true, petal_fan = true, stone_lob = true, echo_shard = true,
        willow_return = true, dew_aura = true,
    }
    local profile = Profile.load(saved)
    assert(Profile.unlocks(profile).characters.comet_keeper)
    assert(not Profile.unlocks(profile).characters.map_weaver, "weapon discoveries alone cannot unlock the mixed gate")
    stageVictory(profile, "windward", roster[8].id)
    profile = Profile.load(Profile.export(profile))
    local flags = Profile.unlocks(profile)
    assert(flags.characters.map_weaver and flags.characters.afterglow and flags.characters.quiet_meridian)
end

do
    local roster, registered = require("data.characters"), {}
    for _, milestone in ipairs(require("data.journal").milestones) do
        for id in pairs(milestone.grants.characters or {}) do registered[id] = true end
    end
    for _, definition in ipairs(roster) do
        assert(not definition.unlock or registered[definition.unlock], "locked character needs a reachable journal grant")
    end
    local unknown = Profile.load()
    local id = assert(Profile.begin_run(unknown))
    local ok, reason = Profile.settle(unknown, id, {
        stage = "cinder_ridge", outcome = "finale_survived", level = "8", coins = 0,
    })
    assert(not ok and reason == "invalid_result" and unknown.active_run_id == id)
end

print("Lua journal unlocks, achievements, collection, save compatibility, and receipt idempotency passed")
