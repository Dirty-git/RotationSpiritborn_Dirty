-- local target_selector = require("my_utility/my_target_selector")
local spell_data = require("my_utility/spell_data")

local function is_auto_play_enabled()
    -- auto play fire spells without orbwalker
    local is_auto_play_active = auto_play.is_active();
    local auto_play_objective = auto_play.get_objective();
    local is_auto_play_fighting = auto_play_objective == objective.fight;
    if is_auto_play_active and is_auto_play_fighting then
        return true;
    end

    return false;
end

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local shrine_conduit_buff_name = "Shine_Conduit";
local shrine_conduit_buff_name_hash = shrine_conduit_buff_name;
local shrine_conduit_buff_name_hash_c = 421661;

local function is_spell_active(spell_id)
    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return false end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return false end

    -- Check each buff for a matching spell ID
    for _, buff in ipairs(local_player_buffs) do
        if buff.name_hash == spell_id then
            return true
        end
    end

    return false
end

local function is_buff_active(spell_id, buff_id, min_stack_count)
    -- set default set count to 1 if not passed
    min_stack_count = min_stack_count or 1

    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return false end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return false end

    -- for every buff
    for _, buff in ipairs(local_player_buffs) do
        -- if we have a matching spell and buff id and
        -- we have at least the minimum amount of stack or the buff has more than 0.2 seconds remaining
        if buff.name_hash == spell_id and buff.type == buff_id and (buff.stacks >= min_stack_count or buff:get_remaining_time() > 0.2) then
            return true
        end
    end

    return false
end

local function buff_stack_count(spell_id, buff_id)
    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return 0 end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return 0 end

    -- iterate over each buff
    for _, buff in ipairs(local_player_buffs) do
        -- check for matching spell and buff id
        if buff.name_hash == spell_id and buff.type == buff_id then
            -- return the stack amount immediately
            return buff.stacks
        end
    end

    -- return 0 if no matching buff is found
    return 0
end

local function is_action_allowed()
    -- evade abort
    local local_player = get_local_player();
    if not local_player then
        return false
    end

    local player_position = local_player:get_position();
    if evade.is_dangerous_position(player_position) then
        return false;
    end

    local busy_spell_id_1 = 197833
    local active_spell_id = local_player:get_active_spell_id()
    if active_spell_id == busy_spell_id_1 then
        return false
    end

    local is_mounted = false;
    local is_blood_mist = false;
    local is_shrine_conduit = false;
    local local_player_buffs = local_player:get_buffs();
    for _, buff in ipairs(local_player_buffs) do
        -- console.print("buff name ", buff:name());
        -- console.print("buff hash ", buff.name_hash);
        if buff.name_hash == mount_buff_name_hash_c then
            is_mounted = true;
            break;
        end

        if buff.name_hash == shrine_conduit_buff_name_hash_c then
            is_shrine_conduit = true;
            break;
        end
    end

    -- do not make any actions while in blood mist
    if is_blood_mist or is_mounted or is_shrine_conduit then
        -- console.print("Blocking Actions for Some Buff");
        return false;
    end

    return true
end

