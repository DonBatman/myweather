core.register_tool("myweather:shovel", {
	description = "Snow Shovel",
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
					local node = core.get_node(p)
					if core.get_item_group(node.name, "myweather_clearable") > 0 then
						core.remove_node(p)
						cleared = true
					end
				end
			end
		end

		if cleared then
			core.sound_play("default_dig_crumbly", {pos = pos, gain = 0.5})
			itemstack:add_wear(65535 / 100)
		end
		return itemstack
	end,
})

core.register_tool("myweather:thermometer", {
    description = "Digital Thermometer",
    inventory_image = "myweather_thermometer.png",
    on_use = function(itemstack, user, pointed_thing)
        local pos = user:get_pos()
        local data = core.get_biome_data(pos)
        
        if data then
        	if myweather and myweather.get_temp then
                current_temp = myweather.get_temp(pos)
            end

            local current_temp = math.floor((data.heat * 0.6) - 20)
            local humid = math.floor(data.humidity)
            
            local node_near = core.find_node_near(pos, 3, {"group:igniter", "group:torch", "default:furnace_active", "group:fire", "group:lava"})
            if node_near then current_temp = current_temp + 15 end

            core.chat_send_player(user:get_player_name(), 
                "Temp: " .. current_temp .. "°C | Humidity: " .. humid .. "%")
        else
            core.chat_send_player(user:get_player_name(), "Error: No signal.")
        end
    end,
})

core.register_craft({
	output = "myweather:shovel",
	recipe = {
		{"", "", "default:steel_ingot"},
		{"", "group:stick", ""},
		{"group:stick", "", ""},
	}
})

core.register_craft({
	output = "myweather:thermometer",
	recipe = {
		{"", "default:glass", ""},
		{"", "default:steel_ingot", ""},
		{"", "default:glass", ""},
	}
})
