--!strict
-- MatchmakingZoneService.server.luau
-- Creates and manages multiple 1v1 and 2v2 matchmaking trigger zones
-- Detects when players enter/exit zones and communicates with MatchmakingService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local MatchmakingConfig = require(Shared:WaitForChild("config"):WaitForChild("MatchmakingConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local MatchmakingService = require(script.Parent:WaitForChild("matchmaking"):WaitForChild("MatchmakingService"))

local CONTEXT = "MatchmakingZoneService"

-- Zone colors
local ZONE_1V1_COLOR = Color3.fromRGB(255, 100, 100) -- Red-ish for 1v1
local ZONE_2V2_COLOR = Color3.fromRGB(100, 100, 255) -- Blue-ish for 2v2

-- Zone capacity
local MAX_PLAYERS_IN_2V2_ZONE = 2

-- Zone data structure
export type ZoneData = {
	model: Model,
	part: Part,
	zoneType: "1v1" | "2v2",
	position: Vector3,
	playersInside: { [number]: boolean }, -- Track players in THIS specific zone
}

-- All zones
local zones: { ZoneData } = {}

-- Track which zone each player is in (by zone index)
local playerZoneIndex: { [number]: number } = {}

--[[
	Create a single matchmaking zone cylinder
]]
local function createZone(
	name: string,
	position: Vector3,
	color: Color3,
	labelText: string,
	sublabelText: string
): Model
	local model = Instance.new("Model")
	model.Name = name
	
	-- Main cylinder (trigger zone)
	local cylinder = Instance.new("Part")
	cylinder.Name = "ZonePart"
	cylinder.Shape = Enum.PartType.Cylinder
	cylinder.Size = Vector3.new(
		MatchmakingConfig.ZONE_HEIGHT,
		MatchmakingConfig.ZONE_RADIUS * 2,
		MatchmakingConfig.ZONE_RADIUS * 2
	)
	cylinder.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	cylinder.Anchored = true
	cylinder.CanCollide = false
	cylinder.Transparency = 0.7
	cylinder.Material = Enum.Material.Neon
	cylinder.Color = color
	cylinder.Parent = model
	
	-- Base ring decoration
	local baseRing = Instance.new("Part")
	baseRing.Name = "BaseRing"
	baseRing.Shape = Enum.PartType.Cylinder
	baseRing.Size = Vector3.new(1, MatchmakingConfig.ZONE_RADIUS * 2 + 2, MatchmakingConfig.ZONE_RADIUS * 2 + 2)
	baseRing.CFrame = CFrame.new(position.X, position.Y - 0.5, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	baseRing.Anchored = true
	baseRing.CanCollide = false
	baseRing.Transparency = 0.4
	baseRing.Material = Enum.Material.Neon
	baseRing.Color = color
	baseRing.Parent = model
	
	-- Inner glow effect
	local innerGlow = Instance.new("Part")
	innerGlow.Name = "InnerGlow"
	innerGlow.Shape = Enum.PartType.Cylinder
	innerGlow.Size = Vector3.new(
		MatchmakingConfig.ZONE_HEIGHT - 2,
		MatchmakingConfig.ZONE_RADIUS * 1.2,
		MatchmakingConfig.ZONE_RADIUS * 1.2
	)
	innerGlow.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	innerGlow.Anchored = true
	innerGlow.CanCollide = false
	innerGlow.Transparency = 0.85
	innerGlow.Material = Enum.Material.Neon
	innerGlow.Color = color
	innerGlow.Parent = model
	
	-- Floating label
	local labelPart = Instance.new("Part")
	labelPart.Name = "LabelPart"
	labelPart.Size = Vector3.new(0.1, 0.1, 0.1)
	labelPart.Position = position + Vector3.new(0, MatchmakingConfig.ZONE_HEIGHT / 2 + 3, 0)
	labelPart.Anchored = true
	labelPart.CanCollide = false
	labelPart.Transparency = 1
	labelPart.Parent = model
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ZoneLabel"
	billboard.Size = UDim2.new(0, 250, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = labelPart
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = labelText
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextSize = 36
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = billboard
	
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	subtitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = sublabelText
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	subtitleLabel.TextStrokeTransparency = 0.7
	subtitleLabel.TextSize = 18
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Parent = billboard
	
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "Instruction"
	instructionLabel.Size = UDim2.new(1, 0, 0.2, 0)
	instructionLabel.Position = UDim2.new(0, 0, 0.8, 0)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Step inside to queue"
	instructionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	instructionLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	instructionLabel.TextStrokeTransparency = 0.7
	instructionLabel.TextSize = 14
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.Parent = billboard
	
	return model
end

--[[
	Count how many players are in a specific zone
]]
local function countPlayersInZone(zoneData: ZoneData): number
	local count = 0
	for _, isIn in zoneData.playersInside do
		if isIn then
			count += 1
		end
	end
	return count
end

--[[
	Teleport a player out of a zone (push them back)
]]
local function pushPlayerOutOfZone(player: Player, zonePosition: Vector3)
	local character = player.Character
	if not character then return end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end
	
	-- Calculate direction away from zone center
	local playerPos = rootPart.Position
	local direction = (playerPos - zonePosition).Unit
	
	-- If direction is zero (player at exact center), pick a random direction
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(1, 0, 0)
	end
	
	-- Teleport player just outside the zone
	local pushDistance = MatchmakingConfig.ZONE_RADIUS + 3
	local newPosition = Vector3.new(
		zonePosition.X + direction.X * pushDistance,
		playerPos.Y,
		zonePosition.Z + direction.Z * pushDistance
	)
	
	rootPart.CFrame = CFrame.new(newPosition)
	Log.Debug(CONTEXT, string.format("Pushed player %s out of full zone", player.Name))
end

--[[
	Check if a player's character is inside a zone
]]
local function isPlayerInZonePart(player: Player, zonePart: Part): boolean
	local character = player.Character
	if not character then return false end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return false end
	
	local zonePos = zonePart.Position
	local playerPos = rootPart.Position
	
	-- Check XZ distance (horizontal) and Y bounds (vertical)
	local xzDistance = math.sqrt((playerPos.X - zonePos.X)^2 + (playerPos.Z - zonePos.Z)^2)
	local yDiff = math.abs(playerPos.Y - zonePos.Y)
	
	return xzDistance <= MatchmakingConfig.ZONE_RADIUS and yDiff <= (MatchmakingConfig.ZONE_HEIGHT / 2 + 3)
end

--[[
	Calculate zone positions in a grid layout
	Returns array of positions for zones of a given type
]]
local function calculateZonePositions(basePosition: Vector3, numZones: number): { Vector3 }
	local positions: { Vector3 } = {}
	local spacing = MatchmakingConfig.ZONE_SPACING
	local rowOffset = MatchmakingConfig.ZONE_ROW_OFFSET
	
	-- Arrange in 2 rows of 3 (or adjust based on count)
	local zonesPerRow = math.ceil(numZones / 2)
	
	for i = 1, numZones do
		local row = math.ceil(i / zonesPerRow) - 1 -- 0 or 1
		local col = ((i - 1) % zonesPerRow) - (zonesPerRow - 1) / 2 -- Center the row
		
		local pos = Vector3.new(
			basePosition.X,
			basePosition.Y,
			basePosition.Z + col * spacing + row * rowOffset
		)
		table.insert(positions, pos)
	end
	
	return positions
end

--[[
	Main update loop to detect zone entry/exit
]]
local function updateZoneDetection()
	for _, player in Players:GetPlayers() do
		local userId = player.UserId
		local currentZoneIdx = playerZoneIndex[userId]
		
		-- Check all zones
		for zoneIdx, zoneData in zones do
			local isInThisZone = isPlayerInZonePart(player, zoneData.part)
			local wasInThisZone = zoneData.playersInside[userId] == true
			
			if isInThisZone and not wasInThisZone then
				-- Player trying to enter this zone
				
				-- First, exit any previous zone
				if currentZoneIdx and currentZoneIdx ~= zoneIdx then
					local prevZone = zones[currentZoneIdx]
					if prevZone then
						prevZone.playersInside[userId] = nil
						MatchmakingService.OnPlayerExitedZone(player)
					end
				end
				
				-- Check capacity for 2v2 zones
				if zoneData.zoneType == "2v2" then
					local currentCount = countPlayersInZone(zoneData)
					if currentCount >= MAX_PLAYERS_IN_2V2_ZONE then
						-- Zone is full, push player out
						pushPlayerOutOfZone(player, zoneData.position)
						RemoteEvents.MatchmakingZoneFullEvent:FireClient(player, "2v2")
						-- Don't mark as entered
						continue
					end
				end
				
				-- Enter this zone
				zoneData.playersInside[userId] = true
				playerZoneIndex[userId] = zoneIdx
				MatchmakingService.OnPlayerEnteredZone(player, zoneData.zoneType, zoneIdx)
				
			elseif not isInThisZone and wasInThisZone then
				-- Exited this zone
				zoneData.playersInside[userId] = nil
				if currentZoneIdx == zoneIdx then
					playerZoneIndex[userId] = nil
					MatchmakingService.OnPlayerExitedZone(player, zoneIdx)
				end
			end
		end
	end
end

--[[
	Clean up when player leaves
]]
local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	
	-- Remove from all zone tracking
	for _, zoneData in zones do
		zoneData.playersInside[userId] = nil
	end
	playerZoneIndex[userId] = nil
end

--[[
	Initialize the matchmaking zones
]]
local function init()
	Log.Info(CONTEXT, "Creating matchmaking zones...")
	
	-- Create folder for zones
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "MatchmakingZones"
	zonesFolder.Parent = workspace
	
	-- Create 1v1 zones folder
	local zones1v1Folder = Instance.new("Folder")
	zones1v1Folder.Name = "1v1Zones"
	zones1v1Folder.Parent = zonesFolder
	
	-- Create 2v2 zones folder
	local zones2v2Folder = Instance.new("Folder")
	zones2v2Folder.Name = "2v2Zones"
	zones2v2Folder.Parent = zonesFolder
	
	-- Calculate positions for 1v1 zones
	local positions1v1 = calculateZonePositions(
		MatchmakingConfig.ZONE_1V1_BASE_POSITION,
		MatchmakingConfig.NUM_1V1_ZONES
	)
	
	-- Create 1v1 zones
	for i, pos in positions1v1 do
		local zoneModel = createZone(
			string.format("Zone1v1_%d", i),
			pos,
			ZONE_1V1_COLOR,
			"⚔️ 1v1 DUEL",
			"Solo Battle"
		)
		zoneModel.Parent = zones1v1Folder
		
		local zoneData: ZoneData = {
			model = zoneModel,
			part = zoneModel:FindFirstChild("ZonePart") :: Part,
			zoneType = "1v1",
			position = pos,
			playersInside = {},
		}
		table.insert(zones, zoneData)
	end
	
	Log.Info(CONTEXT, string.format("Created %d 1v1 zones", MatchmakingConfig.NUM_1V1_ZONES))
	
	-- Calculate positions for 2v2 zones
	local positions2v2 = calculateZonePositions(
		MatchmakingConfig.ZONE_2V2_BASE_POSITION,
		MatchmakingConfig.NUM_2V2_ZONES
	)
	
	-- Create 2v2 zones
	for i, pos in positions2v2 do
		local zoneModel = createZone(
			string.format("Zone2v2_%d", i),
			pos,
			ZONE_2V2_COLOR,
			"👥 2v2 TEAM",
			"Team Battle"
		)
		zoneModel.Parent = zones2v2Folder
		
		local zoneData: ZoneData = {
			model = zoneModel,
			part = zoneModel:FindFirstChild("ZonePart") :: Part,
			zoneType = "2v2",
			position = pos,
			playersInside = {},
		}
		table.insert(zones, zoneData)
	end
	
	Log.Info(CONTEXT, string.format("Created %d 2v2 zones", MatchmakingConfig.NUM_2V2_ZONES))
	
	-- Start zone detection loop
	RunService.Heartbeat:Connect(function()
		updateZoneDetection()
	end)
	
	-- Handle player removal
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Start matchmaking service
	MatchmakingService.Start()
	
	Log.Info(CONTEXT, string.format(
		"Matchmaking zones initialized: %d total (%d 1v1, %d 2v2)",
		#zones,
		MatchmakingConfig.NUM_1V1_ZONES,
		MatchmakingConfig.NUM_2V2_ZONES
	))
end

-- Initialize on script run
init()
