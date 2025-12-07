--!strict
-- FavoriteAnimalsService.luau
-- Handles setting/getting favorite animals for players
-- Players can set up to 2 favorite animals from their captured collection
-- Favorites cannot be changed during an active game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local ServerEvents = require(ServerScriptService.Server.ServerEvents)

local CONTEXT = "FavoriteAnimalsService"
local MAX_FAVORITES = 3

local FavoriteAnimalsService = {}

-- Service references (set during initialization)
local TeamService: any = nil
local AchievementsService: any = nil

-- In-memory storage for favorite animals (keyed by Player)
local playerFavorites: { [Player]: { string } } = {}

-- Set service references (called by initialization script)
function FavoriteAnimalsService.SetServices(teamSvc: any, achievementsSvc: any): nil
	TeamService = teamSvc
	AchievementsService = achievementsSvc
	Log.Info(CONTEXT, "Services set")
end

-- Check if a player can modify their favorites (not during active game)
local function canModifyFavorites(player: Player): boolean
	if not TeamService then
		Log.Warn(CONTEXT, "TeamService not available, allowing modification")
		return true
	end
	
	-- Check if game is active
	local isGameActive = TeamService.IsGameActive()
	if isGameActive then
		Log.Info(CONTEXT, string.format("%s cannot modify favorites - game is active", player.Name))
		return false
	end
	
	return true
end

-- Check if player has captured the animal
local function hasPlayerCapturedAnimal(player: Player, animalID: string): boolean
	if not AchievementsService then
		Log.Warn(CONTEXT, "AchievementsService not available")
		return false
	end
	
	local stats = AchievementsService.GetStats(player)
	if not stats then return false end
	
	local capturedIndex = stats.CapturedAnimalIndex
	if not capturedIndex then return false end
	
	return capturedIndex[animalID] == true
end

