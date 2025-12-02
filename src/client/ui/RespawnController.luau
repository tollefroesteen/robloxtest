--!strict
-- RespawnController.luau
-- Displays a full-screen death overlay with respawn countdown

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

local RespawnController = {}

local player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local screenGui: ScreenGui? = nil
local countdownLabel: TextLabel? = nil

-- Create the death overlay UI
local function createDeathOverlay(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "DeathOverlay"
	gui.ResetOnSpawn = true
	gui.DisplayOrder = 100 -- Above most UI
	gui.IgnoreGuiInset = true
	
	-- Subtle dark overlay at edges (vignette only, no full screen darken)
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxassetid://1526406462" -- Vignette asset
	vignette.ImageColor3 = Color3.fromRGB(80, 0, 0)
	vignette.ImageTransparency = 0.5
	vignette.Parent = gui
	
	-- Top banner container
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.Size = UDim2.new(1, 0, 0, 80)
	banner.Position = UDim2.new(0, 0, 0, 0)
	banner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	banner.BackgroundTransparency = 0.5
	banner.BorderSizePixel = 0
	banner.Parent = gui
	
	-- Gradient on banner (darker at top)
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 90
	gradient.Parent = banner
	
	-- "YOU DIED" text (smaller, top left area)
	local diedLabel = Instance.new("TextLabel")
	diedLabel.Name = "DiedLabel"
	diedLabel.Size = UDim2.new(0, 200, 0, 40)
	diedLabel.Position = UDim2.new(0, 20, 0, 10)
	diedLabel.BackgroundTransparency = 1
	diedLabel.Font = Enum.Font.GothamBold
	diedLabel.TextColor3 = Color3.fromRGB(220, 60, 60)
	diedLabel.TextSize = 28
	diedLabel.TextXAlignment = Enum.TextXAlignment.Left
	diedLabel.Text = "YOU DIED"
	diedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	diedLabel.TextStrokeTransparency = 0.5
	diedLabel.Parent = banner
	
	-- Countdown container (center of banner)
	local countdownContainer = Instance.new("Frame")
	countdownContainer.Name = "CountdownContainer"
	countdownContainer.Size = UDim2.new(0, 200, 0, 60)
	countdownContainer.Position = UDim2.new(0.5, 0, 0, 10)
	countdownContainer.AnchorPoint = Vector2.new(0.5, 0)
	countdownContainer.BackgroundTransparency = 1
	countdownContainer.Parent = banner
	
	-- Countdown number
	local countdown = Instance.new("TextLabel")
	countdown.Name = "CountdownLabel"
	countdown.Size = UDim2.new(0, 60, 1, 0)
	countdown.Position = UDim2.new(0.5, 0, 0, 0)
	countdown.AnchorPoint = Vector2.new(0.5, 0)
	countdown.BackgroundTransparency = 1
	countdown.Font = Enum.Font.GothamBold
	countdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdown.TextSize = 48
	countdown.Text = "5"
	countdown.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	countdown.TextStrokeTransparency = 0.5
	countdown.Parent = countdownContainer
	countdownLabel = countdown
	
	-- "Respawning in..." text (below countdown)
	local respawnLabel = Instance.new("TextLabel")
	respawnLabel.Name = "RespawnLabel"
	respawnLabel.Size = UDim2.new(1, 0, 0, 20)
	respawnLabel.Position = UDim2.new(0, 0, 1, -5)
	respawnLabel.BackgroundTransparency = 1
	respawnLabel.Font = Enum.Font.Gotham
	respawnLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	respawnLabel.TextSize = 14
	respawnLabel.Text = "Respawning in..."
	respawnLabel.Parent = countdownContainer
	
	return gui
end

-- Animate countdown number change
local function animateCountdown(seconds: number)
	if not countdownLabel then return end
	
	countdownLabel.Text = tostring(seconds)
	
	-- Pulse animation
	countdownLabel.TextSize = 60
	local tween = TweenService:Create(
		countdownLabel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextSize = 48 }
	)
	tween:Play()
	
	-- Flash red on low numbers
	if seconds <= 2 then
		countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		task.delay(0.2, function()
			if countdownLabel then
				countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
	end
end

-- Disable player controls during death
local function disableControls()
	-- Disable the reset button so player can't respawn early
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) -- Keep UI visible
	end)
	
	-- Disable character movement by setting WalkSpeed/JumpPower to 0
	-- (Character is dead so this is mostly for safety)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
end

-- Re-enable player controls
local function enableControls()
	-- Controls will be restored when character respawns
	-- No action needed here since new character has fresh humanoid
end

-- Show the death overlay
local function showDeathOverlay()
	if screenGui then return end -- Already showing
	
	screenGui = createDeathOverlay()
	screenGui.Parent = playerGui
	disableControls()
end

-- Hide the death overlay
local function hideDeathOverlay()
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
		countdownLabel = nil
	end
	enableControls()
end

-- Handle countdown updates from server
local function onRespawnCountdown(seconds: number, isActive: boolean)
	if isActive then
		showDeathOverlay()
		animateCountdown(seconds)
	else
		hideDeathOverlay()
	end
end

function RespawnController.Init()
	RemoteEvents.RespawnCountdownEvent.OnClientEvent:Connect(onRespawnCountdown)
	
	-- Also hide overlay on character respawn (safety cleanup)
	player.CharacterAdded:Connect(function()
		hideDeathOverlay()
	end)
end

return RespawnController
