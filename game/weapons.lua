local Enemies = require("game.enemies")
local levels = require("data.weapons").wind_blade.levels
local Weapons = {}

function Weapons.new()
    return { level = 1, projectiles = {}, next_fire_tick = 1 }
end

function Weapons.upgrade(system)
    if system.level == #levels then
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

local function fire(system, run, enemies)
    local stats = levels[system.level]
    local x, y = run.player.x, run.player.y
    local target = nearestEnemy(enemies, x, y, stats.range)
    if not target then
        return
    end

    local dx, dy = target.x - x, target.y - y
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
        dx, dy = dx / length, dy / length
    else
        dx, dy = 1, 0
    end
    local projectiles = system.projectiles
    projectiles[#projectiles + 1] = {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        speed = stats.speed,
        radius = stats.radius,
        damage = stats.damage,
        remaining_distance = stats.range,
        remaining_hits = 1 + stats.pierce,
        hit_ids = {},
    }
    system.next_fire_tick = run.tick + stats.cooldown_ticks
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

local function resolveHits(projectile, enemies, travel, onKill)
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

    table.sort(contacts, function(a, b)
        if a.distance == b.distance then
            return a.enemy.id < b.enemy.id
        end
        return a.distance < b.distance
    end)

    for _, contact in ipairs(contacts) do
        local enemy = contact.enemy
        if enemy.health > 0 and not projectile.hit_ids[enemy.id] then
            projectile.hit_ids[enemy.id] = true
            projectile.remaining_hits = projectile.remaining_hits - 1
            if Enemies.damage(enemy, projectile.damage) and onKill then
                onKill(enemy)
            end
            if projectile.remaining_hits == 0 then
                return
            end
        end
    end
end

-- Called once per simulation tick. Kill notifications precede enemy cleanup.
function Weapons.step(system, run, dtSeconds, onKill)
    local enemies = run.enemies.active
    if run.tick >= system.next_fire_tick then
        fire(system, run, enemies)
    end

    local projectiles = system.projectiles
    local count = #projectiles
    local alive = 0
    for i = 1, count do
        local projectile = projectiles[i]
        local travel = math.min(projectile.remaining_distance, projectile.speed * dtSeconds)
        resolveHits(projectile, enemies, travel, onKill)
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
