--!strict
-- ShopTab.luau
-- Shop tab UI for PlayerMenu (Item purchases and coin bundles)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
local ShopRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ShopRegistry"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local CONTEXT = "ShopTab"

local ShopTab = {}

-- Category header info
local HEADER_COLORS = {
	Ammo = Color3.fromRGB(180, 80, 80),
	Food = Color3.fromRGB(80, 160, 80),
	Tools = Color3.fromRGB(80, 80, 180),
	Materials = Color3.fromRGB(180, 150, 80),
	LuckyBlocks = Color3.fromRGB(255, 180, 50),
	Upgrades = Color3.fromRGB(150, 80, 200),
}

local HEADER_ICONS = {
	Ammo = "🔫",
	Food = "🍎",
	Tools = "🔧",
	Materials = "🪵",
	LuckyBlocks = "🎁",
	Upgrades = "⚡",
}

-- Create coin balance header card
local function createBalanceCard(container: ScrollingFrame, coinBalance: number, order: number): (number, TextLabel?)
	local balanceCard = Instance.new("Frame")
	balanceCard.Name = "BalanceCard"
	balanceCard.Size = UDim2.new(1, -30, 0, 50)
	balanceCard.BackgroundColor3 = Color3.fromRGB(50, 45, 25)
	balanceCard.BorderSizePixel = 0
	balanceCard.LayoutOrder = order
	balanceCard.Parent = container
	
	local balanceCorner = Instance.new("UICorner")
	balanceCorner.CornerRadius = UDim.new(0, 10)
	balanceCorner.Parent = balanceCard
	
	-- Coin icon
	local coinIcon = Instance.new("Frame")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 35, 0, 35)
	coinIcon.Position = UDim2.new(0, 15, 0.5, -17)
	coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	coinIcon.BorderSizePixel = 0
	coinIcon.Parent = balanceCard
	
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
	
	-- Balance text
	local coinBalanceLabel = Instance.new("TextLabel")
	coinBalanceLabel.Name = "BalanceText"
	coinBalanceLabel.Size = UDim2.new(0.5, -60, 1, 0)
	coinBalanceLabel.Position = UDim2.new(0, 60, 0, 0)
	coinBalanceLabel.BackgroundTransparency = 1
	coinBalanceLabel.Text = string.format("%d Coins", coinBalance)
	coinBalanceLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	coinBalanceLabel.TextSize = 20
	coinBalanceLabel.Font = Enum.Font.GothamBold
	coinBalanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinBalanceLabel.Parent = balanceCard
	
	-- "Your Balance" label
	local balanceSubText = Instance.new("TextLabel")
	balanceSubText.Name = "BalanceSubText"
	balanceSubText.Size = UDim2.new(0.5, 0, 0, 20)
	balanceSubText.Position = UDim2.new(0.5, 0, 0.5, -10)
	balanceSubText.BackgroundTransparency = 1
	balanceSubText.Text = "Your Balance"
	balanceSubText.TextColor3 = Color3.fromRGB(180, 160, 100)
	balanceSubText.TextSize = 12
	balanceSubText.Font = Enum.Font.Gotham
	balanceSubText.TextXAlignment = Enum.TextXAlignment.Right
	balanceSubText.Parent = balanceCard
	
	return order + 1, coinBalanceLabel
end

-- Create category header
local function createCategoryHeader(container: ScrollingFrame, category: string, order: number): number
	local header = Instance.new("Frame")
	header.Name = category .. "Header"
	header.Size = UDim2.new(1, -30, 0, 28)
	header.BackgroundColor3 = HEADER_COLORS[category] or Color3.fromRGB(80, 80, 80)
	header.BackgroundTransparency = 0.5
	header.BorderSizePixel = 0
	header.LayoutOrder = order
	header.Parent = container
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 6)
	headerCorner.Parent = header
	
	local headerText = Instance.new("TextLabel")
	headerText.Size = UDim2.new(1, -10, 1, 0)
	headerText.Position = UDim2.new(0, 10, 0, 0)
	headerText.BackgroundTransparency = 1
	headerText.Text = (HEADER_ICONS[category] or "📦") .. " " .. category
	headerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerText.TextSize = 13
	headerText.Font = Enum.Font.GothamBold
	headerText.TextXAlignment = Enum.TextXAlignment.Left
	headerText.Parent = header
	
	return order + 1
