--!strict
-- PlayerDataTypes.luau
-- Shared type definitions for player data systems

export type InventoryItem = {
	ID: string,           -- Unique item identifier (e.g., "AMMO_BASIC", "FOOD_APPLE")
	Category: string,     -- Category for organization (e.g., "Ammo", "Food", "Tools")
	Quantity: number,     -- Current amount
	MaxStack: number?,    -- Optional max stack size (nil = unlimited)
}

export type Inventory = {
	Items: { [string]: InventoryItem },  -- Keyed by item ID for fast lookup
	MaxSlots: number?,                    -- Optional inventory size limit
}

export type AchievementProgress = {
	ID: string,              -- Unique achievement ID
	Category: string,        -- Category (e.g., "Capture", "Combat", "Exploration")
	CurrentValue: number,    -- Current progress value
	TargetValue: number,     -- Value needed to complete
	Completed: boolean,      -- Whether achievement is unlocked
	CompletedAt: number?,    -- Timestamp when completed (os.time())
}

export type PlayerStats = {
	-- Lifetime stats
	TotalCaptures: number,
	TotalKills: number,
	TotalDeaths: number,
	TotalWins: number,
	TotalLosses: number,
	TotalGamesPlayed: number,
	TotalPlayTime: number,    -- In seconds
	
	-- Experience system
	ExperiencePoints: number,
	Level: number,
	
	-- Animal capture index (which animals have been captured at least once)
	CapturedAnimalIndex: { [string]: boolean },  -- Keyed by animal ID
	
	-- Per-animal capture counts
	AnimalCaptureCount: { [string]: number },    -- Keyed by animal ID
}

export type PlayerData = {
	Version: number,          -- Schema version for migrations
	Inventory: Inventory,
	Stats: PlayerStats,
	Achievements: { [string]: AchievementProgress },
	LastSaved: number,        -- Timestamp
}

-- Default values for new players
local PlayerDataTypes = {}

function PlayerDataTypes.CreateDefaultInventory(): Inventory
	return {
		Items = {},
		MaxSlots = 20,
	}
end

function PlayerDataTypes.CreateDefaultStats(): PlayerStats
	return {
		TotalCaptures = 0,
		TotalKills = 0,
		TotalDeaths = 0,
		TotalWins = 0,
		TotalLosses = 0,
		TotalGamesPlayed = 0,
		TotalPlayTime = 0,
		ExperiencePoints = 0,
		Level = 1,
		CapturedAnimalIndex = {},
		AnimalCaptureCount = {},
	}
end

function PlayerDataTypes.CreateDefaultPlayerData(): PlayerData
	return {
		Version = 1,
		Inventory = PlayerDataTypes.CreateDefaultInventory(),
		Stats = PlayerDataTypes.CreateDefaultStats(),
		Achievements = {},
		LastSaved = 0,
	}
end

return PlayerDataTypes
