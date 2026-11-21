local Build = require("game.build")
local Loot = require("game.loot")
local Run = require("game.run")
local Weapons = require("game.weapons")
local passiveData = require("data.passives").items
local weaponData = require("data.weapons")

local function stage(slots)
    return {
        id = "evolution-test",
        duration_ticks = 240,
        terminal_timeout_ticks = 30,
        terminal_kind = "sentinel",
        evolution = { earliest_tick = 20, chest_types = { elite = true } },
        build_rules = { weapon_slots = slots or 4 },
        waves = {
            capacity = 4, spawnDistance = 0, despawnDistance = 20, contactIntervalTicks = 1,
            types = {
                drift = { radius = 0.6, speed = 0, health = 30, contactDamage = 0 },
                sentinel = { radius = 0.9, speed = 0, health = 1, contactDamage = 0, elite = true },
                sealed = { radius = 0.9, speed = 0, health = 1, contactDamage = 0, treasure_kind = "sealed" },
            },
            spawns = {},
        },
    }
end

local function equip(run, id)
    local weapon
    for _, candidate in ipairs(run.weapon_systems) do
        if candidate.id == id then
            weapon = candidate
            break
        end
    end
    if not weapon then
        weapon = Weapons.new(id, run.build.randomUnit)
        run.weapon_systems[#run.weapon_systems + 1] = weapon
    end
    weapon.level = Weapons.max_level(weapon)
    run.build.weapons[id] = weapon.level
    return weapon
end

local function option(choice, id)
    for _, candidate in ipairs(choice.options) do
        if candidate.id == id then
            return candidate
        end
    end
end

local function openChest(run, id, dropTick, openTick, chestType)
    local chest = Loot.defeat(run.loot, {
        id = id, kind = "sentinel", health = 0, x = 0, y = 0, treasureKind = chestType,
    }, dropTick)
    assert(chest and chest.kind == "treasure")
    run.tick = openTick
    Loot.step(run.loot, run)
    return run.loot.choices
end

local gale, union, gift = "recipe:gale_script", "recipe:rime_confluence", "recipe:resonance_gift"

do
    local run = Run.new(7, stage())
    equip(run, "wind_blade")
    run.build.passives.gust_seal = passiveData.gust_seal.max_level

    local early = openChest(run, 1, 19, 45)
    assert(not option(early, gale), "waiting cannot turn an early chest into an evolution source")
    assert(Run.choose_treasure(run, early.token, "coins"))
    local sealed = openChest(run, 2, 45, 45, "sealed")
    assert(not option(sealed, gale), "the wrong chest type cannot evolve")
    assert(Run.choose_treasure(run, sealed.token, "coins"))

    run.stage.evolution = nil
    local disabled = openChest(run, 3, 45, 45)
    assert(not option(disabled, gale), "stages must explicitly opt in to recipes")
    assert(Run.choose_treasure(run, disabled.token, "coins"))
    run.stage.evolution = { earliest_tick = 20, chest_types = { elite = true } }

    run.build.passives.gust_seal = nil
    local missing = openChest(run, 4, 45, 45)
    assert(not option(missing, gale), "required passive cannot be missing")
    assert(Run.choose_treasure(run, missing.token, "coins"))
    run.build.passives.gust_seal = 1
    local short = openChest(run, 5, 45, 45)
    assert(not option(short, gale), "required passive must reach its configured maximum")
    assert(Run.choose_treasure(run, short.token, "coins"))
    run.build.passives.gust_seal = passiveData.gust_seal.max_level

    local max = run.weapons.level
    run.weapons.level = max - 1
    local mismatch = openChest(run, 6, 45, 45)
    assert(not option(mismatch, gale), "stale inventory metadata cannot claim an unequipped rank")
    assert(Run.choose_treasure(run, mismatch.token, "coins"))
    run.weapons.level = max

    run.build.banished["weapon:gale_script"] = true
    local banished = openChest(run, 7, 45, 45)
    assert(not option(banished, gale), "a banished result is not offered")
    assert(Run.choose_treasure(run, banished.token, "coins"))
    run.build.banished["weapon:gale_script"] = nil

    local offered = openChest(run, 8, 45, 45)
    assert(option(offered, gale) and not option(offered, union), "a single maxed weapon is eligible only for its standard recipe")
    assert(not Run.choose_treasure(run, offered.token + 1, gale), "stale chest token cannot change inventory")
    run.build.passives.gust_seal = 1
    assert(not Run.choose_treasure(run, offered.token, gale), "prerequisites are rechecked on selection")
    assert(run.weapons.id == "wind_blade" and run.build.weapons.wind_blade == max and not run.evolutions.gale_script
        and run.loot.choices == offered, "a rejected recipe leaves inventory and the choice intact")
    assert(Run.choose_treasure(run, offered.token, "coins"), "currency remains a valid fallback")
end

do
    local run = Run.new(19, stage(3))
    local starter = equip(run, "wind_blade")
    local frost = equip(run, "frost_pulse")
    local ward = equip(run, "stone_ward")
    run.build.passives.gust_seal = passiveData.gust_seal.max_level
    local choice = openChest(run, 1, 20, 20)
    assert(option(choice, gale) and option(choice, union), "multiple eligible recipes share the original chest token")
    assert(Run.choose_treasure(run, choice.token, union))
    assert(run.weapons.id == "rime_confluence" and run.weapons ~= starter and run.weapon_systems[1] == run.weapons,
        "consuming the starter atomically updates the combat alias")
    assert(#run.weapon_systems == 2 and run.weapon_systems[2] == ward and run.weapon_systems[2] ~= frost,
        "the union consumes two weapons, returns one and preserves other live systems")
    assert(not run.build.weapons.wind_blade and not run.build.weapons.frost_pulse and run.build.weapons.rime_confluence == 1,
        "the build and combat systems agree")
    assert(run.build.banished["weapon:wind_blade"] and run.build.banished["weapon:frost_pulse"]
        and run.build.passives.gust_seal == passiveData.gust_seal.max_level and run.build.remaining.banish == 1,
        "consumed ingredients cannot reenter the pool, but passives and manual banish budget are preserved")
    assert(not Run.choose_treasure(run, choice.token, gale) and not Run.choose_treasure(run, choice.token, union),
        "one chest can pay exactly one of its offered rewards")

    local later = openChest(run, 2, 22, 22)
    assert(not option(later, union) and not option(later, gale), "consumed recipes and their ingredients are not offered again")
    Run.choose_treasure(run, later.token, "coins")
end

do
    local full = Run.new(42, stage(1), "echo_bell")
    equip(full, "echo_bell")
    full.build.passives.tuning_fork = passiveData.tuning_fork.max_level
    assert(not option(openChest(full, 1, 22, 22), gift), "a gift cannot exceed the weapon-slot cap")

    local space = Run.new(42, stage(2), "echo_bell")
    local starter = equip(space, "echo_bell")
    space.build.passives.tuning_fork = passiveData.tuning_fork.max_level
    local options = openChest(space, 1, 22, 22)
    assert(option(options, gift) and Run.choose_treasure(space, options.token, gift))
    assert(space.weapons == starter and space.weapon_systems[1] == starter and #space.weapon_systems == 2
        and space.build.weapons.echo_bell == starter.level and space.build.weapons.resonance_gift == 1,
        "the gift occupies one empty slot without replacing prerequisites")
    assert(not space.build.banished["weapon:echo_bell"] and space.evolutions.resonance_gift)
    space.build.weapons.resonance_gift = nil
    space.weapon_systems[2] = nil
    assert(not option(openChest(space, 2, 30, 30), gift), "a spent recipe cannot recur even when its result later leaves")
end

do
    local catalog = Build.new(function() return 0 end, weaponData, "wind_blade",
        { weapon_slots = 30, passive_slots = 30, choice_count = 100 })
    local choice = Build.offer(catalog)
    for _, recipe in ipairs({ "gale_script", "rime_confluence", "resonance_gift" }) do
        assert(not option(choice, "weapon:" .. recipe), "evolution-only results do not enter the ordinary draw pool")
        for _, candidate in ipairs(choice.options) do
            assert(candidate.id ~= recipe)
        end
    end
end

do
    local fixture = stage(1)
    fixture.evolution.earliest_tick = 3
    fixture.waves.spawns = {
        { tick = 1, kind = "sealed", count = 1 },
        { tick = 3, kind = "sentinel", count = 1 },
        { tick = 4, kind = "drift", count = 1 },
    }
    local run = Run.new(10, fixture)
    equip(run, "wind_blade")
    run.build.passives.gust_seal = passiveData.gust_seal.max_level
    local step = Run.step_seconds
    assert(Run.update(run, step) == 1 and run.kills == 1, "the sealed chest is dropped by a real kill")
    assert(run.loot.choices.chest.chest_type == "sealed" and not option(run.loot.choices, gale))
    assert(Run.choose_treasure(run, run.loot.choices.token, "coins"))
    run.weapons.next_fire_tick = 3
    assert(Run.update(run, step * 2) == 2 and run.kills == 2, "the scheduled elite is defeated at the eligible tick")
    local eligible = run.loot.choices
    assert(eligible.chest.dropped_tick == 3 and option(eligible, gale))
    assert(Run.update(run, step * 3) == 0 and run.tick == 3, "an evolution offer uses ordinary treasure pause")
    assert(Run.choose_treasure(run, eligible.token, gale) and run.kills == 2 and run.weapons.id == "gale_script")
    while run.progress.choices do
        local choice = run.progress.choices
        assert(Run.choose(run, choice.token, choice.options[1].key))
    end
    assert(Run.update(run, step) == 1 and run.kills == 3, "the evolved weapon deals lethal damage through the normal attack loop")

    local fresh = Run.restart(run)
    assert(fresh.seed == run.seed and fresh.stage == fixture and fresh.weapons.id == "wind_blade"
        and fresh.weapons.level == 1 and #fresh.weapon_systems == 1 and not fresh.evolutions.gale_script
        and not fresh.build.banished["weapon:wind_blade"], "restart uses the original starter and resets all recipe state")
end

print("Lua evolution, union, gift, chest eligibility, attack replacement and restart passed")
