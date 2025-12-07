--!strict
-- TestProceduralEnvironment.server.luau
-- Test script for the procedural environment system in the Lobby
-- 
-- Provides admin chat commands for testing different seed combinations.
-- Use /terrain <seed>, /foliage <seed>, or /world <terrainSeed> <foliageSeed>
-- Use /hills to configure Irish Hills parameters

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to load
local Shared = ReplicatedStorage:WaitForChild("Shared")
local config = Shared:WaitForChild("config")
local util = Shared:WaitForChild("util")

local EnvironmentOrchestrator = require(config:WaitForChild("EnvironmentOrchestrator"))
local ProceduralConfig = require(config:WaitForChild("ProceduralConfig"))
local Log = require(util:WaitForChild("Log"))

local CONTEXT = "ProceduralEnvAdmin"

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

local INITIAL_TERRAIN_SEED = 1    -- Starting terrain seed
local INITIAL_FOLIAGE_SEED = 1    -- Starting foliage seed
local GENERATE_ON_START = true    -- Auto-generate on game start
local PLAY_AREA_ONLY = false      -- Set to true for faster generation

-- Irish Hills configuration (applied on script load)
local HILLS_CONFIG = {
	Enabled = true,
	Density = 0.8,           -- Hills per 10k sq units (0.3=sparse, 1.5=dense, 3.0=very hilly)
	MinRadius = 40,          -- Smallest hill radius (studs)
	MaxRadius = 80,          -- Largest hill radius (studs)
	MinHeight = 5,           -- Shortest hill peak (studs)
	MaxHeight = 20,          -- Tallest hill peak (studs)
	Steepness = 1.0,         -- Slope gradient (0.5=gentle, 1.0=normal, 2.0=steep)
	FalloffPower = 2.0,      -- Shape (1=cone, 2=dome/natural, 3=plateau-top)
}

-- Mountain configuration (alpine peaks with ridges)
local MOUNTAIN_CONFIG = {
	Enabled = true,
	-- Base mountain height
	BaseRiseMultiplier = 0.2, -- Overall mountain height (0.5=low, 1.0=normal, 2.0=tall)
	-- Peak generation
	PeakDensity = 5.0,       -- Peaks per 10k sq units (0.5=few, 2.0=many)
	PeakMinRadius = 55,      -- Smallest peak base radius
	PeakMaxRadius = 100,      -- Largest peak base radius
	PeakMinHeight = 20,      -- Min extra height for peaks
	PeakMaxHeight = 200,      -- Max extra height for peaks
	PeakSteepness = 1.5,     -- Peak slope (1.0=gradual, 2.0=sharp)
	-- Ridge generation
	RidgeEnabled = true,
	RidgeNoiseScale = 25,    -- Smaller = more ridges
	RidgeHeight = 0,        -- Additional height for ridges
	RidgeSharpness = 0,    -- Ridge sharpness (1.0=rounded, 2.0=sharp)
	-- Surface detail
	Roughness = 1.2,         -- Surface roughness multiplier
	-- Snow
	SnowHeight = 60,         -- Height where snow starts
	SnowBlend = 10,          -- Transition width
}

-- Flat Zone configuration (flat areas for lobby setup)
-- You can define multiple zones, each with their own position and size
local FLAT_ZONES: {ProceduralConfig.FlatZoneDefinition} = {
	{
		Name = "lobby",
		Enabled = true,
		OriginX = 0,             -- Center X position
		OriginZ = 0,             -- Center Z position
		SizeX = 80,              -- Width (studs)
		SizeZ = 100,             -- Length (studs)
		Height = 1,              -- Height above water level
		BlendDistance = 10,      -- Edge transition distance
	},
	-- Add more flat zones as needed:
	-- {
	-- 	Name = "spawn_north",
	-- 	Enabled = true,
	-- 	OriginX = 0,
	-- 	OriginZ = -120,
	-- 	SizeX = 40,
	-- 	SizeZ = 40,
	-- 	Height = 2,
	-- 	BlendDistance = 8,
	-- },
}

-- Admin user IDs (add your Roblox user IDs here, or leave empty to allow everyone in Studio)
local ADMIN_IDS: {number} = {
	-- 12345678,  -- Example: Add your user ID
}

-- =============================================================================
-- ADMIN SYSTEM
-- =============================================================================

local function isAdmin(player: Player): boolean
	-- In Studio, allow everyone
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	
	-- Check admin list
	for _, id in ADMIN_IDS do
		if player.UserId == id then
			return true
		end
	end
	
	return false
end

local function sendMessage(player: Player, message: string)
	-- Log to output (visible in Studio and server console)
	Log.Info(CONTEXT, message)
end

