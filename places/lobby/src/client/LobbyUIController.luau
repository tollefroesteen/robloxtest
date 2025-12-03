--!strict
-- LobbyUIController.luau
-- Manages the main lobby UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "LobbyUIController"

local LobbyUIController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the main lobby UI
local function createLobbyUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LobbyUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏠 LOBBY"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Stats display
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -20, 0, 100)
	statsLabel.Position = UDim2.new(0, 10, 0, 60)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Loading stats..."
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.TextSize = 16
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.Parent = mainFrame
	
	-- Play button
	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.new(0.8, 0, 0, 60)
	playButton.Position = UDim2.new(0.1, 0, 1, -80)
	playButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	playButton.Text = "▶ PLAY"
	playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playButton.TextSize = 24
	playButton.Font = Enum.Font.GothamBold
	playButton.Parent = mainFrame
	
	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0, 8)
	playCorner.Parent = playButton
	
	-- Play button click
	playButton.MouseButton1Click:Connect(function()
		playButton.Text = "Joining..."
		playButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		RemoteEvents.PlayRequestEvent:FireServer()
	end)
	
	return screenGui, statsLabel
end

local lobbyUI, statsLabel = createLobbyUI()

-- Update stats display
RemoteEvents.StatsUpdatedEvent.OnClientEvent:Connect(function(stats)
	if statsLabel then
		statsLabel.Text = string.format(
			"Level: %d\nXP: %d\nCaptures: %d\nWins: %d\nGames: %d",
			stats.Level or 1,
			stats.ExperiencePoints or 0,
			stats.TotalCaptures or 0,
			stats.TotalWins or 0,
			stats.TotalGamesPlayed or 0
		)
	end
end)

Log.Info(CONTEXT, "LobbyUIController initialized")

return LobbyUIController
