--!strict
-- AchievementNotificationController.luau
-- Displays achievement unlock notifications as popups

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "AchievementNotificationController"
local player: Player = Players.LocalPlayer

local AchievementNotificationController = {}

-- Configuration
local NOTIFICATION_DURATION = 4.0  -- How long the notification stays visible
local SLIDE_IN_TIME = 0.3
local SLIDE_OUT_TIME = 0.3
local NOTIFICATION_HEIGHT = 80
local NOTIFICATION_WIDTH = 300

-- UI references
local notificationGui: ScreenGui? = nil
local notificationContainer: Frame? = nil

-- Queue for multiple achievements
local notificationQueue: { { id: string, name: string, description: string, xp: number } } = {}
local isShowingNotification: boolean = false

-- Initialization guard
local initialized: boolean = false

-- Create the notification GUI
local function createNotificationGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if already exists
	local existing = playerGui:FindFirstChild("AchievementNotificationGui")
	if existing then
		existing:Destroy()
	end
	
	notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "AchievementNotificationGui"
	notificationGui.ResetOnSpawn = false
	notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notificationGui.DisplayOrder = 100  -- Above other UIs
	notificationGui.Parent = playerGui
	
	-- Container for notifications (top center)
	notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, NOTIFICATION_HEIGHT)
	notificationContainer.Position = UDim2.new(0.5, -NOTIFICATION_WIDTH / 2, 0, -NOTIFICATION_HEIGHT)  -- Start off-screen
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.Parent = notificationGui
	
	Log.Info(CONTEXT, "AchievementNotificationGui created")
end

-- Create a notification frame
local function createNotificationFrame(name: string, description: string, xp: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Notification"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	-- Border/glow effect
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 50)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame
	
	-- Achievement icon (trophy)
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 60, 0, 60)
	iconFrame.Position = UDim2.new(0, 10, 0.5, -30)
	iconFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = frame
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconFrame
	
	-- Trophy symbol
	local trophyLabel = Instance.new("TextLabel")
	trophyLabel.Name = "Trophy"
	trophyLabel.Size = UDim2.new(1, 0, 1, 0)
	trophyLabel.BackgroundTransparency = 1
	trophyLabel.Text = "🏆"
	trophyLabel.TextScaled = true
	trophyLabel.Parent = iconFrame
	
	-- "Achievement Unlocked" header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Name = "Header"
	headerLabel.Size = UDim2.new(0, 210, 0, 20)
	headerLabel.Position = UDim2.new(0, 80, 0, 8)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = "ACHIEVEMENT UNLOCKED!"
	headerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	headerLabel.TextSize = 12
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = frame
	
	-- Achievement name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0, 210, 0, 24)
	nameLabel.Position = UDim2.new(0, 80, 0, 28)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = frame
	
	-- XP reward
	local xpLabel = Instance.new("TextLabel")
	xpLabel.Name = "XP"
	xpLabel.Size = UDim2.new(0, 210, 0, 18)
	xpLabel.Position = UDim2.new(0, 80, 0, 52)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = xp > 0 and string.format("+%d XP", xp) or description
	xpLabel.TextColor3 = xp > 0 and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(180, 180, 180)
	xpLabel.TextSize = 14
	xpLabel.Font = Enum.Font.Gotham
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.Parent = frame
	
	return frame
end

-- Show a notification with animation
local function showNotification(id: string, name: string, description: string, xp: number): nil
	if not notificationContainer then return end
	
	isShowingNotification = true
	
	-- Create notification frame
	local notificationFrame = createNotificationFrame(name, description, xp)
	notificationFrame.Parent = notificationContainer
	
	-- Slide in from top
	local slideInTween = TweenService:Create(
		notificationContainer,
		TweenInfo.new(SLIDE_IN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -NOTIFICATION_WIDTH / 2, 0, 20) }
	)
	slideInTween:Play()
	
	-- Wait for display duration
	task.wait(SLIDE_IN_TIME + NOTIFICATION_DURATION)
	
	-- Slide out to top
	local slideOutTween = TweenService:Create(
		notificationContainer,
		TweenInfo.new(SLIDE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, -NOTIFICATION_WIDTH / 2, 0, -NOTIFICATION_HEIGHT) }
	)
	slideOutTween:Play()
	
	task.wait(SLIDE_OUT_TIME)
	
	-- Clean up
	notificationFrame:Destroy()
	isShowingNotification = false
	
	-- Show next in queue if any
	if #notificationQueue > 0 then
		local next = table.remove(notificationQueue, 1)
		task.spawn(function()
			showNotification(next.id, next.name, next.description, next.xp)
		end)
	end
end

-- Queue a notification
local function queueNotification(id: string, name: string, description: string, xp: number): nil
	if isShowingNotification then
		table.insert(notificationQueue, { id = id, name = name, description = description, xp = xp })
	else
		task.spawn(function()
			showNotification(id, name, description, xp)
		end)
	end
end

-- Listen for achievement unlocked events
RemoteEvents.AchievementUnlockedEvent.OnClientEvent:Connect(function(achievementID: string, achievementName: string)
	Log.Info(CONTEXT, string.format("Achievement unlocked: %s (%s)", achievementName, achievementID))
	
	-- Get achievement details from registry
	local achievementDef = AchievementRegistry.GetAchievement(achievementID)
	local description = achievementDef and achievementDef.Description or ""
	local xp = achievementDef and achievementDef.RewardXP or 0
	
	queueNotification(achievementID, achievementName, description, xp)
end)

function AchievementNotificationController.Init(): nil
	if initialized then return end
	initialized = true
	
	Log.Info(CONTEXT, "AchievementNotificationController.Init() called")
	createNotificationGui()
end

-- Manually show an achievement notification (for testing)
function AchievementNotificationController.ShowNotification(name: string, description: string, xp: number): nil
	queueNotification("TEST", name, description, xp)
end

return AchievementNotificationController
