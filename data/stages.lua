local introductory = require("data.waves")
local spawns = {}
for _, wave in ipairs(introductory.spawns) do
    spawns[#spawns + 1] = wave
end

local ticks_per_second = 60
local duration_seconds = 30 * 60
for second = 20, duration_seconds - 10, 10 do
    local tier = math.floor(second / 300)
    spawns[#spawns + 1] = {
        tick = second * ticks_per_second,
        kind = "drift",
        count = 4 + 2 * tier,
    }
    if second % 30 == 0 then
        spawns[#spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "sentinel",
            count = 1 + tier,
        }
    end
    if second >= 50 and second % 40 == 10 then
        spawns[#spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "gale_runner",
            count = 1 + math.floor(tier / 2),
        }
    end
    if second >= 100 and second % 80 == 20 then
        spawns[#spawns + 1] = {
            tick = second * ticks_per_second,
            kind = "ember_ram",
            count = 1,
        }
    end
end

return {
    windward = {
        id = "windward",
        duration_ticks = duration_seconds * ticks_per_second,
        terminal_kind = "tempest",
        terminal_timeout_ticks = 24 * ticks_per_second,
        waves = {
            capacity = introductory.capacity,
            spawnDistance = introductory.spawnDistance,
            despawnDistance = introductory.despawnDistance,
            contactIntervalTicks = introductory.contactIntervalTicks,
            spawns = spawns,
            types = {
                drift = introductory.types.drift,
                sentinel = introductory.types.sentinel,
                gale_runner = introductory.types.gale_runner,
                ember_ram = introductory.types.ember_ram,
                tempest = {
                    radius = 1.4,
                    speed = 5.5,
                    health = 210,
                    contactDamage = 20,
                    frenzy = { healthFraction = 0.45, speed = 7.1, contactDamage = 25 },
                },
            },
        },
    },
}
