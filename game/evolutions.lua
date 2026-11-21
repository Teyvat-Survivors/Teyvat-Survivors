local recipes = require("data.evolutions")
local passives = require("data.passives").items
local weaponData = require("data.weapons")
local Weapons = require("game.weapons")

local Evolutions = {}

local function allowedByStage(run, chest)
    local rule = run.stage and run.stage.evolution
    return rule and chest and chest.dropped_tick and chest.dropped_tick >= rule.earliest_tick
        and rule.chest_types[chest.chest_type] == true
end

local function eligible(run, recipe)
    local build = run.build
    if run.evolutions[recipe.id] or build.weapons[recipe.result] or build.banished["weapon:" .. recipe.result] then
        return false
    end

    local consumed = recipe.kind == "gift" and 0 or #recipe.weapons
    if #run.weapon_systems + 1 - consumed > build.rules.weapon_slots then
        return false
    end

    for _, id in ipairs(recipe.passives) do
        local minimum = (recipe.passive_levels and recipe.passive_levels[id]) or passives[id].max_level
        if (build.passives[id] or 0) < minimum then
            return false
        end
    end

    local live = {}
    for _, system in ipairs(run.weapon_systems) do
        live[system.id] = system
    end
    for _, id in ipairs(recipe.weapons) do
        local system = live[id]
        local max = system and Weapons.max_level(system)
        if not max or system.level ~= max or build.weapons[id] ~= max then
            return false
        end
    end
    return true
end

function Evolutions.options(run, chest)
    local options = {}
    if allowedByStage(run, chest) then
        for _, recipe in ipairs(recipes) do
            if eligible(run, recipe) then
                options[#options + 1] = {
                    id = "recipe:" .. recipe.id,
                    recipe = recipe.id,
                    label = weaponData[recipe.result].label,
                    kind = recipe.kind,
                }
            end
        end
    end
    return options
end

function Evolutions.apply(run, chest, recipeId)
    if not allowedByStage(run, chest) then
        return false
    end

    local recipe
    for _, option in ipairs(recipes) do
        if option.id == recipeId then
            recipe = option
            break
        end
    end
    if not recipe or not eligible(run, recipe) then
        return false
    end

    -- Make the replacement before modifying the live inventory.
    local build = run.build
    local replacement = Weapons.new(recipe.result, build.randomUnit)
    local systems = run.weapon_systems
    local remove = {}
    if recipe.kind ~= "gift" then
        for _, id in ipairs(recipe.weapons) do
            remove[id] = true
            build.weapons[id] = nil
            if build.limit_ranks then build.limit_ranks[id] = nil end
            build.banished["weapon:" .. id] = true
        end
    end

    local retained, inserted = 0, false
    for index = 1, #systems do
        local weapon = systems[index]
        if remove[weapon.id] then
            if not inserted then
                retained = retained + 1
                systems[retained] = replacement
                inserted = true
            end
            if run.weapons == weapon then
                run.weapons = replacement
            end
        else
            retained = retained + 1
            systems[retained] = weapon
        end
    end
    if not inserted then
        retained = retained + 1
        systems[retained] = replacement
    end
    for index = #systems, retained + 1, -1 do
        systems[index] = nil
    end

    build.weapons[recipe.result] = replacement.level
    run.evolutions[recipe.id] = true
    return true
end

return Evolutions
