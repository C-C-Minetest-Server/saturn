local format_pos = function(format,pos)
	return "("..string.format(format,pos.x)..","..string.format(format,pos.y)..","..string.format(format,pos.z)..")"
end

local PROJECTION_XZ = 1
local PROJECTION_XY = 2
local scale_map = {1,2,4,8,16,32,64,128}

local get_map_scale_bar_formspec = function(scale)
    local x_pos = 0.2
    local y_pos = 4
    local bar_length = 8
    local formspec = "image_button["..x_pos..","..y_pos..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:1")..";set_map_scale_"..math.min(scale+1,bar_length)..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:1").."]"..
	"image_button["..x_pos..","..(y_pos+bar_length*0.35+0.35)..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:2")..";set_map_scale_"..math.max(scale-1,1)..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:2").."]"
    for i=1,bar_length do
	if i == scale then
		formspec = formspec .. "image_button["..x_pos..","..(y_pos+(bar_length-i+1)*0.35)..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:6")..";set_map_scale_"..i..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:6").."]"
	else
		formspec = formspec .. "image_button["..x_pos..","..(y_pos+(bar_length-i+1)*0.35)..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:5")..";set_map_scale_"..i..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:5").."]"
	end
    end
    return formspec
end

local get_map_mark_formspec = function(scale, projection, pos, player_pos, title, width, height)
    local scale_multiplier = scale_map[scale]
    local x_pos = ((pos.x - player_pos.x) * scale_multiplier + 31000) * width / 62000
    local y_pos = ((player_pos.z - pos.z) * scale_multiplier + 31000) * height / 62000
    if projection == PROJECTION_XY then
	y_pos = ((player_pos.y - pos.y) * scale_multiplier + 31000) * height / 62000
    end
    if x_pos > 0 and x_pos < width and y_pos > 0 and y_pos < height then
	return "image["..x_pos..","..(y_pos+1)..";0.5,0.5;saturn_arrows_and_frame_blue.png^[verticalframe:10:9]"..
"label["..x_pos..","..(y_pos+1)..";"..title..format_pos("%d",pos).."]"
    else
	return ""
    end
end

local get_color_formspec_frame = function(x,y,w,h,color,thickness)
	local gap = 0.2
	return "box["..(x-thickness+gap)..","..(y-thickness)..";"..(w+thickness-0.2-gap*2)..","..(thickness)..";"..color.."]"..
"box["..(x+w-0.2)..","..(y-thickness+gap)..";"..(thickness)..","..(h+thickness-0.2-gap*2)..";"..color.."]"..
"box["..(x+gap)..","..(y+h-0.2)..";"..(w+thickness-0.2-gap*2)..","..(thickness)..";"..color.."]"..
"box["..(x-thickness)..","..(y+gap)..";"..(thickness)..","..(h+thickness-0.2-gap*2)..";"..color.."]"
end

saturn.get_color_formspec_frame = get_color_formspec_frame

local get_map_formspec = function(scale, projection, player)
    local form_width = 9
    local form_height = 9
    local coordinate_arrows = "saturn_map_zero_xz_mark.png"
    if projection == PROJECTION_XY then
	coordinate_arrows = "saturn_map_zero_xy_mark.png"
    end
    local formspec = get_map_mark_formspec(scale, projection, player:getpos(), player:getpos(), "YOU", form_width, form_height)..
	"image["..(form_width - 1.5)..","..(form_height - 1.5)..";1,1;"..coordinate_arrows.."]"..
	get_map_scale_bar_formspec(scale)..
	get_color_formspec_frame(0,0,form_width,form_height,"#041",0.05)..
	"field[0.5,1;2,0.2;set_waypoint;"..minetest.formspec_escape("Set waypoint:")..";(0,0,0)]"
    for _,ss in ipairs(saturn.human_space_station) do
	formspec = formspec .. get_map_mark_formspec(scale, projection, ss, player:getpos(), "SS#".._, form_width, form_height)
    end
    for _,ess in ipairs(saturn.enemy_space_station) do
	formspec = formspec .. get_map_mark_formspec(scale, projection, ess, player:getpos(), "EMS#".._, form_width, form_height)
    end
    return formspec
end

local get_formspec_label_with_bg_color = function(x,y,w,h,color,text)
	return "box["..x..","..y..";"..w..","..h..";"..color.."]".."label["..x..","..(y-0.2)..";"..text.."]"
end