local function is_spell_allowed(spell_enable_check, next_cast_allowed_time, spell_id)
    if not spell_enable_check then
        return false;
    end;

    local current_time = get_time_since_inject();
    if current_time < next_cast_allowed_time then
        return false;
    end;

    if not utility.is_spell_ready(spell_id) then
        return false;
    end;

    if not utility.is_spell_affordable(spell_id) then
        return false;
    end;

    if not utility.can_cast_spell(spell_id) then
        return false;
    end;


    -- "Combo & Clear", "Combo Only", "Clear Only"
    -- local current_cast_mode = spell_cast_mode

    -- evade abort
    local local_player = get_local_player();
    if local_player then
        local player_position = local_player:get_position();
        if evade.is_dangerous_position(player_position) then
            return false;
        end
    end

    -- -- automatic
    -- if current_cast_mode == 4 then
    --     return true
    -- end

    if is_auto_play_enabled() then
        return true;
    end

    -- local is_pvp_or_clear = current_cast_mode == 0
    -- local is_pvp_only = current_cast_mode == 1
    -- local is_clear_only = current_cast_mode == 2

    local current_orb_mode = orbwalker.get_orb_mode()

    if current_orb_mode == orb_mode.none then
        return false
    end

    local is_current_orb_mode_pvp = current_orb_mode == orb_mode.pvp
    local is_current_orb_mode_clear = current_orb_mode == orb_mode.clear
    -- local is_current_orb_mode_flee = current_orb_mode == orb_mode.flee

    -- if is_pvp_only and not is_current_orb_mode_pvp then
    --     return false
    -- end

    -- if is_clear_only and not is_current_orb_mode_clear then
    --     return false
    -- end

    -- is pvp or clear (both)
    if not is_current_orb_mode_pvp and not is_current_orb_mode_clear then
        return false;
    end

    -- we already checked everything that we wanted. If orb = none, we return false.
    -- PVP only & not pvp mode, return false . PvE only and not pve mode, return false.
    -- All checks passed at this point so we can go ahead with the logics

    return true
end

local function generate_points_around_target(target_position, radius, num_points)
    local points = {};
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points);
        local x = target_position:x() + radius * math.cos(angle);
        local y = target_position:y() + radius * math.sin(angle);
        table.insert(points, vec3.new(x, y, target_position:z()));
    end
    return points;
end

local function get_best_point(target_position, circle_radius, current_hit_list)
    local points = generate_points_around_target(target_position, circle_radius * 0.75, 8); -- Generate 8 points around target
    local hit_table = {};

    local player_position = get_player_position();
    for _, point in ipairs(points) do
        local hit_list = utility.get_units_inside_circle_list(point, circle_radius);

        local hit_list_collision_less = {};
        for _, obj in ipairs(hit_list) do
            local is_wall_collision = target_selector.is_wall_collision(player_position, obj, 2.0);
            if not is_wall_collision then
                table.insert(hit_list_collision_less, obj);
            end
        end

        table.insert(hit_table, {
            point = point,
            hits = #hit_list_collision_less,
            victim_list = hit_list_collision_less
        });
    end

    -- sort by the number of hits
    table.sort(hit_table, function(a, b) return a.hits > b.hits end);

    local current_hit_list_amount = #current_hit_list;
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1]; -- returning the point with the most hits
    end

    return { point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list };
end

function is_target_within_angle(origin, reference, target, max_angle)
    local to_reference = (reference - origin):normalize();
    local to_target = (target - origin):normalize();
    local dot_product = to_reference:dot(to_target);
    local angle = math.deg(math.acos(dot_product));
    return angle <= max_angle;
end

local function generate_points_around_target_rec(target_position, radius, num_points)
    local points = {}
    local angles = {}
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points)
        local x = target_position:x() + radius * math.cos(angle)
        local y = target_position:y() + radius * math.sin(angle)
        table.insert(points, vec3.new(x, y, target_position:z()))
        table.insert(angles, angle)
    end
    return points, angles
end