end

-- Create shop item row
local function createItemRow(container: ScrollingFrame, shopItem: any, itemDef: any, coinBalance: number, category: string, order: number): number
	local canAfford = coinBalance >= shopItem.CoinPrice
	
	local itemRow = Instance.new("Frame")
	itemRow.Name = shopItem.ID
	itemRow.Size = UDim2.new(1, -30, 0, 55)
	itemRow.BackgroundColor3 = if canAfford then Color3.fromRGB(45, 50, 45) else Color3.fromRGB(50, 45, 45)
	itemRow.BorderSizePixel = 0
	itemRow.LayoutOrder = order
	itemRow.Parent = container
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = itemRow
	
	-- Item icon
	local iconBg = Instance.new("Frame")
	iconBg.Name = "IconBg"
	iconBg.Size = UDim2.new(0, 40, 0, 40)
	iconBg.Position = UDim2.new(0, 8, 0.5, -20)
	iconBg.BackgroundColor3 = UIHelpers.ITEM_COLORS[category] or Color3.fromRGB(100, 100, 100)
	iconBg.BorderSizePixel = 0
	iconBg.Parent = itemRow
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = iconBg
	
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = HEADER_ICONS[category] or "📦"
	iconLabel.TextSize = 20
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = iconBg
	
	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0.4, -60, 0, 20)
	nameLabel.Position = UDim2.new(0, 55, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemDef.Name .. " x" .. shopItem.Quantity
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemRow
	
	-- Discount badge if applicable
	if shopItem.Discount and shopItem.Discount > 0 then
		local discountBadge = Instance.new("TextLabel")
		discountBadge.Name = "Discount"
		discountBadge.Size = UDim2.new(0, 45, 0, 16)
		discountBadge.Position = UDim2.new(0, 55, 0, 30)
		discountBadge.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		discountBadge.Text = "-" .. shopItem.Discount .. "%"
		discountBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		discountBadge.TextSize = 10
		discountBadge.Font = Enum.Font.GothamBold
		discountBadge.Parent = itemRow
		
		local discountCorner = Instance.new("UICorner")
		discountCorner.CornerRadius = UDim.new(0, 3)
		discountCorner.Parent = discountBadge
	end
	
	-- Price
	local priceFrame = Instance.new("Frame")
	priceFrame.Name = "PriceFrame"
	priceFrame.Size = UDim2.new(0, 70, 0, 24)
	priceFrame.Position = UDim2.new(0.55, 0, 0.5, -12)
	priceFrame.BackgroundColor3 = Color3.fromRGB(60, 50, 30)
	priceFrame.BorderSizePixel = 0
	priceFrame.Parent = itemRow
	
	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 4)
	priceCorner.Parent = priceFrame
	
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. shopItem.CoinPrice
	priceLabel.TextColor3 = if canAfford then Color3.fromRGB(255, 220, 100) else Color3.fromRGB(200, 100, 100)
	priceLabel.TextSize = 12
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = priceFrame
	
	-- Buy button
	local buyButton = UIHelpers.createTextButton(
		"BuyButton",
		if canAfford then "Buy" else "Need More",
		UDim2.new(0, 75, 0, 32),
		UDim2.new(1, -85, 0.5, -16),
		if canAfford then Color3.fromRGB(80, 160, 80) else Color3.fromRGB(80, 80, 80),
		itemRow
	)
	buyButton.TextSize = 12
	
	if canAfford then
		local capturedID = shopItem.ID
		buyButton.MouseButton1Click:Connect(function()
			RemoteEvents.ShopPurchaseRequestEvent:FireServer(capturedID)
			Log.Info(CONTEXT, "Attempting to purchase: " .. capturedID)
		end)
	end
	
	return order + 1
end

