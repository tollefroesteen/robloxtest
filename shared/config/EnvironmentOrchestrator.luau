--!strict
-- EnvironmentOrchestrator.luau
-- Coordinates all procedural generation systems
-- Single entry point for generating complete environments with integer seeds
--
-- SHARED MODULE: Can be used by both Arena and Lobby places
--
-- USAGE:
--   local Environment = require(path.to.EnvironmentOrchestrator)
--   
--   -- Generate world with single seed (terrain & foliage use same base)
--   Environment.Generate({ terrainSeed = 1, foliageSeed = 1 })
--   
--   -- Mix and match seeds to find perfect combination
--   Environment.Generate({ terrainSeed = 5, foliageSeed = 12 })
--   
--   -- Generate with options
--   Environment.Generate({ terrainSeed = 1, foliageSeed = 1, playAreaOnly = true })

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedManager = require(script.Parent.Parent:WaitForChild("util"):WaitForChild("SeedManager"))
local ProceduralConfig = require(script.Parent:WaitForChild("ProceduralConfig"))
local TerrainGenerator = require(script.Parent:WaitForChild("TerrainGenerator"))
local FoliageGenerator = require(script.Parent:WaitForChild("FoliageGenerator"))
local Log = require(script.Parent.Parent:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "EnvironmentOrchestrator"

export type GenerateOptions = {
	-- Seeds (each generator can have its own seed)
	terrainSeed: number?,
	foliageSeed: number?,
	
	-- Generation flags
	generateTerrain: boolean?,
	generateFoliage: boolean?,
	playAreaOnly: boolean?,  -- Only generate play area (faster for testing)
	
	-- Callbacks
	onProgress: ((stage: string, progress: number) -> ())?,
	onComplete: ((info: GenerationInfo) -> ())?,
}

export type GenerationInfo = {
	terrainSeed: number,
	foliageSeed: number,
	elapsed: number,
	playAreaBounds: {
		minX: number,
		maxX: number,
		minZ: number,
		maxZ: number,
	},
}

local EnvironmentOrchestrator = {}

-- Current state
local currentTerrainSeed: number? = nil
local currentFoliageSeed: number? = nil
local isGenerating: boolean = false

--[=[
	Generate a complete environment with separate seeds for terrain and foliage.
	The same seeds always produce the exact same world.
	
	@param options -- Generation options with seeds
	@return GenerationInfo -- Information about the generated environment
	
	Examples:
	  Generate({ terrainSeed = 1, foliageSeed = 1 })  -- World with matching seeds
	  Generate({ terrainSeed = 5, foliageSeed = 12 }) -- Mix terrain 5 with foliage 12
	  Generate({ terrainSeed = 1, foliageSeed = 1, playAreaOnly = true }) -- Quick test
]=]
function EnvironmentOrchestrator.Generate(options: GenerateOptions?): GenerationInfo
	if isGenerating then
		Log.Warn(CONTEXT, "Generation already in progress, ignoring request")
		return {
			terrainSeed = currentTerrainSeed or 0,
			foliageSeed = currentFoliageSeed or 0,
			elapsed = 0,
			playAreaBounds = {
				minX = ProceduralConfig.PlayArea.MinX,
				maxX = ProceduralConfig.PlayArea.MaxX,
				minZ = ProceduralConfig.PlayArea.MinZ,
				maxZ = ProceduralConfig.PlayArea.MaxZ,
			},
		}
	end
	
	isGenerating = true
	local startTime = os.clock()
	
	-- Default options
	local opts: GenerateOptions = options or {}
	local terrainSeed = opts.terrainSeed or 1
	local foliageSeed = opts.foliageSeed or 1
	local generateTerrain = if opts.generateTerrain == nil then true else opts.generateTerrain
	local generateFoliage = if opts.generateFoliage == nil then true else opts.generateFoliage
	local playAreaOnly = opts.playAreaOnly or false
	local onProgress = opts.onProgress
	local onComplete = opts.onComplete
	
	currentTerrainSeed = terrainSeed
	currentFoliageSeed = foliageSeed
	
	Log.Info(CONTEXT, "============================================")
	Log.Info(CONTEXT, "Starting Environment Generation")
	Log.Info(CONTEXT, string.format("Terrain Seed: %d", terrainSeed))
	Log.Info(CONTEXT, string.format("Foliage Seed: %d", foliageSeed))
	Log.Info(CONTEXT, string.format("Play area only: %s", tostring(playAreaOnly)))
	Log.Info(CONTEXT, "============================================")
	
	-- Progress callback helper
	local function reportProgress(stage: string, progress: number)
		if onProgress then
			onProgress(stage, progress)
		end
	end
	
	-- Clear existing
	reportProgress("Clearing", 0)
	EnvironmentOrchestrator.Clear()
	reportProgress("Clearing", 100)
	
	-- Generate terrain
	if generateTerrain then
		reportProgress("Terrain", 0)
		
		if playAreaOnly then
			TerrainGenerator.GeneratePlayAreaOnly(terrainSeed)
		else
			TerrainGenerator.Generate(terrainSeed)
		end
		
		reportProgress("Terrain", 100)
	end
	
	-- Small delay to let terrain settle
	task.wait(0.1)
	
	-- Generate foliage
	if generateFoliage then
		reportProgress("Foliage", 0)
		FoliageGenerator.Generate(foliageSeed)
		reportProgress("Foliage", 100)
	end
	
	-- Complete
	local elapsed = os.clock() - startTime
	
	local info: GenerationInfo = {
		terrainSeed = terrainSeed,
		foliageSeed = foliageSeed,
		elapsed = elapsed,
		playAreaBounds = {
			minX = ProceduralConfig.PlayArea.MinX,
			maxX = ProceduralConfig.PlayArea.MaxX,
			minZ = ProceduralConfig.PlayArea.MinZ,
			maxZ = ProceduralConfig.PlayArea.MaxZ,
		},
	}
	
	Log.Info(CONTEXT, "============================================")
	Log.Info(CONTEXT, "Environment Generation Complete")
	Log.Info(CONTEXT, string.format("Total time: %.2f seconds", elapsed))
	Log.Info(CONTEXT, "============================================")
	
	if onComplete then
		onComplete(info)
	end
	
	isGenerating = false
	return info
end

--[=[
	Clear all generated environment (terrain and foliage).
]=]
function EnvironmentOrchestrator.Clear(): ()
	Log.Info(CONTEXT, "Clearing environment...")
	TerrainGenerator.Clear()
	FoliageGenerator.Clear()
	currentTerrainSeed = nil
	currentFoliageSeed = nil
end

--[=[
	Regenerate the environment with the same seeds.
	@param options -- Generation options (optional, seeds will be preserved)
	@return GenerationInfo?
]=]
function EnvironmentOrchestrator.Regenerate(options: GenerateOptions?): GenerationInfo?
	if not currentTerrainSeed or not currentFoliageSeed then
		Log.Warn(CONTEXT, "No previous seeds to regenerate from")
		return nil
	end
	
	local opts = options or {}
	opts.terrainSeed = opts.terrainSeed or currentTerrainSeed
	opts.foliageSeed = opts.foliageSeed or currentFoliageSeed
	
	return EnvironmentOrchestrator.Generate(opts)
end

--[=[
	Get the current seeds.
	@return { terrainSeed: number?, foliageSeed: number? }
]=]
function EnvironmentOrchestrator.GetSeeds(): { terrainSeed: number?, foliageSeed: number? }
	return {
		terrainSeed = currentTerrainSeed,
		foliageSeed = currentFoliageSeed,
	}
end

--[=[
	Regenerate only terrain with a new seed (keeps current foliage seed).
	@param terrainSeed -- New terrain seed
	@param playAreaOnly -- Only generate play area (optional)
	@return GenerationInfo?
]=]
function EnvironmentOrchestrator.RegenerateTerrain(terrainSeed: number, playAreaOnly: boolean?): GenerationInfo?
	return EnvironmentOrchestrator.Generate({
		terrainSeed = terrainSeed,
		foliageSeed = currentFoliageSeed or 1,
		generateTerrain = true,
		generateFoliage = true,  -- Re-place foliage on new terrain
		playAreaOnly = playAreaOnly,
	})
end

--[=[
	Regenerate only foliage with a new seed (keeps current terrain).
	@param foliageSeed -- New foliage seed
	@return GenerationInfo?
]=]
function EnvironmentOrchestrator.RegenerateFoliage(foliageSeed: number): GenerationInfo?
	-- Only clear and regenerate foliage, not terrain
	FoliageGenerator.Clear()
	FoliageGenerator.Generate(foliageSeed)
	currentFoliageSeed = foliageSeed
	
	Log.Info(CONTEXT, string.format("Foliage regenerated with seed: %d", foliageSeed))
	
	return {
		terrainSeed = currentTerrainSeed or 0,
		foliageSeed = foliageSeed,
		elapsed = 0,
		playAreaBounds = {
			minX = ProceduralConfig.PlayArea.MinX,
			maxX = ProceduralConfig.PlayArea.MaxX,
			minZ = ProceduralConfig.PlayArea.MinZ,
			maxZ = ProceduralConfig.PlayArea.MaxZ,
		},
	}
end

--[=[
	Check if generation is currently in progress.
	@return boolean
]=]
function EnvironmentOrchestrator.IsGenerating(): boolean
	return isGenerating
end

--[=[
	Get the terrain height at a world position.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return number? -- Terrain height or nil
]=]
function EnvironmentOrchestrator.GetTerrainHeight(x: number, z: number): number?
	return TerrainGenerator.RaycastHeight(x, z)
end

--[=[
	Check if a position is within the play area.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return boolean
]=]
function EnvironmentOrchestrator.IsInPlayArea(x: number, z: number): boolean
	return ProceduralConfig.IsInPlayArea(x, z)
end

--[=[
	Get play area bounds.
	@return {minX: number, maxX: number, minZ: number, maxZ: number}
]=]
function EnvironmentOrchestrator.GetPlayAreaBounds(): {minX: number, maxX: number, minZ: number, maxZ: number}
	return {
		minX = ProceduralConfig.PlayArea.MinX,
		maxX = ProceduralConfig.PlayArea.MaxX,
		minZ = ProceduralConfig.PlayArea.MinZ,
		maxZ = ProceduralConfig.PlayArea.MaxZ,
	}
end

return EnvironmentOrchestrator
