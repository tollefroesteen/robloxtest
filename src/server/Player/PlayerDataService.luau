--!strict
-- PlayerDataService.luau
-- Handles loading, saving, and persistence of player data

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("PlayerDataTypes"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerDataService"
local DATA_STORE_NAME = "PlayerData_v1"
local AUTO_SAVE_INTERVAL = 120  -- Save every 2 minutes

local PlayerDataService = {}

-- DataStore reference (will be nil in Studio if API access is disabled)
local dataStore: DataStore? = nil

-- In-memory player data
local playerData: { [Player]: PlayerDataTypes.PlayerData } = {}

-- Services that need to be notified (set after initialization)
local InventoryService: any = nil
local AchievementsService: any = nil

-- Initialize DataStore
local function initDataStore(): nil
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
			Log.Info(CONTEXT, string.format("Loaded data for %s (Level %d)", player.Name, data.Stats.Level))
		elseif not success then
			Log.Warn(CONTEXT, string.format("Failed to load data for %s: %s", player.Name, tostring(result)))
		end
	end
	
	-- Return loaded data or create new
	if data then
		-- Migration: update schema version if needed
		if data.Version < 1 then
			-- Future migrations go here
			data.Version = 1
		end
		return data
	else
		Log.Info(CONTEXT, string.format("Creating new data for %s", player.Name))
		return PlayerDataTypes.CreateDefaultPlayerData()
	end
end

-- Save player data to DataStore
local function savePlayerData(player: Player): boolean
	local data = playerData[player]
	if not data then return false end
	
	local key = "Player_" .. player.UserId
	data.LastSaved = os.time()
	
	-- Update inventory and stats from services
	if InventoryService then
		local inventory = InventoryService.GetInventory(player)
		if inventory then
			data.Inventory = inventory
		end
	end
	
	if AchievementsService then
		local stats = AchievementsService.GetStats(player)
		local achievements = AchievementsService.GetAchievements(player)
		if stats then
			data.Stats = stats
		end
		if achievements then
			data.Achievements = achievements
		end
	end
	
	if dataStore then
		local success, result = pcall(function()
			dataStore:SetAsync(key, data)
		end)
		
		if success then
			Log.Info(CONTEXT, string.format("Saved data for %s", player.Name))
			return true
		else
			Log.Warn(CONTEXT, string.format("Failed to save data for %s: %s", player.Name, tostring(result)))
			return false
		end
	else
		-- In Studio without DataStore access, just log
		Log.Info(CONTEXT, string.format("Data for %s stored in memory (DataStore unavailable)", player.Name))
		return true
	end
end

-- Set service references (called by init script)
function PlayerDataService.SetServices(inventory: any, achievements: any): nil
	InventoryService = inventory
	AchievementsService = achievements
end

-- Get player data
function PlayerDataService.GetData(player: Player): PlayerDataTypes.PlayerData?
	return playerData[player]
end

-- Force save player data
function PlayerDataService.SavePlayer(player: Player): boolean
	return savePlayerData(player)
end

-- Save all players
function PlayerDataService.SaveAll(): nil
	for player in playerData do
		savePlayerData(player)
	end
end

-- Handle player joining
function PlayerDataService.OnPlayerAdded(player: Player): nil
	-- Load data
	local data = loadPlayerData(player)
	playerData[player] = data
	
	-- Initialize services with loaded data
	if InventoryService then
		InventoryService.InitPlayer(player, data.Inventory)
	end
	
	if AchievementsService then
		AchievementsService.InitPlayer(player, data.Stats, data.Achievements)
	end
	
	Log.Info(CONTEXT, string.format("Player %s data initialized", player.Name))
end

-- Handle player leaving
function PlayerDataService.OnPlayerRemoving(player: Player): nil
	-- Save data
	savePlayerData(player)
	
	-- Cleanup services
	if InventoryService then
		InventoryService.CleanupPlayer(player)
	end
	
	if AchievementsService then
		AchievementsService.CleanupPlayer(player)
	end
	
	-- Remove from memory
	playerData[player] = nil
	
	Log.Info(CONTEXT, string.format("Player %s data cleaned up", player.Name))
end

-- Initialize the service
function PlayerDataService.Init(): nil
	initDataStore()
	
	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			PlayerDataService.SaveAll()
		end
	end)
	
	Log.Info(CONTEXT, "PlayerDataService initialized")
end

-- Handle game shutdown
function PlayerDataService.OnGameClose(): nil
	Log.Info(CONTEXT, "Game closing, saving all player data...")
	PlayerDataService.SaveAll()
end

return PlayerDataService
