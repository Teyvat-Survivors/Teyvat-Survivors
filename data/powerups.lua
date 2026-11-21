return {
    base_stats = {
        max_health = 100,
        speed = 6,
        damage_multiplier = 1,
        coin_multiplier = 1,
    },
    upgrades = {
        vitality = {
            label = "坚韧",
            costs = { 45, 75, 120, 180 },
            stat = "max_health",
            bonus = 8,
        },
        agility = {
            label = "轻身",
            costs = { 60, 95, 150 },
            stat = "speed",
            bonus = 0.25,
        },
        resolve = {
            label = "攻势",
            costs = { 60, 100, 160, 245 },
            stat = "damage_multiplier",
            bonus = 0.08,
        },
        fortune = {
            label = "丰收",
            costs = { 75, 130, 205 },
            stat = "coin_multiplier",
            bonus = 0.12,
        },
    },
}
