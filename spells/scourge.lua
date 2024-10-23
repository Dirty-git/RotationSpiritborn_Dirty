local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(false, get_hash(my_utility.plugin_label .. "main_boolean_scourge_base")),
    filter_mode           = combo_box:new(0, get_hash(my_utility.plugin_label .. "offensive_filter_scourge")),
    enemy_count_threshold = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_enemy_count_scourge")),
    check_buff            = checkbox:new(false, get_hash(my_utility.plugin_label .. "check_buff_scourge")),
    evaluation_range      = slider_int:new(1, 16, 6,
        get_hash(my_utility.plugin_label .. "evaluation_range_scourge")),
}

local function menu()
    if menu_elements.tree_tab:push("Scourge") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.check_buff:render("Only recast if buff is not active", "")
            menu_elements.evaluation_range:render("Evaluation Range", my_utility.evaluation_range_description)
            menu_elements.filter_mode:render("Filter Modes", my_utility.activation_filters, "")
            menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
                "       Minimum number of enemies in Evaluation Range for spell activation")
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
        my_utility.abilities.spell_id_scourge);

    if not is_logic_allowed then
        return false;
    end;

    local check_buff = menu_elements.check_buff:get();
    local is_buff_active = my_utility.is_buff_active(my_utility.abilities.spell_id_scourge,
        my_utility.abilities.buff_id_scourge);

    if check_buff and is_buff_active then
        return false;
    end;

    local filter_mode = menu_elements.filter_mode:get()
    local evaluation_range = menu_elements.evaluation_range:get();
    local all_units_count, _, elite_units_count, champion_units_count, boss_units_count = my_utility
        .enemy_count_in_range(evaluation_range)

    if (filter_mode == 1 and (elite_units_count >= 1 or champion_units_count >= 1 or boss_units_count >= 1))
        or (filter_mode == 2 and boss_units_count >= 1)
        or (all_units_count >= menu_elements.enemy_count_threshold:get())
    then
        if cast_spell.self(my_utility.abilities.spell_id_scourge, 0.000) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + my_utility.spell_delays.instant_cast;
            console.print("Cast Scourge - Offensive - " .. filter_mode)
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
