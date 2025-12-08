--!strict
-- LobbyLuckyBlockService.luau
-- Server-side Lucky Block management for lobby (purchases and reveals)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local LuckyBlockService = require(Shared:WaitForChild("services"):WaitForChild("LuckyBlockService"))
local LuckyBlockConfig = require(Shared:WaitForChild("config"):WaitForChild("LuckyBlockConfig"))
local LuckyBlockTypes = require(Shared:WaitForChild("data"):WaitForChild("LuckyBlockTypes"))
local ShopRegistry = require(Shared:WaitForChild("data"):WaitForChild("ShopRegistry"))
local ItemRegistry = require(Shared:WaitForChild("data"):WaitForChild("ItemRegistry"))

local LobbyLuckyBlockService = {}

-- Active lucky blocks in lobby (owned by players)
local activeLobbyBlocks: {[string]: LuckyBlockTypes.LuckyBlockData} = {}
local activeIsolationZones: {[string]: Part} = {}

-- Generate unique ID for lobby blocks
local function generateBlockID(player: Player): string
	return "LB_LOBBY_" .. player.UserId .. "_" .. os.time()
end

-- Parse rarity from item ID
local function getRarityFromItemID(itemID: string): LuckyBlockTypes.LuckyBlockRarity?
	if itemID == "LUCKY_BLOCK_RARE" then
		return "Rare"
	elseif itemID == "LUCKY_BLOCK_VERY_RARE" then
		return "VeryRare"
	elseif itemID == "LUCKY_BLOCK_ULTRA_RARE" then
		return "UltraRare"
	end
	return nil
end

-- Get favorite animals service (lazy load)
local FavoriteAnimalsService = nil
local function getFavoriteAnimalsService()
	if not FavoriteAnimalsService then
		FavoriteAnimalsService = require(script.Parent.FavoriteAnimalsService)
	end
	return FavoriteAnimalsService
end

-- Handle Lucky Block purchase request from shop
function LobbyLuckyBlockService.OnPurchaseRequest(player: Player, shopItemID: string): boolean
	-- Verify it's a lucky block item
	local shopItem = ShopRegistry.GetShopItem(shopItemID)
	if not shopItem or shopItem.Category ~= "LuckyBlocks" then
		warn("[LobbyLuckyBlockService] Invalid shop item:", shopItemID)
		return false
	end
	
	-- Get rarity
	local rarity = getRarityFromItemID(shopItem.ItemID)
	if not rarity then
		warn("[LobbyLuckyBlockService] Invalid lucky block item:", shopItem.ItemID)
		return false
	end
	
	-- Check if player already has an active block
	for blockID, blockData in pairs(activeLobbyBlocks) do
		if blockData.Owner == player then
			warn("[LobbyLuckyBlockService] Player already has an active lucky block:", player.Name)
			return false
		end
	end
	
	-- Note: Actual coin deduction is handled by shop service
	-- This function assumes the purchase is valid and coins were already deducted
	
	-- Spawn the lucky block in front of player
	local character = player.Character
	if not character or not character.PrimaryPart then
		warn("[LobbyLuckyBlockService] Player has no valid character")
		return false
	end
	
	local spawnPosition = character.PrimaryPart.Position + character.PrimaryPart.CFrame.LookVector * 8
	spawnPosition = Vector3.new(spawnPosition.X, spawnPosition.Y + 2, spawnPosition.Z)
	
	-- Create the lucky block
	local blockModel = LuckyBlockService.CreateLuckyBlockModel(rarity, spawnPosition)
	blockModel.Parent = Workspace
	
	-- Generate ID and store data
	local blockID = generateBlockID(player)
	activeLobbyBlocks[blockID] = {
		ID = blockID,
		Rarity = rarity,
		Position = spawnPosition,
		Owner = player,
		SpawnTime = os.time(),
	}
	
	-- Change prompt text for reveal
	local proximityPrompt = blockModel.PrimaryPart:FindFirstChild("PickupPrompt")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.ActionText = "Reveal Lucky Block"
		proximityPrompt.ObjectText = "Your " .. rarity .. " Lucky Block"
		
		-- Only owner can trigger
		proximityPrompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer == player then
				LobbyLuckyBlockService.OnRevealRequest(player, blockID)
			end
		end)
	end
	
	-- Notify client
	RemoteEvents.LuckyBlockSpawnedEvent:FireClient(player, blockID, rarity, spawnPosition)
	
	print("[LobbyLuckyBlockService] Spawned", rarity, "lucky block for", player.Name)
	
	return true
