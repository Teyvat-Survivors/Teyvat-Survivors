local function one(label, behavior, stats, shape)
    local weapon = shape or {}
    weapon.label, weapon.behavior, weapon.weight, weapon.levels = label, behavior, 0, { stats }
    return weapon
end

return {
    dawn_crescent = one("晨弧重斩", "pulse", {
        damage = 43, cooldown_ticks = 38, radius = 5.6, cone_cos = 0.15, knockback = 1.4,
    }),
    silvery_sparks = one("银芒星阵", "projectile", {
        damage = 19, cooldown_ticks = 24, range = 29, speed = 54, radius = 0.36, pierce = 1, shots = 3,
    }, { aim = "random", radial = true }),
    ridge_volley = one("叠岭齐射", "projectile", {
        damage = 29, cooldown_ticks = 41, range = 36, speed = 46, radius = 0.40,
        pierce = 3, shots = 3, angle_step = 0.16,
    }, { aim = "facing" }),
    atlas_arc = one("擎山陨弧", "projectile", {
        damage = 34, cooldown_ticks = 69, range = 28, speed = 19, radius = 1.5, pierce = 3, apex = 3.2,
        blast_chance = 1, blast_radius = 3.6, blast_multiplier = 0.65,
    }, { motion = "lob" }),
    verdant_wings = one("青枝返翼", "projectile", {
        damage = 23, cooldown_ticks = 58, range = 19, speed = 33, radius = 0.65,
        pierce = 8, return_ratio = 1.9, shots = 2, angle_step = 0.35,
    }, { motion = "return" }),
    jade_constellation = one("玉宿连珠", "field", {
        damage = 12, cooldown_ticks = 141, radius = 1.35, duration_ticks = 166, interval_ticks = 4,
        max_hits_per_target = 10, orbit_radius = 4.9, orbit_period_ticks = 46,
    }, { field_anchor = "orbit" }),
    comet_bloom = one("彗尾花雷", "projectile", {
        damage = 31, cooldown_ticks = 67, range = 28, speed = 24, radius = 0.72, pierce = 1, apex = 3.4,
        blast_chance = 1, blast_radius = 5, blast_multiplier = 0.90,
    }, { motion = "lob" }),
    rising_tide = one("升露回潮", "field", {
        damage = 6, cooldown_ticks = 89, radius = 5.4, duration_ticks = 112,
        interval_ticks = 9, max_hits_per_target = 11,
    }, { field_anchor = "player" }),
    ash_current = one("凝焰灰流", "field", {
        damage = 11, cooldown_ticks = 76, range = 25, radius = 4,
        duration_ticks = 70, interval_ticks = 8, max_hits_per_target = 6, crit_chance = 0.25,
    }),
    crystal_choir = one("晶壁共振", "projectile", {
        damage = 23, cooldown_ticks = 48, range = 54, speed = 42, radius = 0.52, pierce = 6, bounces = 4,
        blast_chance = 1, blast_radius = 2, blast_multiplier = 0.54,
    }, { aim = "facing", motion = "rebound" }),
    petal_crown = one("八瓣花冕", "projectile", {
        damage = 14, cooldown_ticks = 52, range = 27, speed = 32, radius = 0.31, pierce = 1, shots = 8,
    }, { radial = true }),
    high_noon = one("正午尽明", "purge", {
        cooldown_ticks = 380, arena_wide = true, elite_damage = 52,
    }),
    wandering_beacon = one("巡野灯灵", "field", {
        damage = 15, cooldown_ticks = 102, radius = 2.75, drift_per_tick = 0.36, turn_ticks = 18,
        duration_ticks = 126, interval_ticks = 7, max_hits_per_target = 5,
    }, { field_anchor = "roam" }),
    gale_lattice = one("横岚织垣", "pulse", {
        damage = 34, cooldown_ticks = 67, radius = 12.5, line_half_width = 1.9, knockback = 2.2,
    }),
    dust_forge = one("藏尘熔雷", "field", {
        damage = 45, cooldown_ticks = 26, radius = 3.6, rear_offset = 3.0, delay_ticks = 9,
        duration_ticks = 1, interval_ticks = 1, max_hits_per_target = 1,
        travel_distance = 3.8, release_when_stopped = true,
    }, { field_anchor = "trap" }),
    winter_circuit = one("寒川闭环", "stasis", {
        cooldown_ticks = 88, radius = 10.5, duration_ticks = 33, speed_factor = 0, target_cap = 11,
    }),
    mountain_vow = one("磐山誓垒", "ward", {
        cooldown_ticks = 132, duration_ticks = 180, charges = 3,
    }),
    echo_diadem = {
        label = "鸣辰半冕", weight = 0, upgrade_weight = 8, behavior = "projectile", aim = "random",
        levels = {
            {
                damage = 16, cooldown_ticks = 57, range = 29, speed = 40, radius = 0.42,
                pierce = 3, shots = 4, angle_step = 0.16,
            },
            {
                damage = 20, cooldown_ticks = 52, range = 32, speed = 43, radius = 0.46,
                pierce = 4, shots = 5, angle_step = 0.15,
            },
        },
    },
    aurora_diadem = one("极光全冕", "projectile", {
        damage = 26, cooldown_ticks = 46, range = 35, speed = 50, radius = 0.50,
        pierce = 5, shots = 7,
    }, { aim = "random", radial = true }),
    prismatic_willow = one("彩折回柳", "projectile", {
        damage = 21, cooldown_ticks = 49, range = 21, speed = 43, radius = 0.46,
        pierce = 6, return_ratio = 1.7, shots = 6,
    }, { aim = "behind", motion = "return", radial = true }),
    cyclone_braid = one("合卷锋潮", "pulse", {
        damage = 58, cooldown_ticks = 58, radius = 8.5, cone_cos = 0.28, knockback = 2.8,
    }),
    amber_bloom_gift = one("琥珀花灯", "field", {
        damage = 16, cooldown_ticks = 120, radius = 3.4, duration_ticks = 48, interval_ticks = 8,
        max_hits_per_target = 4, orbit_radius = 6.1, orbit_period_ticks = 38,
    }, { field_anchor = "orbit" }),
}
