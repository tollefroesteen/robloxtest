--!strict
-- AchievementsService.luau
-- Server-side achievements and stats tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("PlayerDataTypes"))
local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "AchievementsService"

local AchievementsService = {}

-- XP required per level (can be customized)
local XP_PER_LEVEL = 100
local XP_SCALE_FACTOR = 1.5  -- Each level requires more XP

-- In-memory storage
local playerStats: { [Player]: PlayerDataTypes.PlayerStats } = {}
local playerAchievements: { [Player]: { [string]: PlayerDataTypes.AchievementProgress } } = {}

-- Callbacks for achievement completion (other services can subscribe)
local achievementCallbacks: { (Player, string, AchievementRegistry.AchievementDefinition) -> () } = {}

-- Calculate XP needed for a level
function AchievementsService.GetXPForLevel(level: number): number
	return math.floor(XP_PER_LEVEL * (XP_SCALE_FACTOR ^ (level - 1)))
end

-- Calculate total XP needed to reach a level
function AchievementsService.GetTotalXPForLevel(level: number): number
	local total = 0
	for i = 1, level - 1 do
		total += AchievementsService.GetXPForLevel(i)
	end
	return total
end

-- Initialize stats for a player
function AchievementsService.InitPlayer(player: Player, stats: PlayerDataTypes.PlayerStats?, achievements: { [string]: PlayerDataTypes.AchievementProgress }?): nil
	playerStats[player] = stats or PlayerDataTypes.CreateDefaultStats()
	playerAchievements[player] = achievements or {}
	Log.Info(CONTEXT, string.format("Initialized stats for %s (Level %d, %d XP)", 
		player.Name, playerStats[player].Level, playerStats[player].ExperiencePoints))
end

-- Get player's stats
function AchievementsService.GetStats(player: Player): PlayerDataTypes.PlayerStats?
	return playerStats[player]
end

-- Get player's achievements
function AchievementsService.GetAchievements(player: Player): { [string]: PlayerDataTypes.AchievementProgress }?
	return playerAchievements[player]
end

-- Clean up when player leaves
function AchievementsService.CleanupPlayer(player: Player): nil
	playerStats[player] = nil
	playerAchievements[player] = nil
end

-- Subscribe to achievement completions
function AchievementsService.OnAchievementCompleted(callback: (Player, string, AchievementRegistry.AchievementDefinition) -> ()): nil
	table.insert(achievementCallbacks, callback)
end

-- Add XP and handle level ups
function AchievementsService.AddXP(player: Player, amount: number): (number, boolean)  -- Returns (newLevel, didLevelUp)
	local stats = playerStats[player]
	if not stats then return 0, false end
	
	stats.ExperiencePoints += amount
	local didLevelUp = false
	local startLevel = stats.Level
	
	-- Check for level ups
	while true do
		local xpNeeded = AchievementsService.GetTotalXPForLevel(stats.Level + 1)
		if stats.ExperiencePoints >= xpNeeded then
			stats.Level += 1
			didLevelUp = true
			Log.Info(CONTEXT, string.format("%s leveled up to %d!", player.Name, stats.Level))
			
			-- Check level achievements
			AchievementsService.UpdateProgress(player, "LEVEL_5", stats.Level)
			AchievementsService.UpdateProgress(player, "LEVEL_10", stats.Level)
			AchievementsService.UpdateProgress(player, "LEVEL_25", stats.Level)
		else
			break
		end
	end
	
	if didLevelUp then
		Log.Info(CONTEXT, string.format("%s gained %d XP (Level %d -> %d)", player.Name, amount, startLevel, stats.Level))
	end
	
	return stats.Level, didLevelUp
end

-- Update achievement progress
function AchievementsService.UpdateProgress(player: Player, achievementID: string, value: number): boolean
	local achievements = playerAchievements[player]
	if not achievements then return false end
	
	local achievementDef = AchievementRegistry.GetAchievement(achievementID)
	if not achievementDef then return false end
	
	-- Get or create progress
	local progress = achievements[achievementID]
	if not progress then
		progress = {
			ID = achievementID,
			Category = achievementDef.Category,
			CurrentValue = 0,
			TargetValue = achievementDef.TargetValue,
			Completed = false,
			CompletedAt = nil,
		}
		achievements[achievementID] = progress
	end
	
	-- Skip if already completed (unless repeatable)
	if progress.Completed and not achievementDef.Repeatable then
		return false
	end
	
	-- Update progress
	progress.CurrentValue = math.max(progress.CurrentValue, value)
	
	-- Check for completion
	if progress.CurrentValue >= achievementDef.TargetValue and not progress.Completed then
		progress.Completed = true
		progress.CompletedAt = os.time()
		
		Log.Info(CONTEXT, string.format("%s unlocked achievement: %s", player.Name, achievementDef.Name))
		
		-- Award XP
		if achievementDef.RewardXP > 0 then
			AchievementsService.AddXP(player, achievementDef.RewardXP)
		end
		
		-- Notify callbacks
		for _, callback in achievementCallbacks do
			task.spawn(callback, player, achievementID, achievementDef)
		end
		
		return true
	end
	
	return false
