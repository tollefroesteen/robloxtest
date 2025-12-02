--!strict
-- SpawnService.luau
-- Manages player spawn locations based on team and game state

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "SpawnService"

local SpawnService = {}

-- Spawn location references
local defaultSpawn: SpawnLocation? = nil
local redTeamSpawn: SpawnLocation? = nil
local blueTeamSpawn: SpawnLocation? = nil

-- Track if a game is currently active
local gameActive = false

-- Initialize spawn locations
local function initializeSpawnLocations()
	-- Find spawn locations in workspace
	defaultSpawn = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	redTeamSpawn = workspace:FindFirstChild("SpawnLocationRed") :: SpawnLocation?
	blueTeamSpawn = workspace:FindFirstChild("SpawnLocationBlue") :: SpawnLocation?
	
	if defaultSpawn then
		Log.Info(CONTEXT, "Found default SpawnLocation")
		defaultSpawn.Neutral = true
		defaultSpawn.AllowTeamChangeOnTouch = false
	else
		Log.Warn(CONTEXT, "Default SpawnLocation not found!")
	end
	
	if redTeamSpawn then
		Log.Info(CONTEXT, "Found SpawnLocationRed")
		redTeamSpawn.Neutral = false
		redTeamSpawn.AllowTeamChangeOnTouch = false
		redTeamSpawn.TeamColor = BrickColor.new("Bright red")
	else
		Log.Warn(CONTEXT, "SpawnLocationRed not found!")
	end
	
	if blueTeamSpawn then
		Log.Info(CONTEXT, "Found SpawnLocationBlue")
		blueTeamSpawn.Neutral = false
		blueTeamSpawn.AllowTeamChangeOnTouch = false
		blueTeamSpawn.TeamColor = BrickColor.new("Bright blue")
	else
		Log.Warn(CONTEXT, "SpawnLocationBlue not found!")
	end
end

-- Get the appropriate spawn location for a player
function SpawnService.GetSpawnForPlayer(player: Player): SpawnLocation?
	-- If no game active, use default spawn
	if not gameActive then
		Log.Debug(CONTEXT, string.format("Game not active, using default spawn for %s", player.Name))
		return defaultSpawn
	end
	
	-- Get player's team
	local team = player.Team
	if not team then
		Log.Warn(CONTEXT, string.format("%s has no team, using default spawn", player.Name))
		return defaultSpawn
	end
	
	Log.Info(CONTEXT, string.format("Getting spawn for %s (team: %s)", player.Name, team.Name))
	
	-- Return team-specific spawn
	if team.Name == "Red Team" and redTeamSpawn then
		Log.Info(CONTEXT, string.format("Using SpawnLocationRed for %s", player.Name))
		return redTeamSpawn
	elseif team.Name == "Blue Team" and blueTeamSpawn then
		Log.Info(CONTEXT, string.format("Using SpawnLocationBlue for %s", player.Name))
		return blueTeamSpawn
	end
	
	-- Fallback to default
	Log.Warn(CONTEXT, string.format("No spawn found for team %s, using default", team.Name))
	return defaultSpawn
end

-- Set the player's respawn location before calling LoadCharacter
function SpawnService.SetPlayerSpawnLocation(player: Player)
	local spawn = SpawnService.GetSpawnForPlayer(player)
	if spawn then
		player.RespawnLocation = spawn
		Log.Info(CONTEXT, string.format("Set %s's RespawnLocation to %s", player.Name, spawn.Name))
	else
		Log.Warn(CONTEXT, string.format("No spawn location available for %s", player.Name))
	end
end

-- Set game active state (called when game starts/ends)
function SpawnService.SetGameActive(active: boolean)
	gameActive = active
	Log.Info(CONTEXT, string.format("Game active: %s", tostring(active)))
	
	-- Update spawn location settings based on game state
	if defaultSpawn then
		-- During game, disable default spawn; outside game, enable it
		defaultSpawn.Enabled = not active
		Log.Info(CONTEXT, string.format("Default spawn Enabled: %s", tostring(not active)))
	end
	
	if redTeamSpawn then
		redTeamSpawn.Enabled = active
		Log.Info(CONTEXT, string.format("Red spawn Enabled: %s", tostring(active)))
	end
	
	if blueTeamSpawn then
		blueTeamSpawn.Enabled = active
		Log.Info(CONTEXT, string.format("Blue spawn Enabled: %s", tostring(active)))
	end
end

-- Check if game is active
function SpawnService.IsGameActive(): boolean
	return gameActive
end

-- Initialize on module load
initializeSpawnLocations()

Log.Info(CONTEXT, "SpawnService initialized")

return SpawnService