-- Create coin bundles section
local function createCoinBundles(container: ScrollingFrame, order: number): number
	-- Spacer before coin bundles
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 15)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = order
	spacer.Parent = container
	order += 1
	
	-- Coin Bundles header
	local coinHeader = Instance.new("Frame")
	coinHeader.Name = "CoinBundlesHeader"
	coinHeader.Size = UDim2.new(1, -30, 0, 32)
	coinHeader.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
	coinHeader.BackgroundTransparency = 0.3
	coinHeader.BorderSizePixel = 0
	coinHeader.LayoutOrder = order
	coinHeader.Parent = container
	
	local coinHeaderCorner = Instance.new("UICorner")
	coinHeaderCorner.CornerRadius = UDim.new(0, 6)
	coinHeaderCorner.Parent = coinHeader
	
	local coinHeaderText = Instance.new("TextLabel")
	coinHeaderText.Size = UDim2.new(1, -10, 1, 0)
	coinHeaderText.Position = UDim2.new(0, 10, 0, 0)
	coinHeaderText.BackgroundTransparency = 1
	coinHeaderText.Text = "💎 Buy Coins with Robux"
	coinHeaderText.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinHeaderText.TextSize = 14
	coinHeaderText.Font = Enum.Font.GothamBold
	coinHeaderText.TextXAlignment = Enum.TextXAlignment.Left
	coinHeaderText.Parent = coinHeader
	
	order += 1
	
	-- Coin bundles
	local bundles = ShopRegistry.GetAllCoinBundles()
	for _, bundle in bundles do
		local bundleRow = Instance.new("Frame")
		bundleRow.Name = bundle.ID
		bundleRow.Size = UDim2.new(1, -30, 0, 60)
		bundleRow.BackgroundColor3 = if bundle.Featured then Color3.fromRGB(55, 50, 35) else Color3.fromRGB(50, 50, 55)
		bundleRow.BorderSizePixel = 0
		bundleRow.LayoutOrder = order
		bundleRow.Parent = container
		
		local bundleCorner = Instance.new("UICorner")
		bundleCorner.CornerRadius = UDim.new(0, 8)
		bundleCorner.Parent = bundleRow
		
		-- Featured badge
		if bundle.Featured then
			local featuredBadge = Instance.new("TextLabel")
			featuredBadge.Name = "Featured"
			featuredBadge.Size = UDim2.new(0, 60, 0, 14)
			featuredBadge.Position = UDim2.new(1, -65, 0, 3)
			featuredBadge.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
			featuredBadge.Text = "BEST VALUE"
			featuredBadge.TextColor3 = Color3.fromRGB(50, 30, 0)
			featuredBadge.TextSize = 8
			featuredBadge.Font = Enum.Font.GothamBold
			featuredBadge.Parent = bundleRow
			
			local featuredCorner = Instance.new("UICorner")
			featuredCorner.CornerRadius = UDim.new(0, 3)
			featuredCorner.Parent = featuredBadge
		end
		
		-- Coin icon
		local bundleCoinIcon = Instance.new("Frame")
		bundleCoinIcon.Name = "CoinIcon"
		bundleCoinIcon.Size = UDim2.new(0, 45, 0, 45)
		bundleCoinIcon.Position = UDim2.new(0, 8, 0.5, -22)
		bundleCoinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		bundleCoinIcon.BorderSizePixel = 0
		bundleCoinIcon.Parent = bundleRow
		
		local bundleCoinCorner = Instance.new("UICorner")
		bundleCoinCorner.CornerRadius = UDim.new(1, 0)
		bundleCoinCorner.Parent = bundleCoinIcon
		
		local bundleCoinSymbol = Instance.new("TextLabel")
		bundleCoinSymbol.Size = UDim2.new(1, 0, 1, 0)
		bundleCoinSymbol.BackgroundTransparency = 1
		bundleCoinSymbol.Text = "$"
		bundleCoinSymbol.TextColor3 = Color3.fromRGB(150, 100, 0)
		bundleCoinSymbol.TextScaled = true
		bundleCoinSymbol.Font = Enum.Font.GothamBold
		bundleCoinSymbol.Parent = bundleCoinIcon
		
		-- Bundle name
		local bundleNameLabel = Instance.new("TextLabel")
		bundleNameLabel.Name = "Name"
		bundleNameLabel.Size = UDim2.new(0.4, -60, 0, 20)
		bundleNameLabel.Position = UDim2.new(0, 60, 0, 10)
		bundleNameLabel.BackgroundTransparency = 1
		bundleNameLabel.Text = bundle.Name
		bundleNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		bundleNameLabel.TextSize = 14
		bundleNameLabel.Font = Enum.Font.GothamBold
		bundleNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		bundleNameLabel.Parent = bundleRow
		
		-- Coin amount
		local amountText = string.format("%d Coins", bundle.CoinAmount)
		if bundle.BonusPercent and bundle.BonusPercent > 0 then
			amountText = amountText .. string.format(" (+%d%% bonus!)", bundle.BonusPercent)
		end
		
		local amountLabel = Instance.new("TextLabel")
		amountLabel.Name = "Amount"
		amountLabel.Size = UDim2.new(0.5, -60, 0, 18)
		amountLabel.Position = UDim2.new(0, 60, 0, 32)
		amountLabel.BackgroundTransparency = 1
		amountLabel.Text = amountText
		amountLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		amountLabel.TextSize = 12
		amountLabel.Font = Enum.Font.Gotham
		amountLabel.TextXAlignment = Enum.TextXAlignment.Left
		amountLabel.Parent = bundleRow
		
		-- Robux price button
		local robuxButton = UIHelpers.createTextButton(
			"BuyRobux",
			"R$ " .. bundle.RobuxPrice,
			UDim2.new(0, 80, 0, 36),
			UDim2.new(1, -90, 0.5, -18),
			Color3.fromRGB(0, 160, 80),
			bundleRow
		)
		robuxButton.TextSize = 14
		
		local capturedBundleID = bundle.ID
		robuxButton.MouseButton1Click:Connect(function()
			RemoteEvents.ShopBuyCoinsRequestEvent:FireServer(capturedBundleID)
			Log.Info(CONTEXT, "Attempting to purchase coin bundle: " .. capturedBundleID)
		end)
		
		order += 1
	end
	
	-- Bottom padding
	local bottomPad = Instance.new("Frame")
	bottomPad.Size = UDim2.new(1, 0, 0, 20)
	bottomPad.BackgroundTransparency = 1
	bottomPad.LayoutOrder = order
	bottomPad.Parent = container
	
	return order + 1
