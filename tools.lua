-- MyWeather Mod: Tools & Handhelds

-- 1. SNOW SHOVEL
-- Clears nodes in the "myweather_clearable" group (snow cover AND puddles) in a small radius
minetest.register_tool("myweather:shovel", {
	description = "Snow & Puddle Shovel",
	inventory_image = "myweather_shovel.png",
	wield_image = "myweather_shovel.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then return end
		local pos = pointed_thing.above
		local radius = 1
		local cleared = false

		for x = -radius, radius do
			for z = -radius, radius do
				local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
				for y_off = 0, -1, -1 do
					local p = {x=check_pos.x, y=check_pos.y+y_off, z=check_pos.z}
					local node = minetest.get_node(p)
					if minetest.get_item_group(node.name, "myweather_clearable") > 0 then
						minetest.remove_node(p)
						cleared = true
					end
				end
			end
		end

		if cleared then
			minetest.sound_play("default_dig_crumbly", {pos = pos, gain = 0.5})
			itemstack:add_wear(65535 / 100)
		end
		return itemstack
	end,
})

-- 2. DIGITAL THERMOMETER
-- Checks local temperature and humidity, accounting for nearby heat sources
minetest.register_tool("myweather:thermometer", {
	description = "Digital Thermometer",
	inventory_image = "myweather_thermometer.png",
	on_use = function(itemstack, user, pointed_thing)
		local pos = user:get_pos()
		local data = minetest.get_biome_data(pos)
		
		if data then
			local current_temp = 20 -- Fallback
			if myweather and myweather.get_temp then
				current_temp = myweather.get_temp(pos)
			else
				current_temp = math.floor((data.heat * 0.6) - 20)
			end

			local humid = math.floor(data.humidity)
			
			local node_near = minetest.find_node_near(pos, 3, {"group:igniter", "group:torch", "default:furnace_active", "group:fire", "group:lava"})
			if node_near then current_temp = current_temp + 15 end

			minetest.chat_send_player(user:get_player_name(), 
				"Temp: " .. current_temp .. "°C | Humidity: " .. humid .. "%")
		else
			minetest.chat_send_player(user:get_player_name(), "Error: No signal.")
		end
	end,
})

-- 3. THE WEATHER RADIO
-- Broadcasts global system conditions and wind speed
minetest.register_craftitem("myweather:weather_radio", {
	description = "Weather Radio\nDisplays current conditions when held.",
	inventory_image = "myweather_radio.png",
	stack_max = 1,
	groups = {tool = 1},
	
	on_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()
		local pos = user:get_pos()
		local heat = 25
		if myweather and myweather.get_temp then
			heat = myweather.get_temp(pos)
		end
		local knots = math.floor(math.sqrt(myweather.wind_dir.x^2 + myweather.wind_dir.z^2) * 100)
		
		minetest.chat_send_player(name, minetest.colorize("#00ffff", ">>> Radio Check: " .. myweather.current_system:upper() .. " | " .. heat .. "C | " .. knots .. " knots <<<"))
		
		minetest.sound_play("default_place_node_metal", {pos = pos, gain = 0.5}, true)
		return itemstack
	end,
})

-- 4. CRAFTING RECIPES

-- Shovel Recipe
minetest.register_craft({
	output = "myweather:shovel",
	recipe = {
		{"", "", "default:steel_ingot"},
		{"", "group:stick", ""},
		{"group:stick", "", ""},
	}
})

-- Thermometer Recipe
minetest.register_craft({
	output = "myweather:thermometer",
	recipe = {
		{"", "default:glass", ""},
		{"", "default:steel_ingot", ""},
		{"", "default:glass", ""},
	}
})

-- Weather Radio Recipe
minetest.register_craft({
	output = "myweather:weather_radio",
	recipe = {
		{"", "default:copper_ingot", ""},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
	}
})

-- 5. PUDDLE FORMATION ABM
-- Updated to check for a roof to prevent indoor puddles
minetest.register_abm({
	label = "Puddle Formation",
	nodenames = {"default:dirt_with_grass", "default:dirt", "default:stone", "default:cobble"},
	interval = 15,
	chance = 30,
	action = function(pos, node)
		local current_w = myweather.current_system
		if current_w == "rain" or current_w == "storm" then
			local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
			
			-- Only form if there is air above
			if minetest.get_node(pos_above).name == "air" then
				-- Check for light level (indoors is usually lower)
				-- and perform a raycast/line-of-sight check to the sky
				local sky_check = minetest.line_of_sight(
					{x=pos.x, y=pos.y+1.5, z=pos.z}, 
					{x=pos.x, y=pos.y+20, z=pos.z}
				)
				
				if sky_check and minetest.get_node_light(pos_above) > 10 then
					minetest.set_node(pos_above, {name = "myweather:puddle"})
				end
			end
		end
	end,
})

-- 6. PUDDLE EVAPORATION ABM
minetest.register_abm({
	label = "Puddle Evaporation",
	nodenames = {"myweather:puddle"},
	interval = 20,
	chance = 10,
	action = function(pos, node)
		if myweather.current_system == "clear" then
			minetest.remove_node(pos)
		end
	end,
})
