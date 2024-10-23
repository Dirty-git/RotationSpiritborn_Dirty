local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(false, get_hash(my_utility.plugin_label .. "main_boolean_the_protector")),
    hp_usage_shield       = slider_float:new(0.0, 1.0, 0.80,
        get_hash(my_utility.plugin_label .. "%_the_protector_hp_usage")),
    use_offensively       = checkbox:new(true, get_hash(my_utility.plugin_label .. "use_offensively_the_protector")),
    filter_mode           = combo_box:new(1, get_hash(my_utility.plugin_label .. "offensive_filter_the_protector")),
    enemy_count_threshold = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_enemy_count_the_protector")),
    check_buff            = checkbox:new(true, get_hash(my_utility.plugin_label .. "check_buff_the_protector")),
    evaluation_range      = slider_int:new(1, 16, 6,
        get_hash(my_utility.plugin_label .. "evaluation_range_the_protector")),
}

local function menu()
    if menu_elements.tree_tab:push("The Protector") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.check_buff:render("Only recast if buff is not active", "")
            menu_elements.hp_usage_shield:render("Min cast HP Percent", "", 1)
            menu_elements.use_offensively:render("Use Offensively", "")

            if menu_elements.use_offensively:get() then
                menu_elements.evaluation_range:render("Evaluation Range", my_utility.evaluation_range_description)
                menu_elements.filter_mode:render("Filter Modes", my_utility.activation_filters, "")
                menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
                    "       Minimum number of enemies in Evaluation Range for spell activation")
            end
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
        my_utility.abilities.spell_id_the_protector);

    if not is_logic_allowed then
        return false;
    end;

    local check_buff = menu_elements.check_buff:get();
    local is_buff_active = my_utility.is_buff_active(my_utility.abilities.spell_id_the_protector,
        my_utility.abilities.buff_id_the_protector);

    if check_buff and is_buff_active then
        return false;
    end

    -- Checking for defensive use
    local local_player = get_local_player();
    local player_current_health = local_player:get_current_health();
    local player_max_health = local_player:get_max_health();
    local health_percent = player_current_health / player_max_health;
    local menu_min_percentage = menu_elements.hp_usage_shield:get();

    if health_percent <= menu_min_percentage then
        if cast_spell.self(my_utility.abilities.spell_id_the_protector, 0.000) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + my_utility.spell_delays.instant_cast;
            console.print("Cast The Protector - Defensive - " .. health_percent)
            return true;
        end
    end;

    -- Cheking for offensive use
    local use_offensively = menu_elements.use_offensively:get()

    if use_offensively then
        local filter_mode = menu_elements.filter_mode:get()
        local evaluation_range = menu_elements.evaluation_range:get();
        local all_units_count, _, elite_units_count, champion_units_count, boss_units_count = my_utility
            .enemy_count_in_range(evaluation_range)

        if (filter_mode == 1 and (elite_units_count >= 1 or champion_units_count >= 1 or boss_units_count >= 1))
            or (filter_mode == 2 and boss_units_count >= 1)
            or (all_units_count >= menu_elements.enemy_count_threshold:get())
        then
            if cast_spell.self(my_utility.abilities.spell_id_the_protector, 0.000) then
                local current_time = get_time_since_inject();
                next_time_allowed_cast = current_time + my_utility.spell_delays.instant_cast;
                console.print("Cast The Protector - Offensive - " .. filter_mode)
                return true;
            end
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
