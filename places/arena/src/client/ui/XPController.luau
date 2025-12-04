--!strict
-- XPController.luau
-- Displays the player's XP and level in the HUD

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
local xpBar: Frame? = nil
local xpBarFill: Frame? = nil

-- Current state
local currentXP: number = 0
local currentLevel: number = 1
local xpForNextLevel: number = 100

-- Initialization guard
local initialized: boolean = false

-- XP calculation (must match server)
local XP_PER_LEVEL = 100
local XP_SCALE_FACTOR = 1.5

local function getXPForLevel(level: number): number
	return math.floor(XP_PER_LEVEL * (XP_SCALE_FACTOR ^ (level - 1)))
end

local function getTotalXPForLevel(level: number): number
	local total = 0
	for i = 1, level - 1 do
		total += getXPForLevel(i)
	end
	return total
end

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
	
	-- Calculate XP progress within current level
	local xpForCurrentLevel = getTotalXPForLevel(currentLevel)
	local xpToNextLevel = getXPForLevel(currentLevel)
	local xpIntoLevel = currentXP - xpForCurrentLevel
	local progress = math.clamp(xpIntoLevel / xpToNextLevel, 0, 1)
	
	if xpLabel then
		xpLabel.Text = string.format("%s / %s XP", formatNumber(xpIntoLevel), formatNumber(xpToNextLevel))
	end
	
	if xpBarFill then
		xpBarFill.Size = UDim2.new(progress, 0, 1, 0)
	end
end

-- Animate level up
local function animateLevelUp(): nil
	if not levelLabel then return end
	
	local originalSize = levelLabel.TextSize
	local originalColor = levelLabel.TextColor3
	
	-- Flash gold and scale up
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelLabel.TextSize = originalSize * 1.3
	
	task.delay(0.3, function()
		if levelLabel then
			levelLabel.TextSize = originalSize
			levelLabel.TextColor3 = originalColor
		end
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
		
		local bar = xpGui:FindFirstChild("XPBar", true)
		if bar and bar:IsA("Frame") then
			xpBar = bar :: Frame
			local fill = bar:FindFirstChild("Fill")
			if fill and fill:IsA("Frame") then
				xpBarFill = fill :: Frame
			end
		end
		
		Log.Info(CONTEXT, "Found XPGui from Studio")
		return
	end
	
	-- Create GUI programmatically
	Log.Info(CONTEXT, "Creating XPGui programmatically")
	
	xpGui = Instance.new("ScreenGui")
	xpGui.Name = "XPGui"
	xpGui.ResetOnSpawn = false
	xpGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	xpGui.Parent = playerGui
	
	-- Container frame (top-right corner, below coins)
	local container = Instance.new("Frame")
	container.Name = "XPContainer"
	container.Size = UDim2.new(0, 150, 0, 50)
	container.Position = UDim2.new(1, -160, 0, 0)  -- Below coins
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = xpGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	-- Level label
	levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 50, 0, 24)
	levelLabel.Position = UDim2.new(0, 8, 0, 4)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv.1"
	levelLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
	levelLabel.TextSize = 18
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = container
	
	-- Level stroke
	local levelStroke = Instance.new("UIStroke")
	levelStroke.Color = Color3.fromRGB(0, 0, 0)
	levelStroke.Thickness = 1
	levelStroke.Transparency = 0.5
	levelStroke.Parent = levelLabel
	
	-- XP text label
	xpLabel = Instance.new("TextLabel")
	xpLabel.Name = "XPLabel"
	xpLabel.Size = UDim2.new(0, 85, 0, 24)
	xpLabel.Position = UDim2.new(0, 58, 0, 4)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = "0 / 100 XP"
	xpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	xpLabel.TextSize = 12
	xpLabel.Font = Enum.Font.Gotham
	xpLabel.TextXAlignment = Enum.TextXAlignment.Right
	xpLabel.Parent = container
	
	-- XP bar background
	xpBar = Instance.new("Frame")
	xpBar.Name = "XPBar"
	xpBar.Size = UDim2.new(1, -16, 0, 12)
	xpBar.Position = UDim2.new(0, 8, 0, 32)
	xpBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	xpBar.BorderSizePixel = 0
	xpBar.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = xpBar
	
	-- XP bar fill
	xpBarFill = Instance.new("Frame")
	xpBarFill.Name = "Fill"
	xpBarFill.Size = UDim2.new(0, 0, 1, 0)
	xpBarFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	xpBarFill.BorderSizePixel = 0
	xpBarFill.Parent = xpBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = xpBarFill
	
	-- Gradient on fill
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 160, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255)),
	})
	gradient.Rotation = 90
	gradient.Parent = xpBarFill
	
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
