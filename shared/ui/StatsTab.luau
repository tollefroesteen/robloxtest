--!strict
-- StatsTab.luau
-- Stats tab UI for PlayerMenu (Level, XP, Coins, Game Statistics)
-- Focused on player progression and game performance

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local CONTEXT = "StatsTab"

local StatsTab = {}

-- XP calculation constants (must match server)
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

-- Get level reward info
local function getNextLevelReward(level: number): (string?, string?, number?)
	local levelAchievements = {
		{ level = 5, id = "LEVEL_5", name = "Rising Star", reward = "50x Basic Bullets" },
		{ level = 10, id = "LEVEL_10", name = "Experienced", reward = "25x Tranquilizer Darts" },
		{ level = 25, id = "LEVEL_25", name = "Veteran", reward = "3x Portable Traps" },
	}
	
	for _, ach in levelAchievements do
		if ach.level > level then
			return ach.name, ach.reward, ach.level
		end
	end
	return nil, nil, nil
end

-- Create enhanced Level & XP card
local function createLevelCard(container: ScrollingFrame, cachedStats: any, order: number): number
	local currentLevel = cachedStats.Level or 1
	local totalXP = cachedStats.ExperiencePoints or 0
	local xpForCurrentLevel = getTotalXPForLevel(currentLevel)
	local xpForNextLevel = getTotalXPForLevel(currentLevel + 1)
	local xpInCurrentLevel = totalXP - xpForCurrentLevel
	local xpNeededForNext = xpForNextLevel - xpForCurrentLevel
	local progressToNext = if xpNeededForNext > 0 then math.min(xpInCurrentLevel / xpNeededForNext, 1) else 1
	
	local levelCard = Instance.new("Frame")
	levelCard.Name = "LevelCard"
	levelCard.Size = UDim2.new(1, -30, 0, 100)
	levelCard.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
	levelCard.BorderSizePixel = 0
	levelCard.LayoutOrder = order
	levelCard.Parent = container
	
	local levelCardCorner = Instance.new("UICorner")
	levelCardCorner.CornerRadius = UDim.new(0, 10)
	levelCardCorner.Parent = levelCard
	
	-- Level badge (left side)
	local levelBadge = Instance.new("Frame")
	levelBadge.Name = "LevelBadge"
	levelBadge.Size = UDim2.new(0, 70, 0, 70)
	levelBadge.Position = UDim2.new(0, 15, 0.5, -35)
	levelBadge.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	levelBadge.BorderSizePixel = 0
	levelBadge.Parent = levelCard
	
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 35)
	badgeCorner.Parent = levelBadge
	
	local levelNumber = Instance.new("TextLabel")
	levelNumber.Name = "LevelNumber"
	levelNumber.Size = UDim2.new(1, 0, 0.65, 0)
	levelNumber.Position = UDim2.new(0, 0, 0, 0)
	levelNumber.BackgroundTransparency = 1
	levelNumber.Text = tostring(currentLevel)
	levelNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
	levelNumber.TextSize = 28
	levelNumber.Font = Enum.Font.GothamBold
	levelNumber.Parent = levelBadge
	
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0, 14)
	levelLabel.Position = UDim2.new(0, 0, 1, -16)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "LEVEL"
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextSize = 9
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Parent = levelBadge
	
	-- XP Progress (right side)
	local xpContainer = Instance.new("Frame")
	xpContainer.Name = "XPContainer"
	xpContainer.Size = UDim2.new(1, -110, 0, 80)
	xpContainer.Position = UDim2.new(0, 95, 0, 10)
	xpContainer.BackgroundTransparency = 1
	xpContainer.Parent = levelCard
	
	local xpTitle = Instance.new("TextLabel")
	xpTitle.Name = "XPTitle"
	xpTitle.Size = UDim2.new(1, 0, 0, 18)
	xpTitle.BackgroundTransparency = 1
	xpTitle.Text = "Experience Progress"
	xpTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	xpTitle.TextSize = 12
	xpTitle.Font = Enum.Font.GothamBold
	xpTitle.TextXAlignment = Enum.TextXAlignment.Left
	xpTitle.Parent = xpContainer
	
	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, 0, 0, 18)
	progressBg.Position = UDim2.new(0, 0, 0, 22)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = xpContainer
	
	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 9)
	progressBgCorner.Parent = progressBg
	
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(progressToNext, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	
	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 9)
	progressFillCorner.Parent = progressFill
	
	-- Gradient on progress bar
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 150, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255)),
	})
	gradient.Parent = progressFill
	
	-- Progress percentage inside bar
	local progressPercent = Instance.new("TextLabel")
	progressPercent.Name = "ProgressPercent"
	progressPercent.Size = UDim2.new(1, 0, 1, 0)
	progressPercent.BackgroundTransparency = 1
	progressPercent.Text = string.format("%.0f%%", progressToNext * 100)
	progressPercent.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressPercent.TextSize = 10
	progressPercent.Font = Enum.Font.GothamBold
	progressPercent.Parent = progressBg
	
	-- XP text
	local xpText = Instance.new("TextLabel")
	xpText.Name = "XPText"
	xpText.Size = UDim2.new(1, 0, 0, 16)
	xpText.Position = UDim2.new(0, 0, 0, 44)
	xpText.BackgroundTransparency = 1
	xpText.Text = string.format("%d / %d XP to Level %d", xpInCurrentLevel, xpNeededForNext, currentLevel + 1)
	xpText.TextColor3 = Color3.fromRGB(150, 200, 255)
	xpText.TextSize = 11
	xpText.Font = Enum.Font.Gotham
	xpText.TextXAlignment = Enum.TextXAlignment.Left
	xpText.Parent = xpContainer
	
	return order + 1
