--!strict
-- GameEndController.luau
-- Handles the sequential game end UI display (winner, scores, coins, achievements)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
local PlacesConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlacesConfig"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "GameEndController"
local player = Players.LocalPlayer

local GameEndController = {}

-- UI References
local screenGui: ScreenGui? = nil
local mainFrame: Frame? = nil
local currentTweens: { Tween } = {}

-- Timing configuration
local PHASE_DELAY = 1.5  -- Delay between phases
local COIN_COUNT_DURATION = 2.0  -- How long the coin count-up animation takes
local ACHIEVEMENT_DISPLAY_DURATION = 2.0  -- How long each achievement shows

-- Create the main screen GUI
local function createScreenGui(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "GameEndGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100  -- High priority
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

-- Create a dark overlay background
local function createOverlay(parent: ScreenGui): Frame
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1  -- Start invisible
	overlay.BorderSizePixel = 0
	overlay.Parent = parent
	return overlay
end

-- Create the main content frame
local function createMainFrame(parent: Frame): Frame
	local frame = Instance.new("Frame")
	frame.Name = "MainContent"
	frame.Size = UDim2.new(0.8, 0, 0.7, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = frame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 3
	stroke.Parent = frame
	
	return frame
end

-- Create a text label with standard styling
local function createLabel(parent: Instance, name: string, size: UDim2, position: UDim2, text: string, fontSize: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = fontSize or 36
	label.TextScaled = fontSize == nil
	label.Text = text
	label.TextTransparency = 1  -- Start invisible
	label.Parent = parent
	return label
end

-- Animate text fading in
local function fadeInText(label: TextLabel, duration: number?): Tween
	local tween = TweenService:Create(
		label,
		TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	)
	tween:Play()
	table.insert(currentTweens, tween)
	return tween
end

-- Animate text fading out
local function fadeOutText(label: TextLabel, duration: number?): Tween
	local tween = TweenService:Create(
		label,
		TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }
	)
	tween:Play()
	table.insert(currentTweens, tween)
	return tween
end

-- Animate counting up numbers (for coins)
local function animateCountUp(label: TextLabel, targetValue: number, prefix: string?, suffix: string?): nil
	prefix = prefix or ""
	suffix = suffix or ""
	
	local startTime = tick()
	local startValue = 0
	
	-- Update loop
	local connection: RBXScriptConnection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / COIN_COUNT_DURATION, 1)
		
		-- Ease out for satisfying feel
		local easedProgress = 1 - math.pow(1 - progress, 3)
		local currentValue = math.floor(startValue + (targetValue - startValue) * easedProgress)
		
		label.Text = prefix .. tostring(currentValue) .. suffix
		
		if progress >= 1 then
			connection:Disconnect()
			label.Text = prefix .. tostring(targetValue) .. suffix
		end
	end)
end

-- Clear all UI elements
local function clearUI(): nil
	-- Cancel any running tweens
	for _, tween in currentTweens do
		tween:Cancel()
	end
	currentTweens = {}
	
	-- Destroy the GUI
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
		mainFrame = nil
	end
end

