return {
    starting_stages = { windward = true },
    milestones = {
        {
            id = "first_return", label = "初次归来",
            completed_runs = 1,
            grants = { characters = { pebble_braider = true }, perks = { reed_stride = true } },
        },
        {
            id = "windward_clear", label = "越过风眼",
            win_stage = "windward",
            grants = {
                stages = { moon_reeds = true },
                characters = { paired_wayfinder = true, lantern_attendant = true },
                perks = { tidal_dial = true },
                weapons = { lantern_fanfare = true },
            },
        },
        {
            id = "reeds_clear", label = "月芦守望",
            win_stage = "moon_reeds", requires = "windward_clear",
            grants = {
                stages = { cinder_ridge = true },
                characters = { dawn_drifter = true },
                perks = { golden_balm = true },
            },
        },
        {
            id = "cinder_clear", label = "炉火余光",
            win_stage = "cinder_ridge", requires = "reeds_clear",
            grants = { characters = { unwritten = true, ember_binder = true }, perks = { spring_mark = true } },
        },
        {
            id = "varied_arms", label = "三种锋芒",
            discovered_weapons = 3,
            grants = { characters = { ward_calligrapher = true }, perks = { cinder_refrain = true } },
        },

        {
            id = "two_crossings", label = "再渡",
            completed_runs = 2,
            grants = { characters = { prism_keeper = true } },
        },
        {
            id = "explorers_circle", label = "围炉记事",
            discovered_characters = 4,
            grants = { characters = { cloud_cartographer = true } },
        },
        {
            id = "six_echoes", label = "六种回响",
            discovered_weapons = 6,
            grants = { characters = { cinder_alchemist = true, comet_keeper = true } },
        },
        {
            id = "scout_return", label = "斥候的长路",
            win_stage = "windward", win_character = "wind_scout",
            grants = { characters = { storm_watcher = true } },
        },
        {
            id = "reeds_guard", label = "石堤月色",
            win_stage = "moon_reeds", win_character = "ridge_guard", requires = "reeds_clear",
            grants = { characters = { blossom_tender = true, moon_navigator = true } },
        },
        {
            id = "fire_at_full_growth", label = "熔火行至深处",
            win_stage = "cinder_ridge", min_win_level = 8, requires = "cinder_clear",
            grants = { characters = { resonance_dancer = true, far_shore_traveller = true } },
        },
        {
            id = "varied_paths", label = "众旅同归",
            discovered_characters = 8, discovered_weapons = 10,
            grants = { characters = { afterglow = true, quiet_meridian = true, map_weaver = true } },
        },
    },
}
