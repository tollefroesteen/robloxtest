--!strict
-- PlayerDataLoader.server.luau (Lobby)
-- Loads player data for display in lobby (read-only, no modifications)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataTypes = require(Shared:WaitForChild("data"):WaitForChild("PlayerDataTypes"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerDataLoader"

-- Must match the arena's DataStore name!
local DATA_STORE_NAME = "PlayerData_v1"

-- DataStore reference
local dataStore: DataStore? = nil

-- Initialize DataStore
local function initDataStore()
	local success, result = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	
	if success then
		dataStore = result
		Log.Info(CONTEXT, "DataStore initialized")
	else
		Log.Warn(CONTEXT, "DataStore unavailable (Studio mode?): " .. tostring(result))
	end
end

-- Load player data from DataStore
local function loadPlayerData(player: Player): PlayerDataTypes.PlayerData
	local key = "Player_" .. player.UserId
	local data: PlayerDataTypes.PlayerData? = nil
	
	if dataStore then
		local success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)
		
		if success and result then
			data = result :: PlayerDataTypes.PlayerData
			Log.Info(CONTEXT, string.format("Loaded data for %s (Level %d, %d XP)", 
				player.Name, data.Stats.Level, data.Stats.ExperiencePoints))
		elseif not success then
			Log.Warn(CONTEXT, string.format("Failed to load data for %s: %s", player.Name, tostring(result)))
		else
			Log.Info(CONTEXT, string.format("No existing data for %s, using defaults", player.Name))
		end
	else
		Log.Warn(CONTEXT, "DataStore not available, using default data")
	end
	
	-- Return loaded data or create default
	return data or PlayerDataTypes.CreateDefaultPlayerData()
end

-- Load and send player data to client for display
local function loadPlayerDataForDisplay(player: Player)
	local data = loadPlayerData(player)
	
	-- Send stats to client for UI display
	RemoteEvents.StatsUpdatedEvent:FireClient(player, {
		Level = data.Stats.Level,
		ExperiencePoints = data.Stats.ExperiencePoints,
		TotalCaptures = data.Stats.TotalCaptures,
		TotalWins = data.Stats.TotalWins,
		TotalLosses = data.Stats.TotalLosses,
		TotalGamesPlayed = data.Stats.TotalGamesPlayed,
		TotalKills = data.Stats.TotalKills,
		TotalDeaths = data.Stats.TotalDeaths,
		Achievements = data.Achievements or {},
	})
	
	-- Send inventory to client
	RemoteEvents.InventoryUpdatedEvent:FireClient(player, data.Inventory)
	
	Log.Info(CONTEXT, string.format("Sent display data to %s", player.Name))
end

-- Initialize DataStore on startup
initDataStore()

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayerDataForDisplay, player)
end)

-- Handle players already in game
for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerDataForDisplay, player)
end

Log.Info(CONTEXT, "PlayerDataLoader initialized")
