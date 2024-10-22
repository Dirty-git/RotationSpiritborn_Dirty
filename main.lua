local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_spiritborn = character_id == 7;
if not is_spiritborn then
    return
end;

local my_target_selector = require("my_utility/my_target_selector");
local my_utility = require("my_utility/my_utility");
local menu = require("menu")

local spells =
{
    evade = require("spells/evade"),
    armored_hide = require("spells/armored_hide"),
    counterattack = require("spells/counterattack"),
    ravager = require("spells/ravager"),
    the_seeker = require("spells/the_seeker"),
    touch_of_death = require("spells/touch_of_death"),
    concussive_stomp = require("spells/concussive_stomp"),
    crushing_hand = require("spells/crushing_hand"),
    payback = require("spells/payback"),
    quill_volley = require("spells/quill_volley"),
    rake = require("spells/rake"),
    razor_wings = require("spells/razor_wings"),
    rock_splitter = require("spells/rock_splitter"),
    rushing_claw = require("spells/rushing_claw"),
    scourge = require("spells/scourge"),
    soar = require("spells/soar"),
    stinger = require("spells/stinger"),
    the_devourer = require("spells/the_devourer"),
    the_hunter = require("spells/the_hunter"),
    the_protector = require("spells/the_protector"),
    thrash = require("spells/thrash"),
    thunderspike = require("spells/thunderspike"),
    toxic_skin = require("spells/toxic_skin"),
    vortex = require("spells/vortex"),
    withering_fist = require("spells/withering_fist"),
}

on_render_menu(function()
    if not menu.menu_elements.main_tree:push("Spiritborn [Dirty]") then
        return;
    end;

    menu.menu_elements.main_boolean:render("Enable Plugin", "");

    if menu.menu_elements.main_boolean:get() == false then
        -- plugin not enabled, stop rendering menu elements
        menu.menu_elements.main_tree:pop();
        return;
    end;

    if menu.menu_elements.settings_tree:push("Settings") then
        menu.menu_elements.normal_monster_threshold:render("Normal Monster Threshold",
            "Threshold for considering normal monsters in target selection")
        menu.menu_elements.targeting_refresh_interval:render("Targeting Refresh Interval",
            "       Time between target checks in seconds       ", 1)
        menu.menu_elements.max_targeting_range:render("Max Targeting Range",
            "       Maximum range for targeting       ")
        menu.menu_elements.cursor_targeting_radius:render("Cursor Targeting Radius",
            "       Area size for selecting target around the cursor       ", 1)
        menu.menu_elements.best_target_evaluation_radius:render("Enemy Evaluation Radius",
            "       Area size around an enemy to evaluate if it's the best target       \n" ..
            "       If you use huge aoe spells, you should increase this value       \n" ..
            "       Size is displayed with debug display targets       ", 1)

        menu.menu_elements.enable_debug:render("Enable Debug", "")
        if menu.menu_elements.enable_debug:get() then
            if menu.menu_elements.debug_tree:push("Debug") then
                menu.menu_elements.draw_targets:render("Display Targets", menu.draw_targets_description)
                menu.menu_elements.draw_max_range:render("Display Max Range",
                    "Draw max range circle")
                menu.menu_elements.draw_melee_range:render("Display Melee Range",
                    "Draw melee range circle")
                menu.menu_elements.draw_enemy_circles:render("Display Enemy Circles",
                    "Draw enemy circles")
                menu.menu_elements.draw_cursor_target:render("Display Cursor Target", menu.cursor_target_description)
                menu.menu_elements.debug_tree:pop()
            end
        end


        menu.menu_elements.settings_tree:pop()
    end

    -- TODO ENABLE ALL SPELLS
    if menu.menu_elements.spells_tree:push("Spells") then
        spells.armored_hide.menu()
        spells.scourge.menu()
        spells.ravager.menu()
        spells.the_hunter.menu()
        spells.soar.menu()
        spells.vortex.menu()
        spells.crushing_hand.menu()
        spells.counterattack.menu()
        spells.the_seeker.menu()
        spells.touch_of_death.menu()
        spells.concussive_stomp.menu()
        spells.payback.menu()
        spells.quill_volley.menu()
        spells.rake.menu()
        spells.razor_wings.menu()
        spells.rushing_claw.menu()
        spells.stinger.menu()
        spells.the_devourer.menu()
        spells.the_protector.menu()
        spells.toxic_skin.menu()
        spells.thrash.menu()
        spells.withering_fist.menu()
        spells.rock_splitter.menu()
        spells.thunderspike.menu()
        spells.evade.menu()

        menu.menu_elements.spells_tree:pop()
    end

    menu.menu_elements.main_tree:pop();
end)

