saturn.space_station_pos = {x = -64, y = -64, z = -64}

saturn.default_slot_color = "listcolors[#80808069;#00000069;#141318;#30434C;#FFF]"
saturn.MAX_ITEM_WEAR = 65535 -- Internal minetest constant and should not be changed
saturn.REPAIR_PRICE_PER_WEAR = 0.0001
saturn.saturn_spaceships = {}
saturn.players_info = {}
saturn.players_save_interval = 1000
saturn.save_timer = saturn.players_save_interval
saturn.market_update_interval = 1000
saturn.market_update_timer = saturn.market_update_interval
saturn.item_stats = {}
saturn.market_items = {}
saturn.ore_market_items = {}
saturn.microfactory_market_items = {}
saturn.enemy_item_count = 0
saturn.enemy_items = {}
saturn.ores = {}
saturn.hud_healthbar_id = -1
saturn.hud_energybar_id = -1
saturn.hud_energybar_filler_id = -1
saturn.hud_relative_velocity_id = -1
saturn.hud_attack_info_text_id = -1
saturn.hud_attack_info_frame_id = -1
saturn.hud_hotbar_cooldown = {}
saturn.hotbar_cooldown = {}
saturn.microfactory_nets = {}
saturn.recipe_outputs = {}

local fov = minetest.setting_get("fov")
local fov_x = fov*1.1
local fov_y = fov
local tan_fov_x = math.tan(math.pi*fov_x/360)
local tan_fov_y = math.tan(math.pi*fov_y/360)

saturn.get_onscreen_coords_of_object = function(player, object) --highly inaccurate
	local look_dir=player:get_look_dir()
	local look_x=look_dir.x
	local look_y=look_dir.y
	local look_z=look_dir.z
	local look_yaw = player:get_look_yaw()
	local look_pitch = player:get_look_pitch()
	local player_pos = player:getpos()
	local object_pos = object:getpos()
	local vector_to_object = vector.subtract(object_pos, player_pos)
	local distance_to_object = vector.length(vector_to_object)
	local look_vector_extended_to_point_on_object_sphere = vector.multiply(look_dir, distance_to_object)
	local vector_between_extended_look_and_object = vector.subtract(vector_to_object, look_vector_extended_to_point_on_object_sphere)
	local vlb_x = vector_between_extended_look_and_object.x
	local vlb_y = vector_between_extended_look_and_object.y-1
	local vlb_z = vector_between_extended_look_and_object.z
	local screen_projection_width = tan_fov_x * distance_to_object
	local screen_projection_height = tan_fov_y * distance_to_object
	local cos_yaw = math.cos(look_yaw)
	local sin_yaw = math.sin(look_yaw)
	local x_offset = vlb_x*sin_yaw - vlb_z*cos_yaw
	local y_offset = (vlb_x*cos_yaw + vlb_z*sin_yaw)*look_y-vlb_y*math.cos(look_pitch)
	local xo_normal = x_offset/screen_projection_width
	local yo_normal = y_offset/screen_projection_height
	local x_pos = 0.5*xo_normal+0.5
	local y_pos = 0.5*yo_normal+0.5
	if vector.length(vector_between_extended_look_and_object) > distance_to_object then
		x_pos = 0.5*(xo_normal+saturn.sign_of_number(xo_normal))+0.5
	end
	local frame_type = 0
	if x_pos < 0 and y_pos < 0 then
		frame_type = 1
	elseif x_pos < 1 and y_pos < 0 then
		frame_type = 2
	elseif x_pos < 0 and y_pos < 1 then
		frame_type = 8
	elseif x_pos > 1 and y_pos < 0 then
		frame_type = 3
	elseif x_pos < 0 and y_pos > 1 then
		frame_type = 7
	elseif x_pos < 1 and y_pos > 1 then
		frame_type = 6
	elseif x_pos > 1 and y_pos < 1 then
		frame_type = 4
	elseif x_pos > 1 and y_pos > 1 then
		frame_type = 5
	end
	return {x=math.max(math.min(x_pos,0.98),0.02), y=math.max(math.min(y_pos,0.98),0.02), frame=frame_type}
end

saturn.get_escape_pod = function()
	local escape_pod = ItemStack("saturn:escape_pod")
	escape_pod:set_metadata(minetest.serialize({traction = 500,}))
	return escape_pod
end