end

-- Create Total XP card (similar to coins display)
local function createTotalXPCard(container: ScrollingFrame, cachedStats: any, order: number): number
	local totalXP = cachedStats.ExperiencePoints or 0
	
	local xpCard = Instance.new("Frame")
	xpCard.Name = "TotalXPCard"
	xpCard.Size = UDim2.new(1, -30, 0, 60)
	xpCard.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
	xpCard.BorderSizePixel = 0
	xpCard.LayoutOrder = order
	xpCard.Parent = container
	
	local xpCardCorner = Instance.new("UICorner")
	xpCardCorner.CornerRadius = UDim.new(0, 10)
	xpCardCorner.Parent = xpCard
	
	-- XP icon
	local xpIcon = Instance.new("TextLabel")
	xpIcon.Name = "XPIcon"
	xpIcon.Size = UDim2.new(0, 50, 0, 50)
	xpIcon.Position = UDim2.new(0, 15, 0.5, -25)
	xpIcon.BackgroundTransparency = 1
	xpIcon.Text = "⭐"
	xpIcon.TextSize = 36
	xpIcon.Font = Enum.Font.GothamBold
	xpIcon.Parent = xpCard
	
	-- XP info container
	local xpInfo = Instance.new("Frame")
	xpInfo.Name = "XPInfo"
	xpInfo.Size = UDim2.new(1, -90, 1, -10)
	xpInfo.Position = UDim2.new(0, 75, 0, 5)
	xpInfo.BackgroundTransparency = 1
	xpInfo.Parent = xpCard
	
	local xpLabel = Instance.new("TextLabel")
	xpLabel.Name = "XPLabel"
	xpLabel.Size = UDim2.new(1, 0, 0, 20)
	xpLabel.Position = UDim2.new(0, 0, 0, 5)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = "Total Experience"
	xpLabel.TextColor3 = Color3.fromRGB(180, 150, 220)
	xpLabel.TextSize = 12
	xpLabel.Font = Enum.Font.Gotham
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.Parent = xpInfo
	
	local xpAmount = Instance.new("TextLabel")
	xpAmount.Name = "XPAmount"
	xpAmount.Size = UDim2.new(1, 0, 0, 28)
	xpAmount.Position = UDim2.new(0, 0, 0, 22)
	xpAmount.BackgroundTransparency = 1
	xpAmount.Text = string.format("%d XP", totalXP)
	xpAmount.TextColor3 = Color3.fromRGB(200, 180, 255)
	xpAmount.TextSize = 24
	xpAmount.Font = Enum.Font.GothamBold
	xpAmount.TextXAlignment = Enum.TextXAlignment.Left
	xpAmount.Parent = xpInfo
	
	-- XP tip
	local xpTip = Instance.new("TextLabel")
	xpTip.Name = "XPTip"
	xpTip.Size = UDim2.new(0, 160, 0, 30)
	xpTip.Position = UDim2.new(1, -170, 0.5, -15)
	xpTip.BackgroundTransparency = 1
	xpTip.Text = "Earn XP by capturing\nanimals and winning!"
	xpTip.TextColor3 = Color3.fromRGB(140, 120, 180)
	xpTip.TextSize = 10
	xpTip.Font = Enum.Font.Gotham
	xpTip.TextXAlignment = Enum.TextXAlignment.Right
	xpTip.Parent = xpCard
	
	return order + 1