saturn.get_ship_equipment_formspec = function(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	-- Hull
	local formspec = "list[current_player;ship_hull;0,0;1,1;]".."box[0,0;0.8,0.9;#FFFFFF]"..get_formspec_label_with_bg_color(0,1,0.8,0.2,"#FFFFFF","Hull")..
	"image_button[0.81,0;0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+ship_hull+1;]"
	if inv:get_size("engine") > 0 then
		formspec = formspec.."box[1,0;1.8,3.9;#FFA800]"..get_formspec_label_with_bg_color(0,1.4,0.8,0.2,"#FFA800","Engine")..
		"list[current_player;engine;1,0;2,4;]"
		for ix = 1, 2 do
			for iy = 0, math.ceil(inv:get_size("engine")/2)-1 do
				formspec = formspec.."image_button["..(ix+0.81)..","..(iy)..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+engine+"..(ix+2*iy)..";]"
			end
		end
	end
	if inv:get_size("power_generator") > 0 then
		formspec = formspec.."box[3,0;0.8,3.9;#FF2200]"..get_formspec_label_with_bg_color(0,1.8,0.8,0.2,"#FF2200","Power")..
		"list[current_player;power_generator;3,0;1,4;]"
		for iy = 0, inv:get_size("power_generator")-1 do
			formspec = formspec.."image_button[3.81,"..iy..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+power_generator+"..(iy+1)..";]"
		end
	end
	if inv:get_size("droid") > 0 then
		formspec = formspec.."box[4,0;0.8,3.9;#770000]"..get_formspec_label_with_bg_color(0,2.2,0.8,0.2,"#770000","Droids")..
		"list[current_player;droid;4,0;1,4;]"
		for iy = 0, inv:get_size("droid")-1 do
			formspec = formspec.."image_button[4.81,"..iy..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+droid+"..(iy+1)..";]"
		end
	end
	if inv:get_size("radar") > 0 then
		formspec = formspec.."box[5,0;0.8,0.9;#00FFF0]"..get_formspec_label_with_bg_color(0,2.6,0.8,0.2,"#00FFF0","Radar")..
		"list[current_player;radar;5,0;1,4;]"
		for iy = 0, inv:get_size("radar")-1 do
			formspec = formspec.."image_button[5.81,"..iy..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+radar+"..(iy+1)..";]"
		end
	end
	if inv:get_size("forcefield_generator") > 0 then
		formspec = formspec.."box[6,0;0.8,0.9;#A0A0FF]"..get_formspec_label_with_bg_color(0,3,0.8,0.2,"#A0A0FF","Forcefield")..
		"list[current_player;forcefield_generator;6,0;1,1;]"
		for iy = 0, inv:get_size("forcefield_generator")-1 do
			formspec = formspec.."image_button[6.81,"..iy..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+forcefield_generator+"..(iy+1)..";]"
		end
	end
	if inv:get_size("special_equipment") > 0 then
		formspec = formspec.."box[7,0;0.8,3.9;#A0FFA0]"..get_formspec_label_with_bg_color(0,3.4,0.8,0.2,"#A0FFA0","Special")..
		"list[current_player;special_equipment;7,0;1,4;]"
		for iy = 0, inv:get_size("special_equipment")-1 do
			formspec = formspec.."image_button[7.81,"..iy..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+special_equipment+"..(iy+1)..";]"
		end
	end
	return formspec
end

saturn.get_main_inventory_formspec = function(player, vertical_offset)
    local default_formspec = "list[current_player;main;0,"..vertical_offset..";8,1;]"..
		"list[current_player;main;0,"..(vertical_offset+1.25)..";8,3;8]"..
		saturn.default_slot_color
    if player then
    local name = player:get_player_name()
	for ix = 1, 8 do
		for iy = 0, 3 do
			if iy==0 then
				default_formspec = default_formspec.."image_button["..(ix-0.19)..","..vertical_offset..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+main+"..(ix+8*iy)..";]"
			else
				default_formspec = default_formspec.."image_button["..(ix-0.19)..","..(iy+vertical_offset+0.25)..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+main+"..(ix+8*iy)..";]"
			end
		end
	end
    end
    return default_formspec
end