-- Phase 1: Show winner announcement
local function showWinnerPhase(results: any, isWinner: boolean, isForfeit: boolean?): nil
	if not mainFrame then return end
	
	-- Clear previous content
	for _, child in mainFrame:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("Frame") and child.Name ~= "UICorner" then
			child:Destroy()
		end
	end
	
	-- Winner/Loser banner
	local bannerColor = isWinner and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
	local bannerText = isWinner and "🏆 VICTORY! 🏆" or "DEFEAT"
	
	local banner = createLabel(mainFrame, "Banner", UDim2.new(0.9, 0, 0.15, 0), UDim2.new(0.5, 0, 0.15, 0), bannerText)
	banner.TextColor3 = bannerColor
	banner.TextSize = 64
	fadeInText(banner, 0.8)
	
	-- Winning team info
	local winText = isForfeit 
		and string.format("%s Wins by Forfeit!", results.winningTeam)
		or string.format("%s Wins!", results.winningTeam)
	local winnerLabel = createLabel(
		mainFrame, "WinnerTeam", 
		UDim2.new(0.9, 0, 0.1, 0), 
		UDim2.new(0.5, 0, 0.32, 0),
		winText
	)
	winnerLabel.TextSize = 42
	if results.winningTeam == "Red Team" then
		winnerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		winnerLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
	end
	
	task.delay(0.3, function()
		fadeInText(winnerLabel, 0.5)
	end)
	
	-- Score display
	local scoreLabel = createLabel(
		mainFrame, "Scores",
		UDim2.new(0.9, 0, 0.15, 0),
		UDim2.new(0.5, 0, 0.5, 0),
		string.format("Final Score: %d - %d", results.winningScore, results.losingScore)
	)
	scoreLabel.TextSize = 36
	
	task.delay(0.6, function()
		fadeInText(scoreLabel, 0.5)
	end)
	
	-- Tie or Forfeit indicator
	if results.isTie then
		local tieLabel = createLabel(
			mainFrame, "TieIndicator",
			UDim2.new(0.9, 0, 0.08, 0),
			UDim2.new(0.5, 0, 0.62, 0),
			"(Tie broken by coin flip)"
		)
		tieLabel.TextSize = 24
		tieLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		
		task.delay(0.9, function()
			fadeInText(tieLabel, 0.5)
		end)
	elseif isForfeit then
		local forfeitLabel = createLabel(
			mainFrame, "ForfeitIndicator",
			UDim2.new(0.9, 0, 0.08, 0),
			UDim2.new(0.5, 0, 0.62, 0),
			"(Opponent team left the game)"
		)
		forfeitLabel.TextSize = 24
		forfeitLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
		
		task.delay(0.9, function()
			fadeInText(forfeitLabel, 0.5)
		end)
	end
end

-- Phase 2: Show coin reward with animation
local function showCoinsPhase(coins: number, baseCoins: number, multiplier: number, isWinner: boolean): nil
	if not mainFrame then return end
	
	-- Clear previous content
	for _, child in mainFrame:GetChildren() do
		if child:IsA("TextLabel") and child.Name ~= "UICorner" then
			child:Destroy()
		end
	end
	
	-- Coins earned header
	local header = createLabel(
		mainFrame, "CoinsHeader",
		UDim2.new(0.9, 0, 0.1, 0),
		UDim2.new(0.5, 0, 0.2, 0),
		"💰 Coins Earned 💰"
	)
	header.TextSize = 42
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	fadeInText(header, 0.5)
	
	-- Coin amount (animated count-up)
	local coinLabel = createLabel(
		mainFrame, "CoinAmount",
		UDim2.new(0.9, 0, 0.2, 0),
		UDim2.new(0.5, 0, 0.4, 0),
		"+0"
	)
	coinLabel.TextSize = 72
	coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	
	task.delay(0.3, function()
		fadeInText(coinLabel, 0.3)
		task.delay(0.2, function()
			animateCountUp(coinLabel, coins, "+", "")
		end)
	end)
	
	-- Multiplier info (if > 1.0)
	if multiplier > 1.0 then
		local bonusPercent = math.floor((multiplier - 1) * 100)
		local multiplierLabel = createLabel(
			mainFrame, "Multiplier",
			UDim2.new(0.9, 0, 0.08, 0),
			UDim2.new(0.5, 0, 0.55, 0),
			string.format("(+%d%% bonus from achievements!)", bonusPercent)
		)
		multiplierLabel.TextSize = 24
		multiplierLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		
		task.delay(COIN_COUNT_DURATION + 0.5, function()
			fadeInText(multiplierLabel, 0.5)
		end)
	end
	
	-- Winner/Loser status
	local statusText = isWinner and "Winner Bonus: 100% of team score!" or "Consolation: 25% of team score"
	local statusLabel = createLabel(
		mainFrame, "Status",
		UDim2.new(0.9, 0, 0.08, 0),
		UDim2.new(0.5, 0, 0.7, 0),
		statusText
	)
	statusLabel.TextSize = 24
	statusLabel.TextColor3 = isWinner and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(200, 200, 200)
	
	task.delay(0.8, function()
		fadeInText(statusLabel, 0.5)
	end)
