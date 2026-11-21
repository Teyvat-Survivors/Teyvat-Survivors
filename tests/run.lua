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