local get_player_inventory_formspec = function(player, tab)
	local name = player:get_player_name()
	local default_formspec = "tabheader[0,0;tabs;Status,Hull,Map;"..tab..";true;false]"
	local hull = player:get_inventory():get_stack("ship_hull", 1)
	local hull_stats = saturn.get_item_stats(hull:get_name())
	if hull_stats then
		if tab == 1 then
			local hull_max_wear = hull_stats['max_wear'] or saturn.MAX_ITEM_WEAR
			local hull_wear = hull:get_wear()
			local display_status = hull_wear * hull_max_wear / saturn.MAX_ITEM_WEAR
			local max_volume = hull_stats['free_space']
			local ship = player:get_attach()
			local ship_lua = ship:get_luaentity()
			local velocity = vector.length(ship:getvelocity())
			local traction = ship_lua['traction']
			local traction_bonus = ship_lua.total_modificators['traction']
			if traction_bonus then
				traction = traction + traction_bonus
			end
			local forcefield_protection = ship_lua['forcefield_protection']
			local forcefield_protection_bonus = ship_lua.total_modificators['forcefield_protection']
			if forcefield_protection_bonus then
				forcefield_protection = forcefield_protection + forcefield_protection_bonus
			end
			return "size[8,8.6]"..
				default_formspec..
				"label[0,0;"..minetest.formspec_escape("Hull damage: ")..string.format ('%4.0f',display_status).."/"..hull_max_wear.."]"..
				"label[0,0.25;"..minetest.formspec_escape("Money: ")..string.format ('%4.0f',saturn.players_info[name]['money']).." Cr.]"..
				"label[0,0.5;"..minetest.formspec_escape("Occupied hold volume: ")..string.format ('%4.2f',ship_lua['volume']).."/"..max_volume.." m3]"..
				"label[0,0.75;"..minetest.formspec_escape("Total ship weight: ")..string.format ('%4.0f',ship_lua['weight']).." kg]"..
				"label[0,1.0;"..minetest.formspec_escape("Traction: ")..string.format ('%4.1f',traction/1000).." kN]"..
				"label[0,1.25;"..minetest.formspec_escape("Forcefield damage absorption: ")..string.format ('%4.1f',forcefield_protection).." %]"..
				"label[0,1.5;"..minetest.formspec_escape("Max acceleration: ")..string.format ('%4.1f',traction/ship_lua['weight']).." m/s2]"..
				"label[0,1.75;"..minetest.formspec_escape("Free power: ")..string.format ('%4.0f',ship_lua['free_power']).." MW]"..
				"button[0,2;4,1;abandon_ship;Abandon ship]"..
				saturn.get_main_inventory_formspec(player,4.25)
		elseif tab == 2 then
			return "size[8,8.6]"..default_formspec..saturn.get_ship_equipment_formspec(player)..
				saturn.get_main_inventory_formspec(player,4.25)
		elseif tab == 3 then
			local ship = player:get_attach()
			local ship_lua = ship:get_luaentity()
			local map_scale = ship_lua['map_scale'] or 1
			local map_projection = ship_lua['map_projection'] or 1
			return "size[9,8.6]"..default_formspec..get_map_formspec(map_scale, map_projection, player)
		end
	end
	return default_formspec
end

saturn.get_player_inventory_formspec = get_player_inventory_formspec

