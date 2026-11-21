local Enemies = require("game.enemies")
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

local function fire(system, run, enemies, onKill)
    local weapon = data[system.id]
    local stats = weapon.levels[system.level]
    local mod = run.weapon_modifiers or neutralModifiers
    local x, y = run.player.x, run.player.y
    local range = (stats.range or 0) * (mod.range or 1)
    local target
    if weapon.behavior ~= "pulse" then
        target = nearestEnemy(enemies, x, y, range)
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
        hit_ids = {},
    }
    if weapon.behavior == "projectile" then
        attack.dx, attack.dy = direction(target.x - x, target.y - y)
        attack.speed = stats.speed * (mod.projectile_speed or 1)
        attack.remaining_distance = range
        attack.remaining_hits = 1 + math.max(0, math.floor(stats.pierce + (mod.pierce or 0)))
        local projectiles = system.projectiles
        projectiles[#projectiles + 1] = attack
    elseif weapon.behavior == "field" then
        attack.x, attack.y = target.x, target.y
        attack.interval_ticks = stats.interval_ticks
        attack.next_tick = run.tick
        attack.expires_tick = run.tick + math.max(1, math.floor(stats.duration_ticks * (mod.duration or 1)))
        attack.max_hits_per_target = stats.max_hits_per_target
        system.fields[#system.fields + 1] = attack
    else
        attack.max_hits_per_target = 1
        if not pulse(system, attack, enemies, onKill) then
            return
        end
    end
    system.next_fire_tick = run.tick + math.max(1, math.ceil(stats.cooldown_ticks * (mod.cooldown or 1)))
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

local function stepFields(system, tick, enemies, onKill)
    local fields = system.fields
    local retained = 0
    for _, field in ipairs(fields) do
        if tick < field.expires_tick then
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

-- Called once per simulation tick. Kill notifications precede enemy cleanup.
function Weapons.step(system, run, dtSeconds, onKill)
    local enemies = run.enemies.active
    if run.tick >= system.next_fire_tick then
        fire(system, run, enemies, onKill)
    end

    stepFields(system, run.tick, enemies, onKill)

    local projectiles = system.projectiles
    local count = #projectiles
    local alive = 0
    for i = 1, count do
        local projectile = projectiles[i]
        local travel = math.min(projectile.remaining_distance, projectile.speed * dtSeconds)
        resolveHits(system, projectile, enemies, travel, onKill)
        projectile.remaining_distance = projectile.remaining_distance - travel
        if projectile.remaining_distance > 0 and projectile.remaining_hits > 0 then
            projectile.x = projectile.x + projectile.dx * travel
            projectile.y = projectile.y + projectile.dy * travel
            alive = alive + 1
            projectiles[alive] = projectile
        end
    end
    for i = alive + 1, count do
        projectiles[i] = nil
    end
end

return Weapons
