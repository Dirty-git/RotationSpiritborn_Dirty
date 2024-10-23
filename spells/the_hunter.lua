local my_utility = require("my_utility/my_utility")

local max_spell_range = 16.0
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(false, get_hash(my_utility.plugin_label .. "the_hunter_main_boolean")),
    targeting_mode   = combo_box:new(0, get_hash(my_utility.plugin_label .. "the_hunter_targeting_mode")),
    mobility_only    = checkbox:new(false, get_hash(my_utility.plugin_label .. "the_hunter_mobility_only")),
    min_target_range = slider_float:new(3, max_spell_range - 1, 8,
        get_hash(my_utility.plugin_label .. "the_hunter_min_target_range")),
}

local function menu()
    if menu_elements.tree_tab:push("The Hunter") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.mobility_only:render("Only use for mobility", "")
            if menu_elements.mobility_only:get() then
                menu_elements.min_target_range:render("Minimum Target Range",
                    "\n     Must be lower than Max Targeting Range     \n\n", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_the_hunter);

    if not is_logic_allowed or not target then
        return false;
    end;

    -- if we have the buff already active then skip
    if my_utility.is_buff_active(my_utility.abilities.spell_id_the_hunter, my_utility.abilities.buff_id_the_hunter) then
        return false;
    end;

    local target_position = target:get_position()
    local mobility_only = menu_elements.mobility_only:get();
    if mobility_only then
        local player_position = get_player_position()
        local target_distance = target_position:dist_to(player_position);
        if target_distance <= menu_elements.min_target_range:get() or target_distance >= max_spell_range then
            return false;
        end
    end

    if cast_spell.position(my_utility.abilities.spell_id_the_hunter, target_position, 0.40) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast The Hunter, Target: " .. target:get_skin_name() .. ", Mobility Only: " ..
            tostring(mobility_only));
        return true;
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
