--!strict
-- InventoryTab.luau
-- Inventory tab UI for PlayerMenu

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("ItemRegistry"))
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local InventoryTab = {}

-- Create an inventory item cell
local function createInventoryItem(itemData: any, definition: any): Frame
	local cell = Instance.new("Frame")
	cell.Name = definition.ID
	cell.Size = UDim2.new(0, 80, 0, 90)
	cell.BackgroundColor3 = UIHelpers.ITEM_COLORS[definition.Category] or Color3.fromRGB(80, 80, 80)
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
	local quantityBadge = UIHelpers.createRoundedFrame("QuantityBadge", UDim2.new(0, 35, 0, 18), UDim2.new(0.5, -17, 1, -22), Color3.fromRGB(30, 30, 30), cell)
	
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

-- Populate the inventory container
function InventoryTab.populate(container: ScrollingFrame, cachedInventory: { Items: { [string]: any } }?)
	if not container then return end
	
	-- Clear existing items
	for _, child in container:GetChildren() do
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
		emptyLabel.Parent = container
		return
	end
	
	local itemCount = 0
	for itemID, itemData in cachedInventory.Items do
		-- Skip coins - they are displayed in Stats tab, not as inventory items
		if itemID == "COIN" then
			continue
		end
		
		local definition = ItemRegistry.GetItem(itemID)
		if definition and itemData.Quantity > 0 then
			local cell = createInventoryItem(itemData, definition)
			cell.LayoutOrder = itemCount
			cell.Parent = container
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
		emptyLabel.Parent = container
	end
	
	-- Update canvas size
	local grid = container:FindFirstChildOfClass("UIGridLayout")
	if grid then
		local rows = math.ceil(itemCount / 5)
		container.CanvasSize = UDim2.new(0, 0, 0, rows * 98 + 10)
	end
end

return InventoryTab
