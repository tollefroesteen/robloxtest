--!strict
-- MatchmakingController.luau
-- Client-side controller for matchmaking
-- Handles countdown UI, zone detection feedback, and queue status display

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))
local MatchmakingConfig = require(Shared:WaitForChild("config"):WaitForChild("MatchmakingConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local CONTEXT = "MatchmakingController"
local LocalPlayer = Players.LocalPlayer

local MatchmakingController = {}

-- State
local currentZone: string? = nil -- "1v1" or "2v2"
local isInQueue: boolean = false
local countdownActive: boolean = false
local countdownRemaining: number = 0
local teammateInfo: string? = nil
local queueZoneType: string? = nil -- Track which queue type we're in

-- UI references
local screenGui: ScreenGui? = nil
local countdownFrame: Frame? = nil
local queueFrame: Frame? = nil
local cancelButton: TextButton? = nil

-- Countdown connection
local countdownConnection: RBXScriptConnection? = nil

--[[
	Create the matchmaking UI
]]
local function createUI(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "MatchmakingUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10
	
	-- Countdown frame (shown when in zone)
	local cFrame = Instance.new("Frame")
	cFrame.Name = "CountdownFrame"
	cFrame.Size = UDim2.new(0, 320, 0, 180)
	cFrame.Position = UDim2.new(0.5, -160, 0.25, 0)
	cFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	cFrame.BackgroundTransparency = 0.15
	cFrame.BorderSizePixel = 0
	cFrame.Visible = false
	cFrame.Parent = gui
	
	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 16)
	cCorner.Parent = cFrame
	
	local cStroke = Instance.new("UIStroke")
	cStroke.Name = "Stroke"
	cStroke.Thickness = 3
	cStroke.Parent = cFrame
	
	-- Mode label (1v1 or 2v2)
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(1, 0, 0, 35)
	modeLabel.Position = UDim2.new(0, 0, 0, 10)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "1v1 DUEL"
	modeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	modeLabel.TextSize = 26
	modeLabel.Font = Enum.Font.GothamBold
	modeLabel.Parent = cFrame
	
	-- Countdown number
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(1, 0, 0, 70)
	countdownLabel.Position = UDim2.new(0, 0, 0, 45)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "10"
	countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLabel.TextSize = 64
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.Parent = cFrame
	
	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 25)
	statusLabel.Position = UDim2.new(0, 0, 0, 115)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Joining queue..."
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.TextSize = 16
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = cFrame
	
	-- Instruction label
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "InstructionLabel"
	instructionLabel.Size = UDim2.new(1, 0, 0, 20)
	instructionLabel.Position = UDim2.new(0, 0, 0, 145)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Step out to cancel"
	instructionLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	instructionLabel.TextSize = 14
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.Parent = cFrame
	
	countdownFrame = cFrame
	
	-- Queue status frame (shown when in queue)
	local qFrame = Instance.new("Frame")
	qFrame.Name = "QueueFrame"
	qFrame.Size = UDim2.new(0, 280, 0, 140) -- Increased height for cancel button
	qFrame.Position = UDim2.new(0.5, -140, 0.15, 0)
	qFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 25)
	qFrame.BackgroundTransparency = 0.2
	qFrame.BorderSizePixel = 0
	qFrame.Visible = false
	qFrame.Parent = gui
	
	local qCorner = Instance.new("UICorner")
	qCorner.CornerRadius = UDim.new(0, 12)
	qCorner.Parent = qFrame
	
	local qStroke = Instance.new("UIStroke")
	qStroke.Color = Color3.fromRGB(100, 200, 100)
	qStroke.Thickness = 2
	qStroke.Parent = qFrame
	
	local qModeLabel = Instance.new("TextLabel")
	qModeLabel.Name = "QueueModeLabel"
	qModeLabel.Size = UDim2.new(1, 0, 0, 30)
	qModeLabel.Position = UDim2.new(0, 0, 0, 10)
	qModeLabel.BackgroundTransparency = 1
	qModeLabel.Text = "IN QUEUE - 1v1"
	qModeLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	qModeLabel.TextSize = 20
	qModeLabel.Font = Enum.Font.GothamBold
	qModeLabel.Parent = qFrame
	
	local qStatusLabel = Instance.new("TextLabel")
	qStatusLabel.Name = "QueueStatusLabel"
	qStatusLabel.Size = UDim2.new(1, 0, 0, 25)
	qStatusLabel.Position = UDim2.new(0, 0, 0, 40)
	qStatusLabel.BackgroundTransparency = 1
	qStatusLabel.Text = "Searching for opponent..."
	qStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	qStatusLabel.TextSize = 14
	qStatusLabel.Font = Enum.Font.Gotham
	qStatusLabel.Parent = qFrame
	
	-- Animated dots for searching
	local dotsLabel = Instance.new("TextLabel")
	dotsLabel.Name = "DotsLabel"
	dotsLabel.Size = UDim2.new(1, 0, 0, 20)
	dotsLabel.Position = UDim2.new(0, 0, 0, 65)
	dotsLabel.BackgroundTransparency = 1
	dotsLabel.Text = "• • •"
	dotsLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	dotsLabel.TextSize = 18
	dotsLabel.Font = Enum.Font.GothamBold
	dotsLabel.Parent = qFrame
	
	-- Cancel button
	local qCancelButton = Instance.new("TextButton")
	qCancelButton.Name = "CancelButton"
	qCancelButton.Size = UDim2.new(0, 120, 0, 32)
	qCancelButton.Position = UDim2.new(0.5, -60, 1, -45)
	qCancelButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	qCancelButton.BorderSizePixel = 0
	qCancelButton.Text = "Cancel"
	qCancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	qCancelButton.TextSize = 16
	qCancelButton.Font = Enum.Font.GothamBold
	qCancelButton.Parent = qFrame
	
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = qCancelButton
	
	cancelButton = qCancelButton
	
	queueFrame = qFrame
	
	return gui
