local my_utility = require("my_utility/my_utility")
local my_target_selector = require("my_utility/my_target_selector");

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(false, get_hash(my_utility.plugin_label .. "razor_wings_main_bool")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "razor_wings_targeting_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Razor Wings") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
        end

        menu_elements.tree_tab:pop()
    end
end

local spell_data_razor_wings = spell_data:new(
    1.50,                                      -- radius
    20.0,                                      -- range
    1.0,                                       -- cast_delay
    4.0,                                       -- projectile_speed
    true,                                      -- has_collision
    my_utility.abilities.spell_id_razor_wings, -- spell_id
    spell_geometry.rectangular,                -- geometry_type
    targeting_type.skillshot                   --targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_razor_wings);

    if not is_logic_allowed or not target then
        return false;
    end;

    if cast_spell.target(target, spell_data_razor_wings, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Razor Wings");
        return true;
    end;

    return false;
end


return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
