--!strict
-- FavoriteAnimalsService.luau (Lobby)
-- Handles favorite animal selection in the lobby
-- In the lobby, favorites can always be modified (no active game)
-- Also integrates with PetFollowService to spawn pet companions

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataTypes = require(Shared:WaitForChild("data"):WaitForChild("PlayerDataTypes"))
local AnimalLibraryModule = require(Shared:WaitForChild("data"):WaitForChild("AnimalLibraryModule"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

-- Lazy load PetFollowService to avoid circular dependency
local PetFollowService: any = nil
local function getPetFollowService()
	if not PetFollowService then
		local success, service = pcall(function()
			return require(script.Parent.PetFollowService)
		end)
		if success then
			PetFollowService = service
		end
	end
	return PetFollowService
end

-- Lazy load InventoryService (shared service)
local InventoryService: any = nil
local function getInventoryService()
	if not InventoryService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("InventoryService"))
		end)
		if success then
			InventoryService = service
		end
	end
	return InventoryService
end

-- Lazy load AchievementsService (shared service)
local AchievementsService: any = nil
local function getAchievementsService()
	if not AchievementsService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("AchievementsService"))
		end)
		if success then
			AchievementsService = service
		end
	end
	return AchievementsService
end

-- Lazy load PlayerUpgradesService (shared service)
local PlayerUpgradesService: any = nil
local function getPlayerUpgradesService()
	if not PlayerUpgradesService then
		local success, service = pcall(function()
			return require(Shared:WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
		end)
		if success then
			PlayerUpgradesService = service
		end
	end
	return PlayerUpgradesService
end

local CONTEXT = "FavoriteAnimalsService"
local MAX_FAVORITES = 3

-- Must match the arena's DataStore name
local DATA_STORE_NAME = "PlayerData_v1"

-- DataStore reference
local dataStore: DataStore? = nil

-- Local cache of player data (loaded on join)
-- Using any to avoid cross-file type resolution issues in strict mode
local playerDataCache: { [Player]: any } = {}

local FavoriteAnimalsService = {}

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
local function loadPlayerData(player: Player): any
	local key = "Player_" .. player.UserId
	local data: any = nil
	
	if dataStore then
		local success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)
		
		if success and result then
			data = result
			Log.Info(CONTEXT, string.format("Loaded data for %s", player.Name))
		elseif not success then
			Log.Warn(CONTEXT, string.format("Failed to load data for %s: %s", player.Name, tostring(result)))
		end
	end
	
	-- Start with defaults and merge loaded data to ensure all fields exist
	local defaultData = PlayerDataTypes.CreateDefaultPlayerData()
	if data then
		-- Merge loaded data over defaults (handles missing Upgrades field from old saves)
		for key, value in pairs(data) do
			defaultData[key] = value
		end
		-- Ensure Upgrades field exists (for players who saved before Upgrades existed)
		if not defaultData.Upgrades then
			defaultData.Upgrades = PlayerDataTypes.CreateDefaultUpgrades()
		end
	end
	
	return defaultData
end

-- Save player data to DataStore
local function savePlayerData(player: Player): boolean
	local data = playerDataCache[player]
	if not data then
		Log.Warn(CONTEXT, string.format("No cached data for %s to save", player.Name))
		return false
	end
	
	-- Sync upgrades from PlayerUpgradesService before saving
	local upgradesSvc = getPlayerUpgradesService()
	if upgradesSvc and upgradesSvc.GetPlayerUpgrades then
		local upgrades = upgradesSvc.GetPlayerUpgrades(player)
		if upgrades then
			data.Upgrades = upgrades
		end
	end
	
	if not dataStore then
		Log.Warn(CONTEXT, "DataStore unavailable, cannot save")
		return false
	end
	
	local key = "Player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)
	
	if success then
		Log.Info(CONTEXT, string.format("Saved data for %s", player.Name))
		return true
	else
		Log.Warn(CONTEXT, string.format("Failed to save data for %s: %s", player.Name, tostring(err)))
		return false
	end
end

