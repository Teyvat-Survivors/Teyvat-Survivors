local Enemies = require("game.enemies")
local Loot = require("game.loot")
local Progress = require("game.progress")
local Run = require("game.run")
local Weapons = require("game.weapons")
local data = require("data.weapons")
local fixedStep = 1 / 60

local function liveEnemy(id, x, overrides)
    local enemy = {
        id = id, kind = "drift", x = x, y = 0,
        radius = 0.4, health = 80, speed = 6, contactDamage = 10,
    }
    for key, value in pairs(overrides or {}) do
        enemy[key] = value
    end
    return enemy
end

local function combat(weapon)
    return {
        tick = 1,
        player = { x = 0, y = 0, radius = 0.5, health = 100, max_health = 100 },
        weapon_modifiers = {},
        enemies = Enemies.new({
            capacity = 16, spawnDistance = 2, despawnDistance = 100, contactIntervalTicks = 3,
            types = {}, spawns = {},
        }),
        weapons = Weapons.new(weapon),
        progress = Progress.new(function() return 0.5 end),
        loot = Loot.new(function() return 0.6 end),
    }
end

local function trigger(run, onKill)
    Weapons.step(run.weapons, run, fixedStep, onKill)
end

local function enemiesTick(run, tick)
    run.tick = tick
    Enemies.step(run.enemies, run, fixedStep)
end

do
    local run = combat("stone_ward")
    Weapons.upgrade(run.weapons)
    trigger(run)
    local ward = run.player.ward
    assert(ward.charges == 2, "an upgraded ward creates two charges without an enemy target")
    run.enemies.active = { liveEnemy(1, 0, { contactDamage = 0, speed = 0 }), liveEnemy(2, 0, { speed = 0 }) }
    enemiesTick(run, 2)
    assert(ward.charges == 1 and run.player.health == 100, "the first harmful contact consumes one charge")
    enemiesTick(run, 3)
    enemiesTick(run, 4)
    assert(ward.charges == 1, "normal contact cooldown still prevents rapid charge consumption")
    enemiesTick(run, 5)
    assert(ward.charges == 0 and run.player.health == 100, "a second eligible hit consumes the last charge")
    enemiesTick(run, 8)
    trigger(run)
    assert(run.player.ward == ward and run.player.health == 90, "empty wards do not block or refill before weapon cooldown")

    local expiring = combat("stone_ward")
    expiring.weapon_modifiers.duration = 100
    trigger(expiring)
    local capped = expiring.player.ward
    assert(capped.expires_tick == 242, "ward duration obeys the maximum")
    expiring.enemies.active = { liveEnemy(1, 0, { speed = 0 }) }
    enemiesTick(expiring, 242)
    assert(capped.charges == 1 and expiring.player.health == 90, "an unused charge blocks only before expiry")
end

do
    local run = combat("stillwater_seal")
    Weapons.upgrade(run.weapons)
    run.weapon_modifiers.cooldown = 0.001
    run.weapon_modifiers.duration = 100
    local ordinary = liveEnemy(1, 4)
    local elite = liveEnemy(2, 4, { kind = "sentinel", isElite = true })
    local resistant = liveEnemy(3, 4, { controlImmune = true })
    local terminal = liveEnemy(4, 4, { isTerminal = true })
    run.enemies.active = { ordinary, elite, resistant, terminal }
    trigger(run)
    assert(ordinary.slowFactor == 0 and ordinary.slowUntilTick == 50, "upgraded stasis freezes regular enemies with a duration cap")
    assert(elite.slowFactor == 0.6 and elite.slowUntilTick == 20, "elites are only partially slowed with a shorter cap")
    assert(not resistant.slowUntilTick and not terminal.slowUntilTick, "control-immune and finale targets cannot be slowed")

    enemiesTick(run, 2)
    trigger(run)
    assert(ordinary.x == 4 and ordinary.slowUntilTick == 50, "a frozen enemy cannot refresh its freeze")
    assert(math.abs(elite.x - 3.94) < 1e-9 and math.abs(resistant.x - 3.9) < 1e-9,
        "the partial slow changes actual chase movement")
    enemiesTick(run, 50)
    trigger(run)
    assert(ordinary.x < 4 and ordinary.slowUntilTick == 50, "movement resumes at expiry and immediate reapplication is blocked")
    enemiesTick(run, 61)
    trigger(run)
    assert(ordinary.slowUntilTick == 50, "a thawed enemy gets at least twelve movement ticks")
    enemiesTick(run, 62)
    trigger(run)
    assert(ordinary.slowUntilTick > 50, "stasis can be reapplied after thaw")

    local limited = combat("stillwater_seal")
    for index = 1, 8 do
        limited.enemies.active[index] = liveEnemy(index, 4)
    end
    trigger(limited)
    local cap = data.stillwater_seal.levels[1].target_cap
    assert(limited.enemies.active[cap].slowUntilTick and not limited.enemies.active[cap + 1].slowUntilTick,
        "the target cap limits one cast")
end

