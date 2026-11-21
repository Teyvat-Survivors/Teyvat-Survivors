local Profile = require("game.profile")
local PowerUps = require("data.powerups")

local function expect_error(ok, reason, expected)
    assert(not ok and reason == expected, "expected " .. expected .. ", got " .. tostring(reason))
end

local function rejects_saved(save)
    assert(not pcall(Profile.load, save), "invalid save should fail")
end

do
    local profile = Profile.load()
    assert(profile.version == 1 and profile.coins == 0 and next(profile.ranks) == nil)
    assert(Profile.cost(profile, "vitality") == PowerUps.upgrades.vitality.costs[1])
    local ok, why = Profile.buy(profile, "vitality")
    expect_error(ok, why, "insufficient_coins")
    ok, why = Profile.buy(profile, "typo")
    expect_error(ok, why, "unknown_upgrade")
    assert(profile.coins == 0 and profile.invested == 0 and next(profile.ranks) == nil)
    local stats = Profile.stats(profile)
    stats.max_health = 0
    assert(Profile.stats(profile).max_health == 100)
end

do
    local profile = Profile.load({ version = 0, coins = 400, ranks = { vitality = 2 } })
    assert(profile.coins == 400 and profile.invested == 120 and profile.ranks.vitality == 2)
    assert(Profile.stats(profile).max_health == 116 and Profile.cost(profile, "vitality") == 120)
    assert(Profile.buy(profile, "vitality") and Profile.buy(profile, "vitality"))
    assert(Profile.stats(profile).max_health == 132 and profile.coins == 100 and profile.invested == 420)
    local ok, why = Profile.buy(profile, "vitality")
    expect_error(ok, why, "max_rank")
    assert(Profile.buy(profile, "agility"))
    assert(Profile.stats(profile).speed == 6.25 and profile.coins == 40)
    local saved = Profile.export(profile)
    local reloaded = Profile.load(saved)
    saved.ranks.vitality = 1
    profile.ranks.vitality = 2
    assert(reloaded.ranks.vitality == 4 and reloaded.invested == 480)
    assert(Profile.refund(reloaded) == 480 and Profile.refund(reloaded) == 0)
    assert(reloaded.coins == 520 and next(reloaded.ranks) == nil and Profile.stats(reloaded).max_health == 100)
end

do
    local profile = Profile.load({ coins = 10 })
    local id = assert(Profile.begin_run(profile))
    local active, why = Profile.begin_run(profile)
    expect_error(active, why, "run_active")
    profile = Profile.load(Profile.export(profile))
    assert(profile.active_run_id == id)
    local ok
    ok, why = Profile.settle(profile, id + 1, { coins = 99, outcome = "defeated" })
    expect_error(ok, why, "unknown_run")
    for _, amount in ipairs({ -1, 1.5, 0 / 0, math.huge, "5" }) do
        ok, why = Profile.settle(profile, id, { coins = amount, outcome = "defeated" })
        expect_error(ok, why, "invalid_result")
    end
    ok, why = Profile.settle(profile, id, { coins = 70, outcome = "unfinished" })
    expect_error(ok, why, "invalid_result")
    assert(profile.coins == 10 and profile.completed_runs == 0 and profile.active_run_id == id)
    assert(Profile.settle(profile, id, { coins = 70, outcome = "defeated" }))
    profile = Profile.load(Profile.export(profile))
    ok, why = Profile.settle(profile, id, { coins = 70, outcome = "defeated" })
    expect_error(ok, why, "run_closed")
    assert(profile.coins == 80 and profile.completed_runs == 1 and profile.wins == 0)
    local abandoned = assert(Profile.begin_run(profile))
    assert(abandoned == id + 1 and Profile.abandon_run(profile, abandoned))
    profile = Profile.load(Profile.export(profile))
    local next_id = assert(Profile.begin_run(profile))
    assert(next_id == abandoned + 1)
    ok, why = Profile.settle(profile, abandoned, { coins = 999, outcome = "finale_survived" })
    expect_error(ok, why, "run_closed")
    assert(Profile.settle(profile, next_id, { coins = 0, outcome = "finale_defeated" }))
    assert(profile.coins == 80 and profile.completed_runs == 2 and profile.wins == 1)
end

do
    local max_value = 2147483647
    local profile = Profile.load({ version = 0, coins = max_value - 45, ranks = { vitality = 1 } })
    local id = assert(Profile.begin_run(profile))
    local ok, why = Profile.settle(profile, id, { coins = 1, outcome = "finale_survived" })
    expect_error(ok, why, "balance_limit")
    assert(profile.active_run_id == id and profile.completed_runs == 0 and profile.invested == 45)
    assert(Profile.settle(profile, id, { coins = 0, outcome = "finale_survived" }))
    assert(Profile.refund(profile) == 45 and profile.coins == max_value and profile.wins == 1)

    local exhausted = Profile.export(profile)
    exhausted.last_run_id = max_value
    ok, why = Profile.begin_run(Profile.load(exhausted))
    expect_error(ok, why, "run_id_exhausted")

    rejects_saved({ version = 2 })
    rejects_saved({ coins = -1 })
    rejects_saved({ coins = false })
    rejects_saved({ coins = max_value, ranks = { vitality = 1 } })
    rejects_saved({ ranks = { agility = 4 } })
    rejects_saved({ ranks = { unknown = 1 } })
    local invalid = Profile.export(profile)
    invalid.active_run_id = 2
    rejects_saved(invalid)
    invalid.active_run_id = nil
    invalid.wins = invalid.completed_runs + 1
    rejects_saved(invalid)
end

print("Lua profile migration, purchases, refunds, stats, and durable duplicate-safe settlement passed")
