return {
    max_owned = 3,
    choice_count = 3,
    rerolls = 1,
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
        {
            id = "gem_catalyst", label = "晶砂引火",
            multiply = { experience = 0 },
            trigger = {
                kind = "experience", cooldown_ticks = 1,
                action = { kind = "pulse", amount = 2, amount_scale = 0.68, radius = 3.6 },
            },
        },
        {
            id = "mirror_braid", label = "镜羽双编",
            add = { echo_shots = 1 },
            multiply = { echo_damage = 0.56 },
        },
        {
            id = "ashen_arrival", label = "灰羽归尘",
            trigger = {
                kind = "projectile_end", cooldown_ticks = 33,
                action = { kind = "pulse", center = "event", amount = 8, radius = 2.1 },
            },
        },
        {
            id = "fountain_grace", label = "泉心护鸣",
            multiply = { healing = 1.3 },
            trigger = {
                kind = "heal", cooldown_ticks = 47,
                action = { kind = "pulse", amount = 3, amount_scale = 0.45, radius = 3 },
            },
        },
        {
            id = "shell_turn", label = "折壳纹",
            add = { bounces = 1, pierce = 1 },
        },
        {
            id = "wayfarer_compass", label = "拾星罗针",
            trigger = {
                kind = "tick", delay_ticks = 144, cooldown_ticks = 144,
                action = { kind = "echo_magnet", radius = 16, pickup_cap = 8 },
            },
        },
        {
            id = "iron_ledger", label = "铁枝回录",
            add = { armor = 2 },
            trigger = {
                kind = "hit", cooldown_ticks = 30,
                action = { kind = "pulse", amount = 4, amount_scale = 0.32, radius = 2.7 },
            },
        },
        {
            id = "first_chord", label = "开弦之约",
            window_ticks = 420,
            add = { echo_shots = 1 },
            multiply = { echo_damage = 0.74 },
        },
        {
            id = "pearl_trail", label = "返珠长线",
            multiply = { return_range = 1.4 },
        },
        {
            id = "rime_wake", label = "霜影留踪",
            trigger = {
                kind = "kill", requires_slow = true, cooldown_ticks = 36,
                action = { kind = "pulse", center = "event", amount = 9, radius = 2.4 },
            },
        },
        {
            id = "sowing_clock", label = "双候时册",
            cycle = { period_ticks = 330, active_ticks = 150 },
            multiply = { experience = 1.17 },
            off_multiply = { damage = 1.12, cooldown = 1.07 },
        },
        {
            id = "snowbell", label = "积雪风铃",
            trigger = {
                kind = "tick", delay_ticks = 75, cooldown_ticks = 150,
                action = { kind = "stasis", radius = 3.8, duration_ticks = 20, speed_factor = 0, target_cap = 4 },
            },
        },
        {
            id = "jade_refraction", label = "琢玉映芒",
            add = { crit_chance = 0.13 },
            multiply = { crit_damage = 1.18 },
        },
        {
            id = "long_tide", label = "息潮延契",
            growth = { basis = "levels_gained", cap = 8, add = { duration = 0.045 } },
            add = { duration = 0.09 },
        },
        {
            id = "petal_dial", label = "舒瓣刻轴",
            cycle = { period_ticks = 270, active_ticks = 72 },
            growth = { basis = "levels_gained", cap = 6, add = { range = 0.035 } },
            add = { area = 0.23 },
        },
        {
            id = "vacant_star", label = "虚星余位",
            growth = {
                basis = "empty_weapon_slots", cap = 4,
                add = { damage = 0.09, cooldown = -0.05 },
            },
        },
        {
            id = "orbit_recall", label = "回星引路",
            multiply = { magnet_radius = 1.2 },
            trigger = {
                kind = "experience", cooldown_ticks = 66,
                action = { kind = "pulse", amount = 6, radius = 4.7 },
            },
        },
    },
}
