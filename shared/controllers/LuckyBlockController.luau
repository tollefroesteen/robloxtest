--!strict
-- LuckyBlockController.luau
-- Client-side Lucky Block animation and visual effects controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local LuckyBlockConfig = require(Shared:WaitForChild("config"):WaitForChild("LuckyBlockConfig"))

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

-- Play reveal animation
local function playRevealAnimation(blockID: string, rarity: string)
	local blockData = activeLuckyBlocks[blockID]
	if not blockData then return end
	
	local block = blockData.Model
	if not block or not block.PrimaryPart then return end
	
	local primaryPart = block.PrimaryPart
	
	-- Shake animation
	local originalCFrame = primaryPart.CFrame
	task.spawn(function()
		for i = 1, 10 do
			primaryPart.CFrame = originalCFrame * CFrame.Angles(
				math.rad(math.random(-5, 5)),
				math.rad(math.random(-5, 5)),
				math.rad(math.random(-5, 5))
			)
			task.wait(0.1)
		end
	end)
	
	-- Glow pulse
	local light = primaryPart:FindFirstChildOfClass("PointLight")
	if light then
		local originalBrightness = light.Brightness
		task.spawn(function()
			for i = 1, 5 do
				light.Brightness = originalBrightness * 2
				task.wait(0.2)
				light.Brightness = originalBrightness
				task.wait(0.2)
			end
		end)
	end
	
	-- Burst particles
	local particles = primaryPart:FindFirstChild("RarityParticles")
	if particles and particles:IsA("ParticleEmitter") then
		particles.Rate = 100
		task.wait(1)
		particles.Rate = 20
	end
	
	-- Scale up animation
	task.wait(1)
	local scaleTween = TweenService:Create(primaryPart, TweenInfo.new(1, Enum.EasingStyle.Elastic), {
		Size = primaryPart.Size * 1.2
	})
	scaleTween:Play()
	
	-- After reveal duration, scale back down
	task.wait(LuckyBlockConfig.RevealDuration - 2)
	
	local scaleDownTween = TweenService:Create(primaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
		Size = primaryPart.Size / 1.2
	})
	scaleDownTween:Play()
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

-- Handle reveal start
function LuckyBlockController.OnRevealStart(blockID: string, rarity: string)
	print("[LuckyBlockController] Starting reveal for", blockID, rarity)
	playRevealAnimation(blockID, rarity)
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
	
	RemoteEvents.LuckyBlockRevealStartEvent.OnClientEvent:Connect(function(blockID, rarity)
		LuckyBlockController.OnRevealStart(blockID, rarity)
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