end

--[[
	Lock player movement (disable controls while in queue)
]]
local function lockPlayerMovement()
	local character = LocalPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
	
	-- Disable player controls
	local playerModule = LocalPlayer:FindFirstChild("PlayerScripts")
	if playerModule then
		local controlModule = playerModule:FindFirstChild("PlayerModule")
		if controlModule then
			local controls = require(controlModule):GetControls()
			if controls and controls.Disable then
				controls:Disable()
			end
		end
	end
	
	Log.Debug(CONTEXT, "Player movement locked")
end

--[[
	Unlock player movement
]]
local function unlockPlayerMovement()
	local character = LocalPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 -- Default walk speed
		humanoid.JumpPower = 50 -- Default jump power
		humanoid.JumpHeight = 7.2 -- Default jump height
	end
	
	-- Re-enable player controls
	local playerModule = LocalPlayer:FindFirstChild("PlayerScripts")
	if playerModule then
		local controlModule = playerModule:FindFirstChild("PlayerModule")
		if controlModule then
			local controls = require(controlModule):GetControls()
			if controls and controls.Enable then
				controls:Enable()
			end
		end
	end
	
	Log.Debug(CONTEXT, "Player movement unlocked")
end

--[[
	Update the countdown display
]]
local function updateCountdownDisplay(seconds: number)
	if not countdownFrame then return end
	
	local label = countdownFrame:FindFirstChild("CountdownLabel") :: TextLabel?
	if label then
		label.Text = tostring(math.ceil(seconds))
		
		-- Pulse animation on each second
		label.TextSize = 80
		local tween = TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			TextSize = 64
		})
		tween:Play()
	end
end

--[[
	Show the countdown UI for a specific zone
]]
local function showCountdownUI(zoneType: string)
	if not countdownFrame then return end
	
	-- Set colors and text based on zone type
	local stroke = countdownFrame:FindFirstChild("Stroke") :: UIStroke?
	local modeLabel = countdownFrame:FindFirstChild("ModeLabel") :: TextLabel?
	local statusLabel = countdownFrame:FindFirstChild("StatusLabel") :: TextLabel?
	
	if zoneType == "1v1" then
		if stroke then stroke.Color = Color3.fromRGB(255, 100, 100) end
		if modeLabel then
			modeLabel.Text = "⚔️ 1v1 DUEL"
			modeLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
		end
		if statusLabel then
			statusLabel.Text = "Joining solo queue..."
		end
	else
		if stroke then stroke.Color = Color3.fromRGB(100, 100, 255) end
		if modeLabel then
			modeLabel.Text = "👥 2v2 TEAM"
			modeLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
		end
		if statusLabel then
			statusLabel.Text = "Looking for teammate..."
		end
	end
	
	-- Animate in
	countdownFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
	countdownFrame.BackgroundTransparency = 1
	countdownFrame.Visible = true
	
	local tween = TweenService:Create(countdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -160, 0.25, 0),
		BackgroundTransparency = 0.15
	})
	tween:Play()
end

