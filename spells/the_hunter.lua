local my_utility = require("my_utility/my_utility")

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(false, get_hash(my_utility.plugin_label .. "the_hunter_main_boolean")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "the_hunter_targeting_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("The Hunter") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0

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
    if cast_spell.position(my_utility.abilities.spell_id_the_hunter, target_position, 0.40) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast The Seeker, Target: " .. target:get_skin_name());
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
