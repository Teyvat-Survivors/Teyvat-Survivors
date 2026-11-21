local weapons = {
    lantern_fanfare = {
        label = "灯华齐鸣",
        weight = 0,
        armory_unlock = true,
        behavior = "pulse",
        levels = {
            { damage = 27, cooldown_ticks = 118, radius = 7.8, knockback = 1.4 },
        },
    },
    gale_script = {
        label = "长风篇",
        weight = 0,
        behavior = "projectile",
        levels = {
            { damage = 36, cooldown_ticks = 37, range = 31, speed = 38, radius = 0.47, pierce = 3 },
        },
    },
    rime_confluence = {
        label = "风霜合鸣",
        weight = 0,
        behavior = "field",
        levels = {
            {
                damage = 19, cooldown_ticks = 68, range = 21, radius = 4.8, knockback = 0.35,
                duration_ticks = 54, interval_ticks = 12, max_hits_per_target = 4,
            },
        },
    },
    resonance_gift = {
        label = "余音箓",
        weight = 0,
        behavior = "echo_magnet",
        levels = { { cooldown_ticks = 83, radius = 21, pickup_cap = 9 } },
    },
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
        weight = 18,
        label = "风刃",
        behavior = "projectile",
        levels = {
            { damage = 12, cooldown_ticks = 54, range = 24, speed = 28, radius = 0.28, pierce = 1 },
            { damage = 17, cooldown_ticks = 48, range = 26, speed = 31, radius = 0.33, pierce = 1 },
            { damage = 23, cooldown_ticks = 42, range = 28, speed = 34, radius = 0.39, pierce = 2 },
        },
    },
    frost_pulse = {
        weight = 14,
        label = "霜脉冲",
        behavior = "pulse",
        levels = {
            { damage = 14, cooldown_ticks = 72, radius = 4, knockback = 1.15 },
            { damage = 19, cooldown_ticks = 66, radius = 4.6, knockback = 1.4 },
        },
    },
    ember_field = {
        weight = 12,
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
    mist_cut = {
        label = "断雾斩", behavior = "pulse", weight = 12,
        levels = {
            { damage = 24, cooldown_ticks = 48, radius = 3, cone_cos = 0.55, knockback = 0.6 },
            { damage = 32, cooldown_ticks = 44, radius = 3.5, cone_cos = 0.48, knockback = 0.8 },
        },
    },
    sky_needle = {
        label = "天星落", behavior = "field", aim = "random", weight = 9,
        levels = {
            {
                damage = 26, cooldown_ticks = 115, range = 35, radius = 1.65, delay_ticks = 28,
                duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
            },
            {
                damage = 33, cooldown_ticks = 105, range = 39, radius = 2, delay_ticks = 22,
                duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
            },
        },
    },
    cloud_scout = {
        label = "游云引", behavior = "field", field_anchor = "roam", weight = 8,
        levels = {
            {
                damage = 7, cooldown_ticks = 128, radius = 1.5, drift_per_tick = 0.26, turn_ticks = 29,
                duration_ticks = 105, interval_ticks = 9, max_hits_per_target = 3,
            },
            {
                damage = 10, cooldown_ticks = 120, radius = 1.8, drift_per_tick = 0.30, turn_ticks = 25,
                duration_ticks = 110, interval_ticks = 8, max_hits_per_target = 4,
            },
        },
    },
    moon_tide = {
        label = "逆月潮", behavior = "field", field_anchor = "orbit", weight = 8,
        levels = {
            {
                damage = 13, cooldown_ticks = 126, radius = 1.1, orbit_phase = math.pi,
                orbit_radius = 6, orbit_period_ticks = 96, delay_ticks = 12,
                duration_ticks = 72, interval_ticks = 12, max_hits_per_target = 2,
            },
            {
                damage = 18, cooldown_ticks = 118, radius = 1.3, orbit_phase = math.pi,
                orbit_radius = 6.6, orbit_period_ticks = 84, delay_ticks = 9,
                duration_ticks = 78, interval_ticks = 9, max_hits_per_target = 3,
            },
        },
    },
    prism_cross = {
        label = "四象羽", behavior = "projectile", aim = "facing", radial = true, weight = 10,
        levels = {
            { damage = 9, cooldown_ticks = 69, range = 16, speed = 29, radius = 0.29, pierce = 1, shots = 4 },
            { damage = 12, cooldown_ticks = 63, range = 19, speed = 33, radius = 0.32, pierce = 1, shots = 6 },
        },
    },
    willow_twins = {
        label = "双柳背刺", behavior = "projectile", aim = "behind", weight = 9,
        levels = {
            {
                damage = 16, cooldown_ticks = 59, range = 13, speed = 36, radius = 0.36,
                pierce = 1, shots = 2, angle_step = 0.68, knockback = 0.45,
            },
            {
                damage = 22, cooldown_ticks = 55, range = 16, speed = 40, radius = 0.40,
                pierce = 2, shots = 2, angle_step = 0.56, knockback = 0.7,
            },
        },
    },
    storm_lane = {
        label = "风压长廊", behavior = "pulse", weight = 9,
        levels = {
            { damage = 20, cooldown_ticks = 86, radius = 8, line_half_width = 0.65, knockback = 1.2 },
            { damage = 25, cooldown_ticks = 80, radius = 9.4, line_half_width = 0.95, knockback = 1.7 },
        },
    },
    ember_breath = {
        label = "熔羽风", behavior = "field", field_anchor = "player", weight = 10,
        levels = {
            {
                damage = 6, cooldown_ticks = 87, radius = 5, cone_cos = 0.73,
                duration_ticks = 24, interval_ticks = 6, max_hits_per_target = 4,
            },
            {
                damage = 8, cooldown_ticks = 81, radius = 5.7, cone_cos = 0.66,
                duration_ticks = 25, interval_ticks = 5, max_hits_per_target = 5,
            },
        },
    },
    trail_mine = {
        label = "回尘雷", behavior = "field", field_anchor = "trap", weight = 9,
        levels = {
            {
                damage = 27, cooldown_ticks = 39, radius = 2.2, rear_offset = 2.2, delay_ticks = 18,
                duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
                travel_distance = 5, release_when_stopped = true,
            },
            {
                damage = 32, cooldown_ticks = 31, radius = 2.6, rear_offset = 2.6, delay_ticks = 14,
                duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
                travel_distance = 4.4, release_when_stopped = true,
            },
        },
    },
    pebble_chain = {
        label = "岩雀折线", behavior = "projectile", motion = "ricochet", weight = 9,
        levels = {
            { damage = 11, cooldown_ticks = 66, range = 28, speed = 37, radius = 0.33, pierce = 2 },
            { damage = 15, cooldown_ticks = 60, range = 34, speed = 43, radius = 0.38, pierce = 3 },
        },
    },
    blossom_bomb = {
        label = "绽烟花", behavior = "projectile", motion = "lob", weight = 8,
        levels = {
            {
                damage = 17, cooldown_ticks = 82, range = 20, speed = 16, radius = 0.42, pierce = 0, apex = 2.8,
                blast_chance = 0.50, blast_radius = 2.8, blast_multiplier = 0.75,
            },
            {
                damage = 23, cooldown_ticks = 76, range = 23, speed = 19, radius = 0.46, pierce = 0, apex = 3.2,
                blast_chance = 0.70, blast_radius = 3.4, blast_multiplier = 0.82,
            },
        },
    },
    last_stand = {
        label = "赤岩决", behavior = "pulse", weight = 11,
        levels = {
            {
                damage = 19, cooldown_ticks = 64, radius = 3.8,
                low_health_fraction = 0.4, low_health_multiplier = 1.6,
            },
            {
                damage = 24, cooldown_ticks = 60, radius = 4.4,
                low_health_fraction = 0.45, low_health_multiplier = 1.75,
            },
        },
    },
    needle_ring = {
        label = "碎辰针群", behavior = "projectile", aim = "random", weight = 9,
        levels = {
            {
                damage = 8, cooldown_ticks = 72, range = 22, speed = 32, radius = 0.3,
                pierce = 2, shots = 2, angle_step = 0.18,
            },
            {
                damage = 12, cooldown_ticks = 65, range = 25, speed = 35, radius = 0.35,
                pierce = 2, shots = 3, angle_step = 0.17,
            },
        },
    },
    horizon_shatter = {
        label = "天际碎幕", behavior = "purge", weight = 4,
        levels = {
            { cooldown_ticks = 490, arena_wide = true, elite_damage = 25 },
            { cooldown_ticks = 445, arena_wide = true, elite_damage = 34 },
        },
    },
}

for id, weapon in pairs(require("data.evolved_weapons")) do
    weapons[id] = weapon
end

return weapons
