local function recipe(id, kind, weapons, passives, passiveLevels)
    return {
        id = id,
        kind = kind,
        weapons = weapons,
        passives = passives,
        passive_levels = passiveLevels,
        result = id,
    }
end

local function upgrade(id, weapon, passive)
    return recipe(id, "evolution", { weapon }, { passive }, { [passive] = 1 })
end

return {
    recipe("gale_script", "evolution", { "wind_blade" }, { "gust_seal" }),
    upgrade("dawn_crescent", "mist_cut", "amber_cloak"),
    upgrade("silvery_sparks", "star_spark", "night_pearl"),
    upgrade("ridge_volley", "ridge_dart", "feather_knot"),
    upgrade("atlas_arc", "stone_lob", "star_bell"),
    upgrade("verdant_wings", "willow_return", "sprout_tea"),
    upgrade("jade_constellation", "jade_satellite", "mist_sand"),
    upgrade("comet_bloom", "blossom_bomb", "gust_seal"),
    upgrade("rising_tide", "dew_aura", "tuning_fork"),
    upgrade("ash_current", "ember_field", "gust_seal"),
    upgrade("crystal_choir", "echo_shard", "amber_cloak"),
    upgrade("petal_crown", "petal_fan", "night_pearl"),
    upgrade("high_noon", "horizon_shatter", "dawn_book"),
    upgrade("wandering_beacon", "cloud_scout", "night_pearl"),
    upgrade("gale_lattice", "storm_lane", "mist_sand"),
    upgrade("dust_forge", "trail_mine", "feather_knot"),
    recipe("winter_circuit", "evolution", { "stillwater_seal" }, { "star_bell", "tuning_fork" }),
    recipe("mountain_vow", "evolution", { "stone_ward" }, { "amber_cloak", "sprout_tea" }),
    recipe("echo_diadem", "evolution", { "needle_ring" }, {}),
    recipe("aurora_diadem", "evolution", { "echo_diadem" }, {}),
    recipe("rime_confluence", "union", { "wind_blade", "frost_pulse" }, {}),
    recipe("prismatic_willow", "union", { "prism_cross", "willow_twins" }, { "feather_knot" }, { feather_knot = 1 }),
    recipe("cyclone_braid", "union", { "mist_cut", "gale_script" }, {}),
    recipe("resonance_gift", "gift", { "echo_bell" }, { "tuning_fork" }),
    recipe("amber_bloom_gift", "gift", { "jade_satellite" }, { "night_pearl" }, { night_pearl = 1 }),
}