end

-- Create permanent upgrades section (Robux purchases)
local function createUpgradesSection(container: ScrollingFrame, order: number, playerUpgrades: { [string]: boolean }?): number
	-- Spacer before upgrades
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 15)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = order
	spacer.Parent = container
	order += 1
	
	-- Upgrades header
	local upgradesHeader = Instance.new("Frame")
	upgradesHeader.Name = "UpgradesHeader"
	upgradesHeader.Size = UDim2.new(1, -30, 0, 32)
	upgradesHeader.BackgroundColor3 = Color3.fromRGB(150, 80, 200)
	upgradesHeader.BackgroundTransparency = 0.3
	upgradesHeader.BorderSizePixel = 0
	upgradesHeader.LayoutOrder = order
	upgradesHeader.Parent = container
	
	local upgradesHeaderCorner = Instance.new("UICorner")
	upgradesHeaderCorner.CornerRadius = UDim.new(0, 6)
	upgradesHeaderCorner.Parent = upgradesHeader
	
	local upgradesHeaderText = Instance.new("TextLabel")
	upgradesHeaderText.Size = UDim2.new(1, -10, 1, 0)
	upgradesHeaderText.Position = UDim2.new(0, 10, 0, 0)
	upgradesHeaderText.BackgroundTransparency = 1
	upgradesHeaderText.Text = "⚡ Permanent Upgrades (Robux)"
	upgradesHeaderText.TextColor3 = Color3.fromRGB(255, 255, 255)
	upgradesHeaderText.TextSize = 14
	upgradesHeaderText.Font = Enum.Font.GothamBold
	upgradesHeaderText.TextXAlignment = Enum.TextXAlignment.Left
	upgradesHeaderText.Parent = upgradesHeader
	
	order += 1
	
	-- Get all upgrades
	local upgrades = ShopRegistry.GetAllUpgrades()
	for _, upgrade in upgrades do
		-- Check if player already owns this upgrade
		local alreadyOwned = false
		if playerUpgrades then
			if upgrade.ID == "UPGRADE_HEAT_SEEKING_AMMO" then
				alreadyOwned = playerUpgrades.HeatSeekingAmmo == true
			elseif upgrade.ID == "UPGRADE_REINFORCED_SHIELD" then
				alreadyOwned = playerUpgrades.ReinforcedShield == true
			end
		end
		
		local upgradeRow = Instance.new("Frame")
		upgradeRow.Name = upgrade.ID
		upgradeRow.Size = UDim2.new(1, -30, 0, 75)
		upgradeRow.BackgroundColor3 = if alreadyOwned then Color3.fromRGB(40, 60, 40) elseif upgrade.Featured then Color3.fromRGB(60, 45, 70) else Color3.fromRGB(50, 50, 55)
		upgradeRow.BorderSizePixel = 0
		upgradeRow.LayoutOrder = order
		upgradeRow.Parent = container
		
		local upgradeCorner = Instance.new("UICorner")
		upgradeCorner.CornerRadius = UDim.new(0, 8)
		upgradeCorner.Parent = upgradeRow
		
		-- Featured badge
		if upgrade.Featured then
			local featuredBadge = Instance.new("TextLabel")
			featuredBadge.Name = "Featured"
			featuredBadge.Size = UDim2.new(0, 60, 0, 14)
			featuredBadge.Position = UDim2.new(1, -65, 0, 3)
			featuredBadge.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
			featuredBadge.Text = "FEATURED"
			featuredBadge.TextColor3 = Color3.fromRGB(50, 30, 0)
			featuredBadge.TextSize = 8
			featuredBadge.Font = Enum.Font.GothamBold
			featuredBadge.Parent = upgradeRow
			
			local featuredCorner = Instance.new("UICorner")
			featuredCorner.CornerRadius = UDim.new(0, 3)
			featuredCorner.Parent = featuredBadge
		end
		
		-- Upgrade icon
		local upgradeIcon = Instance.new("Frame")
		upgradeIcon.Name = "UpgradeIcon"
		upgradeIcon.Size = UDim2.new(0, 50, 0, 50)
		upgradeIcon.Position = UDim2.new(0, 8, 0.5, -25)
		upgradeIcon.BackgroundColor3 = Color3.fromRGB(150, 80, 200)
		upgradeIcon.BorderSizePixel = 0
		upgradeIcon.Parent = upgradeRow
		
		local upgradeIconCorner = Instance.new("UICorner")
		upgradeIconCorner.CornerRadius = UDim.new(0, 8)
		upgradeIconCorner.Parent = upgradeIcon
		
		local upgradeIconSymbol = Instance.new("TextLabel")
		upgradeIconSymbol.Size = UDim2.new(1, 0, 1, 0)
		upgradeIconSymbol.BackgroundTransparency = 1
		upgradeIconSymbol.Text = "⚡"
		upgradeIconSymbol.TextSize = 28
		upgradeIconSymbol.Font = Enum.Font.GothamBold
		upgradeIconSymbol.Parent = upgradeIcon
		
		-- Upgrade name
		local upgradeNameLabel = Instance.new("TextLabel")
		upgradeNameLabel.Name = "Name"
		upgradeNameLabel.Size = UDim2.new(0.5, -70, 0, 20)
		upgradeNameLabel.Position = UDim2.new(0, 65, 0, 10)
		upgradeNameLabel.BackgroundTransparency = 1
		upgradeNameLabel.Text = upgrade.Name
		upgradeNameLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
		upgradeNameLabel.TextSize = 14
		upgradeNameLabel.Font = Enum.Font.GothamBold
		upgradeNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		upgradeNameLabel.Parent = upgradeRow
		
		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(0.55, -70, 0, 35)
		descLabel.Position = UDim2.new(0, 65, 0, 32)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = upgrade.Description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextSize = 11
		-- Robux price button or Owned badge
		if alreadyOwned then
			local ownedBadge = Instance.new("TextLabel")
			ownedBadge.Name = "OwnedBadge"
			ownedBadge.Size = UDim2.new(0, 90, 0, 40)
			ownedBadge.Position = UDim2.new(1, -100, 0.5, -20)
			ownedBadge.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
			ownedBadge.Text = "✓ OWNED"
			ownedBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
			ownedBadge.TextSize = 14
			ownedBadge.Font = Enum.Font.GothamBold
			ownedBadge.Parent = upgradeRow
			
			local ownedCorner = Instance.new("UICorner")
			ownedCorner.CornerRadius = UDim.new(0, 8)
			ownedCorner.Parent = ownedBadge
		else
			local robuxButton = UIHelpers.createTextButton(
				"BuyRobux",
				"R$ " .. upgrade.RobuxPrice,
				UDim2.new(0, 90, 0, 40),
				UDim2.new(1, -100, 0.5, -20),
				Color3.fromRGB(0, 160, 80),
				upgradeRow
			)
			robuxButton.TextSize = 16
			
			local capturedUpgradeID = upgrade.ID
			robuxButton.MouseButton1Click:Connect(function()
				RemoteEvents.ShopBuyUpgradeRequestEvent:FireServer(capturedUpgradeID)
				Log.Info(CONTEXT, "Attempting to purchase upgrade: " .. capturedUpgradeID)
			end)
		end
		
		order += 1
	end
	
	return order
