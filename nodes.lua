core.register_node("myweather:puddle", {
	description = "Puddle",
	tiles = {"myweather_puddle.png"},
	drawtype = "nodebox",
	paramtype = "light",
	pointable = false,
	buildable_to = true,
	alpha = 50,
	node_box = {type = "fixed", fixed = {{-0.3, -0.5, -0.3, 0.3, -0.48, 0.3}}},
	groups = {not_in_creative_inventory = 1, crumbly = 3, myweather_clearable = 1, melt_speed = 1},
	drop = "",
})

local snow_levels = {
	{1, -0.4}, {2, -0.2}, {3, 0.0}, {4, 0.2}, {5, 0.5}
}
for _, s in ipairs(snow_levels) do
	core.register_node("myweather:snow_cover_" .. s[1], {
		description = "Snow Layer",
		tiles = {"myweather_snow_cover.png"},
		drawtype = "nodebox",
		paramtype = "light",
		buildable_to = true,
		walkable = false,
		node_box = { type = "fixed", fixed = {{-0.5, -0.5, -0.5, 0.5, s[2], 0.5}} },
		groups = {not_in_creative_inventory = 1, crumbly = 3, snowy = 1, myweather_clearable = 1, melt_speed = 1},
		drop = "default:snow " .. s[1],
	})
end

local barrel_levels = {
	{0, "Empty"}, {1, "Very Low"}, {2, "Low"}, {3, "Half Full"}, {4, "Full"},
}

for _, b in ipairs(barrel_levels) do
	local level = b[1]
	
	local top_tex = "myweather_barrel_top.png"
	if level > 0 then
		top_tex = "myweather_barrel_top.png^myweather_water_" .. level .. ".png"
	end
	
	core.register_node("myweather:barrel_" .. level, {
		description = "Rain Barrel (" .. b[2] .. ")",
		tiles = {
			top_tex,
			"myweather_barrel_bottom.png",
			"myweather_barrel_side.png",
			"myweather_barrel_side.png",
			"myweather_barrel_side.png",
			"myweather_barrel_side.png"
		},
		drawtype = "nodebox",
		paramtype = "light",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.43, -0.5, -0.43, 0.43, 0.4, 0.43},
			},
		},
		groups = {choppy = 2, oddly_breakable_by_hand = 2, barrel = 1, not_in_creative_inventory = (level == 0 and 0 or 1)},
		drop = "myweather:barrel_0",

		can_dig = function(pos, player)
			if level > 0 then
				core.chat_send_player(player:get_player_name(), "The barrel is too heavy to move while it has water!")
				return false
			end
			return true
		end,

		on_rightclick = function(pos, node, clicker, itemstack)
			local item_name = itemstack:get_name()
			local sponge_water = {
    			["mysponge:sponge_moist"] = 1,
    			["mysponge:sponge_wet"] = 2,
    			["mysponge:sponge_soaked"] = 4,
			}
			
			if level < 4 and sponge_water[item_name] then
    			core.sound_play("default_water_footstep", {pos = pos, gain = 0.5})
    			local added = sponge_water[item_name]
    			local new_level = math.min(4, level + added)
    			
    			core.set_node(pos, {name = "myweather:barrel_" .. new_level})
    			
    			return ItemStack("mysponge:sponge_dry")
			end
			if level > 0 and item_name == "mysponge:sponge_dry" then
				core.sound_play("default_water_footstep", {pos = pos, gain = 0.8})
				
				local new_sponge = "mysponge:sponge_soaked"
				if level == 1 then
					new_sponge = "mysponge:sponge_moist"
				elseif level == 2 then
					new_sponge = "mysponge:sponge_wet"
				end
				
				core.set_node(pos, {name = "myweather:barrel_0"})
				
				itemstack:take_item()
				local inv = clicker:get_inventory()
				if inv:room_for_item("main", new_sponge) then
					inv:add_item("main", new_sponge)
				else
					core.add_item(pos, new_sponge)
				end
				return itemstack
			end

			if level > 0 and item_name == "bucket:bucket_empty" then
				core.sound_play("default_water_footstep", {pos = pos, gain = 0.5})
				core.set_node(pos, {name = "myweather:barrel_" .. (level - 1)})
				
				local inv = clicker:get_inventory()
				local water_bucket = ItemStack("bucket:bucket_water")
				
				if itemstack:get_count() > 1 then
					itemstack:take_item()
					if inv:room_for_item("main", water_bucket) then
						inv:add_item("main", water_bucket)
					else
						core.add_item(pos, water_bucket)
					end
					return itemstack
				else
					return water_bucket
				end
			end
		end,
	})
end

core.register_node("myweather:station", {
	description = "Weather Station",
	tiles = {
		"myweather_station_top.png", "myweather_station_side.png", 
		"myweather_station_side.png", "myweather_station_side.png", 
		"myweather_station_side.png", "myweather_station_clear.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {type = "fixed", fixed = {-0.3, -0.5, -0.2, 0.3, 0.1, 0.2}},
	groups = {choppy = 2, oddly_breakable_by_hand = 2, watch_weather = 1},
	
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("infotext", "Weather Station: Calibrating...")
	end,
})

core.register_node("myweather:wind_vane", {
	description = "Wind Vane",
	tiles = {
		"myweather_vane_top.png", "myweather_vane_side.png", 
		"myweather_vane_side.png", "myweather_vane_side.png", 
		"myweather_vane_side.png", "myweather_vane_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.0625, -0.5, -0.0625, 0.0625, 0.25, 0.0625},
			{-0.0625, 0.25, -0.375, 0.0625, 0.375, 0.25},
			{-0.125, 0.25, 0.25, 0.125, 0.375, 0.4375},
		},
	},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
})

core.register_craft({
	output = "myweather:barrel_0",
	recipe = {
		{"group:wood", "", "group:wood"},
		{"group:wood", "", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

core.register_craft({
	output = "myweather:station",
	recipe = {
		{"default:glass", "default:glass", "default:glass"},
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

core.register_craft({
	output = "myweather:wind_vane",
	recipe = {
		{"", "", "default:steel_ingot"},
		{"", "default:steel_ingot", ""},
		{"group:stick", "", ""},
	}
})
