--!strict
-- PlayerDataInit.server.luau
-- Initializes player data systems and connects events

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Server.Player.PlayerDataService)
local InventoryService = require(ServerScriptService.Server.Player.InventoryService)
local AchievementsService = require(ServerScriptService.Server.Player.AchievementsService)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerDataInit"

-- Connect services
PlayerDataService.SetServices(InventoryService, AchievementsService)

-- Initialize PlayerDataService
PlayerDataService.Init()

-- Handle players joining
Players.PlayerAdded:Connect(function(player)
	PlayerDataService.OnPlayerAdded(player)
	
	-- Send initial data to client after a brief delay
	task.delay(1, function()
		local inventory = InventoryService.GetInventory(player)
		if inventory then
			RemoteEvents.InventoryUpdatedEvent:FireClient(player, inventory)
			Log.Info(CONTEXT, string.format("Sent initial inventory to %s", player.Name))
		end
		
		-- Send stats WITH achievements included
		local stats = AchievementsService.GetStats(player)
		local achievements = AchievementsService.GetAchievements(player)
		if stats then
			local payload = {
				Level = stats.Level,
				ExperiencePoints = stats.ExperiencePoints,
				TotalCaptures = stats.TotalCaptures,
				TotalWins = stats.TotalWins,
				TotalLosses = stats.TotalLosses,
				TotalGamesPlayed = stats.TotalGamesPlayed,
				TotalKills = stats.TotalKills,
				TotalDeaths = stats.TotalDeaths,
				CapturedAnimalIndex = stats.CapturedAnimalIndex,
				AnimalCaptureCount = stats.AnimalCaptureCount,
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
		
		-- Send initial data
		task.delay(1, function()
			local inventory = InventoryService.GetInventory(player)
			if inventory then
				RemoteEvents.InventoryUpdatedEvent:FireClient(player, inventory)
			end
			
			-- Send stats WITH achievements included
			local stats = AchievementsService.GetStats(player)
			local achievements = AchievementsService.GetAchievements(player)
			if stats then
				local payload = {
					Level = stats.Level,
					ExperiencePoints = stats.ExperiencePoints,
					TotalCaptures = stats.TotalCaptures,
					TotalWins = stats.TotalWins,
					TotalLosses = stats.TotalLosses,
					TotalGamesPlayed = stats.TotalGamesPlayed,
					TotalKills = stats.TotalKills,
					TotalDeaths = stats.TotalDeaths,
					CapturedAnimalIndex = stats.CapturedAnimalIndex,
					AnimalCaptureCount = stats.AnimalCaptureCount,
					Achievements = achievements or {},
				}
				RemoteEvents.StatsUpdatedEvent:FireClient(player, payload)
			end
		end)
	end)
end

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.OnPlayerRemoving(player)
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
	
	-- Notify client of achievement unlock
	RemoteEvents.AchievementUnlockedEvent:FireClient(player, achievementID, achievementDef.Name)
end)

Log.Info(CONTEXT, "Player data systems initialized")
