local Run = require("game.run")

local function trial(duration, health, contact)
    local kind = { health = health, radius = 0.7, speed = 0, contactDamage = contact }
    return {
        id = "test",
        duration_ticks = duration,
        terminal_kind = "tempest",
        terminal_timeout_ticks = 10,
        waves = {
            capacity = 4,
            spawnDistance = 0,
            despawnDistance = 48,
            contactIntervalTicks = 30,
            spawns = { { tick = 2, kind = "drift", count = 1 } },
            types = { drift = kind, tempest = kind },
        },
    }
end

local early = Run.new(7, trial(120, 1000, 100))
assert(Run.update(early, 0.25) == 2)
assert(early.result.outcome == "defeated" and early.result.tick == 2 and early.result.kills == 0)
assert(Run.update(early, 1) == 0)
local events = Run.take_events(early)
assert(#events == 1 and events[1].kind == "finished")
assert(#Run.take_events(early) == 0 and not Run.choose(early, 1, "weapon:wind_blade"))
assert(Run.restart(early).result == nil)

local win = Run.new(9, trial(3, 1, 0))
Run.update(win, 0.25)
assert(win.terminal_id and win.result.outcome == "finale_defeated" and win.result.kills >= 1)
events = Run.take_events(win)
assert(#events == 2 and events[1].kind == "finale_started" and events[2].kind == "finished")

local timeout = Run.new(9, trial(3, 1000, 0))
Run.update(timeout, 0.25)
assert(timeout.result.outcome == "finale_survived" and timeout.tick == 13)
local restarted = Run.restart(timeout)
assert(restarted.tick == 0 and restarted.kills == 0 and not restarted.terminal_id)
assert(#restarted.enemies.active == 0 and #restarted.enemies.free == 0 and not restarted.progress.choices)
assert(restarted.random_state == timeout.seed and restarted.weapons.level == 1)

local escapeFixture = trial(1, 1000, 0)
escapeFixture.terminal_timeout_ticks = 100
escapeFixture.waves.spawnDistance = 1
escapeFixture.waves.despawnDistance = 2
local escape = Run.new(11, escapeFixture)
Run.update(escape, Run.step_seconds)
local terminal = escape.enemies.active[1]
for _ = 1, 2 do
    Run.update(escape, 0.25, escape.player.x - terminal.x, escape.player.y - terminal.y)
end
assert(not escape.result and #escape.enemies.active == 1)
assert(escape.enemies.active[1].id == escape.terminal_id, "the finale enemy remains active outside the ordinary cull range")

local function advance(run)
    if run.loot.choices then
        assert(Run.choose_treasure(run, run.loot.choices.token, "coins"))
        return
    end
    local choice = run.progress.choices
    if choice then
        local selected = choice.options[1].key
        for _, option in ipairs(choice.options) do
            if option.key == "weapon:wind_blade" then selected = option.key end
        end
        assert(Run.choose(run, choice.token, selected))
    else
        local angle = run.tick * 0.0018
        local dx = 41 * math.cos(angle) - run.player.x
        local dy = 41 * math.sin(angle) - run.player.y
        Run.update(run, 0.25, dx, dy)
    end
end

local full = Run.new(31)
for _ = 1, 10000 do
    if full.result then break end
    advance(full)
end
assert(full.terminal_id and full.result, string.format("the 30-minute run must reach its final event (%d ticks)", full.tick))
assert(full.stage.duration_ticks == 108000 and full.result.tick >= 108000)
assert(full.enemies.totalSpawned > 900 and full.result.kills > 100)
print("Lua full 30-minute round, finale outcomes, and restart passed")
