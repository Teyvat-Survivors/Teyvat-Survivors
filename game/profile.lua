local PowerUps = require("data.powerups")

local Profile = {}

local VERSION = 1
local MAX_VALUE = 2147483647
local outcomes = {
    defeated = "loss",
    finale_defeated = "win",
    finale_survived = "win",
}

local function bounded_integer(value, maximum)
    return type(value) == "number" and value >= 0 and value <= maximum and value % 1 == 0
end

local function copy_map(source)
    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function snapshot(saved, ranks)
    return {
        version = VERSION,
        coins = saved.coins,
        ranks = ranks,
        invested = saved.invested,
        last_run_id = saved.last_run_id,
        active_run_id = saved.active_run_id,
        completed_runs = saved.completed_runs,
        wins = saved.wins,
    }
end

local function empty_profile()
    return {
        version = VERSION,
        coins = 0,
        ranks = {},
        invested = 0,
        last_run_id = 0,
        completed_runs = 0,
        wins = 0,
    }
end

-- Version 0 held the balance and ranks. Reconstruct what those ranks cost.
local function migrate(saved)
    local profile = empty_profile()
    if saved.coins ~= nil then
        profile.coins = saved.coins
    end
    if saved.ranks ~= nil then
        assert(type(saved.ranks) == "table", "invalid saved power-up ranks")
        profile.ranks = saved.ranks
        for id, rank in pairs(profile.ranks) do
            local upgrade = PowerUps.upgrades[id]
            assert(upgrade and bounded_integer(rank, #upgrade.costs), "invalid saved power-up rank")
            for level = 1, rank do
                profile.invested = profile.invested + upgrade.costs[level]
            end
        end
    end
    return profile
end

function Profile.load(saved)
    if saved == nil then
        return empty_profile()
    end
    assert(type(saved) == "table", "profile save must be a table")
    if saved.version == nil or saved.version == 0 then
        saved = migrate(saved)
    end
    assert(saved.version == VERSION, "unsupported profile version")
    assert(bounded_integer(saved.coins, MAX_VALUE), "invalid saved balance")
    assert(bounded_integer(saved.invested, MAX_VALUE - saved.coins), "invalid saved investment")
    assert(type(saved.ranks) == "table", "invalid saved power-up ranks")
    assert(bounded_integer(saved.last_run_id, MAX_VALUE), "invalid saved run sequence")
    assert(saved.active_run_id == nil or (saved.last_run_id > 0 and saved.active_run_id == saved.last_run_id),
        "invalid saved active run")
    local closed_runs = saved.last_run_id - (saved.active_run_id and 1 or 0)
    assert(bounded_integer(saved.completed_runs, closed_runs), "invalid saved run count")
    assert(bounded_integer(saved.wins, saved.completed_runs), "invalid saved win count")

    local levels = 0
    local ranks = {}
    for id, rank in pairs(saved.ranks) do
        local upgrade = PowerUps.upgrades[id]
        assert(upgrade and bounded_integer(rank, #upgrade.costs), "invalid saved power-up rank")
        if rank > 0 then
            ranks[id] = rank
            levels = levels + rank
        end
    end
    assert((levels == 0 and saved.invested == 0) or (levels > 0 and saved.invested >= levels),
        "saved investment contradicts power-up ranks")

    return snapshot(saved, ranks)
end

function Profile.export(profile)
    return snapshot(profile, copy_map(profile.ranks))
end

function Profile.cost(profile, id)
    local upgrade = PowerUps.upgrades[id]
    if not upgrade then
        return nil, "unknown_upgrade"
    end
    local price = upgrade.costs[(profile.ranks[id] or 0) + 1]
    if not price then
        return nil, "max_rank"
    end
    return price
end

function Profile.buy(profile, id)
    local price, reason = Profile.cost(profile, id)
    if not price then
        return false, reason
    end
    if profile.coins < price then
        return false, "insufficient_coins"
    end
    profile.coins = profile.coins - price
    profile.invested = profile.invested + price
    profile.ranks[id] = (profile.ranks[id] or 0) + 1
    return true
end

function Profile.refund(profile)
    local amount = profile.invested
    profile.coins = profile.coins + amount
    profile.invested = 0
    profile.ranks = {}
    return amount
end

function Profile.stats(profile)
    local stats = copy_map(PowerUps.base_stats)
    for id, rank in pairs(profile.ranks) do
        local upgrade = PowerUps.upgrades[id]
        stats[upgrade.stat] = stats[upgrade.stat] + upgrade.bonus * rank
    end
    return stats
end

function Profile.begin_run(profile)
    if profile.active_run_id then
        return nil, "run_active"
    end
    if profile.last_run_id >= MAX_VALUE then
        return nil, "run_id_exhausted"
    end
    profile.last_run_id = profile.last_run_id + 1
    profile.active_run_id = profile.last_run_id
    return profile.active_run_id
end

local function active_run(profile, id)
    if not bounded_integer(id, profile.last_run_id) or id == 0 then
        return false, "unknown_run"
    end
    if id ~= profile.active_run_id then
        return false, "run_closed"
    end
    return true
end

function Profile.abandon_run(profile, id)
    local active, reason = active_run(profile, id)
    if not active then
        return false, reason
    end
    profile.active_run_id = nil
    return true
end

-- Persist the exported state as a unit before acknowledging a settlement.
function Profile.settle(profile, id, result)
    local active, reason = active_run(profile, id)
    if not active then
        return false, reason
    end
    if type(result) ~= "table" or not outcomes[result.outcome] or not bounded_integer(result.coins, MAX_VALUE) then
        return false, "invalid_result"
    end
    if result.coins > MAX_VALUE - profile.coins - profile.invested then
        return false, "balance_limit"
    end

    profile.coins = profile.coins + result.coins
    profile.completed_runs = profile.completed_runs + 1
    if outcomes[result.outcome] == "win" then
        profile.wins = profile.wins + 1
    end
    profile.active_run_id = nil
    return true
end

return Profile