-- Check if an animal has been captured by the player
local function hasPlayerCapturedAnimal(player: Player, animalID: string): boolean
	local data = playerDataCache[player]
	if not data then return false end
	
	local captureIndex = data.Stats.CapturedAnimalIndex or {}
	return captureIndex[animalID] == true
end

-- Get current favorite animals for a player
local function getFavoriteAnimals(player: Player): { [number]: string? }
	local data = playerDataCache[player]
	if not data then return {} end
	
	return data.Stats.FavoriteAnimals or {}
end

-- Sync favorites to client
function FavoriteAnimalsService.SyncFavoritesToClient(player: Player, success: boolean?, errorMsg: string?)
	local favorites = getFavoriteAnimals(player)
	-- In lobby, can always modify (no active game)
	local canModify = true
	
	RemoteEvents.FavoriteAnimalsUpdatedEvent:FireClient(player, favorites, canModify, success, errorMsg)
	
	-- Update pet companions to match favorites
	local petService = getPetFollowService()
	if petService then
		petService.UpdatePets(player, favorites)
	end
end

-- Toggle favorite animal
local function toggleFavoriteAnimal(player: Player, animalID: string)
	local data = playerDataCache[player]
	if not data then
		Log.Warn(CONTEXT, string.format("No data cached for %s", player.Name))
		FavoriteAnimalsService.SyncFavoritesToClient(player, false, "Data not loaded")
		return
	end
	
	-- Validate animal exists
	local animalInfo = AnimalLibraryModule.GetByID(animalID)
	if not animalInfo then
		Log.Warn(CONTEXT, string.format("Player %s tried to favorite invalid animal: %s", player.Name, animalID))
		FavoriteAnimalsService.SyncFavoritesToClient(player, false, "Invalid animal")
		return
	end
	
	-- Ensure FavoriteAnimals array exists
	if not data.Stats.FavoriteAnimals then
		data.Stats.FavoriteAnimals = {}
	end
	
	local favorites = data.Stats.FavoriteAnimals
	
	-- Check if already favorited
	local foundIndex = nil
	for i, id in favorites do
		if id == animalID then
			foundIndex = i
			break
		end
	end
	
	if foundIndex then
		-- Remove from favorites (no capture check needed - already in favorites)
		table.remove(favorites, foundIndex)
		Log.Info(CONTEXT, string.format("Player %s removed %s from favorites", player.Name, animalID))
	else
		-- Adding to favorites - check player has captured this animal
		if not hasPlayerCapturedAnimal(player, animalID) then
			Log.Warn(CONTEXT, string.format("Player %s tried to favorite uncaptured animal: %s", player.Name, animalID))
			FavoriteAnimalsService.SyncFavoritesToClient(player, false, "You haven't captured this animal")
			return
		end
		
		-- Check if at max
		if #favorites >= MAX_FAVORITES then
			Log.Info(CONTEXT, string.format("Player %s already has %d favorites, cannot add more", player.Name, MAX_FAVORITES))
			FavoriteAnimalsService.SyncFavoritesToClient(player, false, string.format("Maximum %d favorites allowed. Remove one first.", MAX_FAVORITES))
			return
		end
		
		-- Add to favorites
		table.insert(favorites, animalID)
		Log.Info(CONTEXT, string.format("Player %s added %s to favorites", player.Name, animalID))
	end
	
	-- Save to DataStore
	savePlayerData(player)
	
	-- Sync to client
	FavoriteAnimalsService.SyncFavoritesToClient(player, true, nil)
end

