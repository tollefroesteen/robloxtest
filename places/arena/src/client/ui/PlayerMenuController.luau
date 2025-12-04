--!strict
-- PlayerMenuController.luau
-- Main player menu with Inventory and Achievements tabs
-- Opens with 'I' key or menu button

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
local ShopRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ShopRegistry"))
local AnimalLibraryModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AnimalLibraryModule"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "PlayerMenuController"
local player: Player = Players.LocalPlayer

local PlayerMenuController = {}

-- State
local initialized: boolean = false
local isMenuOpen: boolean = false
local currentTab: string = "Inventory"

-- Data caches
local cachedInventory: { Items: { [string]: any } }? = nil
local cachedStats: any = nil
local cachedAchievements: { [string]: any }? = nil

-- UI references
local menuGui: ScreenGui? = nil
local menuFrame: Frame? = nil
local inventoryContainer: ScrollingFrame? = nil
local achievementsContainer: ScrollingFrame? = nil
local statsContainer: ScrollingFrame? = nil
local shopContainer: ScrollingFrame? = nil
local tabButtons: { [string]: TextButton } = {}
local coinBalanceLabel: TextLabel? = nil

-- UI Constants
local MENU_SIZE = UDim2.new(0, 550, 0, 450)
local MENU_POSITION_CLOSED = UDim2.new(0.5, -275, 1.5, 0)
local MENU_POSITION_OPEN = UDim2.new(0.5, -275, 0.5, -225)
local TAB_COLORS = {
	Selected = Color3.fromRGB(70, 130, 180),
	Unselected = Color3.fromRGB(50, 50, 50),
}
local ITEM_COLORS = {
	Ammo = Color3.fromRGB(200, 100, 100),
	Food = Color3.fromRGB(100, 200, 100),
	Tools = Color3.fromRGB(100, 100, 200),
	Materials = Color3.fromRGB(200, 180, 100),
	Special = Color3.fromRGB(200, 150, 255),
}
local ACHIEVEMENT_COLORS = {
	Completed = Color3.fromRGB(100, 200, 100),
	InProgress = Color3.fromRGB(200, 200, 100),
	Locked = Color3.fromRGB(100, 100, 100),
}

-- Helper: Create rounded frame
local function createRoundedFrame(name: string, size: UDim2, position: UDim2, color: Color3, parent: GuiObject): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	return frame
end

-- Helper: Create text button
local function createTextButton(name: string, text: string, size: UDim2, position: UDim2, color: Color3, parent: GuiObject): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	return button
end

