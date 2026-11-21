return {
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
}
