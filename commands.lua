core.register_chatcommand("setweather", {
	params = "clear | clouds | rain | storm | snow | snowstorm | sandstorm | hail",
	description = "Force a specific weather type globally",
	privs = {server = true},
	func = function(name, param)
		local valid = {
			clear = true, 
			clouds = true,
			rain = true, 
			storm = true, 
			snow = true, 
			snowstorm = true, 
			sandstorm = true,
			hail = true
		}

		if valid[param] then
    		myweather.current_system = param
    		
    		if myweather.save_state then
        		myweather.save_state()
    		end
    		
    		local knots = (param == "storm" or param == "snowstorm") and math.random(40, 70) or math.random(10, 30)
    		myweather.update_wind(knots)
    		
    		return true, "Weather system forced to: " .. param:upper()
		else
			return false, "Invalid weather! Use: clear, clouds, rain, storm, snow, snowstorm, sandstorm, or hail."
		end
	end,
})

core.register_chatcommand("weather", {
	description = "Check current weather",
	func = function(name)
		local knots = math.floor(math.sqrt(myweather.wind_dir.x^2 + myweather.wind_dir.z^2) * 100)
		return true, "System: " .. myweather.current_system:upper() .. " | Wind: " .. knots .. " knots"
	end,
})

core.register_chatcommand("setwind", {
	params = "<knots>",
	description = "Set wind speed in knots (0-100)",
	privs = {server = true},
	func = function(name, param)
		local knots = tonumber(param)
		if not knots then
			return false, "Usage: /setwind <number>"
		end
		myweather.update_wind(knots)
		return true, "Wind set to " .. knots .. " knots."
	end,
})

core.register_chatcommand("strike", {
	description = "Test a lightning strike at your position",
	privs = {server = true},
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then return false end
		
		local ppos = player:get_pos()
		local strike_pos = {x = ppos.x + 5, y = ppos.y + 20, z = ppos.z + 5}

		core.add_particle({
			pos = strike_pos,
			velocity = {x=0, y=-200, z=0},
			expirationtime = 0.2,
			size = 30,
			texture = "myweather_lightning.png",
			glow = 14,
		})

		core.sound_play("myweather_thunder", {
			pos = strike_pos,
			gain = 1.0,
			max_hear_distance = 150,
		})

		return true, "Lightning strike simulated!"
	end,
})