end

-- Create Coins card
local function createCoinsCard(container: ScrollingFrame, cachedInventory: { Items: { [string]: any } }?, order: number): number
	-- Get coins from inventory
	local coins = 0
	if cachedInventory and cachedInventory.Items and cachedInventory.Items["COIN"] then
		local coinItem = cachedInventory.Items["COIN"]
		if type(coinItem) == "number" then
			coins = coinItem
		elseif type(coinItem) == "table" and coinItem.Quantity then
			coins = coinItem.Quantity
		end
	end
	
	local coinsCard = Instance.new("Frame")
	coinsCard.Name = "CoinsCard"
	coinsCard.Size = UDim2.new(1, -30, 0, 60)
	coinsCard.BackgroundColor3 = Color3.fromRGB(55, 50, 30)
	coinsCard.BorderSizePixel = 0
	coinsCard.LayoutOrder = order
	coinsCard.Parent = container
	
	local coinsCardCorner = Instance.new("UICorner")
	coinsCardCorner.CornerRadius = UDim.new(0, 10)
	coinsCardCorner.Parent = coinsCard
	
	-- Coin icon (gold circle with $ sign)
	local coinIcon = Instance.new("Frame")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 40, 0, 40)
	coinIcon.Position = UDim2.new(0, 15, 0.5, -20)
	coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	coinIcon.BorderSizePixel = 0
	coinIcon.Parent = coinsCard
	
	local coinIconCorner = Instance.new("UICorner")
	coinIconCorner.CornerRadius = UDim.new(1, 0)
	coinIconCorner.Parent = coinIcon
	
	local coinSymbol = Instance.new("TextLabel")
	coinSymbol.Size = UDim2.new(1, 0, 1, 0)
	coinSymbol.BackgroundTransparency = 1
	coinSymbol.Text = "$"
	coinSymbol.TextColor3 = Color3.fromRGB(150, 100, 0)
	coinSymbol.TextScaled = true
	coinSymbol.Font = Enum.Font.GothamBold
	coinSymbol.Parent = coinIcon
	
	-- Coins info container
	local coinsInfo = Instance.new("Frame")
	coinsInfo.Name = "CoinsInfo"
	coinsInfo.Size = UDim2.new(1, -90, 1, -10)
	coinsInfo.Position = UDim2.new(0, 70, 0, 5)
	coinsInfo.BackgroundTransparency = 1
	coinsInfo.Parent = coinsCard
	
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(1, 0, 0, 20)
	coinsLabel.Position = UDim2.new(0, 0, 0, 5)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "Coins Balance"
	coinsLabel.TextColor3 = Color3.fromRGB(200, 180, 100)
	coinsLabel.TextSize = 12
	coinsLabel.Font = Enum.Font.Gotham
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = coinsInfo
	
	local coinsAmount = Instance.new("TextLabel")
	coinsAmount.Name = "CoinsAmount"
	coinsAmount.Size = UDim2.new(1, 0, 0, 28)
	coinsAmount.Position = UDim2.new(0, 0, 0, 22)
	coinsAmount.BackgroundTransparency = 1
	coinsAmount.Text = string.format("%d", coins)
	coinsAmount.TextColor3 = Color3.fromRGB(255, 220, 100)
	coinsAmount.TextSize = 24
	coinsAmount.Font = Enum.Font.GothamBold
	coinsAmount.TextXAlignment = Enum.TextXAlignment.Left
	coinsAmount.Parent = coinsInfo
	
	-- Coins tip
	local coinsTip = Instance.new("TextLabel")
	coinsTip.Name = "CoinsTip"
	coinsTip.Size = UDim2.new(0, 160, 0, 30)
	coinsTip.Position = UDim2.new(1, -170, 0.5, -15)
	coinsTip.BackgroundTransparency = 1
	coinsTip.Text = "Earn coins by capturing\nanimals and winning games!"
	coinsTip.TextColor3 = Color3.fromRGB(150, 140, 100)
	coinsTip.TextSize = 10
	coinsTip.Font = Enum.Font.Gotham
	coinsTip.TextXAlignment = Enum.TextXAlignment.Right
	coinsTip.Parent = coinsCard
	
	return order + 1
