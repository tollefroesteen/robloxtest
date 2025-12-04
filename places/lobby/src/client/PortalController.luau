--!strict
-- PortalController.luau
-- Client-side controller for the lobby portal system
-- Detects when player enters portal, shows countdown UI, triggers teleport

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local LocalPlayer = Players.LocalPlayer

local PortalController = {}

-- Configuration
local COUNTDOWN_SECONDS = 5
local PORTAL_RADIUS = 8 -- Must match server's PORTAL_RADIUS
local PORTAL_HEIGHT = 24 -- Must match server's PORTAL_HEIGHT

-- State
local countdownActive = false
local countdownCoroutine: thread? = nil
local countdownUI: ScreenGui? = nil
local isInsidePortal = false
local portalZone: BasePart? = nil

-- UI Elements
local function createCountdownUI(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PortalCountdownUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "CountdownFrame"
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.Position = UDim2.new(0.5, -150, 0.3, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame
	
	-- Add stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 200, 255)
	stroke.Thickness = 3
	stroke.Parent = frame
	
	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 0, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Teleporting to Arena"
	titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame
	
	-- Countdown number
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(1, 0, 0, 60)
	countdownLabel.Position = UDim2.new(0, 0, 0, 50)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = tostring(COUNTDOWN_SECONDS)
	countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLabel.TextSize = 56
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.Parent = frame
	
	-- Instruction label
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "InstructionLabel"
	instructionLabel.Size = UDim2.new(1, 0, 0, 20)
	instructionLabel.Position = UDim2.new(0, 0, 0, 115)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Step out to cancel"
	instructionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	instructionLabel.TextSize = 14
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.Parent = frame
	
	-- Initially hidden
	frame.Visible = false
	
	return screenGui
end

local function showCountdownUI()
	if countdownUI then
		local frame = countdownUI:FindFirstChild("CountdownFrame") :: Frame?
		if frame then
			frame.Visible = true
			-- Animate in
			frame.Position = UDim2.new(0.5, -150, 0.2, 0)
			frame.BackgroundTransparency = 1
			local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, -150, 0.3, 0),
				BackgroundTransparency = 0.2
			})
			tween:Play()
		end
	end
end

local function hideCountdownUI()
	if countdownUI then
		local frame = countdownUI:FindFirstChild("CountdownFrame") :: Frame?
		if frame then
			-- Animate out
			local tween = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -150, 0.2, 0),
				BackgroundTransparency = 1
			})
			tween:Play()
			tween.Completed:Connect(function()
				frame.Visible = false
			end)
		end
	end
end

local function updateCountdownNumber(num: number)
	if countdownUI then
		local frame = countdownUI:FindFirstChild("CountdownFrame") :: Frame?
		if frame then
			local label = frame:FindFirstChild("CountdownLabel") :: TextLabel?
			if label then
				label.Text = tostring(num)
				-- Pulse animation
				label.TextSize = 70
				local tween = TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
					TextSize = 56
				})
				tween:Play()
			end
		end
	end
end

local function isPlayerInPortal(): boolean
	local character = LocalPlayer.Character
	if not character then return false end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return false end
	
	-- Find the portal zone part (inside ArenaPortal model)
	if not portalZone then
		local portalModel = workspace:FindFirstChild("ArenaPortal")
		if portalModel then
			portalZone = portalModel:FindFirstChild("PortalZone") :: BasePart?
		end
		if not portalZone then
			return false
		end
	end
	
	-- Get portal position (the cylinder is rotated 90 degrees on Z axis)
	local portalPos = portalZone.Position
	local playerPos = rootPart.Position
	
	-- Check XZ distance and Y bounds
	local xzDistance = math.sqrt((playerPos.X - portalPos.X)^2 + (playerPos.Z - portalPos.Z)^2)
	local yDiff = math.abs(playerPos.Y - portalPos.Y)
	
	-- Within cylinder radius and within height bounds
	return xzDistance <= PORTAL_RADIUS and yDiff <= (PORTAL_HEIGHT / 2 + 3)
end

local function startCountdown()
	if countdownActive then return end
	countdownActive = true
	
	showCountdownUI()
	updateCountdownNumber(COUNTDOWN_SECONDS)
	
	countdownCoroutine = coroutine.create(function()
		local timeRemaining = COUNTDOWN_SECONDS
		
		while timeRemaining > 0 do
			task.wait(1)
			
			-- Check if still in portal
			if not isInsidePortal or not countdownActive then
				return
			end
			
			timeRemaining -= 1
			if timeRemaining > 0 then
				updateCountdownNumber(timeRemaining)
			end
		end
		
		-- Countdown complete - request teleport
		if isInsidePortal and countdownActive then
			updateCountdownNumber(0)
			
			-- Update UI to show teleporting
			if countdownUI then
				local frame = countdownUI:FindFirstChild("CountdownFrame") :: Frame?
				if frame then
					local titleLabel = frame:FindFirstChild("TitleLabel") :: TextLabel?
					local instructionLabel = frame:FindFirstChild("InstructionLabel") :: TextLabel?
					if titleLabel then
						titleLabel.Text = "Teleporting..."
					end
					if instructionLabel then
						instructionLabel.Text = ""
					end
				end
			end
			
			-- Fire teleport request to server
			RemoteEvents.PortalTeleportRequestEvent:FireServer()
		end
	end)
	
	coroutine.resume(countdownCoroutine :: thread)
end

local function cancelCountdown()
	if not countdownActive then return end
	countdownActive = false
	
	if countdownCoroutine then
		coroutine.close(countdownCoroutine :: thread)
		countdownCoroutine = nil
	end
	
	hideCountdownUI()
end

local function onPortalEnter()
	if isInsidePortal then return end
	isInsidePortal = true
	startCountdown()
end

local function onPortalExit()
	if not isInsidePortal then return end
	isInsidePortal = false
	cancelCountdown()
end

-- Continuous check for portal proximity (more reliable than Touched events)
local function startPortalCheck()
	RunService.Heartbeat:Connect(function()
		local wasInside = isInsidePortal
		local nowInside = isPlayerInPortal()
		
		if nowInside and not wasInside then
			onPortalEnter()
		elseif not nowInside and wasInside then
			onPortalExit()
		end
	end)
end

function PortalController.Init()
	-- Wait for PlayerGui
	local playerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	
	-- Create and parent the countdown UI
	countdownUI = createCountdownUI()
	countdownUI.Parent = playerGui
	
	-- Wait for the portal to be created by the server
	print("PortalController: Waiting for ArenaPortal...")
	local portalModel = workspace:WaitForChild("ArenaPortal", 10)
	if portalModel then
		portalZone = portalModel:WaitForChild("PortalZone", 5) :: BasePart?
		if portalZone then
			print("PortalController: Found portal at", portalZone.Position)
		else
			warn("PortalController: PortalZone not found inside ArenaPortal")
		end
	else
		warn("PortalController: ArenaPortal not found in workspace")
	end
	
	-- Start checking for portal proximity
	startPortalCheck()
	
	print("PortalController initialized")
end

return PortalController