end

-- Phase 3: Show achievements unlocked
local function showAchievementsPhase(achievementIDs: { string }): nil
	if not mainFrame then return end
	if #achievementIDs == 0 then return end
	
	-- Clear previous content
	for _, child in mainFrame:GetChildren() do
		if child:IsA("TextLabel") and child.Name ~= "UICorner" then
			child:Destroy()
		end
	end
	
	-- Achievements header
	local header = createLabel(
		mainFrame, "AchievementsHeader",
		UDim2.new(0.9, 0, 0.1, 0),
		UDim2.new(0.5, 0, 0.15, 0),
		"🏆 Achievements Unlocked! 🏆"
	)
	header.TextSize = 42
	header.TextColor3 = Color3.fromRGB(255, 200, 100)
	fadeInText(header, 0.5)
	
	-- List achievements
	local yOffset = 0.3
	for i, achievementID in achievementIDs do
		-- Look up achievement name from registry
		local achievementDef = AchievementRegistry.GetAchievement(achievementID)
		local achievementName = achievementDef and achievementDef.Name or achievementID
		
		local achievementLabel = createLabel(
			mainFrame, "Achievement_" .. i,
			UDim2.new(0.8, 0, 0.1, 0),
			UDim2.new(0.5, 0, yOffset, 0),
			string.format("⭐ %s", achievementName)
		)
		achievementLabel.TextSize = 32
		achievementLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
		
		task.delay(0.3 + (i - 1) * 0.4, function()
			fadeInText(achievementLabel, 0.4)
		end)
		
		yOffset += 0.12
		
		-- Limit to 5 visible at once
		if i >= 5 then break end
	end
end

-- Phase 4: Show new animals discovered
local function showNewAnimalsPhase(animalNames: { string }): nil
	if not mainFrame then return end
	if #animalNames == 0 then return end
	
	-- Clear previous content
	for _, child in mainFrame:GetChildren() do
		if child:IsA("TextLabel") and child.Name ~= "UICorner" then
			child:Destroy()
		end
	end
	
	-- New discoveries header
	local header = createLabel(
		mainFrame, "DiscoveriesHeader",
		UDim2.new(0.9, 0, 0.1, 0),
		UDim2.new(0.5, 0, 0.15, 0),
		"🔍 New Discoveries! 🔍"
	)
	header.TextSize = 42
	header.TextColor3 = Color3.fromRGB(100, 200, 255)
	fadeInText(header, 0.5)
	
	-- List animals
	local yOffset = 0.3
	for i, animalName in animalNames do
		local animalLabel = createLabel(
			mainFrame, "Animal_" .. i,
			UDim2.new(0.8, 0, 0.1, 0),
			UDim2.new(0.5, 0, yOffset, 0),
			string.format("🦎 %s added to collection!", animalName)
		)
		animalLabel.TextSize = 28
		animalLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
		
		task.delay(0.3 + (i - 1) * 0.4, function()
			fadeInText(animalLabel, 0.4)
		end)
		
		yOffset += 0.12
		
		-- Limit to 4 visible at once
		if i >= 4 then break end
	end
end

-- Phase for forfeit losers - no rewards message
local function showForfeitNoRewardsPhase(): nil
	if not mainFrame then return end
	
	-- Clear previous content
	for _, child in mainFrame:GetChildren() do
		if child:IsA("TextLabel") and child.Name ~= "UICorner" then
			child:Destroy()
		end
	end
	
	-- No rewards header
	local header = createLabel(
		mainFrame, "NoRewardsHeader",
		UDim2.new(0.9, 0, 0.1, 0),
		UDim2.new(0.5, 0, 0.3, 0),
		"❌ No Rewards ❌"
	)
	header.TextSize = 42
	header.TextColor3 = Color3.fromRGB(200, 100, 100)
	fadeInText(header, 0.5)
	
	-- Explanation
	local explanation = createLabel(
		mainFrame, "Explanation",
		UDim2.new(0.8, 0, 0.15, 0),
		UDim2.new(0.5, 0, 0.5, 0),
		"Your team forfeited by leaving the game."
	)
	explanation.TextSize = 28
	explanation.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	task.delay(0.3, function()
		fadeInText(explanation, 0.5)
	end)
	
	local subtext = createLabel(
		mainFrame, "Subtext",
		UDim2.new(0.8, 0, 0.1, 0),
		UDim2.new(0.5, 0, 0.65, 0),
		"Stay in the game to earn rewards!"
	)
	subtext.TextSize = 22
	subtext.TextColor3 = Color3.fromRGB(150, 150, 150)
	
	task.delay(0.6, function()
		fadeInText(subtext, 0.5)
	end)
