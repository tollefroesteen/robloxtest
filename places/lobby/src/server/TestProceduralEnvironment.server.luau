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

Log.Info(CONTEXT, "=== Chat Commands ===")
Log.Info(CONTEXT, "/world <t> <f> | /terrain <seed> | /foliage <seed>")
Log.Info(CONTEXT, "/seeds | /clear | /regen | /help")
Log.Info(CONTEXT, "/hills | /hills density/height/radius/steep/falloff <values>")
Log.Info(CONTEXT, "=== Command Bar ===")
Log.Info(CONTEXT, "_G.World(t,f) | _G.Terrain(s) | _G.Foliage(s) | _G.Seeds()")
Log.Info(CONTEXT, "_G.Hills() | _G.SetHillDensity(d) | _G.SetHillHeight(min,max)")
Log.Info(CONTEXT, "_G.SetHillRadius(min,max) | _G.SetHillSteepness(s) | _G.SetHillFalloff(f)")
