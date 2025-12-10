--!strict
-- LuckyBlockTypes.luau
-- Shared type definitions for Lucky Block system

export type LuckyBlockRarity = "Rare" | "VeryRare" | "UltraRare"

export type AnimalRarity = "Common" | "MediumRare" | "Rare" | "VeryRare" | "UltraRare"

export type LuckyBlockData = {
	ID: string,
	Rarity: LuckyBlockRarity,
	Position: Vector3?,
	Owner: Player?,           -- Only set for lobby purchased blocks
	SpawnTime: number,
}

export type LuckyBlockConfig = {
	-- Arena UFO spawn settings
	ArenaSpawnIntervalMin: number,
	ArenaSpawnIntervalMax: number,
	MaxActiveArenaBlocks: number,
	
	-- Spawn chance percentages for arena (should add up to 100)
	ArenaRareChance: number,
	ArenaVeryRareChance: number,
	ArenaUltraRareChance: number,
	
	-- Rarity weights for animal selection
	RarityBonuses: {
		[LuckyBlockRarity]: {
			[AnimalRarity]: number
		}
	},
	
	-- Reveal settings
	RevealDuration: number,
	IsolationZoneRadius: number,
	IsolationZoneHeight: number,
}

return {}
