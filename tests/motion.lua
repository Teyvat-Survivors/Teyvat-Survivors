local Run = require("game.run")
local stages = require("data.stages")

local function near(actual, expected)
    assert(math.abs(actual - expected) < 1e-9, tostring(actual) .. " expected " .. tostring(expected))
end

local first, second = Run.new(123, stages.moon_reeds), Run.new(123, stages.moon_reeds)
for frame = 1, 60 do
    local x, y = 1, -1
    if frame > 30 then x, y = 0.5, 0 end
    assert(Run.update(first, Run.step_seconds, x, y) == 1)
    Run.update(second, Run.step_seconds / 2, x, y)
    Run.update(second, Run.step_seconds / 2, x, y)
    assert(Run.random(first) == Run.random(second))
end
assert(first.tick == 60 and second.tick == first.tick)
near(first.player.x, 3 / math.sqrt(2) + 1.5)
near(first.player.y, -3 / math.sqrt(2))
assert(first.player.x == second.player.x and first.player.y == second.player.y)
assert(first.player ~= second.player)

Run.set_paused(first, true)
Run.set_paused(first, true)
assert(Run.update(first, 2, 0, 1) == 0 and first.tick == 60)
Run.set_paused(first, false)
local events = Run.take_events(first)
assert(#events == 2 and events[1].kind == "paused" and events[2].kind == "resumed")
assert(events[1].tick == 60 and #Run.take_events(first) == 0)
assert(Run.update(first, 60, 0, 1) == 15 and first.tick == 75)
assert(not pcall(Run.update, first, -0.1, 0, 0))
assert(not pcall(Run.update, first, 0.1, math.huge, 0))

local edge = Run.new(nil, stages.moon_reeds)
edge.player.x, edge.player.y = 67.99, -38.99
Run.update(edge, Run.step_seconds, 1e300, -1e300)
assert(edge.player.x == 68 and edge.player.y == -39)
local extreme = Run.new()
Run.update(extreme, Run.step_seconds, math.mininteger, 1)
near(extreme.player.x, -0.1)
assert(extreme.player.y == 0 and extreme.player.facing_y == 0)
Run.update(extreme, Run.step_seconds, 0, 1)
near(extreme.player.x, -0.1)
assert(extreme.player.y == 0 and extreme.player.facing_x == -1)
assert(not pcall(Run.update, extreme, 0.1, false, 0))
print("Fixed-step motion, seed, pause, and bounds passed")
