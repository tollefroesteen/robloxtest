--!strict
-- MainServer.server.luau (Lobby)
-- Main entry point for lobby server-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local CONTEXT = "LobbyServer"

-- Arena place ID (set this to your arena place ID)
local ARENA_PLACE_ID = 0  -- TODO: Set your arena place ID here

Log.Info(CONTEXT, "Lobby server starting...")

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	Log.Info(CONTEXT, string.format("Player %s joined the lobby", player.Name))
	
	-- TODO: Load player data for display (stats, inventory preview)
	-- TODO: Set up matchmaking queue
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	Log.Info(CONTEXT, string.format("Player %s left the lobby", player.Name))
	
	-- TODO: Remove from matchmaking queue
end)

-- Teleport player to arena
local function teleportToArena(player: Player)
	if ARENA_PLACE_ID == 0 then
		Log.Warn(CONTEXT, "Arena place ID not configured!")
		return
	end
	
	local success, err = pcall(function()
		TeleportService:Teleport(ARENA_PLACE_ID, player)
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to teleport %s: %s", player.Name, tostring(err)))
	end
end

-- Listen for play requests
RemoteEvents.PlayRequestEvent.OnServerEvent:Connect(function(player)
	Log.Info(CONTEXT, string.format("%s requested to play", player.Name))
	teleportToArena(player)
end)

Log.Info(CONTEXT, "Lobby server initialized")
