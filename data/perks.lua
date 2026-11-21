return {
    max_owned = 3,
    choice_count = 3,
    cards = {
        {
            id = "reed_stride", label = "踏苇行印",
            movement_only = true,
            add = { crit_chance = 0.06 },
            multiply = { cooldown = 0.88 },
        },
        {
            id = "tidal_dial", label = "潮刻轮",
            cycle = { period_ticks = 360, active_ticks = 120 },
            add = { damage = 0.12, area = 0.16 },
            multiply = { projectile_speed = 1.14, duration = 1.1 },
        },
        {
            id = "cinder_refrain", label = "余烬回响",
            trigger = { kind = "kill", duration_ticks = 36, cooldown_ticks = 96 },
            multiply = { damage = 1.2 },
        },
        {
            id = "golden_balm", label = "金蕊润息",
            trigger = {
                kind = "pickup", item = "coin", cooldown_ticks = 90,
                action = { kind = "heal", amount = 5 },
            },
        },
        {
            id = "spring_mark", label = "春脉归契",
            trigger = { kind = "lethal", once = true, action = { kind = "revive", health_fraction = 0.38 } },
        },
    },
}
