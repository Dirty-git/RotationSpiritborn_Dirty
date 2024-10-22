local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_ravager_base")),
    filter_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "ravager_base_filter_mode")),
    min_max_targets  = slider_int:new(0, 30, 5,
        get_hash(my_utility.plugin_label .. "min_max_number_of_targets_for_ravager_base")),
    check_buff       = checkbox:new(false, get_hash(my_utility.plugin_label .. "check_buff_ravager_base")),
    evaluation_range = slider_int:new(1, 16, 12,
        get_hash(my_utility.plugin_label .. "evaluation_range_ravager_base")),
}

local function menu()
    if menu_elements.tree_tab:push("Ravager") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.check_buff:render("Only recast if buff is not active", "")
            menu_elements.evaluation_range:render("Evaluation Range", my_utility.evaluation_range_description)
            menu_elements.filter_mode:render("Filter Modes", my_utility.activation_filters, "")
            menu_elements.min_max_targets:render("Min Normal Enemies Around",
                "Amount of normal enemies to cast the spell")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_ravager);

    if not is_logic_allowed then
        return false;
    end;

    local check_buff = menu_elements.check_buff:get();
    local is_buff_active = my_utility.is_buff_active(my_utility.abilities.spell_id_ravager,
        my_utility.abilities.buff_id_ravager_base);

    if check_buff and is_buff_active then
        return false;
    end;

    local filter_mode = menu_elements.filter_mode:get()
    local evaluation_range = menu_elements.evaluation_range:get();
    local units_count, elite_units, champion_units, boss_units = my_utility.enemy_count_in_range(evaluation_range)

    if (filter_mode == 1 and (elite_units >= 1 or champion_units >= 1 or boss_units >= 1))
        or (filter_mode == 2 and boss_units >= 1)
        or (units_count >= menu_elements.min_max_targets:get())
    then
        if cast_spell.self(my_utility.abilities.spell_id_ravager, 0.000) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + my_utility.spell_delays.instant_cast;
            console.print("Cast Ravager - Offensive - " .. filter_mode)
            return true;
        end
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
