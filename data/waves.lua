return {
    capacity = 300,
    spawnDistance = 18,
    despawnDistance = 48,
    contactIntervalTicks = 30,
    types = {
        drift = { radius = 0.6, speed = 3.2, health = 5, contactDamage = 6 },
        sentinel = { radius = 0.95, speed = 1.9, health = 15, contactDamage = 12 },
    },
    spawns = {
        { tick = 120, kind = "drift", count = 3 },
        { tick = 360, kind = "drift", count = 5 },
        { tick = 600, kind = "sentinel", count = 1 },
        { tick = 600, kind = "drift", count = 6 },
        { tick = 900, kind = "drift", count = 8 },
        { tick = 900, kind = "sentinel", count = 2 },
    },
}
