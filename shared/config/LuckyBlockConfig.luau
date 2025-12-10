--!strict
-- LuckyBlockConfig.luau
-- Configuration for Lucky Block system

local Shared = script.Parent.Parent
local LuckyBlockTypes = require(Shared:WaitForChild("data"):WaitForChild("LuckyBlockTypes"))

local LuckyBlockConfig: LuckyBlockTypes.LuckyBlockConfig = {
	-- Arena UFO spawn settings
	ArenaSpawnIntervalMin = 90,    -- Minimum seconds between spawns
	ArenaSpawnIntervalMax = 180,   -- Maximum seconds between spawns
	MaxActiveArenaBlocks = 2,      -- Maximum blocks active at once
	
	-- Spawn chance percentages for arena (should add up to 100)
	ArenaRareChance = 70,
	ArenaVeryRareChance = 25,
	ArenaUltraRareChance = 5,
	
	-- Rarity bonuses: boost to animal spawn chances based on block rarity
	RarityBonuses = {
		Rare = {
			Common = 0,
			MediumRare = 0,
			Rare = 15,
			VeryRare = 5,
			UltraRare = 0,
		},
		VeryRare = {
			Common = 0,
			MediumRare = 0,
			Rare = 20,
			VeryRare = 20,
			UltraRare = 5,
		},
		UltraRare = {
			Common = 0,
			MediumRare = 0,
			Rare = 25,
			VeryRare = 25,
			UltraRare = 30,
		},
	},
	
	-- Reveal settings
	RevealDuration = 5,              -- Seconds for reveal animation
	IsolationZoneRadius = 10,        -- Radius of blocking cylinder
	IsolationZoneHeight = 20,        -- Height of blocking cylinder
}

return LuckyBlockConfig