--[[
	Hide the countdown UI
]]
local function hideCountdownUI()
	if not countdownFrame then return end
	
	local tween = TweenService:Create(countdownFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -160, 0.2, 0),
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		countdownFrame.Visible = false
	end)
end

--[[
	Show the queue status UI
]]
local function showQueueUI(zoneType: string)
	if not queueFrame then return end
	
	local modeLabel = queueFrame:FindFirstChild("QueueModeLabel") :: TextLabel?
	local statusLabel = queueFrame:FindFirstChild("QueueStatusLabel") :: TextLabel?
	
	if zoneType == "1v1" then
		if modeLabel then modeLabel.Text = "IN QUEUE - 1v1" end
		if statusLabel then statusLabel.Text = "Searching for opponent..." end
	else
		if modeLabel then modeLabel.Text = "IN QUEUE - 2v2" end
		if statusLabel then
			if teammateInfo then
				statusLabel.Text = string.format("Teamed with %s - Finding opponents...", teammateInfo)
			else
				statusLabel.Text = "Searching for match..."
			end
		end
	end
	
	-- Animate in
	queueFrame.Position = UDim2.new(0.5, -140, 0.1, 0)
	queueFrame.BackgroundTransparency = 1
	queueFrame.Visible = true
	
	local tween = TweenService:Create(queueFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -140, 0.15, 0),
		BackgroundTransparency = 0.2
	})
	tween:Play()
	
	-- Start animated dots
	task.spawn(function()
		local dots = { "•", "• •", "• • •" }
		local index = 1
		while isInQueue and queueFrame and queueFrame.Visible do
			local dotsLabel = queueFrame:FindFirstChild("DotsLabel") :: TextLabel?
			if dotsLabel then
				dotsLabel.Text = dots[index]
				index = (index % #dots) + 1
			end
			task.wait(0.5)
		end
	end)
end

--[[
	Hide the queue status UI
]]
local function hideQueueUI()
	if not queueFrame then return end
	
	local tween = TweenService:Create(queueFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -140, 0.1, 0),
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		queueFrame.Visible = false
	end)
end

--[[
	Start the countdown timer
]]
local function startCountdown()
	if countdownActive then return end
	
	countdownActive = true
	countdownRemaining = MatchmakingConfig.COUNTDOWN_SECONDS
	
	updateCountdownDisplay(countdownRemaining)
	
	-- Run countdown
	countdownConnection = RunService.Heartbeat:Connect(function(dt)
		if not countdownActive then
			if countdownConnection then
				countdownConnection:Disconnect()
				countdownConnection = nil
			end
			return
		end
		
		countdownRemaining -= dt
		
		if countdownRemaining <= 0 then
			-- Countdown complete - server will handle queue addition
			countdownActive = false
			if countdownConnection then
				countdownConnection:Disconnect()
				countdownConnection = nil
			end
			
			-- Notify server
			RemoteEvents.MatchmakingCountdownCompleteEvent:FireServer()
			
			Log.Debug(CONTEXT, "Countdown complete, notifying server")
		else
			-- Update display every second
			updateCountdownDisplay(countdownRemaining)
		end
	end)
end

--[[
	Stop the countdown timer
]]
local function stopCountdown()
	countdownActive = false
	countdownRemaining = 0
	
	if countdownConnection then
		countdownConnection:Disconnect()
		countdownConnection = nil
	end
end

--[[
	Handle entering a matchmaking zone
]]
local function onZoneEntered(zoneType: string)
	Log.Debug(CONTEXT, string.format("Entered %s zone", zoneType))
	
	currentZone = zoneType
	showCountdownUI(zoneType)
	startCountdown()
end

--[[
	Handle exiting a matchmaking zone
]]
local function onZoneExited()
	Log.Debug(CONTEXT, "Exited matchmaking zone")
	
	currentZone = nil
	stopCountdown()
	hideCountdownUI()
end

--[[
	Handle joining the queue
]]
local function onQueueJoined(zoneType: string)
	Log.Info(CONTEXT, string.format("Joined %s queue", zoneType))
	
	isInQueue = true
	queueZoneType = zoneType
	hideCountdownUI()
	showQueueUI(zoneType)
	lockPlayerMovement()
end

--[[
	Handle queue cancelled (by player or server)
]]
local function onQueueCancelled()
	Log.Info(CONTEXT, "Queue cancelled")
	
	isInQueue = false
	queueZoneType = nil
	teammateInfo = nil
	hideQueueUI()
	unlockPlayerMovement()