end

-- Handle reveal request
function LobbyLuckyBlockService.OnRevealRequest(player: Player, blockID: string)
	local blockData = activeLobbyBlocks[blockID]
	
	if not blockData then
		warn("[LobbyLuckyBlockService] Block not found:", blockID)
		return
	end
	
	if blockData.Owner ~= player then
		warn("[LobbyLuckyBlockService] Player", player.Name, "attempted to reveal someone else's block")
		return
	end
	
	-- Create isolation zone
	local isolationZone = LuckyBlockService.CreateIsolationZone(blockData.Position, player)
	isolationZone.Parent = Workspace
	activeIsolationZones[blockID] = isolationZone
	
	-- Select animal
	local selectedAnimal = LuckyBlockService.SelectAnimalForBlock(blockData.Rarity)
	
	if not selectedAnimal then
		warn("[LobbyLuckyBlockService] Failed to select animal for block:", blockID)
		return
	end
	
	print("[LobbyLuckyBlockService] Player", player.Name, "revealing", blockData.Rarity, "block - got", selectedAnimal.Name)
	
	-- Start reveal animation (notify client)
	RemoteEvents.LuckyBlockRevealStartEvent:FireClient(player, blockID, blockData.Rarity)
	
	-- Create a preview of the animal above the block using PetBuilder
	local PetBuilder = require(script.Parent.PetBuilder)
	local animalBody = PetBuilder.BuildPet(selectedAnimal.Template, selectedAnimal.Color, blockData.Position + Vector3.new(0, 6, 0))
	
	local animalPreview = Instance.new("Model")
	animalPreview.Name = "AnimalPreview_" .. blockID
	
	if animalBody then
		animalBody.Parent = animalPreview
		animalPreview.PrimaryPart = animalBody
		
		-- Add name label
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Size = UDim2.new(0, 200, 0, 50)
		billboardGui.StudsOffset = Vector3.new(0, 3, 0)
		billboardGui.AlwaysOnTop = true
		billboardGui.Parent = animalBody
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "🎉 " .. selectedAnimal.Name .. " 🎉"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.Parent = billboardGui
	end
	
	animalPreview.Parent = Workspace
	
	if animalPreview and animalPreview.PrimaryPart then
		
		-- Make it glow and spin
		for _, part in ipairs(animalPreview:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				
				-- Add glow
				local highlight = Instance.new("Highlight")
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.Parent = part
			end
		end
		
		-- Spin animation
		task.spawn(function()
			local startTime = os.clock()
			while os.clock() - startTime < LuckyBlockConfig.RevealDuration + 3 do
				if animalPreview and animalPreview.Parent and animalPreview.PrimaryPart then
					animalPreview:SetPrimaryPartCFrame(animalPreview.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(2), 0))
				end
				task.wait(0.03)
			end
			if animalPreview then
				animalPreview:Destroy()
			end
		end)
	end
	
	-- Wait for reveal duration
	task.wait(LuckyBlockConfig.RevealDuration)
	
	-- Award the animal to player (add to captured index)
	local dataService = getFavoriteAnimalsService()
	if dataService and dataService.AddAnimalToIndex then
		dataService.AddAnimalToIndex(player, selectedAnimal.ID)
	end
	
	-- Notify client of completion
	RemoteEvents.LuckyBlockRevealCompleteEvent:FireClient(player, blockID, selectedAnimal.ID, selectedAnimal.Name)
	RemoteEvents.NewAnimalDiscoveredEvent:FireClient(player, selectedAnimal.ID)
	
	-- Clean up
	task.wait(3) -- Give time to see the animal
	LobbyLuckyBlockService.DespawnLuckyBlock(blockID)
end

-- Remove a lucky block and its isolation zone
function LobbyLuckyBlockService.DespawnLuckyBlock(blockID: string)
	local blockData = activeLobbyBlocks[blockID]
	
	if not blockData then
		return
	end
	
	-- Find and destroy the model
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^LuckyBlock_") then
			local primaryPart = child.PrimaryPart
			if primaryPart and (primaryPart.Position - blockData.Position).Magnitude < 1 then
				child:Destroy()
				break
			end
		end
	end
	
	-- Remove isolation zone
	local isolationZone = activeIsolationZones[blockID]
	if isolationZone then
		isolationZone:Destroy()
		activeIsolationZones[blockID] = nil
	end
	
	-- Remove from tracking
	activeLobbyBlocks[blockID] = nil
	
	-- Notify owner
	if blockData.Owner then
		RemoteEvents.LuckyBlockDespawnedEvent:FireClient(blockData.Owner, blockID)
	end
	
	print("[LobbyLuckyBlockService] Despawned lobby lucky block:", blockID)