-- Targets
local best_ranged_target = nil
local best_ranged_target_visible = nil
local best_melee_target = nil
local best_melee_target_visible = nil
local closest_target = nil
local closest_target_visible = nil
local best_cursor_target = nil
local closest_cursor_target = nil

-- Targetting settings
local max_targeting_range = menu.menu_elements.max_targeting_range:get()
local collision_table = { true, 1 } -- collision width
local floor_table = { true, 5.0 }   -- floor height
local angle_table = { false, 90.0 } -- max angle

-- Cache for heavy function results
local next_target_update_time = 0.0 -- Time of next target evaluation
local next_cast_time = 0.0          -- Time of next possible cast
local targeting_refresh_interval = menu.menu_elements.targeting_refresh_interval:get()

-- Define scores for different enemy types
local normal_monster_value = 1
local elite_value = 2
local champion_value = 3
local boss_value = 20

local target_selector_data_all = nil

local function evaluate_targets(target_list, melee_range)
    local best_ranged_target = nil
    local best_melee_target = nil
    local best_cursor_target = nil
    local closest_cursor_target = nil

    local ranged_max_score = 0
    local melee_max_score = 0
    local cursor_max_score = 0

    local melee_range_sqr = melee_range * melee_range
    local player_position = get_player_position()
    local cursor_position = get_cursor_position()
    local cursor_targeting_radius = menu.menu_elements.cursor_targeting_radius:get()
    local cursor_targeting_radius_sqr = cursor_targeting_radius * cursor_targeting_radius
    local best_target_evaluation_radius = menu.menu_elements.best_target_evaluation_radius:get()

    local normal_threshold = menu.menu_elements.normal_monster_threshold:get()
    local closest_cursor_distance_sqr = math.huge

    for _, unit in ipairs(target_list) do
        local unit_position = unit:get_position()
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)
        local cursor_distance_sqr = unit_position:squared_dist_to_ignore_z(cursor_position)

        local is_boss = unit:is_boss()
        local has_champion = unit:is_champion()
        local has_elite = unit:is_elite()

        local area_data = target_selector.get_most_hits_target_circular_area_light(unit_position, 0,
            best_target_evaluation_radius, false)
        if not area_data then goto continue end

        local n_normals = area_data.n_hits
        if n_normals < normal_threshold and not (has_elite or has_champion or is_boss) then
            goto continue
        end

        local total_score = n_normals * normal_monster_value
        if is_boss then
            total_score = total_score + boss_value
        elseif has_champion then
            total_score = total_score + champion_value
        elseif has_elite then
            total_score = total_score + elite_value
        end

        -- in max range
        if total_score > ranged_max_score then
            ranged_max_score = total_score
            best_ranged_target = unit
        end

        -- in melee range
        if distance_sqr < melee_range_sqr and total_score > melee_max_score then
            melee_max_score = total_score
            best_melee_target = unit
        end

        -- in cursor radius
        if cursor_distance_sqr <= cursor_targeting_radius_sqr then
            if total_score > cursor_max_score then
                cursor_max_score = total_score
                best_cursor_target = unit
            end

            if cursor_distance_sqr < closest_cursor_distance_sqr then
                closest_cursor_distance_sqr = cursor_distance_sqr
                closest_cursor_target = unit
            end
        end

        ::continue::
    end

    return best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target
end

