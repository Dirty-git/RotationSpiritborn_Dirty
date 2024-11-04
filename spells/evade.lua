local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 17.0
local menu_elements =
{
    tree_tab          = tree_node:new(1),
    main_boolean      = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_main_bool_base")),
    use_out_of_combat = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_use_out_of_combat")),
    targeting_mode    = combo_box:new(5, get_hash(my_utility.plugin_label .. "evade_targeting_mode")),
    mobility_only     = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_mobility_only")),
    min_target_range  = slider_float:new(3, max_spell_range - 1, 5,
        get_hash(my_utility.plugin_label .. "evade_min_target_range")),
}

local function menu()
    if menu_elements.tree_tab:push("Evade - only for evade build") then
        menu_elements.use_out_of_combat:render("Enable Evade - Out of combat", "")
        menu_elements.main_boolean:render("Enable Evade - In combat", "")

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
    if not target then return false end;
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.evade.spell_id);

    if not is_logic_allowed then return false end;

    local target_position = target:get_position()
    local mobility_only = menu_elements.mobility_only:get();
    if mobility_only then
        if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
            return false
        end
    end

    if cast_spell.position(spell_data.evade.spell_id, target_position, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast Evade - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] .. ", Mobility Only: " ..
            tostring(mobility_only));
        return true;
    end;

    return false;
end

local function out_of_combat()
    local menu_boolean = menu_elements.use_out_of_combat:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.evade.spell_id);

    if not is_logic_allowed then return false end;

    -- check if we are in a safezone
    local in_combat_area = my_utility.is_buff_active(spell_data.in_combat_area.spell_id,
        spell_data.in_combat_area.buff_id);
    if not in_combat_area then return false end;

    local local_player = get_local_player()
    local is_moving = local_player:is_moving()
    local is_dashing = local_player:is_dashing()

    -- if standing still or already dashing
    if not is_moving or is_dashing then return false end;

    local destination = local_player:get_move_destination()
    if cast_spell.position(spell_data.evade.spell_id, destination, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast Evade - Out of Combat")
        return true;
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    out_of_combat = out_of_combat,
    menu_elements = menu_elements
}
