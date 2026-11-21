local Evolutions = require("game.evolutions")
local Progress = require("game.progress")
local Run = require("game.run")
local Weapons = require("game.weapons")
local catalog = require("data.weapons")
local passives = require("data.passives").items
local recipes = require("data.evolutions")
local step = 1 / 60

local function dummy(id, x, y)
    return { id = id, x = x, y = y or 0, radius = 0.1, health = 200 }
end

local function equip(run, id)
    local weapon = run.weapons.id == id and run.weapons or Weapons.new(id, function() return 0 end)
    if weapon ~= run.weapons then
        run.weapon_systems[#run.weapon_systems + 1] = weapon
    end
    weapon.level = Weapons.max_level(weapon)
    run.build.weapons[id] = weapon.level
    return weapon
end

local function contains(options, recipeId)
    for _, option in ipairs(options) do
        if option.recipe == recipeId then
            return true
        end
    end
    return false
end

local function currentChest(run)
    run.tick = run.stage.evolution.earliest_tick
    return { chest_type = "elite", dropped_tick = run.tick }
end

local function launch(run, weapon, targets)
    run.enemies.active = targets
    Weapons.step(weapon, run, step)
end

local function volley(count, damage, motion, speed)
    return function(run, weapon)
        launch(run, weapon, { dummy(1, 8) })
        assert(#weapon.projectiles == count)
        local shot = weapon.projectiles[1]
        assert(shot.damage == damage and shot.motion == motion and shot.speed == speed)
    end
end

local function hit(x, y, damage)
    return function(run, weapon)
        local target = dummy(1, x, y)
        launch(run, weapon, { target })
        assert(target.health == 200 - damage)
    end
end

local function field(anchor, radius, damage, x)
    return function(run, weapon)
        launch(run, weapon, { dummy(1, x or 1) })
        local result = assert(weapon.fields[1])
        assert(result.anchor == anchor and result.radius == radius and result.damage == damage)
    end
end

local function landing(damage, blastRadius, splashDamage)
    return function(run, weapon)
        local direct, splash = dummy(1, 4), dummy(2, 4, blastRadius - 0.1)
        launch(run, weapon, { direct, splash })
        assert(weapon.projectiles[1].motion == "lob" and weapon.projectiles[1].height > 0)
        for _ = 1, 30 do
            run.tick = run.tick + 1
            Weapons.step(weapon, run, step)
        end
        assert(direct.health == 200 - damage and math.abs(splash.health - 200 + splashDamage) < 1e-8)
    end
end

local function magnet(radius)
    return function(run, weapon)
        local near, beyond = { x = radius, y = 0 }, { x = radius + 0.1, y = 0 }
        run.progress.pickups = { near, beyond }
        launch(run, weapon, {})
        assert(near.attracted and not beyond.attracted)
    end
end

local checks = {
    gale_script = volley(1, 36, nil, 38),
    dawn_crescent = hit(4, 2, 43),
    silvery_sparks = volley(3, 19, nil, 54),
    ridge_volley = volley(3, 29, nil, 46),
    atlas_arc = landing(34, 3.6, 34 * 0.65),
    verdant_wings = volley(2, 23, "return", 33),
    jade_constellation = field("orbit", 1.35, 12, 4.9),
    comet_bloom = landing(31, 5, 31 * 0.90),
    rising_tide = field("player", 5.4, 6),
    ash_current = field(nil, 4, 11, 8),
    crystal_choir = function(run, weapon)
        launch(run, weapon, { dummy(1, 8) })
        local shot = assert(weapon.projectiles[1])
        assert(shot.motion == "rebound" and shot.remaining_bounces == 4 and shot.blast_chance == 1)
    end,
    petal_crown = volley(8, 14, nil, 32),
    high_noon = function(run, weapon)
        local regular, elite = dummy(1, 50), dummy(2, 50, 1)
        elite.isElite = true
        launch(run, weapon, { regular, elite })
        assert(regular.health == 0 and elite.health == 148)
    end,
    wandering_beacon = field("roam", 2.75, 15),
    gale_lattice = hit(11, 1.8, 34),
    dust_forge = function(run, weapon)
        launch(run, weapon, {})
        run.player.x = 4
        run.tick = run.tick + 1
        launch(run, weapon, {})
        assert(#weapon.fields == 0, "the upgraded trap still waits for the player to stop")
        local target = dummy(1, 1)
        run.tick = run.tick + 1
        launch(run, weapon, { target })
        local field = assert(weapon.fields[1])
        assert(field.x == 1 and field.damage == 45 and field.next_tick == run.tick + 9)
        run.tick = run.tick + 9
        launch(run, weapon, { target })
        assert(target.health == 155)
    end,
    winter_circuit = function(run, weapon)
        local target = dummy(1, 10)
        launch(run, weapon, { target })
        assert(target.slowFactor == 0 and target.slowUntilTick == run.tick + 34)
    end,
    mountain_vow = function(run, weapon)
        launch(run, weapon, {})
        assert(run.player.ward.charges == 3 and run.player.ward.expires_tick == run.tick + 181)
    end,
    echo_diadem = volley(4, 16, nil, 40),
    aurora_diadem = volley(7, 26, nil, 50),
    rime_confluence = field(nil, 4.8, 19, 8),
    prismatic_willow = volley(6, 21, "return", 43),
    cyclone_braid = hit(7, 2, 58),
    resonance_gift = magnet(21),
    amber_bloom_gift = field("orbit", 3.4, 16, 6.1),
}

local counts = { evolution = 0, union = 0, gift = 0 }
for _, recipe in ipairs(recipes) do
    local run = Run.new(19)
    local chest = currentChest(run)
    counts[recipe.kind] = counts[recipe.kind] + 1
    for _, id in ipairs(recipe.passives) do
        run.build.passives[id] = (recipe.passive_levels and recipe.passive_levels[id]) or passives[id].max_level
    end
    local ingredients = {}
    for index, id in ipairs(recipe.weapons) do
        ingredients[index] = equip(run, id)
    end

    local missing = ingredients[#ingredients]
    run.build.weapons[missing.id] = nil
    assert(not contains(Evolutions.options(run, chest), recipe.id) and not Evolutions.apply(run, chest, recipe.id),
        "missing ingredient must block " .. recipe.id)
    run.build.weapons[missing.id] = missing.level

    for _, id in ipairs(recipe.passives) do
        local rank = run.build.passives[id]
        run.build.passives[id] = rank - 1
        assert(not contains(Evolutions.options(run, chest), recipe.id) and not Evolutions.apply(run, chest, recipe.id),
            "missing catalyst rank must block " .. recipe.id)
        run.build.passives[id] = rank
    end

    local slots = #run.weapon_systems
    assert(contains(Evolutions.options(run, chest), recipe.id) and Evolutions.apply(run, chest, recipe.id),
        "valid recipe " .. recipe.id)
    assert(catalog[recipe.result].weight == 0 and run.build.weapons[recipe.result] == 1)
    assert(#run.weapon_systems == slots + 1 - (recipe.kind ~= "gift" and #recipe.weapons or 0))
    assert(not Evolutions.apply(run, chest, recipe.id), "each recipe must be one-time")
    local product
    for _, weapon in ipairs(run.weapon_systems) do
        if weapon.id == recipe.result then
            product = weapon
            break
        end
    end
    checks[recipe.id](run, assert(product))
end

assert(counts.evolution == 20 and counts.union == 3 and counts.gift == 2)

do
    local run = Run.new(7, nil, "needle_ring")
    equip(run, "needle_ring")
    local chest = currentChest(run)
    assert(Evolutions.apply(run, chest, "echo_diadem") and run.weapons.level == 1)
    assert(not Evolutions.apply(run, chest, "aurora_diadem"), "the first evolution must reach its own rank cap")
    run.build.rules.choice_count = 100
    Progress.drop(run.progress, { id = 1, x = 0, y = 0, xp = run.progress.xpNeeded })
    Progress.step(run.progress, run, step)
    local choice = run.progress.choices
    assert(Run.choose(run, choice.token, "weapon:echo_diadem") and run.weapons.level == 2,
        "evolved weapon ranks are earned through the normal owned item pool")
    assert(Evolutions.apply(run, chest, "aurora_diadem") and run.weapons.id == "aurora_diadem",
        "the second evolution uses the actual upgraded first evolution")
end

print("Lua evolution catalog: all 25 recipe gates and weapon effects, with a playable two-stage evolution, passed")
