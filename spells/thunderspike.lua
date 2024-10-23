local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab           = tree_node:new(1),
    main_boolean       = checkbox:new(false, get_hash(my_utility.plugin_label .. "thunderspike_main_bool_base")),
    targeting_mode     = combo_box:new(5, get_hash(my_utility.plugin_label .. "thunderspike_targeting_mode")),
    use_as_filler_only = checkbox:new(false, get_hash(my_utility.plugin_label .. "thunderspike_use_as_filler_only")),
    max_spirit         = slider_int:new(1, 100, 35,
        get_hash(my_utility.plugin_label .. "thunderspike_max_spirit")),
}

local function menu()
    if menu_elements.tree_tab:push("Thunderspike") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.use_as_filler_only:render("Filler Only", "Prevent casting with a lot of spirit")

            if menu_elements.use_as_filler_only:get() then
                menu_elements.max_spirit:render("Max Spirit", "Prevent casting with more spirit than this value")
            end
        end

        menu_elements.tree_tab:pop()
    end
end

local spell_data_thunderspike = spell_data:new(
    1.0,                                        -- radius
    3.0,                                        -- range (increased from 0.2 to 1.5)
    0.1,                                        -- cast_delay
    0.3,                                        -- projectile_speed
    true,                                       -- has_collision
    my_utility.abilities.spell_id_thunderspike, -- spell_id
    spell_geometry.rectangular,                 -- geometry_type
    targeting_type.targeted                     -- targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_thunderspike);

    if not is_logic_allowed or not target then
        return false;
    end;

    local player_local = get_local_player();

    local is_filler_enabled = menu_elements.use_as_filler_only:get();
    if is_filler_enabled then
        local current_resource_ws = player_local:get_primary_resource_current();
        local max_spirit = menu_elements.max_spirit:get();
        local low_in_spirit = current_resource_ws < max_spirit;

        if not low_in_spirit then
            return false;
        end
    end;

    if cast_spell.target(target, spell_data_thunderspike, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Thunderspike");
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
