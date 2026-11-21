local Data = require("data.progress")
local Build = require("game.build")

local Progress = {}
local MAX_LEVEL = #Data.experience_to_next + 1

function Progress.new()
    return {
        level = 1,
        xp = 0,
        xpNeeded = Data.experience_to_next[1],
        pickups = {},
        pending = 0,
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
    system.choices = system.pending > 0 and Build.offer(run.build) or nil
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

local function collectGem(gem, player, magnetRadius, dt)
    local dx, dy = player.x - gem.x, player.y - gem.y
    local distanceSquared = dx * dx + dy * dy
    local collectRadius = player.radius + Data.gem_radius
    if distanceSquared <= collectRadius * collectRadius then
        return true
    end
    if gem.attracted or distanceSquared <= magnetRadius * magnetRadius then
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
    local magnetRadius = Data.magnet_radius * run.weapon_modifiers.magnet_radius
    local count, nextAlive = #pickups, 1
    local gained = 0
    for i = 1, count do
        local gem = pickups[i]
        if collectGem(gem, run.player, magnetRadius, dt) then
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
        gainExperience(system, run, gained * run.weapon_modifiers.experience)
    end
end

function Progress.settleChoice(system, run, experienceFraction)
    system.pending = system.pending - 1
    if experienceFraction and system.xpNeeded then
        gainExperience(system, run, system.xpNeeded * experienceFraction)
    else
        offerChoice(system, run)
    end
end

return Progress
