local Enemies = require("game.enemies")
local Support = {}
local handlers = {}

local function duration(ticks, modifiers, limit)
    return math.max(1, math.min(limit, math.floor(ticks * (modifiers.duration or 1))))
end

local function distanceSquared(entity, player)
    local dx, dy = entity.x - player.x, entity.y - player.y
    return dx * dx + dy * dy
end

local function inRange(entity, player, radius)
    return distanceSquared(entity, player) <= radius * radius
end

function handlers.ward(stats, modifiers, run)
    local player = run.player
    local ward = player.ward
    if ward and ward.charges > 0 and run.tick < ward.expires_tick then
        return false
    end

    player.ward = {
        charges = stats.charges,
        expires_tick = run.tick + duration(stats.duration_ticks, modifiers, 240) + 1,
    }
    return true
end

function handlers.stasis(stats, modifiers, run, enemies)
    local radius = stats.radius * (modifiers.area or 1)
    local affected = 0
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 and not enemy.isTerminal and not enemy.controlImmune and
            run.tick >= (enemy.slowReadyTick or 0) and inRange(enemy, run.player, radius + enemy.radius) then
            local limit = enemy.isElite and 18 or 48
            enemy.slowFactor = enemy.isElite and math.max(0.6, stats.speed_factor) or stats.speed_factor
            enemy.slowUntilTick = run.tick + duration(stats.duration_ticks, modifiers, limit) + 1
            enemy.slowReadyTick = enemy.slowUntilTick + 12
            affected = affected + 1
            if affected == stats.target_cap then
                break
            end
        end
    end
    return affected > 0
end

function handlers.purge(stats, modifiers, run, enemies, onKill)
    local radius = (stats.radius or 0) * (modifiers.area or 1)
    local eliteDamage = stats.elite_damage * (modifiers.damage or 1)
    local affected = false
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 and not enemy.isTerminal and
            (stats.arena_wide or inRange(enemy, run.player, radius + enemy.radius)) then
            local amount = enemy.isElite and eliteDamage or enemy.health
            if amount > 0 then
                affected = true
                if Enemies.damage(enemy, amount) and onKill then
                    onKill(enemy)
                end
            end
        end
    end
    return affected
end

function handlers.echo_magnet(stats, modifiers, run)
    if not run.progress then
        return false
    end

    local radius = stats.radius * (modifiers.area or 1)
    local radiusSquared = radius * radius
    local nearby = {}
    for index, gem in ipairs(run.progress.pickups) do
        local distance = distanceSquared(gem, run.player)
        if not gem.attracted and distance <= radiusSquared then
            nearby[#nearby + 1] = { gem = gem, distance = distance, order = index }
        end
    end
    table.sort(nearby, function(a, b)
        if a.distance == b.distance then
            return a.order < b.order
        end
        return a.distance < b.distance
    end)
    for index = 1, math.min(stats.pickup_cap, #nearby) do
        nearby[index].gem.attracted = true
    end
    return #nearby > 0
end

-- nil lets the ordinary attack path dispatch non-support behaviors.
function Support.activate(behavior, stats, modifiers, run, enemies, onKill)
    local activate = handlers[behavior]
    if activate then
        return activate(stats, modifiers, run, enemies, onKill)
    end
end

return Support
