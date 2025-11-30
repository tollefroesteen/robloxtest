--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TrapController = require(ServerScriptService.Server.Game.TrapController)
local ScoreService = require(ServerScriptService.Server.Game.ScoreService)

-- Ensure ResetGameEvent exists
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local ResetGameEvent = RemoteEvents.ResetGameEvent
local TimerEndedEvent = ServerEvents.TimerEndedEvent

local CONTEXT = "ResetService"

-- Optional: central score state (if you keep totals on server)
local scoreState = ServerScriptService:FindFirstChild("ScoreState")

-- Listen for client reset requests and broadcast to all clients
ResetGameEvent.OnServerEvent:Connect(function(player)
	Log.Info(CONTEXT, string.format("Game reset requested by %s", player.Name))
	
	-- TODO: validate player permissions if needed
	-- Clear server-side score state if present
	if scoreState and scoreState:IsA("Folder") then
		for _, child in ipairs(scoreState:GetChildren()) do
			child:Destroy()
		end
	end

	-- Clear per-trap captured lists and scores
	TrapController.ResetAllTraps()
	
	-- Fire TimerEndedEvent to stop the timer and spawner
	TimerEndedEvent:Fire()
	
	-- Notify all clients to reset UI/state
	ResetGameEvent:FireAllClients()
	
	Log.Info(CONTEXT, "Game reset complete")
end)
