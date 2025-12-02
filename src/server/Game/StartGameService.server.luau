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

local StartGameEvent = ServerEvents.StartGameEvent
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameRemote = RemoteEvents.StartGameEvent
local ResetGameRemote = RemoteEvents.ResetGameEvent

local CONTEXT = "StartGameService"
local gameStarted = false

Log.Info(CONTEXT, "StartGameService initialized")

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
	
	-- 1. Reset team scores and assign players to teams FIRST
	Log.Info(CONTEXT, "Step 1: Assigning teams...")
	TeamService.ResetTeamScores()
	TeamService.AssignAllPlayersToTeams()
	
	-- Small delay to ensure team assignments are fully applied
	task.wait(0.1)
	
	-- 2. Enable team-based spawning
	Log.Info(CONTEXT, "Step 2: Enabling team spawning...")
	SpawnService.SetGameActive(true)
	
	-- 3. Start tracking achievements for this game
	Log.Info(CONTEXT, "Step 3: Starting achievement tracking...")
	GameEndService.StartGameTracking()
	
	-- 4. Respawn all players at team spawn locations (now that teams are assigned)
	Log.Info(CONTEXT, "Step 4: Respawning players at team spawns...")
	respawnAllPlayersAtTeamSpawns()
	
	-- 5. Fire the server-side BindableEvent to notify all other game systems
	Log.Info(CONTEXT, "Step 5: Firing StartGameEvent BindableEvent")
	StartGameEvent:Fire()
end)

-- Reset gameStarted when timer ends (game over)
TimerEndedEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game ended, ready for new game")
	gameStarted = false
	
	-- Disable team-based spawning (back to default spawn)
	SpawnService.SetGameActive(false)
end)

-- Reset gameStarted when game is manually reset
ResetGameRemote.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Game reset by %s, ready for new game", player.Name))
	gameStarted = false
	
	-- Reset spawn service state
	SpawnService.SetGameActive(false)
end)

-- Handle players joining mid-game
Players.PlayerAdded:Connect(function(player: Player)
	if gameStarted then
		-- Add player to achievement tracking for this game
		GameEndService.AddPlayerToTracking(player)
	end
end)