-- Initialize player favorites (called when player joins)
function FavoriteAnimalsService.InitPlayer(player: Player, stats: any): nil
	-- Load favorites from stats
	local favorites = {}
	if stats and stats.FavoriteAnimals then
		-- Validate that favorites are still captured animals
		for _, animalID in stats.FavoriteAnimals do
			if stats.CapturedAnimalIndex and stats.CapturedAnimalIndex[animalID] then
				table.insert(favorites, animalID)
			end
		end
	end
	
	playerFavorites[player] = favorites
	Log.Info(CONTEXT, string.format("Initialized favorites for %s: %d animals", player.Name, #favorites))
	
	-- Send current favorites to client
	task.defer(function()
		FavoriteAnimalsService.SyncFavoritesToClient(player)
	end)
end

-- Cleanup when player leaves
function FavoriteAnimalsService.CleanupPlayer(player: Player): nil
	playerFavorites[player] = nil
	Log.Info(CONTEXT, string.format("Cleaned up favorites for %s", player.Name))
end

-- Get player's favorite animals
function FavoriteAnimalsService.GetFavorites(player: Player): { string }
	return playerFavorites[player] or {}
end

-- Set an animal as favorite (toggle behavior)
-- If animal is not a favorite and slots available: adds it
-- If animal is already a favorite: removes it
-- Returns success, error message, and the updated favorites list
function FavoriteAnimalsService.ToggleFavorite(player: Player, animalID: string): (boolean, string?, { string })
	local favorites = playerFavorites[player] or {}
	
	-- Check if player can modify favorites
	if not canModifyFavorites(player) then
		return false, "Cannot change favorites during an active game", favorites
	end
	
	-- Check if player has captured this animal
	if not hasPlayerCapturedAnimal(player, animalID) then
		return false, "You haven't captured this animal yet", favorites
	end
	
	-- Check if animal is already a favorite
	local existingIndex: number? = nil
	for i, id in favorites do
		if id == animalID then
			existingIndex = i
			break
		end
	end
	
	if existingIndex then
		-- Remove from favorites
		table.remove(favorites, existingIndex)
		playerFavorites[player] = favorites
		Log.Info(CONTEXT, string.format("%s removed %s from favorites", player.Name, animalID))
		
		-- Sync to AchievementsService stats
		FavoriteAnimalsService.SyncToStats(player)
		
		return true, nil, favorites
	else
		-- Check if we have room for another favorite
		if #favorites >= MAX_FAVORITES then
			return false, string.format("You can only have %d favorite animals. Remove one first.", MAX_FAVORITES), favorites
		end
		
		-- Add to favorites
		table.insert(favorites, animalID)
		playerFavorites[player] = favorites
		Log.Info(CONTEXT, string.format("%s added %s to favorites", player.Name, animalID))
		
		-- Sync to AchievementsService stats
		FavoriteAnimalsService.SyncToStats(player)
		
		return true, nil, favorites
	end
end

-- Set favorite at specific slot (0 = remove, 1-2 = set slot)
function FavoriteAnimalsService.SetFavoriteSlot(player: Player, animalID: string, slot: number): (boolean, string?, { string })
	local favorites = playerFavorites[player] or {}
	
	-- Check if player can modify favorites
	if not canModifyFavorites(player) then
		return false, "Cannot change favorites during an active game", favorites
	end
	
	-- Validate slot
	if slot < 0 or slot > MAX_FAVORITES then
		return false, "Invalid slot number", favorites
	end
	
	if slot == 0 then
		-- Remove from favorites (find and remove)
		for i, id in favorites do
			if id == animalID then
				table.remove(favorites, i)
				playerFavorites[player] = favorites
				Log.Info(CONTEXT, string.format("%s removed %s from favorites", player.Name, animalID))
				FavoriteAnimalsService.SyncToStats(player)
				return true, nil, favorites
			end
		end
		return false, "Animal is not a favorite", favorites
	end
	
	-- Check if player has captured this animal
	if not hasPlayerCapturedAnimal(player, animalID) then
		return false, "You haven't captured this animal yet", favorites
	end
	
	-- Check if animal is already a favorite in another slot
	for i, id in favorites do
		if id == animalID then
			-- Already a favorite, just return success
			return true, nil, favorites
		end
	end
	
	-- Check if we have room
	if #favorites >= MAX_FAVORITES then
		return false, string.format("You can only have %d favorite animals", MAX_FAVORITES), favorites
	end
	
	-- Add to favorites
	table.insert(favorites, animalID)
	playerFavorites[player] = favorites
	Log.Info(CONTEXT, string.format("%s added %s to favorites", player.Name, animalID))
	
	FavoriteAnimalsService.SyncToStats(player)
	return true, nil, favorites
end

-- Sync favorites to client
function FavoriteAnimalsService.SyncFavoritesToClient(player: Player): nil
	local favorites = playerFavorites[player] or {}
	local canModify = canModifyFavorites(player)
	
	RemoteEvents.FavoriteAnimalsUpdatedEvent:FireClient(player, favorites, canModify)
end

-- Sync favorites to player stats (for persistence)
function FavoriteAnimalsService.SyncToStats(player: Player): nil
	if not AchievementsService then return end
	
	local stats = AchievementsService.GetStats(player)
	if stats then
		stats.FavoriteAnimals = playerFavorites[player] or {}
	end
	
	-- Also sync to client
	FavoriteAnimalsService.SyncFavoritesToClient(player)
end

-- Broadcast favorites status to all players (e.g., when game state changes)
function FavoriteAnimalsService.BroadcastCanModifyStatus(): nil
	for player in playerFavorites do
		FavoriteAnimalsService.SyncFavoritesToClient(player)
	end
end

-- Initialize the service
function FavoriteAnimalsService.Init(): nil
	-- Listen for client requests to set favorites
	RemoteEvents.SetFavoriteAnimalEvent.OnServerEvent:Connect(function(player: Player, animalID: string, action: string?)
		if type(animalID) ~= "string" then
			Log.Warn(CONTEXT, string.format("Invalid animalID from %s", player.Name))
			return
		end
		
		local success, errorMsg, favorites = FavoriteAnimalsService.ToggleFavorite(player, animalID)
		
		-- Send result back to client
		local canModify = canModifyFavorites(player)
		RemoteEvents.FavoriteAnimalsUpdatedEvent:FireClient(player, favorites, canModify, success, errorMsg)
	end)
	
	-- Listen for game start to lock favorites
	ServerEvents.StartGameEvent.Event:Connect(function()
		Log.Info(CONTEXT, "Game started - broadcasting favorites locked status")
		task.defer(function()
			FavoriteAnimalsService.BroadcastCanModifyStatus()
		end)
	end)
	
	-- Listen for game end to unlock favorites
	ServerEvents.GameEndProcessedEvent.Event:Connect(function()
		Log.Info(CONTEXT, "Game ended - broadcasting favorites unlocked status")
		task.defer(function()
			FavoriteAnimalsService.BroadcastCanModifyStatus()
		end)
	end)
	
	Log.Info(CONTEXT, "FavoriteAnimalsService initialized")
end

return FavoriteAnimalsService
