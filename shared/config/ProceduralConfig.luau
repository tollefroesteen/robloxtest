--!strict
-- ProceduralConfig.luau
-- Configuration for procedural environment generation
-- Central place to define world parameters, zone boundaries, and generation settings

local ProceduralConfig = {}

--[=[
	@interface WorldBounds
	Total world generation boundaries
]=]
export type WorldBounds = {
	SizeX: number,
	SizeY: number,
	SizeZ: number,
	-- Derived bounds (calculated)
	MinX: number,
	MaxX: number,
	MinZ: number,
	MaxZ: number,
}

--[=[
	@interface PlayAreaConfig
	The main gameplay area - flat grassy plains for animal herding
]=]
export type PlayAreaConfig = {
	SizeX: number,  -- 280 units
	SizeZ: number,  -- 350 units
	-- Derived bounds
	MinX: number,   -- -140
	MaxX: number,   -- +140
	MinZ: number,   -- -175
	MaxZ: number,   -- +175
}

--[=[
	@interface TransitionConfig
	The zone between play area and mountains
]=]
export type TransitionConfig = {
	Width: number,  -- How wide the transition is
}

--[=[
	@interface IrishHillsConfig
	Irish-style rolling hills configuration for play area
	Think green plains with scattered hills of varying sizes
]=]
export type IrishHillsConfig = {
	-- Hill density and coverage
	Enabled: boolean,        -- Whether to use Irish hills system
	Density: number,         -- Hills per 10000 sq units (0.5 = sparse, 2.0 = many hills)
	
	-- Hill size range (radius in studs)
	MinRadius: number,       -- Smallest hills (e.g., 8)
	MaxRadius: number,       -- Largest hills (e.g., 40)
	
	-- Hill height/aggressiveness
	MinHeight: number,       -- Minimum hill peak height (e.g., 3)
	MaxHeight: number,       -- Maximum hill peak height (e.g., 20)
	Steepness: number,       -- 0.5 = gentle slopes, 1.0 = normal, 2.0 = steep (affects gradient)
	
	-- Blending
	FalloffPower: number,    -- How sharply hills blend to ground (1.0 = linear, 2.0 = smooth, 3.0 = plateau-ish)
}

--[=[
	@interface TerrainConfig
	Height and material settings for terrain generation
]=]
export type TerrainConfig = {
	-- Play area terrain (base layer - gentle undulation)
	PlayAreaBaseHeight: number,
	PlayAreaMaxVariation: number,
	PlayAreaNoiseScale: number,
	PlayAreaOctaves: number,
	PlayAreaPersistence: number,
	
	-- Transition terrain
	TransitionHeightStart: number,
	TransitionHeightEnd: number,
	
	-- Mountain terrain (steep rocky barriers)
	MountainBaseHeight: number,
	MountainMaxHeight: number,
	MountainNoiseScale: number,
	MountainOctaves: number,
	MountainPersistence: number,
	MountainSteepness: number,  -- How quickly mountains rise
	
	-- Material thresholds
	SnowHeight: number,  -- Height above which snow appears
	RockSlopeThreshold: number,  -- Slope angle for rock vs grass
	
	-- Generation settings
	Resolution: number,  -- Terrain voxels per unit (4 = Roblox default)
	ChunkSize: number,   -- Size of generation chunks
}

--[=[
	@interface FoliageConfig
	Vegetation and rock placement settings
]=]
export type FoliageConfig = {
	-- Density (approximate items per 1000 square units)
	GrassClumpDensity: number,
	BushDensity: number,
	TreeDensity: number,
	SmallRockDensity: number,
	LargeRockDensity: number,
	
	-- Placement rules
	MinSpacing: number,  -- Minimum distance between foliage items
	MaxSlopeForTrees: number,  -- Max slope angle for tree placement
	MaxSlopeForBushes: number,
	
	-- Size variations (multiplier range)
	SizeVariationMin: number,
	SizeVariationMax: number,
}

-- ============================================================================
-- CONFIGURATION VALUES
-- ============================================================================

-- Total world size (includes mountains)
ProceduralConfig.World = {
	SizeX = 500,
	SizeY = 200,
	SizeZ = 450,
	-- Derived
	MinX = -250,
	MaxX = 250,
	MinZ = -225,
	MaxZ = 225,
}

-- Play area (centered on origin)
ProceduralConfig.PlayArea = {
	SizeX = 280,
	SizeZ = 350,
	-- Derived bounds
	MinX = -140,
	MaxX = 140,
	MinZ = -175,
	MaxZ = 175,
}

-- Transition zone
ProceduralConfig.Transition = {
	Width = 40,
}

-- Terrain generation settings
ProceduralConfig.Terrain = {
	-- Play area: base undulation (beneath the hills)
	PlayAreaBaseHeight = 0,
	PlayAreaMaxVariation = 2,      -- Very gentle base undulation
	PlayAreaNoiseScale = 120,      -- Large scale for smooth base
	PlayAreaOctaves = 2,
	PlayAreaPersistence = 0.3,     -- Very smooth
	
	-- Transition: gradual rise
	TransitionHeightStart = 6,
	TransitionHeightEnd = 25,
	
	-- Mountains: steep barriers
	MountainBaseHeight = 25,
	MountainMaxHeight = 70,
	MountainNoiseScale = 30,       -- Smaller scale = more rugged
	MountainOctaves = 4,
	MountainPersistence = 0.5,
	MountainSteepness = 2.5,       -- Exponential rise factor
	
	-- Materials
	SnowHeight = 55,
	RockSlopeThreshold = 35,       -- Degrees
	
	-- Generation
	Resolution = 4,
	ChunkSize = 32,
}

