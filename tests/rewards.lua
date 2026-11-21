local Build = require("game.build")
local Loot = require("game.loot")
local Profile = require("game.profile")
local Run = require("game.run")
local Stages = require("data.stages")
local Weapons = require("game.weapons")
local catalog = require("data.weapons")

local function contains(choice, id)
    for _, option in ipairs(choice.options) do
        if option.id == id then return true end
    end
    return false
end

local function offer(run, id)
    local enemy = {
        id = id, health = 0, x = 0, y = 0, kind = "armory_warden",
        treasureKind = Stages.windward.waves.types.armory_warden.treasure_kind,
    }
    local drop = assert(Loot.defeat(run.loot, enemy, run.tick))
    assert(drop.chest_type == "armory" and not Loot.defeat(run.loot, enemy, run.tick))
    Loot.step(run.loot, run)
    return assert(run.loot.choices)
end

local profile = Profile.load()
assert(not Profile.unlocks(profile).weapons.lantern_fanfare)
assert(not pcall(Run.new, 1, nil, "lantern_fanfare"))

do
    local run = Run.new(7)
    local choice = offer(run, 1)
    assert(#choice.options == 4 and contains(choice, "coins") and not contains(choice, "upgrade"))
    assert(not contains(choice, "armory:wind_blade") and not contains(choice, "armory:lantern_fanfare"))
    assert(not contains(choice, "armory:gale_script") and not contains(choice, "armory:resonance_gift"))
    local grant = choice.options[2]
    assert(not Run.choose_treasure(run, choice.token + 1, grant.id))
    assert(not Run.choose_treasure(run, choice.token, "armory:lantern_fanfare"))
    assert(#run.weapon_systems == 1 and run.build.weapons[grant.armory_weapon] == nil)
    run.build.banished["weapon:" .. grant.armory_weapon] = true
    assert(not Run.choose_treasure(run, choice.token, grant.id))
    assert(run.loot.choices == choice and #run.weapon_systems == 1)

    grant = choice.options[3]
    run.build.rules.weapon_slots = 1
    assert(not Run.choose_treasure(run, choice.token, grant.id))
    run.build.rules.weapon_slots = 2
    assert(Run.choose_treasure(run, choice.token, grant.id))
    assert(#run.weapon_systems == 2 and run.weapons == run.weapon_systems[1])
    assert(run.weapon_systems[2].id == grant.armory_weapon and run.weapon_systems[2].level == 1)
    assert(run.build.weapons[grant.armory_weapon] == 1)
    assert(not Run.choose_treasure(run, choice.token, grant.id))

    local next_choice = offer(run, 2)
    assert(next_choice.token > choice.token and #next_choice.options == 1 and contains(next_choice, "coins"))
    assert(not Run.choose_treasure(run, choice.token, "coins"))
    assert(Run.choose_treasure(run, next_choice.token, "coins"))
    assert(run.loot.coins == 18)
end

do
    local id = assert(Profile.begin_run(profile))
    assert(Profile.settle(profile, id, { outcome = "defeated", stage = "windward", coins = 0 }))
    assert(not Profile.unlocks(profile).weapons.lantern_fanfare)
    id = assert(Profile.begin_run(profile))
    assert(Profile.settle(profile, id, { outcome = "finale_survived", stage = "windward", coins = 0 }))
    local old = Profile.export(profile)
    profile = Profile.load(old)
    local flags = Profile.unlocks(profile).weapons
    assert(flags.lantern_fanfare)
    assert(not Profile.settle(profile, id, { outcome = "finale_survived", stage = "windward", coins = 5 }))
    local run = Run.new(12, nil, nil, nil, { quick = true, weapon_unlocks = flags })
    flags.lantern_fanfare = nil
    run = Run.restart(run)
    assert(run.mode.quick)
    local probe = Build.new(function() return 0 end, catalog, "wind_blade", nil, { lantern_fanfare = true })
    for _, item in ipairs(probe.catalog) do
        if item.id ~= "lantern_fanfare" then probe.banished[item.key] = true end
    end
    assert(Build.offer(probe).options[1].kind == "reward" and catalog.lantern_fanfare.weight == 0)
    local choice = offer(run, 1)
    assert(choice.options[2].id == "armory:lantern_fanfare")
    assert(Run.choose_treasure(run, choice.token, choice.options[2].id))
    assert(run.build.weapons.lantern_fanfare == 1 and run.weapon_systems[2].id == "lantern_fanfare")
    assert(not contains(offer(run, 2), "armory:lantern_fanfare"))

    local target = { id = 1, x = 4, y = 0, health = 100, radius = 0.4 }
    local weapon = Weapons.new("lantern_fanfare")
    Weapons.step(weapon, {
        tick = 1, player = { x = 0, y = 0, health = 100, max_health = 100 },
        enemies = { active = { target } },
    }, Run.step_seconds)
    assert(target.health == 73 and target.x > 4)
end

do
    local count = 0
    for _, wave in ipairs(Stages.windward.waves.spawns) do
        if wave.kind == "armory_warden" then count = count + wave.count end
    end
    assert(count == 2)
    local typeWithChest = Stages.windward.waves.types.armory_warden
    local stage = {
        id = "armory_fixture", duration_ticks = 100, terminal_timeout_ticks = 10,
        terminal_kind = "armory_warden",
        waves = {
            capacity = 4, spawnDistance = 0, despawnDistance = 20, contactIntervalTicks = 3,
            types = {
                armory_warden = {
                    health = 1, radius = typeWithChest.radius, speed = 0, contactDamage = 0,
                    elite = typeWithChest.elite, treasure_kind = typeWithChest.treasure_kind,
                },
            },
            spawns = { { kind = "armory_warden", tick = 1, count = 1 } },
        },
    }
    local run = Run.new(8, stage, "frost_pulse")
    Run.update(run, Run.step_seconds)
    assert(run.kills == 1 and run.loot.choices.chest.chest_type == "armory")
    local choice = run.loot.choices
    assert(Run.choose_treasure(run, choice.token, choice.options[2].id))
    assert(#run.weapon_systems == 2)
end

print("Lua armory slot, banish and stale tokens, reward unlock, replay and celebration pulse passed")
