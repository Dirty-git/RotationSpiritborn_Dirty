local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(true, get_hash(my_utility.plugin_label .. "soar_main_boolean")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "soar_targeting_mode")),
    check_buff     = checkbox:new(false, get_hash(my_utility.plugin_label .. "soar_check_buff")),
}

local function menu()
    if menu_elements.tree_tab:push("Soar") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.check_buff:render("Only recast if buff is not active", "")
        end
        menu_elements.tree_tab:pop()
    end
end

local spell_data_soar = spell_data:new(
    1.5,                                -- radius
    5.0,                                -- range
    1.0,                                -- cast_delay
    0.7,                                -- projectile_speed
    false,                              -- has_collision
    my_utility.abilities.spell_id_soar, -- spell_id
    spell_geometry.circular,            -- geometry_type
    targeting_type.skillshot            --targeting_type
)

local next_time_allowed_cast = 0.0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        my_utility.abilities.spell_id_soar);

    if not is_logic_allowed or not target then
        return false;
    end;

    local check_buff = menu_elements.check_buff:get();
    local is_buff_active = my_utility.is_buff_active(my_utility.abilities.spell_id_soar,
            my_utility.abilities.buff_id_soar_crit) or
        my_utility.is_buff_active(my_utility.abilities.spell_id_soar,
            my_utility.abilities.buff_id_soar_vulnerable) or
        my_utility.is_buff_active(my_utility.abilities.spell_id_soar,
            my_utility.abilities.buff_id_soar_unstoppable)

    if check_buff and is_buff_active then
        return false;
    end;

    if cast_spell.target(target, spell_data_soar, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;

        console.print("Cast Soar, Target: " .. target:get_skin_name());
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
