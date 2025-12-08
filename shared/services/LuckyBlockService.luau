--!strict
-- LuckyBlockService.luau
-- Shared service for Lucky Block logic (server-side and utility functions)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = script.Parent.Parent
local AnimalLibraryModule = require(Shared:WaitForChild("data"):WaitForChild("AnimalLibraryModule"))
local LuckyBlockConfig = require(Shared:WaitForChild("config"):WaitForChild("LuckyBlockConfig"))
local LuckyBlockTypes = require(Shared:WaitForChild("data"):WaitForChild("LuckyBlockTypes"))

local LuckyBlockService = {}

-- Map SpawnChance ranges to rarity tiers
-- This is a heuristic based on the SpawnChance values in AnimalLibraryModule
local function getAnimalRarity(spawnChance: number): LuckyBlockTypes.AnimalRarity
	if spawnChance >= 30 then
		return "Common"
	elseif spawnChance >= 15 then
		return "MediumRare"
	elseif spawnChance >= 7 then
		return "Rare"
	elseif spawnChance >= 2 then
		return "VeryRare"
	else
		return "UltraRare"
	end
end

-- Generate a random lucky block rarity for arena spawns
function LuckyBlockService.GenerateArenaBlockRarity(): LuckyBlockTypes.LuckyBlockRarity
	local roll = math.random(1, 100)
	
	if roll <= LuckyBlockConfig.ArenaUltraRareChance then
		return "UltraRare"
	elseif roll <= LuckyBlockConfig.ArenaUltraRareChance + LuckyBlockConfig.ArenaVeryRareChance then
		return "VeryRare"
	else
		return "Rare"
	end
end

-- Get a random rarity based on weights (for shop/debug purchases)
function LuckyBlockService.GetRandomRarity(): LuckyBlockTypes.LuckyBlockRarity
	local roll = math.random(1, 100)
	local weights = LuckyBlockConfig.RarityWeights
	
	if roll <= weights.UltraRare then
		return "UltraRare"
	elseif roll <= weights.UltraRare + weights.VeryRare then
		return "VeryRare"
	else
		return "Rare"
	end
end

