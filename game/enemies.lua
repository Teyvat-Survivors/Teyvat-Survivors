local Enemies = {}
local fullTurn = 2 * math.pi

function Enemies.new(config, randomUnit)
    assert(config.capacity >= 0 and config.capacity % 1 == 0, "enemy capacity must be a non-negative integer")
    assert(config.spawnDistance >= 0 and config.despawnDistance > config.spawnDistance, "invalid enemy spawn distances")
    assert(config.contactIntervalTicks >= 1 and config.contactIntervalTicks % 1 == 0, "invalid enemy contact interval")

    local previousTick = 0
    for _, wave in ipairs(config.spawns) do
        assert(wave.tick >= 1 and wave.tick % 1 == 0 and wave.tick >= previousTick, "enemy waves must be sorted by positive integer tick")
        assert(wave.count >= 1 and wave.count % 1 == 0, "enemy wave count must be a positive integer")
        assert(config.types[wave.kind], "unknown enemy type: " .. tostring(wave.kind))
        previousTick = wave.tick
    end

    return {
        config = config,
        randomUnit = randomUnit,
        active = {},
        free = {},
        nextWave = 1,
        nextContactTick = 0,
        totalSpawned = 0,
        totalSkipped = 0,
        despawnDistanceSquared = config.despawnDistance ^ 2,
    }
end

local function distanceSquared(enemy, player)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    return dx * dx + dy * dy
end

local function recycle(system, player)
    local active = system.active
    local retained = 0
    for _, enemy in ipairs(active) do
        if enemy.health > 0 and
            (not player or enemy.isTerminal or distanceSquared(enemy, player) <= system.despawnDistanceSquared) then
            retained = retained + 1
            active[retained] = enemy
        else
            system.free[#system.free + 1] = enemy
        end
    end
    for index = #active, retained + 1, -1 do
        active[index] = nil
    end
end

local function spawn(system, player, kindId)
    local kind = system.config.types[kindId]
    local id = system.totalSpawned + 1
    local turn = system.randomUnit and system.randomUnit() or (id * 0.61803398875) % 1
    local angle = fullTurn * turn
    local distance = system.config.spawnDistance
    local enemy = table.remove(system.free) or {}
    enemy.id = id
    enemy.kind = kindId
    enemy.isTerminal = false
    enemy.x = player.x + math.cos(angle) * distance
    enemy.y = player.y + math.sin(angle) * distance
    enemy.radius = kind.radius
    enemy.speed = kind.speed
    enemy.health = kind.health
    enemy.contactDamage = kind.contactDamage
    system.active[#system.active + 1] = enemy
    system.totalSpawned = id
    return enemy
end

local function spawnWave(system, player, wave)
    local count = math.min(wave.count, system.config.capacity - #system.active)
    system.totalSkipped = system.totalSkipped + wave.count - count
    for _ = 1, count do
        spawn(system, player, wave.kind)
    end
end

function Enemies.begin_finale(system, player, kindId)
    for index = #system.active, 1, -1 do
        system.free[#system.free + 1] = system.active[index]
        system.active[index] = nil
    end
    system.nextWave = #system.config.spawns + 1
    local terminal = spawn(system, player, kindId)
    terminal.isTerminal = true
    return terminal
end

function Enemies.step(system, run, dtSeconds)
    local player = run.player
    recycle(system, player)

    local spawns = system.config.spawns
    local wave = spawns[system.nextWave]
    while wave and wave.tick <= run.tick do
        spawnWave(system, player, wave)
        system.nextWave = system.nextWave + 1
        wave = spawns[system.nextWave]
    end

    for _, enemy in ipairs(system.active) do
        local dx = player.x - enemy.x
        local dy = player.y - enemy.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local travel = math.min(distance, enemy.speed * dtSeconds)
        if distance > 0 then
            enemy.x = enemy.x + dx * travel / distance
            enemy.y = enemy.y + dy * travel / distance
        end

        if run.tick >= system.nextContactTick and distance - travel <= player.radius + enemy.radius then
            local damage = math.max(0, enemy.contactDamage - (player.armor or 0))
            player.health = math.max(0, player.health - damage)
            system.nextContactTick = run.tick + system.config.contactIntervalTicks
        end
    end
end

-- Callers can record a defeat before the pooled record is recycled.
function Enemies.damage(enemy, amount)
    assert(amount > 0 and amount < math.huge, "enemy damage must be positive and finite")
    if enemy.health <= 0 then
        return false
    end
    enemy.health = math.max(0, enemy.health - amount)
    return enemy.health == 0
end

function Enemies.compact(system)
    recycle(system)
end

return Enemies
