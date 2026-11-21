return {
    rules = {
        weapon_slots = 4,
        passive_slots = 4,
        choice_count = 3,
        reroll = 2,
        skip = 2,
        banish = 1,
        skip_experience_fraction = 0.25,
        fallback_heal = 18,
    },
    items = {
        gust_seal = { label = "疾风符", weight = 10, max_level = 4, per_level = { damage = 0.09 } },
        mist_sand = { label = "流岚砂", weight = 7, max_level = 3, per_level = { duration = 0.12, knockback = 0.1 } },
        night_pearl = { label = "夜明珠", weight = 5, max_level = 3, per_level = { crit_chance = 0.05 } },
        star_bell = { label = "流星铃", weight = 8, max_level = 3, per_level = { area = 0.09, range = 0.06 } },
        feather_knot = { label = "轻羽结", weight = 7, max_level = 3, per_level = { projectile_speed = 0.08, cooldown = -0.07 } },
        amber_cloak = { label = "琥珀披风", weight = 8, max_level = 4, per_level = { armor = 1, max_health_bonus = 8 } },
        sprout_tea = { label = "嫩芽茶", weight = 12, max_level = 4, per_level = { speed = 0.075, max_health_bonus = 4 } },
        dawn_book = { label = "晨曦札记", weight = 8, max_level = 4, per_level = { experience = 0.09 } },
        tuning_fork = { label = "引灵音叉", weight = 9, max_level = 3, per_level = { magnet_radius = 0.15 } },
    },
}
