--!strict
-- LeaderboardController.luau
-- Client-side leaderboard display controller for the lobby
-- Creates and manages two 3D billboards: Global (all servers) and Server (current lobby)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local services = Shared:WaitForChild("services")
local LeaderboardService = require(services:WaitForChild("LeaderboardService"))

local player = Players.LocalPlayer

-- Define types locally (mirrors LeaderboardService types)
type LeaderboardEntry = {
	Rank: number,
	UserId: number,
	DisplayName: string,
	Value: number,
}

type LeaderboardData = {
	Entries: { LeaderboardEntry },
	LastUpdated: number,
	StatType: string,
}

-- Configuration
local CONFIG = {
	-- Billboard positions (side by side)
	GLOBAL_BILLBOARD_POSITION = Vector3.new(-12, 15, -50),  -- Left billboard (global)
	SERVER_BILLBOARD_POSITION = Vector3.new(12, 15, -50),   -- Right billboard (server)
	BILLBOARD_SIZE = Vector3.new(18, 12, 1),                -- Slightly narrower to fit both
	
	-- Colors
	BACKGROUND_COLOR = Color3.fromRGB(20, 25, 35),
	GLOBAL_HEADER_COLOR = Color3.fromRGB(255, 215, 0),      -- Gold for global
	SERVER_HEADER_COLOR = Color3.fromRGB(100, 200, 255),    -- Blue for server
	RANK_COLORS = {
		Color3.fromRGB(255, 215, 0),   -- 1st: Gold
		Color3.fromRGB(192, 192, 192), -- 2nd: Silver
		Color3.fromRGB(205, 127, 50),  -- 3rd: Bronze
	},
	DEFAULT_TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	HIGHLIGHT_COLOR = Color3.fromRGB(100, 200, 255),  -- For current player
	
	-- Entry display
	MAX_VISIBLE_ENTRIES = 10,
	ENTRY_HEIGHT = 0.08,  -- Fraction of billboard height per entry
	
	-- Animation
	UPDATE_TWEEN_TIME = 0.3,
}

local LeaderboardController = {}

-- Billboard data structure
type BillboardData = {
	Model: Model?,
	SurfaceGui: SurfaceGui?,
	EntriesFrame: Frame?,
	EntryLabels: { [number]: { Rank: TextLabel, Name: TextLabel, XP: TextLabel } },
	LastData: LeaderboardData?,
}

-- References for both billboards
local globalBillboard: BillboardData = {
	Model = nil,
	SurfaceGui = nil,
	EntriesFrame = nil,
	EntryLabels = {},
	LastData = nil,
}

local serverBillboard: BillboardData = {
	Model = nil,
	SurfaceGui = nil,
	EntriesFrame = nil,
	EntryLabels = {},
	LastData = nil,
}