-- Select an animal to spawn based on lucky block rarity
-- Returns the animal data from AnimalLibraryModule
function LuckyBlockService.SelectAnimalForBlock(blockRarity: LuckyBlockTypes.LuckyBlockRarity): any
	local animalList = AnimalLibraryModule.List
	
	-- Build weighted list with bonuses applied
	local weightedList = {}
	local totalWeight = 0
	
	for _, animal in ipairs(animalList) do
		local baseChance = animal.SpawnChance or 0
		local animalRarity = getAnimalRarity(baseChance)
		
		-- Apply rarity bonus from lucky block
		local bonus = LuckyBlockConfig.RarityBonuses[blockRarity][animalRarity] or 0
		local finalWeight = baseChance + bonus
		
		if finalWeight > 0 then
			table.insert(weightedList, {
				Animal = animal,
				Weight = finalWeight,
			})
			totalWeight = totalWeight + finalWeight
		end
	end
	
	-- Select random animal based on weighted chances
	if totalWeight == 0 then
		-- Fallback to first animal if something went wrong
		return animalList[1]
	end
	
	local roll = math.random() * totalWeight
	local accumulated = 0
	
	for _, entry in ipairs(weightedList) do
		accumulated = accumulated + entry.Weight
		if roll <= accumulated then
			return entry.Animal
		end
	end
	
	-- Fallback (shouldn't reach here)
	return weightedList[#weightedList].Animal
end

-- Generate a random spawn position within arena bounds
function LuckyBlockService.GenerateArenaSpawnPosition(arenaFolder: Folder): Vector3?
	-- Look for spawn boundary or use default arena center
	local spawnZone = arenaFolder:FindFirstChild("LuckyBlockSpawnZone")
	
	if spawnZone and spawnZone:IsA("Part") then
		-- Spawn within the bounds of the spawn zone part
		local pos = spawnZone.Position
		local size = spawnZone.Size
		
		local randomX = pos.X + (math.random() - 0.5) * size.X * 0.8
		local randomZ = pos.Z + (math.random() - 0.5) * size.Z * 0.8
		local y = pos.Y + size.Y / 2 + 5  -- Slightly above ground
		
		return Vector3.new(randomX, y, randomZ)
	else
		-- Default: spawn at arena center with some randomness
		local center = Vector3.new(0, 50, 0)
		local radius = 80
		
		local angle = math.random() * math.pi * 2
		local distance = math.random() * radius
		
		local x = center.X + math.cos(angle) * distance
		local z = center.Z + math.sin(angle) * distance
		
		return Vector3.new(x, center.Y, z)
	end
end

-- Create the visual lucky block model
function LuckyBlockService.CreateLuckyBlockModel(rarity: LuckyBlockTypes.LuckyBlockRarity, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "LuckyBlock_" .. rarity
	
	-- Create gift box base
	local box = Instance.new("Part")
	box.Name = "GiftBox"
	box.Size = Vector3.new(4, 4, 4)
	box.Position = position
	box.Anchored = true
	box.CanCollide = true
	
	-- Color based on rarity
	if rarity == "Rare" then
		box.BrickColor = BrickColor.new("Bright blue")
	elseif rarity == "VeryRare" then
		box.BrickColor = BrickColor.new("Bright violet")
	elseif rarity == "UltraRare" then
		box.BrickColor = BrickColor.new("Gold")
	end
	
	box.Material = Enum.Material.SmoothPlastic
	box.Parent = model
	
	-- Add ribbon (cross on top)
	local ribbon1 = Instance.new("Part")
	ribbon1.Name = "Ribbon1"
	ribbon1.Size = Vector3.new(4.2, 0.5, 0.8)
	ribbon1.Position = position + Vector3.new(0, 0, 0)
	ribbon1.BrickColor = BrickColor.new("Institutional white")
	ribbon1.Material = Enum.Material.SmoothPlastic
	ribbon1.Anchored = true
	ribbon1.CanCollide = false
	ribbon1.Parent = model
	
	local ribbon2 = Instance.new("Part")
	ribbon2.Name = "Ribbon2"
	ribbon2.Size = Vector3.new(0.8, 0.5, 4.2)
	ribbon2.Position = position + Vector3.new(0, 0, 0)
	ribbon2.BrickColor = BrickColor.new("Institutional white")
	ribbon2.Material = Enum.Material.SmoothPlastic
	ribbon2.Anchored = true
	ribbon2.CanCollide = false
	ribbon2.Parent = model
	
	-- Create floating question mark
	local qMark = Instance.new("Part")
	qMark.Name = "QuestionMark"
	qMark.Size = Vector3.new(1, 1, 0.2)
	qMark.Position = position + Vector3.new(0, 5, 0)
	qMark.BrickColor = BrickColor.new("Bright yellow")
	qMark.Material = Enum.Material.Neon
	qMark.Anchored = true
	qMark.CanCollide = false
	qMark.Shape = Enum.PartType.Ball
	qMark.Parent = model
	
	-- Add glow effect
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 15
	if rarity == "Rare" then
		light.Color = Color3.fromRGB(0, 100, 255)
	elseif rarity == "VeryRare" then
		light.Color = Color3.fromRGB(180, 0, 255)
	elseif rarity == "UltraRare" then
		light.Color = Color3.fromRGB(255, 215, 0)
	end
	light.Parent = box
	
	-- Add label for rarity
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "RarityLabel"
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = box
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = rarity
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Parent = billboardGui
	
	-- Add a ProximityPrompt for interaction
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "PickupPrompt"
	proximityPrompt.ActionText = "Open Lucky Block"
	proximityPrompt.ObjectText = rarity .. " Lucky Block"
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = box
	
	model.PrimaryPart = box
	
	return model
end

-- Create isolation zone (lobby only)
function LuckyBlockService.CreateIsolationZone(position: Vector3, ownerPlayer: Player): Part
	local cylinder = Instance.new("Part")
	cylinder.Name = "IsolationZone_" .. ownerPlayer.Name
	cylinder.Shape = Enum.PartType.Cylinder
	cylinder.Size = Vector3.new(
		LuckyBlockConfig.IsolationZoneHeight,
		LuckyBlockConfig.IsolationZoneRadius * 2,
		LuckyBlockConfig.IsolationZoneRadius * 2
	)
	cylinder.Position = position
	cylinder.Rotation = Vector3.new(0, 0, 90) -- Orient cylinder vertically
	cylinder.Anchored = true
	cylinder.CanCollide = false -- Don't collide with anyone
	cylinder.Transparency = 0.7
	cylinder.BrickColor = BrickColor.new("Electric blue")
	cylinder.Material = Enum.Material.ForceField
	
	-- Visual only - doesn't block movement
	cylinder:SetAttribute("Owner", ownerPlayer.UserId)
	
	return cylinder
end

return LuckyBlockService
