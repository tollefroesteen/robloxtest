--!strict
-- ShieldService.luau
-- Manages player shield state and visual effects
-- Shields now use health-based system (damage absorbs shield HP until broken)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "ShieldService"

-- Shield configuration
local BASE_SHIELD_HEALTH = 50        -- Default shield health
local REINFORCED_BONUS = 50          -- Extra HP from reinforced shield upgrade (total 100)

local ShieldService = {}

-- Track active shields: [Player] = { currentHealth: number, maxHealth: number, visual: Part?, expireTime: number? }
local activeShields: { [Player]: { currentHealth: number, maxHealth: number, visual: Part?, expireTime: number? } } = {}

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

-- Lazy load PlayerUpgradesService to check for reinforced shield upgrade
local PlayerUpgradesService: any = nil
local function getPlayerUpgradesService()
	if not PlayerUpgradesService then
		local success, service = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("services"):WaitForChild("PlayerUpgradesService"))
		end)
		if success then
			PlayerUpgradesService = service
		end
	end
	return PlayerUpgradesService
end

-- Create the visual shield effect around a character
local function createShieldVisual(character: Model, isReinforced: boolean): Part?
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end
	
	-- Create shield sphere
	local shield = Instance.new("Part")
	shield.Name = "ShieldEffect"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(8, 8, 8)
	shield.Transparency = 0.6
	
	-- Different colors for normal vs reinforced shields
	if isReinforced then
		shield.Color = Color3.fromRGB(255, 200, 80)  -- Golden for reinforced
	else
		shield.Color = Color3.fromRGB(80, 150, 255)  -- Light blue for normal
	end
	
	shield.Material = Enum.Material.ForceField
	shield.CanCollide = false
	shield.Anchored = false
	shield.Massless = true
	shield.CastShadow = false
	
	-- Weld to character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = shield
	weld.Parent = shield
	
	shield.CFrame = rootPart.CFrame
	shield.Parent = character
	
	-- Add highlight effect
	local highlight = Instance.new("Highlight")
	highlight.Name = "ShieldHighlight"
	
	if isReinforced then
		highlight.FillColor = Color3.fromRGB(255, 220, 100)
		highlight.OutlineColor = Color3.fromRGB(255, 180, 50)
	else
		highlight.FillColor = Color3.fromRGB(100, 180, 255)
		highlight.OutlineColor = Color3.fromRGB(150, 200, 255)
	end
	
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
	
	-- Add particle effect
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "ShieldParticles"
	
	if isReinforced then
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80))
	else
		particles.Color = ColorSequence.new(Color3.fromRGB(100, 180, 255))
	end
	
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 20
	particles.Speed = NumberRange.new(2, 4)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = shield
	
	Log.Info(CONTEXT, string.format("Created %s shield visual", isReinforced and "reinforced" or "normal"))
	return shield
end

-- Remove shield visual with fade effect
local function removeShieldVisual(character: Model)
	local shield = character:FindFirstChild("ShieldEffect")
	local highlight = character:FindFirstChild("ShieldHighlight")
	
	if shield then
		-- Fade out animation
		local tween = TweenService:Create(
			shield,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = Vector3.new(12, 12, 12) }
		)
		tween:Play()
		tween.Completed:Connect(function()
			shield:Destroy()
		end)
	end
	
	if highlight then
		highlight:Destroy()
	end
end

-- Update shield visual based on current health (flash when damaged)
local function flashShieldVisual(character: Model)
	local shield = character:FindFirstChild("ShieldEffect")
	if not shield then return end
	
	-- Quick flash to white and back
	local originalColor = shield.Color
	shield.Color = Color3.fromRGB(255, 255, 255)
	
	task.delay(0.1, function()
		if shield and shield.Parent then
			shield.Color = originalColor
		end
	end)
end