saturn.release_delayed_power_and_try_to_shoot_again = function(ship_lua, amount, slot_number)
	local stop_sound = true
	local player = ship_lua.driver
	ship_lua['recharging_equipment_power_consumption'] = ship_lua['recharging_equipment_power_consumption'] - amount
	saturn.refresh_energy_hud(player)
	if player:get_wield_index() == slot_number then
		if player:get_player_control().LMB then
			local item_stack = player:get_wielded_item()
			if not item_stack:is_empty() then
				local on_use = item_stack:get_definition().on_use
				if on_use then
					ship_lua['ignore_cooldown'] = true
					player:set_wielded_item(on_use(item_stack, player, nil))
					stop_sound = false
				end
			end
		end
	end
	if stop_sound and ship_lua['weapon_sound_handler'] then
		minetest.sound_stop(ship_lua['weapon_sound_handler'])
		ship_lua['weapon_sound_handler'] = nil
	end
end

saturn.get_item_weight = function(list_name, item_stack)
	local item_name = item_stack:get_name()
	local value = 1000
	if list_name == "hangar" then
		value = 0
	else
		local stats = saturn.item_stats[item_name]
		if stats ~= nil then
			if stats['weight'] then
				value = stats['weight']
				local metadata = minetest.deserialize(item_stack:get_metadata())
				if metadata then
					if metadata['weight'] then
						value = value + metadata['weight']
					end
				end
			end
		end
	end
	return value
end

saturn.get_item_volume = function(list_name, item_stack)
	local item_name = item_stack:get_name()
	local value = 1
	if list_name == "ship_hull" or list_name == "hangar" then
		value = 0
	else
		local stats = saturn.item_stats[item_name]
		if stats ~= nil then
			if stats['volume'] then
				value = stats['volume']
				local metadata = minetest.deserialize(item_stack:get_metadata())
				if metadata then
					if metadata['volume'] then
						value = value + metadata['volume']
					end
				end
			end
		end
	end
	return value
end

saturn.get_item_stat = function(item_stack, stat_name, default_value)
	local item_name = item_stack:get_name()
	local value = default_value
	local stats = saturn.item_stats[item_name]
	if stats ~= nil then
		if stats[stat_name] then
			value = stats[stat_name]
			local metadata = minetest.deserialize(item_stack:get_metadata())
			if metadata then
				if metadata[stat_name] then
					value = value + metadata[stat_name]
				end
			end
		end
	end
	return value
end

saturn.refresh_health_hud = function(player)
		local inv = player:get_inventory()
		local ship_hull_stack = inv:get_stack("ship_hull", 1)
		if not ship_hull_stack:is_empty() then
			local wear = ship_hull_stack:get_wear()
			local display_status = (saturn.MAX_ITEM_WEAR - wear) * 316 / saturn.MAX_ITEM_WEAR
			local display_color = 29-math.ceil((saturn.MAX_ITEM_WEAR - wear) * 29 / saturn.MAX_ITEM_WEAR)
			local picture = "saturn_hud_bar.png^[verticalframe:32:"..display_color
			player:hud_change(saturn.hud_healthbar_id, "number", display_status)
			player:hud_change(saturn.hud_healthbar_id, "text", picture)
		end
end

saturn.refresh_energy_hud = function(player)
		local ship_obj = player:get_attach()
		if ship_obj then
			local ship_lua = ship_obj:get_luaentity()
			if ship_lua and ship_lua['free_power'] > 0 then
				local display_status = (ship_lua['free_power'] - ship_lua['recharging_equipment_power_consumption']) * 316 / ship_lua['free_power']
				player:hud_change(saturn.hud_energybar_id, "number", display_status)
			end
		end
end

saturn.create_hit_effect = function(time, vel_range, object_pos)
	for i=1,16 do
		minetest.add_particlespawner({
			amount = i,
			time = i*time/16,
			minpos = object_pos,
			maxpos = object_pos,
			minvel = {x=-vel_range, y=-vel_range, z=-vel_range},
			maxvel = {x=vel_range, y=vel_range, z=vel_range},
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = i*time/16,
			maxexptime = i*time/16,
			minsize = 6,
			maxsize = 6,
			collisiondetection = false,
			vertical = false,
			texture = "saturn_flame_particle.png^[verticalframe:16:"..i,
		})
	end
end

