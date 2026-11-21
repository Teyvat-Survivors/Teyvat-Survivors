return {
    stone_ward = {
        label = "砾石护壁",
        behavior = "ward",
        levels = {
            { cooldown_ticks = 160, duration_ticks = 112, charges = 1 },
            { cooldown_ticks = 148, duration_ticks = 132, charges = 2 },
        },
    },
    stillwater_seal = {
        label = "静水印",
        behavior = "stasis",
        levels = {
            { cooldown_ticks = 120, radius = 6, duration_ticks = 16, speed_factor = 0.25, target_cap = 4 },
            { cooldown_ticks = 104, radius = 7.5, duration_ticks = 24, speed_factor = 0, target_cap = 7 },
        },
    },
    dawn_break = {
        label = "破晓环",
        behavior = "purge",
        levels = {
            { cooldown_ticks = 220, radius = 5.5, elite_damage = 15 },
            { cooldown_ticks = 192, radius = 7.5, elite_damage = 23 },
        },
    },
    echo_bell = {
        label = "回响铃",
        behavior = "echo_magnet",
        levels = {
            { cooldown_ticks = 120, radius = 10, pickup_cap = 3 },
            { cooldown_ticks = 96, radius = 15, pickup_cap = 6 },
        },
    },
    wind_blade = {
        label = "风刃", weight = 18,
        label = "风刃",
        behavior = "projectile",
        levels = {
            { damage = 12, cooldown_ticks = 54, range = 24, speed = 28, radius = 0.28, pierce = 1 },
            { damage = 17, cooldown_ticks = 48, range = 26, speed = 31, radius = 0.33, pierce = 1 },
            { damage = 23, cooldown_ticks = 42, range = 28, speed = 34, radius = 0.39, pierce = 2 },
        },
    },
    frost_pulse = {
        label = "霜环", weight = 14,
        label = "霜脉冲",
        behavior = "pulse",
        levels = {
            { damage = 14, cooldown_ticks = 72, radius = 4, knockback = 1.15 },
            { damage = 19, cooldown_ticks = 66, radius = 4.6, knockback = 1.4 },
        },
    },
    ember_field = {
        label = "余烬阵", weight = 12,
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
    ridge_dart = {
        label = "岭锋",
        behavior = "projectile",
        aim = "facing",
        levels = {
            { damage = 15, cooldown_ticks = 54, range = 28, speed = 36, radius = 0.27, pierce = 0 },
            { damage = 22, cooldown_ticks = 47, range = 32, speed = 39, radius = 0.34, pierce = 1 },
        },
    },
    star_spark = {
        label = "星火针",
        behavior = "projectile",
        aim = "random",
        levels = {
            { damage = 9, cooldown_ticks = 34, range = 20, speed = 45, radius = 0.25, pierce = 0 },
            { damage = 13, cooldown_ticks = 30, range = 25, speed = 50, radius = 0.28, pierce = 0 },
        },
    },
    petal_fan = {
        label = "飞瓣扇",
        behavior = "projectile",
        levels = {
            {
                damage = 7, cooldown_ticks = 65, range = 19, speed = 25, radius = 0.22,
                pierce = 0, shots = 3, angle_step = 0.24,
            },
            {
                damage = 10, cooldown_ticks = 60, range = 23, speed = 28, radius = 0.26,
                pierce = 0, shots = 5, angle_step = 0.19,
            },
        },
    },
    stone_lob = {
        label = "坠岩",
        behavior = "projectile",
        motion = "lob",
        levels = {
            { damage = 16, cooldown_ticks = 85, range = 19, speed = 12, radius = 0.9, pierce = 1, apex = 1.8 },
            { damage = 21, cooldown_ticks = 78, range = 22, speed = 15, radius = 1.2, pierce = 2, apex = 2.2 },
        },
    },
    echo_shard = {
        label = "鸣壁晶片",
        behavior = "projectile",
        aim = "facing",
        motion = "rebound",
        levels = {
            { damage = 11, cooldown_ticks = 65, range = 38, speed = 34, radius = 0.36, pierce = 2, bounces = 1 },
            { damage = 15, cooldown_ticks = 57, range = 47, speed = 38, radius = 0.44, pierce = 3, bounces = 2 },
        },
    },
    willow_return = {
        label = "回柳刃",
        behavior = "projectile",
        motion = "return",
        levels = {
            { damage = 13, cooldown_ticks = 75, range = 12, speed = 24, radius = 0.48, pierce = 4, return_ratio = 1.5 },
            { damage = 17, cooldown_ticks = 66, range = 15, speed = 28, radius = 0.56, pierce = 6, return_ratio = 1.6 },
        },
    },
    dew_aura = {
        label = "露潮护域",
        behavior = "field",
        field_anchor = "player",
        levels = {
            {
                damage = 3, cooldown_ticks = 108, radius = 3.8,
                duration_ticks = 90, interval_ticks = 15, max_hits_per_target = 6,
            },
            {
                damage = 4, cooldown_ticks = 102, radius = 4.2,
                duration_ticks = 96, interval_ticks = 12, max_hits_per_target = 8,
            },
        },
    },
    jade_satellite = {
        label = "玉轮随星",
        behavior = "field",
        field_anchor = "orbit",
        levels = {
            {
                damage = 7, cooldown_ticks = 160, radius = 0.7,
                duration_ticks = 144, interval_ticks = 6, max_hits_per_target = 6,
                orbit_radius = 3.2, orbit_period_ticks = 72,
            },
            {
                damage = 9, cooldown_ticks = 156, radius = 0.85,
                duration_ticks = 150, interval_ticks = 5, max_hits_per_target = 9,
                orbit_radius = 3.7, orbit_period_ticks = 60,
            },
        },
    },
    step_quake = {
        label = "踏尘震环",
        behavior = "field",
        field_anchor = "player",
        levels = {
            {
                damage = 13, cooldown_ticks = 24, radius = 3,
                duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
                travel_distance = 4,
            },
            {
                damage = 17, cooldown_ticks = 20, radius = 3.5,
                duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
                travel_distance = 3.6,
            },
        },
    },
}
