local Enemies = {}
local fullTurn = 2 * math.pi

local function positive(value)
    return type(value) == "number" and value > 0 and value < math.huge
end

local function ticks(value)
    return positive(value) and value % 1 == 0
end

local function validateType(kind)
    local charge = kind.charge
    if charge then
        assert(positive(charge.range) and positive(charge.speed), "invalid enemy charge movement")
        assert(ticks(charge.windupTicks) and ticks(charge.chargeTicks) and ticks(charge.cooldownTicks),
            "invalid enemy charge timing")
    end
    local frenzy = kind.frenzy
    if frenzy then
        assert(positive(frenzy.healthFraction) and frenzy.healthFraction < 1 and
            positive(frenzy.speed) and positive(frenzy.contactDamage), "invalid enemy frenzy")
    end
end

function Enemies.new(config, randomUnit)
    assert(config.capacity >= 0 and config.capacity % 1 == 0, "enemy capacity must be a non-negative integer")
    assert(config.spawnDistance >= 0 and config.despawnDistance > config.spawnDistance, "invalid enemy spawn distances")
    assert(config.contactIntervalTicks >= 1 and config.contactIntervalTicks % 1 == 0, "invalid enemy contact interval")
    for _, kind in pairs(config.types) do
        validateType(kind)
    end

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
    enemy.isElite = kind.elite == true
    enemy.treasureKind = kind.treasure_kind
    enemy.controlImmune = kind.controlImmune == true
    enemy.slowFactor, enemy.slowUntilTick, enemy.slowReadyTick = nil, nil, nil
    enemy.x = player.x + math.cos(angle) * distance
    enemy.y = player.y + math.sin(angle) * distance
    enemy.radius = kind.radius
    enemy.speed = kind.speed
    enemy.health = kind.health
    enemy.contactDamage = kind.contactDamage
    enemy.xp = kind.xp
    enemy.charge = kind.charge
    enemy.frenzy = kind.frenzy
    enemy.maxHealth = kind.health
    enemy.phase = kind.frenzy and 1 or nil
    enemy.motion = kind.charge and "approach" or nil
    enemy.motionEndsTick = nil
    enemy.nextChargeTick = nil
    enemy.chargeX = nil
    enemy.chargeY = nil
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

local function updateFrenzy(enemy)
    local frenzy = enemy.frenzy
    if frenzy and enemy.phase == 1 and enemy.health <= enemy.maxHealth * frenzy.healthFraction then
        enemy.phase = 2
        enemy.speed = frenzy.speed
        enemy.contactDamage = frenzy.contactDamage
    end
end

local function chargeMovement(enemy, tick, dx, dy, distance, dtSeconds)
    local charge = enemy.charge
    if enemy.motion == "windup" and tick >= enemy.motionEndsTick then
        enemy.motion = "charging"
        enemy.motionEndsTick = tick + charge.chargeTicks
    elseif enemy.motion == "charging" and tick >= enemy.motionEndsTick then
        enemy.motion = "approach"
        enemy.motionEndsTick = nil
        enemy.nextChargeTick = tick + charge.cooldownTicks
    end
    if enemy.motion == "approach" and tick >= (enemy.nextChargeTick or 0) and
        distance > 0 and distance <= charge.range then
        enemy.motion = "windup"
        enemy.motionEndsTick = tick + charge.windupTicks
        enemy.chargeX, enemy.chargeY = dx / distance, dy / distance
    end
    if enemy.motion == "windup" then
        return 0, 0
    end
    if enemy.motion == "charging" then
        local travel = charge.speed * dtSeconds
        return enemy.chargeX * travel, enemy.chargeY * travel
    end
end

local function crossesPlayer(dx, dy, moveX, moveY, radius)
    local lengthSquared = moveX * moveX + moveY * moveY
    if lengthSquared > 0 then
        local fraction = math.max(0, math.min(1, (dx * moveX + dy * moveY) / lengthSquared))
        dx, dy = dx - moveX * fraction, dy - moveY * fraction
    end
    return dx * dx + dy * dy <= radius * radius
end

local function stepEnemy(enemy, player, tick, dtSeconds, checkContact)
    updateFrenzy(enemy)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local radius = player.radius + enemy.radius
    if enemy.charge then
        local moveX, moveY = chargeMovement(enemy, tick, dx, dy, distance, dtSeconds)
        if moveX then
            enemy.x, enemy.y = enemy.x + moveX, enemy.y + moveY
            return checkContact and crossesPlayer(dx, dy, moveX, moveY, radius)
        end
    end
    local travel = math.min(distance, enemy.speed * dtSeconds)
    if distance > 0 then
        enemy.x = enemy.x + dx * travel / distance
        enemy.y = enemy.y + dy * travel / distance
    end
    return checkContact and distance - travel <= radius
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
        local step = dtSeconds
        if enemy.slowUntilTick and run.tick < enemy.slowUntilTick then
            step = step * enemy.slowFactor
        end
        if stepEnemy(enemy, player, run.tick, step, run.tick >= system.nextContactTick) then
            local damage = math.max(0, enemy.contactDamage - (player.armor or 0))
            if damage > 0 then
                local ward = player.ward
                if ward and ward.charges > 0 and run.tick < ward.expires_tick then
                    ward.charges = ward.charges - 1
                else
                    player.health = math.max(0, player.health - damage)
                end
                system.nextContactTick = run.tick + system.config.contactIntervalTicks
            end
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
