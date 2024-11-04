-- To modify spell priority, edit the spell_priority table below.
-- The table is sorted from highest priority to lowest priority.
-- The priority is used to determine which spell to cast when multiple spells are valid to cast.

local spell_priority = {
    -- instant cast
    "armored_hide",
    "scourge",
    "counterattack",
    "ravager",
    "toxic_skin",
    "vortex",

    -- ultimates
    "the_hunter",
    "the_seeker",
    "the_devourer",
    "the_protector",

    -- main damage abilities
    "quill_volley",
    "crushing_hand",
    "stinger",
    "rake",
    "touch_of_death",
    "payback",
    "razor_wings",
    "concussive_stomp",

    -- mobility
    "soar",
    "rushing_claw",
    "evade",

    -- filler abilities
    "rock_splitter",
    "thrash",
    "thunderspike",
    "withering_fist",
}

return spell_priority
