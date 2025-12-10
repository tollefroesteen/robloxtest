--!strict
-- LuckyBlockController.luau
-- Client-side Lucky Block animation and visual effects controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local LuckyBlockConfig = require(Shared:WaitForChild("config"):WaitForChild("LuckyBlockConfig"))
local LuckyBlockRevealEffect = require(Shared:WaitForChild("effects"):WaitForChild("LuckyBlockRevealEffect"))

local LuckyBlockController = {}

local activeLuckyBlocks = {}

-- Animate the floating question mark
local function animateQuestionMark(questionMark: Part)
	if not questionMark then return end
	
	-- Bobbing animation
	local startPos = questionMark.Position
	local bobbingTween = TweenService:Create(questionMark, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = startPos + Vector3.new(0, 1, 0)
	})
	bobbingTween:Play()
	
	-- Rotation animation
	local rotationTween = TweenService:Create(questionMark, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
		Orientation = Vector3.new(0, 360, 0)
	})
	rotationTween:Play()
	
	return { bobbingTween, rotationTween }
end

-- Add particle effects based on rarity
local function addParticleEffects(block: Model, rarity: string)
	local primaryPart = block.PrimaryPart
	if not primaryPart then return end
	
	-- Create sparkle particles
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "RarityParticles"
	
	if rarity == "Rare" then
		particles.Color = ColorSequence.new(Color3.fromRGB(0, 100, 255))
	elseif rarity == "VeryRare" then
		particles.Color = ColorSequence.new(Color3.fromRGB(180, 0, 255))
	elseif rarity == "UltraRare" then
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	end
	
	particles.Size = NumberSequence.new(0.5, 0.1)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(2, 4)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = primaryPart
end

-- Play reveal animation using the cinematic reveal effect
local function playRevealAnimation(blockID: string, rarity: string, animalModel: Model?, positionOverride: Vector3?)
	local blockData = activeLuckyBlocks[blockID]
	local position: Vector3
	
	if blockData and blockData.Model and blockData.Model.PrimaryPart then
		local block = blockData.Model
		position = block.PrimaryPart.Position
		
		-- Hide the lucky block model
		for _, part in ipairs(block:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
			if part:IsA("BillboardGui") then
				part.Enabled = false
			end
			if part:IsA("ParticleEmitter") then
				part.Enabled = false
			end
			if part:IsA("PointLight") then
				part.Enabled = false
			end
		end
	elseif positionOverride then
		-- Use provided position if no block data (e.g., client joined mid-reveal)
		position = positionOverride
	elseif blockData and blockData.Position then
		-- Use stored position if model not found
		position = blockData.Position
	else
		warn("[LuckyBlockController] Cannot play reveal - no position available for", blockID)
		return
	end
	
	-- Play the cinematic reveal effect
	LuckyBlockRevealEffect.PlayReveal({
		Position = position,
		Rarity = rarity,
		AnimalModel = animalModel,
		OnComplete = function()
			print("[LuckyBlockController] Reveal animation complete for", blockID)
		end,
	})
end

-- Handle Lucky Block spawned
function LuckyBlockController.OnBlockSpawned(blockID: string, rarity: string, position: Vector3)
	-- Wait for the model to appear in workspace
	task.wait(0.5)
	
	-- Find the block model
	local block = nil
	for _, child in ipairs(Workspace:GetDescendants()) do
		if child:IsA("Model") and child.Name:match("^LuckyBlock_") then
			local primaryPart = child.PrimaryPart
			if primaryPart and (primaryPart.Position - position).Magnitude < 5 then
				block = child
				break
			end
		end
	end
	
	if not block then
		warn("[LuckyBlockController] Could not find block model for", blockID)
		return
	end
	
	-- Store block data
	activeLuckyBlocks[blockID] = {
		Model = block,
		Rarity = rarity,
		Position = position,
	}
	
	-- Add animations and effects
	local questionMark = block:FindFirstChild("QuestionMark")
	if questionMark then
		animateQuestionMark(questionMark)
	end
	
	addParticleEffects(block, rarity)
	
	print("[LuckyBlockController] Initialized animations for", blockID)
end

-- Handle Lucky Block despawned
function LuckyBlockController.OnBlockDespawned(blockID: string)
	local blockData = activeLuckyBlocks[blockID]
	if blockData then
		activeLuckyBlocks[blockID] = nil
		print("[LuckyBlockController] Removed tracking for", blockID)
	end
end

-- Store pending animal models for reveals
local pendingAnimalModels: {[string]: Model} = {}

-- Handle reveal start (server sends animal model along with rarity)
function LuckyBlockController.OnRevealStart(blockID: string, rarity: string, animalModel: Model?)
	print("[LuckyBlockController] Starting reveal for", blockID, rarity)
	
	-- Use any pending animal model if one was sent separately
	local modelToUse = animalModel or pendingAnimalModels[blockID]
	pendingAnimalModels[blockID] = nil
	
	playRevealAnimation(blockID, rarity, modelToUse)
end

-- Set a pending animal model (can be called before reveal starts)
function LuckyBlockController.SetPendingAnimalModel(blockID: string, animalModel: Model)
	pendingAnimalModels[blockID] = animalModel
end

-- Handle reveal complete
function LuckyBlockController.OnRevealComplete(blockID: string, animalID: string, animalName: string)
	print("[LuckyBlockController] Reveal complete:", animalName)
	
	-- Show a UI notification or celebration effect
	-- This could be expanded with custom UI
end

-- Handle arena pickup
function LuckyBlockController.OnArenaPickup(blockID: string, playerUserId: number, animalID: string)
	local player = game:GetService("Players"):GetPlayerByUserId(playerUserId)
	local playerName = player and player.Name or "Someone"
	
	print("[LuckyBlockController] Arena pickup:", playerName, "spawned", animalID)
	
	-- Could show a notification here
end

-- Initialize
function LuckyBlockController.Initialize()
	-- Listen for Lucky Block events
	RemoteEvents.LuckyBlockSpawnedEvent.OnClientEvent:Connect(function(blockID, rarity, position)
		LuckyBlockController.OnBlockSpawned(blockID, rarity, position)
	end)
	
	RemoteEvents.LuckyBlockDespawnedEvent.OnClientEvent:Connect(function(blockID)
		LuckyBlockController.OnBlockDespawned(blockID)
	end)
	
	-- Reveal start now receives optional animal model
	RemoteEvents.LuckyBlockRevealStartEvent.OnClientEvent:Connect(function(blockID, rarity, animalModel)
		LuckyBlockController.OnRevealStart(blockID, rarity, animalModel)
	end)
	
	RemoteEvents.LuckyBlockRevealCompleteEvent.OnClientEvent:Connect(function(blockID, animalID, animalName)
		LuckyBlockController.OnRevealComplete(blockID, animalID, animalName)
	end)
	
	RemoteEvents.LuckyBlockPickupEvent.OnClientEvent:Connect(function(blockID, playerUserId, animalID)
		LuckyBlockController.OnArenaPickup(blockID, playerUserId, animalID)
	end)
	
	print("[LuckyBlockController] Initialized")
end

return LuckyBlockController
