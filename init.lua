myweather = {}
myweather.current_system = "clear"
myweather.wind_dir = {x = 0.2, z = 0.2}
myweather.sounds = {}
myweather.weather_timer = 0
myweather.wind_timer = 0
local storage = core.get_mod_storage()

myweather.current_system = storage:get_string("current_system")
if myweather.current_system == "" then
	myweather.current_system = "clear"
end

myweather.weather_timer = tonumber(storage:get_string("weather_timer")) or 0
myweather.wind_timer = tonumber(storage:get_string("wind_timer")) or 0

local settings = core.settings
local part_mult = settings:get("myweather_particle_multiplier") or 1.0
local wind_push = settings:get("myweather_wind_push_strength") or 1.0
local use_sound = settings:get_bool("myweather_enable_sound") ~= false

myweather.config = {
	part_mult = tonumber(part_mult) or 1.0,
	wind_push = tonumber(wind_push) or 1.0,
	use_sound = use_sound,
}
----------------------------------------------------------------------
function myweather.update_wind(knots)
    local k = tonumber(knots) or math.random(20, 40)
    local strength = k * 0.01
    myweather.wind_dir = {
        x = (math.random() * 2 - 1) * strength, 
        z = (math.random() * 2 - 1) * strength
    }
    --core.chat_send_all("The wind is now blowing at " .. k .. " knots.")
end
------------------------------------------------------------------------
function myweather.save_state()
	storage:set_string("current_system", myweather.current_system)
	storage:set_string("weather_timer", tostring(myweather.weather_timer))
	storage:set_string("wind_timer", tostring(myweather.wind_timer))
end
-------------------------------------------------------------------------
function myweather.get_temp(pos)
    local data = core.get_biome_data(pos)
    if not data then return 25 end
    local base_temp = (data.heat * 0.6) - 20
    
    if pos.y < 0 then
        return math.max(18, math.floor(base_temp))
    end
    return math.floor(base_temp)
end
--------------------------------------------------------
local function get_local_weather(pos)
    if pos.y < -10 then return "clear" end
    
	local data = core.get_biome_data(pos)
	if not data then return "clear" end
    
	local temp = myweather.get_temp(pos)
	local humid = data.humidity
	local sys = myweather.current_system
    
	if sys == "clear" then return "clear" end
	if sys == "clouds" then return "clouds" end
    
	if temp < 0 then 
        return (sys == "storm") and "snowstorm" or "snow"
	elseif temp > 35 and humid < 30 then 
        return (sys == "storm") and "sandstorm" or "clear"
	elseif sys == "storm" and humid > 70 then 
        return "hail" 
    end
	return sys
