local Progress = require("game.progress")
local Data = require("data.progress")
local Weapons = require("game.weapons")
local WeaponData = require("data.weapons")

local function seeded(seed)
    return function()
        seed = (seed * 16807) % 2147483647
        return (seed - 1) / 2147483646
    end
end

local function newRun(seed)
    return {
        player = { x = 0, y = 0, radius = 0.42, speed = 6, health = 45, max_health = 60 },
        progress = Progress.new(seeded(seed or 1)),
        weapons = Weapons.new(),
        enemies = { active = {} },
        tick = 1,
    }
end

local function drop(run, id, x, xp)
    return Progress.drop(run.progress, { id = id, x = x or 0, y = 0, xp = xp })
end

local function collect(run, value)
    drop(run, 100, 0, value)
    Progress.step(run.progress, run, 0.05)
end

local function optionIds(choice)
    local ids, seen = {}, {}
    for i, option in ipairs(choice.options) do
        assert(not seen[option.id], "a choice cannot repeat a candidate")
        seen[option.id] = true
        ids[i] = option.id
    end
    return table.concat(ids, ",")
end

do
    local run = newRun()
    local state = run.progress
    local source = { id = 1, x = Data.magnet_radius + 1, y = 0, xp = 3 }
    local gem = Progress.drop(state, source)
    source.x, source.y, source.id, source.xp = 0, 20, 99, 20
    assert(gem.x == Data.magnet_radius + 1 and gem.y == 0 and gem.enemyId == 1 and gem.value == 3,
        "pooled enemy reuse must not alter an existing gem")
    Progress.step(state, run, 0.05)
    assert(gem.x == Data.magnet_radius + 1 and not gem.attracted and state.xp == 0,
        "the gem is still outside magnet range")
    run.player.x = 1.5
    Progress.step(state, run, 0.05)
    assert(gem.attracted and gem.x == Data.magnet_radius + 1 - Data.magnet_speed * 0.05 and #state.pickups == 1,
        "a nearby gem moves towards the player at the configured speed")
    run.player.x = -1
    Progress.step(state, run, 1)
    assert(#state.pickups == 0 and state.xp == 3, "an attracted gem stays targeted and is collected only once")
    assert(not drop(run, 2, 0, 0), "zero-experience defeats do not make gems")
    Progress.step(state, run, 1)
    assert(state.xp == 3, "expired gems cannot be collected twice")
end

do
    local run = newRun()
    local state = run.progress
    local before = state.xpNeeded - 1
    collect(run, before)
    assert(state.level == 1 and state.xp == before and not Progress.hasChoice(state),
        "experience below the first threshold does not level up")
    assert(drop(run, 1) and drop(run, 2, 0, Data.experience_to_next[2] + 1))
    Progress.step(state, run, 0.05)
    assert(state.level == 3 and state.xp == Data.experience_per_enemy and state.pending == 2,
        "one tick can collect multiple gems and retain overflow")
    local firstChoice = state.choices
    assert(#firstChoice.options == 3)
    optionIds(firstChoice)

    local nextGem = drop(run, 3, Data.magnet_radius / 2, 3)
    Progress.step(state, run, 1)
    assert(not nextGem.attracted and state.xp == Data.experience_per_enemy,
        "gem updates remain paused while the player is choosing")
    assert(not Progress.choose(state, run, firstChoice.token, "missing"), "a missing option has no effect")
    assert(not Progress.choose(state, run, firstChoice.token + 1, "health"), "a mismatched token has no effect")
    assert(state.choices == firstChoice and state.pending == 2 and run.player.health == 45,
        "invalid choices cannot consume a pending level or mutate the player")
    assert(Progress.choose(state, run, firstChoice.token, "health"), "the correct token applies its option")
    assert(run.player.health == 45 + Data.health_per_upgrade and run.player.max_health == 60 + Data.health_per_upgrade)
    local secondChoice = state.choices
    assert(state.pending == 1 and secondChoice.token > firstChoice.token, "each queued choice has a fresh token")
    assert(not Progress.choose(state, run, firstChoice.token, "health"), "a duplicate tap cannot choose the next level")
    assert(Progress.choose(state, run, secondChoice.token, "speed"))
    assert(run.player.speed == 6 + Data.speed_per_upgrade and state.pending == 0 and not Progress.hasChoice(state))
    Progress.step(state, run, 1)
    assert(state.xp == Data.experience_per_enemy + 3, "gem pickups resume after the last pending choice")
end

do
    local first, replay = newRun(19), newRun(19)
    for i = 1, 3 do
        collect(first, first.progress.xpNeeded)
        collect(replay, replay.progress.xpNeeded)
        local a, b = first.progress.choices, replay.progress.choices
        assert(a.token == b.token and optionIds(a) == optionIds(b), "seeded replays see the same option order")
        assert(Progress.choose(first.progress, first, a.token, "speed"))
        assert(Progress.choose(replay.progress, replay, b.token, "speed"))
    end
end

do
    local baseline, grown = newRun(), newRun()
    collect(grown, grown.progress.xpNeeded)
    assert(Progress.choose(grown.progress, grown, grown.progress.choices.token, "weapon"))
    local health, step = 100, 0.05
    local starter = WeaponData.wind_blade.levels[1]
    local targetX = math.min(starter.speed * step, starter.range) / 2
    local function damage(run)
        local enemy = { id = 1, x = targetX, y = 0, radius = 0.6, health = health }
        run.enemies.active[1] = enemy
        Weapons.step(run.weapons, run, step)
        return health - enemy.health
    end
    local levelOneDamage, levelTwoDamage = damage(baseline), damage(grown)
    assert(grown.weapons.level == 2 and levelTwoDamage > levelOneDamage,
        "a chosen weapon upgrade must strengthen subsequent real projectile damage")
    assert(levelOneDamage == WeaponData.wind_blade.levels[1].damage)
    assert(levelTwoDamage == WeaponData.wind_blade.levels[2].damage)
end

do
    local run = newRun()
    local state = run.progress
    local total = 0
    for _, threshold in ipairs(Data.experience_to_next) do
        total = total + threshold
    end

    drop(run, 1, Data.magnet_radius + 1, 12)
    collect(run, total + 20)
    assert(state.level == #Data.experience_to_next + 1 and state.xpNeeded == nil and state.xp == 0,
        "experience saturates at maximum level and drops its remainder")
    assert(not drop(run, 2) and #state.pickups == 0, "max-level runs discard and stop spawning gems")

    for _ = 1, #Data.experience_to_next do
        local choice = state.choices
        local ids = optionIds(choice)
        if run.weapons.level == #WeaponData.wind_blade.levels then
            assert(not ids:find("weapon", 1, true), "a capped weapon is not offered")
        end
        if state.speedUpgrades == Data.max_speed_upgrades then
            assert(not ids:find("speed", 1, true), "capped movement speed is not offered")
        end
        if state.healthUpgrades == Data.max_health_upgrades then
            assert(not ids:find("health", 1, true), "capped max health is not offered")
        end
        local selected = ids:find("weapon", 1, true) and "weapon" or choice.options[1].id
        assert(Progress.choose(state, run, choice.token, selected))
    end
    assert(not Progress.hasChoice(state) and state.pending == 0, "every pending choice is settled")
end

print("Lua experience, gem attraction, deterministic choices, and weapon growth passed")