local function showHelp(player: Player)
	sendMessage(player, "=== Procedural Environment Commands ===")
	sendMessage(player, "/world <terrain> <foliage> - Generate with both seeds")
	sendMessage(player, "/terrain <seed> - Change terrain seed only")
	sendMessage(player, "/foliage <seed> - Change foliage seed only")
	sendMessage(player, "/seeds - Show current seeds")
	sendMessage(player, "/clear - Clear all generated content")
	sendMessage(player, "/regen - Regenerate with current seeds")
	sendMessage(player, "=== Hill Configuration ===")
	sendMessage(player, "/hills - Show current hill settings")
	sendMessage(player, "/hills density <0.3-3.0> - Hills per area (0.3=sparse, 1.5=dense)")
	sendMessage(player, "/hills height <min> <max> - Hill height range (e.g., 4 20)")
	sendMessage(player, "/hills radius <min> <max> - Hill size range (e.g., 10 45)")
	sendMessage(player, "/hills steep <0.5-2.0> - Slope steepness (0.5=gentle, 2.0=steep)")
	sendMessage(player, "/hills falloff <1-3> - Shape (1=cone, 2=dome, 3=plateau)")
	sendMessage(player, "=== Mountain Configuration ===")
	sendMessage(player, "/mountain - Show current mountain settings")
	sendMessage(player, "/mountain height <0.5-3.0> - Overall mountain height multiplier")
	sendMessage(player, "/mountain peaks <0.5-3.0> - Peak density (0.5=few, 2.0=many)")
	sendMessage(player, "/mountain pheight <min> <max> - Peak heights (e.g., 10 35)")
	sendMessage(player, "/mountain pradius <min> <max> - Peak base sizes (e.g., 15 40)")
	sendMessage(player, "/mountain steep <1.0-2.5> - Peak steepness (1=gradual, 2=sharp)")
	sendMessage(player, "/mountain ridges on|off - Toggle ridge generation")
	sendMessage(player, "/mountain ridge <height> <sharpness> - Ridge settings")
	sendMessage(player, "/mountain snow <height> <blend> - Snow line settings")
	sendMessage(player, "/mountain rough <0.5-2.0> - Surface roughness")
	sendMessage(player, "=== Flat Zone Configuration ===")
	sendMessage(player, "/flat - List all flat zones")
	sendMessage(player, "/flat add <name> <x> <z> <sizeX> <sizeZ> <height> [blend] - Add a flat zone")
	sendMessage(player, "/flat remove <name> - Remove a flat zone")
	sendMessage(player, "/flat move <name> <x> <z> - Move a flat zone")
	sendMessage(player, "/flat resize <name> <sizeX> <sizeZ> - Resize a flat zone")
	sendMessage(player, "/flat height <name> <value> - Set flat zone height")
	sendMessage(player, "/flat blend <name> <distance> - Set edge blend distance")
	sendMessage(player, "/flat enable <name> / /flat disable <name> - Toggle a zone")
	sendMessage(player, "/flat clear - Remove all flat zones")
	sendMessage(player, "/help - Show this help")
end

