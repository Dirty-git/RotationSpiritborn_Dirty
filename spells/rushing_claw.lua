local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(true, get_hash(my_utility.plugin_label .. "rushing_claw_main_boolean")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "rushing_claw_targeting_mode")),
    check_buff     = checkbox:new(false, get_hash(my_utility.plugin_label .. "check_buff_armored_hide")),
}

local function menu()
    if menu_elements.tree_tab:push("Rushing Claw") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.check_buff:render("Only recast if buff is not active", "")
        end

        menu_elements.tree_tab:pop()
    end
end

local rushing_claw_data = spell_data:new(
    0.5,                                        -- radius
    4.0,                                        -- range
    0.8,                                        -- cast_delay
    1.5,                                        -- projectile_speed
    false,                                      -- has_collision
    my_utility.abilities.spell_id_rushing_claw, -- spell_id
    spell_geometry.rectangular,                 -- geometry_type
    targeting_type.targeted                     -- targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_rushing_claw);

    if not is_logic_allowed or not target then
        return false;
    end;

    local check_buff = menu_elements.check_buff:get();
    local is_buff_active = my_utility.is_buff_active(my_utility.abilities.spell_id_rushing_claw,
        my_utility.abilities.buff_id_rushing_claw_dodge)

    if check_buff and is_buff_active then
        return false;
    end

    if cast_spell.target(target, rushing_claw_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Rushing Claw");
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
