--!strict
-- PortalService.server.luau
-- Creates the teleport portal and handles teleportation to arena

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local PlacesConfig = require(Shared:WaitForChild("PlacesConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local CONTEXT = "PortalService"

-- Portal configuration
local PORTAL_POSITION = Vector3.new(0, 0, 0) -- Center of lobby spawn area
local PORTAL_RADIUS = 8
local PORTAL_HEIGHT = 24

-- Create the portal in workspace
local function createPortal(): Model
	local portalModel = Instance.new("Model")
	portalModel.Name = "ArenaPortal"
	
	-- Main cylinder (the portal zone)
	local cylinder = Instance.new("Part")
	cylinder.Name = "PortalZone"
	cylinder.Shape = Enum.PartType.Cylinder
	cylinder.Size = Vector3.new(PORTAL_HEIGHT, PORTAL_RADIUS * 2, PORTAL_RADIUS * 2)
	cylinder.CFrame = CFrame.new(PORTAL_POSITION) * CFrame.Angles(0, 0, math.rad(90))
	cylinder.Anchored = true
	cylinder.CanCollide = false
	cylinder.Transparency = 0.7
	cylinder.Material = Enum.Material.Neon
	cylinder.Color = Color3.fromRGB(0, 200, 255)
	cylinder.Parent = portalModel
	
	-- Base ring (decorative)
	local baseRing = Instance.new("Part")
	baseRing.Name = "BaseRing"
	baseRing.Shape = Enum.PartType.Cylinder
	baseRing.Size = Vector3.new(1, PORTAL_RADIUS * 2 + 2, PORTAL_RADIUS * 2 + 2)
	baseRing.CFrame = CFrame.new(PORTAL_POSITION.X, PORTAL_POSITION.Y - 0.5, PORTAL_POSITION.Z) * CFrame.Angles(0, 0, math.rad(90))
	baseRing.Anchored = true
	baseRing.CanCollide = false
	baseRing.Transparency = 0.3
	baseRing.Material = Enum.Material.Neon
	baseRing.Color = Color3.fromRGB(0, 150, 200)
	baseRing.Parent = portalModel
	
	-- Inner glow effect
	local innerGlow = Instance.new("Part")
	innerGlow.Name = "InnerGlow"
	innerGlow.Shape = Enum.PartType.Cylinder
	innerGlow.Size = Vector3.new(PORTAL_HEIGHT - 2, PORTAL_RADIUS * 1.5, PORTAL_RADIUS * 1.5)
	innerGlow.CFrame = CFrame.new(PORTAL_POSITION) * CFrame.Angles(0, 0, math.rad(90))
	innerGlow.Anchored = true
	innerGlow.CanCollide = false
	innerGlow.Transparency = 0.85
	innerGlow.Material = Enum.Material.Neon
	innerGlow.Color = Color3.fromRGB(100, 255, 255)
	innerGlow.Parent = portalModel
	
	-- Floating label above portal
	local labelPart = Instance.new("Part")
	labelPart.Name = "LabelPart"
	labelPart.Size = Vector3.new(0.1, 0.1, 0.1)
	labelPart.Position = PORTAL_POSITION + Vector3.new(0, PORTAL_HEIGHT / 2 + 3, 0)
	labelPart.Anchored = true
	labelPart.CanCollide = false
	labelPart.Transparency = 1
	labelPart.Parent = portalModel
	
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "PortalLabel"
	billboardGui.Size = UDim2.new(0, 200, 0, 80)
	billboardGui.StudsOffset = Vector3.new(0, 0, 0)
	billboardGui.AlwaysOnTop = false
	billboardGui.Parent = labelPart
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⚔️ ARENA"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 100, 150)
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextSize = 32
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = billboardGui
	
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Step inside to teleport"
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 230, 255)
	subtitleLabel.TextSize = 16
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Parent = billboardGui
	
	-- Add particle effects
	local attachment = Instance.new("Attachment")
	attachment.Parent = cylinder
	
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "PortalParticles"
	particles.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 30
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment
	
	-- Point light
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(0, 200, 255)
	pointLight.Brightness = 2
	pointLight.Range = PORTAL_RADIUS * 2
	pointLight.Parent = cylinder
	
	portalModel.Parent = workspace
	
	Log.Info(CONTEXT, string.format("Portal created at %s", tostring(PORTAL_POSITION)))
	
	return portalModel
end

-- Teleport player to arena
local function teleportToArena(player: Player)
	if PlacesConfig.ARENA_PLACE_ID == 0 then
		Log.Warn(CONTEXT, "Arena place ID not configured in PlacesConfig!")
		return false
	end
	
	Log.Info(CONTEXT, string.format("Teleporting %s to arena", player.Name))
	
	local success, err = pcall(function()
		TeleportService:Teleport(PlacesConfig.ARENA_PLACE_ID, player)
	end)
	
	if not success then
		Log.Warn(CONTEXT, string.format("Failed to teleport %s: %s", player.Name, tostring(err)))
		return false
	end
	
	return true
end

-- Listen for teleport requests from clients (after countdown completes)
RemoteEvents.PortalTeleportRequestEvent.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("%s requested teleport via portal", player.Name))
	teleportToArena(player)
end)

-- Create the portal on startup
createPortal()

Log.Info(CONTEXT, "PortalService initialized")