-- Initialize for a player
function FavoriteAnimalsService.InitPlayer(player: Player)
	-- Load player data into cache
	local data = loadPlayerData(player)
	playerDataCache[player] = data
	
	-- Ensure FavoriteAnimals field exists
	if not data.Stats.FavoriteAnimals then
		data.Stats.FavoriteAnimals = {}
	end
	
	-- Load upgrades into PlayerUpgradesService cache
	local upgradesSvc = getPlayerUpgradesService()
	if upgradesSvc and upgradesSvc.SetPlayerUpgrades then
		local upgrades = data.Upgrades or PlayerDataTypes.CreateDefaultUpgrades()
		upgradesSvc.SetPlayerUpgrades(player, upgrades)
		Log.Info(CONTEXT, string.format("Loaded upgrades for %s: HeatSeek=%s, Shield=%s", 
			player.Name, tostring(upgrades.HeatSeekingAmmo), tostring(upgrades.ReinforcedShield)))
	end
	
	Log.Info(CONTEXT, string.format("Initialized player %s with %d favorites", player.Name, #data.Stats.FavoriteAnimals))
	
	-- Initialize pet companions
	local petService = getPetFollowService()
	if petService then
		petService.InitPlayer(player, data.Stats.FavoriteAnimals)
	end
	
	-- Send initial sync to client
	task.defer(function()
		FavoriteAnimalsService.SyncFavoritesToClient(player, nil, nil)
	end)
end

-- Cleanup for a player (saves data before cleanup)
function FavoriteAnimalsService.CleanupPlayer(player: Player)
	-- Save any pending changes before cleanup
	savePlayerData(player)
	playerDataCache[player] = nil
	
	-- Cleanup pet companions
	local petService = getPetFollowService()
	if petService then
		petService.CleanupPlayer(player)
	end
	
	Log.Info(CONTEXT, string.format("Cleaned up player %s", player.Name))
end

-- Save player data (called by other services when they modify the cached data)
function FavoriteAnimalsService.SavePlayerData(player: Player): boolean
	return savePlayerData(player)
end

-- Get cached data for a player (used by PlayerDataLoader)
function FavoriteAnimalsService.GetPlayerData(player: Player): any
	return playerDataCache[player]
end

-- Add an animal to the player's captured index (for Lucky Blocks)
function FavoriteAnimalsService.AddAnimalToIndex(player: Player, animalID: string): boolean
	local data = playerDataCache[player]
	if not data then
		Log.Warn(CONTEXT, string.format("No data found for player %s", player.Name))
		return false
	end
	
	-- Check if already captured
	if data.Stats.CapturedAnimalIndex[animalID] then
		Log.Info(CONTEXT, string.format("Player %s already has %s in index", player.Name, animalID))
		return true
	end
	
	-- Add to captured index
	data.Stats.CapturedAnimalIndex[animalID] = true
	
	-- Increment capture count
	if not data.Stats.AnimalCaptureCount[animalID] then
		data.Stats.AnimalCaptureCount[animalID] = 0
	end
	data.Stats.AnimalCaptureCount[animalID] = data.Stats.AnimalCaptureCount[animalID] + 1
	
	-- Increment total captures
	data.Stats.TotalCaptures = data.Stats.TotalCaptures + 1
	
	Log.Info(CONTEXT, string.format("Added %s to %s's captured index", animalID, player.Name))
	
	-- Save data
	savePlayerData(player)
	
	-- Sync to client
	RemoteEvents.StatsUpdatedEvent:FireClient(player, {
		CapturedAnimalIndex = data.Stats.CapturedAnimalIndex,
		AnimalCaptureCount = data.Stats.AnimalCaptureCount,
		TotalCaptures = data.Stats.TotalCaptures,
	})
	
	return true
end

-- Get player's favorite animals (for debug commands)
function FavoriteAnimalsService.GetFavorites(player: Player): { [number]: string? }
	return getFavoriteAnimals(player)
end

-- Reset all player data to defaults (for debug commands)
function FavoriteAnimalsService.ResetPlayerData(player: Player): boolean
	local data = playerDataCache[player]
	if not data then
		Log.Warn(CONTEXT, string.format("No data found for player %s", player.Name))
		return false
	end
	
	-- Reset to default data but with empty inventory (no starting items for reset)
	local defaultData = PlayerDataTypes.CreateDefaultPlayerData()
	-- Override inventory to be completely empty
	defaultData.Inventory = {
		Items = {},
		MaxSlots = 20,
	}
	playerDataCache[player] = defaultData
	
	Log.Info(CONTEXT, string.format("Reset all player data for %s", player.Name))
	
	-- IMPORTANT: Also reset the shared service caches so they stay in sync
	local invService = getInventoryService()
	if invService and invService.ResetInventory then
		invService.ResetInventory(player)
		Log.Info(CONTEXT, "Reset InventoryService cache")
	end
	
	local achievementsSvc = getAchievementsService()
	if achievementsSvc and achievementsSvc.ResetAllStats then
		achievementsSvc.ResetAllStats(player)
		Log.Info(CONTEXT, "Reset AchievementsService cache")
	end
	
	local upgradesSvc = getPlayerUpgradesService()
	if upgradesSvc and upgradesSvc.ResetUpgrades then
		upgradesSvc.ResetUpgrades(player)
		Log.Info(CONTEXT, "Reset PlayerUpgradesService cache")
	end
	
	-- Sync favorites to client (which also updates pets)
	FavoriteAnimalsService.SyncFavoritesToClient(player, true)
	
	-- Send full stats update to client
	RemoteEvents.StatsUpdatedEvent:FireClient(player, {
		Level = defaultData.Stats.Level,
		ExperiencePoints = defaultData.Stats.ExperiencePoints,
		TotalCaptures = defaultData.Stats.TotalCaptures,
		TotalWins = defaultData.Stats.TotalWins,
		TotalLosses = defaultData.Stats.TotalLosses,
		TotalGamesPlayed = defaultData.Stats.TotalGamesPlayed,
		TotalKills = defaultData.Stats.TotalKills,
		TotalDeaths = defaultData.Stats.TotalDeaths,
		Achievements = defaultData.Achievements or {},
		CapturedAnimalIndex = defaultData.Stats.CapturedAnimalIndex or {},
		AnimalCaptureCount = defaultData.Stats.AnimalCaptureCount or {},
		FavoriteAnimals = defaultData.Stats.FavoriteAnimals or {},
	})
	
	-- Send inventory update to client
	RemoteEvents.InventoryUpdatedEvent:FireClient(player, defaultData.Inventory)
	
	-- Send upgrades update to client
	RemoteEvents.UpgradesUpdatedEvent:FireClient(player, defaultData.Upgrades)
	
	-- Save reset data to DataStore
	savePlayerData(player)
	
	return true
end

-- Remove animal from a specific favorite slot (for debug commands)
function FavoriteAnimalsService.RemoveAnimalFromSlot(player: Player, slot: number): boolean
	local data = playerDataCache[player]
	if not data then
		Log.Warn(CONTEXT, string.format("No data found for player %s", player.Name))
		return false
	end
	
	if slot < 1 or slot > MAX_FAVORITES then
		Log.Warn(CONTEXT, string.format("Invalid slot %d (must be 1-%d)", slot, MAX_FAVORITES))
		return false
	end
	
	-- Remove from favorites
	local favorites = data.Stats.FavoriteAnimals
	local animalID = favorites[slot]
	
	if not animalID then
		Log.Info(CONTEXT, string.format("Slot %d is already empty for %s", slot, player.Name))
		return false
	end
	
	favorites[slot] = nil
	
	Log.Info(CONTEXT, string.format("Removed %s from slot %d for %s", animalID, slot, player.Name))
	
	-- Sync to client
	FavoriteAnimalsService.SyncFavoritesToClient(player, true)
	
	-- Save data
	savePlayerData(player)
	
	return true
end

-- Initialize
initDataStore()

-- Register save callback with PlayerUpgradesService so upgrades are persisted
local upgradesSvc = getPlayerUpgradesService()
if upgradesSvc and upgradesSvc.SetSaveCallback then
	upgradesSvc.SetSaveCallback(function(player: Player)
		savePlayerData(player)
		Log.Info(CONTEXT, string.format("Saved player data after upgrade grant for %s", player.Name))
	end)
	Log.Info(CONTEXT, "Registered save callback with PlayerUpgradesService")
end

-- Listen for toggle requests
RemoteEvents.SetFavoriteAnimalEvent.OnServerEvent:Connect(function(player: Player, animalID: string)
	Log.Info(CONTEXT, string.format("Player %s requested to toggle favorite: %s", player.Name, animalID))
	toggleFavoriteAnimal(player, animalID)
end)

Log.Info(CONTEXT, "FavoriteAnimalsService initialized")

return FavoriteAnimalsService
