return {
    {
        id = "wind_scout", label = "风庭斥候", starters = { "wind_blade" },
    },
    {
        id = "ridge_guard", label = "栖岩卫", starters = { "stone_ward" },
        bonuses = { max_health_bonus = 25, armor = 2, speed = -0.14 },
        growth = { { at = 4, every = 3, steps = 3, bonuses = { armor = 1 } } },
    },
    {
        id = "spring_mender", label = "清泉医师", starters = { "stillwater_seal" },
        bonuses = { area = 0.12, duration = 0.15 },
        growth = { { at = 3, every = 2, steps = 4, bonuses = { max_health_bonus = 4 } } },
    },
    {
        id = "frost_scribe", label = "霜信书记", starters = { "frost_pulse" },
        bonuses = { area = 0.16, speed = -0.07 },
        growth = { { at = 4, every = 3, steps = 2, bonuses = { cooldown = -0.05 } } },
    },
    {
        id = "ember_courier", label = "炉火信使", starters = { "ember_field" },
        bonuses = { speed = 0.17, max_health_bonus = -12 },
        growth = { { at = 2, every = 2, steps = 4, bonuses = { duration = 0.08 } } },
    },
    {
        id = "jade_patroller", label = "青玉巡山人", starters = { "jade_satellite" },
        bonuses = { knockback = 0.30, area = 0.10 },
        growth = { { at = 5, bonuses = { projectile_speed = 0.20, damage = 0.1 } } },
    },
    {
        id = "willow_dancer", label = "柳风歌者", starters = { "willow_return" },
        bonuses = { speed = 0.1, projectile_speed = 0.15 },
        growth = { { at = 3, every = 2, steps = 4, bonuses = { damage = 0.065 } } },
    },
    {
        id = "dawn_sentinel", label = "破晓巡火人", starters = { "dawn_break" },
        bonuses = { cooldown = 0.14, max_health_bonus = 18, speed = -0.08 },
        growth = { { at = 6, bonuses = { cooldown = -0.19, area = 0.15 } } },
    },
    {
        id = "star_listener", label = "听星学徒", starters = { "star_spark" },
        bonuses = { experience = 0.18, magnet_radius = -0.13 },
        growth = { { at = 4, every = 2, steps = 3, bonuses = { magnet_radius = 0.16 } } },
    },
    {
        id = "echo_fugitive", label = "回响旅客", starters = { "echo_bell" },
        bonuses = { max_health_bonus = -20, crit_chance = 0.11, magnet_radius = 0.10 },
        growth = { { at = 5, bonuses = { damage = 0.22, cooldown = -0.09 } } },
    },
    {
        id = "paired_wayfinder", label = "双迹领路人", unlock = "paired_wayfinder",
        starters = { "ridge_dart", "dew_aura" },
        bonuses = { speed = -0.10, damage = -0.1 },
        growth = { { at = 6, bonuses = { speed = 0.14, damage = 0.20 } } },
    },
    {
        id = "unwritten", label = "无名客", unlock = "unwritten",
        random_starters = { "petal_fan", "stone_lob", "step_quake", "echo_shard" },
        growth = {
            { at = 3, bonuses = { range = 0.18 } },
            { at = 7, bonuses = { damage = 0.15, armor = 1 } },
        },
    },
    {
        id = "petal_runner", label = "飞花赶路人", starters = { "petal_fan" },
        bonuses = { speed = 0.12, max_health_bonus = -10 },
        combat = { when = "moving", at = 3, bonuses = { projectile_speed = 0.24 } },
    },
    {
        id = "quarry_hand", label = "采石工", starters = { "stone_lob" },
        bonuses = { speed = -0.18, armor = 1, max_health_bonus = 16 },
        combat = { when = "still", at = 4, bonuses = { area = 0.28 } },
    },
    {
        id = "mist_herald", label = "报雾人", starters = { "mist_cut" },
        bonuses = { speed = 0.15, magnet_radius = -0.20 },
        growth = { { at = 3, every = 3, steps = 3, bonuses = { cooldown = -0.045, range = 0.08 } } },
    },
    {
        id = "sky_keeper", label = "天针守望人", starters = { "sky_needle" },
        bonuses = { range = 0.16, area = -0.09 },
        combat = { when = "still", bonuses = { crit_chance = 0.25 } },
    },
    {
        id = "reed_guide", label = "苇原向导", starters = { "trail_mine" },
        bonuses = { speed = 0.08, duration = 0.16 },
        combat = { when = "moving", bonuses = { cooldown = -0.11 } },
    },
    {
        id = "dew_gardener", label = "晨露园丁", starters = { "dew_aura" },
        bonuses = { area = 0.21, speed = -0.07 },
        growth = { { at = 2, every = 2, steps = 4, bonuses = { max_health_bonus = 5 } } },
    },
    {
        id = "echo_tinker", label = "回音修匠", starters = { "echo_shard" },
        bonuses = { projectile_speed = -0.12, range = 0.20 },
        growth = { { at = 4, every = 2, steps = 3, bonuses = { knockback = 0.10, damage = 0.06 } } },
    },
    {
        id = "pebble_braider", label = "砾石编绳人", unlock = "pebble_braider", starters = { "pebble_chain" },
        bonuses = { pierce = 1, duration = -0.10 },
        growth = { { at = 5, bonuses = { area = 0.14, pierce = 1 } } },
    },
    {
        id = "ward_calligrapher", label = "刻印书生", unlock = "ward_calligrapher", starters = { "stone_ward" },
        bonuses = { max_health_bonus = -25, duration = 0.25 },
        growth = { { at = 6, bonuses = { max_health_bonus = 44, armor = 2 } } },
    },
    {
        id = "prism_keeper", label = "折光馆主", unlock = "prism_keeper", starters = { "prism_cross" },
        bonuses = { range = -0.12, damage = 0.19 },
        combat = { when = "still", at = 3, bonuses = { cooldown = -0.21 } },
    },
    {
        id = "lantern_attendant", label = "掌灯官", unlock = "lantern_attendant", starters = { "lantern_fanfare" },
        bonuses = { area = 0.18, max_health_bonus = -14 },
        growth = { { at = 6, bonuses = { duration = 0.26, magnet_radius = 0.20 } } },
    },
    {
        id = "dawn_drifter", label = "黎明渡客", unlock = "dawn_drifter", starters = { "dawn_break" },
        bonuses = { max_health_bonus = -28, cooldown = 0.10, speed = 0.13 },
        combat = { when = "wounded", threshold = 0.45, bonuses = { area = 0.32, cooldown = -0.23 } },
    },
    {
        id = "storm_watcher", label = "听雷人", unlock = "storm_watcher", starters = { "storm_lane" },
        bonuses = { damage = 0.08, knockback = 0.18 },
        combat = { when = "still", at = 5, bonuses = { range = 0.31, knockback = 0.18 } },
    },
    {
        id = "cloud_cartographer", label = "云路绘图师", unlock = "cloud_cartographer", starters = { "cloud_scout" },
        bonuses = { speed = 0.16, max_health_bonus = -12 },
        growth = { { at = 3, every = 2, steps = 4, bonuses = { range = 0.09 } } },
    },
    {
        id = "cinder_alchemist", label = "余火炼师", unlock = "cinder_alchemist", starters = { "ember_breath" },
        bonuses = { duration = 0.22, range = -0.13 },
        combat = { when = "moving", at = 3, bonuses = { area = 0.25 } },
    },
    {
        id = "comet_keeper", label = "彗光守门人", unlock = "comet_keeper", starters = { "horizon_shatter" },
        bonuses = { max_health_bonus = -17, range = 0.18 },
        combat = { when = "lean", threshold = 1, at = 4, bonuses = { damage = 0.30 } },
    },
    {
        id = "blossom_tender", label = "山花养护人", unlock = "blossom_tender", starters = { "blossom_bomb" },
        bonuses = { area = 0.17, speed = -0.08, magnet_radius = 0.10 },
        growth = { { at = 2, every = 3, steps = 3, bonuses = { duration = 0.09, area = 0.04 } } },
    },
    {
        id = "moon_navigator", label = "望月舵手", unlock = "moon_navigator", starters = { "moon_tide" },
        bonuses = { duration = 0.16, armor = 1 },
        combat = { when = "wounded", threshold = 0.48, at = 4, bonuses = { duration = 0.30, cooldown = -0.18 } },
    },
    {
        id = "resonance_dancer", label = "双弦舞师", unlock = "resonance_dancer", starters = { "willow_twins" },
        bonuses = { speed = 0.11, crit_chance = 0.06 },
        growth = { { at = 7, bonuses = { pierce = 1, projectile_speed = 0.23 } } },
    },
    {
        id = "far_shore_traveller", label = "远岸行者", unlock = "far_shore_traveller", starters = { "echo_bell" },
        random_starters = { "stillwater_seal", "last_stand", "needle_ring", "pebble_chain" },
        bonuses = { damage = -0.10, experience = 0.12, magnet_radius = 0.16 },
        growth = { { at = 6, bonuses = { damage = 0.21, speed = 0.08 } } },
    },
    {
        id = "afterglow", label = "余照", unlock = "afterglow", starters = { "last_stand" },
        bonuses = { max_health_bonus = -36, speed = 0.09 },
        combat = { when = "wounded", threshold = 0.40, bonuses = { damage = 0.30, knockback = 0.28 } },
    },
    {
        id = "quiet_meridian", label = "寂脉居士", unlock = "quiet_meridian", starters = { "needle_ring" },
        bonuses = { armor = 2, speed = -0.20 },
        combat = { when = "still", at = 5, bonuses = { pierce = 1, crit_chance = 0.12 } },
    },
    {
        id = "map_weaver", label = "绘流者", unlock = "map_weaver",
        random_starters = { "gale_script", "rime_confluence", "horizon_shatter" },
        bonuses = { damage = -0.20, experience = 0.14 },
        growth = { { at = 8, bonuses = { damage = 0.36, duration = 0.16 } } },
    },
    {
        id = "ember_binder", label = "结火人", unlock = "ember_binder", starters = { "ember_breath", "ember_field" },
        bonuses = { damage = -0.12, speed = -0.08, duration = 0.20 },
        growth = { { at = 7, bonuses = { damage = 0.20, area = 0.15 } } },
    },
}
