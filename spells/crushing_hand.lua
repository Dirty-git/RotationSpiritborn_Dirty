local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(false, get_hash(my_utility.plugin_label .. "crushing_hand_base_main_bool")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "crushing_hand_base_targeting_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Crushing Hand") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
        end

        menu_elements.tree_tab:pop()
    end
end

local crushing_hand_spell_data = spell_data:new(
    3.0,                                         -- radius
    2.15,                                        -- range
    0.01,                                        -- cast_delay
    0.3,                                         -- projectile_speed
    true,                                        -- has_collision
    my_utility.abilities.spell_id_crushing_hand, -- spell_id
    spell_geometry.rectangular,                  -- geometry_type
    targeting_type.targeted                      --targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_crushing_hand);

    if not is_logic_allowed or not target then
        return false;
    end;

    if cast_spell.target(target, crushing_hand_spell_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Crushing Hand");
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
