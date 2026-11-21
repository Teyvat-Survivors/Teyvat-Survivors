local Passives = require("data.passives")
local Build = {}

local function addCatalog(target, definitions, kind)
    for id, definition in pairs(definitions) do
        target[#target + 1] = {
            id = id,
            key = kind .. ":" .. id,
            kind = kind,
            label = definition.label or id,
            weight = definition.weight or 1,
            upgrade_weight = definition.upgrade_weight,
            armory_unlock = definition.armory_unlock,
            max_level = definition.max_level or #definition.levels,
            per_level = definition.per_level,
        }
    end
end

function Build.new(randomUnit, weaponCatalog, startingWeapon, overrides, weaponUnlocks)
    assert(type(randomUnit) == "function", "build requires the run's random source")
    local rules = {}
    for name, value in pairs(Passives.rules) do
        rules[name] = value
    end
    for name, value in pairs(overrides or {}) do
        rules[name] = value
    end
    assert(rules.weapon_slots >= 0 and rules.weapon_slots % 1 == 0, "invalid weapon slot count")
    assert(rules.passive_slots >= 0 and rules.passive_slots % 1 == 0, "invalid passive slot count")
    assert(rules.choice_count >= 1 and rules.choice_count % 1 == 0, "invalid choice count")
    for _, action in ipairs({ "reroll", "skip", "banish" }) do
        assert(rules[action] >= 0 and rules[action] % 1 == 0, "invalid upgrade action count")
    end
    assert(rules.skip_experience_fraction >= 0 and rules.skip_experience_fraction < 1, "invalid skip experience")
    assert(rules.fallback_heal > 0 and rules.fallback_heal < math.huge, "invalid fallback health")

    local catalog = {}
    addCatalog(catalog, weaponCatalog, "weapon")
    addCatalog(catalog, Passives.items, "passive")
    table.sort(catalog, function(a, b)
        return a.key < b.key
    end)
    for _, item in ipairs(catalog) do
        assert(item.weight >= 0 and item.weight < math.huge, "invalid item weight")
        assert(item.upgrade_weight == nil or (item.upgrade_weight >= 0 and item.upgrade_weight < math.huge),
            "invalid owned item upgrade weight")
        assert(item.max_level >= 1 and item.max_level % 1 == 0, "invalid item level cap")
    end

    assert(weaponUnlocks == nil or type(weaponUnlocks) == "table", "invalid weapon unlocks")
    local unlocks = {}
    for id, unlocked in pairs(weaponUnlocks or {}) do
        if unlocked == true and weaponCatalog[id] then unlocks[id] = true end
    end
    local weapons = {}
    local starters = type(startingWeapon) == "table" and startingWeapon or { startingWeapon }
    assert(#starters <= rules.weapon_slots, "starting weapons exceed available slots")
    for _, id in ipairs(starters) do
        local definition = weaponCatalog[id]
        assert(definition and not weapons[id], "invalid or repeated starting weapon")
        assert(not definition.armory_unlock or unlocks[id], "starting weapon is locked")
        weapons[id] = 1
    end

    return {
        weapons = weapons, weapon_unlocks = unlocks,
        passives = {},
        catalog = catalog,
        rules = rules,
        remaining = { reroll = rules.reroll, skip = rules.skip, banish = rules.banish },
        banished = {},
        token = 0,
        randomUnit = randomUnit,
    }
end

local function size(owned)
    local count = 0
    for _ in pairs(owned) do
        count = count + 1
    end
    return count
end

local function candidates(build)
    local weaponsFull = size(build.weapons) >= build.rules.weapon_slots
    local passivesFull = size(build.passives) >= build.rules.passive_slots
    local pool = {}
    for _, item in ipairs(build.catalog) do
        local owned, full = build.passives, passivesFull
        if item.kind == "weapon" then
            owned, full = build.weapons, weaponsFull
        end
        local level = owned[item.id]
        local weight = (level and item.upgrade_weight) or item.weight
        if weight > 0 and not item.armory_unlock and not build.banished[item.key]
            and ((level and level < item.max_level) or (not level and not full)) then
            pool[#pool + 1] = {
                key = item.key,
                id = item.id,
                kind = item.kind,
                label = item.label,
                level = (level or 0) + 1,
                weight = weight,
            }
        end
    end
    return pool
end

local function draw(build, pool)
    local total = 0
    for _, option in ipairs(pool) do
        total = total + option.weight
    end

    local unit = build.randomUnit()
    assert(type(unit) == "number" and unit >= 0 and unit < 1, "random source must return a value in [0, 1)")
    local threshold = unit * total
    for i, option in ipairs(pool) do
        threshold = threshold - option.weight
        if threshold < 0 then
            return table.remove(pool, i)
        end
    end
    return table.remove(pool)
end

local function armoryEligible(build, item)
    if item.kind ~= "weapon" or build.weapons[item.id] or build.banished[item.key] then
        return false
    end
    if item.armory_unlock then
        return build.weapon_unlocks[item.id] == true
    end
    return item.weight > 0
end

function Build.armory_options(build, limit)
    local options, base = {}, {}
    if size(build.weapons) >= build.rules.weapon_slots then
        return options
    end
    for _, item in ipairs(build.catalog) do
        if armoryEligible(build, item) then
            if item.armory_unlock and #options < limit then
                options[#options + 1] = item
            elseif not item.armory_unlock then
                base[#base + 1] = item
            end
        end
    end
    while #options < limit and #base > 0 do
        options[#options + 1] = draw(build, base)
    end
    return options
end

function Build.claim_armory(build, id)
    if size(build.weapons) >= build.rules.weapon_slots then
        return false
    end
    for _, item in ipairs(build.catalog) do
        if item.id == id and armoryEligible(build, item) then
            build.weapons[id] = 1
            return true
        end
    end
    return false
end

local function publish(build, pool, first)
    local options = {}
    if first then
        options[1] = first
    end
    while #options < build.rules.choice_count and #pool > 0 do
        options[#options + 1] = draw(build, pool)
    end
    if #options == 0 then
        options[1] = { key = "reward:heal", kind = "reward", id = "heal", label = "恢复生命" }
    end

    build.token = build.token + 1
    build.choices = { token = build.token, options = options }
    return build.choices
end

function Build.offer(build)
    if build.choices then
        return build.choices
    end
    return publish(build, candidates(build))
end

local function optionFor(build, token, key)
    local choice = build.choices
    if choice and choice.token == token then
        for _, option in ipairs(choice.options) do
            if option.key == key then
                return option
            end
        end
    end
end

function Build.choose(build, token, key)
    local option = optionFor(build, token, key)
    if not option then
        return nil
    end
    build.choices = nil
    if option.kind == "reward" then
        return { kind = "reward", id = option.id, amount = build.rules.fallback_heal }
    end

    local owned = option.kind == "weapon" and build.weapons or build.passives
    owned[option.id] = option.level
    return { kind = option.kind, id = option.id, level = option.level }
end

function Build.reroll(build, token)
    local choice = build.choices
    if not choice or choice.token ~= token or build.remaining.reroll == 0 then
        return nil
    end
    local seen = {}
    for _, option in ipairs(choice.options) do
        seen[option.key] = true
    end
    local pool, alternatives = candidates(build), {}
    for _, option in ipairs(pool) do
        if not seen[option.key] then
            alternatives[#alternatives + 1] = option
        end
    end
    if #alternatives == 0 then
        return nil
    end

    local first = draw(build, alternatives)
    for i, option in ipairs(pool) do
        if option == first then
            table.remove(pool, i)
            break
        end
    end
    build.remaining.reroll = build.remaining.reroll - 1
    return publish(build, pool, first)
end

function Build.skip(build, token)
    local choice = build.choices
    if choice and choice.token == token and build.remaining.skip > 0 then
        build.remaining.skip = build.remaining.skip - 1
        build.choices = nil
        return { kind = "skip", experience_fraction = build.rules.skip_experience_fraction }
    end
end

function Build.banish(build, token, key)
    local option = optionFor(build, token, key)
    if option and option.kind ~= "reward" and build.remaining.banish > 0 then
        build.remaining.banish = build.remaining.banish - 1
        build.banished[option.key] = true
        build.choices = nil
        return { kind = "banish", id = option.id, item_kind = option.kind }
    end
end

function Build.stats(build)
    local stats = {
        damage = 1, range = 1, area = 1, projectile_speed = 1, duration = 1, cooldown = 1,
        knockback = 1, speed = 1, magnet_radius = 1, experience = 1,
        armor = 0, max_health_bonus = 0, crit_chance = 0, pierce = 0,
    }
    for _, item in ipairs(build.catalog) do
        local level = item.kind == "passive" and build.passives[item.id]
        if level then
            for stat, perLevel in pairs(item.per_level) do
                stats[stat] = stats[stat] + level * perLevel
            end
        end
    end
    return stats
end

return Build