end

-- Create Next Reward card
local function createRewardCard(container: ScrollingFrame, currentLevel: number, order: number): number
	local rewardName, rewardItems, rewardLevel = getNextLevelReward(currentLevel)
	
	if rewardName then
		local rewardCard = Instance.new("Frame")
		rewardCard.Name = "RewardCard"
		rewardCard.Size = UDim2.new(1, -30, 0, 60)
		rewardCard.BackgroundColor3 = Color3.fromRGB(50, 45, 30)
		rewardCard.BorderSizePixel = 0
		rewardCard.LayoutOrder = order
		rewardCard.Parent = container
		
		local rewardCardCorner = Instance.new("UICorner")
		rewardCardCorner.CornerRadius = UDim.new(0, 8)
		rewardCardCorner.Parent = rewardCard
		
		local giftIcon = Instance.new("TextLabel")
		giftIcon.Name = "GiftIcon"
		giftIcon.Size = UDim2.new(0, 45, 0, 45)
		giftIcon.Position = UDim2.new(0, 12, 0.5, -22)
		giftIcon.BackgroundTransparency = 1
		giftIcon.Text = "🎁"
		giftIcon.TextSize = 32
		giftIcon.Font = Enum.Font.GothamBold
		giftIcon.Parent = rewardCard
		
		local rewardTitle = Instance.new("TextLabel")
		rewardTitle.Name = "RewardTitle"
		rewardTitle.Size = UDim2.new(1, -75, 0, 20)
		rewardTitle.Position = UDim2.new(0, 65, 0, 10)
		rewardTitle.BackgroundTransparency = 1
		rewardTitle.Text = string.format("Next Reward at Level %d: %s", rewardLevel, rewardName)
		rewardTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
		rewardTitle.TextSize = 14
		rewardTitle.Font = Enum.Font.GothamBold
		rewardTitle.TextXAlignment = Enum.TextXAlignment.Left
		rewardTitle.Parent = rewardCard
		
		local rewardDesc = Instance.new("TextLabel")
		rewardDesc.Name = "RewardDesc"
		rewardDesc.Size = UDim2.new(1, -75, 0, 18)
		rewardDesc.Position = UDim2.new(0, 65, 0, 32)
		rewardDesc.BackgroundTransparency = 1
		rewardDesc.Text = "🎖️ " .. rewardItems
		rewardDesc.TextColor3 = Color3.fromRGB(180, 180, 150)
		rewardDesc.TextSize = 12
		rewardDesc.Font = Enum.Font.Gotham
		rewardDesc.TextXAlignment = Enum.TextXAlignment.Left
		rewardDesc.Parent = rewardCard
	else
		local maxedCard = Instance.new("Frame")
		maxedCard.Name = "MaxedCard"
		maxedCard.Size = UDim2.new(1, -30, 0, 45)
		maxedCard.BackgroundColor3 = Color3.fromRGB(40, 55, 40)
		maxedCard.BorderSizePixel = 0
		maxedCard.LayoutOrder = order
		maxedCard.Parent = container
		
		local maxedCardCorner = Instance.new("UICorner")
		maxedCardCorner.CornerRadius = UDim.new(0, 8)
		maxedCardCorner.Parent = maxedCard
		
		local maxedText = Instance.new("TextLabel")
		maxedText.Size = UDim2.new(1, 0, 1, 0)
		maxedText.BackgroundTransparency = 1
		maxedText.Text = "⭐ All level rewards claimed! You're a true veteran!"
		maxedText.TextColor3 = Color3.fromRGB(150, 220, 150)
		maxedText.TextSize = 14
		maxedText.Font = Enum.Font.GothamBold
		maxedText.Parent = maxedCard
	end
	
	return order + 1
