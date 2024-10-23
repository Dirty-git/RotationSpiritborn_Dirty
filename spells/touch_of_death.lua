local my_utility = require("my_utility/my_utility");

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(false, get_hash(my_utility.plugin_label .. "touch_of_death_main_boolean")),
    targeting_mode = combo_box:new(3, get_hash(my_utility.plugin_label .. "touch_of_death_targeting_mode")),
    swarm_stacking = checkbox:new(false,
        get_hash(my_utility.plugin_label .. "touch_of_death_swarm_stacking")),
}

local function menu()
    if menu_elements.tree_tab:push("Touch of Death") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.swarm_stacking:render("Swarm stacking only",
                "Only use ability for stacking up to 3 swarms")
        end

        menu_elements.tree_tab:pop()
    end
end

local touch_of_death_data = spell_data:new(
    0.3,                                          -- radius
    3.0,                                          -- range
    0.1,                                          -- cast_delay
    0.1,                                          -- projectile_speed
    true,                                         -- has_collision
    my_utility.abilities.spell_id_touch_of_death, -- spell_id
    spell_geometry.rectangular,                   -- geometry_type
    targeting_type.targeted                       --targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local swarm_stacking_only = menu_elements.swarm_stacking:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_touch_of_death);

    if not is_logic_allowed or not target then
        return false;
    end;

    local buff_stack_count = my_utility.buff_stack_count(my_utility.abilities.spell_id_touch_of_death,
        my_utility.abilities.buff_id_touch_of_death_swarm)
    local time_since_last_cast = get_time_since_inject() - next_time_allowed_cast
    -- NOTE: if we use this just to stack swarms to 3 then only use if we are below 3 stacks or if we have casted it in the past 2 seconds (otherwise we fall from 3 stacks to 0 if we dont check this)
    if swarm_stacking_only and buff_stack_count > 2 and time_since_last_cast < 2 then
        return false;
    end;

    if cast_spell.target(target, touch_of_death_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Touch of Death | Stacks: " .. buff_stack_count .. " | Since last: " .. time_since_last_cast);
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
