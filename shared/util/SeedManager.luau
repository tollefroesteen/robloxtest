--!strict
-- SeedManager.luau
-- Deterministic random number generation with seeded RNG and noise functions
-- Provides reproducible randomness for procedural generation

local CONTEXT = "SeedManager"

--[=[
	@class SeededRandom
	A seeded random number generator that produces deterministic sequences.
	Given the same seed, it will always produce the same sequence of values.
]=]

export type SeededRandom = {
	-- Core RNG
	NextNumber: (self: SeededRandom, min: number?, max: number?) -> number,
	NextInteger: (self: SeededRandom, min: number, max: number) -> number,
	NextBool: (self: SeededRandom, probability: number?) -> boolean,
	
	-- Vector generation
	NextVector2: (self: SeededRandom) -> Vector2,
	NextVector3: (self: SeededRandom) -> Vector3,
	NextPointInCircle: (self: SeededRandom, radius: number?) -> Vector2,
	NextPointInSphere: (self: SeededRandom, radius: number?) -> Vector3,
	
	-- Noise functions
	Noise2D: (self: SeededRandom, x: number, z: number, scale: number?, octaves: number?, persistence: number?, lacunarity: number?) -> number,
	Noise3D: (self: SeededRandom, x: number, y: number, z: number, scale: number?) -> number,
	
	-- Utility
	SubSeed: (self: SeededRandom, name: string) -> SeededRandom,
	Shuffle: <T>(self: SeededRandom, array: {T}) -> {T},
	Choose: <T>(self: SeededRandom, array: {T}) -> T?,
	WeightedChoice: <T>(self: SeededRandom, options: {{item: T, weight: number}}) -> T?,
	
	-- State
	GetSeed: (self: SeededRandom) -> number,
	Clone: (self: SeededRandom) -> SeededRandom,
}

local SeedManager = {}

-- Large prime numbers for seed hashing
local PRIME1 = 198491317
local PRIME2 = 6542989
local PRIME3 = 357239

--[=[
	Convert any seed (string or number) to a consistent numeric seed.
	@param seed -- The seed value (string or number)
	@return number -- A consistent numeric seed
]=]
local function hashSeed(seed: string | number): number
	if type(seed) == "number" then
		-- Ensure it's a positive integer
		return math.abs(math.floor(seed)) % 2147483647 + 1
	end
	
	-- Hash string to number using DJB2-like algorithm
	local hash = 5381
	for i = 1, #seed do
		local char = string.byte(seed, i)
		hash = ((hash * 33) + char) % 2147483647
	end
	return hash + 1
end

--[=[
	Create a sub-seed by combining parent seed with a name.
	This ensures different systems get different but deterministic sequences.
]=]
local function combineSeeds(parentSeed: number, name: string): number
	local nameHash = hashSeed(name)
	-- Combine using multiplication and XOR for good distribution
	local combined = (parentSeed * PRIME1) % 2147483647
	combined = bit32.bxor(combined, nameHash * PRIME2) % 2147483647
	combined = (combined * PRIME3) % 2147483647
	return combined + 1
end

