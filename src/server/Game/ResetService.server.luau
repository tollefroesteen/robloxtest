--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TrapController = require(ServerScriptService.Server.Game.TrapController)

-- Ensure ResetGameEvent exists
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ResetGameEvent = RemoteEvents.ResetGameEvent

-- Optional: central score state (if you keep totals on server)
local scoreState = ServerScriptService:FindFirstChild("ScoreState")

-- Listen for client reset requests and broadcast to all clients
ResetGameEvent.OnServerEvent:Connect(function(player)
	-- TODO: validate player permissions if needed
	-- Clear server-side score state if present
	if scoreState and scoreState:IsA("Folder") then
		for _, child in ipairs(scoreState:GetChildren()) do
			child:Destroy()
		end
	end

	-- Clear per-trap captured lists and scores
	TrapController.ResetAllTraps()
	
	-- Notify all clients to reset UI/state
	ResetGameEvent:FireAllClients()
end)