--[=[
	Create a 3D billboard model in workspace.
	@param position -- World position for the billboard
	@param headerText -- Text to display in header
	@param headerColor -- Color for the header text
	@param billboardName -- Name for the model
	@return BillboardData -- References to billboard components
]=]
local function createBillboard(position: Vector3, headerText: string, headerColor: Color3, billboardName: string): BillboardData
	local billboardData: BillboardData = {
		Model = nil,
		SurfaceGui = nil,
		EntriesFrame = nil,
		EntryLabels = {},
		LastData = nil,
	}
	-- Create model container
	local model = Instance.new("Model")
	model.Name = billboardName
	
	-- Create the main part
	local part = Instance.new("Part")
	part.Name = "Board"
	part.Size = CONFIG.BILLBOARD_SIZE
	-- Rotate 180 degrees around Y axis so it faces the correct direction
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = CONFIG.BACKGROUND_COLOR
	part.Parent = model
	
	-- Create decorative frame around billboard
	local frameThickness = 0.3
	local frameColor = Color3.fromRGB(60, 70, 90)
	
	-- Top frame
	local topFrame = Instance.new("Part")
	topFrame.Name = "TopFrame"
	topFrame.Size = Vector3.new(CONFIG.BILLBOARD_SIZE.X + frameThickness * 2, frameThickness, CONFIG.BILLBOARD_SIZE.Z + 0.1)
	topFrame.CFrame = part.CFrame * CFrame.new(0, CONFIG.BILLBOARD_SIZE.Y / 2 + frameThickness / 2, 0)
	topFrame.Anchored = true
	topFrame.CanCollide = false
	topFrame.Material = Enum.Material.Metal
	topFrame.Color = frameColor
	topFrame.Parent = model
	
	-- Bottom frame
	local bottomFrame = topFrame:Clone()
	bottomFrame.Name = "BottomFrame"
	bottomFrame.CFrame = part.CFrame * CFrame.new(0, -(CONFIG.BILLBOARD_SIZE.Y / 2 + frameThickness / 2), 0)
	bottomFrame.Parent = model
	
	-- Left frame
	local leftFrame = Instance.new("Part")
	leftFrame.Name = "LeftFrame"
	leftFrame.Size = Vector3.new(frameThickness, CONFIG.BILLBOARD_SIZE.Y, CONFIG.BILLBOARD_SIZE.Z + 0.1)
	leftFrame.CFrame = part.CFrame * CFrame.new(-(CONFIG.BILLBOARD_SIZE.X / 2 + frameThickness / 2), 0, 0)
	leftFrame.Anchored = true
	leftFrame.CanCollide = false
	leftFrame.Material = Enum.Material.Metal
	leftFrame.Color = frameColor
	leftFrame.Parent = model
	
	-- Right frame
	local rightFrame = leftFrame:Clone()
	rightFrame.Name = "RightFrame"
	rightFrame.CFrame = part.CFrame * CFrame.new(CONFIG.BILLBOARD_SIZE.X / 2 + frameThickness / 2, 0, 0)
	rightFrame.Parent = model
	
	-- Create SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = part
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = gui
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.Position = UDim2.new(0, 0, 0.02, 0)
	header.BackgroundTransparency = 1
	header.Text = headerText
	header.TextColor3 = headerColor
	header.TextScaled = true
	header.Font = Enum.Font.GothamBold
	header.Parent = container
	
	-- Entries container
	local entries = Instance.new("Frame")
	entries.Name = "Entries"
	entries.Size = UDim2.new(0.95, 0, 0.82, 0)
	entries.Position = UDim2.new(0.025, 0, 0.15, 0)
	entries.BackgroundTransparency = 1
	entries.Parent = container
	
	-- Create entry rows
	local entryLabels: { [number]: { Rank: TextLabel, Name: TextLabel, XP: TextLabel } } = {}
	
	for i = 1, CONFIG.MAX_VISIBLE_ENTRIES do
		local yPos = (i - 1) * CONFIG.ENTRY_HEIGHT
		
		local entryFrame = Instance.new("Frame")
		entryFrame.Name = "Entry" .. i
		entryFrame.Size = UDim2.new(1, 0, CONFIG.ENTRY_HEIGHT - 0.01, 0)
		entryFrame.Position = UDim2.new(0, 0, yPos, 0)
		entryFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
		entryFrame.BackgroundTransparency = 0.5
		entryFrame.BorderSizePixel = 0
		entryFrame.Parent = entries
		
		-- Add corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = entryFrame
		
		-- Rank label
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "Rank"
		rankLabel.Size = UDim2.new(0.12, 0, 1, 0)
		rankLabel.Position = UDim2.new(0.02, 0, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. i
		rankLabel.TextColor3 = CONFIG.RANK_COLORS[i] or CONFIG.DEFAULT_TEXT_COLOR
		rankLabel.TextScaled = true
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.TextXAlignment = Enum.TextXAlignment.Left
		rankLabel.Parent = entryFrame
		
		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "---"
		nameLabel.TextColor3 = CONFIG.DEFAULT_TEXT_COLOR
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entryFrame
		
		-- XP label
		local xpLabel = Instance.new("TextLabel")
		xpLabel.Name = "XP"
		xpLabel.Size = UDim2.new(0.25, 0, 1, 0)
		xpLabel.Position = UDim2.new(0.72, 0, 0, 0)
		xpLabel.BackgroundTransparency = 1
		xpLabel.Text = "0 XP"
		xpLabel.TextColor3 = headerColor
		xpLabel.TextScaled = true
		xpLabel.Font = Enum.Font.GothamBold
		xpLabel.TextXAlignment = Enum.TextXAlignment.Right
		xpLabel.Parent = entryFrame
		
		entryLabels[i] = {
			Rank = rankLabel,
			Name = nameLabel,
			XP = xpLabel,
		}
	end
	
	-- "Last updated" footer
	local footer = Instance.new("TextLabel")
	footer.Name = "Footer"
	footer.Size = UDim2.new(1, 0, 0.05, 0)
	footer.Position = UDim2.new(0, 0, 0.95, 0)
	footer.BackgroundTransparency = 1
	footer.Text = "Updated just now"
	footer.TextColor3 = Color3.fromRGB(150, 150, 150)
	footer.TextScaled = true
	footer.Font = Enum.Font.Gotham
	footer.Parent = container
	
	model.Parent = workspace
	
	-- Store references
	billboardData.Model = model
	billboardData.SurfaceGui = gui
	billboardData.EntriesFrame = entries
	billboardData.EntryLabels = entryLabels
	
	return billboardData
end

--[=[
	Update a billboard display with new leaderboard data.
	@param billboard -- The billboard data structure to update
	@param data -- The leaderboard data to display
	@param headerColor -- Color for XP text
]=]
local function updateDisplay(billboard: BillboardData, data: LeaderboardData, headerColor: Color3)
	if not billboard.EntriesFrame then return end
	
	billboard.LastData = data
	
	for i = 1, CONFIG.MAX_VISIBLE_ENTRIES do
		local labels = billboard.EntryLabels[i]
		if not labels then continue end
		
		local entry = data.Entries[i]
		local entryFrame = billboard.EntriesFrame:FindFirstChild("Entry" .. i) :: Frame?
		
		if entry then
			-- Update labels
			labels.Rank.Text = "#" .. entry.Rank
			labels.Name.Text = entry.DisplayName
			labels.XP.Text = LeaderboardService.FormatXP(entry.Value) .. " XP"
			
			-- Color based on rank
			labels.Rank.TextColor3 = CONFIG.RANK_COLORS[entry.Rank] or CONFIG.DEFAULT_TEXT_COLOR
			
			-- Highlight current player
			if entry.UserId == player.UserId then
				labels.Name.TextColor3 = CONFIG.HIGHLIGHT_COLOR
				labels.Name.Text = "► " .. entry.DisplayName
				if entryFrame then
					entryFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
					entryFrame.BackgroundTransparency = 0.3
				end
			else
				labels.Name.TextColor3 = CONFIG.DEFAULT_TEXT_COLOR
				if entryFrame then
					entryFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
					entryFrame.BackgroundTransparency = 0.5
				end
			end
			
			-- Show entry
			if entryFrame then
				entryFrame.Visible = true
			end
		else
			-- Hide empty entry
			labels.Rank.Text = "#" .. i
			labels.Name.Text = "---"
			labels.XP.Text = "---"
			labels.Name.TextColor3 = Color3.fromRGB(100, 100, 100)
			
			if entryFrame then
				entryFrame.Visible = true  -- Keep visible but dimmed
			end
		end
	end
	
	-- Update footer
	if billboard.SurfaceGui then
		local container = billboard.SurfaceGui:FindFirstChild("Container") :: Frame?
		if container then
			local footer = container:FindFirstChild("Footer") :: TextLabel?
			if footer then
				local timeSinceUpdate = os.time() - data.LastUpdated
				if timeSinceUpdate < 60 then
					footer.Text = "Updated just now"
				elseif timeSinceUpdate < 3600 then
					footer.Text = string.format("Updated %d min ago", math.floor(timeSinceUpdate / 60))
				else
					footer.Text = string.format("Updated %d hr ago", math.floor(timeSinceUpdate / 3600))
				end
			end
		end
	end
end

--[=[
	Handle global leaderboard update event from server.
]=]
local function onGlobalLeaderboardUpdated(data: LeaderboardData)
	updateDisplay(globalBillboard, data, CONFIG.GLOBAL_HEADER_COLOR)
end

--[=[
	Handle server leaderboard update event from server.
]=]
local function onServerLeaderboardUpdated(data: LeaderboardData)
	updateDisplay(serverBillboard, data, CONFIG.SERVER_HEADER_COLOR)
end

--[=[
	Request a leaderboard refresh from server.
]=]
function LeaderboardController.RequestRefresh()
	RemoteEvents.RequestLeaderboardEvent:FireServer()
end

--[=[
	Get the last received global leaderboard data.
]=]
function LeaderboardController.GetGlobalLeaderboardData(): LeaderboardData?
	return globalBillboard.LastData
end

--[=[
	Get the last received server leaderboard data.
]=]
function LeaderboardController.GetServerLeaderboardData(): LeaderboardData?
	return serverBillboard.LastData
end

--[=[
	Initialize the leaderboard controller.
]=]
function LeaderboardController.Init()
	-- Create both billboards
	globalBillboard = createBillboard(
		CONFIG.GLOBAL_BILLBOARD_POSITION,
		"🌍 GLOBAL LEADERBOARD 🌍",
		CONFIG.GLOBAL_HEADER_COLOR,
		"GlobalLeaderboardBillboard"
	)
	
	serverBillboard = createBillboard(
		CONFIG.SERVER_BILLBOARD_POSITION,
		"🏠 THIS SERVER 🏠",
		CONFIG.SERVER_HEADER_COLOR,
		"ServerLeaderboardBillboard"
	)
	
	-- Connect to leaderboard updates
	RemoteEvents.LeaderboardUpdatedEvent.OnClientEvent:Connect(onGlobalLeaderboardUpdated)
	RemoteEvents.ServerLeaderboardUpdatedEvent.OnClientEvent:Connect(onServerLeaderboardUpdated)
	
	-- Request initial data
	task.wait(1)
	LeaderboardController.RequestRefresh()
	
	print("[LeaderboardController] Initialized with Global and Server leaderboards")
end

return LeaderboardController
