local my_utility = require("my_utility/my_utility")
local menu_elements =
{
    main_boolean                  = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean")),
    -- first parameter is the default state, second one the menu element's ID. The ID must be unique,
    -- not only from within the plugin but also it needs to be unique between demo menu elements and
    -- other scripts menu elements. This is why we concatenate the plugin name ("LUA_EXAMPLE_NECROMANCER")
    -- with the menu element name itself.

    main_tree                     = tree_node:new(0),

    -- trees are the menu tabs. The parameter that we pass is the depth of the node. (0 for main menu (bright red rectangle),
    -- 1 for sub-menu of depth 1 (circular red rectangle with white background) and so on)
    settings_tree                 = tree_node:new(1),
    enemy_count_threshold         = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "enemy_count_threshold")),
    max_targeting_range           = slider_int:new(1, 16, 12, get_hash(my_utility.plugin_label .. "max_targeting_range")),
    cursor_targeting_radius       = slider_float:new(0.1, 6, 3,
        get_hash(my_utility.plugin_label .. "cursor_targeting_radius")),
    cursor_targeting_angle        = slider_int:new(20, 50, 30,
        get_hash(my_utility.plugin_label .. "cursor_targeting_angle")),
    best_target_evaluation_radius = slider_float:new(0.1, 6, 3,
        get_hash(my_utility.plugin_label .. "best_target_evaluation_radius")),

    enable_debug                  = checkbox:new(false, get_hash(my_utility.plugin_label .. "enable_debug")),
    debug_tree                    = tree_node:new(2),
    draw_targets                  = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_targets")),
    draw_max_range                = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_max_range")),
    draw_melee_range              = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_melee_range")),
    draw_enemy_circles            = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_enemy_circles")),
    draw_cursor_target            = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_cursor_target")),
    targeting_refresh_interval    = slider_float:new(0.1, 1, 0.2,
        get_hash(my_utility.plugin_label .. "targeting_refresh_interval")),

    custom_enemy_weights_tree     = tree_node:new(2),
    custom_enemy_weights          = checkbox:new(false, get_hash(my_utility.plugin_label .. "custom_enemy_weights")),
    enemy_weight_normal           = slider_int:new(1, 10, 2,
        get_hash(my_utility.plugin_label .. "enemy_weight_normal")),
    enemy_weight_elite            = slider_int:new(1, 50, 10,
        get_hash(my_utility.plugin_label .. "enemy_weight_elite")),
    enemy_weight_champion         = slider_int:new(1, 50, 15,
        get_hash(my_utility.plugin_label .. "enemy_weight_champion")),
    enemy_weight_boss             = slider_int:new(1, 100, 50,
        get_hash(my_utility.plugin_label .. "enemy_weight_boss")),

    spells_tree                   = tree_node:new(1),
    disabled_spells_tree          = tree_node:new(1),
}

local draw_targets_description =
    "\n     Targets in sight:\n" ..
    "     Ranged Target - RED circle with line     \n" ..
    "     Melee Target - GREEN circle with line     \n" ..
    "     Closest Target - CYAN circle with line     \n\n" ..
    "     Targets out of sight (only if they are not the same as targets in sight):\n" ..
    "     Ranged Target - faded RED circle     \n" ..
    "     Melee Target - faded GREEN circle     \n" ..
    "     Closest Target - faded CYAN circle     \n\n" ..
    "     Best Target Evaluation Radius:\n" ..
    "     faded WHITE circle       \n\n"

local cursor_target_description =
    "\n     Best Cursor Target - ORANGE pentagon     \n" ..
    "     Closest Cursor Target - GREEN pentagon     \n\n"

return
{
    menu_elements = menu_elements,
    draw_targets_description = draw_targets_description,
    cursor_target_description = cursor_target_description
}
