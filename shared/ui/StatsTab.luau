--!strict
-- StatsTab.luau
-- Stats tab UI for PlayerMenu (Level, XP, Game Stats, Favorites, Animal Collection)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local AnimalLibraryModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AnimalLibraryModule"))
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

-- Create Level & XP card
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
	levelNumber.Size = UDim2.new(1, 0, 0.7, 0)
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
	progressBg.Size = UDim2.new(1, 0, 0, 16)
	progressBg.Position = UDim2.new(0, 0, 0, 22)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = xpContainer
	
	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 8)
	progressBgCorner.Parent = progressBg
	
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(progressToNext, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	
	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 8)
	progressFillCorner.Parent = progressFill
	
	-- Gradient on progress bar
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 150, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255)),
	})
	gradient.Parent = progressFill
	
	-- XP text
	local xpText = Instance.new("TextLabel")
	xpText.Name = "XPText"
	xpText.Size = UDim2.new(1, 0, 0, 16)
	xpText.Position = UDim2.new(0, 0, 0, 42)
	xpText.BackgroundTransparency = 1
	xpText.Text = string.format("%d / %d XP to Level %d", xpInCurrentLevel, xpNeededForNext, currentLevel + 1)
	xpText.TextColor3 = Color3.fromRGB(150, 200, 255)
	xpText.TextSize = 12
	xpText.Font = Enum.Font.Gotham
	xpText.TextXAlignment = Enum.TextXAlignment.Left
	xpText.Parent = xpContainer
	
	-- Total XP badge
	local totalXPBadge = Instance.new("Frame")
	totalXPBadge.Name = "TotalXPBadge"
	totalXPBadge.Size = UDim2.new(0, 120, 0, 22)
	totalXPBadge.Position = UDim2.new(0, 0, 0, 58)
	totalXPBadge.BackgroundColor3 = Color3.fromRGB(60, 50, 80)
	totalXPBadge.BorderSizePixel = 0
	totalXPBadge.Parent = xpContainer
	
	local totalXPBadgeCorner = Instance.new("UICorner")
	totalXPBadgeCorner.CornerRadius = UDim.new(0, 6)
	totalXPBadgeCorner.Parent = totalXPBadge
	
	local totalXPText = Instance.new("TextLabel")
	totalXPText.Name = "TotalXP"
	totalXPText.Size = UDim2.new(1, 0, 1, 0)
	totalXPText.BackgroundTransparency = 1
	totalXPText.Text = string.format("⭐ Total: %d XP", totalXP)
	totalXPText.TextColor3 = Color3.fromRGB(220, 180, 255)
	totalXPText.TextSize = 12
	totalXPText.Font = Enum.Font.GothamBold
	totalXPText.Parent = totalXPBadge
	
	return order + 1
end

