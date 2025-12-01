--!strict
-- AchievementRegistry.luau
-- Central registry of all achievements in the game
-- Add new achievements here to make them trackable

local AchievementRegistry = {}

export type AchievementDefinition = {
	ID: string,
	Name: string,
	Description: string,
	Category: string,
	TargetValue: number,      -- Value needed to complete
	RewardXP: number,         -- XP awarded on completion
	RewardItems: { [string]: number }?,  -- Optional item rewards (itemID -> quantity)
	Hidden: boolean,          -- Hidden until unlocked?
	Repeatable: boolean,      -- Can be completed multiple times?
}

-- Achievement categories
AchievementRegistry.Categories = {
	Capture = "Capture",
	Combat = "Combat",
	Exploration = "Exploration",
	Social = "Social",
	Milestones = "Milestones",
	Collection = "Collection",
}

-- All achievement definitions
AchievementRegistry.Achievements: { [string]: AchievementDefinition } = {
	-- Capture achievements
	CAPTURE_FIRST = {
		ID = "CAPTURE_FIRST",
		Name = "First Catch",
		Description = "Capture your first animal",
		Category = "Capture",
		TargetValue = 1,
		RewardXP = 50,
		Hidden = false,
		Repeatable = false,
	},
	CAPTURE_10 = {
		ID = "CAPTURE_10",
		Name = "Novice Catcher",
		Description = "Capture 10 animals",
		Category = "Capture",
		TargetValue = 10,
		RewardXP = 100,
		Hidden = false,
		Repeatable = false,
	},
	CAPTURE_50 = {
		ID = "CAPTURE_50",
		Name = "Expert Catcher",
		Description = "Capture 50 animals",
		Category = "Capture",
		TargetValue = 50,
		RewardXP = 250,
		Hidden = false,
		Repeatable = false,
	},
	CAPTURE_100 = {
		ID = "CAPTURE_100",
		Name = "Master Catcher",
		Description = "Capture 100 animals",
		Category = "Capture",
		TargetValue = 100,
		RewardXP = 500,
		Hidden = false,
		Repeatable = false,
	},
	
	-- Collection achievements (capture each type at least once)
	COLLECT_WHITE_ROVER = {
		ID = "COLLECT_WHITE_ROVER",
		Name = "White Rover Found",
		Description = "Capture a White Rover",
		Category = "Collection",
		TargetValue = 1,
		RewardXP = 25,
		Hidden = false,
		Repeatable = false,
	},
	COLLECT_BLUE_BOUNCER = {
		ID = "COLLECT_BLUE_BOUNCER",
		Name = "Blue Bouncer Found",
		Description = "Capture a Blue Bouncer",
		Category = "Collection",
		TargetValue = 1,
		RewardXP = 50,
		Hidden = false,
		Repeatable = false,
	},
	COLLECT_YELLOW_CRAWLER = {
		ID = "COLLECT_YELLOW_CRAWLER",
		Name = "Yellow Crawler Found",
		Description = "Capture a Yellow Crawler",
		Category = "Collection",
		TargetValue = 1,
		RewardXP = 75,
		Hidden = false,
		Repeatable = false,
	},
	COLLECT_ALL = {
		ID = "COLLECT_ALL",
		Name = "Gotta Catch 'Em All",
		Description = "Capture every type of animal at least once",
		Category = "Collection",
		TargetValue = 3,  -- Update this when adding new animals
		RewardXP = 500,
		RewardItems = { TOOL_TRAP = 5 },
		Hidden = true,
		Repeatable = false,
	},
	
	-- Win achievements
	WIN_FIRST = {
		ID = "WIN_FIRST",
		Name = "Victory!",
		Description = "Win your first game",
		Category = "Milestones",
		TargetValue = 1,
		RewardXP = 100,
		Hidden = false,
		Repeatable = false,
	},
	WIN_10 = {
		ID = "WIN_10",
		Name = "Winning Streak",
		Description = "Win 10 games",
		Category = "Milestones",
		TargetValue = 10,
		RewardXP = 300,
		Hidden = false,
		Repeatable = false,
	},
	WIN_50 = {
		ID = "WIN_50",
		Name = "Champion",
		Description = "Win 50 games",
		Category = "Milestones",
		TargetValue = 50,
		RewardXP = 1000,
		Hidden = false,
		Repeatable = false,
	},
	
	-- Games played
	GAMES_PLAYED_1 = {
		ID = "GAMES_PLAYED_1",
		Name = "Getting Started",
		Description = "Play your first game",
		Category = "Milestones",
		TargetValue = 1,
		RewardXP = 25,
		Hidden = false,
		Repeatable = false,
	},
	GAMES_PLAYED_25 = {
		ID = "GAMES_PLAYED_25",
		Name = "Regular Player",
		Description = "Play 25 games",
		Category = "Milestones",
		TargetValue = 25,
		RewardXP = 200,
		Hidden = false,
		Repeatable = false,
	},
	GAMES_PLAYED_100 = {
		ID = "GAMES_PLAYED_100",
		Name = "Dedicated",
		Description = "Play 100 games",
		Category = "Milestones",
		TargetValue = 100,
		RewardXP = 500,
		Hidden = false,
		Repeatable = false,
	},
	
	-- Level achievements
	LEVEL_5 = {
		ID = "LEVEL_5",
		Name = "Rising Star",
		Description = "Reach level 5",
		Category = "Milestones",
		TargetValue = 5,
		RewardXP = 0,  -- No XP to avoid infinite loop
		RewardItems = { AMMO_BASIC = 50 },
		Hidden = false,
		Repeatable = false,
	},
	LEVEL_10 = {
		ID = "LEVEL_10",
		Name = "Experienced",
		Description = "Reach level 10",
		Category = "Milestones",
		TargetValue = 10,
		RewardXP = 0,
		RewardItems = { AMMO_TRANQ = 25 },
		Hidden = false,
		Repeatable = false,
	},
	LEVEL_25 = {
		ID = "LEVEL_25",
		Name = "Veteran",
		Description = "Reach level 25",
		Category = "Milestones",
		TargetValue = 25,
		RewardXP = 0,
		RewardItems = { TOOL_TRAP = 3 },
		Hidden = false,
		Repeatable = false,
	},
}

-- Get achievement definition by ID
function AchievementRegistry.GetAchievement(achievementID: string): AchievementDefinition?
	return AchievementRegistry.Achievements[achievementID]
end

-- Get all achievements in a category
function AchievementRegistry.GetAchievementsByCategory(category: string): { AchievementDefinition }
	local result = {}
	for _, achievement in AchievementRegistry.Achievements do
		if achievement.Category == category then
			table.insert(result, achievement)
		end
	end
	return result
end

-- Get all achievement IDs
function AchievementRegistry.GetAllIDs(): { string }
	local ids = {}
	for id in AchievementRegistry.Achievements do
		table.insert(ids, id)
	end
	return ids
end

return AchievementRegistry
