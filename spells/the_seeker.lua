local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(false, get_hash(my_utility.plugin_label .. "the_seeker_main_boolean")),
    targeting_mode = combo_box:new(0, get_hash(my_utility.plugin_label .. "the_seeker_targeting_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("The Seeker") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;

local function logics(target)
    if not target then return false end;
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.the_seeker.spell_id);

    if not is_logic_allowed then return false end;

    -- if we have the buff already active then skip
    if my_utility.is_buff_active(spell_data.the_seeker.spell_id, spell_data.the_seeker.buff_id) then
        return false;
    end;

    local target_position = target:get_position()
    if cast_spell.position(spell_data.the_seeker.spell_id, target_position, 0.40) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast The Seeker, Target: " .. my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1])
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
