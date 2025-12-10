--!strict
-- GiftSpawner.server.luau
-- Spawns gift/freebie pickups from the UFO that players can collect

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameEvent = ServerEvents.StartGameEvent

local GiftConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArenaConfig"):WaitForChild("GiftConfig"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "GiftSpawner"

-- Lazy load InventoryService from shared
local InventoryService: any = nil
local function getInventoryService()
	if not InventoryService then
		local success, service = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("services"):WaitForChild("InventoryService"))
		end)
		if success then
			InventoryService = service
		end
	end
	return InventoryService
end

-- References
local UFOModel = workspace:FindFirstChild("UFO")
local ufo = UFOModel and UFOModel.PrimaryPart

-- Ensure Gifts folder exists
local GiftsFolder = workspace:FindFirstChild("Gifts")
if not GiftsFolder then
	GiftsFolder = Instance.new("Folder")
	GiftsFolder.Name = "Gifts"
	GiftsFolder.Parent = workspace
end

-- State
local gameActive = false
local nextSpawnTime = 0
local totalGiftsSpawned = 0

-- Calculate total weight for gift selection
local totalWeight = 0
for _, gift in GiftConfig.GiftTable do
	totalWeight += gift.Weight
end

-- Select random gift based on weights
local function selectRandomGift(): { ItemID: string, MinAmount: number, MaxAmount: number, Weight: number }
	local roll = math.random() * totalWeight
	local cumulative = 0
	
	for _, gift in GiftConfig.GiftTable do
		cumulative += gift.Weight
		if roll <= cumulative then
			return gift
		end
	end
	
	-- Fallback to first gift
	return GiftConfig.GiftTable[1]
end