--[=[
	Create a new SeededRandom instance.
	@param seed -- The seed value (string, number, or nil for random)
	@return SeededRandom -- A new seeded random generator
]=]
function SeedManager.Create(seed: (string | number)?): SeededRandom
	local numericSeed: number
	
	if seed == nil then
		-- Use current time + random for truly random seed
		numericSeed = hashSeed(os.time() + math.random(1, 1000000))
	else
		numericSeed = hashSeed(seed)
	end
	
	-- Create Roblox's Random object with our seed
	local rng = Random.new(numericSeed)
	
	-- Offset for noise functions to make them seed-dependent
	local noiseOffsetX = (numericSeed % 10000) / 10
	local noiseOffsetZ = ((numericSeed * PRIME1) % 10000) / 10
	local noiseOffsetY = ((numericSeed * PRIME2) % 10000) / 10
	
	local self = {} :: SeededRandom
	
	--[=[
		Generate a random float.
		@param min -- Minimum value (default 0)
		@param max -- Maximum value (default 1)
		@return number -- Random float in range [min, max)
	]=]
	function self:NextNumber(min: number?, max: number?): number
		local minVal = min or 0
		local maxVal = max or 1
		return rng:NextNumber() * (maxVal - minVal) + minVal
	end
	
	--[=[
		Generate a random integer.
		@param min -- Minimum value (inclusive)
		@param max -- Maximum value (inclusive)
		@return number -- Random integer in range [min, max]
	]=]
	function self:NextInteger(min: number, max: number): number
		return rng:NextInteger(min, max)
	end
	
	--[=[
		Generate a random boolean.
		@param probability -- Chance of true (default 0.5)
		@return boolean
	]=]
	function self:NextBool(probability: number?): boolean
		return rng:NextNumber() < (probability or 0.5)
	end
	
	--[=[
		Generate a random unit Vector2.
		@return Vector2 -- Unit vector pointing in random direction
	]=]
	function self:NextVector2(): Vector2
		local angle = rng:NextNumber() * math.pi * 2
		return Vector2.new(math.cos(angle), math.sin(angle))
	end
	
	--[=[
		Generate a random unit Vector3.
		@return Vector3 -- Unit vector pointing in random direction
	]=]
	function self:NextVector3(): Vector3
		-- Use spherical coordinates for uniform distribution
		local theta = rng:NextNumber() * math.pi * 2
		local phi = math.acos(2 * rng:NextNumber() - 1)
		return Vector3.new(
			math.sin(phi) * math.cos(theta),
			math.sin(phi) * math.sin(theta),
			math.cos(phi)
		)
	end
	
	--[=[
		Generate a random point within a circle.
		@param radius -- Circle radius (default 1)
		@return Vector2 -- Point within the circle
	]=]
	function self:NextPointInCircle(radius: number?): Vector2
		local r = radius or 1
		-- Use square root for uniform distribution
		local distance = math.sqrt(rng:NextNumber()) * r
		local angle = rng:NextNumber() * math.pi * 2
		return Vector2.new(
			math.cos(angle) * distance,
			math.sin(angle) * distance
		)
	end
	
	--[=[
		Generate a random point within a sphere.
		@param radius -- Sphere radius (default 1)
		@return Vector3 -- Point within the sphere
	]=]
	function self:NextPointInSphere(radius: number?): Vector3
		local r = radius or 1
		-- Use cube root for uniform distribution in 3D
		local distance = (rng:NextNumber() ^ (1/3)) * r
		local dir = self:NextVector3()
		return dir * distance
	end
	
	--[=[
		Sample 2D Perlin noise with octaves (fractal noise).
		@param x -- X coordinate
		@param z -- Z coordinate
		@param scale -- Base scale (default 1, larger = more zoomed out)
		@param octaves -- Number of noise layers (default 1)
		@param persistence -- Amplitude decay per octave (default 0.5)
		@param lacunarity -- Frequency increase per octave (default 2)
		@return number -- Noise value in range approximately [-1, 1]
	]=]
	function self:Noise2D(x: number, z: number, scale: number?, octaves: number?, persistence: number?, lacunarity: number?): number
		local s = scale or 1
		local oct = octaves or 1
		local pers = persistence or 0.5
		local lac = lacunarity or 2
		
		-- Apply seed offset
		local sampleX = (x / s) + noiseOffsetX
		local sampleZ = (z / s) + noiseOffsetZ
		
		if oct == 1 then
			-- Simple single-octave noise
			return math.noise(sampleX, sampleZ)
		end
		
		-- Fractal noise with multiple octaves
		local total = 0
		local amplitude = 1
		local frequency = 1
		local maxValue = 0
		
		for _ = 1, oct do
			total += math.noise(sampleX * frequency, sampleZ * frequency) * amplitude
			maxValue += amplitude
			amplitude *= pers
			frequency *= lac
		end
		
		-- Normalize to approximately [-1, 1]
		return total / maxValue
	end
	
	--[=[
		Sample 3D Perlin noise.
		@param x -- X coordinate
		@param y -- Y coordinate
		@param z -- Z coordinate
		@param scale -- Scale (default 1)
		@return number -- Noise value in range approximately [-0.5, 0.5]
	]=]
	function self:Noise3D(x: number, y: number, z: number, scale: number?): number
		local s = scale or 1
		return math.noise(
			(x / s) + noiseOffsetX,
			(y / s) + noiseOffsetY,
			(z / s) + noiseOffsetZ
		)
	end
	
	--[=[
		Create a sub-generator with a derived seed.
		Useful for giving different systems their own deterministic sequences.
		@param name -- Name to derive the sub-seed from
		@return SeededRandom -- New generator with derived seed
	]=]
	function self:SubSeed(name: string): SeededRandom
		local subSeed = combineSeeds(numericSeed, name)
		return SeedManager.Create(subSeed)
	end
	
	--[=[
		Shuffle an array in place (Fisher-Yates).
		@param array -- Array to shuffle
		@return {T} -- The same array, shuffled
	]=]
	function self:Shuffle<T>(array: {T}): {T}
		for i = #array, 2, -1 do
			local j = rng:NextInteger(1, i)
			array[i], array[j] = array[j], array[i]
		end
		return array
	end
	
	--[=[
		Choose a random element from an array.
		@param array -- Array to choose from
		@return T? -- Random element, or nil if array is empty
	]=]
	function self:Choose<T>(array: {T}): T?
		if #array == 0 then return nil end
		return array[rng:NextInteger(1, #array)]
	end
	
	--[=[
		Choose from weighted options.
		@param options -- Array of {item, weight} pairs
		@return T? -- Chosen item based on weights
	]=]
	function self:WeightedChoice<T>(options: {{item: T, weight: number}}): T?
		if #options == 0 then return nil end
		
		-- Calculate total weight
		local totalWeight = 0
		for _, option in options do
			totalWeight += option.weight
		end
		
		if totalWeight <= 0 then return nil end
		
		-- Pick random point in total weight
		local pick = rng:NextNumber() * totalWeight
		local current = 0
		
		for _, option in options do
			current += option.weight
			if pick <= current then
				return option.item
			end
		end
		
		-- Fallback (shouldn't reach here)
		return options[#options].item
	end
	
	--[=[
		Get the numeric seed this generator was created with.
		@return number
	]=]
	function self:GetSeed(): number
		return numericSeed
	end
	
	--[=[
		Create a clone of this generator at its current state.
		Note: Due to Roblox Random limitations, this creates a new generator
		with the same initial seed (not current state).
		@return SeededRandom
	]=]
	function self:Clone(): SeededRandom
		return SeedManager.Create(numericSeed)
	end
	
	return self
end

--[=[
	Utility: Create a quick hash of a position for local variation.
	Useful for adding small variations based on world position.
	@param position -- World position
	@param seed -- Base seed to combine with
	@return number -- Hash value
]=]
function SeedManager.HashPosition(position: Vector3, seed: number?): number
	local baseSeed = seed or 0
	local x = math.floor(position.X * 100)
	local y = math.floor(position.Y * 100)
	local z = math.floor(position.Z * 100)
	
	local hash = baseSeed
	hash = bit32.bxor(hash, x * PRIME1)
	hash = bit32.bxor(hash, y * PRIME2)
	hash = bit32.bxor(hash, z * PRIME3)
	
	return (hash % 2147483647) + 1
end

--[=[
	Utility: Convert a hash to a normalized float [0, 1).
	@param hash -- Hash value from HashPosition
	@return number -- Float in range [0, 1)
]=]
function SeedManager.HashToFloat(hash: number): number
	return (hash % 1000000) / 1000000
end

return SeedManager
