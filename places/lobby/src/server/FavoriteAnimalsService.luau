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
	
	return data or PlayerDataTypes.CreateDefaultPlayerData()
end

-- Save player data to DataStore
local function savePlayerData(player: Player): boolean
	local data = playerDataCache[player]
	if not data then
		Log.Warn(CONTEXT, string.format("No cached data for %s to save", player.Name))
		return false
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

-- Listen for toggle requests
RemoteEvents.SetFavoriteAnimalEvent.OnServerEvent:Connect(function(player: Player, animalID: string)
	Log.Info(CONTEXT, string.format("Player %s requested to toggle favorite: %s", player.Name, animalID))
	toggleFavoriteAnimal(player, animalID)
end)

Log.Info(CONTEXT, "FavoriteAnimalsService initialized")

return FavoriteAnimalsService