local function handleCommand(player: Player, message: string)
	if not isAdmin(player) then
		return
	end
	
	local args = string.split(string.lower(message), " ")
	local command = args[1]
	
	-- Remove the "/" prefix
	if string.sub(command, 1, 1) == "/" then
		command = string.sub(command, 2)
	else
		return -- Not a command
	end
	
	if command == "world" or command == "w" then
		local terrainSeed = tonumber(args[2])
		local foliageSeed = tonumber(args[3])
		
		if not terrainSeed or not foliageSeed then
			sendMessage(player, "Usage: /world <terrainSeed> <foliageSeed>")
			return
		end
		
		sendMessage(player, string.format("Generating world: Terrain=%d, Foliage=%d", terrainSeed, foliageSeed))
		
		task.spawn(function()
			local info = EnvironmentOrchestrator.Generate({
				terrainSeed = terrainSeed,
				foliageSeed = foliageSeed,
				playAreaOnly = PLAY_AREA_ONLY,
			})
			sendMessage(player, string.format("World generated in %.2fs!", info.elapsed))
		end)
		
	elseif command == "terrain" or command == "t" then
		local seed = tonumber(args[2])
		
		if not seed then
			sendMessage(player, "Usage: /terrain <seed>")
			return
		end
		
		sendMessage(player, string.format("Regenerating terrain with seed: %d", seed))
		
		task.spawn(function()
			EnvironmentOrchestrator.RegenerateTerrain(seed, PLAY_AREA_ONLY)
			sendMessage(player, "Terrain regenerated!")
		end)
		
	elseif command == "foliage" or command == "f" then
		local seed = tonumber(args[2])
		
		if not seed then
			sendMessage(player, "Usage: /foliage <seed>")
			return
		end
		
		sendMessage(player, string.format("Regenerating foliage with seed: %d", seed))
		
		task.spawn(function()
			EnvironmentOrchestrator.RegenerateFoliage(seed)
			sendMessage(player, "Foliage regenerated!")
		end)
		
	elseif command == "seeds" or command == "s" then
		local seeds = EnvironmentOrchestrator.GetSeeds()
		sendMessage(player, string.format("Current seeds - Terrain: %s, Foliage: %s", 
			tostring(seeds.terrainSeed or "none"), 
			tostring(seeds.foliageSeed or "none")
		))
		
	elseif command == "clear" or command == "c" then
		sendMessage(player, "Clearing environment...")
		EnvironmentOrchestrator.Clear()
		sendMessage(player, "Environment cleared!")
		
	elseif command == "regen" or command == "r" then
		local seeds = EnvironmentOrchestrator.GetSeeds()
		local terrainSeed = seeds.terrainSeed or INITIAL_TERRAIN_SEED
		local foliageSeed = seeds.foliageSeed or INITIAL_FOLIAGE_SEED
		
		sendMessage(player, string.format("Regenerating: Terrain=%d, Foliage=%d", terrainSeed, foliageSeed))
		
		task.spawn(function()
			local info = EnvironmentOrchestrator.Generate({
				terrainSeed = terrainSeed,
				foliageSeed = foliageSeed,
				playAreaOnly = PLAY_AREA_ONLY,
			})
			sendMessage(player, string.format("Regenerated in %.2fs!", info.elapsed))
		end)
		
	elseif command == "help" or command == "h" or command == "?" then
		showHelp(player)
		
	elseif command == "hills" then
		local hillConfig = ProceduralConfig.IrishHills
		local subCommand = args[2]
		
		if not subCommand then
			-- Show current hill settings
			sendMessage(player, "=== Irish Hills Configuration ===")
			sendMessage(player, string.format("Enabled: %s", tostring(hillConfig.Enabled)))
			sendMessage(player, string.format("Density: %.2f (hills per 10k sq units)", hillConfig.Density))
			sendMessage(player, string.format("Radius: %d - %d studs", hillConfig.MinRadius, hillConfig.MaxRadius))
			sendMessage(player, string.format("Height: %d - %d studs", hillConfig.MinHeight, hillConfig.MaxHeight))
			sendMessage(player, string.format("Steepness: %.2f (0.5=gentle, 2.0=steep)", hillConfig.Steepness))
			sendMessage(player, string.format("Falloff: %.1f (1=cone, 2=dome, 3=plateau)", hillConfig.FalloffPower))
			sendMessage(player, "Use /regen to apply changes")
			
		elseif subCommand == "density" or subCommand == "d" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /hills density <0.3-3.0>")
				return
			end
			hillConfig.Density = math.clamp(value, 0.1, 5.0)
			sendMessage(player, string.format("Hill density set to %.2f - use /regen to apply", hillConfig.Density))
			
		elseif subCommand == "height" or subCommand == "h" then
			local minVal = tonumber(args[3])
			local maxVal = tonumber(args[4])
			if not minVal or not maxVal then
				sendMessage(player, "Usage: /hills height <min> <max>")
				return
			end
			hillConfig.MinHeight = math.max(1, minVal)
			hillConfig.MaxHeight = math.max(hillConfig.MinHeight + 1, maxVal)
			sendMessage(player, string.format("Hill height set to %d-%d - use /regen to apply", hillConfig.MinHeight, hillConfig.MaxHeight))
			
		elseif subCommand == "radius" or subCommand == "r" or subCommand == "size" then
			local minVal = tonumber(args[3])
			local maxVal = tonumber(args[4])
			if not minVal or not maxVal then
				sendMessage(player, "Usage: /hills radius <min> <max>")
				return
			end
			hillConfig.MinRadius = math.max(5, minVal)
			hillConfig.MaxRadius = math.max(hillConfig.MinRadius + 5, maxVal)
			sendMessage(player, string.format("Hill radius set to %d-%d - use /regen to apply", hillConfig.MinRadius, hillConfig.MaxRadius))
			
		elseif subCommand == "steep" or subCommand == "steepness" or subCommand == "s" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /hills steep <0.5-2.0>")
				return
			end
			hillConfig.Steepness = math.clamp(value, 0.3, 3.0)
			sendMessage(player, string.format("Hill steepness set to %.2f - use /regen to apply", hillConfig.Steepness))
			
		elseif subCommand == "falloff" or subCommand == "f" or subCommand == "shape" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /hills falloff <1-3>")
				return
			end
			hillConfig.FalloffPower = math.clamp(value, 0.5, 4.0)
			sendMessage(player, string.format("Hill falloff set to %.1f - use /regen to apply", hillConfig.FalloffPower))
			
		elseif subCommand == "on" or subCommand == "enable" then
			hillConfig.Enabled = true
			sendMessage(player, "Irish Hills enabled - use /regen to apply")
			
		elseif subCommand == "off" or subCommand == "disable" then
			hillConfig.Enabled = false
			sendMessage(player, "Irish Hills disabled - use /regen to apply")
			
		else
			sendMessage(player, "Unknown hills command. Use /hills for current settings or /help for commands")
		end
		
	elseif command == "mountain" or command == "mt" or command == "mountains" then
		local mtConfig = ProceduralConfig.Mountains
		local subCommand = args[2]
		
		if not subCommand then
			-- Show current mountain settings
			sendMessage(player, "=== Alpine Mountain Configuration ===")
			sendMessage(player, string.format("Enabled: %s", tostring(mtConfig.Enabled)))
			sendMessage(player, string.format("Base Height Multiplier: %.2f (0.5=low, 1.0=normal, 2.0=tall)", mtConfig.BaseRiseMultiplier or 1.0))
			sendMessage(player, string.format("Peak Density: %.2f (peaks per 10k sq units)", mtConfig.PeakDensity))
			sendMessage(player, string.format("Peak Radius: %d - %d studs", mtConfig.PeakMinRadius, mtConfig.PeakMaxRadius))
			sendMessage(player, string.format("Peak Height: %d - %d studs", mtConfig.PeakMinHeight, mtConfig.PeakMaxHeight))
			sendMessage(player, string.format("Peak Steepness: %.2f (1=gradual, 2=sharp)", mtConfig.PeakSteepness))
			sendMessage(player, string.format("Ridges: %s (height=%d, sharpness=%.1f)", 
				tostring(mtConfig.RidgeEnabled), mtConfig.RidgeHeight, mtConfig.RidgeSharpness))
			sendMessage(player, string.format("Snow: starts at %d, blend=%d", mtConfig.SnowHeight, mtConfig.SnowBlend))
			sendMessage(player, string.format("Roughness: %.2f", mtConfig.Roughness))
			sendMessage(player, "Use /regen to apply changes")
			
		elseif subCommand == "height" or subCommand == "base" or subCommand == "h" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /mountain height <0-5.0>")
				return
			end
			mtConfig.BaseRiseMultiplier = math.clamp(value, 0, 5.0)
			sendMessage(player, string.format("Mountain height multiplier set to %.2f - use /regen to apply", mtConfig.BaseRiseMultiplier))
			
		elseif subCommand == "peaks" or subCommand == "density" or subCommand == "d" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /mountain peaks <0-5.0>")
				return
			end
			mtConfig.PeakDensity = math.clamp(value, 0, 5.0)
			sendMessage(player, string.format("Peak density set to %.2f - use /regen to apply", mtConfig.PeakDensity))
			
		elseif subCommand == "pheight" or subCommand == "ph" then
			local minVal = tonumber(args[3])
			local maxVal = tonumber(args[4])
			if not minVal or not maxVal then
				sendMessage(player, "Usage: /mountain pheight <min> <max>")
				return
			end
			mtConfig.PeakMinHeight = math.max(0, minVal)
			mtConfig.PeakMaxHeight = math.max(mtConfig.PeakMinHeight, maxVal)
			sendMessage(player, string.format("Peak height set to %d-%d - use /regen to apply", mtConfig.PeakMinHeight, mtConfig.PeakMaxHeight))
			
		elseif subCommand == "pradius" or subCommand == "pr" or subCommand == "psize" then
			local minVal = tonumber(args[3])
			local maxVal = tonumber(args[4])
			if not minVal or not maxVal then
				sendMessage(player, "Usage: /mountain pradius <min> <max>")
				return
			end
			mtConfig.PeakMinRadius = math.max(5, minVal)
			mtConfig.PeakMaxRadius = math.max(mtConfig.PeakMinRadius + 5, maxVal)
			sendMessage(player, string.format("Peak radius set to %d-%d - use /regen to apply", mtConfig.PeakMinRadius, mtConfig.PeakMaxRadius))
			
		elseif subCommand == "steep" or subCommand == "steepness" or subCommand == "s" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /mountain steep <0-3.0>")
				return
			end
			mtConfig.PeakSteepness = math.clamp(value, 0, 3.0)
			sendMessage(player, string.format("Peak steepness set to %.2f - use /regen to apply", mtConfig.PeakSteepness))
			
		elseif subCommand == "ridges" or subCommand == "ridge" or subCommand == "r" then
			local arg3 = args[3]
			if arg3 == "on" or arg3 == "true" then
				mtConfig.RidgeEnabled = true
				sendMessage(player, "Ridges enabled - use /regen to apply")
			elseif arg3 == "off" or arg3 == "false" then
				mtConfig.RidgeEnabled = false
				sendMessage(player, "Ridges disabled - use /regen to apply")
			else
				-- Treat as height and sharpness
				local height = tonumber(args[3])
				local sharpness = tonumber(args[4])
				if height then
					mtConfig.RidgeHeight = math.clamp(height, 0, 500)
				end
				if sharpness then
					mtConfig.RidgeSharpness = math.clamp(sharpness, 0, 3.0)
				end
				sendMessage(player, string.format("Ridge height=%d, sharpness=%.1f - use /regen to apply", mtConfig.RidgeHeight, mtConfig.RidgeSharpness))
			end
			
		elseif subCommand == "snow" then
			local height = tonumber(args[3])
			local blend = tonumber(args[4])
			if not height then
				sendMessage(player, "Usage: /mountain snow <height> [blend]")
				return
			end
			mtConfig.SnowHeight = math.max(20, height)
			if blend then
				mtConfig.SnowBlend = math.clamp(blend, 2, 30)
			end
			sendMessage(player, string.format("Snow height=%d, blend=%d - use /regen to apply", mtConfig.SnowHeight, mtConfig.SnowBlend))
			
		elseif subCommand == "rough" or subCommand == "roughness" then
			local value = tonumber(args[3])
			if not value then
				sendMessage(player, "Usage: /mountain rough <0-3.0>")
				return
			end
			mtConfig.Roughness = math.clamp(value, 0, 3.0)
			sendMessage(player, string.format("Roughness set to %.2f - use /regen to apply", mtConfig.Roughness))
			
		elseif subCommand == "on" or subCommand == "enable" then
			mtConfig.Enabled = true
			sendMessage(player, "Mountains enabled - use /regen to apply")
			
		elseif subCommand == "off" or subCommand == "disable" then
			mtConfig.Enabled = false
			sendMessage(player, "Mountains disabled - use /regen to apply")
			
		else
			sendMessage(player, "Unknown mountain command. Use /mountain for settings or /help for commands")
		end
		
	elseif command == "flat" or command == "flatzone" or command == "flatzones" then
		local flatZones = ProceduralConfig.FlatZones
		local subCommand = args[2]
		
		if not subCommand then
			-- List all flat zones
			sendMessage(player, "=== Flat Zones ===")
			sendMessage(player, string.format("Master Enabled: %s", tostring(flatZones.Enabled)))
			if #flatZones.Zones == 0 then
				sendMessage(player, "No flat zones defined. Use /flat add <name> <x> <z> <sizeX> <sizeZ> <height>")
			else
				for i, zone in flatZones.Zones do
					sendMessage(player, string.format("[%d] %s: %s at (%d,%d) size %dx%d h=%d blend=%d",
						i, zone.Name, zone.Enabled and "ON" or "OFF",
						zone.OriginX, zone.OriginZ, zone.SizeX, zone.SizeZ, zone.Height, zone.BlendDistance))
				end
			end
			sendMessage(player, "Use /regen to apply changes")
			
		elseif subCommand == "on" or subCommand == "enable" then
			local zoneName = args[3]
			if zoneName then
				local zone = ProceduralConfig.GetFlatZone(zoneName)
				if zone then
					zone.Enabled = true
					sendMessage(player, string.format("Flat zone '%s' enabled - use /regen to apply", zoneName))
				else
					sendMessage(player, string.format("Flat zone '%s' not found", zoneName))
				end
			else
				flatZones.Enabled = true
				sendMessage(player, "All flat zones enabled - use /regen to apply")
			end
			
		elseif subCommand == "off" or subCommand == "disable" then
			local zoneName = args[3]
			if zoneName then
				local zone = ProceduralConfig.GetFlatZone(zoneName)
				if zone then
					zone.Enabled = false
					sendMessage(player, string.format("Flat zone '%s' disabled - use /regen to apply", zoneName))
				else
					sendMessage(player, string.format("Flat zone '%s' not found", zoneName))
				end
			else
				flatZones.Enabled = false
				sendMessage(player, "All flat zones disabled - use /regen to apply")
			end
			
		elseif subCommand == "add" or subCommand == "new" or subCommand == "create" then
			local name = args[3]
			local originX = tonumber(args[4])
			local originZ = tonumber(args[5])
			local sizeX = tonumber(args[6])
			local sizeZ = tonumber(args[7])
			local height = tonumber(args[8])
			local blend = tonumber(args[9]) or 10
			
			if not name or not originX or not originZ or not sizeX or not sizeZ or not height then
				sendMessage(player, "Usage: /flat add <name> <x> <z> <sizeX> <sizeZ> <height> [blend]")
				return
			end
			
			-- Check if name already exists
			if ProceduralConfig.GetFlatZone(name) then
				sendMessage(player, string.format("Flat zone '%s' already exists. Use /flat remove %s first.", name, name))
				return
			end
			
			ProceduralConfig.AddFlatZone({
				Name = name,
				Enabled = true,
				OriginX = originX,
				OriginZ = originZ,
				SizeX = math.clamp(sizeX, 10, 500),
				SizeZ = math.clamp(sizeZ, 10, 500),
				Height = math.clamp(height, -10, 100),
				BlendDistance = math.clamp(blend, 0, 100),
			})
			sendMessage(player, string.format("Added flat zone '%s' at (%d,%d) size %dx%d h=%d - use /regen to apply",
				name, originX, originZ, sizeX, sizeZ, height))
			
		elseif subCommand == "remove" or subCommand == "delete" or subCommand == "rm" then
			local name = args[3]
			if not name then
				sendMessage(player, "Usage: /flat remove <name>")
				return
			end
			if ProceduralConfig.RemoveFlatZone(name) then
				sendMessage(player, string.format("Removed flat zone '%s' - use /regen to apply", name))
			else
				sendMessage(player, string.format("Flat zone '%s' not found", name))
			end
			
		elseif subCommand == "move" or subCommand == "pos" or subCommand == "position" then
			local name = args[3]
			local newX = tonumber(args[4])
			local newZ = tonumber(args[5])
			if not name or not newX or not newZ then
				sendMessage(player, "Usage: /flat move <name> <x> <z>")
				return
			end
			local zone = ProceduralConfig.GetFlatZone(name)
			if zone then
				zone.OriginX = newX
				zone.OriginZ = newZ
				sendMessage(player, string.format("Moved '%s' to (%d,%d) - use /regen to apply", name, newX, newZ))
			else
				sendMessage(player, string.format("Flat zone '%s' not found", name))
			end
			
		elseif subCommand == "resize" or subCommand == "size" then
			local name = args[3]
			local sizeX = tonumber(args[4])
			local sizeZ = tonumber(args[5])
			if not name or not sizeX then
				sendMessage(player, "Usage: /flat resize <name> <sizeX> [sizeZ]")
				return
			end
			local zone = ProceduralConfig.GetFlatZone(name)
			if zone then
				zone.SizeX = math.clamp(sizeX, 10, 500)
				zone.SizeZ = math.clamp(sizeZ or sizeX, 10, 500)
				sendMessage(player, string.format("Resized '%s' to %dx%d - use /regen to apply", name, zone.SizeX, zone.SizeZ))
			else
				sendMessage(player, string.format("Flat zone '%s' not found", name))
			end
			
		elseif subCommand == "height" or subCommand == "h" then
			local name = args[3]
			local height = tonumber(args[4])
			if not name or not height then
				sendMessage(player, "Usage: /flat height <name> <value>")
				return
			end
			local zone = ProceduralConfig.GetFlatZone(name)
			if zone then
				zone.Height = math.clamp(height, -10, 100)
				sendMessage(player, string.format("Set '%s' height to %d - use /regen to apply", name, zone.Height))
			else
				sendMessage(player, string.format("Flat zone '%s' not found", name))
			end
			
		elseif subCommand == "blend" then
			local name = args[3]
			local blend = tonumber(args[4])
			if not name or not blend then
				sendMessage(player, "Usage: /flat blend <name> <distance>")
				return
			end
			local zone = ProceduralConfig.GetFlatZone(name)
			if zone then
				zone.BlendDistance = math.clamp(blend, 0, 100)
				sendMessage(player, string.format("Set '%s' blend to %d - use /regen to apply", name, zone.BlendDistance))
			else
				sendMessage(player, string.format("Flat zone '%s' not found", name))
			end
			
		elseif subCommand == "clear" then
			ProceduralConfig.ClearFlatZones()
			sendMessage(player, "Cleared all flat zones - use /regen to apply")
			
		else
			sendMessage(player, "Unknown flat zone command. Use /flat for list or /help for commands")
		end
	end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

