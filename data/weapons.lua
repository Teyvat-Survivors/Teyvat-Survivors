return {
    wind_blade = {
        label = "风刃",
        behavior = "projectile",
        levels = {
            { damage = 12, cooldown_ticks = 54, range = 24, speed = 28, radius = 0.28, pierce = 1 },
            { damage = 17, cooldown_ticks = 48, range = 26, speed = 31, radius = 0.33, pierce = 1 },
            { damage = 23, cooldown_ticks = 42, range = 28, speed = 34, radius = 0.39, pierce = 2 },
        },
    },
    frost_pulse = {
        label = "霜脉冲",
        behavior = "pulse",
        levels = {
            { damage = 14, cooldown_ticks = 72, radius = 4, knockback = 1.15 },
            { damage = 19, cooldown_ticks = 66, radius = 4.6, knockback = 1.4 },
        },
    },
    ember_field = {
        label = "余烬领域",
        behavior = "field",
        levels = {
            {
                damage = 4, cooldown_ticks = 96, range = 18, radius = 2.6,
                duration_ticks = 45, interval_ticks = 12, max_hits_per_target = 3,
                crit_chance = 0.15, crit_multiplier = 1.5,
            },
            {
                damage = 6, cooldown_ticks = 90, range = 20, radius = 3,
                duration_ticks = 54, interval_ticks = 12, max_hits_per_target = 4,
                crit_chance = 0.20, crit_multiplier = 1.5,
            },
        },
    },
}
