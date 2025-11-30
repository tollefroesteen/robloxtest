--!strict
-- TimerController.luau
-- Displays the game timer on the player's HUD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "TimerController"
local player: Player = Players.LocalPlayer

local TimerController = {}

local timerLabel: TextLabel? = nil
local timerGui: ScreenGui? = nil
local timeRemaining: number = 0

-- Formats seconds into MM:SS format
local function formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

-- Updates the timer display
local function updateTimerUI(): nil
	if not timerLabel then return end
	timerLabel.Text = formatTime(timeRemaining)
	
	-- Color feedback: white -> yellow -> red as time runs out
	if timeRemaining > 60 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
	elseif timeRemaining > 30 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50) -- Yellow
	else
		timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
	end
end

-- Creates the timer GUI programmatically
local function createTimerGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if already exists
	local existing = playerGui:FindFirstChild("TimerGui")
	if existing then
		timerGui = existing :: ScreenGui
		timerLabel = timerGui:FindFirstChild("TimerLabel") :: TextLabel
		return
	end
	
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TimerGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui
	timerGui = screenGui
	
	-- Create timer label at top center
	local label = Instance.new("TextLabel")
	label.Name = "TimerLabel"
	label.Size = UDim2.new(0, 150, 0, 50)
	label.Position = UDim2.new(0.5, -75, 0, 20)
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.3
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 32
	label.Font = Enum.Font.GothamBold
	label.Text = "00:00"
	label.Parent = screenGui
	timerLabel = label
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

-- Listen for timer updates from server
RemoteEvents.TimerUpdateEvent.OnClientEvent:Connect(function(remaining: number)
	timeRemaining = remaining
	
	-- Show GUI when timer starts
	if timerGui and not timerGui.Enabled then
		timerGui.Enabled = true
	end
	
	updateTimerUI()
end)

-- Listen for game end
RemoteEvents.EndGameEvent.OnClientEvent:Connect(function()
	Log.Info(CONTEXT, "Game ended")
	timeRemaining = 0
	updateTimerUI()
end)

-- Listen for game reset
RemoteEvents.ResetGameEvent.OnClientEvent:Connect(function()
	timeRemaining = 0
	updateTimerUI()
	if timerGui then
		timerGui.Enabled = false
	end
end)

function TimerController.Init(): nil
	createTimerGui()
	updateTimerUI()
	
	-- Hide GUI initially until game starts
	if timerGui then
		timerGui.Enabled = false
	end
end

return TimerController
