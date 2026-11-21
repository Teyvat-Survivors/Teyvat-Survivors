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
}
