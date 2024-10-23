local my_utility = require("my_utility/my_utility");

local menu_elements =
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(false, get_hash(my_utility.plugin_label .. "concussive_stomp_main_boolean")),
    hp_usage_shield       = slider_float:new(0.0, 1.0, 0.80,
        get_hash(my_utility.plugin_label .. "%_concussive_stomp_hp_usage")),
    use_offensively       = checkbox:new(true, get_hash(my_utility.plugin_label .. "concussive_stomp_use_offensively")),
    targeting_mode        = combo_box:new(5, get_hash(my_utility.plugin_label .. "concussive_stomp_targeting_mode")),
    spam_with_intricacy   = checkbox:new(true,
        get_hash(my_utility.plugin_label .. "concussive_stomp_spam_with_intricacy")),
    filter_mode           = combo_box:new(1, get_hash(my_utility.plugin_label .. "concussive_stomp_offensive_filter")),
    enemy_count_threshold = slider_int:new(0, 30, 3,
        get_hash(my_utility.plugin_label .. "concussive_stomp_min_enemy_count")),
    evaluation_range      = slider_int:new(1, 6, 2,
        get_hash(my_utility.plugin_label .. "concussive_stomp_evaluation_range")),
}

local function menu()
    if menu_elements.tree_tab:push("Concussive Stomp") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.spam_with_intricacy:render("Spam with Intricacy", "")
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

local concussive_stomp_spell_data = spell_data:new(
    2.0,                                            -- radius
    1.5,                                            -- range
    0.6,                                            -- cast_delay
    0.5,                                            -- projectile_speed
    true,                                           -- has_collision
    my_utility.abilities.spell_id_concussive_stomp, -- spell_id
    spell_geometry.rectangular,                     -- geometry_type
    targeting_type.skillshot                        --targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_concussive_stomp);

    if not is_logic_allowed or not target then
        return false;
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
            if cast_spell.target(target, concussive_stomp_spell_data, false) then
                local current_time = get_time_since_inject();
                next_time_allowed_cast = current_time + my_utility.spell_delays.instant_cast;
                console.print("Cast Concussive Stomp - Offensive - " .. filter_mode)
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