local function get_best_point_rec(target_position, rectangle_radius, width, current_hit_list)
    local points, angles = generate_points_around_target_rec(target_position, rectangle_radius, 8)
    local hit_table = {}

    for i, point in ipairs(points) do
        local angle = angles[i]
        -- Calculate the destination point based on width and angle
        local destination = vec3.new(point:x() + width * math.cos(angle), point:y() + width * math.sin(angle), point:z())

        local hit_list = utility.get_units_inside_rectangle_list(point, destination, width)
        table.insert(hit_table, { point = point, hits = #hit_list, victim_list = hit_list })
    end

    table.sort(hit_table, function(a, b) return a.hits > b.hits end)

    local current_hit_list_amount = #current_hit_list
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1] -- returning the point with the most hits
    end

    return { point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list }
end

local function enemy_count_in_range(evaluation_range, source_position)
    -- set default source position to player position
    local source_position = source_position or get_player_position();
    local enemies = target_selector.get_near_target_list(source_position, evaluation_range);
    local all_units_count = 0;
    local normal_units_count = 0;
    local elite_units_count = 0;
    local champion_units_count = 0;
    local boss_units_count = 0;

    for _, obj in ipairs(enemies) do
        if not obj:is_enemy() or obj:is_untargetable() or obj:is_immune() then
            -- Skip this object and continue with the next one
            goto continue
        end;

        if obj:is_boss() then
            boss_units_count = boss_units_count + 1;
        elseif obj:is_champion() then
            champion_units_count = champion_units_count + 1;
        elseif obj:is_elite() then
            elite_units_count = elite_units_count + 1;
        else
            normal_units_count = normal_units_count + 1;
        end
        all_units_count = all_units_count + 1;

        ::continue::
    end;
    return all_units_count, normal_units_count, elite_units_count, champion_units_count, boss_units_count
end

local function get_melee_range()
    local melee_range = 2

    if is_buff_active(spell_data.ravager.spell_id, spell_data.ravager.buff_ids.dash) then
        melee_range = 7
    end

    return melee_range
end

local function is_in_range(target, range)
    local target_position = target:get_position()
    local player_position = get_player_position()
    local target_distance_sqr = player_position:squared_dist_to_ignore_z(target_position)
    local range_sqr = (range * range)
    return target_distance_sqr < range_sqr
end

local spell_delays = {
    -- NOTE: if a regular cast is used, it means even instant abilities will be on cooldown for the duration of the regular cast, not optimal
    instant_cast = 0.01, -- instant cast abilites should be used as soon as possible
    regular_cast = 0.1   -- regular abilites with animation should be used with a delay
}

local evaluation_range_description = "\n      Range to check for enemies around the player      \n\n"

local targeting_modes = {
    "Ranged Target",             -- 0
    "Ranged Target (in sight)",  -- 1
    "Melee Target",              -- 2
    "Melee Target (in sight)",   -- 3
    "Closest Target",            -- 4
    "Closest Target (in sight)", -- 5
    "Best Cursor Target",        -- 6
    "Closest Cursor Target"      -- 7
}

local activation_filters = {
    "Any Enemy",         -- 0
    "Elite & Boss Only", -- 1
    "Boss Only"          -- 2
}

local targeting_mode_description =
    "       Ranged Target: Targets the most valuable enemy within max range (set in settings)     \n" ..
    "       Ranged Target (in sight): Targets the most valuable visible enemy within max range     \n" ..
    "       Melee Target: Targets the most valuable enemy within melee range (influenced by ravager buff)     \n" ..
    "       Melee Target (in sight): Targets the most valuable visible enemy within melee range     \n" ..
    "       Closest Target: Targets the closest enemy to the player      \n" ..
    "       Closest Target (in sight): Targets the closest visible enemy to the player      \n" ..
    "       Best Cursor Target: Targets the most valuable enemy around the cursor      \n" ..
    "       Closest Cursor Target: Targets the enemy nearest to the cursor      \n"

local plugin_label = "BASE_SPIRITBORN_PLUGIN_DIRTY_"

return
{
    spell_delays = spell_delays,
    activation_filters = activation_filters,
    targeting_mode_description = targeting_mode_description,
    targeting_modes = targeting_modes,
    evaluation_range_description = evaluation_range_description,
    plugin_label = plugin_label,
    is_spell_allowed = is_spell_allowed,
    is_action_allowed = is_action_allowed,
    is_spell_active = is_spell_active,
    is_buff_active = is_buff_active,
    buff_stack_count = buff_stack_count,

    is_auto_play_enabled = is_auto_play_enabled,

    get_best_point = get_best_point,
    generate_points_around_target = generate_points_around_target,

    is_target_within_angle = is_target_within_angle,

    get_best_point_rec = get_best_point_rec,
    enemy_count_in_range = enemy_count_in_range,
    get_melee_range = get_melee_range,
    is_in_range = is_in_range
}