Log.Info(CONTEXT, "Procedural Environment Admin loaded")

-- Apply hills configuration from this file
local hillConfig = ProceduralConfig.IrishHills
hillConfig.Enabled = HILLS_CONFIG.Enabled
hillConfig.Density = HILLS_CONFIG.Density
hillConfig.MinRadius = HILLS_CONFIG.MinRadius
hillConfig.MaxRadius = HILLS_CONFIG.MaxRadius
hillConfig.MinHeight = HILLS_CONFIG.MinHeight
hillConfig.MaxHeight = HILLS_CONFIG.MaxHeight
hillConfig.Steepness = HILLS_CONFIG.Steepness
hillConfig.FalloffPower = HILLS_CONFIG.FalloffPower

Log.Info(CONTEXT, string.format("Hills config: Density=%.2f, Radius=%d-%d, Height=%d-%d, Steep=%.1f, Falloff=%.1f",
	hillConfig.Density, hillConfig.MinRadius, hillConfig.MaxRadius,
	hillConfig.MinHeight, hillConfig.MaxHeight, hillConfig.Steepness, hillConfig.FalloffPower))

-- Apply mountain configuration from this file
local mtConfig = ProceduralConfig.Mountains
mtConfig.Enabled = MOUNTAIN_CONFIG.Enabled
mtConfig.BaseRiseMultiplier = MOUNTAIN_CONFIG.BaseRiseMultiplier
mtConfig.PeakDensity = MOUNTAIN_CONFIG.PeakDensity
mtConfig.PeakMinRadius = MOUNTAIN_CONFIG.PeakMinRadius
mtConfig.PeakMaxRadius = MOUNTAIN_CONFIG.PeakMaxRadius
mtConfig.PeakMinHeight = MOUNTAIN_CONFIG.PeakMinHeight
mtConfig.PeakMaxHeight = MOUNTAIN_CONFIG.PeakMaxHeight
mtConfig.PeakSteepness = MOUNTAIN_CONFIG.PeakSteepness
mtConfig.RidgeEnabled = MOUNTAIN_CONFIG.RidgeEnabled
mtConfig.RidgeNoiseScale = MOUNTAIN_CONFIG.RidgeNoiseScale
mtConfig.RidgeHeight = MOUNTAIN_CONFIG.RidgeHeight
mtConfig.RidgeSharpness = MOUNTAIN_CONFIG.RidgeSharpness
mtConfig.Roughness = MOUNTAIN_CONFIG.Roughness
mtConfig.SnowHeight = MOUNTAIN_CONFIG.SnowHeight
mtConfig.SnowBlend = MOUNTAIN_CONFIG.SnowBlend

