--!strict
-- UIHelpers.luau
-- Shared UI helper functions for PlayerMenu tabs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Lazy load AnimalPreviewBuilder to avoid circular dependencies
local AnimalPreviewBuilder = nil
local function getAnimalPreviewBuilder()
	if not AnimalPreviewBuilder then
		AnimalPreviewBuilder = require(ReplicatedStorage.Shared.ui.AnimalPreviewBuilder)
	end
	return AnimalPreviewBuilder
end

local UIHelpers = {}

-- Color constants shared across tabs
UIHelpers.TAB_COLORS = {
	Selected = Color3.fromRGB(70, 130, 180),
	Unselected = Color3.fromRGB(50, 50, 50),
}

UIHelpers.ITEM_COLORS = {
	Ammo = Color3.fromRGB(200, 100, 100),
	Food = Color3.fromRGB(100, 200, 100),
	Tools = Color3.fromRGB(100, 100, 200),
	Materials = Color3.fromRGB(200, 180, 100),
	Special = Color3.fromRGB(200, 150, 255),
}

UIHelpers.ACHIEVEMENT_COLORS = {
	Completed = Color3.fromRGB(100, 200, 100),
	InProgress = Color3.fromRGB(200, 200, 100),
	Locked = Color3.fromRGB(100, 100, 100),
}

UIHelpers.RARITY_COLORS = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 180, 80),
	Rare = Color3.fromRGB(255, 180, 50),
	Legendary = Color3.fromRGB(200, 80, 255),
}

-- Helper: Create rounded frame
function UIHelpers.createRoundedFrame(name: string, size: UDim2, position: UDim2, color: Color3, parent: Instance): Frame
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
function UIHelpers.createTextButton(name: string, text: string, size: UDim2, position: UDim2, color: Color3, parent: Instance): TextButton
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

-- Helper: Create stat row
function UIHelpers.createStatRow(name: string, value: any, order: number): Frame
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

