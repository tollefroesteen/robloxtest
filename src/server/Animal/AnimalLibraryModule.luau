-- ModuleScript: PartLibraryModule
local PartLibrary = {}

-- Define your parts with SpawnChance and unique ID
PartLibrary.List = {
	{
		ID = "RR01",
		Name = "RedRunner",
		Color = BrickColor.new("Bright white"),
		PointValue = 1,
		MaxSpeed = 0.3,
		Hungriness = 0.5,
		FearFactor = 0.6,
		ObservationRadius = 20,
		SpawnChance = 50
	},
	{
		ID = "BB01",
		Name = "BlueBouncer",
		Color = BrickColor.new("Bright blue"),
		PointValue = 3,
		MaxSpeed = 0.4,
		Hungriness = 0.8,
		FearFactor = 0.3,
		ObservationRadius = 25,
		SpawnChance = 20
	},
	{
		ID = "YC01",
		Name = "YellowCrawler",
		Color = BrickColor.new("Bright yellow"),
		PointValue = 5,
		MaxSpeed = 0.15,
		Hungriness = 0.3,
		FearFactor = 0.9,
		ObservationRadius = 15,
		SpawnChance = 10
	},
	{
		ID = "OC01",
		Name = "OrangeCrawler",
		Color = BrickColor.new("Bright orange"),
		PointValue = 6,
		MaxSpeed = 0.15,
		Hungriness = 0.3,
		FearFactor = 0.9,
		ObservationRadius = 15,
		SpawnChance = 10
	},
	{
		ID = "GS01",
		Name = "GreenScout",
		Color = BrickColor.new("Bright green"),
		PointValue = 8,
		MaxSpeed = 0.35,
		Hungriness = 0.9,
		FearFactor = 0.4,
		ObservationRadius = 35,
		SpawnChance = 5
	},
	{
		ID = "BS01",
		Name = "BlusihScout",
		Color = BrickColor.new("Bright bluish green"),
		PointValue = 10,
		MaxSpeed = 0.35,
		Hungriness = 0.9,
		FearFactor = 0.4,
		ObservationRadius = 35,
		SpawnChance = 5
	},
}

-- Helper: get a random part type using weighted probabilities
function PartLibrary.GetRandomType()
	local list = PartLibrary.List
	local totalWeight = 0

	for _, partType in ipairs(list) do
		totalWeight += partType.SpawnChance or 0
	end

	if totalWeight <= 0 then
		warn("No valid SpawnChance values found. Returning first part.")
		return list[1]
	end

	local rand = math.random(1, totalWeight)
	local cumulative = 0

	for _, partType in ipairs(list) do
		cumulative += partType.SpawnChance or 0
		if rand <= cumulative then
			return partType
		end
	end

	return list[#list]
end

-- Optional helper to get part type by ID
function PartLibrary.GetByID(id)
	for _, partType in ipairs(PartLibrary.List) do
		if partType.ID == id then
			return partType
		end
	end
	return nil
end

return PartLibrary
