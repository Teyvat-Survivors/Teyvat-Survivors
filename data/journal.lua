return {
    starting_stages = { windward = true },
    milestones = {
        {
            id = "first_return", label = "初次归来",
            completed_runs = 1,
            grants = { perks = { reed_stride = true } },
        },
        {
            id = "windward_clear", label = "越过风眼",
            win_stage = "windward",
            grants = {
                stages = { moon_reeds = true },
                characters = { paired_wayfinder = true },
                perks = { tidal_dial = true },
                weapons = { lantern_fanfare = true },
            },
        },
        {
            id = "reeds_clear", label = "月芦守望",
            win_stage = "moon_reeds", requires = "windward_clear",
            grants = { stages = { cinder_ridge = true }, perks = { golden_balm = true } },
        },
        {
            id = "cinder_clear", label = "炉火余光",
            win_stage = "cinder_ridge", requires = "reeds_clear",
            grants = { characters = { unwritten = true }, perks = { spring_mark = true } },
        },
        {
            id = "varied_arms", label = "三种锋芒",
            discovered_weapons = 3,
            grants = { perks = { cinder_refrain = true } },
        },
    },
}