-- Update shield visual to reflect damage state (degradation effect)
local function updateShieldDegradation(character: Model, healthPercent: number)
	local shield = character:FindFirstChild("ShieldEffect")
	local highlight = character:FindFirstChild("ShieldHighlight")
	
	if not shield then return end
	
	-- Calculate visual properties based on health percentage
	-- Full health: Size 8, Transparency 0.6
	-- Low health: Size 6-7, Transparency 0.75, more flickering
	local minSize = 6
	local maxSize = 8
	local minTransparency = 0.6
	local maxTransparency = 0.8
	
	local targetSize = minSize + (maxSize - minSize) * healthPercent
	local targetTransparency = maxTransparency - (maxTransparency - minTransparency) * healthPercent
	
	-- Smooth transition
	local tween = TweenService:Create(
		shield,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ 
			Size = Vector3.new(targetSize, targetSize, targetSize),
			Transparency = targetTransparency
		}
	)
	tween:Play()
	
	-- Update highlight transparency based on damage
	if highlight then
		highlight.FillTransparency = 0.7 + (0.2 * (1 - healthPercent))  -- 0.7 at full, 0.9 at empty
		highlight.OutlineTransparency = 0.2 + (0.5 * (1 - healthPercent))  -- 0.2 at full, 0.7 at low
	end
	
	-- Add flickering effect when shield is low (below 30%)
	if healthPercent < 0.3 and shield.Parent then
		task.spawn(function()
			for i = 1, 3 do
				if not shield or not shield.Parent then break end
				shield.Transparency = targetTransparency + 0.15
				task.wait(0.05)
				if not shield or not shield.Parent then break end
				shield.Transparency = targetTransparency
				task.wait(0.1)
			end
		end)
	end
end

-- Check if player has active shield
function ShieldService.HasShield(player: Player): boolean
	local shieldData = activeShields[player]
	if not shieldData then return false end
	
	-- Check if shield has expired (time-based)
	if shieldData.expireTime and tick() > shieldData.expireTime then
		ShieldService.RemoveShield(player)
		return false
	end
	
	if shieldData.currentHealth <= 0 then
		-- Shield depleted, clean up
		ShieldService.RemoveShield(player)
		return false
	end
	
	return true
end

-- Get current shield health
function ShieldService.GetShieldHealth(player: Player): number
	local shieldData = activeShields[player]
	if not shieldData then return 0 end
	return math.max(0, shieldData.currentHealth)
end

-- Get max shield health
function ShieldService.GetMaxShieldHealth(player: Player): number
	local shieldData = activeShields[player]
	if not shieldData then return 0 end
	return shieldData.maxHealth
end

-- Apply damage to shield, returns remaining damage that passes through
function ShieldService.DamageShield(player: Player, damage: number): number
	local shieldData = activeShields[player]
	if not shieldData or shieldData.currentHealth <= 0 then
		return damage  -- No shield, full damage passes through
	end
	
	-- Check if shield has expired
	if shieldData.expireTime and tick() > shieldData.expireTime then
		ShieldService.RemoveShield(player)
		return damage
	end
	
	local absorbedDamage = math.min(damage, shieldData.currentHealth)
	local remainingDamage = damage - absorbedDamage
	
	shieldData.currentHealth = shieldData.currentHealth - absorbedDamage
	
	Log.Info(CONTEXT, string.format("%s shield took %d damage, %d HP remaining", 
		player.Name, absorbedDamage, shieldData.currentHealth))
	
	-- Visual feedback
	local character = player.Character
	if character then
		flashShieldVisual(character)
		
		-- Update shield visual to show degradation
		local healthPercent = shieldData.currentHealth / shieldData.maxHealth
		updateShieldDegradation(character, healthPercent)
	end
	
	-- Update client with new shield status
	RemoteEvents.ShieldStatusEvent:FireClient(player, true, shieldData.currentHealth, shieldData.maxHealth)
	
	-- Check if shield is broken
	if shieldData.currentHealth <= 0 then
		ShieldService.RemoveShield(player)
	end
	
	return remainingDamage
end