end

-- Create Game Statistics section
local function createGameStats(container: ScrollingFrame, cachedStats: any, order: number): number
	-- Spacer
	local spacer1 = Instance.new("Frame")
	spacer1.Size = UDim2.new(1, 0, 0, 15)
	spacer1.BackgroundTransparency = 1
	spacer1.LayoutOrder = order
	spacer1.Parent = container
	order += 1
	
	-- Header
	local gameHeader = Instance.new("TextLabel")
	gameHeader.Name = "GameHeader"
	gameHeader.Size = UDim2.new(1, -30, 0, 24)
	gameHeader.BackgroundTransparency = 1
	gameHeader.Text = "🎮 Game Statistics"
	gameHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
	gameHeader.TextSize = 16
	gameHeader.Font = Enum.Font.GothamBold
	gameHeader.TextXAlignment = Enum.TextXAlignment.Left
	gameHeader.LayoutOrder = order
	gameHeader.Parent = container
	order += 1
	
	-- Stats card
	local statsCard = Instance.new("Frame")
	statsCard.Name = "StatsCard"
	statsCard.Size = UDim2.new(1, -30, 0, 140)
	statsCard.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
	statsCard.BorderSizePixel = 0
	statsCard.LayoutOrder = order
	statsCard.Parent = container
	
	local statsCardCorner = Instance.new("UICorner")
	statsCardCorner.CornerRadius = UDim.new(0, 8)
	statsCardCorner.Parent = statsCard
	
	local statsPadding = Instance.new("UIPadding")
	statsPadding.PaddingLeft = UDim.new(0, 15)
	statsPadding.PaddingTop = UDim.new(0, 10)
	statsPadding.PaddingRight = UDim.new(0, 15)
	statsPadding.Parent = statsCard
	
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.Padding = UDim.new(0, 6)
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Parent = statsCard
	
	UIHelpers.createStatRow("Total Captures", cachedStats.TotalCaptures or 0, 1).Parent = statsCard
	UIHelpers.createStatRow("Total Wins", cachedStats.TotalWins or 0, 2).Parent = statsCard
	UIHelpers.createStatRow("Total Losses", cachedStats.TotalLosses or 0, 3).Parent = statsCard
	UIHelpers.createStatRow("Games Played", cachedStats.TotalGamesPlayed or 0, 4).Parent = statsCard
	
	-- Win rate
	local gamesPlayed = cachedStats.TotalGamesPlayed or 0
	local wins = cachedStats.TotalWins or 0
	local winRate = if gamesPlayed > 0 then math.floor((wins / gamesPlayed) * 100) else 0
	UIHelpers.createStatRow("Win Rate", winRate .. "%", 5).Parent = statsCard
	
	return order + 1
end

