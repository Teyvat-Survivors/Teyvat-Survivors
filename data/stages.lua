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
                tempest = { radius = 1.4, speed = 5.5, health = 210, contactDamage = 20 },
            },
        },
    },
}
