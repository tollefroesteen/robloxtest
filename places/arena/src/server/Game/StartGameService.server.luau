--!strict
-- StartGameService.server.luau
-- Listens for StartGameEvent RemoteEvent and fires StartGameEvent BindableEvent

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local SpawnService = require(ServerScriptService.Server.Game.SpawnService)
local TeamService = require(ServerScriptService.Server.Game.TeamService)
local GameEndService = require(ServerScriptService.Server.Game.GameEndService)
local TrapController = require(ServerScriptService.Server.Game.TrapController)

local StartGameEvent = ServerEvents.StartGameEvent
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameRemote = RemoteEvents.StartGameEvent

local CONTEXT = "StartGameService"
local gameStarted = false

Log.Info(CONTEXT, "StartGameService initialized")

-- Clean up game state before starting a new game
local function cleanUpGameState()
	Log.Info(CONTEXT, "Cleaning up game state...")
	
	-- Clear all animals from Flock folder
	local Flock = workspace:FindFirstChild("Flock")
	if Flock then
		for _, child in Flock:GetChildren() do
			child:Destroy()
		end
		Log.Info(CONTEXT, "Cleared Flock folder")
	end
	
	-- Clear Food folder
	local Food = workspace:FindFirstChild("Food")
	if Food then
		for _, child in Food:GetChildren() do
			child:Destroy()
		end
		Log.Info(CONTEXT, "Cleared Food folder")
	end
	
	-- Clear Gifts folder
	local Gifts = workspace:FindFirstChild("Gifts")
	if Gifts then
		for _, child in Gifts:GetChildren() do
			child:Destroy()
		end
		Log.Info(CONTEXT, "Cleared Gifts folder")
	end
	
	-- Reset trap states
	TrapController.ResetAllTraps()
	TrapController.ResetCapturedAnimals()
	TrapController.SetGameActive(true)
	Log.Info(CONTEXT, "Reset trap controller")
	
	-- Reset team scores
	TeamService.ResetTeamScores()
	Log.Info(CONTEXT, "Reset team scores")
	
	-- Reset GameEndService state
	GameEndService.ResetGameState()
	Log.Info(CONTEXT, "Reset game end service state")
	
	Log.Info(CONTEXT, "Game state cleanup complete")
end

-- Respawn all players at their team spawn locations
local function respawnAllPlayersAtTeamSpawns()
	for _, player in Players:GetPlayers() do
		-- Log the player's team for debugging
		local team = player.Team
		Log.Info(CONTEXT, string.format("Respawning %s (team: %s)", player.Name, team and team.Name or "none"))
		
		SpawnService.SetPlayerSpawnLocation(player)
		player:LoadCharacter()
	end
end

-- Listen for client requests to start the game
StartGameRemote.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Game start requested by %s", player.Name))
	
	if gameStarted then
		Log.Warn(CONTEXT, string.format("Game already started, ignoring request from %s", player.Name))
		return
	end
	
	gameStarted = true
	
	-- 1. Clean up any previous game state
	Log.Info(CONTEXT, "Step 1: Cleaning up previous game state...")
	cleanUpGameState()
	
	-- 2. Assign players to teams
	Log.Info(CONTEXT, "Step 2: Assigning teams...")
	TeamService.AssignAllPlayersToTeams()
	
	-- Small delay to ensure team assignments are fully applied
	task.wait(0.1)
	
	-- 3. Enable team-based spawning
	Log.Info(CONTEXT, "Step 3: Enabling team spawning...")
	SpawnService.SetGameActive(true)
	
	-- 4. Start tracking achievements for this game
	Log.Info(CONTEXT, "Step 4: Starting achievement tracking...")
	GameEndService.StartGameTracking()
	
	-- 5. Respawn all players at team spawn locations (now that teams are assigned)
	Log.Info(CONTEXT, "Step 5: Respawning players at team spawns...")
	respawnAllPlayersAtTeamSpawns()
	
	-- 6. Fire the server-side BindableEvent to notify all other game systems
	Log.Info(CONTEXT, "Step 6: Firing StartGameEvent BindableEvent")
	StartGameEvent:Fire()
end)

-- Reset gameStarted when timer ends (game over)
TimerEndedEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game ended, ready for new game")
	gameStarted = false
	
	-- Disable team-based spawning (back to default spawn)
	SpawnService.SetGameActive(false)
end)

-- Handle players joining mid-game
Players.PlayerAdded:Connect(function(player: Player)
	if gameStarted then
		-- Add player to achievement tracking for this game
		GameEndService.AddPlayerToTracking(player)
	end
end)

-- Handle rematch requests from clients
RemoteEvents.RematchRequestEvent.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Rematch requested by %s", player.Name))
	
	-- Only allow rematch if game has ended
	if gameStarted then
		Log.Warn(CONTEXT, string.format("Game still in progress, ignoring rematch request from %s", player.Name))
		return
	end
	
	-- Start a new game (same flow as normal start)
	gameStarted = true
	
	-- 1. Clean up any previous game state
	Log.Info(CONTEXT, "Rematch: Cleaning up previous game state...")
	cleanUpGameState()
	
	-- 2. Assign players to teams (re-shuffle for fairness)
	Log.Info(CONTEXT, "Rematch: Assigning teams...")
	TeamService.AssignAllPlayersToTeams()
	
	task.wait(0.1)
	
	-- 3. Enable team-based spawning
	Log.Info(CONTEXT, "Rematch: Enabling team spawning...")
	SpawnService.SetGameActive(true)
	
	-- 4. Start tracking achievements for this game
	Log.Info(CONTEXT, "Rematch: Starting achievement tracking...")
	GameEndService.StartGameTracking()
	
	-- 5. Respawn all players at team spawn locations
	Log.Info(CONTEXT, "Rematch: Respawning players at team spawns...")
	respawnAllPlayersAtTeamSpawns()
	
	-- 6. Fire the server-side BindableEvent to notify all other game systems
	Log.Info(CONTEXT, "Rematch: Firing StartGameEvent BindableEvent")
	StartGameEvent:Fire()
end)