-- Remove shield from player
function ShieldService.RemoveShield(player: Player)
	local shieldData = activeShields[player]
	if not shieldData then return end
	
	-- Remove visual
	local character = player.Character
	if character then
		removeShieldVisual(character)
	end
	
	activeShields[player] = nil
	
	-- Notify client (0 health = shield gone)
	RemoteEvents.ShieldStatusEvent:FireClient(player, false, 0, 0)
	
	Log.Info(CONTEXT, string.format("%s shield deactivated", player.Name))
end

-- Calculate shield health for a player (considers upgrades)
local function calculateShieldHealth(player: Player): number
	local baseHealth = BASE_SHIELD_HEALTH
	
	-- Check for reinforced shield upgrade
	local upgradesService = getPlayerUpgradesService()
	if upgradesService and upgradesService.HasUpgrade(player, "ReinforcedShield") then
		baseHealth = baseHealth + REINFORCED_BONUS
		Log.Info(CONTEXT, string.format("%s has reinforced shield upgrade, total HP: %d", player.Name, baseHealth))
	end
	
	return baseHealth
end

-- Activate shield for player (health-based, with optional time limit)
-- overrideHealth: custom shield HP (nil = calculate based on upgrades)
-- duration: optional time limit in seconds (nil = no time limit, shield lasts until broken)
function ShieldService.ActivateShield(player: Player, overrideHealth: number?, duration: number?): boolean
	-- Don't stack shields - if already active, ignore
	if ShieldService.HasShield(player) then
		Log.Info(CONTEXT, string.format("%s already has active shield", player.Name))
		return false
	end
	
	local character = player.Character
	if not character then return false end
	
	-- Calculate shield health
	local shieldHealth = overrideHealth or calculateShieldHealth(player)
	
	-- Check if player has reinforced upgrade for visual
	local upgradesService = getPlayerUpgradesService()
	local isReinforced = upgradesService and upgradesService.HasUpgrade(player, "ReinforcedShield") or false
	
	-- Create visual
	local visual = createShieldVisual(character, isReinforced)
	
	-- Calculate expire time if duration is provided
	local expireTime: number? = nil
	if duration then
		expireTime = tick() + duration
	end
	
	-- Store shield data
	activeShields[player] = {
		currentHealth = shieldHealth,
		maxHealth = shieldHealth,
		visual = visual,
		expireTime = expireTime,
	}
	
	-- Notify client
	RemoteEvents.ShieldStatusEvent:FireClient(player, true, shieldHealth, shieldHealth)
	
	if duration then
		Log.Info(CONTEXT, string.format("%s activated shield with %d HP (expires in %d seconds)", player.Name, shieldHealth, duration))
		
		-- Schedule automatic removal when time expires
		task.delay(duration, function()
			if activeShields[player] and activeShields[player].expireTime and tick() >= activeShields[player].expireTime then
				ShieldService.RemoveShield(player)
			end
		end)
	else
		Log.Info(CONTEXT, string.format("%s activated shield with %d HP (no time limit)", player.Name, shieldHealth))
	end
	
	return true
end

-- Handle shield activation request from client
local function onShieldActivate(player: Player)
	-- Check if player has shield item
	local invService = getInventoryService()
	if not invService then
		Log.Warn(CONTEXT, "InventoryService not available")
		return
	end
	
	if not invService.HasItem(player, "TOOL_SHIELD", 1) then
		Log.Info(CONTEXT, string.format("%s tried to activate shield but has none", player.Name))
		return
	end
	
	-- Try to activate (health is calculated internally based on upgrades)
	if ShieldService.ActivateShield(player) then
		-- Consume the shield item
		invService.RemoveItem(player, "TOOL_SHIELD", 1)
	end
end

-- Initialize
RemoteEvents.ShieldActivateEvent.OnServerEvent:Connect(onShieldActivate)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	activeShields[player] = nil
end)

-- Clean up shield when character dies/respawns
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Remove any lingering shield data on respawn
		activeShields[player] = nil
	end)
end)

Log.Info(CONTEXT, "ShieldService initialized (damage-based shields)")

return ShieldService
