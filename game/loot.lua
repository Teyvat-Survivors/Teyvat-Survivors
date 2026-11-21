local Data = require("data.loot")
local Weapons = require("game.weapons")
local Build = require("game.build")
local Evolutions = require("game.evolutions")

local Loot = {}
local totalWeight = 0

for _, drop in ipairs(Data.drop_weights) do
    totalWeight = totalWeight + drop.weight
end

function Loot.new(randomUnit)
    assert(type(randomUnit) == "function", "loot requires the run's random source")
    return {
        randomUnit = randomUnit,
        pickups = {},
        coins = 0,
        choiceToken = 0,
        -- Enemy tables are pooled. The ID distinguishes their current lifetime.
        rewarded = setmetatable({}, { __mode = "k" }),
    }
end

local function roll(system)
    local fraction = system.randomUnit()
    assert(type(fraction) == "number" and fraction >= 0 and fraction < 1,
        "random source must return a value in [0, 1)")
    local cursor = fraction * totalWeight
    for _, drop in ipairs(Data.drop_weights) do
        cursor = cursor - drop.weight
        if cursor < 0 then
            return drop.kind
        end
    end
    return Data.drop_weights[#Data.drop_weights].kind
end

function Loot.defeat(system, enemy, tick)
    if enemy.health ~= 0 or system.rewarded[enemy] == enemy.id then
        return nil
    end
    system.rewarded[enemy] = enemy.id

    local chestType = enemy.treasureKind or ((enemy.isElite or Data.treasure_sources[enemy.kind]) and "elite")
    local kind = chestType and "treasure" or roll(system)
    if kind == "none" then
        return nil
    end

    local item = { kind = kind, x = enemy.x, y = enemy.y, enemyId = enemy.id }
    if chestType then
        item.chest_type, item.dropped_tick = chestType, tick
    end
    system.pickups[#system.pickups + 1] = item
    return item
end

local function canUpgrade(run)
    return not run.loot_upgrade_slots_full and run.weapons.level < Weapons.max_level(run.weapons)
end

local function offerTreasure(system, run, chest)
    local options = {
        { id = "coins", label = "领取风砂币", amount = Data.treasure_coin_value },
    }
    if chest.chest_type == "armory" then
        for _, weapon in ipairs(Build.armory_options(run.build, Data.armory_choice_count)) do
            options[#options + 1] = { id = "armory:" .. weapon.id, label = weapon.label, armory_weapon = weapon.id }
        end
    else
        if canUpgrade(run) then
            options[#options + 1] = { id = "upgrade", label = "强化当前武器" }
        end
        for _, recipe in ipairs(Evolutions.options(run, chest)) do
            options[#options + 1] = recipe
        end
    end
    system.choiceToken = system.choiceToken + 1
    system.choices = { token = system.choiceToken, options = options, chest = chest }
end

local function collect(system, run, item)
    local player = run.player
    if item.kind == "coin" then
        system.coins = system.coins + Data.coin_value
        if run.perk_event then run.perk_event("pickup", "coin") end
    elseif item.kind == "healing" then
        local multiplier = math.max(0, player.healing_multiplier or 1)
        player.health = math.min(player.max_health, player.health + Data.healing_value * multiplier)
    elseif item.kind == "magnet" then
        for _, gem in ipairs(run.progress.pickups) do
            gem.attracted = true
        end
    else
        offerTreasure(system, run, item)
    end
end

function Loot.hasChoice(system)
    return system.choices ~= nil
end

function Loot.step(system, run)
    local player = run.player
    if player.health <= 0 or Loot.hasChoice(system) then
        return
    end

    local pickups = system.pickups
    local radiusSquared = (player.radius + Data.pickup_radius) ^ 2
    local count, retained = #pickups, 0
    for i = 1, count do
        local item = pickups[i]
        local dx, dy = item.x - player.x, item.y - player.y
        if dx * dx + dy * dy <= radiusSquared and not Loot.hasChoice(system) then
            collect(system, run, item)
        else
            retained = retained + 1
            pickups[retained] = item
        end
    end
    for i = count, retained + 1, -1 do
        pickups[i] = nil
    end
end

function Loot.choose(system, run, token, optionId)
    local choices = system.choices
    if run.player.health <= 0 or not choices or choices.token ~= token then
        return false
    end

    for _, option in ipairs(choices.options) do
        if option.id == optionId then
            if optionId == "coins" then
                system.coins = system.coins + option.amount
            elseif option.armory_weapon then
                local weapon = Weapons.new(option.armory_weapon, run.build.randomUnit)
                if not Build.claim_armory(run.build, weapon.id) then
                    return false
                end
                run.weapon_systems[#run.weapon_systems + 1] = weapon
                if not run.weapons then run.weapons = weapon end
            elseif option.recipe then
                if not Evolutions.apply(run, choices.chest, option.recipe) then
                    return false
                end
            elseif not canUpgrade(run) or not Weapons.upgrade(run.weapons) then
                return false
            end
            system.choices = nil
            return true
        end
    end
    return false
end

return Loot
