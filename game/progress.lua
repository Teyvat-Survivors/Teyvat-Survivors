local Data = require("data.progress")
local Weapons = require("game.weapons")

local Progress = {}
local MAX_LEVEL = #Data.experience_to_next + 1

function Progress.new(randomUnit)
    assert(type(randomUnit) == "function", "progress requires the run's random source")
    return {
        randomUnit = randomUnit,
        level = 1,
        xp = 0,
        xpNeeded = Data.experience_to_next[1],
        pickups = {},
        pending = 0,
        choiceToken = 0,
        speedUpgrades = 0,
        healthUpgrades = 0,
    }
end

function Progress.drop(system, enemy)
    if system.level == MAX_LEVEL then
        return nil
    end

    local value = enemy.xp or Data.experience_per_enemy
    if value <= 0 then
        return nil
    end
    local gem = {
        x = enemy.x,
        y = enemy.y,
        enemyId = enemy.id,
        value = value,
        attracted = false,
    }
    system.pickups[#system.pickups + 1] = gem
    return gem
end

local function offerChoice(system, run)
    if system.pending == 0 then
        return
    end

    local options = {}
    if run.weapons.level < Weapons.max_level(run.weapons) then
        options[#options + 1] = { id = "weapon", label = "强化当前武器" }
    end
    if system.speedUpgrades < Data.max_speed_upgrades then
        options[#options + 1] = { id = "speed", label = "提升移速" }
    end
    if system.healthUpgrades < Data.max_health_upgrades then
        options[#options + 1] = { id = "health", label = "提升生命上限" }
    end

    if #options == 0 then
        system.pending = 0
        return
    end
    for i = #options, 2, -1 do
        local fraction = system.randomUnit()
        assert(type(fraction) == "number" and fraction >= 0 and fraction < 1,
            "random source must return a value in [0, 1)")
        local pick = math.floor(fraction * i) + 1
        options[i], options[pick] = options[pick], options[i]
    end
    system.choiceToken = system.choiceToken + 1
    system.choices = { token = system.choiceToken, options = options }
end

local function gainExperience(system, run, value)
    system.xp = system.xp + value
    while system.xpNeeded and system.xp >= system.xpNeeded do
        system.xp = system.xp - system.xpNeeded
        system.level = system.level + 1
        system.pending = system.pending + 1
        system.xpNeeded = Data.experience_to_next[system.level]
    end
    if system.level == MAX_LEVEL then
        system.xp = 0
        for i = #system.pickups, 1, -1 do
            system.pickups[i] = nil
        end
    end
    offerChoice(system, run)
end

local function collectGem(gem, player, dt)
    local dx, dy = player.x - gem.x, player.y - gem.y
    local distanceSquared = dx * dx + dy * dy
    local collectRadius = player.radius + Data.gem_radius
    if distanceSquared <= collectRadius * collectRadius then
        return true
    end
    if gem.attracted or distanceSquared <= Data.magnet_radius * Data.magnet_radius then
        gem.attracted = true
        local distance = math.sqrt(distanceSquared)
        local travel = math.min(Data.magnet_speed * dt, distance)
        gem.x = gem.x + dx * travel / distance
        gem.y = gem.y + dy * travel / distance
        return distance - travel <= collectRadius
    end
    return false
end

function Progress.hasChoice(system)
    return system.choices ~= nil
end

function Progress.step(system, run, dt)
    if Progress.hasChoice(system) then
        return
    end

    local pickups = system.pickups
    local count, nextAlive = #pickups, 1
    local gained = 0
    for i = 1, count do
        local gem = pickups[i]
        if collectGem(gem, run.player, dt) then
            gained = gained + gem.value
        else
            pickups[nextAlive] = gem
            nextAlive = nextAlive + 1
        end
    end
    for i = nextAlive, count do
        pickups[i] = nil
    end
    if gained > 0 then
        gainExperience(system, run, gained)
    end
end

function Progress.choose(system, run, token, optionId)
    local choice = system.choices
    if not choice or token ~= choice.token then
        return false
    end

    local offered = false
    for _, option in ipairs(choice.options) do
        if option.id == optionId then
            offered = true
            break
        end
    end
    if not offered then
        return false
    end

    if optionId == "weapon" then
        if not Weapons.upgrade(run.weapons) then
            return false
        end
    elseif optionId == "speed" then
        system.speedUpgrades = system.speedUpgrades + 1
        run.player.speed = run.player.speed + Data.speed_per_upgrade
    else
        system.healthUpgrades = system.healthUpgrades + 1
        run.player.max_health = run.player.max_health + Data.health_per_upgrade
        run.player.health = run.player.health + Data.health_per_upgrade
    end

    system.choices = nil
    system.pending = system.pending - 1
    offerChoice(system, run)
    return true
end

return Progress