local function use_ability(spell_name, delay_after_cast)
    local spell = spells[spell_name]
    if not (spell and spell.menu_elements.main_boolean:get()) then
        return false
    end

    local target_unit = nil
    if spell.menu_elements.targeting_mode then
        local targeting_mode = spell.menu_elements.targeting_mode:get()
        target_unit = ({
            [0] = best_ranged_target,
            [1] = best_ranged_target_visible,
            [2] = best_melee_target,
            [3] = best_melee_target_visible,
            [4] = closest_target,
            [5] = closest_target_visible,
            [6] = best_cursor_target,
            [7] = closest_cursor_target
        })[targeting_mode]
    end

    --if target_unit is nil, it means the spell is not targetted and we use the default logic without target
    if (target_unit and spell.logics(target_unit)) or (not target_unit and spell.logics()) then
        next_cast_time = get_time_since_inject() + delay_after_cast
        return true
    end

    return false
end

-- on_update callback
on_update(function()
    local current_time = get_time_since_inject()
    local local_player = get_local_player()
    if not local_player or menu.menu_elements.main_boolean:get() == false or current_time < next_cast_time then
        return
    end

    if not my_utility.is_action_allowed() then
        return;
    end

    targeting_refresh_interval = menu.menu_elements.targeting_refresh_interval:get()
    -- Only update targets if targeting_refresh_interval has expired
    if current_time >= next_target_update_time then
        local player_position = get_player_position()
        max_targeting_range = menu.menu_elements.max_targeting_range:get()

        local entity_list_visible, entity_list = my_target_selector.get_target_list(
            player_position,
            max_targeting_range,
            collision_table,
            floor_table,
            angle_table)

        target_selector_data_all = my_target_selector.get_target_selector_data(
            player_position,
            entity_list)

        local target_selector_data_visible = my_target_selector.get_target_selector_data(
            player_position,
            entity_list_visible)

        if not target_selector_data_all or not target_selector_data_all.is_valid then
            return
        end

        best_ranged_target = nil
        best_melee_target = nil
        closest_target = nil
        best_ranged_target_visible = nil
        best_melee_target_visible = nil
        closest_target_visible = nil
        best_cursor_target = nil
        closest_cursor_target = nil
        local melee_range = my_utility.get_melee_range()

        -- Check all targets within max range
        if target_selector_data_all and target_selector_data_all.is_valid then
            best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target = evaluate_targets(
                target_selector_data_all.list,
                melee_range)
            closest_target = target_selector_data_all.closest_unit
        end


        -- Check visible targets within max range
        if target_selector_data_visible and target_selector_data_visible.is_valid then
            best_ranged_target_visible, best_melee_target_visible = evaluate_targets(
                target_selector_data_visible.list,
                melee_range)
            closest_target_visible = target_selector_data_visible.closest_unit
        end

        -- Update next target update time
        next_target_update_time = current_time + targeting_refresh_interval
    end

    -- Ability usage - Sequence influences priority
    if use_ability("evade", my_utility.spell_delays.instant_cast) then return end
    if use_ability("armored_hide", my_utility.spell_delays.instant_cast) then return end
    if use_ability("ravager", my_utility.spell_delays.instant_cast) then return end
    if use_ability("counterattack", my_utility.spell_delays.instant_cast) then return end
    if use_ability("the_hunter", my_utility.spell_delays.regular_cast) then return end
    if use_ability("soar", my_utility.spell_delays.regular_cast) then return end
    if use_ability("scourge", my_utility.spell_delays.instant_cast) then return end
    if use_ability("vortex", my_utility.spell_delays.instant_cast) then return end
    if use_ability("crushing_hand", my_utility.spell_delays.regular_cast) then return end
    if use_ability("quill_volley", my_utility.spell_delays.regular_cast) then return end
    if use_ability("the_seeker", my_utility.spell_delays.regular_cast) then return end
    if use_ability("the_devourer", my_utility.spell_delays.regular_cast) then return end
    if use_ability("touch_of_death", my_utility.spell_delays.regular_cast) then return end
    if use_ability("concussive_stomp", my_utility.spell_delays.regular_cast) then return end
    if use_ability("payback", my_utility.spell_delays.regular_cast) then return end
    if use_ability("rake", my_utility.spell_delays.regular_cast) then return end
    if use_ability("razor_wings", my_utility.spell_delays.regular_cast) then return end
    if use_ability("rushing_claw", my_utility.spell_delays.regular_cast) then return end
    if use_ability("stinger", my_utility.spell_delays.regular_cast) then return end
    if use_ability("the_protector", my_utility.spell_delays.regular_cast) then return end
    if use_ability("toxic_skin", my_utility.spell_delays.instant_cast) then return end
    if use_ability("thunderspike", my_utility.spell_delays.regular_cast) then return end
    if use_ability("rock_splitter", my_utility.spell_delays.regular_cast) then return end
    if use_ability("thrash", my_utility.spell_delays.regular_cast) then return end
    if use_ability("withering_fist", my_utility.spell_delays.regular_cast) then return end
end)