-- Irish Hills configuration (rolling green hills scattered across play area)
ProceduralConfig.IrishHills = {
	Enabled = true,
	
	-- Density: hills per 10000 square units
	-- 0.3 = sparse, 0.8 = moderate, 1.5 = dense, 3.0 = very hilly
	Density = 0.8,
	
	-- Hill radius range (studs)
	MinRadius = 10,           -- Small gentle mounds
	MaxRadius = 45,           -- Large rolling hills
	
	-- Hill height range (studs)
	MinHeight = 4,            -- Subtle bumps
	MaxHeight = 18,           -- Prominent hills
	
	-- Steepness: affects slope gradient
	-- 0.5 = very gentle, 1.0 = natural, 1.5 = steep, 2.0 = aggressive
	Steepness = 1.0,
	
	-- Falloff: how hills blend to ground
	-- 1.0 = linear (cone), 2.0 = smooth (natural), 3.0 = plateau-top
	FalloffPower = 2.0,
}

-- Foliage settings
ProceduralConfig.Foliage = {
	-- Density (per 1000 sq units)
	GrassClumpDensity = 20,
	BushDensity = 4,
	TreeDensity = 1,
	SmallRockDensity = 2,
	LargeRockDensity = 3,  -- In transition zone
	
	-- Placement
	MinSpacing = 3,
	MaxSlopeForTrees = 20,
	MaxSlopeForBushes = 35,
	
	-- Size variation
	SizeVariationMin = 0.7,
	SizeVariationMax = 1.3,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--[=[
	Determine which zone a world position is in.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return "PlayArea" | "Transition" | "Mountain"
]=]
function ProceduralConfig.GetZone(x: number, z: number): string
	local playArea = ProceduralConfig.PlayArea
	local transition = ProceduralConfig.Transition
	
	-- Calculate normalized distance from center
	-- 0 = center, 1 = edge of play area
	local normalizedX = math.abs(x) / (playArea.SizeX / 2)
	local normalizedZ = math.abs(z) / (playArea.SizeZ / 2)
	local normalizedDist = math.max(normalizedX, normalizedZ)
	
	if normalizedDist < 1.0 then
		return "PlayArea"
	end
	
	-- Calculate transition threshold (normalized)
	local transitionEnd = 1.0 + (transition.Width / math.min(playArea.SizeX / 2, playArea.SizeZ / 2))
	
	if normalizedDist < transitionEnd then
		return "Transition"
	end
	
	return "Mountain"
end

--[=[
	Get the blend factor for transition zone (0 = play area edge, 1 = mountain start).
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return number -- Blend factor [0, 1], or -1 if not in transition
]=]
function ProceduralConfig.GetTransitionBlend(x: number, z: number): number
	local playArea = ProceduralConfig.PlayArea
	local transition = ProceduralConfig.Transition
	
	local normalizedX = math.abs(x) / (playArea.SizeX / 2)
	local normalizedZ = math.abs(z) / (playArea.SizeZ / 2)
	local normalizedDist = math.max(normalizedX, normalizedZ)
	
	if normalizedDist < 1.0 then
		return -1  -- In play area
	end
	
	local transitionNorm = transition.Width / math.min(playArea.SizeX / 2, playArea.SizeZ / 2)
	local transitionEnd = 1.0 + transitionNorm
	
	if normalizedDist >= transitionEnd then
		return -1  -- In mountain zone
	end
	
	-- Calculate blend: 0 at play area edge, 1 at mountain start
	return (normalizedDist - 1.0) / transitionNorm
end

--[=[
	Get distance past the play area boundary (for mountain height calculation).
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return number -- Distance past boundary (0 if inside play area)
]=]
function ProceduralConfig.GetDistancePastPlayArea(x: number, z: number): number
	local playArea = ProceduralConfig.PlayArea
	
	local distX = math.max(0, math.abs(x) - playArea.SizeX / 2)
	local distZ = math.max(0, math.abs(z) - playArea.SizeZ / 2)
	
	return math.max(distX, distZ)
end

--[=[
	Check if a position is within the total world bounds.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return boolean
]=]
function ProceduralConfig.IsInWorldBounds(x: number, z: number): boolean
	local world = ProceduralConfig.World
	return x >= world.MinX and x <= world.MaxX and z >= world.MinZ and z <= world.MaxZ
end

--[=[
	Check if a position is within the play area.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return boolean
]=]
function ProceduralConfig.IsInPlayArea(x: number, z: number): boolean
	local playArea = ProceduralConfig.PlayArea
	return x >= playArea.MinX and x <= playArea.MaxX and z >= playArea.MinZ and z <= playArea.MaxZ
end

return ProceduralConfig