Log.Info(CONTEXT, string.format("Mountain config: Peaks=%.2f, Radius=%d-%d, Height=%d-%d, Steep=%.1f",
	mtConfig.PeakDensity, mtConfig.PeakMinRadius, mtConfig.PeakMaxRadius,
	mtConfig.PeakMinHeight, mtConfig.PeakMaxHeight, mtConfig.PeakSteepness))
Log.Info(CONTEXT, string.format("Mountain ridges: %s (height=%d, sharp=%.1f), Snow=%d, Rough=%.1f",
	tostring(mtConfig.RidgeEnabled), mtConfig.RidgeHeight, mtConfig.RidgeSharpness, mtConfig.SnowHeight, mtConfig.Roughness))

-- Apply flat zones configuration from this file
ProceduralConfig.ClearFlatZones()
ProceduralConfig.FlatZones.Enabled = true
for _, zone in FLAT_ZONES do
	ProceduralConfig.AddFlatZone(zone)
end

Log.Info(CONTEXT, string.format("Flat zones: %d zones defined", #ProceduralConfig.FlatZones.Zones))
for _, zone in ProceduralConfig.FlatZones.Zones do
	Log.Info(CONTEXT, string.format("  - %s: %s at (%d,%d) size %dx%d h=%d blend=%d",
		zone.Name, zone.Enabled and "ON" or "OFF",
		zone.OriginX, zone.OriginZ, zone.SizeX, zone.SizeZ, zone.Height, zone.BlendDistance))
end

-- Connect chat listener for each player
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		handleCommand(player, message)
	end)
end)