saturn.create_gauss_hit_effect = function(time, _vel_range, object_pos)
	minetest.add_particle({
		pos = object_pos,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.1,
		size = 1,
		collisiondetection = false,
		vertical = false,
		texture = "saturn_gauss_shot_particle.png"
	})
	local vel_range = 1
	minetest.add_particlespawner({
		amount = math.random(5)+1,
		time = 0.3,
		minpos = object_pos,
		maxpos = object_pos,
		minvel = {x=-vel_range, y=-vel_range, z=-vel_range},
		maxvel = {x=vel_range, y=vel_range, z=vel_range},
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 0.01,
		maxexptime = 0.05,
		minsize = 0.1,
		maxsize = 0.5,
		collisiondetection = false,
		vertical = false,
		texture = "saturn_incandescent_gradient.png^[verticalframe:16:"..math.random(4),
	})
end

saturn.create_shooting_effect = function(shooter_pos, direction_to_target, shooter_size)
	local x_pos = shooter_pos.x+direction_to_target.x*shooter_size
	local y_pos = shooter_pos.y+direction_to_target.y*shooter_size
	local z_pos = shooter_pos.z+direction_to_target.z*shooter_size
	minetest.add_particle({
		pos = {x=x_pos, y=y_pos, z=z_pos},
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.1,
		size = 6,
		collisiondetection = false,
		vertical = false,
		texture = "saturn_cdbcemw_shoot_particle.png"
	})
end

saturn.create_explosion_effect = function(explosion_pos)
	local x_pos = explosion_pos.x
	local y_pos = explosion_pos.y
	local z_pos = explosion_pos.z
	minetest.add_particle({
		pos = {x=x_pos, y=y_pos, z=z_pos},
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.1,
		size = 100,
		collisiondetection = false,
		vertical = false,
		texture = "saturn_white_halo.png"
	})
	local v_1 = vector.new(1,1,1)
	local time = 1.0
	for i=1,16 do
		minetest.add_particlespawner({
			amount = i,
			time = i*time/16,
			minpos = vector.subtract(explosion_pos, v_1),
			maxpos = vector.add(explosion_pos, v_1),
			minvel = {x=-1, y=-1, z=-1},
			maxvel = {x=1, y=1, z=1},
			minacc = {x=-1, y=-1, z=-1},
			maxacc = {x=1, y=1, z=1},
			minexptime = i*time/16,
			maxexptime = i*time/16,
			minsize = 6,
			maxsize = 6,
			collisiondetection = false,
			vertical = false,
			texture = "saturn_flame_particle.png^[verticalframe:16:"..i,
		})
	end
end

saturn.create_node_explosion_effect = function(explosion_pos, node_name)
	local node_def = minetest.registered_nodes[node_name]
	local v_1 = vector.new(1,1,1)
	local time = 0.2
	minetest.add_particlespawner({
		amount = 32,
		time = time,
		minpos = vector.subtract(explosion_pos, v_1),
		maxpos = vector.add(explosion_pos, v_1),
		minvel = {x=-10, y=-10, z=-10},
		maxvel = {x=10, y=10, z=10},
		minacc = {x=-1, y=-1, z=-1},
		maxacc = {x=1, y=1, z=1},
		minexptime = 0.1,
		maxexptime = time,
		minsize = 0.1,
		maxsize = 1.0,
		collisiondetection = true,
		vertical = false,
		texture = node_def.tiles[1],
	})
end

saturn.punch_object = function(punched, puncher, damage)
	if punched:is_player() and damage then
		local inv = punched:get_inventory()
		local ship_hull_stack = inv:get_stack("ship_hull", 1)
		local hull_stats = saturn.get_item_stats(ship_hull_stack:get_name())
		if hull_stats then
			ship_hull_stack:add_wear(damage * saturn.MAX_ITEM_WEAR / hull_stats['max_wear'])
			if ship_hull_stack:is_empty() then
				for list_name,list in pairs(inv:get_lists()) do
					for listpos,stack in pairs(list) do
						if stack ~= nil and not stack:is_empty() then
							inv:remove_item(list_name, stack)
							if list_name ~= "ship_hull" then
								saturn.throw_item(stack, punched:get_attach(), punched:getpos())
							end
						end
					end
				end
				saturn.create_explosion_effect(punched:getpos())
				inv:set_stack("ship_hull", 1, saturn:get_escape_pod())
			else
				inv:set_stack("ship_hull", 1, ship_hull_stack)
			end
			saturn.refresh_health_hud(punched)
			local name = punched:get_player_name()
			local ship_lua = punched:get_attach():get_luaentity()
			punched:set_inventory_formspec(saturn.get_player_inventory_formspec(punched,ship_lua['current_gui_tab']))
			ship_lua.hit_effect_timer = 5.0
			ship_lua.last_attacker = puncher

		end
	else
		punched:punch(puncher, 1.0, {
		full_punch_interval=1.0,
		damage_groups={fleshy=damage,enemy=damage},
		}, nil)
	end
