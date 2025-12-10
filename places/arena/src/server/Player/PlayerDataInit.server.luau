--!strict
-- PlayerDataInit.server.luau
-- Initializes player data systems and connects events

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Player.PlayerDataService)
local AchievementsService = require(ServerScriptService.Server.Player.AchievementsService)
local FavoriteAnimalsService = require(ServerScriptService.Server.Player.FavoriteAnimalsService)
local TeamService = require(ServerScriptService.Server.Game.TeamService)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InventoryService = require(Shared:WaitForChild("services"):WaitForChild("InventoryService"))
local PlayerUpgradesService = require(Shared:WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerDataInit"

-- Connect services
PlayerDataService.SetServices(InventoryService, AchievementsService)
FavoriteAnimalsService.SetServices(TeamService, AchievementsService)

-- Initialize services
PlayerDataService.Init()
FavoriteAnimalsService.Init()

-- Handle players joining
Players.PlayerAdded:Connect(function(player)
	PlayerDataService.OnPlayerAdded(player)
	
	-- Initialize favorite animals from loaded stats
	local stats = AchievementsService.GetStats(player)
	if stats then
		FavoriteAnimalsService.InitPlayer(player, stats)
	end
	
	-- Send initial data to client after a brief delay
	task.delay(1, function()
		local inventory = InventoryService.GetInventory(player)
		if inventory then
			RemoteEvents.InventoryUpdatedEvent:FireClient(player, inventory)
			Log.Info(CONTEXT, string.format("Sent initial inventory to %s", player.Name))
		end
		
		-- Send initial upgrades
		local upgrades = PlayerUpgradesService.GetPlayerUpgrades(player)
		if upgrades then
			RemoteEvents.UpgradesUpdatedEvent:FireClient(player, upgrades)
			Log.Info(CONTEXT, string.format("Sent initial upgrades to %s", player.Name))
		end
		
		-- Send stats WITH achievements included
		local currentStats = AchievementsService.GetStats(player)
		local achievements = AchievementsService.GetAchievements(player)
		local favorites = FavoriteAnimalsService.GetFavorites(player)
		if currentStats then
			local payload = {
				Level = currentStats.Level,
				ExperiencePoints = currentStats.ExperiencePoints,
				TotalCaptures = currentStats.TotalCaptures,
				TotalWins = currentStats.TotalWins,
				TotalLosses = currentStats.TotalLosses,
				TotalGamesPlayed = currentStats.TotalGamesPlayed,
				TotalKills = currentStats.TotalKills,
				TotalDeaths = currentStats.TotalDeaths,
				CapturedAnimalIndex = currentStats.CapturedAnimalIndex,
				AnimalCaptureCount = currentStats.AnimalCaptureCount,
				FavoriteAnimals = favorites,
				Achievements = achievements or {},
			}
			RemoteEvents.StatsUpdatedEvent:FireClient(player, payload)
			Log.Info(CONTEXT, string.format("Sent initial stats and achievements to %s", player.Name))
		end
	end)
end)

-- Handle players already in game (in case script loads late)
for _, player in Players:GetPlayers() do
	task.spawn(function()
		PlayerDataService.OnPlayerAdded(player)
		
		-- Initialize favorite animals from loaded stats
		local stats = AchievementsService.GetStats(player)
		if stats then
			FavoriteAnimalsService.InitPlayer(player, stats)
		end
		
		-- Send initial data
		task.delay(1, function()
			local inventory = InventoryService.GetInventory(player)
			if inventory then
				RemoteEvents.InventoryUpdatedEvent:FireClient(player, inventory)
			end
			
			-- Send initial upgrades
			local upgrades = PlayerUpgradesService.GetPlayerUpgrades(player)
			if upgrades then
				RemoteEvents.UpgradesUpdatedEvent:FireClient(player, upgrades)
			end
			
			-- Send stats WITH achievements included
			local currentStats = AchievementsService.GetStats(player)
			local achievements = AchievementsService.GetAchievements(player)
			local favorites = FavoriteAnimalsService.GetFavorites(player)
			if currentStats then
				local payload = {
					Level = currentStats.Level,
					ExperiencePoints = currentStats.ExperiencePoints,
					TotalCaptures = currentStats.TotalCaptures,
					TotalWins = currentStats.TotalWins,
					TotalLosses = currentStats.TotalLosses,
					TotalGamesPlayed = currentStats.TotalGamesPlayed,
					TotalKills = currentStats.TotalKills,
					TotalDeaths = currentStats.TotalDeaths,
					CapturedAnimalIndex = currentStats.CapturedAnimalIndex,
					AnimalCaptureCount = currentStats.AnimalCaptureCount,
					FavoriteAnimals = favorites,
					Achievements = achievements or {},
				}
				RemoteEvents.StatsUpdatedEvent:FireClient(player, payload)
			end
		end)
	end)
end

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
	FavoriteAnimalsService.CleanupPlayer(player)
	PlayerDataService.OnPlayerRemoving(player)
end)

-- Handle client requesting player data refresh (e.g., when opening player menu)
RemoteEvents.RequestPlayerDataEvent.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Player data requested by %s", player.Name))
	
	-- Send inventory
	local inventory = InventoryService.GetInventory(player)
	if inventory then
		RemoteEvents.InventoryUpdatedEvent:FireClient(player, inventory)
	end
	
	-- Send upgrades
	local upgrades = PlayerUpgradesService.GetPlayerUpgrades(player)
	if upgrades then
		RemoteEvents.UpgradesUpdatedEvent:FireClient(player, upgrades)
	end
	
	-- Send stats with achievements
	local currentStats = AchievementsService.GetStats(player)
	local achievements = AchievementsService.GetAchievements(player)
	local favorites = FavoriteAnimalsService.GetFavorites(player)
	if currentStats then
		local payload = {
			Level = currentStats.Level,
			ExperiencePoints = currentStats.ExperiencePoints,
			TotalCaptures = currentStats.TotalCaptures,
			TotalWins = currentStats.TotalWins,
			TotalLosses = currentStats.TotalLosses,
			TotalGamesPlayed = currentStats.TotalGamesPlayed,
			TotalKills = currentStats.TotalKills,
			TotalDeaths = currentStats.TotalDeaths,
			CapturedAnimalIndex = currentStats.CapturedAnimalIndex,
			AnimalCaptureCount = currentStats.AnimalCaptureCount,
			FavoriteAnimals = favorites,
			Achievements = achievements or {},
		}
		RemoteEvents.StatsUpdatedEvent:FireClient(player, payload)
	end
end)

-- Handle game shutdown
game:BindToClose(function()
	PlayerDataService.OnGameClose()
end)

-- Subscribe to achievement completions to award item rewards
AchievementsService.OnAchievementCompleted(function(player, achievementID, achievementDef)
	-- Award item rewards if any
	if achievementDef.RewardItems then
		for itemID, quantity in achievementDef.RewardItems do
			local success, message = InventoryService.AddItem(player, itemID, quantity)
			if success then
				Log.Info(CONTEXT, string.format("%s received reward: %dx %s", player.Name, quantity, itemID))
			else
				Log.Warn(CONTEXT, string.format("Failed to award %s to %s: %s", itemID, player.Name, message))
			end
		end
	end
	
	-- Note: AchievementUnlockedEvent is already fired by AchievementsService.UpdateProgress()
	-- so we don't fire it again here to avoid duplicate notifications
end)

Log.Info(CONTEXT, "Player data systems initialized")
