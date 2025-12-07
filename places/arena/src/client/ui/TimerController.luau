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
local totalTime: number = 0 -- Track initial total time for percentage calculations

-- Formats seconds into MM:SS format
local function formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

-- Updates the timer display
local function updateTimerUI(): nil
	if not timerLabel then 
		Log.Warn(CONTEXT, "updateTimerUI called but timerLabel is nil")
		return 
	end
	timerLabel.Text = formatTime(timeRemaining)
	
	-- Color feedback based on percentage of time remaining
	-- >50% = Black, 25-50% = Yellow, <25% = Red
	local newColor: Color3
	local percentRemaining = if totalTime > 0 then (timeRemaining / totalTime) * 100 else 0
	
	if percentRemaining > 50 then
		newColor = Color3.fromRGB(0, 0, 0) -- Black
	elseif percentRemaining > 25 then
		newColor = Color3.fromRGB(255, 200, 50) -- Yellow
	else
		newColor = Color3.fromRGB(255, 80, 80) -- Red
	end
	
	timerLabel.TextColor3 = newColor
	Log.Info(CONTEXT, string.format("Timer: %s, Color set to RGB(%d,%d,%d)", 
		formatTime(timeRemaining), 
		math.floor(newColor.R * 255), 
		math.floor(newColor.G * 255), 
		math.floor(newColor.B * 255)))
end

-- Creates the timer GUI programmatically as a fallback
local function createTimerGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if we already created one
	local existing = playerGui:FindFirstChild("TimerGui")
	if existing then
		existing:Destroy()
	end
	
	-- Create ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "TimerGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	
	-- Create a frame to hold the timer (top center)
	local frame = Instance.new("Frame")
	frame.Name = "TimerFrame"
	frame.Size = UDim2.new(0, 120, 0, 50)
	frame.Position = UDim2.new(0.5, -60, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = gui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Create timer label
	local label = Instance.new("TextLabel")
	label.Name = "TimerLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "00:00"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = frame
	
	timerGui = gui
	timerLabel = label
	
	Log.Info(CONTEXT, "Created TimerGui programmatically")
end

-- Finds the timer GUI from Studio's StarterGui or creates one
local function findTimerGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- If we already have valid references, just verify they exist
	if timerGui and timerGui.Parent == playerGui and timerLabel then
		Log.Info(CONTEXT, "Using existing TimerGui references")
		return
	end
	
	-- Try to find existing TimerGui from Studio's StarterGui
	local existing = playerGui:FindFirstChild("TimerGui")
	if not existing then
		-- Wait a short time in case it's still loading
		existing = playerGui:WaitForChild("TimerGui", 1)
	end
	
	if existing and existing:IsA("ScreenGui") then
		timerGui = existing :: ScreenGui
		-- Search descendants in case TimerLabel is nested inside a Frame
		local label = timerGui:FindFirstChild("TimerLabel", true)
		if label and label:IsA("TextLabel") then
			timerLabel = label :: TextLabel
			Log.Info(CONTEXT, "Found TimerGui and TimerLabel from Studio")
			return
		else
			Log.Warn(CONTEXT, "TimerGui found but TimerLabel not found inside it")
		end
	end
	
	-- Fallback: Create GUI programmatically
	Log.Info(CONTEXT, "TimerGui not found in PlayerGui, creating programmatically")
	createTimerGui()
end

-- Listen for timer updates from server
RemoteEvents.TimerUpdateEvent.OnClientEvent:Connect(function(remaining: number)
	Log.Info(CONTEXT, string.format("Timer update received: %d seconds", remaining))
	
	-- Capture total time on first update (when timer starts)
	if totalTime == 0 or remaining > totalTime then
		totalTime = remaining
		Log.Info(CONTEXT, string.format("Total game time set to: %d seconds", totalTime))
	end
	
	timeRemaining = remaining
	
	-- Ensure GUI reference is found if not already
	if not timerLabel then
		Log.Warn(CONTEXT, "TimerLabel not ready, attempting to find GUI")
		findTimerGui()
	end
	
	-- Show GUI when timer starts
	if timerGui and not timerGui.Enabled then
		timerGui.Enabled = true
		Log.Info(CONTEXT, "Timer GUI now visible")
	end
	
	updateTimerUI()
end)

-- Listen for game end
RemoteEvents.EndGameEvent.OnClientEvent:Connect(function()
	Log.Info(CONTEXT, "Game ended")
	timeRemaining = 0
	updateTimerUI()
end)

-- Listen for team forfeit (opponent left)
RemoteEvents.TeamForfeitEvent.OnClientEvent:Connect(function(abandonedTeamName: string, winningTeamName: string, remainingTime: number)
	Log.Info(CONTEXT, string.format("Team forfeit: %s abandoned, %s wins. %d seconds remaining.", abandonedTeamName, winningTeamName, remainingTime))
	
	-- Update total time to new remaining time for color calculations
	totalTime = remainingTime
	
	-- Show notification to player (simple approach - update timer label temporarily)
	if timerLabel then
		-- Flash the text to indicate forfeit
		task.spawn(function()
			local originalText = timerLabel.Text
			timerLabel.Text = "FORFEIT!"
			timerLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
			task.wait(1.5)
			-- Timer will be updated by next TimerUpdateEvent
		end)
	end
end)

-- Listen for game reset
RemoteEvents.ResetGameEvent.OnClientEvent:Connect(function()
	timeRemaining = 0
	totalTime = 0 -- Reset total time for next game
	updateTimerUI()
	if timerGui then
		timerGui.Enabled = false
	end
end)

function TimerController.Init(): nil
	Log.Info(CONTEXT, "TimerController.Init() called")
	findTimerGui()
	updateTimerUI()
	
	-- Hide GUI initially until game starts
	if timerGui then
		timerGui.Enabled = false
		Log.Info(CONTEXT, "Timer GUI hidden until game starts")
	else
		Log.Warn(CONTEXT, "timerGui is nil after findTimerGui()")
	end
end

return TimerController