-- Create Next Reward card
local function createRewardCard(container: ScrollingFrame, currentLevel: number, order: number): number
	local rewardName, rewardItems, rewardLevel = getNextLevelReward(currentLevel)
	
	if rewardName then
		local rewardCard = Instance.new("Frame")
		rewardCard.Name = "RewardCard"
		rewardCard.Size = UDim2.new(1, -30, 0, 55)
		rewardCard.BackgroundColor3 = Color3.fromRGB(50, 45, 30)
		rewardCard.BorderSizePixel = 0
		rewardCard.LayoutOrder = order
		rewardCard.Parent = container
		
		local rewardCardCorner = Instance.new("UICorner")
		rewardCardCorner.CornerRadius = UDim.new(0, 8)
		rewardCardCorner.Parent = rewardCard
		
		local giftIcon = Instance.new("TextLabel")
		giftIcon.Name = "GiftIcon"
		giftIcon.Size = UDim2.new(0, 40, 0, 40)
		giftIcon.Position = UDim2.new(0, 10, 0.5, -20)
		giftIcon.BackgroundTransparency = 1
		giftIcon.Text = "🎁"
		giftIcon.TextSize = 28
		giftIcon.Font = Enum.Font.GothamBold
		giftIcon.Parent = rewardCard
		
		local rewardTitle = Instance.new("TextLabel")
		rewardTitle.Name = "RewardTitle"
		rewardTitle.Size = UDim2.new(1, -60, 0, 18)
		rewardTitle.Position = UDim2.new(0, 55, 0, 8)
		rewardTitle.BackgroundTransparency = 1
		rewardTitle.Text = string.format("Next Reward at Level %d: %s", rewardLevel, rewardName)
		rewardTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
		rewardTitle.TextSize = 13
		rewardTitle.Font = Enum.Font.GothamBold
		rewardTitle.TextXAlignment = Enum.TextXAlignment.Left
		rewardTitle.Parent = rewardCard
		
		local rewardDesc = Instance.new("TextLabel")
		rewardDesc.Name = "RewardDesc"
		rewardDesc.Size = UDim2.new(1, -60, 0, 16)
		rewardDesc.Position = UDim2.new(0, 55, 0, 28)
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
		maxedCard.Size = UDim2.new(1, -30, 0, 40)
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
		maxedText.Text = "⭐ All level rewards claimed!"
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
	spacer1.Size = UDim2.new(1, 0, 0, 10)
	spacer1.BackgroundTransparency = 1
	spacer1.LayoutOrder = order
	spacer1.Parent = container
	order += 1
	
	-- Header
	local gameHeader = Instance.new("TextLabel")
	gameHeader.Name = "GameHeader"
	gameHeader.Size = UDim2.new(1, -30, 0, 20)
	gameHeader.BackgroundTransparency = 1
	gameHeader.Text = "🎮 Game Statistics"
	gameHeader.TextColor3 = Color3.fromRGB(100, 200, 255)
	gameHeader.TextSize = 14
	gameHeader.Font = Enum.Font.GothamBold
	gameHeader.TextXAlignment = Enum.TextXAlignment.Left
	gameHeader.LayoutOrder = order
	gameHeader.Parent = container
	order += 1
	
	UIHelpers.createStatRow("Total Captures", cachedStats.TotalCaptures or 0, order).Parent = container
	order += 1
	UIHelpers.createStatRow("Total Wins", cachedStats.TotalWins or 0, order).Parent = container
	order += 1
	UIHelpers.createStatRow("Total Losses", cachedStats.TotalLosses or 0, order).Parent = container
	order += 1
	UIHelpers.createStatRow("Games Played", cachedStats.TotalGamesPlayed or 0, order).Parent = container
	order += 1
	
	-- Win rate
	local gamesPlayed = cachedStats.TotalGamesPlayed or 0
	local wins = cachedStats.TotalWins or 0
	local winRate = if gamesPlayed > 0 then math.floor((wins / gamesPlayed) * 100) else 0
	UIHelpers.createStatRow("Win Rate", winRate .. "%", order).Parent = container
	order += 1
	
	return order
end