saturn.get_item_info_formspec = function(item_stack)
	local item_name = item_stack:get_name()
	local formspec = "size[8,8.6]"..
		"item_image[0,0;1,1;"..item_name.."]"..
		"label[1,0.0;"..item_name.."]"..
		"image_button[6.5,0.1;1.5,0.4;saturn_back_button_icon.png;ii_return;Back  ;false;false;saturn_back_button_icon.png]"
	local row_step = 0.3
	local row = 1
	formspec = formspec.."label[0,"..row..";Basic properties:]"
	row = row + 0.1
	if minetest.registered_items[item_name] then
		for key,value in pairs(minetest.registered_items[item_name]) do
			if not saturn.localisation_and_units[key] then
				error("Missing localisation for "..key)
				return
			end
			if not saturn.localisation_and_units[key].hidden then
				row = row + row_step
				local localisation = saturn.localisation_and_units[key]
				local string_value
				if localisation.format_normal == "date" then
					string_value = saturn.date_to_string(value) .." ".. localisation.units
				elseif type(value) == "number" then
					string_value = string.format(localisation.format_normal,value) .." ".. localisation.units
				else
					string_value = tostring(value)
				end
				formspec = formspec.."label[0,"..row..";"..localisation.name..": "..string_value.."]"
			end
		end
	end
	local metadata = minetest.deserialize(item_stack:get_metadata())
	if metadata then
		row = row + row_step*2
		formspec = formspec.."label[0,"..row..";Special properties:]"
		row = row + 0.1
		for key,value in pairs(metadata) do
			if not saturn.localisation_and_units[key] then
				error("Missing localisation for "..key)
				return
			end
			if not saturn.localisation_and_units[key].hidden then
				row = row + row_step
				local localisation = saturn.localisation_and_units[key]
				local string_value
				if localisation.format_special == "date" then
					string_value = saturn.date_to_string(value) .." ".. localisation.units
				elseif type(value) == "number" then
					string_value = string.format(localisation.format_special,value) .." ".. localisation.units
				else
					string_value = tostring(value)
				end
				formspec = formspec.."label[0,"..row..";"..localisation.name..": "..string_value.."]"
			end
		end
	end
	return formspec
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if player:get_attach() then
	local ship_lua = player:get_attach():get_luaentity()
	if fields.tabs or fields.ii_return then
		if player:get_attach() then
			local tab = ship_lua['current_gui_tab']
			if fields.tabs then
				tab = tonumber(fields.tabs)
			end
			ship_lua['current_gui_tab'] = tab
			if formname == "saturn:space_station" then
				minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab, ship_lua['last_ss']))
			else
				player:set_inventory_formspec(get_player_inventory_formspec(player, tab))
			end
		end
	elseif fields.repair then
		saturn.repair_player_inventory_and_get_price(player, true)
		minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, ship_lua['current_gui_tab'], ship_lua['last_ss']))
		saturn.refresh_health_hud(player)
	elseif fields.deliver then
		saturn.deliver_package_and_get_reward(ship_lua['last_ss'], player, true)
		minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, ship_lua['current_gui_tab'], ship_lua['last_ss']))
	elseif fields.abandon_ship then
		local inv = player:get_inventory()
		for list_name,list in pairs(inv:get_lists()) do
			for listpos,stack in pairs(list) do
				if stack ~= nil and not stack:is_empty() then
					inv:remove_item(list_name, stack)
					saturn.throw_item(stack, player:get_attach(), player:getpos())
				end
			end
		end
		minetest.sound_play("saturn_item_drop", {to_player = name})
		inv:set_stack("ship_hull", 1, saturn:get_escape_pod())
	elseif fields.set_waypoint then
		for key,v in pairs(fields) do
			local parameters_list, match = string.gsub(key, "^set_map_scale_", "")
			if match == 1 and parameters_list then
				local scale = tonumber(parameters_list)
				ship_lua['map_scale'] = scale
				player:set_inventory_formspec(get_player_inventory_formspec(player, 3))
			end
		end
		if fields.quit then
			local wp_pos = minetest.string_to_pos(fields.set_waypoint)
			if wp_pos then
				ship_lua['waypoint'] = wp_pos
			else
				local number, match = string.gsub(fields.set_waypoint, "^SS#", "")
				if match == 1 and tonumber(number) and tonumber(number)<=saturn.NUMBER_OF_SPACE_STATIONS then
					ship_lua['waypoint'] = saturn.human_space_station[tonumber(number)]
				end
				number, match = string.gsub(fields.set_waypoint, "^EMS#", "")
				if match == 1 and tonumber(number) and tonumber(number)<=#saturn.enemy_space_station then
					ship_lua['waypoint'] = saturn.enemy_space_station[tonumber(number)]
				end
			end

		end
		--minetest.chat_send_all(dump(fields))
	elseif fields.quit then
		if player:get_attach() then
			ship_lua['is_node_gui_opened'] = false
		end
	else
		for key,v in pairs(fields) do
			local parameters_list, match = string.gsub(key, "^item_info_", "")
			if match == 1 and parameters_list then
				local item_stack_location_data = string.split(parameters_list, "+", false, -1, false)
				local inventory_type = item_stack_location_data[1]
				local inventory_name_or_pos = item_stack_location_data[2]
				local inventory_list_name = item_stack_location_data[3]
				local inventory_slot_number = tonumber(item_stack_location_data[4])
				local inventory
				if inventory_type == "nodemeta" then
					inventory = minetest.get_inventory({type=inventory_type, pos=minetest.string_to_pos(inventory_name_or_pos)})
					if not inventory then
						error("Calling inventory failed for "..parameters_list)
					end
				else
					inventory = minetest.get_inventory({type=inventory_type, name=inventory_name_or_pos})
				end
				local item_stack = inventory:get_stack(inventory_list_name, inventory_slot_number)
				if not item_stack:is_empty() then
					if formname == "saturn:space_station" then
						minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_item_info_formspec(item_stack))
					else
						player:set_inventory_formspec(saturn.get_item_info_formspec(item_stack))
					end
					return true
				end
			end
		end
	end
    end
end)