-- Create the main menu GUI
local function createMenuGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Remove existing if any
	local existing = playerGui:FindFirstChild("PlayerMenuGui")
	if existing then
		existing:Destroy()
	end
	
	-- Screen GUI
	menuGui = Instance.new("ScreenGui")
	menuGui.Name = "PlayerMenuGui"
	menuGui.ResetOnSpawn = false
	menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	menuGui.DisplayOrder = 10
	menuGui.Parent = playerGui
	
	-- Main frame
	menuFrame = createRoundedFrame("MenuFrame", MENU_SIZE, MENU_POSITION_CLOSED, Color3.fromRGB(40, 40, 40), menuGui)
	menuFrame.Visible = false
	
	-- Title bar
	local titleBar = createRoundedFrame("TitleBar", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), Color3.fromRGB(30, 30, 30), menuFrame)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Player Menu"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar
	
	-- Close button
	local closeButton = createTextButton("CloseButton", "X", UDim2.new(0, 35, 0, 35), UDim2.new(1, -40, 0.5, -17), Color3.fromRGB(180, 60, 60), titleBar)
	closeButton.MouseButton1Click:Connect(function()
		PlayerMenuController.CloseMenu()
	end)
	
	-- Tab bar
	local tabBar = createRoundedFrame("TabBar", UDim2.new(1, -20, 0, 35), UDim2.new(0, 10, 0, 50), Color3.fromRGB(30, 30, 30), menuFrame)
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabBar
	
	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 5)
	tabPadding.PaddingTop = UDim.new(0, 3)
	tabPadding.Parent = tabBar
	
	-- Create tabs
	local tabs = { "Inventory", "Shop", "Achievements", "Stats" }
	for _, tabName in ipairs(tabs) do
		local isSelected = tabName == currentTab
		local tabWidth = if tabName == "Achievements" then 105 else 85
		local button = createTextButton(
			tabName .. "Tab",
			tabName,
			UDim2.new(0, tabWidth, 0, 28),
			UDim2.new(0, 0, 0, 0),
			if isSelected then TAB_COLORS.Selected else TAB_COLORS.Unselected,
			tabBar
		)
		button.TextSize = 13
		tabButtons[tabName] = button
		
		button.MouseButton1Click:Connect(function()
			PlayerMenuController.SwitchTab(tabName)
		end)
	end
	
	-- Content area
	local contentArea = createRoundedFrame("ContentArea", UDim2.new(1, -20, 1, -100), UDim2.new(0, 10, 0, 95), Color3.fromRGB(50, 50, 50), menuFrame)
	
	-- Inventory container (scrolling grid)
	inventoryContainer = Instance.new("ScrollingFrame")
	inventoryContainer.Name = "InventoryContainer"
	inventoryContainer.Size = UDim2.new(1, -10, 1, -10)
	inventoryContainer.Position = UDim2.new(0, 5, 0, 5)
	inventoryContainer.BackgroundTransparency = 1
	inventoryContainer.ScrollBarThickness = 6
	inventoryContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	inventoryContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryContainer.Visible = true
	inventoryContainer.Parent = contentArea
	
	local invGrid = Instance.new("UIGridLayout")
	invGrid.CellSize = UDim2.new(0, 80, 0, 90)
	invGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	invGrid.SortOrder = Enum.SortOrder.LayoutOrder
	invGrid.Parent = inventoryContainer
	
	local invPadding = Instance.new("UIPadding")
	invPadding.PaddingLeft = UDim.new(0, 5)
	invPadding.PaddingTop = UDim.new(0, 5)
	invPadding.Parent = inventoryContainer
	
	-- Achievements container (scrolling list)
	achievementsContainer = Instance.new("ScrollingFrame")
	achievementsContainer.Name = "AchievementsContainer"
	achievementsContainer.Size = UDim2.new(1, -10, 1, -10)
	achievementsContainer.Position = UDim2.new(0, 5, 0, 5)
	achievementsContainer.BackgroundTransparency = 1
	achievementsContainer.ScrollBarThickness = 6
	achievementsContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	achievementsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	achievementsContainer.Visible = false
	achievementsContainer.Parent = contentArea
	
	local achList = Instance.new("UIListLayout")
	achList.Padding = UDim.new(0, 5)
	achList.SortOrder = Enum.SortOrder.LayoutOrder
	achList.Parent = achievementsContainer
	
	local achPadding = Instance.new("UIPadding")
	achPadding.PaddingLeft = UDim.new(0, 5)
	achPadding.PaddingTop = UDim.new(0, 5)
	achPadding.PaddingRight = UDim.new(0, 5)
	achPadding.Parent = achievementsContainer
	
	-- Stats container (scrolling)
	statsContainer = Instance.new("ScrollingFrame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(1, -10, 1, -10)
	statsContainer.Position = UDim2.new(0, 5, 0, 5)
	statsContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	statsContainer.BackgroundTransparency = 0
	statsContainer.BorderSizePixel = 0
	statsContainer.ScrollBarThickness = 6
	statsContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	statsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	statsContainer.Visible = false
	statsContainer.Parent = contentArea
	
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = statsContainer
	
	local statsList = Instance.new("UIListLayout")
	statsList.Padding = UDim.new(0, 8)
	statsList.SortOrder = Enum.SortOrder.LayoutOrder
	statsList.Parent = statsContainer
	
	local statsPadding = Instance.new("UIPadding")
	statsPadding.PaddingLeft = UDim.new(0, 15)
	statsPadding.PaddingTop = UDim.new(0, 15)
	statsPadding.PaddingRight = UDim.new(0, 15)
	statsPadding.PaddingBottom = UDim.new(0, 15)
	statsPadding.Parent = statsContainer
	
	-- Shop container (scrolling)
	shopContainer = Instance.new("ScrollingFrame")
	shopContainer.Name = "ShopContainer"
	shopContainer.Size = UDim2.new(1, -10, 1, -10)
	shopContainer.Position = UDim2.new(0, 5, 0, 5)
	shopContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	shopContainer.BackgroundTransparency = 0
	shopContainer.BorderSizePixel = 0
	shopContainer.ScrollBarThickness = 6
	shopContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	shopContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopContainer.Visible = false
	shopContainer.Parent = contentArea
	
	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 8)
	shopCorner.Parent = shopContainer
	
	local shopList = Instance.new("UIListLayout")
	shopList.Padding = UDim.new(0, 8)
	shopList.SortOrder = Enum.SortOrder.LayoutOrder
	shopList.Parent = shopContainer
	
	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingLeft = UDim.new(0, 15)
	shopPadding.PaddingTop = UDim.new(0, 15)
	shopPadding.PaddingRight = UDim.new(0, 15)
	shopPadding.PaddingBottom = UDim.new(0, 15)
	shopPadding.Parent = shopContainer
	
	-- Open menu button (bottom-left corner)
	local openButton = createTextButton("OpenMenuButton", "📦", UDim2.new(0, 50, 0, 50), UDim2.new(0, 10, 1, -60), Color3.fromRGB(60, 60, 60), menuGui)
	openButton.TextSize = 24
	openButton.MouseButton1Click:Connect(function()
		PlayerMenuController.ToggleMenu()
	end)
	
	-- Tooltip for open button
	local tooltip = Instance.new("TextLabel")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.new(0, 80, 0, 20)
	tooltip.Position = UDim2.new(1, 5, 0.5, -10)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tooltip.BackgroundTransparency = 0.2
	tooltip.Text = "Press I"
	tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
	tooltip.TextSize = 12
	tooltip.Font = Enum.Font.Gotham
	tooltip.Visible = false
	tooltip.Parent = openButton
	
	local tooltipCorner = Instance.new("UICorner")
	tooltipCorner.CornerRadius = UDim.new(0, 4)
	tooltipCorner.Parent = tooltip
	
	openButton.MouseEnter:Connect(function()
		tooltip.Visible = true
	end)
	openButton.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
	
	Log.Info(CONTEXT, "PlayerMenuGui created")
end

-- Create an inventory item cell
local function createInventoryItem(itemData: any, definition: any): Frame
	local cell = Instance.new("Frame")
	cell.Name = definition.ID
	cell.Size = UDim2.new(0, 80, 0, 90)
	cell.BackgroundColor3 = ITEM_COLORS[definition.Category] or Color3.fromRGB(80, 80, 80)
	cell.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = cell
	
	-- Icon - use visual elements for Special (coins), emojis for others
	if definition.Category == "Special" and definition.ID == "COIN" then
		-- Create coin icon matching the HUD
		local coinIcon = Instance.new("Frame")
		coinIcon.Name = "CoinIcon"
		coinIcon.Size = UDim2.new(0, 36, 0, 36)
		coinIcon.Position = UDim2.new(0.5, -18, 0, 7)
		coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		coinIcon.BorderSizePixel = 0
		coinIcon.Parent = cell
		
		local coinCorner = Instance.new("UICorner")
		coinCorner.CornerRadius = UDim.new(1, 0)
		coinCorner.Parent = coinIcon
		
		local coinSymbol = Instance.new("TextLabel")
		coinSymbol.Name = "CoinSymbol"
		coinSymbol.Size = UDim2.new(1, 0, 1, 0)
		coinSymbol.BackgroundTransparency = 1
		coinSymbol.Text = "$"
		coinSymbol.TextColor3 = Color3.fromRGB(150, 100, 0)
		coinSymbol.TextScaled = true
		coinSymbol.Font = Enum.Font.GothamBold
		coinSymbol.Parent = coinIcon
	else
		-- Standard emoji icons for other categories
		local iconSymbols = {
			Ammo = "🔫",
			Food = "🍎",
			Tools = "🔧",
			Materials = "🪵",
			Special = "⭐",
		}
		
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 0, 40)
		icon.Position = UDim2.new(0, 0, 0, 5)
		icon.BackgroundTransparency = 1
		icon.Text = iconSymbols[definition.Category] or "📦"
		icon.TextSize = 28
		icon.Font = Enum.Font.GothamBold
		icon.Parent = cell
	end
	
	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -4, 0, 20)
	nameLabel.Position = UDim2.new(0, 2, 0, 45)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = definition.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 10
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = cell
	
	-- Quantity badge
	local quantityBadge = createRoundedFrame("QuantityBadge", UDim2.new(0, 35, 0, 18), UDim2.new(0.5, -17, 1, -22), Color3.fromRGB(30, 30, 30), cell)
	
	local quantityLabel = Instance.new("TextLabel")
	quantityLabel.Name = "Quantity"
	quantityLabel.Size = UDim2.new(1, 0, 1, 0)
	quantityLabel.BackgroundTransparency = 1
	quantityLabel.Text = tostring(itemData.Quantity)
	quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	quantityLabel.TextSize = 12
	quantityLabel.Font = Enum.Font.GothamBold
	quantityLabel.Parent = quantityBadge
	
	return cell
