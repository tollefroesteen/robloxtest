--!strict
-- PlayerDataLoader.server.luau (Lobby)
-- Loads player data for display in lobby (read-only, no modifications)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataTypes = require(Shared:WaitForChild("data"):WaitForChild("PlayerDataTypes"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerDataLoader"

-- Load player data for display
local function loadPlayerDataForDisplay(player: Player)
	-- TODO: Load from DataStore (same key as arena uses)
	-- For now, send default data
	local defaultData = PlayerDataTypes.CreateDefaultPlayerData()
	
	-- Send to client for UI display
	RemoteEvents.StatsUpdatedEvent:FireClient(player, {
		Level = defaultData.Stats.Level,
		ExperiencePoints = defaultData.Stats.ExperiencePoints,
		TotalCaptures = defaultData.Stats.TotalCaptures,
		TotalWins = defaultData.Stats.TotalWins,
		TotalGamesPlayed = defaultData.Stats.TotalGamesPlayed,
	})
	
	RemoteEvents.InventoryUpdatedEvent:FireClient(player, defaultData.Inventory)
	
	Log.Info(CONTEXT, string.format("Loaded display data for %s", player.Name))
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayerDataForDisplay, player)
end)

-- Handle players already in game
for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerDataForDisplay, player)
end

Log.Info(CONTEXT, "PlayerDataLoader initialized")