end

local on_throwed_step = function(self, dtime) -- Taken from PilzAdam Throwing mod from https://github.com/PilzAdam/throwing/
    self.age=self.age+dtime
    local pos = self.object:getpos()
    local node = minetest.env:get_node(pos)
    local self_velocity = self.object:getvelocity()
    if self.age>0.2 then
		local objs = minetest.env:get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, math.min(2,self.age))
		for k, obj in pairs(objs) do
			local collided = obj:get_luaentity()
			if collided then
				if collided.name ~= self.name and collided.name ~= "__builtin:item" then
					local damage = vector.length(vector.subtract(obj:getvelocity(), self_velocity))
					if collided.name == "saturn:spaceship" and collided.driver and damage > 1.0 then 
						saturn.punch_object(collided.driver, self.object, damage)
					else
						saturn.punch_object(obj, self.object, damage)
					end
					if damage < 10 then
						self.object:setvelocity(vector.add(obj:getvelocity(),vector.multiply(self_velocity, -0.5)))
					else
						self.itemstring = ''
						self.object:remove()
					end
				end
			end
		end
    end
    local lastpos=self.lastpos
    if lastpos.x~=nil then
	if node.name ~= "air" and node.name ~= "saturn:fog" and node.name ~= "ignore" then
		self.object:setpos(self.lastpos)
		self.object:setvelocity(vector.multiply(self_velocity,-0.1))
	end
    end
    self.lastpos={x=pos.x, y=pos.y, z=pos.z}
end

