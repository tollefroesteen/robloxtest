--!strict
-- TerrainGenerator.luau
-- Generates terrain using Roblox's Terrain system with zone-based heightmap and materials
-- Creates Irish-style rolling green hills in the play area, with rocky mountain barriers
-- 
-- SHARED MODULE: Can be used by both Arena and Lobby places

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedManager = require(script.Parent.Parent:WaitForChild("util"):WaitForChild("SeedManager"))
local ProceduralConfig = require(script.Parent:WaitForChild("ProceduralConfig"))
local Log = require(script.Parent.Parent:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "TerrainGenerator"

type SeededRandom = SeedManager.SeededRandom

-- Hill data structure
type Hill = {
	x: number,
	z: number,
	radius: number,
	height: number,
}

-- Mountain peak data structure
type Peak = {
	x: number,
	z: number,
	radius: number,
	height: number,
}

local TerrainGenerator = {}

-- Cache terrain reference
local terrain: Terrain = workspace.Terrain

-- Generated hills cache (persists between height queries)
local generatedHills: {Hill} = {}

-- Generated mountain peaks cache
local generatedPeaks: {Peak} = {}

-- Material enum shortcuts
local Materials = {
	Air = Enum.Material.Air,
	Grass = Enum.Material.Grass,
	Ground = Enum.Material.Ground,
	Rock = Enum.Material.Rock,
	Snow = Enum.Material.Snow,
	Mud = Enum.Material.Mud,
	Sand = Enum.Material.Sand,
}

--[=[
	Generate hill positions using Poisson-like distribution.
	@param rng -- Seeded random generator
	@return {Hill} -- Array of hill data
]=]
local function generateHillPositions(rng: SeededRandom): {Hill}
	local hills: {Hill} = {}
	local hillConfig = ProceduralConfig.IrishHills
	local playArea = ProceduralConfig.PlayArea
	
	if not hillConfig.Enabled then
		return hills
	end
	
	-- Calculate approximate number of hills based on density
	local area = playArea.SizeX * playArea.SizeZ
	local targetHillCount = math.floor(area / 10000 * hillConfig.Density)
	
	-- Use sub-seed for hill placement
	local hillRng = rng:SubSeed("hills")
	
	-- Minimum spacing between hill centers (based on average radius)
	local avgRadius = (hillConfig.MinRadius + hillConfig.MaxRadius) / 2
	local minSpacing = avgRadius * 0.8  -- Allow some overlap for natural look
	
	-- Simple rejection sampling for hill placement
	local maxAttempts = targetHillCount * 10
	local attempts = 0
	
	while #hills < targetHillCount and attempts < maxAttempts do
		attempts += 1
		
		-- Random position within play area (with padding)
		local padding = hillConfig.MaxRadius * 0.5
		local x = hillRng:NextNumber(playArea.MinX + padding, playArea.MaxX - padding)
		local z = hillRng:NextNumber(playArea.MinZ + padding, playArea.MaxZ - padding)
		
		-- Check distance to existing hills
		local tooClose = false
		for _, existingHill in hills do
			local dist = math.sqrt((x - existingHill.x)^2 + (z - existingHill.z)^2)
			if dist < minSpacing then
				tooClose = true
				break
			end
		end
		
		if not tooClose then
			-- Random radius and height within configured ranges
			local radius = hillRng:NextNumber(hillConfig.MinRadius, hillConfig.MaxRadius)
			local height = hillRng:NextNumber(hillConfig.MinHeight, hillConfig.MaxHeight)
			
			-- Larger hills tend to be taller (natural correlation)
			local sizeRatio = (radius - hillConfig.MinRadius) / (hillConfig.MaxRadius - hillConfig.MinRadius)
			height = height + sizeRatio * (hillConfig.MaxHeight - hillConfig.MinHeight) * 0.3
			
			table.insert(hills, {
				x = x,
				z = z,
				radius = radius,
				height = height,
			})
		end
	end
	
	Log.Info(CONTEXT, string.format("Generated %d hills (target: %d)", #hills, targetHillCount))
	return hills
end

--[=[
	Calculate hill contribution at a position.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return number -- Height contribution from all nearby hills
]=]
local function getHillHeightAt(x: number, z: number): number
	local hillConfig = ProceduralConfig.IrishHills
	if not hillConfig.Enabled or #generatedHills == 0 then
		return 0
	end
	
	local totalHeight = 0
	local maxSearchRadius = hillConfig.MaxRadius * 1.5  -- Only check nearby hills
	
	for _, hill in generatedHills do
		local dx = x - hill.x
		local dz = z - hill.z
		local distance = math.sqrt(dx * dx + dz * dz)
		
		-- Skip if too far from this hill
		if distance > hill.radius * 1.2 then
			continue
		end
		
		-- Normalized distance (0 at center, 1 at edge)
		local normalizedDist = distance / hill.radius
		
		if normalizedDist < 1.0 then
			-- Apply steepness modifier
			local adjustedDist = normalizedDist ^ (1 / hillConfig.Steepness)
			
			-- Smooth falloff using configured power
			-- falloffPower = 1.0: linear (cone shape)
			-- falloffPower = 2.0: smooth (natural dome)
			-- falloffPower = 3.0: plateau-ish (flatter tops)
			local falloff = 1.0 - (adjustedDist ^ hillConfig.FalloffPower)
			
			-- Extra smoothing at the edges using smoothstep
			falloff = falloff * falloff * (3 - 2 * falloff)
			
			local hillContribution = hill.height * falloff
			
			-- Use max blending for overlapping hills (creates natural ridges)
			totalHeight = math.max(totalHeight, hillContribution)
		end
	end
	
	return totalHeight
end

--[=[
	Generate mountain peak positions in the mountain zone.
	@param rng -- Seeded random generator
	@return {Peak} -- Array of peak data
]=]
local function generateMountainPeaks(rng: SeededRandom): {Peak}
	local peaks: {Peak} = {}
	local mtConfig = ProceduralConfig.Mountains
	local world = ProceduralConfig.World
	local playArea = ProceduralConfig.PlayArea
	local transition = ProceduralConfig.Transition
	
	if not mtConfig.Enabled then
		return peaks
	end
	
	-- Mountain zone starts after transition
	local mountainStartX = playArea.MaxX + transition.Width
	local mountainStartZ = playArea.MaxZ + transition.Width
	
	-- Calculate mountain area (rough approximation - ring around play area)
	local mountainArea = (world.SizeX * world.SizeZ) - ((playArea.SizeX + transition.Width * 2) * (playArea.SizeZ + transition.Width * 2))
	local targetPeakCount = math.floor(mountainArea / 10000 * mtConfig.PeakDensity)
	
	local peakRng = rng:SubSeed("peaks")
	local avgRadius = (mtConfig.PeakMinRadius + mtConfig.PeakMaxRadius) / 2
	local minSpacing = avgRadius * 0.6  -- Allow closer peaks for mountain ranges
	
	local maxAttempts = targetPeakCount * 15
	local attempts = 0
	
	while #peaks < targetPeakCount and attempts < maxAttempts do
		attempts += 1
		
		-- Random position in the mountain zone (outside play area + transition)
		local x = peakRng:NextNumber(world.MinX, world.MaxX)
		local z = peakRng:NextNumber(world.MinZ, world.MaxZ)
		
		-- Check if in mountain zone
		local zone = ProceduralConfig.GetZone(x, z)
		if zone ~= "Mountain" then
			continue
		end
		
		-- Check distance to existing peaks
		local tooClose = false
		for _, existingPeak in peaks do
			local dist = math.sqrt((x - existingPeak.x)^2 + (z - existingPeak.z)^2)
			if dist < minSpacing then
				tooClose = true
				break
			end
		end
		
		if not tooClose then
			local radius = peakRng:NextNumber(mtConfig.PeakMinRadius, mtConfig.PeakMaxRadius)
			local height = peakRng:NextNumber(mtConfig.PeakMinHeight, mtConfig.PeakMaxHeight)
			
			-- Larger peaks tend to be taller
			local sizeRatio = (radius - mtConfig.PeakMinRadius) / math.max(1, mtConfig.PeakMaxRadius - mtConfig.PeakMinRadius)
			height = height + sizeRatio * (mtConfig.PeakMaxHeight - mtConfig.PeakMinHeight) * 0.4
			
			table.insert(peaks, {
				x = x,
				z = z,
				radius = radius,
				height = height,
			})
		end
	end
	
	Log.Info(CONTEXT, string.format("Generated %d mountain peaks (target: %d)", #peaks, targetPeakCount))
	return peaks
end

--[=[
	Calculate mountain peak contribution at a position.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return number -- Height contribution from nearby peaks
]=]
local function getPeakHeightAt(x: number, z: number): number
	local mtConfig = ProceduralConfig.Mountains
	if not mtConfig.Enabled or #generatedPeaks == 0 then
		return 0
	end
	
	local maxHeight = 0
	
	for _, peak in generatedPeaks do
		local dx = x - peak.x
		local dz = z - peak.z
		local distance = math.sqrt(dx * dx + dz * dz)
		
		-- Skip if too far
		if distance > peak.radius * 1.5 then
			continue
		end
		
		local normalizedDist = distance / peak.radius
		
		if normalizedDist < 1.0 then
			-- Sharp peak falloff for alpine look
			local adjustedDist = normalizedDist ^ (1 / mtConfig.PeakSteepness)
			
			-- Exponential falloff for sharp peaks
			local falloff = math.exp(-adjustedDist * 3) * (1 - adjustedDist)
			falloff = math.max(0, falloff)
			
			local peakContribution = peak.height * falloff
			maxHeight = math.max(maxHeight, peakContribution)
		end
	end
	
	return maxHeight
end

--[=[
	Calculate ridge contribution using noise.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@param rng -- Seeded random generator
	@return number -- Ridge height contribution
]=]
local function getRidgeHeightAt(x: number, z: number, rng: SeededRandom): number
	local mtConfig = ProceduralConfig.Mountains
	if not mtConfig.Enabled or not mtConfig.RidgeEnabled then
		return 0
	end
	
	-- Ridge noise using absolute value for sharp ridges
	local ridgeNoise = rng:Noise2D(x, z, mtConfig.RidgeNoiseScale, 3, 0.5)
	
	-- Create ridge effect: 1.0 at ridge line, 0.0 in valleys
	local ridgeValue = 1.0 - math.abs(ridgeNoise)
	
	-- Sharpen the ridges
	ridgeValue = ridgeValue ^ mtConfig.RidgeSharpness
	
	return ridgeValue * mtConfig.RidgeHeight
end

--[=[
	Calculate the height at a given world position based on zone.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@param rng -- Seeded random generator
	@return number -- Height at this position
]=]
local function getHeightAt(x: number, z: number, rng: SeededRandom): number
	local config = ProceduralConfig.Terrain
	local zone = ProceduralConfig.GetZone(x, z)
	
	if zone == "PlayArea" then
		-- Base undulation using smooth noise
		local baseNoise = rng:Noise2D(x, z, config.PlayAreaNoiseScale, config.PlayAreaOctaves, config.PlayAreaPersistence)
		local baseHeight = config.PlayAreaBaseHeight + ((baseNoise + 1) / 2) * config.PlayAreaMaxVariation
		
		-- Add Irish hills on top
		local hillHeight = getHillHeightAt(x, z)
		
		return baseHeight + hillHeight
		
	elseif zone == "Transition" then
		-- Blend between play area height and mountain height
		local blend = ProceduralConfig.GetTransitionBlend(x, z)
		
		-- Get play area height at this position (including hills)
		local playNoise = rng:Noise2D(x, z, config.PlayAreaNoiseScale, config.PlayAreaOctaves, config.PlayAreaPersistence)
		local playHeight = config.PlayAreaBaseHeight + ((playNoise + 1) / 2) * config.PlayAreaMaxVariation
		playHeight = playHeight + getHillHeightAt(x, z) * (1 - blend)  -- Fade out hills in transition
		
		-- Get mountain-style height with peaks starting to appear
		local distancePast = ProceduralConfig.GetDistancePastPlayArea(x, z)
		
		-- Steeper rise based on distance
		local riseAmount = (distancePast / ProceduralConfig.Transition.Width) * (config.TransitionHeightEnd - config.TransitionHeightStart)
		
		-- Blend in peaks and ridges near the end of transition
		local peakBlend = math.max(0, (blend - 0.5) * 2)  -- Only starts blending peaks at 50% into transition
		local peakContribution = getPeakHeightAt(x, z) * peakBlend * 0.5  -- Partial peak influence
		local ridgeContribution = getRidgeHeightAt(x, z, rng) * peakBlend * 0.3
		
		local transitionHeight = config.TransitionHeightStart + riseAmount + peakContribution + ridgeContribution
		
		-- Smooth blend using smoothstep
		local t = blend * blend * (3 - 2 * blend)  -- Smoothstep
		return playHeight * (1 - t) + transitionHeight * t
		
	else -- Mountain
		local mtConfig = ProceduralConfig.Mountains
		local distancePast = ProceduralConfig.GetDistancePastPlayArea(x, z)
		
		-- Base elevation rises with distance into mountain zone
		local normalizedDist = distancePast / 60  -- Normalize to reasonable range
		local riseMultiplier = mtConfig.BaseRiseMultiplier or 1.0
		local baseRise = mtConfig.BaseHeight + (normalizedDist ^ config.MountainSteepness) * 15 * riseMultiplier
		
		-- Add mountain peaks
		local peakHeight = getPeakHeightAt(x, z)
		
		-- Add ridge lines for alpine effect
		local ridgeHeight = getRidgeHeightAt(x, z, rng)
		
		-- Add alpine roughness/texture noise
		local roughnessNoise = rng:Noise2D(x, z, 8, 4, 0.6)  -- High frequency detail
		local roughnessContribution = ((roughnessNoise + 1) / 2) * mtConfig.Roughness * 6
		
		-- Combine all contributions
		local totalHeight = baseRise + peakHeight + ridgeHeight + roughnessContribution
		
		return math.min(totalHeight, config.MountainMaxHeight)
	end
end

--[=[
	Calculate terrain slope at a position (for material selection).
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@param rng -- Seeded random generator
	@return number -- Slope angle in degrees
]=]
local function getSlopeAt(x: number, z: number, rng: SeededRandom): number
	local sampleDist = 2  -- Distance to sample for slope calculation
	
	local h0 = getHeightAt(x, z, rng)
	local hX = getHeightAt(x + sampleDist, z, rng)
	local hZ = getHeightAt(x, z + sampleDist, rng)
	
	-- Calculate gradient
	local dx = (hX - h0) / sampleDist
	local dz = (hZ - h0) / sampleDist
	
	-- Convert to angle
	local gradient = math.sqrt(dx * dx + dz * dz)
	return math.deg(math.atan(gradient))
end

--[=[
	Determine the terrain material at a position.
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@param height -- Height at this position
	@param slope -- Slope at this position (degrees)
	@param rng -- Seeded random generator
	@return Enum.Material
]=]
local function getMaterialAt(x: number, z: number, height: number, slope: number, rng: SeededRandom): Enum.Material
	local config = ProceduralConfig.Terrain
	local mtConfig = ProceduralConfig.Mountains
	local zone = ProceduralConfig.GetZone(x, z)
	
	-- Snow on high peaks (use mountain config for more control)
	if zone == "Mountain" or zone == "Transition" then
		if height > mtConfig.SnowHeight + mtConfig.SnowBlend then
			return Materials.Snow
		elseif height > mtConfig.SnowHeight then
			-- Blend zone - randomly choose snow or rock
			local snowChance = (height - mtConfig.SnowHeight) / mtConfig.SnowBlend
			local variation = rng:Noise2D(x * 3, z * 3, 5, 1)
			if variation + snowChance > 0.5 then
				return Materials.Snow
			end
		end
	elseif height > config.SnowHeight then
		return Materials.Snow
	end
	
	-- Rock on steep slopes
	if slope > config.RockSlopeThreshold then
		return Materials.Rock
	end
	
	if zone == "PlayArea" then
		-- Mostly grass with occasional dirt patches
		local variation = rng:Noise2D(x * 2, z * 2, 20, 1)
		if variation > 0.6 then
			return Materials.Ground  -- Dirt patches
		end
		return Materials.Grass
		
	elseif zone == "Transition" then
		-- Blend from grass to rock based on blend factor
		local blend = ProceduralConfig.GetTransitionBlend(x, z)
		local variation = rng:Noise2D(x, z, 15, 2)
		
		-- More rock as we get further from play area
		if variation + blend > 0.5 then
			return Materials.Rock
		elseif variation + blend > 0.2 then
			return Materials.Ground
		end
		return Materials.Grass
		
	else -- Mountain
		-- Mostly rock with some ground pockets
		local variation = rng:Noise2D(x, z, 25, 1)
		if variation > 0.3 then
			return Materials.Rock
		end
		return Materials.Ground
	end
end

--[=[
	Generate a single chunk of terrain.
	@param chunkX -- Chunk X index
	@param chunkZ -- Chunk Z index
	@param chunkSize -- Size of each chunk in studs
	@param rng -- Seeded random generator
]=]
local function generateChunk(chunkX: number, chunkZ: number, chunkSize: number, rng: SeededRandom): ()
	local resolution = ProceduralConfig.Terrain.Resolution
	local voxelSize = 4 / resolution  -- Roblox terrain voxel is 4 studs at resolution 1
	
	-- Calculate world position of chunk corner
	local worldX = chunkX * chunkSize
	local worldZ = chunkZ * chunkSize
	
	-- Skip if outside world bounds
	if not ProceduralConfig.IsInWorldBounds(worldX, worldZ) and 
	   not ProceduralConfig.IsInWorldBounds(worldX + chunkSize, worldZ + chunkSize) then
		return
	end
	
	-- Determine height range for this chunk to optimize voxel array size
	local minHeight = math.huge
	local maxHeight = -math.huge
	
	-- Sample heights across chunk to find range
	for sx = 0, chunkSize, 8 do
		for sz = 0, chunkSize, 8 do
			local h = getHeightAt(worldX + sx, worldZ + sz, rng)
			minHeight = math.min(minHeight, h)
			maxHeight = math.max(maxHeight, h)
		end
	end
	
	-- Add padding
	minHeight = math.max(0, math.floor(minHeight) - 4)
	maxHeight = math.ceil(maxHeight) + 4
	
	-- Generate terrain using FillBlock for each column (simpler approach)
	-- This is less performant than WriteVoxels but more straightforward
	
	local stepSize = 4  -- Generate in 4-stud columns
	
	for lx = 0, chunkSize - stepSize, stepSize do
		for lz = 0, chunkSize - stepSize, stepSize do
			local px = worldX + lx + stepSize / 2
			local pz = worldZ + lz + stepSize / 2
			
			-- Skip if outside world bounds
			if not ProceduralConfig.IsInWorldBounds(px, pz) then
				continue
			end
			
			local height = getHeightAt(px, pz, rng)
			local slope = getSlopeAt(px, pz, rng)
			local material = getMaterialAt(px, pz, height, slope, rng)
			
			-- Fill terrain column
			if height > 0 then
				local position = Vector3.new(px, height / 2, pz)
				local size = Vector3.new(stepSize, height, stepSize)
				
				terrain:FillBlock(CFrame.new(position), size, material)
			end
		end
	end
end

--[=[
	Generate the entire terrain for the world.
	@param seed -- Integer seed for reproducible generation (e.g., 1, 2, 3...)
]=]
function TerrainGenerator.Generate(seed: number): ()
	Log.Info(CONTEXT, string.format("Starting terrain generation with seed: %d", seed))
	
	local rng = SeedManager.Create(seed):SubSeed("terrain")
	local startTime = os.clock()
	local config = ProceduralConfig.Terrain
	local world = ProceduralConfig.World
	
	-- Clear existing terrain
	terrain:Clear()
	
	-- Generate hill positions first (these persist for height queries)
	generatedHills = generateHillPositions(rng)
	
	-- Generate mountain peak positions
	generatedPeaks = generateMountainPeaks(rng)
	
	-- Calculate chunk grid
	local chunkSize = config.ChunkSize
	local chunksX = math.ceil(world.SizeX / chunkSize)
	local chunksZ = math.ceil(world.SizeZ / chunkSize)
	
	local startChunkX = math.floor(world.MinX / chunkSize)
	local startChunkZ = math.floor(world.MinZ / chunkSize)
	
	local totalChunks = chunksX * chunksZ
	local processedChunks = 0
	
	Log.Info(CONTEXT, string.format("Generating %d chunks (%dx%d)", totalChunks, chunksX, chunksZ))
	
	-- Generate each chunk
	for cx = 0, chunksX - 1 do
		for cz = 0, chunksZ - 1 do
			local chunkX = startChunkX + cx
			local chunkZ = startChunkZ + cz
			
			generateChunk(chunkX, chunkZ, chunkSize, rng)
			
			processedChunks += 1
			
			-- Yield occasionally to prevent timeout
			if processedChunks % 10 == 0 then
				task.wait()
			end
		end
		
		-- Progress update
		local progress = math.floor((cx + 1) / chunksX * 100)
		if progress % 25 == 0 then
			Log.Info(CONTEXT, string.format("Terrain generation: %d%%", progress))
		end
	end
	
	local elapsed = os.clock() - startTime
	Log.Info(CONTEXT, string.format("Terrain generation complete in %.2f seconds", elapsed))
end

--[=[
	Generate terrain for just the play area (faster for testing).
	@param seed -- Integer seed for reproducible generation
]=]
function TerrainGenerator.GeneratePlayAreaOnly(seed: number): ()
	Log.Info(CONTEXT, string.format("Generating play area terrain only with seed: %d", seed))
	
	local rng = SeedManager.Create(seed):SubSeed("terrain")
	local startTime = os.clock()
	local config = ProceduralConfig.Terrain
	local playArea = ProceduralConfig.PlayArea
	
	terrain:Clear()
	
	-- Generate hill positions first
	generatedHills = generateHillPositions(rng)
	
	local chunkSize = config.ChunkSize
	local chunksX = math.ceil(playArea.SizeX / chunkSize)
	local chunksZ = math.ceil(playArea.SizeZ / chunkSize)
	
	local startChunkX = math.floor(playArea.MinX / chunkSize)
	local startChunkZ = math.floor(playArea.MinZ / chunkSize)
	
	for cx = 0, chunksX - 1 do
		for cz = 0, chunksZ - 1 do
			local chunkX = startChunkX + cx
			local chunkZ = startChunkZ + cz
			
			generateChunk(chunkX, chunkZ, chunkSize, rng)
		end
		task.wait()
	end
	
	local elapsed = os.clock() - startTime
	Log.Info(CONTEXT, string.format("Play area terrain complete in %.2f seconds", elapsed))
end

--[=[
	Clear all generated terrain.
]=]
function TerrainGenerator.Clear(): ()
	terrain:Clear()
	generatedHills = {}
	generatedPeaks = {}
	Log.Info(CONTEXT, "Terrain cleared")
end

--[=[
	Get the height at a world position (for foliage placement).
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@param seed -- Integer seed (must match terrain generation seed)
	@return number -- Terrain height at this position
]=]
function TerrainGenerator.GetHeightAt(x: number, z: number, seed: number): number
	local rng = SeedManager.Create(seed):SubSeed("terrain")
	return getHeightAt(x, z, rng)
end

--[=[
	Get the slope at a world position (for foliage placement rules).
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@param seed -- Integer seed (must match terrain generation seed)
	@return number -- Slope in degrees
]=]
function TerrainGenerator.GetSlopeAt(x: number, z: number, seed: number): number
	local rng = SeedManager.Create(seed):SubSeed("terrain")
	return getSlopeAt(x, z, rng)
end

--[=[
	Raycast to find actual terrain height (after generation).
	@param x -- World X coordinate
	@param z -- World Z coordinate
	@return number? -- Actual terrain height, or nil if no terrain
]=]
function TerrainGenerator.RaycastHeight(x: number, z: number): number?
	local rayOrigin = Vector3.new(x, 200, z)
	local rayDirection = Vector3.new(0, -400, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {}
	raycastParams.IgnoreWater = true
	
	-- Raycast against terrain
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if result and result.Instance == terrain then
		return result.Position.Y
	end
	
	-- Try terrain-specific raycast
	local cellPos = terrain:WorldToCell(Vector3.new(x, 100, z))
	local region = Region3.new(
		Vector3.new(x - 2, -10, z - 2),
		Vector3.new(x + 2, 200, z + 2)
	)
	
	-- Read material to check if there's terrain
	local materials, occupancy = terrain:ReadVoxels(region:ExpandToGrid(4), 4)
	
	-- Find highest occupied voxel
	if materials then
		local sizeY = #materials[1]
		for y = sizeY, 1, -1 do
			if materials[1][y] and materials[1][y][1] ~= Enum.Material.Air then
				return -10 + (y - 1) * 4 + 2
			end
		end
	end
	
	return nil
end

return TerrainGenerator
