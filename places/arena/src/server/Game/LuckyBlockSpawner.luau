--!strict
-- LuckyBlockSpawner.server.luau
-- Arena server-side Lucky Block spawning system via UFO

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local LuckyBlockService = require(Shared:WaitForChild("services"):WaitForChild("LuckyBlockService"))
local LuckyBlockConfig = require(Shared:WaitForChild("config"):WaitForChild("LuckyBlockConfig"))
local LuckyBlockTypes = require(Shared:WaitForChild("data"):WaitForChild("LuckyBlockTypes"))
local AnimalBuilder = require(script.Parent.Parent.Animal.AnimalBuilder)
local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "LuckyBlockSpawner"

local LuckyBlockSpawner = {}

local activeLuckyBlocks: {[string]: LuckyBlockTypes.LuckyBlockData} = {}
local isSpawningEnabled = false
local spawnLoopRunning = false

-- Generate unique ID for lucky blocks
local function generateBlockID(): string
	return "LB_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Spawn a lucky block in the arena
function LuckyBlockSpawner.SpawnLuckyBlock(arenaFolder: Folder): string?
	-- Check if we're at max capacity
	local activeCount = 0
	for _ in pairs(activeLuckyBlocks) do
		activeCount = activeCount + 1
	end
	
	if activeCount >= LuckyBlockConfig.MaxActiveArenaBlocks then
		return nil
	end
	
	-- Generate rarity and position
	local rarity = LuckyBlockService.GenerateArenaBlockRarity()
	local position = LuckyBlockService.GenerateArenaSpawnPosition(arenaFolder)
	
	if not position then
		warn("[LuckyBlockSpawner] Failed to generate spawn position")
		return nil
	end
	
	-- Create the block model
	local blockModel = LuckyBlockService.CreateLuckyBlockModel(rarity, position)
	blockModel.Parent = arenaFolder
	
	-- Generate ID and store data
	local blockID = generateBlockID()
	activeLuckyBlocks[blockID] = {
		ID = blockID,
		Rarity = rarity,
		Position = position,
		Owner = nil,
		SpawnTime = os.time(),
	}
	
	-- Set up pickup interaction
	local proximityPrompt = blockModel.PrimaryPart:FindFirstChild("PickupPrompt")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.Triggered:Connect(function(player)
			LuckyBlockSpawner.OnBlockPickup(blockID, player, arenaFolder)
		end)
	end
	
	-- Notify all clients
	RemoteEvents.LuckyBlockSpawnedEvent:FireAllClients(blockID, rarity, position)
	
	Log.Info(CONTEXT, string.format("Spawned %s lucky block at %s", rarity, tostring(position)))
	
	return blockID
end

-- Handle player picking up a lucky block in arena
function LuckyBlockSpawner.OnBlockPickup(blockID: string, player: Player, arenaFolder: Folder)
	local blockData = activeLuckyBlocks[blockID]
	
	if not blockData then
		warn("[LuckyBlockSpawner] Block not found:", blockID)
		return
	end
	
	-- Select animal based on block rarity
	local selectedAnimal = LuckyBlockService.SelectAnimalForBlock(blockData.Rarity)
	
	if not selectedAnimal then
		warn("[LuckyBlockSpawner] Failed to select animal for block:", blockID)
		return
	end
	
	Log.Info(CONTEXT, string.format("Player %s picked up %s block, spawning %s", player.Name, blockData.Rarity, selectedAnimal.Name))
	
	-- Ensure Flock folder exists (same as UFO spawner)
	local flockFolder = Workspace:FindFirstChild("Flock")
	if not flockFolder then
		flockFolder = Instance.new("Folder")
		flockFolder.Name = "Flock"
		flockFolder.Parent = Workspace
	end
	
	-- Spawn the animal at the block's location (slightly above)
	local spawnPos = blockData.Position + Vector3.new(0, 2, 0)
	local templateID = selectedAnimal.Template or "BASIC_QUADRUPED"
	local clone = AnimalBuilder.BuildAnimal(templateID, selectedAnimal.Color, spawnPos)
	
	if clone then
		-- Set all attributes (same as UFO spawner - SpawnAnimal.server.luau)
		clone:SetAttribute("TemplateID", templateID)
		clone:SetAttribute("PointValue", selectedAnimal.PointValue)
		clone:SetAttribute("CurrentPointValue", selectedAnimal.PointValue)
		clone:SetAttribute("MaxSpeed", selectedAnimal.MaxSpeed)
		clone:SetAttribute("Hungriness", selectedAnimal.Hungriness)
		clone:SetAttribute("FearFactor", selectedAnimal.FearFactor)
		clone:SetAttribute("ObservationRadius", selectedAnimal.ObservationRadius)
		clone:SetAttribute("ID", selectedAnimal.ID)
		clone:SetAttribute("Team", "None")
		clone:SetAttribute("InCage", false)
		clone:SetAttribute("MovementState", "Idle") -- Start idle since it spawned on ground
		
		-- Set color on body (Bouncepart) if present
		local visual = clone:FindFirstChild("Visual")
		if visual then
			local bouncepart = visual:FindFirstChild("Bouncepart")
			if bouncepart and selectedAnimal.Color then
				bouncepart.Color = selectedAnimal.Color.Color -- Convert BrickColor to Color3
			end
		end
		
		-- Parent to Flock folder (same as UFO spawner)
		clone.Parent = flockFolder
		
		-- Set network owner to server for physics authority
		clone:SetNetworkOwner(nil)
		
		-- Mark as ready for flocking after positions replicate
		task.delay(0.5, function()
			if clone and clone.Parent then
				clone:SetAttribute("ReadyForFlocking", true)
			end
		end)
		
		-- Fire events to notify clients and internal systems (same as UFO spawner)
		RemoteEvents.AnimalSpawnedEvent:FireAllClients(clone)
		ServerEvents.FlockSpawnedEvent:Fire(clone)
		
		-- Also notify about the lucky block pickup
		RemoteEvents.LuckyBlockPickupEvent:FireAllClients(blockID, player.UserId, selectedAnimal.ID)
		
		Log.Info(CONTEXT, string.format("Spawned %s from lucky block (Points: %d, Template: %s)", 
			selectedAnimal.Name, selectedAnimal.PointValue, templateID))
	else
		warn("[LuckyBlockSpawner] Failed to build animal model for:", selectedAnimal.Name)
	end
	
	-- Remove the lucky block
	LuckyBlockSpawner.DespawnLuckyBlock(blockID, arenaFolder)
