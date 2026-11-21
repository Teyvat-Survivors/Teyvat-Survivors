local introductory = require("data.waves")
local windward_spawns = {}
for _, wave in ipairs(introductory.spawns) do
    windward_spawns[#windward_spawns + 1] = wave
end

local ticks_per_second = 60
local duration_seconds = 30 * 60
for second = 20, duration_seconds - 10, 10 do
    local tier = math.floor(second / 300)
    windward_spawns[#windward_spawns + 1] = {
        tick = second * ticks_per_second,
        kind = "drift",
        count = 4 + 2 * tier,
    }
    if second % 30 == 0 then
        windward_spawns[#windward_spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "sentinel",
            count = 1 + tier,
        }
    end
    if second >= 50 and second % 40 == 10 then
        windward_spawns[#windward_spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "gale_runner",
            count = 1 + math.floor(tier / 2),
        }
    end
    if second >= 100 and second % 80 == 20 then
        windward_spawns[#windward_spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "ember_ram",
            count = 1,
        }
    end
    if second == 430 or second == 1060 then
        windward_spawns[#windward_spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "armory_warden",
            count = 1,
        }
    end
end

local function patternedSpawns(duration, pattern)
    local spawns = {}
    local second = 0
    local index = 1
    while true do
        local entry = pattern[index]
        second = second + entry.interval
        if second >= duration then
            return spawns
        end
        for _, group in ipairs(entry.groups) do
            spawns[#spawns + 1] = {
                tick = second * ticks_per_second,
                kind = group.kind,
                count = group.count,
            }
        end
        index = index % #pattern + 1
    end
end

local function waves(spawns, terminal_kind, terminal, spawn_distance)
    local types = { [terminal_kind] = terminal }
    for kind, definition in pairs(introductory.types) do
        types[kind] = definition
    end
    return {
        capacity = introductory.capacity,
        spawnDistance = spawn_distance or introductory.spawnDistance,
        despawnDistance = introductory.despawnDistance,
        contactIntervalTicks = introductory.contactIntervalTicks,
        spawns = spawns,
        types = types,
    }
end

local reeds_duration = 8 * 60
local reeds_spawns = patternedSpawns(reeds_duration, {
    { interval = 6, groups = { { kind = "drift", count = 4 } } },
    { interval = 13, groups = { { kind = "gale_runner", count = 2 }, { kind = "drift", count = 2 } } },
    { interval = 11, groups = { { kind = "sentinel", count = 1 }, { kind = "drift", count = 3 } } },
})

local ridge_duration = 6 * 60
local ridge_spawns = patternedSpawns(ridge_duration, {
    { interval = 10, groups = { { kind = "drift", count = 4 } } },
    { interval = 11, groups = { { kind = "ember_ram", count = 1 } } },
    { interval = 17, groups = { { kind = "sentinel", count = 1 }, { kind = "gale_runner", count = 2 } } },
})

local windward_waves = waves(windward_spawns, "tempest", {
    radius = 1.4,
    speed = 5.5,
    health = 210,
    contactDamage = 20,
    frenzy = { healthFraction = 0.45, speed = 7.1, contactDamage = 25 },
})
windward_waves.types.armory_warden = {
    radius = 0.68, speed = 4.1, health = 86, contactDamage = 14, xp = 9,
    elite = true, treasure_kind = "armory",
}

return {
    windward = {
        id = "windward",
        straight_lane = true,
        evolution = { earliest_tick = 3600, chest_types = { elite = true } },
        duration_ticks = duration_seconds * ticks_per_second,
        terminal_kind = "tempest",
        terminal_timeout_ticks = 24 * ticks_per_second,
        waves = windward_waves,
    },
    moon_reeds = {
        id = "moon_reeds",
        name = "月芦滩",
        duration_ticks = reeds_duration * ticks_per_second,
        terminal_kind = "reed_keeper",
        terminal_timeout_ticks = 18 * ticks_per_second,
        bounds = { min_x = -68, max_x = 68, min_y = -39, max_y = 39 },
        features = {
            { kind = "healing", x = -27, y = -12, radius = 1.8, amount = 18 },
            { kind = "healing", x = 27, y = 12, radius = 1.8, amount = 18 },
        },
        waves = waves(reeds_spawns, "reed_keeper",
            { radius = 1.2, speed = 4.7, health = 132, contactDamage = 16 }, 15),
    },
    cinder_ridge = {
        id = "cinder_ridge",
        name = "余烬峡",
        duration_ticks = ridge_duration * ticks_per_second,
        terminal_kind = "ridge_core",
        terminal_timeout_ticks = 15 * ticks_per_second,
        bounds = { min_x = -34, max_x = 34, min_y = -23, max_y = 23 },
        features = {
            { kind = "hazard", x = -13, y = 0, radius = 4, amount = 8, first_tick = 180, interval_ticks = 180 },
            { kind = "hazard", x = 13, y = 0, radius = 4, amount = 8, first_tick = 270, interval_ticks = 180 },
        },
        waves = waves(ridge_spawns, "ridge_core", {
            radius = 1.25,
            speed = 2.4,
            health = 177,
            contactDamage = 16,
            charge = { range = 10, speed = 13, windupTicks = 35, chargeTicks = 35, cooldownTicks = 75 },
        }, 14),
    },
}
