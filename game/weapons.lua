local Enemies = require("game.enemies")
local Support = require("game.support")
local data = require("data.weapons")
local Weapons = {}

local function defaultRandom()
    local seed = 1
    return function()
        seed = (seed * 48271) % 2147483647
        return (seed - 1) / 2147483646
    end
end

function Weapons.new(id, randomUnit)
    id = id or "wind_blade"
    assert(data[id], "unknown weapon: " .. tostring(id))
    return {
        id = id, level = 1, projectiles = {}, fields = {}, next_fire_tick = 1,
        randomUnit = randomUnit or defaultRandom(),
    }
end

function Weapons.max_level(system)
    return #data[system.id].levels
end

function Weapons.upgrade(system)
    if system.level >= Weapons.max_level(system) then
        return nil
    end
    system.level = system.level + 1
    return system.level
end

local function nearestEnemy(enemies, x, y, range)
    local best, limit = nil, range * range
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 then
            local dx, dy = enemy.x - x, enemy.y - y
            local distance = dx * dx + dy * dy
            if distance <= limit and (distance < limit or not best or enemy.id < best.id) then
                best, limit = enemy, distance
            end
        end
    end
    return best
end

local function direction(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then
        return x / length, y / length
    end
    return 1, 0
end

local function damage(system, attack, enemy, dx, dy, onKill)
    local amount = attack.damage
    if amount <= 0 then
        return
    end
    local chance = attack.crit_chance
    if chance == 1 or (chance > 0 and system.randomUnit() < chance) then
        amount = amount * attack.crit_multiplier
    end
    if Enemies.damage(enemy, amount) then
        if onKill then
            onKill(enemy)
        end
    elseif attack.knockback > 0 then
        dx, dy = direction(dx, dy)
        enemy.x = enemy.x + dx * attack.knockback
        enemy.y = enemy.y + dy * attack.knockback
    end
end

local function contactOrder(a, b)
    if a.distance == b.distance then
        return a.enemy.id < b.enemy.id
    end
    return a.distance < b.distance
end

local function pulse(system, attack, enemies, onKill)
    local contacts = {}
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 and (attack.hit_ids[enemy.id] or 0) < attack.max_hits_per_target then
            local dx, dy = enemy.x - attack.x, enemy.y - attack.y
            local distance = dx * dx + dy * dy
            if distance <= (attack.radius + enemy.radius) ^ 2 then
                contacts[#contacts + 1] = { enemy = enemy, distance = distance }
            end
        end
    end
    table.sort(contacts, contactOrder)
    local previousId
    for _, contact in ipairs(contacts) do
        local enemy = contact.enemy
        if enemy.id ~= previousId then
            previousId = enemy.id
            attack.hit_ids[enemy.id] = (attack.hit_ids[enemy.id] or 0) + 1
            damage(system, attack, enemy, enemy.x - attack.x, enemy.y - attack.y, onKill)
        end
    end
    return #contacts > 0
end

local neutralModifiers = {}

local function randomTarget(system, enemies, x, y, range)
    local targets = {}
    local limit = range * range
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 then
            local dx, dy = enemy.x - x, enemy.y - y
            if dx * dx + dy * dy <= limit then
                targets[#targets + 1] = enemy
            end
        end
    end
    if #targets > 0 then
        table.sort(targets, function(a, b) return a.id < b.id end)
        local index = math.min(#targets, 1 + math.floor(system.randomUnit() * #targets))
        return targets[index]
    end
end

local function launch(system, weapon, attack, stats, mod, player, target, range)
    local dx, dy = target.x - player.x, target.y - player.y
    local forwardX, forwardY
    if weapon.aim == "facing" then
        forwardX, forwardY = direction(player.facing_x or 0, player.facing_y or 0)
    else
        forwardX, forwardY = direction(dx, dy)
    end

    local count = stats.shots or 1
    local projectiles = system.projectiles
    for shot = 1, count do
        local projectile = attack
        if count > 1 then
            projectile = {}
            for key, value in pairs(attack) do
                projectile[key] = value
            end
        end
        projectile.hit_ids = {}
        projectile.dx, projectile.dy = forwardX, forwardY
        if count > 1 then
            local offset = (shot - (count + 1) / 2) * stats.angle_step
            local c, si = math.cos(offset), math.sin(offset)
            projectile.dx = forwardX * c - forwardY * si
            projectile.dy = forwardX * si + forwardY * c
        end
        projectile.motion = weapon.motion
        projectile.speed = stats.speed * (mod.projectile_speed or 1)
        projectile.remaining_distance = range
        projectile.remaining_hits = 1 + math.max(0, math.floor(stats.pierce + (mod.pierce or 0)))
        if weapon.motion == "lob" then
            projectile.remaining_distance = math.min(range, math.sqrt(dx * dx + dy * dy))
            projectile.initial_distance = projectile.remaining_distance
            projectile.apex = stats.apex
            projectile.height = 0
        elseif weapon.motion == "rebound" then
            projectile.remaining_bounces = stats.bounces
        elseif weapon.motion == "return" then
            projectile.return_distance = range * stats.return_ratio
        end
        projectiles[#projectiles + 1] = projectile
    end
end

local function fire(system, run, enemies, onKill)
    local weapon = data[system.id]
    local stats = weapon.levels[system.level]
    local mod = run.weapon_modifiers or neutralModifiers
    local cooldown = math.max(1, math.ceil(stats.cooldown_ticks * (mod.cooldown or 1)))
    local supported = Support.activate(weapon.behavior, stats, mod, run, enemies, onKill)
    if supported ~= nil then
        if supported then
            system.next_fire_tick = run.tick + cooldown
        end
        return
    end
    local x, y = run.player.x, run.player.y
    local range = (stats.range or 0) * (mod.range or 1)
    local target
    if weapon.behavior ~= "pulse" and (weapon.behavior ~= "field" or not weapon.field_anchor) then
        if weapon.aim == "random" then
            target = randomTarget(system, enemies, x, y, range)
        else
            target = nearestEnemy(enemies, x, y, range)
        end
        if not target then
            return
        end
    end
    local attack = {
        x = x,
        y = y,
        radius = stats.radius * (mod.area or 1),
        damage = stats.damage * (mod.damage or 1),
        crit_chance = math.max(0, math.min(1, (stats.crit_chance or 0) + (mod.crit_chance or 0))),
        crit_multiplier = stats.crit_multiplier or 1.5,
        knockback = (stats.knockback or 0) * (mod.knockback or 1),
    }
    if weapon.behavior == "projectile" then
        launch(system, weapon, attack, stats, mod, run.player, target, range)
    elseif weapon.behavior == "field" then
        attack.hit_ids = {}
        if target then
            attack.x, attack.y = target.x, target.y
        end
        attack.anchor = weapon.field_anchor
        attack.start_tick = run.tick
        attack.orbit_radius = stats.orbit_radius
        attack.orbit_period_ticks = stats.orbit_period_ticks
        attack.interval_ticks = stats.interval_ticks
        attack.next_tick = run.tick
        attack.expires_tick = run.tick + math.max(1, math.floor(stats.duration_ticks * (mod.duration or 1)))
        attack.max_hits_per_target = stats.max_hits_per_target
        system.fields[#system.fields + 1] = attack
    else
        attack.hit_ids = {}
        attack.max_hits_per_target = 1
        if not pulse(system, attack, enemies, onKill) then
            return
        end
    end
    system.next_fire_tick = run.tick + cooldown
    return true
end

-- First point along the swept projectile segment that overlaps the enemy.
local function firstContact(projectile, enemy, travel)
    local x, y = enemy.x - projectile.x, enemy.y - projectile.y
    local radius = projectile.radius + enemy.radius
    local squared_distance = x * x + y * y
    local squared_radius = radius * radius
    if squared_distance <= squared_radius then
        return 0
    end

    local projection = x * projectile.dx + y * projectile.dy
    if projection <= 0 or projection > travel + radius then
        return nil
    end
    local discriminant = squared_radius - (squared_distance - projection * projection)
    if discriminant < 0 then
        return nil
    end
    local entry = projection - math.sqrt(discriminant)
    if entry <= travel then
        return entry
    end
end

local function resolveHits(system, projectile, enemies, travel, onKill)
    local contacts = nil
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 and not projectile.hit_ids[enemy.id] then
            local entry = firstContact(projectile, enemy, travel)
            if entry then
                if not contacts then
                    contacts = {}
                end
                contacts[#contacts + 1] = { distance = entry, enemy = enemy }
            end
        end
    end
    if not contacts then
        return
    end

    table.sort(contacts, contactOrder)

    for _, contact in ipairs(contacts) do
        local enemy = contact.enemy
        if enemy.health > 0 and not projectile.hit_ids[enemy.id] then
            projectile.hit_ids[enemy.id] = true
            projectile.remaining_hits = projectile.remaining_hits - 1
            damage(system, projectile, enemy, projectile.dx, projectile.dy, onKill)
            if projectile.remaining_hits == 0 then
                return
            end
        end
    end
end

local function move(shot, distance)
    shot.x = shot.x + shot.dx * distance
    shot.y = shot.y + shot.dy * distance
    shot.remaining_distance = shot.remaining_distance - distance
    if shot.remaining_distance < 1e-9 then
        shot.remaining_distance = 0
    end
end

local function fly(system, shot, enemies, distance, onKill)
    resolveHits(system, shot, enemies, distance, onKill)
    move(shot, distance)
end

local defaultBounds = { min_x = -96, max_x = 96, min_y = -96, max_y = 96 }

local function edgeDistance(position, axis, minimum, maximum)
    if axis == 0 then
        return math.huge
    end
    return math.max(0, ((axis > 0 and maximum or minimum) - position) / axis)
end

local function rebound(system, shot, enemies, distance, bounds, onKill)
    while distance > 0 and shot.remaining_hits > 0 do
        local xDistance = edgeDistance(shot.x, shot.dx, bounds.min_x, bounds.max_x)
        local yDistance = edgeDistance(shot.y, shot.dy, bounds.min_y, bounds.max_y)
        local edge = math.min(xDistance, yDistance)
        if edge > distance then
            fly(system, shot, enemies, distance, onKill)
            return
        end

        fly(system, shot, enemies, edge, onKill)
        distance = distance - edge
        if shot.remaining_bounces == 0 then
            shot.remaining_distance = 0
            return
        end
        shot.remaining_bounces = shot.remaining_bounces - 1
        if math.abs(xDistance - edge) <= 1e-9 then
            shot.dx = -shot.dx
        end
        if math.abs(yDistance - edge) <= 1e-9 then
            shot.dy = -shot.dy
        end
    end
end

local function returnFlight(system, shot, enemies, budget, player, onKill)
    if not shot.returning then
        local outbound = math.min(budget, shot.remaining_distance)
        fly(system, shot, enemies, outbound, onKill)
        if shot.remaining_distance > 0 or shot.remaining_hits == 0 then
            return
        end
        shot.returning = true
        shot.remaining_distance = shot.return_distance
        budget = budget - outbound
    end

    local x, y = player.x - shot.x, player.y - shot.y
    local distance = math.sqrt(x * x + y * y)
    if distance > 0 then
        shot.dx, shot.dy = x / distance, y / distance
        local travel = math.min(budget, shot.remaining_distance, distance)
        if travel > 0 then
            fly(system, shot, enemies, travel, onKill)
        end
        if travel < distance then
            return
        end
    end
    shot.remaining_distance = 0
end

local function stepProjectile(system, shot, run, enemies, dtSeconds, onKill)
    local budget = shot.speed * dtSeconds
    local travel = math.min(shot.remaining_distance, budget)
    if shot.motion == "lob" then
        move(shot, travel)
        if shot.remaining_distance == 0 then
            shot.height = 0
            resolveHits(system, shot, enemies, 0, onKill)
        else
            local progress = 1 - shot.remaining_distance / shot.initial_distance
            shot.height = 4 * shot.apex * progress * (1 - progress)
        end
    elseif shot.motion == "rebound" then
        rebound(system, shot, enemies, travel, run.bounds or defaultBounds, onKill)
    elseif shot.motion == "return" then
        returnFlight(system, shot, enemies, budget, run.player, onKill)
    else
        fly(system, shot, enemies, travel, onKill)
    end
end

local function updateFieldCenter(field, player, tick)
    if field.anchor == "player" then
        field.x, field.y = player.x, player.y
    elseif field.anchor == "orbit" then
        local age = tick - field.start_tick
        local angle = 2 * math.pi * (age % field.orbit_period_ticks) / field.orbit_period_ticks
        field.x = player.x + field.orbit_radius * math.cos(angle)
        field.y = player.y + field.orbit_radius * math.sin(angle)
    end
end

local function stepFields(system, run, enemies, onKill)
    local tick = run.tick
    local fields = system.fields
    local retained = 0
    for _, field in ipairs(fields) do
        if tick < field.expires_tick then
            updateFieldCenter(field, run.player, tick)
            if tick >= field.next_tick then
                pulse(system, field, enemies, onKill)
                field.next_tick = field.next_tick + field.interval_ticks
            end
            retained = retained + 1
            fields[retained] = field
        end
    end
    for i = #fields, retained + 1, -1 do
        fields[i] = nil
    end
end

local function readyFromTravel(system, player, threshold)
    if not threshold then
        return true
    end
    local travel = system.travel
    if not travel then
        system.travel = { x = player.x, y = player.y, distance = 0 }
        return false
    end
    local dx, dy = player.x - travel.x, player.y - travel.y
    travel.x, travel.y = player.x, player.y
    travel.distance = math.min(threshold, travel.distance + math.sqrt(dx * dx + dy * dy))
    return travel.distance + 1e-9 >= threshold
end

-- Called once per simulation tick. Kill notifications precede enemy cleanup.
function Weapons.step(system, run, dtSeconds, onKill)
    local enemies = run.enemies.active
    local travelDistance = data[system.id].levels[system.level].travel_distance
    if readyFromTravel(system, run.player, travelDistance) and run.tick >= system.next_fire_tick then
        if fire(system, run, enemies, onKill) and travelDistance then
            system.travel.distance = 0
        end
    end

    stepFields(system, run, enemies, onKill)

    local projectiles = system.projectiles
    local count = #projectiles
    local alive = 0
    for i = 1, count do
        local projectile = projectiles[i]
        stepProjectile(system, projectile, run, enemies, dtSeconds, onKill)
        if projectile.remaining_distance > 0 and projectile.remaining_hits > 0 then
            alive = alive + 1
            projectiles[alive] = projectile
        end
    end
    for i = alive + 1, count do
        projectiles[i] = nil
    end
end

return Weapons