end

--[[
	Handle zone full notification
]]
local function onZoneFull(zoneType: string)
	Log.Info(CONTEXT, string.format("%s zone is full", zoneType))
	
	-- Could show a brief notification to the player
	-- For now, they just get pushed out of the zone
end

--[[
	Request to cancel the queue
]]
local function requestCancelQueue()
	if not isInQueue then return end
	
	Log.Debug(CONTEXT, "Requesting queue cancellation")
	RemoteEvents.MatchmakingCancelQueueEvent:FireServer()
end

--[[
	Handle team formation in 2v2
]]
local function onTeamFormed(teammateName: string)
	Log.Info(CONTEXT, string.format("Team formed with %s", teammateName))
	
	teammateInfo = teammateName
	
	-- Update status label if queue UI is visible
	if queueFrame and queueFrame.Visible then
		local statusLabel = queueFrame:FindFirstChild("QueueStatusLabel") :: TextLabel?
		if statusLabel then
			statusLabel.Text = string.format("Teamed with %s - Finding opponents...", teammateName)
		end
	end
	
	-- Show notification
	-- TODO: Could add a toast notification here
end

--[[
	Handle match found
]]
local function onMatchFound()
	Log.Info(CONTEXT, "Match found! Teleporting...")
	
	isInQueue = false
	queueZoneType = nil
	teammateInfo = nil
	hideQueueUI()
	unlockPlayerMovement() -- Unlock before teleport
	
	-- Show "Match Found" message briefly
	if queueFrame then
		local modeLabel = queueFrame:FindFirstChild("QueueModeLabel") :: TextLabel?
		local statusLabel = queueFrame:FindFirstChild("QueueStatusLabel") :: TextLabel?
		local dotsLabel = queueFrame:FindFirstChild("DotsLabel") :: TextLabel?
		local cancelBtn = queueFrame:FindFirstChild("CancelButton") :: TextButton?
		
		if modeLabel then
			modeLabel.Text = "🎮 MATCH FOUND!"
			modeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		end
		if statusLabel then statusLabel.Text = "Teleporting to arena..." end
		if dotsLabel then dotsLabel.Text = "" end
		if cancelBtn then cancelBtn.Visible = false end
		
		queueFrame.Visible = true
		queueFrame.BackgroundTransparency = 0.1
	end
end

--[[
	Initialize the matchmaking controller
]]
function MatchmakingController.Init()
	Log.Info(CONTEXT, "Initializing matchmaking controller...")
	
	-- Create UI
	screenGui = createUI()
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Connect cancel button
	if cancelButton then
		cancelButton.MouseButton1Click:Connect(requestCancelQueue)
		
		-- Hover effects for cancel button
		cancelButton.MouseEnter:Connect(function()
			TweenService:Create(cancelButton, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(200, 80, 80)
			}):Play()
		end)
		cancelButton.MouseLeave:Connect(function()
			TweenService:Create(cancelButton, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(180, 60, 60)
			}):Play()
		end)
	end
	
	-- Connect to server events
	RemoteEvents.MatchmakingZoneEnteredEvent.OnClientEvent:Connect(onZoneEntered)
	RemoteEvents.MatchmakingZoneExitedEvent.OnClientEvent:Connect(onZoneExited)
	RemoteEvents.MatchmakingZoneFullEvent.OnClientEvent:Connect(onZoneFull)
	RemoteEvents.MatchmakingQueueJoinedEvent.OnClientEvent:Connect(onQueueJoined)
	RemoteEvents.MatchmakingTeamFormedEvent.OnClientEvent:Connect(onTeamFormed)
	RemoteEvents.MatchmakingMatchFoundEvent.OnClientEvent:Connect(onMatchFound)
	RemoteEvents.MatchmakingQueueCancelledEvent.OnClientEvent:Connect(onQueueCancelled)
	
	-- Make sure movement is restored when character respawns
	LocalPlayer.CharacterAdded:Connect(function()
		if not isInQueue then
			unlockPlayerMovement()
		end
	end)
	
	Log.Info(CONTEXT, "Matchmaking controller initialized")
end

--[[
	Check if player is currently in queue
]]
function MatchmakingController.IsInQueue(): boolean
	return isInQueue
end

--[[
	Get current zone type
]]
function MatchmakingController.GetCurrentZone(): string?
	return currentZone
end

--[[
	Cancel queue from external source
]]
function MatchmakingController.CancelQueue()
	requestCancelQueue()
end

return MatchmakingController
