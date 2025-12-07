--!strict
-- ShieldService.luau
-- Manages player shield state and visual effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "ShieldService"

local ShieldService = {}

-- Track active shields: [Player] = { expireTime: number, visual: Part }
local activeShields: { [Player]: { expireTime: number, visual: Part? } } = {}

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

-- Create the visual shield effect around a character
local function createShieldVisual(character: Model): Part?
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end
	
	-- Create shield sphere
	local shield = Instance.new("Part")
	shield.Name = "ShieldEffect"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(8, 8, 8)
	shield.Transparency = 0.6
	shield.Color = Color3.fromRGB(80, 150, 255)  -- Light blue
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
	highlight.FillColor = Color3.fromRGB(100, 180, 255)
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.fromRGB(150, 200, 255)
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
	
	-- Add particle effect
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "ShieldParticles"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 180, 255))
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
	
	Log.Info(CONTEXT, "Created shield visual")
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

-- Check if player has active shield
function ShieldService.HasShield(player: Player): boolean
	local shieldData = activeShields[player]
	if not shieldData then return false end
	
	if tick() > shieldData.expireTime then
		-- Shield expired, clean up
		ShieldService.RemoveShield(player)
		return false
	end
	
	return true
end

-- Get remaining shield time
function ShieldService.GetRemainingTime(player: Player): number
	local shieldData = activeShields[player]
	if not shieldData then return 0 end
	
	local remaining = shieldData.expireTime - tick()
	return math.max(0, remaining)
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
	
	-- Notify client
	RemoteEvents.ShieldStatusEvent:FireClient(player, false, 0)
	
	Log.Info(CONTEXT, string.format("%s shield deactivated", player.Name))
end

-- Activate shield for player
function ShieldService.ActivateShield(player: Player, duration: number): boolean
	-- Don't stack shields - if already active, ignore
	if ShieldService.HasShield(player) then
		Log.Info(CONTEXT, string.format("%s already has active shield", player.Name))
		return false
	end
	
	local character = player.Character
	if not character then return false end
	
	-- Create visual
	local visual = createShieldVisual(character)
	
	-- Store shield data
	activeShields[player] = {
		expireTime = tick() + duration,
		visual = visual,
	}
	
	-- Notify client
	RemoteEvents.ShieldStatusEvent:FireClient(player, true, duration)
	
	Log.Info(CONTEXT, string.format("%s activated shield for %d seconds", player.Name, duration))
	
	-- Schedule automatic removal
	task.delay(duration, function()
		if activeShields[player] and activeShields[player].expireTime <= tick() then
			ShieldService.RemoveShield(player)
		end
	end)
	
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
	
	-- Get shield duration from item definition
	local itemDef = ItemRegistry.GetItem("TOOL_SHIELD")
	local duration = itemDef and itemDef.ShieldDuration or 10
	
	-- Try to activate
	if ShieldService.ActivateShield(player, duration) then
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

Log.Info(CONTEXT, "ShieldService initialized")

return ShieldService
