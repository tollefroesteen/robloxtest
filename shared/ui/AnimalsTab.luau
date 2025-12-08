--!strict
-- AnimalsTab.luau
-- Animals tab UI for PlayerMenu (Favorite Animals, Animal Collection)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local AnimalLibraryModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AnimalLibraryModule"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local AnimalPreviewBuilder = require(script.Parent:WaitForChild("AnimalPreviewBuilder"))

local CONTEXT = "AnimalsTab"

local AnimalsTab = {}

-- Create Favorite Animals section
local function createFavoritesSection(container: ScrollingFrame, cachedFavoriteAnimals: { string }, canModifyFavorites: boolean, menuGui: ScreenGui?, order: number): number
	-- Header
	local favoritesHeader = Instance.new("TextLabel")
	favoritesHeader.Name = "FavoritesHeader"
	favoritesHeader.Size = UDim2.new(1, -30, 0, 24)
	favoritesHeader.BackgroundTransparency = 1
	favoritesHeader.Text = "⭐ Favorite Animals (" .. #cachedFavoriteAnimals .. "/3)"
	favoritesHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
	favoritesHeader.TextSize = 16
	favoritesHeader.Font = Enum.Font.GothamBold
	favoritesHeader.TextXAlignment = Enum.TextXAlignment.Left
	favoritesHeader.LayoutOrder = order
	favoritesHeader.Parent = container
	order += 1
	
	-- Description
	local favDesc = Instance.new("TextLabel")
	favDesc.Name = "FavoritesDescription"
	favDesc.Size = UDim2.new(1, -30, 0, 18)
	favDesc.BackgroundTransparency = 1
	favDesc.Text = "Your favorite animals will spawn as your pets in the lobby!"
	favDesc.TextColor3 = Color3.fromRGB(160, 160, 160)
	favDesc.TextSize = 11
	favDesc.Font = Enum.Font.Gotham
	favDesc.TextXAlignment = Enum.TextXAlignment.Left
	favDesc.LayoutOrder = order
	favDesc.Parent = container
	order += 1
	
	-- Spacer
	local spacerAfterDesc = Instance.new("Frame")
	spacerAfterDesc.Size = UDim2.new(1, 0, 0, 5)
	spacerAfterDesc.BackgroundTransparency = 1
	spacerAfterDesc.LayoutOrder = order
	spacerAfterDesc.Parent = container
	order += 1
	
	-- Show favorite animals or empty state
	if #cachedFavoriteAnimals > 0 then
		for _, animalID in cachedFavoriteAnimals do
			local animalDef = AnimalLibraryModule.GetByID(animalID)
			if animalDef then
				local favCard = Instance.new("Frame")
				favCard.Name = animalID .. "FavCard"
				favCard.Size = UDim2.new(1, -30, 0, 70)
				favCard.BackgroundColor3 = Color3.fromRGB(60, 55, 35)
				favCard.BorderSizePixel = 0
				favCard.LayoutOrder = order
				favCard.Parent = container
				
				local favCardCorner = Instance.new("UICorner")
				favCardCorner.CornerRadius = UDim.new(0, 8)
				favCardCorner.Parent = favCard
				
				-- ViewportFrame for 3D preview
				local previewContainer = Instance.new("Frame")
				previewContainer.Name = "PreviewContainer"
				previewContainer.Size = UDim2.new(0, 60, 0, 60)
				previewContainer.Position = UDim2.new(0, 5, 0.5, -30)
				previewContainer.BackgroundColor3 = Color3.fromRGB(40, 35, 25)
				previewContainer.BorderSizePixel = 0
				previewContainer.Parent = favCard
				
				local previewCorner = Instance.new("UICorner")
				previewCorner.CornerRadius = UDim.new(0, 8)
				previewCorner.Parent = previewContainer
				
				-- Create viewport preview
				local viewport = AnimalPreviewBuilder.CreateViewportPreview(
					animalID,
					UDim2.new(1, 0, 1, 0),
					previewContainer
				)
				if viewport then
					viewport.Position = UDim2.new(0, 0, 0, 0)
				end
				
				-- Star overlay on preview
				local starOverlay = Instance.new("TextLabel")
				starOverlay.Name = "StarOverlay"
				starOverlay.Size = UDim2.new(0, 20, 0, 20)
				starOverlay.Position = UDim2.new(1, -22, 0, 2)
				starOverlay.BackgroundTransparency = 1
				starOverlay.Text = "★"
				starOverlay.TextColor3 = Color3.fromRGB(255, 200, 50)
				starOverlay.TextSize = 16
				starOverlay.Font = Enum.Font.GothamBold
				starOverlay.ZIndex = 2
				starOverlay.Parent = previewContainer
				
				-- Name
				local favNameLabel = Instance.new("TextLabel")
				favNameLabel.Name = "Name"
				favNameLabel.Size = UDim2.new(0.5, -80, 0, 22)
				favNameLabel.Position = UDim2.new(0, 72, 0, 8)
				favNameLabel.BackgroundTransparency = 1
				favNameLabel.Text = animalDef.Name
				favNameLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
				favNameLabel.TextSize = 15
				favNameLabel.Font = Enum.Font.GothamBold
				favNameLabel.TextXAlignment = Enum.TextXAlignment.Left
				favNameLabel.Parent = favCard
				
				-- Rarity
				local rarity = AnimalLibraryModule.GetRarity(animalDef.SpawnChance)
				local favRarityLabel = Instance.new("TextLabel")
				favRarityLabel.Name = "Rarity"
				favRarityLabel.Size = UDim2.new(0.5, -80, 0, 14)
				favRarityLabel.Position = UDim2.new(0, 72, 0, 30)
				favRarityLabel.BackgroundTransparency = 1
				favRarityLabel.Text = rarity .. " • " .. animalDef.PointValue .. " pts"
				favRarityLabel.TextColor3 = Color3.fromRGB(180, 160, 120)
				favRarityLabel.TextSize = 11
				favRarityLabel.Font = Enum.Font.Gotham
				favRarityLabel.TextXAlignment = Enum.TextXAlignment.Left
				favRarityLabel.Parent = favCard
				
				-- Info button
				local infoButton = UIHelpers.createInfoButton(
					UDim2.new(0, 24, 0, 24),
					UDim2.new(0, 72, 0, 46),
					favCard
				)
				
				-- Capture for closure
				local capturedAnimalDef = animalDef
				local capturedRarity = rarity
				local capturedAnimalID = animalID
				infoButton.MouseButton1Click:Connect(function()
					if menuGui then
						local stats = {
							{ name = "Point Value", value = tostring(capturedAnimalDef.PointValue) .. " pts" },
							{ name = "Rarity", value = capturedRarity },
							{ name = "Max Speed", value = string.format("%.0f%%", (capturedAnimalDef.MaxSpeed or 0.5) * 100) },
							{ name = "Fear Factor", value = string.format("%.0f%%", (capturedAnimalDef.FearFactor or 0.5) * 100) },
							{ name = "Hunger", value = string.format("%.0f%%", (capturedAnimalDef.Hungriness or 0.5) * 100) },
						}
						local color = capturedAnimalDef.Color
						if typeof(color) == "BrickColor" then
							color = color.Color
						end
						UIHelpers.showInfoPopup(menuGui, capturedAnimalDef.Name, capturedAnimalDef.Description, stats, color, capturedAnimalID)
					end
				end)
				
				-- Unfavorite button
				local unfavButton = UIHelpers.createTextButton(
					"UnfavoriteButton",
					"✕ Remove",
					UDim2.new(0, 75, 0, 28),
					UDim2.new(1, -85, 0.5, -14),
					Color3.fromRGB(120, 60, 50),
					favCard
				)
				unfavButton.TextSize = 11
				
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
		emptyFavLabel.Size = UDim2.new(1, -30, 0, 40)
		emptyFavLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		emptyFavLabel.Text = "No favorite animals yet. Select from your captured animals below!"
		emptyFavLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		emptyFavLabel.TextSize = 12
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
		lockedNote.Size = UDim2.new(1, -30, 0, 26)
		lockedNote.BackgroundColor3 = Color3.fromRGB(80, 60, 40)
		lockedNote.Text = "⚠️ Favorites locked during active game"
		lockedNote.TextColor3 = Color3.fromRGB(255, 200, 100)
		lockedNote.TextSize = 12
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
	collectionHeader.Size = UDim2.new(1, -30, 0, 24)
	collectionHeader.BackgroundTransparency = 1
	collectionHeader.Text = "🦎 Animal Collection"
	collectionHeader.TextColor3 = Color3.fromRGB(200, 150, 255)
	collectionHeader.TextSize = 16
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
	
	-- Summary card
	local summaryCard = Instance.new("Frame")
	summaryCard.Name = "SummaryCard"
	summaryCard.Size = UDim2.new(1, -30, 0, 45)
	summaryCard.BackgroundColor3 = Color3.fromRGB(45, 40, 55)
	summaryCard.BorderSizePixel = 0
	summaryCard.LayoutOrder = order
	summaryCard.Parent = container
	
	local summaryCorner = Instance.new("UICorner")
	summaryCorner.CornerRadius = UDim.new(0, 8)
	summaryCorner.Parent = summaryCard
	
	local summaryLabel = Instance.new("TextLabel")
	summaryLabel.Name = "Summary"
	summaryLabel.Size = UDim2.new(1, -20, 1, 0)
	summaryLabel.Position = UDim2.new(0, 10, 0, 0)
	summaryLabel.BackgroundTransparency = 1
	summaryLabel.Text = string.format("🔍 Discovered: %d / %d animals (%.0f%%)", capturedCount, totalAnimalCount, (capturedCount / totalAnimalCount) * 100)
	summaryLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
	summaryLabel.TextSize = 14
	summaryLabel.Font = Enum.Font.GothamBold
	summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	summaryLabel.Parent = summaryCard
	
	order += 1
	
	-- Spacer
	local spacerBeforeCards = Instance.new("Frame")
	spacerBeforeCards.Size = UDim2.new(1, 0, 0, 8)
	spacerBeforeCards.BackgroundTransparency = 1
	spacerBeforeCards.LayoutOrder = order
	spacerBeforeCards.Parent = container
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
			-- Include full animal def for info popup
			FullDef = libraryAnimal,
		})
	end
	
	-- Create animal cards
	for _, animal in animalData do
		local isCaptured = capturedIndex[animal.ID] == true
		local timesCaptured = animalCaptureCount[animal.ID] or 0
		local isFavorite = table.find(cachedFavoriteAnimals, animal.ID) ~= nil
		
		local animalCard = Instance.new("Frame")
		animalCard.Name = animal.ID .. "Card"
		animalCard.Size = UDim2.new(1, -30, 0, 80)
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
		
		-- Favorite star indicator (bottom-right of preview, bigger and more visible)
		-- Will be added after preview container is created
		
		-- Preview container (holds ViewportFrame or locked preview)
		local previewContainer = Instance.new("Frame")
		previewContainer.Name = "PreviewContainer"
		previewContainer.Size = UDim2.new(0, 65, 0, 65)
		previewContainer.Position = UDim2.new(0, 8, 0.5, -32.5)
		previewContainer.BackgroundColor3 = if isCaptured then Color3.fromRGB(30, 35, 30) else Color3.fromRGB(40, 40, 45)
		previewContainer.BorderSizePixel = 0
		previewContainer.Parent = animalCard
		
		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 8)
		previewCorner.Parent = previewContainer
		
		if isCaptured then
			-- Create 3D viewport preview for discovered animals
			local viewport = AnimalPreviewBuilder.CreateViewportPreview(
				animal.ID,
				UDim2.new(1, 0, 1, 0),
				previewContainer
			)
			if viewport then
				viewport.Position = UDim2.new(0, 0, 0, 0)
			end
		else
			-- Show locked preview with question mark
			AnimalPreviewBuilder.CreateLockedPreview(
				UDim2.new(1, 0, 1, 0),
				previewContainer
			)
		end
		
		-- Animal name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.4, -80, 0, 20)
		nameLabel.Position = UDim2.new(0, 82, 0, 8)
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
		rarityBadge.Position = UDim2.new(0, 82, 0, 28)
		rarityBadge.BackgroundColor3 = if isCaptured then (UIHelpers.RARITY_COLORS[animal.Rarity] or Color3.fromRGB(100, 100, 100)) else Color3.fromRGB(60, 60, 60)
		rarityBadge.Text = if isCaptured then animal.Rarity else "Unknown"
		rarityBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		rarityBadge.TextSize = 10
		rarityBadge.Font = Enum.Font.GothamBold
		rarityBadge.Parent = animalCard
		
		local rarityCorner = Instance.new("UICorner")
		rarityCorner.CornerRadius = UDim.new(0, 4)
		rarityCorner.Parent = rarityBadge
		
		-- Info button (only for discovered animals)
		if isCaptured then
			local infoButton = UIHelpers.createInfoButton(
				UDim2.new(0, 22, 0, 22),
				UDim2.new(0, 160, 0, 26),
				animalCard
			)
			
			-- Capture for closure
			local capturedAnimal = animal
			infoButton.MouseButton1Click:Connect(function()
				if menuGui then
					local fullDef = capturedAnimal.FullDef
					local stats = {
						{ name = "Point Value", value = tostring(capturedAnimal.PointValue) .. " pts" },
						{ name = "Rarity", value = capturedAnimal.Rarity },
						{ name = "Max Speed", value = string.format("%.0f%%", (fullDef.MaxSpeed or 0.5) * 100) },
						{ name = "Fear Factor", value = string.format("%.0f%%", (fullDef.FearFactor or 0.5) * 100) },
						{ name = "Hunger", value = string.format("%.0f%%", (fullDef.Hungriness or 0.5) * 100) },
					}
					UIHelpers.showInfoPopup(menuGui, capturedAnimal.Name, capturedAnimal.Description, stats, capturedAnimal.Color, capturedAnimal.ID)
				end
			end)
		end
		
		-- Right side stats
		local statsFrame = Instance.new("Frame")
		statsFrame.Name = "StatsFrame"
		statsFrame.Size = UDim2.new(0.4, -10, 1, -10)
		statsFrame.Position = UDim2.new(0.6, 5, 0, 5)
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
		
		-- Favorite button (only for captured animals, on same line as rarity/info)
		if isCaptured then
			-- Favorite star indicator (shown before favorite button if favorited)
			if isFavorite then
				local favStarIndicator = Instance.new("TextLabel")
				favStarIndicator.Name = "FavoriteStarIndicator"
				favStarIndicator.Size = UDim2.new(0, 22, 0, 22)
				favStarIndicator.Position = UDim2.new(0, 186, 0, 26)
				favStarIndicator.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
				favStarIndicator.BorderSizePixel = 0
				favStarIndicator.Text = "★"
				favStarIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
				favStarIndicator.TextSize = 14
				favStarIndicator.Font = Enum.Font.GothamBold
				favStarIndicator.Parent = animalCard
				
				local starCorner = Instance.new("UICorner")
				starCorner.CornerRadius = UDim.new(0.5, 0)
				starCorner.Parent = favStarIndicator
			end
			
			-- Position favorite button after the star indicator
			local favButtonX = if isFavorite then 212 else 186
			local favoriteButton = UIHelpers.createTextButton(
				"FavoriteButton",
				if isFavorite then "Unfavorite" else "☆ Favorite",
				UDim2.new(0, 70, 0, 22),
				UDim2.new(0, favButtonX, 0, 26),
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
			local capturedFavoriteAnimals = cachedFavoriteAnimals
			
			favoriteButton.MouseButton1Click:Connect(function()
				if not canModifyFavorites then
					Log.Info(CONTEXT, "Cannot change favorites during an active game")
					if menuGui then
						UIHelpers.showToast(menuGui, "⚠️ Cannot change favorites during a game", Color3.fromRGB(150, 100, 50), 2)
					end
					return
				end
				
				-- Check if trying to add when at max
				if not capturedIsFavorite and #capturedFavoriteAnimals >= 3 then
					Log.Info(CONTEXT, "Maximum 3 favorites allowed")
					if menuGui then
						UIHelpers.showToast(menuGui, "⚠️ You can only have 3 favorites. Remove one first.", Color3.fromRGB(150, 80, 50), 2.5)
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
export type AnimalsTabData = {
	cachedStats: any,
	cachedFavoriteAnimals: { string },
	canModifyFavorites: boolean,
	menuGui: ScreenGui?,
}

function AnimalsTab.populate(container: ScrollingFrame, data: AnimalsTabData)
	if not container then return end
	
	UIHelpers.clearContainer(container)
	
	if not data.cachedStats then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Loading animal data..."
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = container
		return
	end
	
	local order = 0
	
	-- Favorite Animals section
	order = createFavoritesSection(container, data.cachedFavoriteAnimals, data.canModifyFavorites, data.menuGui, order)
	
	-- Animal Collection
	order = createAnimalCollection(container, data.cachedStats, data.cachedFavoriteAnimals, data.canModifyFavorites, data.menuGui, order)
	
	-- Update canvas size
	local animalCount = AnimalLibraryModule.GetTotalCount()
	local baseHeight = 200
	local animalCardsHeight = animalCount * 90  -- Increased from 80 to 90 for larger cards
	local favoritesHeight = #data.cachedFavoriteAnimals * 80 + 100
	local totalHeight = baseHeight + animalCardsHeight + favoritesHeight
	container.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

return AnimalsTab
