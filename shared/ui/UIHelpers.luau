--!strict
-- UIHelpers.luau
-- Shared UI helper functions for PlayerMenu tabs

local TweenService = game:GetService("TweenService")

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

return UIHelpers