-- Connect existing players (for Studio testing)
for _, player in Players:GetPlayers() do
	player.Chatted:Connect(function(message)
		handleCommand(player, message)
	end)
end

-- Auto-generate on start
if GENERATE_ON_START then
	task.wait(2)
	
	Log.Info(CONTEXT, string.format("Auto-generating: Terrain=%d, Foliage=%d", INITIAL_TERRAIN_SEED, INITIAL_FOLIAGE_SEED))
	
	EnvironmentOrchestrator.Generate({
		terrainSeed = INITIAL_TERRAIN_SEED,
		foliageSeed = INITIAL_FOLIAGE_SEED,
		playAreaOnly = PLAY_AREA_ONLY,
		onComplete = function(genInfo)
			Log.Info(CONTEXT, string.format("Complete! Terrain=%d, Foliage=%d, Time=%.2fs", 
				genInfo.terrainSeed, genInfo.foliageSeed, genInfo.elapsed
			))
		end,
	})
end

-- =============================================================================
-- DEBUG COMMANDS (for Studio command bar)
-- =============================================================================

_G.World = function(terrainSeed: number, foliageSeed: number?, playAreaOnly: boolean?)
	return EnvironmentOrchestrator.Generate({
		terrainSeed = terrainSeed,
		foliageSeed = foliageSeed or terrainSeed,
		playAreaOnly = playAreaOnly,
	})
end

_G.Terrain = function(seed: number, playAreaOnly: boolean?)
	return EnvironmentOrchestrator.RegenerateTerrain(seed, playAreaOnly)
end

_G.Foliage = function(seed: number)
	return EnvironmentOrchestrator.RegenerateFoliage(seed)
end

_G.Seeds = function()
	return EnvironmentOrchestrator.GetSeeds()
end

_G.ClearWorld = function()
	EnvironmentOrchestrator.Clear()
end

-- Hill configuration functions
_G.Hills = function()
	local h = ProceduralConfig.IrishHills
	print("=== Irish Hills Config ===")
	print(string.format("Enabled: %s", tostring(h.Enabled)))
	print(string.format("Density: %.2f", h.Density))
	print(string.format("Radius: %d-%d", h.MinRadius, h.MaxRadius))
	print(string.format("Height: %d-%d", h.MinHeight, h.MaxHeight))
	print(string.format("Steepness: %.2f", h.Steepness))
	print(string.format("Falloff: %.1f", h.FalloffPower))
	return h
end

_G.SetHillDensity = function(density: number)
	ProceduralConfig.IrishHills.Density = math.clamp(density, 0.1, 5.0)
	print(string.format("Density: %.2f - use _G.Terrain(seed) to regenerate", ProceduralConfig.IrishHills.Density))