-- Create Favorite Animals section
local function createFavoritesSection(container: ScrollingFrame, cachedFavoriteAnimals: { string }, canModifyFavorites: boolean, order: number): number
	-- Spacer
	local spacer2 = Instance.new("Frame")
	spacer2.Size = UDim2.new(1, 0, 0, 10)
	spacer2.BackgroundTransparency = 1
	spacer2.LayoutOrder = order
	spacer2.Parent = container
	order += 1
	
	-- Header
	local favoritesHeader = Instance.new("TextLabel")
	favoritesHeader.Name = "FavoritesHeader"
	favoritesHeader.Size = UDim2.new(1, -30, 0, 20)
	favoritesHeader.BackgroundTransparency = 1
	favoritesHeader.Text = "⭐ Favorite Animals (" .. #cachedFavoriteAnimals .. "/2)"
	favoritesHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
	favoritesHeader.TextSize = 14
	favoritesHeader.Font = Enum.Font.GothamBold
	favoritesHeader.TextXAlignment = Enum.TextXAlignment.Left
	favoritesHeader.LayoutOrder = order
	favoritesHeader.Parent = container
	order += 1
	
	-- Show favorite animals or empty state
	if #cachedFavoriteAnimals > 0 then
		for _, animalID in cachedFavoriteAnimals do
			local animalDef = AnimalLibraryModule.GetByID(animalID)
			if animalDef then
				local favCard = Instance.new("Frame")
				favCard.Name = animalID .. "FavCard"
				favCard.Size = UDim2.new(1, -30, 0, 45)
				favCard.BackgroundColor3 = Color3.fromRGB(60, 55, 35)
				favCard.BorderSizePixel = 0
				favCard.LayoutOrder = order
				favCard.Parent = container
				
				local favCardCorner = Instance.new("UICorner")
				favCardCorner.CornerRadius = UDim.new(0, 8)
				favCardCorner.Parent = favCard
				
				-- Color badge
				local color = animalDef.Color
				if typeof(color) == "BrickColor" then
					color = color.Color
				end
				
				local favColorBadge = Instance.new("Frame")
				favColorBadge.Name = "ColorBadge"
				favColorBadge.Size = UDim2.new(0, 35, 0, 35)
				favColorBadge.Position = UDim2.new(0, 8, 0.5, -17)
				favColorBadge.BackgroundColor3 = color
				favColorBadge.BorderSizePixel = 0
				favColorBadge.Parent = favCard
				
				local favBadgeCorner = Instance.new("UICorner")
				favBadgeCorner.CornerRadius = UDim.new(0, 6)
				favBadgeCorner.Parent = favColorBadge
				
				-- Star icon inside badge
				local starIcon = Instance.new("TextLabel")
				starIcon.Name = "Star"
				starIcon.Size = UDim2.new(1, 0, 1, 0)
				starIcon.BackgroundTransparency = 1
				starIcon.Text = "★"
				starIcon.TextColor3 = Color3.fromRGB(50, 40, 20)
				starIcon.TextSize = 18
				starIcon.Font = Enum.Font.GothamBold
				starIcon.Parent = favColorBadge
				
				-- Name
				local favNameLabel = Instance.new("TextLabel")
				favNameLabel.Name = "Name"
				favNameLabel.Size = UDim2.new(0.5, -50, 0, 20)
				favNameLabel.Position = UDim2.new(0, 50, 0, 5)
				favNameLabel.BackgroundTransparency = 1
				favNameLabel.Text = animalDef.Name
				favNameLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
				favNameLabel.TextSize = 14
				favNameLabel.Font = Enum.Font.GothamBold
				favNameLabel.TextXAlignment = Enum.TextXAlignment.Left
				favNameLabel.Parent = favCard
				
				-- Rarity
				local rarity = AnimalLibraryModule.GetRarity(animalDef.SpawnChance)
				local favRarityLabel = Instance.new("TextLabel")
				favRarityLabel.Name = "Rarity"
				favRarityLabel.Size = UDim2.new(0.5, -50, 0, 14)
				favRarityLabel.Position = UDim2.new(0, 50, 0, 26)
				favRarityLabel.BackgroundTransparency = 1
				favRarityLabel.Text = rarity .. " • " .. animalDef.PointValue .. " pts"
				favRarityLabel.TextColor3 = Color3.fromRGB(180, 160, 120)
				favRarityLabel.TextSize = 11
				favRarityLabel.Font = Enum.Font.Gotham
				favRarityLabel.TextXAlignment = Enum.TextXAlignment.Left
				favRarityLabel.Parent = favCard
				
				-- Unfavorite button
				local unfavButton = UIHelpers.createTextButton(
					"UnfavoriteButton",
					"✕ Remove",
					UDim2.new(0, 70, 0, 24),
					UDim2.new(1, -80, 0.5, -12),
					Color3.fromRGB(120, 60, 50),
					favCard
				)
				unfavButton.TextSize = 10
				
				local capturedAnimalID = animalID
				unfavButton.MouseButton1Click:Connect(function()
					Log.Info(CONTEXT, string.format("Quick unfavorite: %s", capturedAnimalID))
					RemoteEvents.SetFavoriteAnimalEvent:FireServer(capturedAnimalID)
				end)
				
				order += 1
			end
		end
	else
		local emptyFavLabel = Instance.new("TextLabel")
		emptyFavLabel.Name = "EmptyFavorites"
		emptyFavLabel.Size = UDim2.new(1, -30, 0, 35)
		emptyFavLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		emptyFavLabel.Text = "No favorite animals yet. Select from your captured animals below!"
		emptyFavLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		emptyFavLabel.TextSize = 11
		emptyFavLabel.Font = Enum.Font.Gotham
		emptyFavLabel.LayoutOrder = order
		emptyFavLabel.Parent = container
		
		local emptyCorner = Instance.new("UICorner")
		emptyCorner.CornerRadius = UDim.new(0, 6)
		emptyCorner.Parent = emptyFavLabel
		
		order += 1
	end
	
	-- Status indicator for whether favorites can be changed
	if not canModifyFavorites then
		local lockedNote = Instance.new("TextLabel")
		lockedNote.Name = "LockedNote"
		lockedNote.Size = UDim2.new(1, -30, 0, 22)
		lockedNote.BackgroundColor3 = Color3.fromRGB(80, 60, 40)
		lockedNote.Text = "⚠️ Favorites locked during active game"
		lockedNote.TextColor3 = Color3.fromRGB(255, 200, 100)
		lockedNote.TextSize = 11
		lockedNote.Font = Enum.Font.GothamBold
		lockedNote.LayoutOrder = order
		lockedNote.Parent = container
		
		local lockedCorner = Instance.new("UICorner")
		lockedCorner.CornerRadius = UDim.new(0, 4)
		lockedCorner.Parent = lockedNote
		
		order += 1
	end
	
	return order
