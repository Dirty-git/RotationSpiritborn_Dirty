local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(true, get_hash(my_utility.plugin_label .. "quill_volley_base_main_bool")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "quill_volley_base_targeting_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Quill Volley") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
        end

        menu_elements.tree_tab:pop()
    end
end

local quill_volley_spell_data = spell_data:new(
    4.0,                                        -- radius
    6.0,                                        -- range
    0.001,                                      -- cast_delay
    1.0,                                        -- projectile_speed
    false,                                      -- has_collision
    my_utility.abilities.spell_id_quill_volley, -- spell_id
    spell_geometry.rectangular,                 -- geometry_type
    targeting_type.skillshot                    --targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_quill_volley);

    if not is_logic_allowed or not target then
        return false;
    end;

    if cast_spell.target(target, quill_volley_spell_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Quill Volley");
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
