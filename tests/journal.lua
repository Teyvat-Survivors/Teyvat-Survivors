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
assert(#achievements == 5)
for _, entry in ipairs(achievements) do
    assert(entry.earned)
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

print("Lua journal unlocks, achievements, collection, save compatibility, and receipt idempotency passed")