end

_G.SetHillHeight = function(min: number, max: number)
	ProceduralConfig.IrishHills.MinHeight = math.max(1, min)
	ProceduralConfig.IrishHills.MaxHeight = math.max(min + 1, max)
	print(string.format("Height: %d-%d - use _G.Terrain(seed) to regenerate", min, max))
end

_G.SetHillRadius = function(min: number, max: number)
	ProceduralConfig.IrishHills.MinRadius = math.max(5, min)
	ProceduralConfig.IrishHills.MaxRadius = math.max(min + 5, max)
	print(string.format("Radius: %d-%d - use _G.Terrain(seed) to regenerate", min, max))
end

_G.SetHillSteepness = function(steepness: number)
	ProceduralConfig.IrishHills.Steepness = math.clamp(steepness, 0.3, 3.0)
	print(string.format("Steepness: %.2f - use _G.Terrain(seed) to regenerate", ProceduralConfig.IrishHills.Steepness))
end

_G.SetHillFalloff = function(falloff: number)
	ProceduralConfig.IrishHills.FalloffPower = math.clamp(falloff, 0.5, 4.0)
	print(string.format("Falloff: %.1f - use _G.Terrain(seed) to regenerate", ProceduralConfig.IrishHills.FalloffPower))
end

-- Mountain configuration functions
_G.Mountain = function()
	local m = ProceduralConfig.Mountains
	print("=== Alpine Mountain Config ===")
	print(string.format("Enabled: %s", tostring(m.Enabled)))
	print(string.format("Height Multiplier: %.2f", m.BaseRiseMultiplier or 1.0))
	print(string.format("Peak Density: %.2f", m.PeakDensity))
	print(string.format("Peak Radius: %d-%d", m.PeakMinRadius, m.PeakMaxRadius))
	print(string.format("Peak Height: %d-%d", m.PeakMinHeight, m.PeakMaxHeight))
	print(string.format("Peak Steepness: %.2f", m.PeakSteepness))
	print(string.format("Ridges: %s (height=%d, sharpness=%.1f)", tostring(m.RidgeEnabled), m.RidgeHeight, m.RidgeSharpness))
	print(string.format("Snow: %d (blend=%d)", m.SnowHeight, m.SnowBlend))
	print(string.format("Roughness: %.2f", m.Roughness))
	return m
end

_G.SetMountainHeight = function(multiplier: number)
	ProceduralConfig.Mountains.BaseRiseMultiplier = math.clamp(multiplier, 0, 5.0)
	print(string.format("Mountain Height: %.2f - use _G.Terrain(seed) to regenerate", ProceduralConfig.Mountains.BaseRiseMultiplier))
end

_G.SetPeakDensity = function(density: number)
	ProceduralConfig.Mountains.PeakDensity = math.clamp(density, 0, 5.0)
	print(string.format("Peak Density: %.2f - use _G.Terrain(seed) to regenerate", ProceduralConfig.Mountains.PeakDensity))
end

_G.SetPeakHeight = function(min: number, max: number)
	ProceduralConfig.Mountains.PeakMinHeight = math.max(0, min)
	ProceduralConfig.Mountains.PeakMaxHeight = math.max(min, max)
	print(string.format("Peak Height: %d-%d - use _G.Terrain(seed) to regenerate", min, max))
end

_G.SetPeakRadius = function(min: number, max: number)
	ProceduralConfig.Mountains.PeakMinRadius = math.max(5, min)
	ProceduralConfig.Mountains.PeakMaxRadius = math.max(min + 5, max)
	print(string.format("Peak Radius: %d-%d - use _G.Terrain(seed) to regenerate", min, max))
end

_G.SetPeakSteepness = function(steepness: number)
	ProceduralConfig.Mountains.PeakSteepness = math.clamp(steepness, 0, 3.0)
	print(string.format("Peak Steepness: %.2f - use _G.Terrain(seed) to regenerate", ProceduralConfig.Mountains.PeakSteepness))
end

_G.SetRidges = function(enabled: boolean, height: number?, sharpness: number?)
	ProceduralConfig.Mountains.RidgeEnabled = enabled
	if height then ProceduralConfig.Mountains.RidgeHeight = math.clamp(height, 0, 500) end
	if sharpness then ProceduralConfig.Mountains.RidgeSharpness = math.clamp(sharpness, 0, 3.0) end
	print(string.format("Ridges: %s (height=%d, sharp=%.1f) - use _G.Terrain(seed) to regenerate",
		tostring(enabled), ProceduralConfig.Mountains.RidgeHeight, ProceduralConfig.Mountains.RidgeSharpness))
end

_G.SetSnowLine = function(height: number, blend: number?)
	ProceduralConfig.Mountains.SnowHeight = math.max(20, height)
	if blend then ProceduralConfig.Mountains.SnowBlend = math.clamp(blend, 2, 30) end
	print(string.format("Snow: %d (blend=%d) - use _G.Terrain(seed) to regenerate",
		ProceduralConfig.Mountains.SnowHeight, ProceduralConfig.Mountains.SnowBlend))
end

_G.SetMountainRoughness = function(roughness: number)
	ProceduralConfig.Mountains.Roughness = math.clamp(roughness, 0, 3.0)
	print(string.format("Roughness: %.2f - use _G.Terrain(seed) to regenerate", ProceduralConfig.Mountains.Roughness))
end