end
-------------------------------------------------------------
local effect_t = 0
core.register_globalstep(function(dtime)
	effect_t = effect_t + dtime
	if effect_t < 0.1 then return end
	effect_t = 0

	for _, player in ipairs(core.get_connected_players()) do
		local ppos = player:get_pos()
		local name = player:get_player_name()
		local ray = core.line_of_sight({x=ppos.x, y=ppos.y+1.5, z=ppos.z}, {x=ppos.x, y=ppos.y+20, z=ppos.z})
		local local_w = get_local_weather(ppos)
		local is_sheltered = (ray == false)

		local current_physics = player:get_physics_override()
		local target_speed = 1.0
		local target_jump = 1.0
		local pos_feet = {x=ppos.x, y=ppos.y + 0.1, z=ppos.z}
		local node_at_feet = core.get_node(pos_feet).name
		
		if node_at_feet == "myweather:snow_cover_1" then target_speed = 0.95
		elseif node_at_feet == "myweather:snow_cover_2" then target_speed = 0.80
		elseif node_at_feet == "myweather:snow_cover_3" then target_speed = 0.65
		elseif node_at_feet == "myweather:snow_cover_4" then target_speed = 0.50; target_jump = 1.1
		elseif node_at_feet == "myweather:snow_cover_5" then target_speed = 0.35; target_jump = 1.2
		end
		
		if math.abs(current_physics.speed - target_speed) > 0.01 then
			player:set_physics_override({speed = target_speed, jump = target_jump, gravity = 1.0})
		end

		if myweather.config.use_sound then
			if local_w == "rain" or local_w == "storm" then
				if not myweather.sounds[name] then
					myweather.sounds[name] = core.sound_play("myweather_rain", {to_player = name, gain = is_sheltered and 0.2 or 0.6, loop = true})
				else
					core.sound_fade(myweather.sounds[name], 0.5, is_sheltered and 0.2 or 0.6)
				end
			elseif myweather.sounds[name] then
				core.sound_stop(myweather.sounds[name])
				myweather.sounds[name] = nil
			end
		end

		if local_w ~= "clear" then
            local is_storm = (local_w == "storm" or local_w == "snowstorm" or local_w == "sandstorm")
            local is_snow = (local_w == "snow" or local_w == "snowstorm")
            local is_sand = (local_w == "sandstorm")

    		if not is_sheltered then
        		local push = (is_storm and 0.45 or 0.1) * myweather.config.wind_push
        		player:add_velocity({
            		x = myweather.wind_dir.x * push, 
            		y = 0, 
            		z = myweather.wind_dir.z * push
        		})
    		end

			local amount = 100
			if local_w == "clouds" then amount = 0
			elseif local_w == "rain" then amount = 400
			elseif local_w == "storm" then amount = 1200
			elseif local_w == "snow" then amount = 200
			elseif local_w == "snowstorm" then amount = 800
			elseif local_w == "hail" then amount = 400
			elseif local_w == "sandstorm" then amount = 800 end

			amount = math.floor((is_sheltered and amount * 0.25 or amount) * myweather.config.part_mult)
			local texture = (local_w == "hail") and "myweather_hail.png" or (is_sand and "myweather_sand.png" or (is_snow and "myweather_snow.png" or "myweather_rain.png"))
			local vel_y = is_snow and (is_storm and -10 or -5) or -22
			
			core.add_particlespawner({
				amount = amount, time = 0.1,
				minpos = {x=ppos.x - 15, y=ppos.y + 6, z=ppos.z - 15},
				maxpos = {x=ppos.x + 15, y=ppos.y + 12, z=ppos.z + 15},
				minvel = {x=myweather.wind_dir.x*30, y=vel_y, z=myweather.wind_dir.z*30},
				maxvel = {x=myweather.wind_dir.x*40, y=vel_y-4, z=myweather.wind_dir.z*40},
				minexptime = is_snow and 3.0 or 0.8, maxexptime = is_snow and 4.0 or 1.2,
				minsize = 2, maxsize = is_storm and 6 or 4,
				texture = texture, playername = name,
				vertical = not (is_sand or local_w == "hail" or is_snow),
				collisiondetection = true, collision_removal = true,
			})

			local sky_color = (local_w == "clouds") and "#778899" or (is_storm and "#111111" or "#556677")
			player:set_sky({
				base_color = sky_color, type = "plain", clouds = false,
				fog = { distance = is_storm and 25 or 45, color = sky_color }
			})

			if is_storm and math.random(1, 100) == 1 then
				local strike_pos = {x = ppos.x + math.random(-50, 50), y = ppos.y + 20, z = ppos.z + math.random(-50, 50)}
				core.add_particle({
					pos = strike_pos, velocity = {x=0, y=-200, z=0}, expirationtime = 0.2,
					size = 30, texture = "myweather_lightning.png", glow = 14,
				})
				core.sound_play("myweather_thunder", {pos = strike_pos, gain = 1.0, max_hear_distance = 150})
				
				player:set_sky({base_color = "#ffffff", type = "plain"})
				core.after(0.1, function()
					if player:is_player() then
						player:set_sky({base_color = sky_color, type = "plain", clouds = false})
					end
				end)
			end
		else
			player:set_sky({base_color = "#8cbafa", type = "regular"})
		end
	end
end)

core.register_abm({
	label = "Weather Devices Update",
	nodenames = {"myweather:wind_vane", "group:watch_weather"},
	interval = 2,
	chance = 1,
	action = function(pos, node)
			if node.name == "myweather:wind_vane" then
    			local dir = 0
    			local wx = myweather.wind_dir.x
    			local wz = myweather.wind_dir.z
			
    			if math.abs(wx) > math.abs(wz) then
        			dir = (wx > 0) and 1 or 3
    			else
        			dir = (wz > 0) and 0 or 2
    			end
    			core.swap_node(pos, {name = node.name, param2 = dir})
			else
    			local meta = core.get_meta(pos)
    			
    			local heat = myweather.get_temp(pos)
                local data = core.get_biome_data(pos)
    			local humidity = data and math.floor(data.humidity) or 0
    			local speed_raw = math.sqrt(myweather.wind_dir.x^2 + myweather.wind_dir.z^2)
    			local knots = math.floor(speed_raw * 100)
			
    			local seconds_left = math.max(0, math.floor(300 - myweather.weather_timer))
    			local minutes = math.floor(seconds_left / 60)
    			
    			local forecast = "Stable"
    			if myweather.current_system == "clouds" then
        			forecast = "Imminent Precipitation"
    			elseif seconds_left < 60 then
        			forecast = "Pressure Dropping"
    			elseif seconds_left < 150 then
        			forecast = "Changing"
    			end
			
    			meta:set_string("infotext", 
        			"--- Weather Station ---\n" ..
        			"System: " .. myweather.current_system:upper() .. "\n" ..
        			"Temp: " .. heat .. "°C | Humid: " .. humidity .. "%\n" ..
        			"Wind: " .. knots .. " knots\n" ..
        			"Forecast: " .. forecast .. " (" .. minutes .. "m remaining)"
    			)
			end
	end,
})

