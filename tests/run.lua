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

dofile("tests/platform_probe.lua")