end

-- Main populate function
export type ShopTabData = {
	cachedInventory: { Items: { [string]: any }, Upgrades: { [string]: boolean }? }?,
}

function ShopTab.populate(container: ScrollingFrame, data: ShopTabData): TextLabel?
	if not container then return nil end
	
	UIHelpers.clearContainer(container)
	
	local order = 0
	
	-- Get current coin balance from cached inventory
	local coinBalance = 0
	if data.cachedInventory and data.cachedInventory.Items and data.cachedInventory.Items.COIN then
		coinBalance = data.cachedInventory.Items.COIN.Quantity or 0
	end
	
	-- Coin balance header
	local coinBalanceLabel: TextLabel?
	order, coinBalanceLabel = createBalanceCard(container, coinBalance, order)
	
	-- Get items by category
	local categories = { "LuckyBlocks", "Ammo", "Food", "Tools", "Materials" }
	
	for _, category in categories do
		local items = ShopRegistry.GetItemsByCategory(category)
		if #items > 0 then
			-- Category header
			order = createCategoryHeader(container, category, order)
			
			-- Sort items by price
			table.sort(items, function(a, b)
				return a.CoinPrice < b.CoinPrice
			end)
			
			-- Items in category
			for _, shopItem in items do
				local itemDef = ItemRegistry.GetItem(shopItem.ItemID)
				if itemDef then
					order = createItemRow(container, shopItem, itemDef, coinBalance, category, order)
				end
			end
		end
	end
	
	-- Permanent upgrades section (pass player upgrades for owned state)
	local playerUpgrades = data.cachedInventory and (data.cachedInventory :: any).Upgrades or nil
	Log.Info(CONTEXT, "ShopTab upgrades data: " .. tostring(playerUpgrades) .. ", HeatSeekingAmmo=" .. tostring(playerUpgrades and playerUpgrades.HeatSeekingAmmo))
	order = createUpgradesSection(container, order, playerUpgrades)
	
	-- Coin bundles section
	order = createCoinBundles(container, order)
	
	-- Calculate canvas size
	local calcHeight = 58 -- balance card
	for _, category in categories do
		local items = ShopRegistry.GetItemsByCategory(category)
		if #items > 0 then
			calcHeight += 36 -- header
			calcHeight += #items * 63 -- items
		end
	end
	calcHeight += 23 + 40 -- spacer + upgrades header
	local upgrades = ShopRegistry.GetAllUpgrades()
	calcHeight += #upgrades * 83 -- upgrades
	calcHeight += 23 + 40 -- spacer + coin header
	local bundles = ShopRegistry.GetAllCoinBundles()
	calcHeight += #bundles * 68 -- bundles
	calcHeight += 28 -- bottom pad
	
	container.CanvasSize = UDim2.new(0, 0, 0, calcHeight)
	
	return coinBalanceLabel
end

return ShopTab
