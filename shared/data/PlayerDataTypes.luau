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
	
	-- Favorite animals (up to 2, selected from captured animals)
	FavoriteAnimals: { string },  -- Array of animal IDs (max 2)
}

export type PlayerUpgrades = {
	HeatSeekingAmmo: boolean,
	ReinforcedShield: boolean,
}

export type PlayerData = {
	Version: number,          -- Schema version for migrations
	Inventory: Inventory,
	Stats: PlayerStats,
	Achievements: { [string]: AchievementProgress },
	Upgrades: PlayerUpgrades, -- Permanent upgrades (Robux purchases)
	LastSaved: number,        -- Timestamp
}

-- Default values for new players
local PlayerDataTypes = {}

function PlayerDataTypes.CreateDefaultInventory(): Inventory
	return {
		Items = {
			AMMO_BASIC = 50,    -- Starting ammo
			FOOD_BAIT = 10,     -- Starting bait
		},
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
		FavoriteAnimals = {},
	}
end

function PlayerDataTypes.CreateDefaultUpgrades(): PlayerUpgrades
	return {
		HeatSeekingAmmo = false,
		ReinforcedShield = false,
	}
end

function PlayerDataTypes.CreateDefaultPlayerData(): PlayerData
	return {
		Version = 1,
		Inventory = PlayerDataTypes.CreateDefaultInventory(),
		Stats = PlayerDataTypes.CreateDefaultStats(),
		Achievements = {},
		Upgrades = PlayerDataTypes.CreateDefaultUpgrades(),
		LastSaved = 0,
	}
end

return PlayerDataTypes