core.register_abm({
	label = "Weather Accumulation",
	nodenames = {"group:solid", "default:dirt_with_grass", "default:dirt", "default:sand"},
	interval = 30,
	chance = 20,
	action = function(pos, node)
		local local_w = get_local_weather(pos)
		local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
		local node_above = core.get_node(pos_above).name

		if local_w:find("snow") then
			if node_above:find("myweather:snow_cover_") then
				local level = tonumber(node_above:sub(-1))
				if level and level < 5 then 
					core.set_node(pos_above, {name="myweather:snow_cover_"..(level+1)}) 
				end
			elseif node_above == "air" then
				if (core.get_node_light(pos_above) or 0) < 13 then
					core.set_node(pos_above, {name="myweather:snow_cover_1"})
				end
			end
		end
	end,
})

core.register_abm({
	label = "Snow Melting",
	nodenames = {"group:snowy"},
	interval = 20,
	chance = 10,
	action = function(pos, node)
		local local_w = get_local_weather(pos)
		if local_w == "clear" and (core.get_node_light(pos) or 0) > 12 then
			core.remove_node(pos)
		end
	end,
})

local modpath = core.get_modpath("myweather")
dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/tools.lua")
dofile(modpath .. "/commands.lua")

core.register_abm({
	label = "Rain Collection",
	nodenames = {"group:barrel"},
	interval = 45,
	chance = 5,
	action = function(pos, node)
		local local_w = get_local_weather(pos)
		if local_w == "rain" or local_w == "storm" then
			local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
			if core.get_node_light(pos_above, 0.5) > 12 then
				local level_str = node.name:match("myweather:barrel_(%d+)")
				local level = tonumber(level_str)
				if level and level < 4 then
					core.set_node(pos, {name = "myweather:barrel_" .. (level + 1)})
					core.sound_play("default_water_footstep", {pos = pos, gain = 0.2})
				end
			end
		end
	end,
})

core.register_globalstep(function(dtime)
    myweather.wind_timer = myweather.wind_timer + dtime
    if myweather.wind_timer > 300 then
        myweather.wind_timer = 0
        myweather.save_state()
        local knots = math.random(5, 45)
        local strength = knots * 0.01
        myweather.wind_dir = {
            x = (math.random() * 2 - 1) * strength,
            z = (math.random() * 2 - 1) * strength
        }
        core.log("action", "[MyWeather] Wind changed: " .. knots .. " knots")
    end
end)

core.register_globalstep(function(dtime)
    myweather.weather_timer = myweather.weather_timer + dtime
    if myweather.weather_timer > 300 then
    	myweather.save_state()
        myweather.weather_timer = 0
        local roll = math.random(1, 100)
        
        if myweather.current_system == "clear" then
            if roll <= 25 then
                myweather.current_system = "clouds"
                core.chat_send_all("The sky is turning grey...")
            end
        elseif myweather.current_system == "clouds" then
            if roll <= 50 then
                myweather.current_system = "rain"
            elseif roll <= 75 then
                myweather.current_system = "storm"
                core.chat_send_all("A heavy storm is rolling in!")
            else
                myweather.current_system = "clear"
            end
        elseif myweather.current_system == "rain" then
            if roll <= 20 then
                myweather.current_system = "storm"
            elseif roll <= 50 then
                myweather.current_system = "clear"
                core.chat_send_all("The sun is coming out.")
            end
        elseif myweather.current_system == "storm" then
            if roll <= 40 then
                myweather.current_system = "rain"
            end
        end
    end
end)
