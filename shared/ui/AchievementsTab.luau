--!strict
-- AchievementsTab.luau
-- Achievements tab UI for PlayerMenu

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementRegistry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AchievementRegistry"))
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local AchievementsTab = {}

-- Create an achievement row
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

-- Helper to create section header
local function createSectionHeader(title: string, icon: string, count: number, color: Color3, layoutOrder: number): Frame
	local header = Instance.new("Frame")
	header.Name = title .. "Header"
	header.Size = UDim2.new(1, -10, 0, 30)
	header.BackgroundColor3 = color
	header.BackgroundTransparency = 0.5
	header.BorderSizePixel = 0
	header.LayoutOrder = layoutOrder
	
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

-- Populate the achievements container
function AchievementsTab.populate(container: ScrollingFrame, cachedAchievements: { [string]: any }?)
	if not container then return end
	
	UIHelpers.clearContainer(container)
	
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
	summaryFrame.Parent = container
	
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
	
	-- IN PROGRESS section (show first - most relevant)
	if #inProgressAchievements > 0 then
		local header = createSectionHeader("In Progress", "⏳", #inProgressAchievements, Color3.fromRGB(180, 150, 50), rowCount)
		header.Parent = container
		rowCount += 1
		
		for _, entry in inProgressAchievements do
			local row = createAchievementRow(entry.def.ID, entry.progress, entry.def, false)
			row.LayoutOrder = rowCount
			row.Parent = container
			rowCount += 1
		end
	end
	
	-- LOCKED section (not started)
	if #lockedAchievements > 0 then
		local header = createSectionHeader("Not Started", "🔒", #lockedAchievements, Color3.fromRGB(80, 80, 100), rowCount)
		header.Parent = container
		rowCount += 1
		
		for _, entry in lockedAchievements do
			local row = createAchievementRow(entry.def.ID, entry.progress, entry.def, false)
			row.LayoutOrder = rowCount
			row.Parent = container
			rowCount += 1
		end
	end
	
	-- COMPLETED section (at bottom)
	if #completedAchievements > 0 then
		local header = createSectionHeader("Completed", "✅", #completedAchievements, Color3.fromRGB(50, 120, 50), rowCount)
		header.Parent = container
		rowCount += 1
		
		for _, entry in completedAchievements do
			local row = createAchievementRow(entry.def.ID, entry.progress, entry.def, true)
			row.LayoutOrder = rowCount
			row.Parent = container
			rowCount += 1
		end
	end
	
	-- Update canvas size (summary=58, headers=38, rows=68 each)
	local headerCount = (if #inProgressAchievements > 0 then 1 else 0) 
		+ (if #lockedAchievements > 0 then 1 else 0) 
		+ (if #completedAchievements > 0 then 1 else 0)
	local achievementCount = #inProgressAchievements + #lockedAchievements + #completedAchievements
	local totalHeight = 58 + (headerCount * 38) + (achievementCount * ROW_HEIGHT) + 20
	container.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

return AchievementsTab
