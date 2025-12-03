--!strict
-- CoinsController.luau
-- Displays the player's coin count in the HUD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "CoinsController"
local player: Player = Players.LocalPlayer

local CoinsController = {}

-- UI references
local coinsGui: ScreenGui? = nil
local coinsLabel: TextLabel? = nil
local coinsIcon: ImageLabel? = nil

-- Current coin count
local currentCoins: number = 0

-- Animation state
local isAnimating: boolean = false

-- Initialization guard
local initialized: boolean = false

-- Format coin number with commas (e.g., 1,234,567)
local function formatNumber(num: number): string
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- Update the coins display
local function updateCoinsDisplay(): nil
	if coinsLabel then
		coinsLabel.Text = formatNumber(currentCoins)
	end
end

-- Animate coin gain (optional visual feedback)
local function animateCoinGain(amount: number): nil
	if isAnimating or not coinsLabel then return end
	isAnimating = true
	
	-- Store original properties
	local originalSize = coinsLabel.Size
	local originalColor = coinsLabel.TextColor3
	
	-- Flash green and scale up
	coinsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	coinsLabel.Size = UDim2.new(
		originalSize.X.Scale * 1.2, originalSize.X.Offset,
		originalSize.Y.Scale * 1.2, originalSize.Y.Offset
	)
	
	-- Animate back to normal
	task.delay(0.15, function()
		if coinsLabel then
			coinsLabel.Size = originalSize
			coinsLabel.TextColor3 = originalColor
		end
		isAnimating = false
	end)
end

-- Create the coins GUI programmatically if not found in StarterGui
local function createCoinsGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if already exists from Studio
	local existing = playerGui:FindFirstChild("CoinsGui")
	if existing and existing:IsA("ScreenGui") then
		coinsGui = existing :: ScreenGui
		
		local label = coinsGui:FindFirstChild("CoinsLabel", true)
		if label and label:IsA("TextLabel") then
			coinsLabel = label :: TextLabel
		end
		
		local icon = coinsGui:FindFirstChild("CoinsIcon", true)
		if icon and icon:IsA("ImageLabel") then
			coinsIcon = icon :: ImageLabel
		end
		
		Log.Info(CONTEXT, "Found CoinsGui from Studio")
		return
	end
	
	-- Create GUI programmatically
	Log.Info(CONTEXT, "Creating CoinsGui programmatically")
	
	coinsGui = Instance.new("ScreenGui")
	coinsGui.Name = "CoinsGui"
	coinsGui.ResetOnSpawn = false
	coinsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	coinsGui.Parent = playerGui
	
	-- Container frame (top-right corner)
	local container = Instance.new("Frame")
	container.Name = "CoinsContainer"
	container.Size = UDim2.new(0, 150, 0, 40)
	container.Position = UDim2.new(1, -160, 0, 10)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = coinsGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	-- Coin icon (using a simple circle as placeholder)
	coinsIcon = Instance.new("ImageLabel")
	coinsIcon.Name = "CoinsIcon"
	coinsIcon.Size = UDim2.new(0, 28, 0, 28)
	coinsIcon.Position = UDim2.new(0, 8, 0.5, -14)
	coinsIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	coinsIcon.BackgroundTransparency = 0
	coinsIcon.BorderSizePixel = 0
	coinsIcon.Image = ""  -- Can be set to a coin image asset ID
	coinsIcon.Parent = container
	
	-- Make icon circular
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = coinsIcon
	
	-- Coin symbol on icon
	local coinSymbol = Instance.new("TextLabel")
	coinSymbol.Name = "CoinSymbol"
	coinSymbol.Size = UDim2.new(1, 0, 1, 0)
	coinSymbol.BackgroundTransparency = 1
	coinSymbol.Text = "$"
	coinSymbol.TextColor3 = Color3.fromRGB(150, 100, 0)
	coinSymbol.TextScaled = true
	coinSymbol.Font = Enum.Font.GothamBold
	coinSymbol.Parent = coinsIcon
	
	-- Coins text label
	coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0, 100, 1, 0)
	coinsLabel.Position = UDim2.new(0, 44, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextSize = 22
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Parent = container
	
	-- Stroke for better visibility
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = coinsLabel
	
	Log.Info(CONTEXT, "CoinsGui created")
end

-- Listen for coins awarded event (just for animation, not for updating count)
-- The actual count comes from InventoryUpdatedEvent which fires right after
RemoteEvents.CoinsAwardedEvent.OnClientEvent:Connect(function(coins: number, multiplier: number, isWinner: boolean)
	-- Only trigger animation - don't update count here since InventoryUpdatedEvent handles it
	animateCoinGain(coins)
end)

-- Listen for inventory updates to sync coin count (source of truth)
RemoteEvents.InventoryUpdatedEvent.OnClientEvent:Connect(function(inventory: any)
	if inventory and inventory.Items then
		local coinItem = inventory.Items.COIN
		local newCoins = if coinItem then coinItem.Quantity else 0
		if newCoins ~= currentCoins then
			Log.Info(CONTEXT, string.format("Coins updated: %d -> %d", currentCoins, newCoins))
			currentCoins = newCoins
			updateCoinsDisplay()
		end
	else
		-- No items means 0 coins
		if currentCoins ~= 0 then
			currentCoins = 0
			updateCoinsDisplay()
		end
	end
end)

function CoinsController.Init(): nil
	if initialized then return end
	initialized = true
	
	Log.Info(CONTEXT, "CoinsController.Init() called")
	createCoinsGui()
	updateCoinsDisplay()
end

-- Get current coin count (for other controllers)
function CoinsController.GetCoins(): number
	return currentCoins
end

-- Set coins (for initialization from server data)
function CoinsController.SetCoins(amount: number): nil
	currentCoins = amount
	updateCoinsDisplay()
end

return CoinsController
