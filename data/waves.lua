return {
    capacity = 300,
    spawnDistance = 18,
    despawnDistance = 48,
    contactIntervalTicks = 30,
    types = {
        drift = { radius = 0.6, speed = 3.2, health = 5, contactDamage = 6 },
        sentinel = { radius = 0.95, speed = 1.9, health = 15, contactDamage = 12, elite = true },
        gale_runner = { radius = 0.42, speed = 6.2, health = 5, contactDamage = 7 },
        ember_ram = {
            radius = 0.84,
            speed = 2.8,
            health = 24,
            contactDamage = 13,
            elite = true,
            charge = { range = 7, speed = 12, windupTicks = 45, chargeTicks = 42, cooldownTicks = 100 },
        },
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