-- Helper: Show toast notification
function UIHelpers.showToast(parent: ScreenGui, message: string, bgColor: Color3?, duration: number?)
	local color = bgColor or Color3.fromRGB(150, 100, 50)
	local dur = duration or 2
	
	-- Remove existing toast
	local existingToast = parent:FindFirstChild("Toast")
	if existingToast then
		existingToast:Destroy()
	end
	
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.new(0, 320, 0, 40)
	toast.Position = UDim2.new(0.5, -160, 0, 80)
	toast.BackgroundColor3 = color
	toast.BorderSizePixel = 0
	toast.ZIndex = 100
	toast.Parent = parent
	
	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toast
	
	local toastText = Instance.new("TextLabel")
	toastText.Size = UDim2.new(1, -20, 1, 0)
	toastText.Position = UDim2.new(0, 10, 0, 0)
	toastText.BackgroundTransparency = 1
	toastText.Text = message
	toastText.TextColor3 = Color3.fromRGB(255, 255, 255)
	toastText.TextSize = 12
	toastText.Font = Enum.Font.GothamBold
	toastText.TextXAlignment = Enum.TextXAlignment.Left
	toastText.ZIndex = 101
	toastText.Parent = toast
	
	task.delay(dur, function()
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
	
	return toast
end

-- Helper: Clear container children (frames and labels)
function UIHelpers.clearContainer(container: ScrollingFrame)
	for _, child in container:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

-- Helper: Create an info popup modal with optional animal preview
function UIHelpers.showInfoPopup(
	parent: ScreenGui,
	title: string,
	description: string,
	stats: { { name: string, value: string } }?,
	accentColor: Color3?,
	animalID: string?  -- Optional: if provided, shows a large animal preview
)
	local color = accentColor or Color3.fromRGB(100, 150, 200)
	
	-- Remove existing popup
	local existingPopup = parent:FindFirstChild("InfoPopup")
	if existingPopup then
		existingPopup:Destroy()
	end
	
	-- Backdrop (semi-transparent dark overlay)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "InfoPopup"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.Position = UDim2.new(0, 0, 0, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.ZIndex = 200
	backdrop.Parent = parent
	
	-- Close on backdrop click
	local backdropButton = Instance.new("TextButton")
	backdropButton.Size = UDim2.new(1, 0, 1, 0)
	backdropButton.BackgroundTransparency = 1
	backdropButton.Text = ""
	backdropButton.ZIndex = 200
	backdropButton.Parent = backdrop
	backdropButton.MouseButton1Click:Connect(function()
		backdrop:Destroy()
	end)
	
	-- Calculate popup height based on whether we have an animal preview
	local popupHeight = if animalID then 480 else 280
	local popupWidth = if animalID then 400 else 360
	
	-- Main popup card
	local popup = Instance.new("Frame")
	popup.Name = "PopupCard"
	popup.Size = UDim2.new(0, popupWidth, 0, popupHeight)
	popup.Position = UDim2.new(0.5, -popupWidth/2, 0.5, -popupHeight/2)
	popup.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
	popup.BorderSizePixel = 0
	popup.ZIndex = 210
	popup.Parent = backdrop
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 12)
	popupCorner.Parent = popup
	
	-- Color accent bar at top
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(1, 0, 0, 4)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = color
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 211
	accentBar.Parent = popup
	
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 12)
	accentCorner.Parent = accentBar
	
	-- Hide bottom corners of accent bar
	local accentBottom = Instance.new("Frame")
	accentBottom.Size = UDim2.new(1, 0, 0.5, 0)
	accentBottom.Position = UDim2.new(0, 0, 0.5, 0)
	accentBottom.BackgroundColor3 = color
	accentBottom.BorderSizePixel = 0
	accentBottom.ZIndex = 211
	accentBottom.Parent = accentBar
	
	-- Close button (X)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 32, 0, 32)
	closeButton.Position = UDim2.new(1, -40, 0, 8)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(200, 150, 150)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = 212
	closeButton.Parent = popup
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		backdrop:Destroy()
	end)
	
	-- Create scrollable content container for everything below the close button
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "ContentScroll"
	contentScroll.Size = UDim2.new(1, 0, 1, -48)  -- Leave room for close button
	contentScroll.Position = UDim2.new(0, 0, 0, 8)
	contentScroll.BackgroundTransparency = 1
	contentScroll.BorderSizePixel = 0
	contentScroll.ScrollBarThickness = 6
	contentScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentScroll.ZIndex = 211
	contentScroll.Parent = popup
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.Padding = UDim.new(0, 12)
	contentLayout.Parent = contentScroll
	
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 16)
	contentPadding.PaddingRight = UDim.new(0, 16)
	contentPadding.PaddingTop = UDim.new(0, 8)
	contentPadding.PaddingBottom = UDim.new(0, 16)
	contentPadding.Parent = contentScroll
	
	-- Large animal preview (if animalID provided)
	if animalID then
		local previewContainer = Instance.new("Frame")
		previewContainer.Name = "PreviewContainer"
		previewContainer.Size = UDim2.new(0, 160, 0, 160)
		previewContainer.BackgroundColor3 = Color3.fromRGB(28, 30, 35)
		previewContainer.BorderSizePixel = 0
		previewContainer.LayoutOrder = 1
		previewContainer.ZIndex = 211
		previewContainer.Parent = contentScroll
		
		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 8)
		previewCorner.Parent = previewContainer
		
		-- Add ViewportFrame with animal preview
		local PreviewBuilder = getAnimalPreviewBuilder()
		PreviewBuilder.CreateViewportPreview(animalID, UDim2.new(1, 0, 1, 0), previewContainer)
	end
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = 211
	titleLabel.Parent = contentScroll
	
	-- Description container (expands based on content)
	local descContainer = Instance.new("Frame")
	descContainer.Name = "DescriptionContainer"
	descContainer.Size = UDim2.new(1, 0, 0, 0)
	descContainer.AutomaticSize = Enum.AutomaticSize.Y
	descContainer.BackgroundColor3 = Color3.fromRGB(28, 30, 35)
	descContainer.BorderSizePixel = 0
	descContainer.LayoutOrder = 3
	descContainer.ZIndex = 211
	descContainer.Parent = contentScroll
	
	local descCorner = Instance.new("UICorner")
	descCorner.CornerRadius = UDim.new(0, 6)
	descCorner.Parent = descContainer
	
	local descPadding = Instance.new("UIPadding")
	descPadding.PaddingLeft = UDim.new(0, 10)
	descPadding.PaddingRight = UDim.new(0, 10)
	descPadding.PaddingTop = UDim.new(0, 8)
	descPadding.PaddingBottom = UDim.new(0, 8)
	descPadding.Parent = descContainer
	
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, 0, 0, 0)
	descLabel.AutomaticSize = Enum.AutomaticSize.Y
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.ZIndex = 212
	descLabel.Parent = descContainer
	
	-- Stats section (if provided)
	if stats and #stats > 0 then
		local statsFrame = Instance.new("Frame")
		statsFrame.Name = "StatsFrame"
		statsFrame.Size = UDim2.new(1, 0, 0, 0)
		statsFrame.AutomaticSize = Enum.AutomaticSize.Y
		statsFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 35)
		statsFrame.BorderSizePixel = 0
		statsFrame.LayoutOrder = 4
		statsFrame.ZIndex = 211
		statsFrame.Parent = contentScroll
		
		local statsCorner = Instance.new("UICorner")
		statsCorner.CornerRadius = UDim.new(0, 6)
		statsCorner.Parent = statsFrame
		
		local statsLayout = Instance.new("UIListLayout")
		statsLayout.FillDirection = Enum.FillDirection.Vertical
		statsLayout.Padding = UDim.new(0, 4)
		statsLayout.Parent = statsFrame
		
		local statsPadding = Instance.new("UIPadding")
		statsPadding.PaddingLeft = UDim.new(0, 10)
		statsPadding.PaddingRight = UDim.new(0, 10)
		statsPadding.PaddingTop = UDim.new(0, 8)
		statsPadding.PaddingBottom = UDim.new(0, 8)
		statsPadding.Parent = statsFrame
		
		for i, stat in stats do
			local statRow = Instance.new("Frame")
			statRow.Name = "Stat" .. i
			statRow.Size = UDim2.new(1, 0, 0, 20)
			statRow.BackgroundTransparency = 1
			statRow.LayoutOrder = i
			statRow.ZIndex = 212
			statRow.Parent = statsFrame
			
			local statName = Instance.new("TextLabel")
			statName.Size = UDim2.new(0.6, 0, 1, 0)
			statName.BackgroundTransparency = 1
			statName.Text = stat.name
			statName.TextColor3 = Color3.fromRGB(160, 160, 160)
			statName.TextSize = 12
			statName.Font = Enum.Font.Gotham
			statName.TextXAlignment = Enum.TextXAlignment.Left
			statName.ZIndex = 213
			statName.Parent = statRow
			
			local statValue = Instance.new("TextLabel")
			statValue.Size = UDim2.new(0.4, 0, 1, 0)
			statValue.Position = UDim2.new(0.6, 0, 0, 0)
			statValue.BackgroundTransparency = 1
			statValue.Text = stat.value
			statValue.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Always white
			statValue.TextSize = 12
			statValue.Font = Enum.Font.GothamBold
			statValue.TextXAlignment = Enum.TextXAlignment.Right
			statValue.ZIndex = 213
			statValue.Parent = statRow
		end
	end
	
	return backdrop
end

-- Helper: Create circular info button
function UIHelpers.createInfoButton(size: UDim2, position: UDim2, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = "InfoButton"
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
	button.BorderSizePixel = 0
	button.Text = "i"
	button.TextColor3 = Color3.fromRGB(200, 220, 255)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)  -- Make it circular
	corner.Parent = button
	
	return button
end

return UIHelpers
