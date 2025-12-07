--!strict
-- PlayerMenuController.luau
-- Main player menu with Inventory, Shop, Achievements, and Stats tabs
-- Opens with 'I' key or menu button
-- Refactored to use modular tab components

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

-- Tab modules
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local InventoryTab = require(script.Parent:WaitForChild("InventoryTab"))
local AchievementsTab = require(script.Parent:WaitForChild("AchievementsTab"))
local StatsTab = require(script.Parent:WaitForChild("StatsTab"))
local ShopTab = require(script.Parent:WaitForChild("ShopTab"))
local AnimalsTab = require(script.Parent:WaitForChild("AnimalsTab"))

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
local cachedFavoriteAnimals: { string } = {}
local canModifyFavorites: boolean = true

-- UI references
local menuGui: ScreenGui? = nil
local menuFrame: Frame? = nil
local inventoryContainer: ScrollingFrame? = nil
local achievementsContainer: ScrollingFrame? = nil
local statsContainer: ScrollingFrame? = nil
local shopContainer: ScrollingFrame? = nil
local animalsContainer: ScrollingFrame? = nil
local tabButtons: { [string]: TextButton } = {}
local coinBalanceLabel: TextLabel? = nil

-- UI Constants
local MENU_SIZE = UDim2.new(0, 550, 0, 450)
local MENU_POSITION_CLOSED = UDim2.new(0.5, -275, 1.5, 0)
local MENU_POSITION_OPEN = UDim2.new(0.5, -275, 0.5, -225)

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
	menuFrame = UIHelpers.createRoundedFrame("MenuFrame", MENU_SIZE, MENU_POSITION_CLOSED, Color3.fromRGB(40, 40, 40), menuGui)
	menuFrame.Visible = false
	
	-- Title bar
	local titleBar = UIHelpers.createRoundedFrame("TitleBar", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), Color3.fromRGB(30, 30, 30), menuFrame)
	
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
	local closeButton = UIHelpers.createTextButton("CloseButton", "X", UDim2.new(0, 35, 0, 35), UDim2.new(1, -40, 0.5, -17), Color3.fromRGB(180, 60, 60), titleBar)
	closeButton.MouseButton1Click:Connect(function()
		PlayerMenuController.CloseMenu()
	end)
	
	-- Tab bar
	local tabBar = UIHelpers.createRoundedFrame("TabBar", UDim2.new(1, -20, 0, 35), UDim2.new(0, 10, 0, 50), Color3.fromRGB(30, 30, 30), menuFrame)
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabBar
	
	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 5)
	tabPadding.PaddingTop = UDim.new(0, 3)
	tabPadding.Parent = tabBar
	
	-- Create tabs
	local tabs = { "Inventory", "Shop", "Animals", "Achievements", "Stats" }
	for _, tabName in ipairs(tabs) do
		local isSelected = tabName == currentTab
		local tabWidth = if tabName == "Achievements" then 95 elseif tabName == "Animals" then 70 else 75
		local button = UIHelpers.createTextButton(
			tabName .. "Tab",
			tabName,
			UDim2.new(0, tabWidth, 0, 28),
			UDim2.new(0, 0, 0, 0),
			if isSelected then UIHelpers.TAB_COLORS.Selected else UIHelpers.TAB_COLORS.Unselected,
			tabBar
		)
		button.TextSize = 12
		tabButtons[tabName] = button
		
		button.MouseButton1Click:Connect(function()
			PlayerMenuController.SwitchTab(tabName)
		end)
	end
	
	-- Content area
	local contentArea = UIHelpers.createRoundedFrame("ContentArea", UDim2.new(1, -20, 1, -100), UDim2.new(0, 10, 0, 95), Color3.fromRGB(50, 50, 50), menuFrame)
	
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
	
	-- Animals container (scrolling)
	animalsContainer = Instance.new("ScrollingFrame")
	animalsContainer.Name = "AnimalsContainer"
	animalsContainer.Size = UDim2.new(1, -10, 1, -10)
	animalsContainer.Position = UDim2.new(0, 5, 0, 5)
	animalsContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	animalsContainer.BackgroundTransparency = 0
	animalsContainer.BorderSizePixel = 0
	animalsContainer.ScrollBarThickness = 6
	animalsContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	animalsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	animalsContainer.Visible = false
	animalsContainer.Parent = contentArea
	
	local animalsCorner = Instance.new("UICorner")
	animalsCorner.CornerRadius = UDim.new(0, 8)
	animalsCorner.Parent = animalsContainer
	
	local animalsList = Instance.new("UIListLayout")
	animalsList.Padding = UDim.new(0, 8)
	animalsList.SortOrder = Enum.SortOrder.LayoutOrder
	animalsList.Parent = animalsContainer
	
	local animalsPadding = Instance.new("UIPadding")
	animalsPadding.PaddingLeft = UDim.new(0, 15)
	animalsPadding.PaddingTop = UDim.new(0, 15)
	animalsPadding.PaddingRight = UDim.new(0, 15)
	animalsPadding.PaddingBottom = UDim.new(0, 15)
	animalsPadding.Parent = animalsContainer
	
	-- Open menu button (bottom-left corner)
	local openButton = UIHelpers.createTextButton("OpenMenuButton", "📦", UDim2.new(0, 50, 0, 50), UDim2.new(0, 10, 1, -60), Color3.fromRGB(60, 60, 60), menuGui :: ScreenGui)
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

