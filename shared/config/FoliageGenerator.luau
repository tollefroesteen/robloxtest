--!strict
-- FoliageGenerator.luau
-- Populates terrain with vegetation and rocks using Poisson disk sampling
-- Places grass clumps, bushes, trees in play area; rocks in transition/mountains
--
-- SHARED MODULE: Can be used by both Arena and Lobby places

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedManager = require(script.Parent.Parent:WaitForChild("util"):WaitForChild("SeedManager"))
local ProceduralConfig = require(script.Parent:WaitForChild("ProceduralConfig"))
local Log = require(script.Parent.Parent:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "FoliageGenerator"

type SeededRandom = SeedManager.SeededRandom

local FoliageGenerator = {}

-- Folder to hold all generated foliage
local foliageFolder: Folder? = nil

-- Colors for procedural foliage
local Colors = {
	TreeTrunk = Color3.fromRGB(101, 67, 33),
	TreeLeaves = Color3.fromRGB(34, 139, 34),
	TreeLeavesDark = Color3.fromRGB(25, 100, 25),
	Bush = Color3.fromRGB(46, 125, 50),
	BushDark = Color3.fromRGB(30, 90, 30),
	GrassTall = Color3.fromRGB(124, 179, 66),
	GrassDark = Color3.fromRGB(85, 139, 47),
	RockGray = Color3.fromRGB(128, 128, 128),
	RockDark = Color3.fromRGB(80, 80, 80),
	RockLight = Color3.fromRGB(160, 160, 160),
}

--[=[
	Create a simple procedural tree.
	@param position -- World position for tree base
	@param rng -- Seeded random generator
	@param sizeMult -- Size multiplier
	@return Model
]=]
local function createTree(position: Vector3, rng: SeededRandom, sizeMult: number): Model
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	
	-- Trunk
	local trunkHeight = rng:NextNumber(8, 14) * sizeMult
	local trunkWidth = rng:NextNumber(1.5, 2.5) * sizeMult
	
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(trunkWidth, trunkHeight, trunkWidth)
	trunk.Position = position + Vector3.new(0, trunkHeight / 2, 0)
	trunk.Color = Colors.TreeTrunk
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.Parent = tree
	
	-- Leaves (multiple spheres for fuller look)
	local leafRadius = rng:NextNumber(4, 6) * sizeMult
	local leafPositions = {
		Vector3.new(0, trunkHeight + leafRadius * 0.5, 0),
		Vector3.new(leafRadius * 0.4, trunkHeight + leafRadius * 0.2, 0),
		Vector3.new(-leafRadius * 0.4, trunkHeight + leafRadius * 0.2, 0),
		Vector3.new(0, trunkHeight + leafRadius * 0.2, leafRadius * 0.4),
		Vector3.new(0, trunkHeight + leafRadius * 0.2, -leafRadius * 0.4),
	}
	
	for i, offset in leafPositions do
		local leaf = Instance.new("Part")
		leaf.Name = "Leaves" .. i
		leaf.Shape = Enum.PartType.Ball
		leaf.Size = Vector3.new(leafRadius * rng:NextNumber(0.8, 1.2), leafRadius * rng:NextNumber(0.6, 0.9), leafRadius * rng:NextNumber(0.8, 1.2))
		leaf.Position = position + offset
		leaf.Color = if rng:NextBool(0.5) then Colors.TreeLeaves else Colors.TreeLeavesDark
		leaf.Material = Enum.Material.Grass
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.CastShadow = true
		leaf.Parent = tree
	end
	
	tree.PrimaryPart = trunk
	return tree
end

--[=[
	Create a simple procedural bush.
	@param position -- World position for bush
	@param rng -- Seeded random generator
	@param sizeMult -- Size multiplier
	@return Model
]=]
local function createBush(position: Vector3, rng: SeededRandom, sizeMult: number): Model
	local bush = Instance.new("Model")
	bush.Name = "Bush"
	
	-- Main bush body (flattened sphere)
	local width = rng:NextNumber(2, 4) * sizeMult
	local height = rng:NextNumber(1.5, 2.5) * sizeMult
	
	local main = Instance.new("Part")
	main.Name = "Main"
	main.Shape = Enum.PartType.Ball
	main.Size = Vector3.new(width, height, width)
	main.Position = position + Vector3.new(0, height / 2, 0)
	main.Color = if rng:NextBool(0.6) then Colors.Bush else Colors.BushDark
	main.Material = Enum.Material.Grass
	main.Anchored = true
	main.CanCollide = true
	main.Parent = bush
	
	-- Add some smaller bumps for variation
	if rng:NextBool(0.5) then
		local bump = Instance.new("Part")
		bump.Name = "Bump"
		bump.Shape = Enum.PartType.Ball
		bump.Size = Vector3.new(width * 0.6, height * 0.7, width * 0.6)
		bump.Position = position + Vector3.new(width * 0.3 * rng:NextNumber(-1, 1), height * 0.3, width * 0.3 * rng:NextNumber(-1, 1))
		bump.Color = Colors.BushDark
		bump.Material = Enum.Material.Grass
		bump.Anchored = true
		bump.CanCollide = false
		bump.Parent = bush
	end
	
	bush.PrimaryPart = main
	return bush
end

--[=[
	Create a tall grass clump.
	@param position -- World position
	@param rng -- Seeded random generator
	@param sizeMult -- Size multiplier
	@return Model
]=]
local function createGrassClump(position: Vector3, rng: SeededRandom, sizeMult: number): Model
	local grass = Instance.new("Model")
	grass.Name = "GrassClump"
	
	-- Create several thin tall parts
	local bladeCount = rng:NextInteger(3, 6)
	local baseHeight = rng:NextNumber(1, 2) * sizeMult
	
	for i = 1, bladeCount do
		local blade = Instance.new("Part")
		blade.Name = "Blade" .. i
		blade.Size = Vector3.new(0.2, baseHeight * rng:NextNumber(0.7, 1.3), 0.2)
		
		local offsetX = rng:NextNumber(-0.5, 0.5) * sizeMult
		local offsetZ = rng:NextNumber(-0.5, 0.5) * sizeMult
		blade.Position = position + Vector3.new(offsetX, blade.Size.Y / 2, offsetZ)
		
		-- Slight random rotation
		blade.CFrame = blade.CFrame * CFrame.Angles(
			math.rad(rng:NextNumber(-15, 15)),
			math.rad(rng:NextNumber(0, 360)),
			math.rad(rng:NextNumber(-15, 15))
		)
		
		blade.Color = if rng:NextBool(0.7) then Colors.GrassTall else Colors.GrassDark
		blade.Material = Enum.Material.Grass
		blade.Anchored = true
		blade.CanCollide = false
		blade.CastShadow = false
		blade.Parent = grass
	end
	
	return grass
end

--[=[
	Create a procedural rock.
	@param position -- World position
	@param rng -- Seeded random generator
	@param sizeMult -- Size multiplier
	@param isLarge -- Whether this is a large boulder
	@return Part
]=]
local function createRock(position: Vector3, rng: SeededRandom, sizeMult: number, isLarge: boolean): Part
	local rock = Instance.new("Part")
	rock.Name = if isLarge then "Boulder" else "Rock"
	
	local baseSize = if isLarge then rng:NextNumber(4, 8) else rng:NextNumber(1, 3)
	baseSize = baseSize * sizeMult
	
	-- Irregular size
	rock.Size = Vector3.new(
		baseSize * rng:NextNumber(0.8, 1.3),
		baseSize * rng:NextNumber(0.5, 1.0),
		baseSize * rng:NextNumber(0.8, 1.3)
	)
	
	rock.Position = position + Vector3.new(0, rock.Size.Y / 2, 0)
	
	-- Random rotation for variety
	rock.CFrame = rock.CFrame * CFrame.Angles(
		math.rad(rng:NextNumber(-10, 10)),
		math.rad(rng:NextNumber(0, 360)),
		math.rad(rng:NextNumber(-10, 10))
	)
	
	-- Random rock color
	local colorChoice = rng:NextNumber()
	if colorChoice < 0.4 then
		rock.Color = Colors.RockGray
	elseif colorChoice < 0.7 then
		rock.Color = Colors.RockDark
	else
		rock.Color = Colors.RockLight
	end
	
	rock.Material = Enum.Material.Rock
	rock.Anchored = true
	rock.CanCollide = true
	
	return rock
end

--[=[
	Poisson disk sampling for natural distribution.
	@param minX -- Minimum X bound
	@param maxX -- Maximum X bound  
	@param minZ -- Minimum Z bound
	@param maxZ -- Maximum Z bound
	@param minDist -- Minimum distance between points
	@param rng -- Seeded random generator
	@param maxPoints -- Maximum points to generate (optional)
	@return {Vector2} -- Array of 2D positions
]=]
local function poissonDiskSample(minX: number, maxX: number, minZ: number, maxZ: number, minDist: number, rng: SeededRandom, maxPoints: number?): {Vector2}
	local cellSize = minDist / math.sqrt(2)
	local gridWidth = math.ceil((maxX - minX) / cellSize)
	local gridHeight = math.ceil((maxZ - minZ) / cellSize)
	
	local grid: {{Vector2?}} = {}
	for _ = 1, gridWidth do
		local col = {}
		for _ = 1, gridHeight do
			table.insert(col, nil)
		end
		table.insert(grid, col)
	end
	
	local points: {Vector2} = {}
	local activeList: {Vector2} = {}
	local maxAttempts = 30
	local limit = maxPoints or 10000
	
	-- Helper to get grid cell
	local function getCell(p: Vector2): (number, number)
		local cx = math.floor((p.X - minX) / cellSize) + 1
		local cz = math.floor((p.Y - minZ) / cellSize) + 1
		return math.clamp(cx, 1, gridWidth), math.clamp(cz, 1, gridHeight)
	end
	
	-- Helper to check if point is valid
	local function isValid(p: Vector2): boolean
		if p.X < minX or p.X > maxX or p.Y < minZ or p.Y > maxZ then
			return false
		end
		
		local cx, cz = getCell(p)
		
		-- Check neighboring cells
		for dx = -2, 2 do
			for dz = -2, 2 do
				local nx = cx + dx
				local nz = cz + dz
				if nx >= 1 and nx <= gridWidth and nz >= 1 and nz <= gridHeight then
					local neighbor = grid[nx][nz]
					if neighbor then
						local dist = (p - neighbor).Magnitude
						if dist < minDist then
							return false
						end
					end
				end
			end
		end
		
		return true
	end
	
	-- Start with random point
	local startPoint = Vector2.new(
		rng:NextNumber(minX, maxX),
		rng:NextNumber(minZ, maxZ)
	)
	table.insert(points, startPoint)
	table.insert(activeList, startPoint)
	local cx, cz = getCell(startPoint)
	grid[cx][cz] = startPoint
	
	-- Generate points
	while #activeList > 0 and #points < limit do
		local idx = rng:NextInteger(1, #activeList)
		local point = activeList[idx]
		local foundValid = false
		
		for _ = 1, maxAttempts do
			local angle = rng:NextNumber(0, math.pi * 2)
			local dist = rng:NextNumber(minDist, minDist * 2)
			
			local newPoint = Vector2.new(
				point.X + math.cos(angle) * dist,
				point.Y + math.sin(angle) * dist
			)
			
			if isValid(newPoint) then
				table.insert(points, newPoint)
				table.insert(activeList, newPoint)
				local ncx, ncz = getCell(newPoint)
				grid[ncx][ncz] = newPoint
				foundValid = true
				break
			end
		end
		
		if not foundValid then
			table.remove(activeList, idx)
		end
	end
	
	return points
end

--[=[
	Get terrain height using raycast (requires terrain to be generated).
	@param x -- World X
	@param z -- World Z
	@return number? -- Height or nil
]=]
local function getTerrainHeight(x: number, z: number): number?
	local rayOrigin = Vector3.new(x, 200, z)
	local rayDirection = Vector3.new(0, -400, 0)
	
	local result = workspace:Raycast(rayOrigin, rayDirection)
	
	if result and result.Instance == workspace.Terrain then
		return result.Position.Y
	end
	
	return nil
end

--[=[
	Generate all foliage for the world.
	@param seed -- Integer seed for reproducible generation (must match terrain seed)
]=]
function FoliageGenerator.Generate(seed: number): ()
	Log.Info(CONTEXT, string.format("Starting foliage generation with seed: %d", seed))
	local startTime = os.clock()
	
	local rng = SeedManager.Create(seed):SubSeed("foliage")
	
	-- Create or clear foliage folder
	if foliageFolder then
		foliageFolder:ClearAllChildren()
	else
		foliageFolder = Instance.new("Folder")
		foliageFolder.Name = "GeneratedFoliage"
		foliageFolder.Parent = workspace
	end
	
	local config = ProceduralConfig.Foliage
	local playArea = ProceduralConfig.PlayArea
	local world = ProceduralConfig.World
	local transition = ProceduralConfig.Transition
	
	local placedCount = {
		trees = 0,
		bushes = 0,
		grass = 0,
		rocks = 0,
	}
	
	-- Create sub-RNGs for each foliage type
	local treeRng = rng:SubSeed("trees")
	local bushRng = rng:SubSeed("bushes")
	local grassRng = rng:SubSeed("grass")
	local rockRng = rng:SubSeed("rocks")
	
	-- =========================================================================
	-- TREES (sparse, mostly at edges of play area)
	-- =========================================================================
	Log.Info(CONTEXT, "Generating trees...")
	
	local treeSpacing = math.sqrt(1000 / config.TreeDensity) * 2
	local treePoints = poissonDiskSample(
		playArea.MinX + 20, playArea.MaxX - 20,  -- Keep away from center
		playArea.MinZ + 20, playArea.MaxZ - 20,
		treeSpacing, treeRng, 100
	)
	
	for _, point in treePoints do
		-- Prefer edges of play area
		local distFromCenterX = math.abs(point.X) / (playArea.SizeX / 2)
		local distFromCenterZ = math.abs(point.Y) / (playArea.SizeZ / 2)
		local edgeFactor = math.max(distFromCenterX, distFromCenterZ)
		
		-- Higher chance near edges
		if treeRng:NextNumber() > edgeFactor * 0.8 then
			continue
		end
		
		local height = getTerrainHeight(point.X, point.Y)
		if not height then continue end
		
		local sizeMult = treeRng:NextNumber(config.SizeVariationMin, config.SizeVariationMax)
		local tree = createTree(Vector3.new(point.X, height, point.Y), treeRng, sizeMult)
		tree.Parent = foliageFolder
		placedCount.trees += 1
	end
	
	task.wait()
	
	-- =========================================================================
	-- BUSHES (moderate density in play area)
	-- =========================================================================
	Log.Info(CONTEXT, "Generating bushes...")
	
	local bushSpacing = math.sqrt(1000 / config.BushDensity)
	local bushPoints = poissonDiskSample(
		playArea.MinX, playArea.MaxX,
		playArea.MinZ, playArea.MaxZ,
		bushSpacing, bushRng, 500
	)
	
	for _, point in bushPoints do
		local height = getTerrainHeight(point.X, point.Y)
		if not height then continue end
		
		local sizeMult = bushRng:NextNumber(config.SizeVariationMin, config.SizeVariationMax)
		local bush = createBush(Vector3.new(point.X, height, point.Y), bushRng, sizeMult)
		bush.Parent = foliageFolder
		placedCount.bushes += 1
	end
	
	task.wait()
	
	-- =========================================================================
	-- GRASS CLUMPS (high density in play area)
	-- =========================================================================
	Log.Info(CONTEXT, "Generating grass clumps...")
	
	local grassSpacing = math.sqrt(1000 / config.GrassClumpDensity)
	local grassPoints = poissonDiskSample(
		playArea.MinX, playArea.MaxX,
		playArea.MinZ, playArea.MaxZ,
		grassSpacing, grassRng, 2000
	)
	
	for _, point in grassPoints do
		local height = getTerrainHeight(point.X, point.Y)
		if not height then continue end
		
		local sizeMult = grassRng:NextNumber(config.SizeVariationMin, config.SizeVariationMax)
		local grass = createGrassClump(Vector3.new(point.X, height, point.Y), grassRng, sizeMult)
		grass.Parent = foliageFolder
		placedCount.grass += 1
		
		-- Yield occasionally
		if placedCount.grass % 100 == 0 then
			task.wait()
		end
	end
	
	-- =========================================================================
	-- ROCKS (small in play area, large in transition/mountains)
	-- =========================================================================
	Log.Info(CONTEXT, "Generating rocks...")
	
	-- Small decorative rocks in play area
	local smallRockSpacing = math.sqrt(1000 / config.SmallRockDensity)
	local smallRockPoints = poissonDiskSample(
		playArea.MinX, playArea.MaxX,
		playArea.MinZ, playArea.MaxZ,
		smallRockSpacing, rockRng, 200
	)
	
	for _, point in smallRockPoints do
		local height = getTerrainHeight(point.X, point.Y)
		if not height then continue end
		
		local sizeMult = rockRng:NextNumber(config.SizeVariationMin, config.SizeVariationMax)
		local rock = createRock(Vector3.new(point.X, height, point.Y), rockRng, sizeMult, false)
		rock.Parent = foliageFolder
		placedCount.rocks += 1
	end
	
	-- Large boulders in transition zone
	local transitionMinX = playArea.MinX - transition.Width
	local transitionMaxX = playArea.MaxX + transition.Width
	local transitionMinZ = playArea.MinZ - transition.Width
	local transitionMaxZ = playArea.MaxZ + transition.Width
	
	local largeRockSpacing = math.sqrt(1000 / config.LargeRockDensity)
	local largeRockPoints = poissonDiskSample(
		transitionMinX, transitionMaxX,
		transitionMinZ, transitionMaxZ,
		largeRockSpacing, rockRng:SubSeed("large"), 300
	)
	
	for _, point in largeRockPoints do
		-- Only place in transition zone
		local zone = ProceduralConfig.GetZone(point.X, point.Y)
		if zone == "PlayArea" then continue end
		
		local height = getTerrainHeight(point.X, point.Y)
		if not height then continue end
		
		local sizeMult = rockRng:NextNumber(config.SizeVariationMin, config.SizeVariationMax)
		local rock = createRock(Vector3.new(point.X, height, point.Y), rockRng, sizeMult * 1.5, true)
		rock.Parent = foliageFolder
		placedCount.rocks += 1
	end
	
	local elapsed = os.clock() - startTime
	Log.Info(CONTEXT, string.format(
		"Foliage generation complete in %.2f seconds: %d trees, %d bushes, %d grass, %d rocks",
		elapsed, placedCount.trees, placedCount.bushes, placedCount.grass, placedCount.rocks
	))
end

--[=[
	Clear all generated foliage.
]=]
function FoliageGenerator.Clear(): ()
	if foliageFolder then
		foliageFolder:ClearAllChildren()
	end
	Log.Info(CONTEXT, "Foliage cleared")
end

--[=[
	Get the foliage folder.
	@return Folder?
]=]
function FoliageGenerator.GetFolder(): Folder?
	return foliageFolder
end

return FoliageGenerator