-- Create visual gift box (returns Model with Part inside)
local function createGiftVisual(position: Vector3, giftData: { ItemID: string, Amount: number }): Model
	-- Use a Model container for proper BillboardGui support
	local giftModel = Instance.new("Model")
	giftModel.Name = "Gift_" .. giftData.ItemID
	
	local giftPart = Instance.new("Part")
	giftPart.Name = "GiftBox"
	giftPart.Shape = Enum.PartType.Block
	giftPart.Size = GiftConfig.GIFT_SIZE
	giftPart.Color = GiftConfig.GIFT_COLOR
	giftPart.Material = Enum.Material.Neon
	giftPart.Anchored = true
	giftPart.CanCollide = false
	giftPart.Position = position
	giftPart.Parent = giftModel
	
	giftModel.PrimaryPart = giftPart
	
	-- Store gift data on model
	giftModel:SetAttribute("ItemID", giftData.ItemID)
	giftModel:SetAttribute("Amount", giftData.Amount)
	giftModel:SetAttribute("SpawnTime", tick())
	
	-- Add attachment for particles
	local attachment = Instance.new("Attachment")
	attachment.Name = "ParticleAttachment"
	attachment.Parent = giftPart
	
	-- Add sparkle particles
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.LightEmission = 1
	particles.LightInfluence = 0
	particles.Lifetime = NumberRange.new(0.5, 1.5)
	particles.Rate = 30
	particles.Speed = NumberRange.new(3, 6)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Acceleration = Vector3.new(0, 2, 0)
	particles.Parent = attachment
	
	-- Add point light for glow
	local light = Instance.new("PointLight")
	light.Color = GiftConfig.GLOW_COLOR
	light.Brightness = 2
	light.Range = 8
	light.Parent = giftPart
	
	-- Add billboard label
	local itemDef = ItemRegistry.GetItem(giftData.ItemID)
	local itemName = itemDef and itemDef.Name or giftData.ItemID
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GiftLabel"
	billboard.Size = UDim2.new(0, 150, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = giftPart
	billboard.Parent = giftModel
	
	local frame = Instance.new("Frame")
	frame.Name = "Background"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "ItemLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = string.format("🎁 %dx %s", giftData.Amount, itemName)
	label.Parent = frame
	
	-- Floating animation
	task.spawn(function()
		local startY = position.Y
		local floatOffset = 0
		local rotation = 0
		while giftModel and giftModel.Parent and giftPart and giftPart.Parent do
			floatOffset += 0.05
			rotation += 1
			local newY = startY + math.sin(floatOffset) * 0.5
			giftPart.CFrame = CFrame.new(position.X, newY, position.Z) * CFrame.Angles(0, math.rad(rotation), 0)
			task.wait(0.03)
		end
	end)
	
	return giftModel
end

-- Handle player touching gift
local function onGiftTouched(giftModel: Model, hit: BasePart)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	
	-- Check if already collected (prevent double pickup)
	if giftModel:GetAttribute("Collected") then return end
	giftModel:SetAttribute("Collected", true)
	
	local itemID = giftModel:GetAttribute("ItemID")
	local amount = giftModel:GetAttribute("Amount")
	
	if not itemID or not amount then
		giftModel:Destroy()
		return
	end
	
	-- Grant item to player
	local invService = getInventoryService()
	if invService then
		local success, msg = invService.AddItem(player, itemID, amount)
		if success then
			local itemDef = ItemRegistry.GetItem(itemID)
			local itemName = itemDef and itemDef.Name or itemID
			Log.Info(CONTEXT, string.format("%s collected gift: %dx %s", player.Name, amount, itemName))
		else
			Log.Warn(CONTEXT, string.format("Failed to grant gift to %s: %s", player.Name, msg))
		end
	end
	
	-- Collect animation on the part
	local giftPart = giftModel:FindFirstChild("GiftBox")
	if giftPart then
		local tween = TweenService:Create(
			giftPart,
			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Size = Vector3.new(0, 0, 0), Transparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			giftModel:Destroy()
		end)
	else
		giftModel:Destroy()
	end
end

-- Spawn a gift from the UFO
local function spawnGift()
	if not gameActive then return end
	if not ufo then return end
	
	-- Check gift limit
	local currentGifts = #GiftsFolder:GetChildren()
	if currentGifts >= GiftConfig.MAX_GIFTS then
		Log.Debug(CONTEXT, string.format("Gift spawn skipped: at capacity (%d/%d)", currentGifts, GiftConfig.MAX_GIFTS))
		return
	end
	
	-- Select gift contents
	local giftTemplate = selectRandomGift()
	local amount = math.random(giftTemplate.MinAmount, giftTemplate.MaxAmount)
	
	local giftData = {
		ItemID = giftTemplate.ItemID,
		Amount = amount,
	}
	
	-- Spawn position (below UFO, at ground level)
	local ufoPos = ufo.Position
	
	-- Raycast to find TERRAIN only, ignoring all other objects
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { workspace.Terrain }
	
	local rayResult = workspace:Raycast(
		Vector3.new(ufoPos.X, ufoPos.Y + 50, ufoPos.Z),  -- Start from above UFO
		Vector3.new(0, -300, 0),
		rayParams
	)
	
	local spawnPos
	if rayResult then
		-- Check if there's anything blocking this spot (objects on terrain)
		local checkParams = RaycastParams.new()
		checkParams.FilterType = Enum.RaycastFilterType.Exclude
		checkParams.FilterDescendantsInstances = { workspace.Terrain, UFOModel, GiftsFolder }
		
		local obstacleCheck = workspace:Raycast(
			rayResult.Position + Vector3.new(0, 10, 0),
			Vector3.new(0, -12, 0),
			checkParams
		)
		
		if obstacleCheck then
			-- There's an object here, offset and re-raycast terrain at new position
			local offsetAngle = math.random() * math.pi * 2
			local offsetDist = 5 + math.random() * 5
			local newX = ufoPos.X + math.cos(offsetAngle) * offsetDist
			local newZ = ufoPos.Z + math.sin(offsetAngle) * offsetDist
			
			-- Re-raycast terrain at the offset position to get correct height
			local retryResult = workspace:Raycast(
				Vector3.new(newX, ufoPos.Y + 50, newZ),
				Vector3.new(0, -300, 0),
				rayParams
			)
			
			if retryResult then
				spawnPos = retryResult.Position + Vector3.new(0, 2, 0)
			else
				-- Fallback to original terrain hit + offset
				spawnPos = Vector3.new(newX, rayResult.Position.Y + 2, newZ)
			end
		else
			-- Clear spot, spawn 2 studs above terrain
			spawnPos = rayResult.Position + Vector3.new(0, 2, 0)
		end
	else
		-- Fallback: use terrain base level
		spawnPos = Vector3.new(ufoPos.X, 2, ufoPos.Z)
		Log.Warn(CONTEXT, "Raycast failed to find terrain, using fallback position")
	end
	
	-- Create the gift model
	local giftModel = createGiftVisual(spawnPos, giftData)
	giftModel.Parent = GiftsFolder
	
	-- Connect touch detection to the part inside
	local giftPart = giftModel:FindFirstChild("GiftBox")
	if giftPart then
		giftPart.Touched:Connect(function(hit)
			onGiftTouched(giftModel, hit)
		end)
	end
	
	totalGiftsSpawned += 1
	
	local itemDef = ItemRegistry.GetItem(giftData.ItemID)
	local itemName = itemDef and itemDef.Name or giftData.ItemID
	Log.Info(CONTEXT, string.format("Gift #%d spawned: %dx %s at (%.0f, %.0f, %.0f)", 
		totalGiftsSpawned, amount, itemName, spawnPos.X, spawnPos.Y, spawnPos.Z))
	
	-- Auto-despawn after lifetime
	task.delay(GiftConfig.GIFT_LIFETIME, function()
		if giftModel and giftModel.Parent and not giftModel:GetAttribute("Collected") then
			-- Fade out
			local part = giftModel:FindFirstChild("GiftBox")
			if part then
				local tween = TweenService:Create(
					part,
					TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				)
				tween:Play()
				tween.Completed:Connect(function()
					giftModel:Destroy()
				end)
			else
				giftModel:Destroy()
			end
			Log.Debug(CONTEXT, "Gift despawned (uncollected)")
		end
	end)
end

-- Calculate next spawn time
local function scheduleNextSpawn()
	local interval = math.random() * (GiftConfig.MAX_INTERVAL - GiftConfig.MIN_INTERVAL) + GiftConfig.MIN_INTERVAL
	nextSpawnTime = tick() + interval
	Log.Debug(CONTEXT, string.format("Next gift spawn in %.1f seconds", interval))
end

-- Main loop
RunService.Heartbeat:Connect(function()
	if not gameActive then return end
	
	if tick() >= nextSpawnTime then
		spawnGift()
		scheduleNextSpawn()
	end
end)

-- Game state handlers
StartGameEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game started - gift spawner active")
	gameActive = true
	totalGiftsSpawned = 0
	scheduleNextSpawn()
end)

TimerEndedEvent.Event:Connect(function()
	Log.Info(CONTEXT, string.format("Game ended - total gifts spawned: %d", totalGiftsSpawned))
	gameActive = false
	
	-- Clean up remaining gifts
	for _, gift in GiftsFolder:GetChildren() do
		gift:Destroy()
	end
end)

Log.Info(CONTEXT, "GiftSpawner initialized")