do
    local run = combat("dawn_break")
    local regular = liveEnemy(1, 3)
    local elite = liveEnemy(2, 3, { kind = "sentinel", isElite = true })
    local weakened = liveEnemy(3, 3, { kind = "sentinel", isElite = true, health = 10 })
    local terminal = liveEnemy(4, 3, { isTerminal = true })
    local distant = liveEnemy(5, 8)
    run.enemies.active = { regular, elite, weakened, terminal, distant }
    local kills = {}
    local function onKill(enemy)
        kills[#kills + 1] = enemy.id
        Progress.drop(run.progress, enemy)
        Loot.defeat(run.loot, enemy)
    end
    trigger(run, onKill)
    assert(regular.health == 0 and elite.health == 65 and weakened.health == 0, "regular targets are cleared while elites take finite damage")
    assert(terminal.health == 80 and distant.health == 80, "the finale and enemies out of area are untouched")
    assert(table.concat(kills, ",") == "1,3" and #run.progress.pickups == 2, "real defeat callbacks create one XP gem each")
    assert(run.loot.pickups[1].kind == "coin" and run.loot.pickups[2].kind == "treasure",
        "clears preserve normal drops and elite treasure eligibility")
    run.tick = run.tick + 1
    trigger(run, onKill)
    assert(#kills == 2 and #run.loot.pickups == 2, "cooldown and dead-target filtering prevent duplicate rewards")

    local grown = combat("dawn_break")
    Weapons.upgrade(grown.weapons)
    local upgradedElite = liveEnemy(1, 7, { isElite = true })
    grown.enemies.active = { upgradedElite }
    trigger(grown)
    assert(upgradedElite.health == 57, "the upgraded burst has greater radius and elite damage")
end

do
    local run = combat("echo_bell")
    local distances = { 9, 7, 3, 6, 6, 8, 12, 13 }
    for index, distance in ipairs(distances) do
        Progress.drop(run.progress, liveEnemy(index, distance))
    end
    local coin = Loot.defeat(run.loot, { id = 1, x = 8, y = 0, kind = "drift", health = 0 })
    trigger(run)
    local gems = run.progress.pickups
    assert(gems[3].attracted and gems[4].attracted and gems[5].attracted, "magnet selects the closest gems within the cap")
    assert(not gems[2].attracted and not gems[6].attracted and not gems[7].attracted and not coin.attracted,
        "non-XP loot, out-of-range gems and gems beyond the cap are not affected")
    assert(#gems == 8 and run.progress.xp == 0, "attraction does not award XP or remove gems early")
    local nextActivation = run.weapons.next_fire_tick
    Weapons.upgrade(run.weapons)
    run.tick = nextActivation
    trigger(run)
    assert(gems[7].attracted and gems[8].attracted, "the upgraded magnet reaches the newly eligible gems")
end

do
    local stage = {
        id = "support-test",
        duration_ticks = 180,
        terminal_timeout_ticks = 30,
        terminal_kind = "sentinel",
        waves = {
            capacity = 4, spawnDistance = 2, despawnDistance = 30, contactIntervalTicks = 12,
            types = {
                drift = { radius = 0.5, speed = 0, health = 250, contactDamage = 5 },
                sentinel = { radius = 0.8, speed = 0, health = 100, contactDamage = 8, elite = true },
            },
            spawns = {
                { tick = 1, kind = "drift", count = 1 },
                { tick = 1, kind = "sentinel", count = 1 },
            },
        },
    }
    local run = Run.new(123, stage, "dawn_break")
    Run.update(run, fixedStep)
    assert(run.kills == 1 and #run.enemies.active == 1 and #run.progress.pickups == 1,
        "the regular run entry clears an enemy and spawns its XP")
    assert(run.enemies.active[1].isElite and run.enemies.active[1].health == 85,
        "spawned elite metadata reaches ordinary combat")
end

do
    local run = combat("stillwater_seal")
    run.enemies = Enemies.new({
        capacity = 1, spawnDistance = 2, despawnDistance = 30, contactIntervalTicks = 3,
        types = {
            drift = { radius = 0.5, speed = 0, health = 1, contactDamage = 0 },
            sentinel = { radius = 0.9, speed = 0, health = 8, contactDamage = 0, elite = true },
        },
        spawns = {
            { tick = 1, kind = "drift", count = 1 },
            { tick = 2, kind = "sentinel", count = 1 },
        },
    })
    enemiesTick(run, 1)
    trigger(run)
    local reused = run.enemies.active[1]
    assert(reused.slowUntilTick and Enemies.damage(reused, 1))
    Enemies.compact(run.enemies)
    enemiesTick(run, 2)
    assert(run.enemies.active[1] == reused and reused.id == 2 and reused.isElite,
        "the pool reuses the defeated table but initializes the new life")
    assert(not reused.slowUntilTick and not reused.slowReadyTick and not reused.slowFactor,
        "newly spawned enemies do not inherit pooled control effects")
end

print("Lua shield charges, anti-lock stasis, capped XP magnet and clear reward behavior passed")