end

-- Create an achievement row (redesigned for clarity)
local function createAchievementRow(achievementID: string, progress: any?, definition: any, isCompletedSection: boolean): Frame
	local isCompleted = progress and progress.Completed
	local currentValue = if progress then progress.CurrentValue else 0
	local targetValue = definition.TargetValue
	local progressPercent = math.min(currentValue / targetValue, 1)
	
	local row = Instance.new("Frame")
	row.Name = achievementID
	row.Size = UDim2.new(1, -10, 0, 60)
	row.BorderSizePixel = 0
	
	-- Different styling for completed vs incomplete
	if isCompleted then
		row.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
	elseif currentValue > 0 then
		row.BackgroundColor3 = Color3.fromRGB(60, 55, 35)
	else
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	end
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row
	
	-- Left accent bar (color indicates status)
	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 4, 1, -8)
	accent.Position = UDim2.new(0, 4, 0, 4)
	accent.BorderSizePixel = 0
	accent.BackgroundColor3 = if isCompleted then Color3.fromRGB(80, 200, 80) else if currentValue > 0 then Color3.fromRGB(200, 180, 60) else Color3.fromRGB(100, 100, 120)
	accent.Parent = row
	
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accent
	
	-- Status icon (larger, more visible)
	local statusIcon = Instance.new("TextLabel")
	statusIcon.Name = "StatusIcon"
	statusIcon.Size = UDim2.new(0, 36, 0, 36)
	statusIcon.Position = UDim2.new(0, 14, 0.5, -18)
	statusIcon.BackgroundTransparency = 1
	statusIcon.Text = if isCompleted then "✅" else if currentValue > 0 then "⏳" else "🔒"
	statusIcon.TextSize = 24
	statusIcon.Font = Enum.Font.GothamBold
	statusIcon.Parent = row
	
	-- Name (bold, prominent)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0.55, -60, 0, 22)
	nameLabel.Position = UDim2.new(0, 55, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = definition.Name
	nameLabel.TextColor3 = if isCompleted then Color3.fromRGB(150, 255, 150) else Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 15
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0.55, -60, 0, 16)
	descLabel.Position = UDim2.new(0, 55, 0, 30)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = definition.Description
	descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	descLabel.TextSize = 12
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = row
	
	-- Right side container for progress
	local rightContainer = Instance.new("Frame")
	rightContainer.Name = "RightContainer"
	rightContainer.Size = UDim2.new(0.4, 0, 1, 0)
	rightContainer.Position = UDim2.new(0.6, 0, 0, 0)
	rightContainer.BackgroundTransparency = 1
	rightContainer.Parent = row
	
	if isCompleted then
		-- Show "COMPLETED" badge for completed achievements
		local completedBadge = Instance.new("TextLabel")
		completedBadge.Name = "CompletedBadge"
		completedBadge.Size = UDim2.new(0, 90, 0, 24)
		completedBadge.Position = UDim2.new(0.5, -45, 0.5, -12)
		completedBadge.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
		completedBadge.Text = "COMPLETED"
		completedBadge.TextColor3 = Color3.fromRGB(200, 255, 200)
		completedBadge.TextSize = 11
		completedBadge.Font = Enum.Font.GothamBold
		completedBadge.Parent = rightContainer
		
		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = completedBadge
	else
		-- Progress bar for incomplete
		local progressBg = Instance.new("Frame")
		progressBg.Name = "ProgressBg"
		progressBg.Size = UDim2.new(0.85, 0, 0, 10)
		progressBg.Position = UDim2.new(0.075, 0, 0, 15)
		progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		progressBg.BorderSizePixel = 0
		progressBg.Parent = rightContainer
		
		local progressBgCorner = Instance.new("UICorner")
		progressBgCorner.CornerRadius = UDim.new(0, 4)
		progressBgCorner.Parent = progressBg
		
		local progressFill = Instance.new("Frame")
		progressFill.Name = "ProgressFill"
		progressFill.Size = UDim2.new(progressPercent, 0, 1, 0)
		progressFill.BackgroundColor3 = if currentValue > 0 then Color3.fromRGB(200, 180, 60) else Color3.fromRGB(80, 80, 100)
		progressFill.BorderSizePixel = 0
		progressFill.Parent = progressBg
		
		local progressFillCorner = Instance.new("UICorner")
		progressFillCorner.CornerRadius = UDim.new(0, 4)
		progressFillCorner.Parent = progressFill
		
		-- Progress text (below bar)
		local progressText = Instance.new("TextLabel")
		progressText.Name = "ProgressText"
		progressText.Size = UDim2.new(1, 0, 0, 16)
		progressText.Position = UDim2.new(0, 0, 0, 28)
		progressText.BackgroundTransparency = 1
		progressText.Text = string.format("%d / %d", currentValue, targetValue)
		progressText.TextColor3 = Color3.fromRGB(180, 180, 180)
		progressText.TextSize = 12
		progressText.Font = Enum.Font.GothamBold
		progressText.Parent = rightContainer
		
		-- XP reward
		local xpLabel = Instance.new("TextLabel")
		xpLabel.Name = "XPReward"
		xpLabel.Size = UDim2.new(1, 0, 0, 14)
		xpLabel.Position = UDim2.new(0, 0, 0, 44)
		xpLabel.BackgroundTransparency = 1
		xpLabel.Text = "Reward: +" .. definition.RewardXP .. " XP"
		xpLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		xpLabel.TextSize = 10
		xpLabel.Font = Enum.Font.Gotham
		xpLabel.Parent = rightContainer
	end
	
	return row
