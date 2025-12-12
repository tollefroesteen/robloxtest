--!strict
-- PlayerDataLoader.server.luau (Lobby)
-- Loads player data for display in lobby and handles favorite animal modifications

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")
local FavoriteAnimalsService = require(Server:WaitForChild("FavoriteAnimalsService"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InventoryService = require(Shared:WaitForChild("services"):WaitForChild("InventoryService"))
local AchievementsService = require(Shared:WaitForChild("services"):WaitForChild("AchievementsService"))
local PlayerUpgradesService = require(Shared:WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerDataLoader"

-- Send player data to client for display
local function sendPlayerDataToClient(player: Player)
	-- Get data from FavoriteAnimalsService (which loads and caches it)
	local data = FavoriteAnimalsService.GetPlayerData(player)
	if not data then
		Log.Warn(CONTEXT, string.format("No data available for %s", player.Name))
		return
	end
	
	-- Send stats to client for UI display (includes animal data for PlayerMenu)
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
		-- Animal data for PlayerMenu favorites feature
		CapturedAnimalIndex = data.Stats.CapturedAnimalIndex or {},
		AnimalCaptureCount = data.Stats.AnimalCaptureCount or {},
		FavoriteAnimals = data.Stats.FavoriteAnimals or {},
	})
	
	-- Send inventory to client
	RemoteEvents.InventoryUpdatedEvent:FireClient(player, data.Inventory)
	
	-- Send upgrades to client
	local upgrades = PlayerUpgradesService.GetPlayerUpgrades(player)
	if upgrades then
		RemoteEvents.UpgradesUpdatedEvent:FireClient(player, upgrades)
	end
	
	Log.Info(CONTEXT, string.format("Sent display data to %s", player.Name))
end

-- Player joined
local function onPlayerAdded(player: Player)
	-- Initialize player in FavoriteAnimalsService (loads data)
	FavoriteAnimalsService.InitPlayer(player)
	
	-- Small delay to ensure data is loaded
	task.wait(0.1)
	
	-- Initialize services with the loaded data
	local data = FavoriteAnimalsService.GetPlayerData(player)
	if data then
		InventoryService.InitPlayer(player, data.Inventory)
		AchievementsService.InitPlayer(player, data.Stats, data.Achievements)
	end
	
	-- Send data to client
	sendPlayerDataToClient(player)
end

-- Player leaving
local function onPlayerRemoving(player: Player)
	-- Save changes back to player data before cleanup
	local inventory = InventoryService.GetInventory(player)
	local stats = AchievementsService.GetStats(player)
	local achievements = AchievementsService.GetAchievements(player)
	local data = FavoriteAnimalsService.GetPlayerData(player)
	
	if data then
		if inventory then
			data.Inventory = inventory
		end
		if stats then
			data.Stats = stats
		end
		if achievements then
			data.Achievements = achievements
		end
	end
	
	InventoryService.CleanupPlayer(player)
	AchievementsService.CleanupPlayer(player)
	FavoriteAnimalsService.CleanupPlayer(player)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle client requesting player data refresh (e.g., when opening player menu)
RemoteEvents.RequestPlayerDataEvent.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Player data requested by %s", player.Name))
	sendPlayerDataToClient(player)
end)

-- Handle players already in game
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Log.Info(CONTEXT, "PlayerDataLoader initialized")