end

-- Clean up blocks for a player leaving
function LobbyLuckyBlockService.CleanupPlayerBlocks(player: Player)
	local toRemove = {}
	
	for blockID, blockData in pairs(activeLobbyBlocks) do
		if blockData.Owner == player then
			table.insert(toRemove, blockID)
		end
	end
	
	for _, blockID in ipairs(toRemove) do
		LobbyLuckyBlockService.DespawnLuckyBlock(blockID)
	end
end

-- Spawn a lucky block for player (debug/admin command)
function LobbyLuckyBlockService.SpawnLuckyBlockForPlayer(player: Player, rarityInput: string?): boolean
	-- Check if player already has an active block
	for blockID, blockData in pairs(activeLobbyBlocks) do
		if blockData.Owner == player then
			warn("[LobbyLuckyBlockService] Player already has an active lucky block:", player.Name)
			return false
		end
	end
	
	-- Parse rarity (default to random)
	local rarity: LuckyBlockTypes.LuckyBlockRarity = "Rare"
	if rarityInput then
		local lower = string.lower(rarityInput)
		if lower == "veryrare" or lower == "very_rare" then
			rarity = "VeryRare"
		elseif lower == "ultrarare" or lower == "ultra_rare" then
			rarity = "UltraRare"
		elseif lower == "rare" then
			rarity = "Rare"
		else
			-- Random rarity based on weights
			rarity = LuckyBlockService.GetRandomRarity()
		end
	else
		rarity = LuckyBlockService.GetRandomRarity()
	end
	
	-- Verify player has valid character
	local character = player.Character
	if not character or not character.PrimaryPart then
		warn("[LobbyLuckyBlockService] Player has no valid character")
		return false
	end
	
	-- Spawn position in front of player
	local spawnPosition = character.PrimaryPart.Position + character.PrimaryPart.CFrame.LookVector * 8
	spawnPosition = Vector3.new(spawnPosition.X, spawnPosition.Y + 2, spawnPosition.Z)
	
	-- Create the lucky block
	local blockModel = LuckyBlockService.CreateLuckyBlockModel(rarity, spawnPosition)
	blockModel.Parent = Workspace
	
	-- Generate ID and store data
	local blockID = generateBlockID(player)
	activeLobbyBlocks[blockID] = {
		ID = blockID,
		Rarity = rarity,
		Position = spawnPosition,
		Owner = player,
		SpawnTime = os.time(),
	}
	
	-- Setup proximity prompt for reveal
	local proximityPrompt = blockModel.PrimaryPart:FindFirstChild("PickupPrompt")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.ActionText = "Reveal Lucky Block"
		proximityPrompt.ObjectText = "Your " .. rarity .. " Lucky Block"
		
		proximityPrompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer == player then
				LobbyLuckyBlockService.OnRevealRequest(player, blockID)
			end
		end)
	end
	
	-- Notify client
	RemoteEvents.LuckyBlockSpawnedEvent:FireClient(player, blockID, rarity, spawnPosition)
	
	print("[LobbyLuckyBlockService] Debug spawned", rarity, "lucky block for", player.Name)
	
	return true
end

-- Initialize
function LobbyLuckyBlockService.Initialize()
	-- Listen for purchase requests (this should be called by ShopService)
	RemoteEvents.LuckyBlockPurchaseRequestEvent.OnServerEvent:Connect(function(player, shopItemID)
		-- This is handled by ShopService, but we provide a direct endpoint too
		local success = LobbyLuckyBlockService.OnPurchaseRequest(player, shopItemID)
		RemoteEvents.ShopPurchaseResultEvent:FireClient(player, shopItemID, success)
	end)
	
	-- Listen for reveal requests
	RemoteEvents.LuckyBlockRevealRequestEvent.OnServerEvent:Connect(function(player, blockID)
		LobbyLuckyBlockService.OnRevealRequest(player, blockID)
	end)
	
	-- Clean up on player leaving
	Players.PlayerRemoving:Connect(function(player)
		LobbyLuckyBlockService.CleanupPlayerBlocks(player)
	end)
	
	print("[LobbyLuckyBlockService] Initialized")
end

return LobbyLuckyBlockService
