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

-- Finds the timer GUI from Studio's StarterGui
local function findTimerGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Find TimerGui from Studio's StarterGui
	local existing = playerGui:WaitForChild("TimerGui", 5)
	if existing and existing:IsA("ScreenGui") then
		timerGui = existing :: ScreenGui
		-- Search descendants in case TimerLabel is nested inside a Frame
		local label = timerGui:FindFirstChild("TimerLabel", true)
		if label and label:IsA("TextLabel") then
			timerLabel = label :: TextLabel
			Log.Info(CONTEXT, "Found TimerGui and TimerLabel from Studio")
		else
			Log.Warn(CONTEXT, "TimerGui found but TimerLabel not found inside it")
		end
	else
		Log.Warn(CONTEXT, "TimerGui not found in PlayerGui - make sure it exists in StarterGui")
	end
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