-- Flat Zone configuration functions (multiple zones support)
_G.FlatZones = function()
	local fz = ProceduralConfig.FlatZones
	print("=== Flat Zones Config ===")
	print(string.format("Master Enabled: %s", tostring(fz.Enabled)))
	print(string.format("Zone Count: %d", #fz.Zones))
	for i, zone in fz.Zones do
		print(string.format("[%d] %s: %s at (%d,%d) size %dx%d h=%d blend=%d",
			i, zone.Name, zone.Enabled and "ON" or "OFF",
			zone.OriginX, zone.OriginZ, zone.SizeX, zone.SizeZ, zone.Height, zone.BlendDistance))
	end
	return fz
end

_G.AddFlatZone = function(name: string, x: number, z: number, sizeX: number, sizeZ: number, height: number, blend: number?)
	ProceduralConfig.AddFlatZone({
		Name = name,
		Enabled = true,
		OriginX = x,
		OriginZ = z,
		SizeX = math.clamp(sizeX, 10, 500),
		SizeZ = math.clamp(sizeZ, 10, 500),
		Height = math.clamp(height, -10, 100),
		BlendDistance = math.clamp(blend or 10, 0, 100),
	})
	print(string.format("Added flat zone '%s' at (%d,%d) - use _G.Terrain(seed) to regenerate", name, x, z))
end

_G.RemoveFlatZone = function(name: string)
	if ProceduralConfig.RemoveFlatZone(name) then
		print(string.format("Removed flat zone '%s' - use _G.Terrain(seed) to regenerate", name))
	else
		print(string.format("Flat zone '%s' not found", name))
	end
end

_G.MoveFlatZone = function(name: string, x: number, z: number)
	local zone = ProceduralConfig.GetFlatZone(name)
	if zone then
		zone.OriginX = x
		zone.OriginZ = z
		print(string.format("Moved '%s' to (%d,%d) - use _G.Terrain(seed) to regenerate", name, x, z))
	else
		print(string.format("Flat zone '%s' not found", name))
	end
end

_G.ResizeFlatZone = function(name: string, sizeX: number, sizeZ: number?)
	local zone = ProceduralConfig.GetFlatZone(name)
	if zone then
		zone.SizeX = math.clamp(sizeX, 10, 500)
		zone.SizeZ = math.clamp(sizeZ or sizeX, 10, 500)
		print(string.format("Resized '%s' to %dx%d - use _G.Terrain(seed) to regenerate", name, zone.SizeX, zone.SizeZ))
	else
		print(string.format("Flat zone '%s' not found", name))
	end
end

_G.SetFlatZoneHeight = function(name: string, height: number)
	local zone = ProceduralConfig.GetFlatZone(name)
	if zone then
		zone.Height = math.clamp(height, -10, 100)
		print(string.format("Set '%s' height to %d - use _G.Terrain(seed) to regenerate", name, zone.Height))
	else
		print(string.format("Flat zone '%s' not found", name))
	end
end

_G.SetFlatZoneBlend = function(name: string, blend: number)
	local zone = ProceduralConfig.GetFlatZone(name)
	if zone then
		zone.BlendDistance = math.clamp(blend, 0, 100)
		print(string.format("Set '%s' blend to %d - use _G.Terrain(seed) to regenerate", name, zone.BlendDistance))
	else
		print(string.format("Flat zone '%s' not found", name))
	end
end

_G.EnableFlatZone = function(name: string, enabled: boolean)
	local zone = ProceduralConfig.GetFlatZone(name)
	if zone then
		zone.Enabled = enabled
		print(string.format("Flat zone '%s': %s - use _G.Terrain(seed) to regenerate", name, enabled and "enabled" or "disabled"))
	else
		print(string.format("Flat zone '%s' not found", name))
	end
end

_G.ClearFlatZones = function()
	ProceduralConfig.ClearFlatZones()
	print("Cleared all flat zones - use _G.Terrain(seed) to regenerate")
end

Log.Info(CONTEXT, "=== Chat Commands ===")
Log.Info(CONTEXT, "/world <t> <f> | /terrain <seed> | /foliage <seed>")
Log.Info(CONTEXT, "/seeds | /clear | /regen | /help")
Log.Info(CONTEXT, "/hills | /hills density/height/radius/steep/falloff <values>")
Log.Info(CONTEXT, "/mountain | /mountain peaks/pheight/pradius/steep/ridges/snow/rough <values>")
Log.Info(CONTEXT, "/flat | /flat on/off/size/height/blend <values>")
Log.Info(CONTEXT, "=== Command Bar ===")
Log.Info(CONTEXT, "_G.World(t,f) | _G.Terrain(s) | _G.Foliage(s) | _G.Seeds()")
Log.Info(CONTEXT, "_G.Hills() | _G.SetHillDensity(d) | _G.SetHillHeight(min,max)")
Log.Info(CONTEXT, "_G.SetHillRadius(min,max) | _G.SetHillSteepness(s) | _G.SetHillFalloff(f)")
Log.Info(CONTEXT, "_G.Mountain() | _G.SetPeakDensity(d) | _G.SetPeakHeight(min,max)")
Log.Info(CONTEXT, "_G.SetPeakRadius(min,max) | _G.SetPeakSteepness(s) | _G.SetRidges(on,h,s)")
Log.Info(CONTEXT, "_G.SetSnowLine(h,blend) | _G.SetMountainRoughness(r)")
Log.Info(CONTEXT, "_G.FlatZones() | _G.AddFlatZone(name,x,z,sizeX,sizeZ,h,blend)")
Log.Info(CONTEXT, "_G.RemoveFlatZone(name) | _G.MoveFlatZone(name,x,z)")
Log.Info(CONTEXT, "_G.ResizeFlatZone(name,sizeX,sizeZ) | _G.SetFlatZoneHeight(name,h)")
Log.Info(CONTEXT, "_G.SetFlatZoneBlend(name,d) | _G.EnableFlatZone(name,on)")
Log.Info(CONTEXT, "_G.ClearFlatZones()")
