--!strict
-- StartGameService.server.luau
-- Listens for StartGameEvent RemoteEvent and fires StartGameEvent BindableEvent

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local StartGameEvent = ServerEvents.StartGameEvent
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameRemote = RemoteEvents.StartGameEvent
local ResetGameRemote = RemoteEvents.ResetGameEvent

local CONTEXT = "StartGameService"
local gameStarted = false

Log.Info(CONTEXT, "StartGameService initialized")

-- Listen for client requests to start the game
StartGameRemote.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Game start requested by %s", player.Name))
	
	if gameStarted then
		Log.Warn(CONTEXT, string.format("Game already started, ignoring request from %s", player.Name))
		return
	end
	
	gameStarted = true
	
	-- Fire the server-side BindableEvent to notify all game systems
	Log.Info(CONTEXT, "Firing StartGameEvent BindableEvent")
	StartGameEvent:Fire()
end)

-- Reset gameStarted when timer ends (game over)
TimerEndedEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game ended, ready for new game")
	gameStarted = false
end)

-- Reset gameStarted when game is manually reset
ResetGameRemote.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Game reset by %s, ready for new game", player.Name))
	gameStarted = false
end)
