local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    main_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(false, get_hash(my_utility.plugin_label .. "main_boolean_vortex")),
    filter_mode           = combo_box:new(1, get_hash(my_utility.plugin_label .. "offensive_filter_vortex")),
    enemy_count_threshold = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_enemy_count_vortex")),
    evaluation_range      = slider_int:new(1, 16, 6,
        get_hash(my_utility.plugin_label .. "evaluation_range_vortex")),
}

local function menu()
    if menu_elements.main_tab:push("Vortex") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.evaluation_range:render("Evaluation Range", my_utility.evaluation_range_description)
            menu_elements.filter_mode:render("Filter Modes", my_utility.activation_filters, "")
            menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
                "       Minimum number of enemies in Evaluation Range for spell activation")
        end

        menu_elements.main_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.vortex.spell_id);

    if not is_logic_allowed then return false end;

    local filter_mode = menu_elements.filter_mode:get()
    local evaluation_range = menu_elements.evaluation_range:get();
    local all_units_count, _, elite_units_count, champion_units_count, boss_units_count = my_utility
        .enemy_count_in_range(evaluation_range)

    if (filter_mode == 1 and (elite_units_count >= 1 or champion_units_count >= 1 or boss_units_count >= 1))
        or (filter_mode == 2 and boss_units_count >= 1)
        or (all_units_count >= menu_elements.enemy_count_threshold:get())
    then
        if cast_spell.self(spell_data.vortex.spell_id, 0.0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
            console.print("Cast Vortex");
            return true;
        end;
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