-- Debug
local font_size = 16
local y_offset = font_size + 2
local visible_text = 255
local visible_alpha = 180
local alpha = 100
local target_evaluation_radius_alpha = 50
on_render(function()
    if menu.menu_elements.main_boolean:get() == false or not menu.menu_elements.enable_debug:get() then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    -- Draw max range
    max_targeting_range = menu.menu_elements.max_targeting_range:get()
    if menu.menu_elements.draw_max_range:get() then
        graphics.circle_3d(player_position, max_targeting_range, color_white(85), 2.5, 144)
    end

    -- Draw melee range
    if menu.menu_elements.draw_melee_range:get() then
        local melee_range = my_utility.get_melee_range()
        graphics.circle_3d(player_position, melee_range, color_white(85), 2.5, 144)
    end

    -- Draw enemy circles
    if menu.menu_elements.draw_enemy_circles:get() then
        local enemies = actors_manager.get_enemy_npcs()

        for i, obj in ipairs(enemies) do
            local position = obj:get_position();
            graphics.circle_3d(position, 1, color_white(100));

            local future_position = prediction.get_future_unit_position(obj, 0.4);
            graphics.circle_3d(future_position, 0.25, color_yellow(100));
        end;
    end

    if menu.menu_elements.draw_cursor_target:get() then
        local cursor_position = get_cursor_position()
        local cursor_targeting_radius = menu.menu_elements.cursor_targeting_radius:get()

        -- Draw cursor radius
        graphics.circle_3d(cursor_position, cursor_targeting_radius, color_white(target_evaluation_radius_alpha), 1);
    end

    -- Only draw targets if we have valid target selector data
    if not target_selector_data_all or not target_selector_data_all.is_valid then
        return
    end

    local best_target_evaluation_radius = menu.menu_elements.best_target_evaluation_radius:get()

    -- Draw targets
    if menu.menu_elements.draw_targets:get() then
        -- Draw visible ranged target
        if best_ranged_target_visible and best_ranged_target_visible:is_enemy() then
            local best_ranged_target_visible_position = best_ranged_target_visible:get_position();
            local best_ranged_target_visible_position_2d = graphics.w2s(best_ranged_target_visible_position);
            graphics.line(best_ranged_target_visible_position_2d, player_screen_position, color_red(visible_alpha),
                2.5)
            graphics.circle_3d(best_ranged_target_visible_position, 0.80, color_red(visible_alpha), 2.0);
            graphics.circle_3d(best_ranged_target_visible_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_ranged_target_visible_position_2d.x,
                best_ranged_target_visible_position_2d.y - y_offset)
            graphics.text_2d("RANGED_VISIBLE", text_position, font_size, color_red(visible_text))
        end

        -- Draw ranged target if it's not the same as the visible ranged target
        if best_ranged_target_visible ~= best_ranged_target and best_ranged_target and best_ranged_target:is_enemy() then
            local best_ranged_target_position = best_ranged_target:get_position();
            local best_ranged_target_position_2d = graphics.w2s(best_ranged_target_position);
            graphics.circle_3d(best_ranged_target_position, 0.80, color_red_pale(alpha), 2.0, 8);
            graphics.circle_3d(best_ranged_target_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_ranged_target_position_2d.x,
                best_ranged_target_position_2d.y - y_offset)
            graphics.text_2d("RANGED", text_position, font_size, color_red_pale(alpha))
        end

        -- Draw visible melee target
        if best_melee_target_visible and best_melee_target_visible:is_enemy() then
            local best_melee_target_visible_position = best_melee_target_visible:get_position();
            local best_melee_target_visible_position_2d = graphics.w2s(best_melee_target_visible_position);
            graphics.line(best_melee_target_visible_position_2d, player_screen_position, color_green(visible_alpha),
                2.5)
            graphics.circle_3d(best_melee_target_visible_position, 0.70, color_green(visible_alpha), 2.0);
            graphics.circle_3d(best_melee_target_visible_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_melee_target_visible_position_2d.x,
                best_melee_target_visible_position_2d.y)
            graphics.text_2d("MELEE_VISIBLE", text_position, font_size, color_green(visible_text))
        end

        -- Draw melee target if it's not the same as the visible melee target
        if best_melee_target_visible ~= best_melee_target and best_melee_target and best_melee_target:is_enemy() then
            local best_melee_target_position = best_melee_target:get_position();
            local best_melee_target_position_2d = graphics.w2s(best_melee_target_position);
            graphics.circle_3d(best_melee_target_position, 0.70, color_green_pale(alpha), 2.0, 8);
            graphics.circle_3d(best_melee_target_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_melee_target_position_2d.x, best_melee_target_position_2d.y)
            graphics.text_2d("MELEE", text_position, font_size, color_green_pale(alpha))
        end

        -- Draw visible closest target
        if closest_target_visible and closest_target_visible:is_enemy() then
            local closest_target_visible_position = closest_target_visible:get_position();
            local closest_target_visible_position_2d = graphics.w2s(closest_target_visible_position);
            graphics.line(closest_target_visible_position_2d, player_screen_position, color_cyan(visible_alpha), 2.5)
            graphics.circle_3d(closest_target_visible_position, 0.60, color_cyan(visible_alpha), 2.0);
            graphics.circle_3d(closest_target_visible_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(closest_target_visible_position_2d.x,
                closest_target_visible_position_2d.y + y_offset)
            graphics.text_2d("CLOSEST_VISIBLE", text_position, font_size, color_cyan(visible_text))
        end

        -- Draw closest target if it's not the same as the visible closest target
        if closest_target_visible ~= closest_target and closest_target and closest_target:is_enemy() then
            local closest_target_position = closest_target:get_position();
            local closest_target_position_2d = graphics.w2s(closest_target_position);
            graphics.circle_3d(closest_target_position, 0.60, color_cyan_pale(alpha), 2.0, 8);
            graphics.circle_3d(closest_target_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(closest_target_position_2d.x, closest_target_position_2d.y + y_offset)
            graphics.text_2d("CLOSEST", text_position, font_size, color_cyan_pale(alpha))
        end
    end

    if menu.menu_elements.draw_cursor_target:get() then
        -- Draw best cursor target
        if best_cursor_target and best_cursor_target:is_enemy() then
            local best_cursor_target_position = best_cursor_target:get_position();
            local best_cursor_target_position_2d = graphics.w2s(best_cursor_target_position);
            graphics.circle_3d(best_cursor_target_position, 0.60, color_orange_red(255), 2.0, 5);
            graphics.text_2d("best_cursor_target", best_cursor_target_position_2d, font_size, color_orange_red(255))
        end

        -- Draw closest cursor target
        if closest_cursor_target and closest_cursor_target:is_enemy() then
            local closest_cursor_target_position = closest_cursor_target:get_position();
            local closest_cursor_target_position_2d = graphics.w2s(closest_cursor_target_position);
            graphics.circle_3d(closest_cursor_target_position, 0.40, color_green_pastel(255), 2.0, 5);
            local text_position = vec2:new(closest_cursor_target_position_2d.x,
                closest_cursor_target_position_2d.y + y_offset)
            graphics.text_2d("closest_cursor_target", text_position, font_size,
                color_green_pastel(255))
        end
    end
end);

console.print("Lua Plugin - Spiritborn Dirty - Version 1.0");