end

-- Increment a stat and update related achievements
function AchievementsService.IncrementStat(player: Player, statName: string, amount: number?): nil
	local stats = playerStats[player]
	if not stats then return end
	
	local increment = amount or 1
	
	-- Update the stat
	if statName == "TotalCaptures" then
		stats.TotalCaptures += increment
		AchievementsService.UpdateProgress(player, "CAPTURE_FIRST", stats.TotalCaptures)
		AchievementsService.UpdateProgress(player, "CAPTURE_10", stats.TotalCaptures)
		AchievementsService.UpdateProgress(player, "CAPTURE_50", stats.TotalCaptures)
		AchievementsService.UpdateProgress(player, "CAPTURE_100", stats.TotalCaptures)
		
	elseif statName == "TotalWins" then
		stats.TotalWins += increment
		AchievementsService.UpdateProgress(player, "WIN_FIRST", stats.TotalWins)
		AchievementsService.UpdateProgress(player, "WIN_10", stats.TotalWins)
		AchievementsService.UpdateProgress(player, "WIN_50", stats.TotalWins)
		
	elseif statName == "TotalLosses" then
		stats.TotalLosses += increment
		
	elseif statName == "TotalGamesPlayed" then
		stats.TotalGamesPlayed += increment
		AchievementsService.UpdateProgress(player, "GAMES_PLAYED_1", stats.TotalGamesPlayed)
		AchievementsService.UpdateProgress(player, "GAMES_PLAYED_25", stats.TotalGamesPlayed)
		AchievementsService.UpdateProgress(player, "GAMES_PLAYED_100", stats.TotalGamesPlayed)
		
	elseif statName == "TotalKills" then
		stats.TotalKills += increment
		
	elseif statName == "TotalDeaths" then
		stats.TotalDeaths += increment
	end
end

-- Record an animal capture
function AchievementsService.RecordAnimalCapture(player: Player, animalID: string): nil
	local stats = playerStats[player]
	if not stats then return end
	
	-- Increment total captures
	AchievementsService.IncrementStat(player, "TotalCaptures", 1)
	
	-- Update per-animal count
	stats.AnimalCaptureCount[animalID] = (stats.AnimalCaptureCount[animalID] or 0) + 1
	
	-- Update capture index (first time catching this type)
	local isFirstCatch = not stats.CapturedAnimalIndex[animalID]
	if isFirstCatch then
		stats.CapturedAnimalIndex[animalID] = true
		Log.Info(CONTEXT, string.format("%s discovered new animal: %s", player.Name, animalID))
		
		-- Check collection achievements
		if animalID == "RR01" then
			AchievementsService.UpdateProgress(player, "COLLECT_WHITE_ROVER", 1)
		elseif animalID == "BB01" then
			AchievementsService.UpdateProgress(player, "COLLECT_BLUE_BOUNCER", 1)
		elseif animalID == "YC01" then
			AchievementsService.UpdateProgress(player, "COLLECT_YELLOW_CRAWLER", 1)
		end
		
		-- Count unique animals for "catch all" achievement
		local uniqueCount = 0
		for _ in stats.CapturedAnimalIndex do
			uniqueCount += 1
		end
		AchievementsService.UpdateProgress(player, "COLLECT_ALL", uniqueCount)
	end
end

-- Check if achievement is completed
function AchievementsService.IsAchievementCompleted(player: Player, achievementID: string): boolean
	local achievements = playerAchievements[player]
	if not achievements then return false end
	
	local progress = achievements[achievementID]
	return progress and progress.Completed or false
end

-- Get achievement progress (0-1)
function AchievementsService.GetAchievementProgress(player: Player, achievementID: string): number
	local achievements = playerAchievements[player]
	if not achievements then return 0 end
	
	local progress = achievements[achievementID]
	if not progress then return 0 end
	
	return math.min(progress.CurrentValue / progress.TargetValue, 1)
end

return AchievementsService