end

-- Create Animal Collection section
local function createAnimalCollection(container: ScrollingFrame, cachedStats: any, cachedFavoriteAnimals: { string }, canModifyFavorites: boolean, menuGui: ScreenGui?, order: number): number
	-- Spacer before collection
	local spacer3 = Instance.new("Frame")
	spacer3.Size = UDim2.new(1, 0, 0, 15)
	spacer3.BackgroundTransparency = 1
	spacer3.LayoutOrder = order
	spacer3.Parent = container
	order += 1
	
	-- Collection Header
	local collectionHeader = Instance.new("TextLabel")
	collectionHeader.Name = "CollectionHeader"
	collectionHeader.Size = UDim2.new(1, -30, 0, 20)
	collectionHeader.BackgroundTransparency = 1
	collectionHeader.Text = "🦎 Animal Collection"
	collectionHeader.TextColor3 = Color3.fromRGB(200, 150, 255)
	collectionHeader.TextSize = 14
	collectionHeader.Font = Enum.Font.GothamBold
	collectionHeader.TextXAlignment = Enum.TextXAlignment.Left
	collectionHeader.LayoutOrder = order
	collectionHeader.Parent = container
	order += 1
	
	local capturedIndex = cachedStats.CapturedAnimalIndex or {}
	local animalCaptureCount = cachedStats.AnimalCaptureCount or {}
	local capturedCount = 0
	for _ in capturedIndex do
		capturedCount += 1
	end
	
	local totalAnimalCount = AnimalLibraryModule.GetTotalCount()
	
	-- Summary row
	UIHelpers.createStatRow("Unique Animals Discovered", capturedCount .. "/" .. totalAnimalCount, order).Parent = container
	order += 1
	
	-- Build animalData from AnimalLibraryModule
	local animalData = {}
	for _, libraryAnimal in AnimalLibraryModule.List do
		local color = libraryAnimal.Color
		if typeof(color) == "BrickColor" then
			color = color.Color
		end
		
		local rarity = AnimalLibraryModule.GetRarity(libraryAnimal.SpawnChance)
		
		table.insert(animalData, {
			ID = libraryAnimal.ID,
			Name = libraryAnimal.Name,
			Color = color,
			PointValue = libraryAnimal.PointValue,
			Rarity = rarity,
			Description = libraryAnimal.Description,
		})
	end
	
	-- Create animal cards
	for _, animal in animalData do
		local isCaptured = capturedIndex[animal.ID] == true
		local timesCaptured = animalCaptureCount[animal.ID] or 0
		local isFavorite = table.find(cachedFavoriteAnimals, animal.ID) ~= nil
		
		local animalCard = Instance.new("Frame")
		animalCard.Name = animal.ID .. "Card"
		animalCard.Size = UDim2.new(1, -30, 0, 70)
		local cardBgColor = if not isCaptured then Color3.fromRGB(35, 35, 40)
			elseif isFavorite then Color3.fromRGB(55, 50, 35)
			else Color3.fromRGB(40, 50, 45)
		animalCard.BackgroundColor3 = cardBgColor
		animalCard.BorderSizePixel = 0
		animalCard.LayoutOrder = order
		animalCard.Parent = container
		
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = animalCard
		
		-- Favorite star indicator
		if isFavorite then
			local favStar = Instance.new("TextLabel")
			favStar.Name = "FavoriteStar"
			favStar.Size = UDim2.new(0, 24, 0, 24)
			favStar.Position = UDim2.new(1, -28, 0, 4)
			favStar.BackgroundTransparency = 1
			favStar.Text = "⭐"
			favStar.TextSize = 16
			favStar.Font = Enum.Font.GothamBold
			favStar.Parent = animalCard
		end
		
		-- Left color indicator
		local colorBadge = Instance.new("Frame")
		colorBadge.Name = "ColorBadge"
		colorBadge.Size = UDim2.new(0, 50, 0, 50)
		colorBadge.Position = UDim2.new(0, 10, 0.5, -25)
		colorBadge.BackgroundColor3 = if isCaptured then animal.Color else Color3.fromRGB(60, 60, 60)
		colorBadge.BorderSizePixel = 0
		colorBadge.Parent = animalCard
		
		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 8)
		badgeCorner.Parent = colorBadge
		
		-- Question mark or check
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "Status"
		statusLabel.Size = UDim2.new(1, 0, 1, 0)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = if isCaptured then "✓" else "?"
		statusLabel.TextColor3 = if isCaptured then Color3.fromRGB(50, 50, 50) else Color3.fromRGB(100, 100, 100)
		statusLabel.TextSize = 28
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.Parent = colorBadge
		
		-- Animal name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.5, -70, 0, 20)
		nameLabel.Position = UDim2.new(0, 70, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if isCaptured then animal.Name else "???"
		nameLabel.TextColor3 = if isCaptured then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(120, 120, 120)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = animalCard
		
		-- Rarity badge
		local rarityBadge = Instance.new("TextLabel")
		rarityBadge.Name = "Rarity"
		rarityBadge.Size = UDim2.new(0, 75, 0, 16)
		rarityBadge.Position = UDim2.new(0, 70, 0, 28)
		rarityBadge.BackgroundColor3 = if isCaptured then (UIHelpers.RARITY_COLORS[animal.Rarity] or Color3.fromRGB(100, 100, 100)) else Color3.fromRGB(60, 60, 60)
		rarityBadge.Text = if isCaptured then animal.Rarity else "Unknown"
		rarityBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		rarityBadge.TextSize = 10
		rarityBadge.Font = Enum.Font.GothamBold
		rarityBadge.Parent = animalCard
		
		local rarityCorner = Instance.new("UICorner")
		rarityCorner.CornerRadius = UDim.new(0, 4)
		rarityCorner.Parent = rarityBadge
		
		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(0.5, -70, 0, 14)
		descLabel.Position = UDim2.new(0, 70, 0, 48)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = if isCaptured then animal.Description else "Capture to discover"
		descLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		descLabel.TextSize = 11
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = animalCard
		
		-- Right side stats
		local statsFrame = Instance.new("Frame")
		statsFrame.Name = "StatsFrame"
		statsFrame.Size = UDim2.new(0.4, 0, 1, -10)
		statsFrame.Position = UDim2.new(0.6, 0, 0, 5)
		statsFrame.BackgroundTransparency = 1
		statsFrame.Parent = animalCard
		
		-- Points value
		local pointsLabel = Instance.new("TextLabel")
		pointsLabel.Name = "Points"
		pointsLabel.Size = UDim2.new(1, 0, 0, 18)
		pointsLabel.Position = UDim2.new(0, 0, 0, 5)
		pointsLabel.BackgroundTransparency = 1
		pointsLabel.Text = if isCaptured then "⭐ " .. animal.PointValue .. " pts" else "⭐ ?"
		pointsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		pointsLabel.TextSize = 13
		pointsLabel.Font = Enum.Font.GothamBold
		pointsLabel.TextXAlignment = Enum.TextXAlignment.Right
		pointsLabel.Parent = statsFrame
		
		-- Times captured
		local capturedLabel = Instance.new("TextLabel")
		capturedLabel.Name = "Captured"
		capturedLabel.Size = UDim2.new(1, 0, 0, 16)
		capturedLabel.Position = UDim2.new(0, 0, 0, 26)
		capturedLabel.BackgroundTransparency = 1
		capturedLabel.Text = if isCaptured then "Captured: " .. timesCaptured .. "x" else "Not discovered"
		capturedLabel.TextColor3 = if isCaptured then Color3.fromRGB(150, 220, 150) else Color3.fromRGB(100, 100, 100)
		capturedLabel.TextSize = 11
		capturedLabel.Font = Enum.Font.Gotham
		capturedLabel.TextXAlignment = Enum.TextXAlignment.Right
		capturedLabel.Parent = statsFrame
		
		-- Discovery status icon
		local discoveryIcon = Instance.new("TextLabel")
		discoveryIcon.Name = "DiscoveryIcon"
		discoveryIcon.Size = UDim2.new(1, 0, 0, 18)
		discoveryIcon.Position = UDim2.new(0, 0, 0, 44)
		discoveryIcon.BackgroundTransparency = 1
		discoveryIcon.Text = if isCaptured then "✅ Discovered" else "🔒 Locked"
		discoveryIcon.TextColor3 = if isCaptured then Color3.fromRGB(100, 200, 100) else Color3.fromRGB(100, 100, 100)
		discoveryIcon.TextSize = 11
		discoveryIcon.Font = Enum.Font.GothamBold
		discoveryIcon.TextXAlignment = Enum.TextXAlignment.Right
		discoveryIcon.Parent = statsFrame
		
		-- Favorite button (only for captured animals)
		if isCaptured then
			local favoriteButton = UIHelpers.createTextButton(
				"FavoriteButton",
				if isFavorite then "★ Unfavorite" else "☆ Favorite",
				UDim2.new(0, 80, 0, 22),
				UDim2.new(0, 70, 0, 46),
				if isFavorite then Color3.fromRGB(180, 140, 50) else Color3.fromRGB(70, 70, 80),
				animalCard
			)
			favoriteButton.TextSize = 10
			
			-- Show disabled state if can't modify
			if not canModifyFavorites then
				favoriteButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				favoriteButton.TextColor3 = Color3.fromRGB(120, 120, 120)
			end
			
			-- Capture values for closure
			local capturedAnimalID = animal.ID
			local capturedIsFavorite = isFavorite
			
			favoriteButton.MouseButton1Click:Connect(function()
				if not canModifyFavorites then
					Log.Info(CONTEXT, "Cannot change favorites during an active game")
					if menuGui then
						UIHelpers.showToast(menuGui, "⚠️ Cannot change favorites during a game", Color3.fromRGB(150, 100, 50), 2)
					end
					return
				end
				
				-- Check if trying to add a 3rd favorite
				if not capturedIsFavorite and #cachedFavoriteAnimals >= 2 then
					Log.Info(CONTEXT, "Maximum 2 favorites allowed")
					if menuGui then
						UIHelpers.showToast(menuGui, "⚠️ You can only have 2 favorites. Remove one first.", Color3.fromRGB(150, 80, 50), 2.5)
					end
					return
				end
				
				-- Send request to server
				Log.Info(CONTEXT, string.format("Toggling favorite for %s", capturedAnimalID))
				RemoteEvents.SetFavoriteAnimalEvent:FireServer(capturedAnimalID)
			end)
		end
		
		order += 1
	end
	
	-- Add bottom padding
	local bottomSpacer = Instance.new("Frame")
	bottomSpacer.Name = "BottomSpacer"
	bottomSpacer.Size = UDim2.new(1, 0, 0, 40)
	bottomSpacer.BackgroundTransparency = 1
	bottomSpacer.LayoutOrder = order
	bottomSpacer.Parent = container
	
	return order + 1
end

-- Main populate function
export type StatsTabData = {
	cachedStats: any,
	cachedFavoriteAnimals: { string },
	canModifyFavorites: boolean,
	menuGui: ScreenGui?,
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
	
	-- Level & XP Card
	order = createLevelCard(container, data.cachedStats, order)
	
	-- Next Reward Card
	local currentLevel = data.cachedStats.Level or 1
	order = createRewardCard(container, currentLevel, order)
	
	-- Game Statistics
	order = createGameStats(container, data.cachedStats, order)
	
	-- Favorite Animals section
	order = createFavoritesSection(container, data.cachedFavoriteAnimals, data.canModifyFavorites, order)
	
	-- Animal Collection
	order = createAnimalCollection(container, data.cachedStats, data.cachedFavoriteAnimals, data.canModifyFavorites, data.menuGui, order)
	
	-- Update canvas size
	local animalCount = AnimalLibraryModule.GetTotalCount()
	local baseHeight = 500
	local animalCardsHeight = animalCount * 80
	local totalHeight = baseHeight + animalCardsHeight + 100
	container.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

return StatsTab