-- Create XP earning tips
local function createXPTips(container: ScrollingFrame, order: number): number
	-- Spacer
	local spacer2 = Instance.new("Frame")
	spacer2.Size = UDim2.new(1, 0, 0, 15)
	spacer2.BackgroundTransparency = 1
	spacer2.LayoutOrder = order
	spacer2.Parent = container
	order += 1
	
	-- Header
	local tipsHeader = Instance.new("TextLabel")
	tipsHeader.Name = "TipsHeader"
	tipsHeader.Size = UDim2.new(1, -30, 0, 24)
	tipsHeader.BackgroundTransparency = 1
	tipsHeader.Text = "💡 How to Earn XP & Coins"
	tipsHeader.TextColor3 = Color3.fromRGB(200, 180, 100)
	tipsHeader.TextSize = 16
	tipsHeader.Font = Enum.Font.GothamBold
	tipsHeader.TextXAlignment = Enum.TextXAlignment.Left
	tipsHeader.LayoutOrder = order
	tipsHeader.Parent = container
	order += 1
	
	local tips = {
		{ icon = "🦎", text = "Capture animals to earn XP based on their rarity", xp = "+5-50 XP" },
		{ icon = "🏆", text = "Win games to earn bonus XP", xp = "+100 XP" },
		{ icon = "🎯", text = "Complete achievements for XP rewards", xp = "Varies" },
		{ icon = "🪙", text = "Earn coins from captures and wins", xp = "+Coins" },
	}
	
	for _, tip in tips do
		local tipCard = Instance.new("Frame")
		tipCard.Name = "TipCard"
		tipCard.Size = UDim2.new(1, -30, 0, 35)
		tipCard.BackgroundColor3 = Color3.fromRGB(45, 45, 40)
		tipCard.BorderSizePixel = 0
		tipCard.LayoutOrder = order
		tipCard.Parent = container
		
		local tipCorner = Instance.new("UICorner")
		tipCorner.CornerRadius = UDim.new(0, 6)
		tipCorner.Parent = tipCard
		
		local tipIcon = Instance.new("TextLabel")
		tipIcon.Size = UDim2.new(0, 30, 1, 0)
		tipIcon.Position = UDim2.new(0, 8, 0, 0)
		tipIcon.BackgroundTransparency = 1
		tipIcon.Text = tip.icon
		tipIcon.TextSize = 18
		tipIcon.Font = Enum.Font.GothamBold
		tipIcon.Parent = tipCard
		
		local tipText = Instance.new("TextLabel")
		tipText.Size = UDim2.new(1, -110, 1, 0)
		tipText.Position = UDim2.new(0, 42, 0, 0)
		tipText.BackgroundTransparency = 1
		tipText.Text = tip.text
		tipText.TextColor3 = Color3.fromRGB(180, 180, 180)
		tipText.TextSize = 11
		tipText.Font = Enum.Font.Gotham
		tipText.TextXAlignment = Enum.TextXAlignment.Left
		tipText.Parent = tipCard
		
		local tipXP = Instance.new("TextLabel")
		tipXP.Size = UDim2.new(0, 60, 1, 0)
		tipXP.Position = UDim2.new(1, -68, 0, 0)
		tipXP.BackgroundTransparency = 1
		tipXP.Text = tip.xp
		tipXP.TextColor3 = Color3.fromRGB(150, 220, 150)
		tipXP.TextSize = 11
		tipXP.Font = Enum.Font.GothamBold
		tipXP.TextXAlignment = Enum.TextXAlignment.Right
		tipXP.Parent = tipCard
		
		order += 1
	end
	
	return order
end

-- Main populate function
export type StatsTabData = {
	cachedStats: any,
	cachedFavoriteAnimals: { string },
	canModifyFavorites: boolean,
	menuGui: ScreenGui?,
	cachedInventory: { Items: { [string]: any } }?,
}

function StatsTab.populate(container: ScrollingFrame, data: StatsTabData)
	if not container then return end
	
	UIHelpers.clearContainer(container)
	
	if not data.cachedStats then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No stats available"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = container
		return
	end
	
	local order = 0
	
	-- Level & XP Card (enhanced)
	order = createLevelCard(container, data.cachedStats, order)
	
	-- Total XP Card (new prominent display)
	order = createTotalXPCard(container, data.cachedStats, order)
	
	-- Coins Card (gets coins from inventory)
	order = createCoinsCard(container, data.cachedInventory, order)
	
	-- Next Reward Card
	local currentLevel = data.cachedStats.Level or 1
	order = createRewardCard(container, currentLevel, order)
	
	-- Game Statistics
	order = createGameStats(container, data.cachedStats, order)
	
	-- XP & Coins earning tips
	order = createXPTips(container, order)
	
	-- Add bottom padding
	local bottomSpacer = Instance.new("Frame")
	bottomSpacer.Name = "BottomSpacer"
	bottomSpacer.Size = UDim2.new(1, 0, 0, 40)
	bottomSpacer.BackgroundTransparency = 1
	bottomSpacer.LayoutOrder = order
	bottomSpacer.Parent = container
	
	-- Update canvas size
	container.CanvasSize = UDim2.new(0, 0, 0, 620)
end

return StatsTab