end

-- Final phase: Show buttons for Lobby and Rematch
local function showFinalPhase(): nil
	if not mainFrame then return end
	
	-- Clear previous content
	for _, child in mainFrame:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("TextButton") and child.Name ~= "UICorner" then
			child:Destroy()
		end
	end
	
	-- "What's next?" text
	local headerLabel = createLabel(
		mainFrame, "Header",
		UDim2.new(0.9, 0, 0.15, 0),
		UDim2.new(0.5, 0, 0.25, 0),
		"What's next?"
	)
	headerLabel.TextSize = 48
	headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	fadeInText(headerLabel, 0.5)
	
	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(0.8, 0, 0.25, 0)
	buttonContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
	buttonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = mainFrame
	
	-- Lobby button
	local lobbyButton = Instance.new("TextButton")
	lobbyButton.Name = "LobbyButton"
	lobbyButton.Size = UDim2.new(0.45, 0, 1, 0)
	lobbyButton.Position = UDim2.new(0, 0, 0, 0)
	lobbyButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
	lobbyButton.Text = "🏠 Lobby"
	lobbyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	lobbyButton.TextSize = 32
	lobbyButton.Font = Enum.Font.GothamBold
	lobbyButton.AutoButtonColor = true
	lobbyButton.Parent = buttonContainer
	
	local lobbyCorner = Instance.new("UICorner")
	lobbyCorner.CornerRadius = UDim.new(0, 12)
	lobbyCorner.Parent = lobbyButton
	
	local lobbyStroke = Instance.new("UIStroke")
	lobbyStroke.Color = Color3.fromRGB(100, 150, 255)
	lobbyStroke.Thickness = 2
	lobbyStroke.Parent = lobbyButton
	
	-- Rematch button
	local rematchButton = Instance.new("TextButton")
	rematchButton.Name = "RematchButton"
	rematchButton.Size = UDim2.new(0.45, 0, 1, 0)
	rematchButton.Position = UDim2.new(0.55, 0, 0, 0)
	rematchButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
	rematchButton.Text = "🔄 Rematch"
	rematchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rematchButton.TextSize = 32
	rematchButton.Font = Enum.Font.GothamBold
	rematchButton.AutoButtonColor = true
	rematchButton.Parent = buttonContainer
	
	local rematchCorner = Instance.new("UICorner")
	rematchCorner.CornerRadius = UDim.new(0, 12)
	rematchCorner.Parent = rematchButton
	
	local rematchStroke = Instance.new("UIStroke")
	rematchStroke.Color = Color3.fromRGB(100, 220, 130)
	rematchStroke.Thickness = 2
	rematchStroke.Parent = rematchButton
	
	-- Lobby button click handler
	lobbyButton.MouseButton1Click:Connect(function()
		lobbyButton.Text = "Teleporting..."
		lobbyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		
		if PlacesConfig.LOBBY_PLACE_ID == 0 then
			Log.Warn(CONTEXT, "Lobby place ID not configured!")
			lobbyButton.Text = "Not configured"
			return
		end
		
		local success, err = pcall(function()
			TeleportService:Teleport(PlacesConfig.LOBBY_PLACE_ID, player)
		end)
		
		if not success then
			Log.Warn(CONTEXT, "Failed to teleport to lobby: " .. tostring(err))
			lobbyButton.Text = "Failed!"
			task.delay(2, function()
				if lobbyButton and lobbyButton.Parent then
					lobbyButton.Text = "🏠 Lobby"
					lobbyButton.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
				end
			end)
		end
	end)
	
	-- Rematch button click handler
	rematchButton.MouseButton1Click:Connect(function()
		rematchButton.Text = "Starting..."
		rematchButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		
		-- Fire rematch request to server
		RemoteEvents.RematchRequestEvent:FireServer()
		
		-- Clear UI after requesting rematch
		task.delay(1, function()
			clearUI()
		end)
	end)
	
	-- Fade in buttons
	lobbyButton.BackgroundTransparency = 1
	lobbyButton.TextTransparency = 1
	rematchButton.BackgroundTransparency = 1
	rematchButton.TextTransparency = 1
	
	task.delay(0.3, function()
		local lobbyTween = TweenService:Create(
			lobbyButton,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0, TextTransparency = 0 }
		)
		lobbyTween:Play()
		table.insert(currentTweens, lobbyTween)
	end)
	
	task.delay(0.5, function()
		local rematchTween = TweenService:Create(
			rematchButton,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0, TextTransparency = 0 }
		)
		rematchTween:Play()
		table.insert(currentTweens, rematchTween)
	end)
