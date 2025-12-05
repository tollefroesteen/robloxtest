--!strict
-- XPController.luau
-- Displays the player's XP and level in the HUD (simple style matching CoinsController)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "XPController"
local player: Player = Players.LocalPlayer

local XPController = {}

-- UI references
local xpGui: ScreenGui? = nil
local xpLabel: TextLabel? = nil
local levelLabel: TextLabel? = nil

-- Current state
local currentXP: number = 0
local currentLevel: number = 1

-- Initialization guard
local initialized: boolean = false

-- Animation state
local isAnimating: boolean = false

-- Format number with commas
local function formatNumber(num: number): string
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- Update the XP display
local function updateXPDisplay(): nil
	if levelLabel then
		levelLabel.Text = "Lv." .. tostring(currentLevel)
	end
	
	if xpLabel then
		xpLabel.Text = formatNumber(currentXP)
	end
end

-- Animate level up
local function animateLevelUp(): nil
	if isAnimating or not levelLabel then return end
	isAnimating = true
	
	local originalColor = levelLabel.TextColor3
	
	-- Flash gold
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	
	task.delay(0.3, function()
		if levelLabel then
			levelLabel.TextColor3 = originalColor
		end
		isAnimating = false
	end)
end

-- Create the XP GUI programmatically if not found in StarterGui
local function createXPGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if already exists from Studio
	local existing = playerGui:FindFirstChild("XPGui")
	if existing and existing:IsA("ScreenGui") then
		xpGui = existing :: ScreenGui
		
		local lvl = xpGui:FindFirstChild("LevelLabel", true)
		if lvl and lvl:IsA("TextLabel") then
			levelLabel = lvl :: TextLabel
		end
		
		local xp = xpGui:FindFirstChild("XPLabel", true)
		if xp and xp:IsA("TextLabel") then
			xpLabel = xp :: TextLabel
		end
		
		Log.Info(CONTEXT, "Found XPGui from Studio")
		return
	end
	
	-- Create GUI programmatically
	Log.Info(CONTEXT, "Creating XPGui programmatically")
	
	xpGui = Instance.new("ScreenGui")
	xpGui.Name = "XPGui"
	xpGui.ResetOnSpawn = false
	xpGui.IgnoreGuiInset = true
	xpGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	xpGui.Parent = playerGui
	
	-- Container frame (top-right corner, below coins)
	local container = Instance.new("Frame")
	container.Name = "XPContainer"
	container.Size = UDim2.new(0, 150, 0, 40)
	container.Position = UDim2.new(1, -160, 0, 55)  -- Below coins (coins at 10, this at 55)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = xpGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	-- XP icon (blue circle with star)
	local xpIcon = Instance.new("Frame")
	xpIcon.Name = "XPIcon"
	xpIcon.Size = UDim2.new(0, 28, 0, 28)
	xpIcon.Position = UDim2.new(0, 8, 0.5, -14)
	xpIcon.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	xpIcon.BorderSizePixel = 0
	xpIcon.Parent = container
	
	-- Make icon circular
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = xpIcon
	
	-- XP symbol on icon
	local xpSymbol = Instance.new("TextLabel")
	xpSymbol.Name = "XPSymbol"
	xpSymbol.Size = UDim2.new(1, 0, 1, 0)
	xpSymbol.Position = UDim2.new(0, 0, 0, -1)  -- Slight offset to visually center the star
	xpSymbol.BackgroundTransparency = 1
	xpSymbol.Text = "★"
	xpSymbol.TextColor3 = Color3.fromRGB(40, 80, 150)
	xpSymbol.TextScaled = true
	xpSymbol.Font = Enum.Font.GothamBold
	xpSymbol.TextXAlignment = Enum.TextXAlignment.Center
	xpSymbol.TextYAlignment = Enum.TextYAlignment.Center
	xpSymbol.Parent = xpIcon
	
	-- Level label (small, above XP value)
	levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 40, 0, 16)
	levelLabel.Position = UDim2.new(0, 44, 0, 2)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv.1"
	levelLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	levelLabel.TextSize = 12
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = container
	
	-- XP text label
	xpLabel = Instance.new("TextLabel")
	xpLabel.Name = "XPLabel"
	xpLabel.Size = UDim2.new(0, 100, 0, 20)
	xpLabel.Position = UDim2.new(0, 44, 0, 17)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = "0"
	xpLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	xpLabel.TextSize = 18
	xpLabel.Font = Enum.Font.GothamBold
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.Parent = container
	
	-- Stroke for better visibility
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = xpLabel
	
	Log.Info(CONTEXT, "XPGui created")
end

-- Listen for stats updates (source of truth for XP/Level)
RemoteEvents.StatsUpdatedEvent.OnClientEvent:Connect(function(stats: any)
	if stats then
		local previousLevel = currentLevel
		currentXP = stats.ExperiencePoints or 0
		currentLevel = stats.Level or 1
		updateXPDisplay()
		
		if currentLevel > previousLevel then
			animateLevelUp()
		end
		
		Log.Info(CONTEXT, string.format("Stats updated: Level %d, XP %d", currentLevel, currentXP))
	end
end)

-- Listen for level up event (for immediate feedback)
RemoteEvents.LevelUpEvent.OnClientEvent:Connect(function(newLevel: number)
	local previousLevel = currentLevel
	currentLevel = newLevel
	updateXPDisplay()
	
	if newLevel > previousLevel then
		animateLevelUp()
		Log.Info(CONTEXT, string.format("Level up! Now level %d", newLevel))
	end
end)

function XPController.Init(): nil
	if initialized then return end
	initialized = true
	
	Log.Info(CONTEXT, "XPController.Init() called")
	createXPGui()
	updateXPDisplay()
end

-- Get current XP (for other controllers)
function XPController.GetXP(): number
	return currentXP
end

-- Get current level (for other controllers)
function XPController.GetLevel(): number
	return currentLevel
end

return XPController
