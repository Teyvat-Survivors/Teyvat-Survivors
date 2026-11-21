local Run = require("game.run")

local first = Run.new(42)
local second = Run.new(42)
assert(first.seed == 42 and first.tick == 0, "new run starts at tick zero with its seed")
assert(second.seed == first.seed and second.tick == first.tick, "same seed starts in the same state")
assert(first ~= second, "each run owns its state")
assert(Run.new().seed == 1, "omitting the seed uses the deterministic default")
assert(Run.new(2147483646).seed == 2147483646, "the largest supported seed is accepted")

for _, seed in ipairs({ 0, -1, 1.5, 2147483647, "42", math.huge, 0 / 0 }) do
    assert(not pcall(Run.new, seed), "invalid run seed must be rejected")
end

print("Lua run initialization passed")

dofile("tests/motion.lua")
dofile("tests/enemies.lua")
dofile("tests/weapons.lua")

do
    local a, b = Run.new(14), Run.new(14)
    for _ = 1, 420 do
        Run.update(a, Run.step_seconds, 0, 0)
        Run.update(b, Run.step_seconds / 2, 0, 0)
        Run.update(b, Run.step_seconds / 2, 0, 0)
    end
    assert(a.enemies.totalSpawned > 3 and #a.enemies.free > 0, "normal run spawns and recycles auto-attack kills")
    assert(a.tick == b.tick and #a.enemies.active == #b.enemies.active)
    for i, enemy in ipairs(a.enemies.active) do
        local other = b.enemies.active[i]
        assert(enemy.id == other.id and enemy.health == other.health and enemy.x == other.x and enemy.y == other.y)
    end
end
dofile("tests/build.lua")
dofile("tests/progress.lua")

do
    local run = Run.new(11)
    for id = 1, 2 do
        run.on_defeat({ id = id, x = run.player.x, y = run.player.y })
    end
    assert(Run.update(run, Run.step_seconds * 1.5, 0, 0) == 1 and run.tick == 1)
    local choice = assert(run.progress.choices)
    assert(Run.update(run, 1, 1, 0) == 0 and run.tick == 1)
    assert(not Run.choose(run, choice.token, "bad"))
    assert(Run.choose(run, choice.token, "weapon:wind_blade") and run.weapons.level == 2)
    assert(not Run.choose(run, choice.token, "weapon:wind_blade"))
    assert(Run.update(run, Run.step_seconds / 2, 1, 0) == 0 and run.tick == 1)
    assert(Run.update(run, Run.step_seconds / 2, 1, 0) == 1 and run.tick == 2)
end

dofile("tests/round.lua")

dofile("tests/combat.lua")

do
    local enemy = { health = 10, radius = 0.4, speed = 0, contactDamage = 0 }
    local stage = {
        id = "pulse",
        duration_ticks = 180,
        terminal_kind = "target",
        terminal_timeout_ticks = 10,
        waves = {
            capacity = 8, spawnDistance = 2, despawnDistance = 20, contactIntervalTicks = 30,
            spawns = { { tick = 1, kind = "target", count = 1 } },
            types = { target = enemy },
        },
    }
    local pulse = Run.new(9, stage, "frost_pulse")
    Run.update(pulse, Run.step_seconds)
    assert(pulse.kills == 1 and #pulse.enemies.active == 0, "selected area weapon uses the normal Run attack lifecycle")
    assert(Run.restart(pulse).weapons.id == "frost_pulse")
    assert(not pcall(Run.restart, pulse, false))
end

dofile("tests/loot.lua")

dofile("tests/platform_probe.lua")