end

-- Main sequence controller
local function runGameEndSequence(data: any): nil
	Log.Info(CONTEXT, "Starting game end sequence")
	
	-- Clear any existing UI
	clearUI()
	
	-- Create UI structure
	screenGui = createScreenGui()
	local overlay = createOverlay(screenGui)
	mainFrame = createMainFrame(overlay)
	
	-- Fade in overlay
	local overlayTween = TweenService:Create(
		overlay,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.4 }
	)
	overlayTween:Play()
	table.insert(currentTweens, overlayTween)
	
	-- Determine if local player won (use server-provided data, or fall back to team check)
	local isWinner = data.isWinner
	if isWinner == nil then
		local localTeam = player.Team
		isWinner = localTeam and localTeam.Name == data.results.winningTeam
	end
	
	local isForfeit = data.isForfeit or false
	
	-- Phase 1: Winner announcement
	task.wait(0.5)
	showWinnerPhase(data.results, isWinner, isForfeit)
	
	-- Phase 2: Coins earned (skip if forfeit loser with 0 coins)
	task.wait(PHASE_DELAY + 1.5)
	if data.coins and data.coins > 0 then
		showCoinsPhase(data.coins, data.baseCoins or data.coins, data.multiplier or 1.0, isWinner)
		task.wait(PHASE_DELAY + COIN_COUNT_DURATION)
	elseif isForfeit and not isWinner then
		-- Show "no rewards" message for forfeit losers
		showForfeitNoRewardsPhase()
		task.wait(PHASE_DELAY + 1.0)
	end
	
	-- Phase 3: Achievements (if any)
	if data.achievements and #data.achievements > 0 then
		showAchievementsPhase(data.achievements)
		task.wait(PHASE_DELAY + #data.achievements * 0.4 + 0.5)
	end
	
	-- Phase 4: New animals (if any)
	if data.newAnimals and #data.newAnimals > 0 then
		showNewAnimalsPhase(data.newAnimals)
		task.wait(PHASE_DELAY + #data.newAnimals * 0.4 + 0.5)
	end
	
	-- Final phase
	task.wait(PHASE_DELAY)
	showFinalPhase()
	
	-- No auto-dismiss - player must choose Lobby or Rematch
	
	Log.Info(CONTEXT, "Game end sequence complete")
end

-- Initialize the controller
function GameEndController.Init(): nil
	Log.Info(CONTEXT, "Initializing GameEndController")
	
	-- Listen for game end sequence event
	RemoteEvents.GameEndSequenceEvent.OnClientEvent:Connect(function(data: any)
		Log.Info(CONTEXT, "Received game end sequence data")
		task.spawn(function()
			runGameEndSequence(data)
		end)
	end)
	
	-- Listen for game unfreeze to clear UI
	RemoteEvents.GameFreezeEvent.OnClientEvent:Connect(function(frozen: boolean)
		if not frozen then
			-- Game unfrozen, clear the end game UI after a short delay
			task.delay(1, function()
				clearUI()
			end)
		end
	end)
	
	Log.Info(CONTEXT, "GameEndController initialized")
end

return GameEndController