end

-- Remove a lucky block
function LuckyBlockSpawner.DespawnLuckyBlock(blockID: string, arenaFolder: Folder)
	local blockData = activeLuckyBlocks[blockID]
	
	if not blockData then
		return
	end
	
	-- Find and destroy the model
	for _, child in ipairs(arenaFolder:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^LuckyBlock_") then
			-- Check if this is the right block by position proximity
			local primaryPart = child.PrimaryPart
			if primaryPart and (primaryPart.Position - blockData.Position).Magnitude < 1 then
				child:Destroy()
				break
			end
		end
	end
	
	-- Remove from tracking
	activeLuckyBlocks[blockID] = nil
	
	-- Notify clients
	RemoteEvents.LuckyBlockDespawnedEvent:FireAllClients(blockID)
	
	Log.Debug(CONTEXT, string.format("Despawned lucky block: %s", blockID))
end

-- Start the spawn loop
function LuckyBlockSpawner.StartSpawnLoop(arenaFolder: Folder)
	if spawnLoopRunning then
		return
	end
	
	isSpawningEnabled = true
	spawnLoopRunning = true
	
	task.spawn(function()
		while isSpawningEnabled do
			-- Random interval between min and max
			local interval = math.random(
				LuckyBlockConfig.ArenaSpawnIntervalMin,
				LuckyBlockConfig.ArenaSpawnIntervalMax
			)
			
			task.wait(interval)
			
			if isSpawningEnabled then
				LuckyBlockSpawner.SpawnLuckyBlock(arenaFolder)
			end
		end
		
		spawnLoopRunning = false
	end)
	
	Log.Info(CONTEXT, "Spawn loop started")
end

-- Stop the spawn loop
function LuckyBlockSpawner.StopSpawnLoop()
	isSpawningEnabled = false
	Log.Info(CONTEXT, "Spawn loop stopped")
end

-- Clear all active blocks
function LuckyBlockSpawner.ClearAllBlocks(arenaFolder: Folder)
	for blockID in pairs(activeLuckyBlocks) do
		LuckyBlockSpawner.DespawnLuckyBlock(blockID, arenaFolder)
	end
end

-- Debug: Spawn a lucky block in front of a player (bypasses capacity and position checks)
function LuckyBlockSpawner.SpawnLuckyBlockForPlayer(player: Player, rarityInput: string?): string?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		Log.Warn(CONTEXT, "Player has no HumanoidRootPart")
		return nil
	end
	
	-- Parse rarity
	local rarity: LuckyBlockTypes.LuckyBlockRarity = "Rare"
	if rarityInput then
		local lower = string.lower(rarityInput)
		if lower == "veryrare" or lower == "vr" then
			rarity = "VeryRare"
		elseif lower == "ultrarare" or lower == "ur" then
			rarity = "UltraRare"
		end
	end
	
	-- Spawn position in front of player
	local position = root.Position + root.CFrame.LookVector * 8 + Vector3.new(0, 2, 0)
	
	-- Create the block model
	local blockModel = LuckyBlockService.CreateLuckyBlockModel(rarity, position)
	
	-- Ensure Flock folder exists for parenting
	local flockFolder = Workspace:FindFirstChild("Flock")
	if not flockFolder then
		flockFolder = Instance.new("Folder")
		flockFolder.Name = "Flock"
		flockFolder.Parent = Workspace
	end
	
	blockModel.Parent = Workspace
	
	-- Generate ID and store data
	local blockID = generateBlockID()
	activeLuckyBlocks[blockID] = {
		ID = blockID,
		Rarity = rarity,
		Position = position,
		Owner = nil,
		SpawnTime = os.time(),
	}
	
	-- Set up pickup interaction
	local proximityPrompt = blockModel.PrimaryPart:FindFirstChild("PickupPrompt")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.Triggered:Connect(function(triggeringPlayer)
			LuckyBlockSpawner.OnBlockPickup(blockID, triggeringPlayer, Workspace :: any)
		end)
	end
	
	-- Notify all clients
	RemoteEvents.LuckyBlockSpawnedEvent:FireAllClients(blockID, rarity, position)
	
	Log.Info(CONTEXT, string.format("Debug spawned %s lucky block for %s at %s", rarity, player.Name, tostring(position)))
	
	return blockID
end

return LuckyBlockSpawner