local throwable_item_entity={
	initial_properties = {
		is_visible = false,
		physical = false,
		collisionbox = {0,0,0,0,0,0},
		visual = "sprite",
		visual_size = {x = 0.4, y = 0.4},
		textures = {""},
		infotext = "",
	},

	age = 0,
	lastpos={},
	itemstring = '',

	on_step = function(self, dtime)
		on_throwed_step(self, dtime)
	end,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		local count = stack:get_count()
		local max_count = stack:get_stack_max()
		if count > max_count then
			count = max_count
			self.itemstring = stack:get_name().." "..max_count
		end
		local s = 0.8 + 0.1 * (count / max_count)
		local c = s
		local itemtable = stack:to_table()
		local itemname = nil
		local description = ""
		if itemtable then
			itemname = stack:to_table().name
		end
		local item_texture = nil
		local item_type = ""
		local itemdef = core.registered_items[itemname]
		if itemdef then
			item_texture = itemdef.inventory_image
			item_type = itemdef.type
			description = itemdef.description
		end
		local prop = {
			is_visible = true,
			visual = "sprite",
			textures = {item_texture},
			visual_size = {x = s, y = s},
			automatic_rotate = math.pi * 0.5,
			infotext = description,
		}
		if item_type == "node" then
			prop.visual = "cube"
			prop.textures = itemdef.tiles
		end
		self.object:set_properties(prop)
	end,

	get_staticdata = function(self)
		return core.serialize({
			itemstring = self.itemstring,
			always_collect = self.always_collect,
			age = self.age,
			velocity = self.object:getvelocity()
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		if string.sub(staticdata, 1, string.len("return")) == "return" then
			local data = core.deserialize(staticdata)
			if data and type(data) == "table" then
				self.itemstring = data.itemstring
				self.always_collect = data.always_collect
				if data.age then
					self.age = data.age + dtime_s
				else
					self.age = dtime_s
				end
				self.object:setvelocity(data.velocity)
			end
		else
			self.itemstring = staticdata
		end
		self.object:set_armor_groups({immortal = 1})
		self:set_item(self.itemstring)
	end,

	on_punch = function(self, hitter)
		self.itemstring = ''
		self.object:remove()
	end,
}

minetest.register_entity("saturn:throwable_item_entity", throwable_item_entity)

saturn.get_color_formspec_frame = function(x,y,w,h,color,thickness)
	local gap = 0.2
	return "box["..(x-thickness+gap)..","..(y-thickness)..";"..(w+thickness-0.2-gap*2)..","..(thickness)..";"..color.."]"..
"box["..(x+w-0.2)..","..(y-thickness+gap)..";"..(thickness)..","..(h+thickness-0.2-gap*2)..";"..color.."]"..
"box["..(x+gap)..","..(y+h-0.2)..";"..(w+thickness-0.2-gap*2)..","..(thickness)..";"..color.."]"..
"box["..(x-thickness)..","..(y+gap)..";"..(thickness)..","..(h+thickness-0.2-gap*2)..";"..color.."]"
end

local get_formspec_label_with_bg_color = function(x,y,w,h,color,text)
	return "box["..x..","..y..";"..w..","..h..";"..color.."]".."label["..x..","..(y-0.2)..";"..text.."]"
end


saturn.get_ship_equipment_formspec = function(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
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
	if inv:get_size("scaner") > 0 then
		formspec = formspec.."box[5,0;0.8,3.9;#00FFF0]"..get_formspec_label_with_bg_color(0,2.6,0.8,0.2,"#00FFF0","Scaner")..
		"list[current_player;scaner;5,0;1,4;]"
		for iy = 0, inv:get_size("scaner")-1 do
			formspec = formspec.."image_button[5.81,"..iy..";0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+scaner+"..(iy+1)..";]"
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

saturn.get_player_inventory_formspec = function(player, tab)
	local name = player:get_player_name()
	local default_formspec = "size[8,8.6]"..
			"tabheader[0,0;tabs;Status,Hull;"..tab..";true;false]"..
			saturn.get_main_inventory_formspec(player,4.25)
	local hull = player:get_inventory():get_stack("ship_hull", 1)
	local hull_stats = saturn.get_item_stats(hull:get_name())
	if hull_stats then
		if tab == 1 then
			local hull_max_wear = hull_stats['max_wear']
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
			return default_formspec..
				"label[0,0;"..minetest.formspec_escape("Hull damage: ")..string.format ('%4.0f',display_status).."/"..hull_max_wear.."]"..
				"label[0,0.25;"..minetest.formspec_escape("Money: ")..string.format ('%4.0f',saturn.players_info[name]['money']).." Cr.]"..
				"label[0,0.5;"..minetest.formspec_escape("Occupied hold volume: ")..string.format ('%4.2f',ship_lua['volume']).."/"..max_volume.." m3]"..
				"label[0,0.75;"..minetest.formspec_escape("Total ship weight: ")..string.format ('%4.0f',ship_lua['weight']).." kg]"..
				"label[0,1.0;"..minetest.formspec_escape("Traction: ")..string.format ('%4.1f',traction/1000).." kN]"..
				"label[0,1.25;"..minetest.formspec_escape("Max acceleration: ")..string.format ('%4.1f',traction/ship_lua['weight']).." m/s2]"..
				"label[0,1.5;"..minetest.formspec_escape("Free power: ")..string.format ('%4.0f',ship_lua['free_power']).." MW]"..
				"button[0,2;4,1;abandon_ship;Abandon ship]"
		elseif tab == 2 then
			return default_formspec..saturn.get_ship_equipment_formspec(player)
		end
	end
	return default_formspec
end

saturn.get_item_info_formspec = function(item_stack)
	local item_name = item_stack:get_name()
	local formspec = "size[8,8.6]"..
		"item_image[0,0;1,1;"..item_name.."]"..
		"label[1,0.0;"..item_name.."]"..
		"image_button[6.5,0.1;1.5,0.4;saturn_back_button_icon.png;ii_return;Back  ;false;false;saturn_back_button_icon.png]"
	local row_step = 0.3
	local row = 1-row_step
	formspec = formspec.."label[0,"..row..";Basic properties:]"
	for key,value in pairs(saturn.item_stats[item_name]) do
		row = row + row_step
		local string_value
		if type(value) == "number" then
			string_value = string.format('%4.2f',value)
		else
			string_value = tostring(value)
		end
		formspec = formspec.."label[0,"..row..";"..key.."="..string_value.."]"
	end
	local metadata = minetest.deserialize(item_stack:get_metadata())
	if metadata then
		row = row + row_step*2
		formspec = formspec.."label[0,"..row..";Special properties:]"
		for key,value in pairs(metadata) do
			row = row + row_step
			local string_value
			if type(value) == "number" then
				string_value = string.format('%+4.2f',value)
			else
				string_value = tostring(value)
			end
			formspec = formspec.."label[0,"..row..";"..key.."="..string_value.."]"
		end
	end
	return formspec
end

saturn.save_players = function()
    local file = io.open(minetest.get_worldpath().."/saturn_players", "w")
    file:write(minetest.serialize(saturn.players_info))
    file:close()
end

saturn.load_players = function()
    local file = io.open(minetest.get_worldpath().."/saturn_players", "r")
    if file ~= nil then
	local text = file:read("*a")
        file:close()
	if text and text ~= "" then
	    saturn.players_info = minetest.deserialize(text)
	end
    end
end

saturn.throw_item = function(stack, ship, pos)
	local velocity = vector.new(math.random()-0.5,math.random()-0.5,math.random()-0.5)
	if ship then
		local ship_velocity = ship:getvelocity()
		if ship_velocity then
			local ship_velocity_module = vector.length(ship_velocity)
			if ship_velocity_module ~= 0 then
				velocity = vector.add(vector.add(ship_velocity, vector.normalize(ship_velocity)),velocity)
			end
		end
	end
	local start_pos = {x=pos.x+velocity.x, y=pos.y+velocity.y, z=pos.z+velocity.z}
	local obj = minetest.env:add_entity(start_pos, "saturn:throwable_item_entity")
	obj:setvelocity(velocity)
	obj:get_luaentity():set_item(stack:to_string())
end

saturn.set_item_stats = function(item_name, stats)
	saturn.item_stats[item_name] = stats
end

saturn.get_item_stats = function(item_name)
	return saturn.item_stats[item_name]
end

saturn.get_item_price = function(item_name)
	local stats = saturn.item_stats[item_name]
	if stats ~= nil then
		local value = stats['price']
		if value ~= nil then
			return value
		end
	end
	return 0
end

saturn.generate_random_enemy_item = function()
	local item_name = saturn.enemy_items[math.random(#saturn.enemy_items)]
	local item_stack = ItemStack(item_name)
	local item_stats = saturn.item_stats[item_name]
	local possible_modifications = item_stats.possible_modifications
	if possible_modifications then 
		local modifications = {}
		for key,value in pairs(possible_modifications) do
			local median = (value[1] + value[2])/2
			local scale = value[2] - median
			local modification_power = saturn.get_pseudogaussian_random(median, scale)
			if math.abs(modification_power) > scale then
				if modification_power < 0 and item_stats[key] then
					modifications[key] = math.max(scale*0.1 - item_stats[key], modification_power)
				else
					modifications[key] = modification_power
				end
				
			end
		end
		item_stack:set_metadata(minetest.serialize(modifications))
	end
	return item_stack
end

minetest.register_globalstep(function(dtime)
    saturn.save_timer = saturn.save_timer - 1
    if saturn.save_timer <= 0 then
	saturn.save_timer = saturn.players_save_interval
	saturn:save_players()
    end
    saturn.market_update_timer = saturn.market_update_timer - 1
    if saturn.market_update_timer <= 0 then
	saturn.market_update_timer = saturn.market_update_interval
	saturn:update_space_station_market()
    end
    for _,player in ipairs(minetest.get_connected_players()) do
	local player_inv = player:get_inventory()
	local name = player:get_player_name()
	local ship_obj = player:get_attach()
	local ship_cooldown_mod = 0
	if ship_obj and ship_obj:get_luaentity() then
		ship_cooldown_mod = ship_obj:get_luaentity().total_modificators['cooldown'] or 0
	end
	for i=1,8 do
	   local cooldown = saturn.hotbar_cooldown[name][i]
	   if cooldown > 0 then
		local stack = player_inv:get_stack("main", i)
		local number = 0
		if stack:is_empty() then
			cooldown = 0
		else
			cooldown = cooldown - dtime
			number = 44 * cooldown / math.max(0.2,saturn.get_item_stat(stack, 'cooldown', 88) + ship_cooldown_mod)
		end
		player:hud_change(saturn.hud_hotbar_cooldown[name][i], "number", number)
		saturn.hotbar_cooldown[name][i] = cooldown
	   end
	end
    end
end)

minetest.register_on_shutdown(function()
	saturn:save_players()
end)