-- Populate tab content using modular tab components
local function populateInventory(): nil
	if inventoryContainer then
		InventoryTab.populate(inventoryContainer, cachedInventory)
	end
end

local function populateAchievements(): nil
	if achievementsContainer then
		AchievementsTab.populate(achievementsContainer, cachedAchievements)
	end
end

local function populateStats(): nil
	if statsContainer then
		StatsTab.populate(statsContainer, {
			cachedStats = cachedStats,
			cachedFavoriteAnimals = cachedFavoriteAnimals,
			canModifyFavorites = canModifyFavorites,
			menuGui = menuGui,
			cachedInventory = cachedInventory,
		})
	end
end

local function populateShop(): nil
	if shopContainer then
		coinBalanceLabel = ShopTab.populate(shopContainer, {
			cachedInventory = cachedInventory,
		})
	end
end

local function populateAnimals(): nil
	if animalsContainer then
		AnimalsTab.populate(animalsContainer, {
			cachedStats = cachedStats,
			cachedFavoriteAnimals = cachedFavoriteAnimals,
			canModifyFavorites = canModifyFavorites,
			menuGui = menuGui,
		})
	end
end

-- Switch between tabs
function PlayerMenuController.SwitchTab(tabName: string): nil
	currentTab = tabName
	
	-- Update tab button colors
	for name, button in tabButtons do
		button.BackgroundColor3 = if name == tabName then UIHelpers.TAB_COLORS.Selected else UIHelpers.TAB_COLORS.Unselected
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
	if animalsContainer then
		animalsContainer.Visible = tabName == "Animals"
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
	elseif tabName == "Animals" then
		populateAnimals()
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
	
	-- Always request fresh data from server when opening menu
	-- This ensures we have the latest data, especially in Arena place
	Log.Info(CONTEXT, "Requesting player data from server")
	RemoteEvents.RequestPlayerDataEvent:FireServer()
	
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
				populateShop()
			elseif currentTab == "Stats" then
				populateStats()
			end
		end
	end)
	
	-- Listen for stats updates
	RemoteEvents.StatsUpdatedEvent.OnClientEvent:Connect(function(stats: any)
		cachedStats = stats
		if stats and stats.Achievements then
			cachedAchievements = stats.Achievements
		end
		if stats and stats.FavoriteAnimals then
			cachedFavoriteAnimals = stats.FavoriteAnimals
		end
		if isMenuOpen then
			if currentTab == "Achievements" then
				populateAchievements()
			elseif currentTab == "Stats" then
				populateStats()
			elseif currentTab == "Animals" then
				populateAnimals()
			end
		end
	end)
	
	-- Listen for achievement unlocks
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
		
		if menuGui then
			local message = if success 
				then string.format("✅ Purchased %dx %s!", quantity, itemName)
				else "❌ Purchase failed: " .. itemName
			local color = if success then Color3.fromRGB(50, 120, 50) else Color3.fromRGB(150, 50, 50)
			UIHelpers.showToast(menuGui, message, color, 3)
		end
	end)
	
	-- Listen for favorite animals updates
	RemoteEvents.FavoriteAnimalsUpdatedEvent.OnClientEvent:Connect(function(favorites: { string }, canModify: boolean, success: boolean?, errorMsg: string?)
		Log.Info(CONTEXT, string.format("Favorite animals updated: %d favorites, canModify: %s", #favorites, tostring(canModify)))
		
		cachedFavoriteAnimals = favorites
		canModifyFavorites = canModify
		
		if isMenuOpen then
			if currentTab == "Stats" then
				populateStats()
			elseif currentTab == "Animals" then
				populateAnimals()
			end
		end
		
		-- Show toast for success/failure on toggle
		if success ~= nil and menuGui then
			if success then
				UIHelpers.showToast(menuGui, "⭐ Favorites updated!", Color3.fromRGB(50, 120, 80), 2)
			elseif errorMsg then
				UIHelpers.showToast(menuGui, "❌ " .. errorMsg, Color3.fromRGB(150, 60, 50), 3)
			end
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
	if stats and stats.FavoriteAnimals then
		cachedFavoriteAnimals = stats.FavoriteAnimals
	end
end

function PlayerMenuController.IsOpen(): boolean
	return isMenuOpen
end

return PlayerMenuController