end

-- Create a stat row
local function createStatRow(name: string, value: any, order: number): Frame
	local row = Instance.new("Frame")
	row.Name = name
	row.Size = UDim2.new(1, -30, 0, 25)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(value)
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = row
	
	return row
end

-- Populate inventory tab
local function populateInventory(): nil
	if not inventoryContainer then return end
	
	-- Clear existing items
	for _, child in inventoryContainer:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if not cachedInventory or not cachedInventory.Items then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyMessage"
		emptyLabel.Size = UDim2.new(1, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Your inventory is empty"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = inventoryContainer
		return
	end
	
	local itemCount = 0
	for itemID, itemData in cachedInventory.Items do
		local definition = ItemRegistry.GetItem(itemID)
		if definition and itemData.Quantity > 0 then
			local cell = createInventoryItem(itemData, definition)
			cell.LayoutOrder = itemCount
			cell.Parent = inventoryContainer
			itemCount += 1
		end
	end
	
	if itemCount == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyMessage"
		emptyLabel.Size = UDim2.new(1, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Your inventory is empty"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = inventoryContainer
	end
	
	-- Update canvas size
	local grid = inventoryContainer:FindFirstChildOfClass("UIGridLayout")
	if grid then
		local rows = math.ceil(itemCount / 5)
		inventoryContainer.CanvasSize = UDim2.new(0, 0, 0, rows * 98 + 10)
	end
end

-- Populate achievements tab (redesigned: separate completed vs in-progress)
local function populateAchievements(): nil
	if not achievementsContainer then return end
	
	-- Clear existing
	for _, child in achievementsContainer:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	-- Collect all achievements and sort them
	local completedAchievements: { { def: any, progress: any } } = {}
	local inProgressAchievements: { { def: any, progress: any } } = {}
	local lockedAchievements: { { def: any, progress: any } } = {}
	
	local allAchievementIDs = AchievementRegistry.GetAllIDs()
	for _, achievementID in allAchievementIDs do
		local definition = AchievementRegistry.GetAchievement(achievementID)
		if definition then
			local progress = cachedAchievements and cachedAchievements[achievementID]
			local isCompleted = progress and progress.Completed
			local currentValue = if progress then progress.CurrentValue else 0
			
			-- Skip hidden achievements that aren't completed
			if definition.Hidden and not isCompleted then
				continue
			end
			
			local entry = { def = definition, progress = progress }
			
			if isCompleted then
				table.insert(completedAchievements, entry)
			elseif currentValue > 0 then
				table.insert(inProgressAchievements, entry)
			else
				table.insert(lockedAchievements, entry)
			end
		end
	end
	
	local rowCount = 0
	local ROW_HEIGHT = 68 -- 60 + 8 padding
	
	-- Summary header
	local totalCount = #completedAchievements + #inProgressAchievements + #lockedAchievements
	local summaryFrame = Instance.new("Frame")
	summaryFrame.Name = "Summary"
	summaryFrame.Size = UDim2.new(1, -10, 0, 50)
	summaryFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	summaryFrame.BorderSizePixel = 0
	summaryFrame.LayoutOrder = rowCount
	summaryFrame.Parent = achievementsContainer
	
	local summaryCorner = Instance.new("UICorner")
	summaryCorner.CornerRadius = UDim.new(0, 8)
	summaryCorner.Parent = summaryFrame
	
	local summaryText = Instance.new("TextLabel")
	summaryText.Size = UDim2.new(1, 0, 0, 25)
	summaryText.Position = UDim2.new(0, 0, 0, 5)
	summaryText.BackgroundTransparency = 1
	summaryText.Text = string.format("🏆 Achievements: %d / %d Completed", #completedAchievements, totalCount)
	summaryText.TextColor3 = Color3.fromRGB(255, 215, 0)
	summaryText.TextSize = 16
	summaryText.Font = Enum.Font.GothamBold
	summaryText.Parent = summaryFrame
	
	-- Progress bar for overall completion
	local overallProgress = if totalCount > 0 then #completedAchievements / totalCount else 0
	local overallBg = Instance.new("Frame")
	overallBg.Size = UDim2.new(0.9, 0, 0, 8)
	overallBg.Position = UDim2.new(0.05, 0, 0, 35)
	overallBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	overallBg.BorderSizePixel = 0
	overallBg.Parent = summaryFrame
	
	local overallBgCorner = Instance.new("UICorner")
	overallBgCorner.CornerRadius = UDim.new(0, 4)
	overallBgCorner.Parent = overallBg
	
	local overallFill = Instance.new("Frame")
	overallFill.Size = UDim2.new(overallProgress, 0, 1, 0)
	overallFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	overallFill.BorderSizePixel = 0
	overallFill.Parent = overallBg
	
	local overallFillCorner = Instance.new("UICorner")
	overallFillCorner.CornerRadius = UDim.new(0, 4)
	overallFillCorner.Parent = overallFill
	
	rowCount += 1
	
	-- Helper to create section header
	local function createSectionHeader(title: string, icon: string, count: number, color: Color3): Frame
		local header = Instance.new("Frame")
		header.Name = title .. "Header"
		header.Size = UDim2.new(1, -10, 0, 30)
		header.BackgroundColor3 = color
		header.BackgroundTransparency = 0.5
		header.BorderSizePixel = 0
		header.LayoutOrder = rowCount
		
		local headerCorner = Instance.new("UICorner")
		headerCorner.CornerRadius = UDim.new(0, 6)
		headerCorner.Parent = header
		
		local headerText = Instance.new("TextLabel")
		headerText.Size = UDim2.new(1, -10, 1, 0)
		headerText.Position = UDim2.new(0, 10, 0, 0)
		headerText.BackgroundTransparency = 1
		headerText.Text = string.format("%s %s (%d)", icon, title, count)
		headerText.TextColor3 = Color3.fromRGB(255, 255, 255)
		headerText.TextSize = 14
		headerText.Font = Enum.Font.GothamBold
		headerText.TextXAlignment = Enum.TextXAlignment.Left
		headerText.Parent = header
		
		return header
	end
	
	-- IN PROGRESS section (show first - most relevant)
	if #inProgressAchievements > 0 then
		local header = createSectionHeader("In Progress", "⏳", #inProgressAchievements, Color3.fromRGB(180, 150, 50))
		header.Parent = achievementsContainer
		rowCount += 1
		
		for _, entry in inProgressAchievements do
			local row = createAchievementRow(entry.def.ID, entry.progress, entry.def, false)
			row.LayoutOrder = rowCount
			row.Parent = achievementsContainer
			rowCount += 1
		end
	end
	
	-- LOCKED section (not started)
	if #lockedAchievements > 0 then
		local header = createSectionHeader("Not Started", "🔒", #lockedAchievements, Color3.fromRGB(80, 80, 100))
		header.Parent = achievementsContainer
		rowCount += 1
		
		for _, entry in lockedAchievements do
			local row = createAchievementRow(entry.def.ID, entry.progress, entry.def, false)
			row.LayoutOrder = rowCount
			row.Parent = achievementsContainer
			rowCount += 1
		end
	end
	
	-- COMPLETED section (at bottom)
	if #completedAchievements > 0 then
		local header = createSectionHeader("Completed", "✅", #completedAchievements, Color3.fromRGB(50, 120, 50))
		header.Parent = achievementsContainer
		rowCount += 1
		
		for _, entry in completedAchievements do
			local row = createAchievementRow(entry.def.ID, entry.progress, entry.def, true)
			row.LayoutOrder = rowCount
			row.Parent = achievementsContainer
			rowCount += 1
		end
	end
	
	-- Update canvas size (summary=58, headers=38, rows=68 each)
	local headerCount = (if #inProgressAchievements > 0 then 1 else 0) 
		+ (if #lockedAchievements > 0 then 1 else 0) 
		+ (if #completedAchievements > 0 then 1 else 0)
	local achievementCount = #inProgressAchievements + #lockedAchievements + #completedAchievements
	local totalHeight = 58 + (headerCount * 38) + (achievementCount * ROW_HEIGHT) + 20
	achievementsContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Populate stats tab
local function populateStats(): nil
	if not statsContainer then return end
	
	-- Clear existing
	for _, child in statsContainer:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	if not cachedStats then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No stats available"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = statsContainer
		return
	end
	
	local order = 0
	
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
	local function getNextLevelReward(level: number): (string?, string?)
		-- Check for level achievements that give rewards
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
	
	local currentLevel = cachedStats.Level or 1
	local totalXP = cachedStats.ExperiencePoints or 0
	local xpForCurrentLevel = getTotalXPForLevel(currentLevel)
	local xpForNextLevel = getTotalXPForLevel(currentLevel + 1)
	local xpInCurrentLevel = totalXP - xpForCurrentLevel
	local xpNeededForNext = xpForNextLevel - xpForCurrentLevel
	local progressToNext = if xpNeededForNext > 0 then math.min(xpInCurrentLevel / xpNeededForNext, 1) else 1
	
	-- Level & Experience Card
	local levelCard = Instance.new("Frame")
	levelCard.Name = "LevelCard"
	levelCard.Size = UDim2.new(1, -30, 0, 100)
	levelCard.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
	levelCard.BorderSizePixel = 0
	levelCard.LayoutOrder = order
	levelCard.Parent = statsContainer
	
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
	
	-- LEVEL text inside the badge at bottom
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
	
	-- Total XP (more prominent)
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
	
	order += 1
	
	-- Next Reward Card
	local rewardName, rewardItems, rewardLevel = getNextLevelReward(currentLevel)
	if rewardName then
		local rewardCard = Instance.new("Frame")
		rewardCard.Name = "RewardCard"
		rewardCard.Size = UDim2.new(1, -30, 0, 55)
		rewardCard.BackgroundColor3 = Color3.fromRGB(50, 45, 30)
		rewardCard.BorderSizePixel = 0
		rewardCard.LayoutOrder = order
		rewardCard.Parent = statsContainer
		
		local rewardCardCorner = Instance.new("UICorner")
		rewardCardCorner.CornerRadius = UDim.new(0, 8)
		rewardCardCorner.Parent = rewardCard
		
		-- Gift icon
		local giftIcon = Instance.new("TextLabel")
		giftIcon.Name = "GiftIcon"
		giftIcon.Size = UDim2.new(0, 40, 0, 40)
		giftIcon.Position = UDim2.new(0, 10, 0.5, -20)
		giftIcon.BackgroundTransparency = 1
		giftIcon.Text = "🎁"
		giftIcon.TextSize = 28
		giftIcon.Font = Enum.Font.GothamBold
		giftIcon.Parent = rewardCard
		
		-- Reward info
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
		
		order += 1
	else
		-- All level rewards claimed
		local maxedCard = Instance.new("Frame")
		maxedCard.Name = "MaxedCard"
		maxedCard.Size = UDim2.new(1, -30, 0, 40)
		maxedCard.BackgroundColor3 = Color3.fromRGB(40, 55, 40)
		maxedCard.BorderSizePixel = 0
		maxedCard.LayoutOrder = order
		maxedCard.Parent = statsContainer
		
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
		
		order += 1
	end
	
	-- Spacer
	local spacer1 = Instance.new("Frame")
	spacer1.Size = UDim2.new(1, 0, 0, 10)
	spacer1.BackgroundTransparency = 1
	spacer1.LayoutOrder = order
	spacer1.Parent = statsContainer
	order += 1
	
	-- Game stats
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
	gameHeader.Parent = statsContainer
	order += 1
	
	createStatRow("Total Captures", cachedStats.TotalCaptures or 0, order).Parent = statsContainer
	order += 1
	createStatRow("Total Wins", cachedStats.TotalWins or 0, order).Parent = statsContainer
	order += 1
	createStatRow("Total Losses", cachedStats.TotalLosses or 0, order).Parent = statsContainer
	order += 1
	createStatRow("Games Played", cachedStats.TotalGamesPlayed or 0, order).Parent = statsContainer
	order += 1
	
	-- Win rate
	local gamesPlayed = cachedStats.TotalGamesPlayed or 0
	local wins = cachedStats.TotalWins or 0
	local winRate = if gamesPlayed > 0 then math.floor((wins / gamesPlayed) * 100) else 0
	createStatRow("Win Rate", winRate .. "%", order).Parent = statsContainer
	order += 1
	
	-- Spacer
	local spacer2 = Instance.new("Frame")
	spacer2.Size = UDim2.new(1, 0, 0, 10)
	spacer2.BackgroundTransparency = 1
	spacer2.LayoutOrder = order
	spacer2.Parent = statsContainer
	order += 1
	
	-- Collection
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
	collectionHeader.Parent = statsContainer
	order += 1
	
	local capturedIndex = cachedStats.CapturedAnimalIndex or {}
	local animalCaptureCount = cachedStats.AnimalCaptureCount or {}
	local capturedCount = 0
	for _ in capturedIndex do
		capturedCount += 1
	end
	
	-- Get total animal count from library
	local totalAnimalCount = AnimalLibraryModule.GetTotalCount()
	
	-- Summary row
	createStatRow("Unique Animals Discovered", capturedCount .. "/" .. totalAnimalCount, order).Parent = statsContainer
	order += 1
	
	-- Build animalData from AnimalLibraryModule (dynamically synced)
	local animalData = {}
	for _, libraryAnimal in AnimalLibraryModule.List do
		-- Convert BrickColor to Color3 for UI
		local color = libraryAnimal.Color
		if typeof(color) == "BrickColor" then
			color = color.Color -- BrickColor has a .Color property that returns Color3
		end
		
		-- Determine rarity from spawn chance
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
		
		local animalCard = Instance.new("Frame")
		animalCard.Name = animal.ID .. "Card"
		animalCard.Size = UDim2.new(1, -30, 0, 70)
		animalCard.BackgroundColor3 = if isCaptured then Color3.fromRGB(40, 50, 45) else Color3.fromRGB(35, 35, 40)
		animalCard.BorderSizePixel = 0
		animalCard.LayoutOrder = order
		animalCard.Parent = statsContainer
		
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = animalCard
		
		-- Left color indicator / animal preview
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
		
		-- Question mark or check for undiscovered/discovered
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
		local rarityColors = {
			Common = Color3.fromRGB(150, 150, 150),
			Uncommon = Color3.fromRGB(80, 180, 80),
			Rare = Color3.fromRGB(255, 180, 50),
			Legendary = Color3.fromRGB(200, 80, 255), -- Purple for UFO aliens
		}
		
		local rarityBadge = Instance.new("TextLabel")
		rarityBadge.Name = "Rarity"
		rarityBadge.Size = UDim2.new(0, 75, 0, 16)
		rarityBadge.Position = UDim2.new(0, 70, 0, 28)
		rarityBadge.BackgroundColor3 = if isCaptured then (rarityColors[animal.Rarity] or Color3.fromRGB(100, 100, 100)) else Color3.fromRGB(60, 60, 60)
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
		
		order += 1
	end
	
	-- Add bottom padding
	local bottomSpacer = Instance.new("Frame")
	bottomSpacer.Name = "BottomSpacer"
	bottomSpacer.Size = UDim2.new(1, 0, 0, 40)
	bottomSpacer.BackgroundTransparency = 1
	bottomSpacer.LayoutOrder = order
	bottomSpacer.Parent = statsContainer
	
	-- Update canvas size for scrolling
	-- Calculate based on content: we need to account for all elements
	-- Each animal card is 70px + 8px padding = 78px
	local animalCount = AnimalLibraryModule.GetTotalCount()
	local baseHeight = 500 -- Level card, reward card, headers, stat rows, spacers
	local animalCardsHeight = animalCount * 80 -- 70px card + padding each
	local totalHeight = baseHeight + animalCardsHeight + 100 -- Extra buffer
	statsContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Populate shop tab
local function populateShop(): nil
	if not shopContainer then return end
	
	-- Clear existing
	for _, child in shopContainer:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	local order = 0
	
	-- Get current coin balance from cached inventory
	local coinBalance = 0
	if cachedInventory and cachedInventory.Items and cachedInventory.Items.COIN then
		coinBalance = cachedInventory.Items.COIN.Quantity or 0
	end
	
	-- Coin balance header
	local balanceCard = Instance.new("Frame")
	balanceCard.Name = "BalanceCard"
	balanceCard.Size = UDim2.new(1, -30, 0, 50)
	balanceCard.BackgroundColor3 = Color3.fromRGB(50, 45, 25)
	balanceCard.BorderSizePixel = 0
	balanceCard.LayoutOrder = order
	balanceCard.Parent = shopContainer
	
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
	coinBalanceLabel = Instance.new("TextLabel")
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
	
	order += 1
	
	-- Get items by category
	local categories = { "Ammo", "Food", "Tools", "Materials" }
	
	for _, category in categories do
		local items = ShopRegistry.GetItemsByCategory(category)
		if #items > 0 then
			-- Category header
			local headerColors = {
				Ammo = Color3.fromRGB(180, 80, 80),
				Food = Color3.fromRGB(80, 160, 80),
				Tools = Color3.fromRGB(80, 80, 180),
				Materials = Color3.fromRGB(180, 150, 80),
			}
			local headerIcons = {
				Ammo = "🔫",
				Food = "🍎",
				Tools = "🔧",
				Materials = "🪵",
			}
			
			local header = Instance.new("Frame")
			header.Name = category .. "Header"
			header.Size = UDim2.new(1, -30, 0, 28)
			header.BackgroundColor3 = headerColors[category] or Color3.fromRGB(80, 80, 80)
			header.BackgroundTransparency = 0.5
			header.BorderSizePixel = 0
			header.LayoutOrder = order
			header.Parent = shopContainer
			
			local headerCorner = Instance.new("UICorner")
			headerCorner.CornerRadius = UDim.new(0, 6)
			headerCorner.Parent = header
			
			local headerText = Instance.new("TextLabel")
			headerText.Size = UDim2.new(1, -10, 1, 0)
			headerText.Position = UDim2.new(0, 10, 0, 0)
			headerText.BackgroundTransparency = 1
			headerText.Text = (headerIcons[category] or "📦") .. " " .. category
			headerText.TextColor3 = Color3.fromRGB(255, 255, 255)
			headerText.TextSize = 13
			headerText.Font = Enum.Font.GothamBold
			headerText.TextXAlignment = Enum.TextXAlignment.Left
			headerText.Parent = header
			
			order += 1
			
			-- Sort items by price
			table.sort(items, function(a, b)
				return a.CoinPrice < b.CoinPrice
			end)
			
			-- Items in category
			for _, shopItem in items do
				local itemDef = ItemRegistry.GetItem(shopItem.ItemID)
				if itemDef then
					local canAfford = coinBalance >= shopItem.CoinPrice
					
					local itemRow = Instance.new("Frame")
					itemRow.Name = shopItem.ID
					itemRow.Size = UDim2.new(1, -30, 0, 55)
					itemRow.BackgroundColor3 = if canAfford then Color3.fromRGB(45, 50, 45) else Color3.fromRGB(50, 45, 45)
					itemRow.BorderSizePixel = 0
					itemRow.LayoutOrder = order
					itemRow.Parent = shopContainer
					
					local rowCorner = Instance.new("UICorner")
					rowCorner.CornerRadius = UDim.new(0, 8)
					rowCorner.Parent = itemRow
					
					-- Item icon (color based on category)
					local iconBg = Instance.new("Frame")
					iconBg.Name = "IconBg"
					iconBg.Size = UDim2.new(0, 40, 0, 40)
					iconBg.Position = UDim2.new(0, 8, 0.5, -20)
					iconBg.BackgroundColor3 = ITEM_COLORS[category] or Color3.fromRGB(100, 100, 100)
					iconBg.BorderSizePixel = 0
					iconBg.Parent = itemRow
					
					local iconCorner = Instance.new("UICorner")
					iconCorner.CornerRadius = UDim.new(0, 6)
					iconCorner.Parent = iconBg
					
					local iconLabel = Instance.new("TextLabel")
					iconLabel.Size = UDim2.new(1, 0, 1, 0)
					iconLabel.BackgroundTransparency = 1
					iconLabel.Text = headerIcons[category] or "📦"
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
					local buyButton = createTextButton(
						"BuyButton",
						if canAfford then "Buy" else "Need More",
						UDim2.new(0, 75, 0, 32),
						UDim2.new(1, -85, 0.5, -16),
						if canAfford then Color3.fromRGB(80, 160, 80) else Color3.fromRGB(80, 80, 80),
						itemRow
					)
					buyButton.TextSize = 12
					
					if canAfford then
						buyButton.MouseButton1Click:Connect(function()
							RemoteEvents.ShopPurchaseRequestEvent:FireServer(shopItem.ID)
							Log.Info(CONTEXT, "Attempting to purchase: " .. shopItem.ID)
						end)
					end
					
					order += 1
				end
			end
		end
	end
	
	-- Spacer before coin bundles
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 15)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = order
	spacer.Parent = shopContainer
	order += 1
	
	-- Coin Bundles section
	local coinHeader = Instance.new("Frame")
	coinHeader.Name = "CoinBundlesHeader"
	coinHeader.Size = UDim2.new(1, -30, 0, 32)
	coinHeader.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
	coinHeader.BackgroundTransparency = 0.3
	coinHeader.BorderSizePixel = 0
	coinHeader.LayoutOrder = order
	coinHeader.Parent = shopContainer
	
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
		bundleRow.Parent = shopContainer
		
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
		
		-- Bundle name and amount
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
		local robuxButton = createTextButton(
			"BuyRobux",
			"R$ " .. bundle.RobuxPrice,
			UDim2.new(0, 80, 0, 36),
			UDim2.new(1, -90, 0.5, -18),
			Color3.fromRGB(0, 160, 80),
			bundleRow
		)
		robuxButton.TextSize = 14
		
		robuxButton.MouseButton1Click:Connect(function()
			RemoteEvents.ShopBuyCoinsRequestEvent:FireServer(bundle.ID)
			Log.Info(CONTEXT, "Attempting to purchase coin bundle: " .. bundle.ID)
		end)
		
		order += 1
	end
	
	-- Bottom padding
	local bottomPad = Instance.new("Frame")
	bottomPad.Size = UDim2.new(1, 0, 0, 20)
	bottomPad.BackgroundTransparency = 1
	bottomPad.LayoutOrder = order
	bottomPad.Parent = shopContainer
	
	-- Calculate canvas size
	-- Balance: 58, Headers: 36, Items: 63, Bundles: 68, Spacer: 23, Bottom: 28
	local itemsCount = 0
	for _, category in categories do
		local items = ShopRegistry.GetItemsByCategory(category)
		if #items > 0 then
			itemsCount += 1 + #items  -- header + items
		end
	end
	local bundleCount = #bundles
	local totalHeight = 58 + (itemsCount * 36) + 23 + 40 + (bundleCount * 68) + 28
	-- Recalculate more accurately
	local calcHeight = 58 -- balance card
	for _, category in categories do
		local items = ShopRegistry.GetItemsByCategory(category)
		if #items > 0 then
			calcHeight += 36 -- header
			calcHeight += #items * 63 -- items
		end
	end
	calcHeight += 23 + 40 -- spacer + coin header
	calcHeight += #bundles * 68 -- bundles
	calcHeight += 28 -- bottom pad
	
	shopContainer.CanvasSize = UDim2.new(0, 0, 0, calcHeight)
end

-- Switch between tabs
function PlayerMenuController.SwitchTab(tabName: string): nil
	currentTab = tabName
	
	-- Update tab button colors
	for name, button in tabButtons do
		button.BackgroundColor3 = if name == tabName then TAB_COLORS.Selected else TAB_COLORS.Unselected
	end
	
	-- Show/hide containers
	if inventoryContainer then
		inventoryContainer.Visible = tabName == "Inventory"
	end
	if achievementsContainer then
		achievementsContainer.Visible = tabName == "Achievements"
	end
	if statsContainer then
		statsContainer.Visible = tabName == "Stats"
	end
	if shopContainer then
		shopContainer.Visible = tabName == "Shop"
	end
	
	-- Populate content
	if tabName == "Inventory" then
		populateInventory()
	elseif tabName == "Achievements" then
		populateAchievements()
	elseif tabName == "Stats" then
		populateStats()
	elseif tabName == "Shop" then
		populateShop()
	end
end

-- Animate menu open
local function animateOpen(): nil
	if not menuFrame then return end
	
	menuFrame.Visible = true
	menuFrame.Position = MENU_POSITION_CLOSED
	
	local tween = TweenService:Create(
		menuFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = MENU_POSITION_OPEN }
	)
	tween:Play()
end

-- Animate menu close
local function animateClose(): nil
	if not menuFrame then return end
	
	local tween = TweenService:Create(
		menuFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = MENU_POSITION_CLOSED }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if menuFrame then
			menuFrame.Visible = false
		end
	end)
end

-- Open the menu
function PlayerMenuController.OpenMenu(): nil
	if isMenuOpen then return end
	isMenuOpen = true
	
	Log.Info(CONTEXT, "Opening player menu")
	animateOpen()
	PlayerMenuController.SwitchTab(currentTab)
end

-- Close the menu
function PlayerMenuController.CloseMenu(): nil
	if not isMenuOpen then return end
	isMenuOpen = false
	
	Log.Info(CONTEXT, "Closing player menu")
	animateClose()
end

-- Toggle menu
function PlayerMenuController.ToggleMenu(): nil
	if isMenuOpen then
		PlayerMenuController.CloseMenu()
	else
		PlayerMenuController.OpenMenu()
	end
end

-- Handle keyboard input
local function onInputBegan(input: InputObject, gameProcessed: boolean): nil
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.I then
		PlayerMenuController.ToggleMenu()
	elseif input.KeyCode == Enum.KeyCode.Escape and isMenuOpen then
		PlayerMenuController.CloseMenu()
	end
end

-- Initialize
function PlayerMenuController.Init(): nil
	if initialized then return end
	initialized = true
	
	Log.Info(CONTEXT, "PlayerMenuController.Init() called")
	
	createMenuGui()
	
	-- Connect input
	UserInputService.InputBegan:Connect(onInputBegan)
	
	-- Listen for inventory updates
	RemoteEvents.InventoryUpdatedEvent.OnClientEvent:Connect(function(inventory: any)
		cachedInventory = inventory
		if isMenuOpen then
			if currentTab == "Inventory" then
				populateInventory()
			elseif currentTab == "Shop" then
				-- Refresh shop to update coin balance and affordability
				populateShop()
			end
		end
	end)
	
	-- Listen for stats updates
	RemoteEvents.StatsUpdatedEvent.OnClientEvent:Connect(function(stats: any)
		cachedStats = stats
		-- Also extract achievements if included
		if stats and stats.Achievements then
			cachedAchievements = stats.Achievements
		end
		if isMenuOpen then
			if currentTab == "Achievements" then
				populateAchievements()
			elseif currentTab == "Stats" then
				populateStats()
			end
		end
	end)
	
	-- Listen for achievement unlocks to update progress
	RemoteEvents.AchievementUnlockedEvent.OnClientEvent:Connect(function(achievementID: string, achievementName: string)
		if cachedAchievements then
			cachedAchievements[achievementID] = {
				ID = achievementID,
				Completed = true,
				CurrentValue = 1,
				TargetValue = 1,
			}
		end
		if isMenuOpen and currentTab == "Achievements" then
			populateAchievements()
		end
	end)
	
	-- Listen for shop purchase results
	RemoteEvents.ShopPurchaseResultEvent.OnClientEvent:Connect(function(success: boolean, itemID: string, quantity: number, itemName: string)
		Log.Info(CONTEXT, "Shop result: " .. tostring(success) .. " - " .. itemName)
		
		-- Show feedback to user (toast notification)
		if menuGui then
			-- Create a simple feedback toast
			local existingToast = menuGui:FindFirstChild("ShopToast")
			if existingToast then
				existingToast:Destroy()
			end
			
			local message = if success 
				then string.format("Purchased %dx %s!", quantity, itemName)
				else "Purchase failed: " .. itemName
			
			local toast = Instance.new("Frame")
			toast.Name = "ShopToast"
			toast.Size = UDim2.new(0, 280, 0, 40)
			toast.Position = UDim2.new(0.5, -140, 0, 80)
			toast.BackgroundColor3 = if success then Color3.fromRGB(50, 120, 50) else Color3.fromRGB(150, 50, 50)
			toast.BorderSizePixel = 0
			toast.ZIndex = 100
			toast.Parent = menuGui
			
			local toastCorner = Instance.new("UICorner")
			toastCorner.CornerRadius = UDim.new(0, 8)
			toastCorner.Parent = toast
			
			local toastText = Instance.new("TextLabel")
			toastText.Size = UDim2.new(1, -20, 1, 0)
			toastText.Position = UDim2.new(0, 10, 0, 0)
			toastText.BackgroundTransparency = 1
			toastText.Text = (if success then "✅ " else "❌ ") .. message
			toastText.TextColor3 = Color3.fromRGB(255, 255, 255)
			toastText.TextSize = 14
			toastText.Font = Enum.Font.GothamBold
			toastText.TextXAlignment = Enum.TextXAlignment.Left
			toastText.ZIndex = 101
			toastText.Parent = toast
			
			-- Auto-hide after 3 seconds
			task.delay(3, function()
				if toast and toast.Parent then
					local fadeTween = TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
					local textFade = TweenService:Create(toastText, TweenInfo.new(0.3), { TextTransparency = 1 })
					fadeTween:Play()
					textFade:Play()
					fadeTween.Completed:Connect(function()
						if toast and toast.Parent then
							toast:Destroy()
						end
					end)
				end
			end)
		end
	end)
end

-- Expose for external updates
function PlayerMenuController.UpdateInventory(inventory: any): nil
	cachedInventory = inventory
end

function PlayerMenuController.UpdateStats(stats: any): nil
	cachedStats = stats
	if stats and stats.Achievements then
		cachedAchievements = stats.Achievements
	end
end

function PlayerMenuController.IsOpen(): boolean
	return isMenuOpen
end

return PlayerMenuController
