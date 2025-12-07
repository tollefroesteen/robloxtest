--!strict
-- TeamController.luau
-- Displays team scores and handles team-related UI on the client

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "TeamController"
local player: Player = Players.LocalPlayer

local TeamController = {}

-- UI references (from Studio's StarterGui)
local teamScoreGui: ScreenGui? = nil
local redScoreLabel: TextLabel? = nil
local blueScoreLabel: TextLabel? = nil

-- Current scores
local teamScores: { [string]: number } = {
	["Red Team"] = 0,
	["Blue Team"] = 0,
}

-- Updates the team score display
local function updateScoreUI(): nil
	if redScoreLabel then
		redScoreLabel.Text = tostring(teamScores["Red Team"] or 0)
	end
	if blueScoreLabel then
		blueScoreLabel.Text = tostring(teamScores["Blue Team"] or 0)
	end
end

-- Creates the team score GUI programmatically as a fallback
local function createTeamScoreGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Check if we already created one
	local existing = playerGui:FindFirstChild("TeamScoreGui")
	if existing then
		existing:Destroy()
	end
	
	-- Create ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "TeamScoreGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	
	-- Create a frame to hold scores (top area, below timer)
	local frame = Instance.new("Frame")
	frame.Name = "ScoreFrame"
	frame.Size = UDim2.new(0, 200, 0, 40)
	frame.Position = UDim2.new(0.5, -100, 0, 70)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = gui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Red team score (left side)
	local redLabel = Instance.new("TextLabel")
	redLabel.Name = "RedScoreLabel"
	redLabel.Size = UDim2.new(0.4, 0, 1, 0)
	redLabel.Position = UDim2.new(0.05, 0, 0, 0)
	redLabel.BackgroundTransparency = 1
	redLabel.Text = "0"
	redLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	redLabel.TextScaled = true
	redLabel.Font = Enum.Font.GothamBold
	redLabel.TextXAlignment = Enum.TextXAlignment.Center
	redLabel.Parent = frame
	
	-- VS separator
	local vsLabel = Instance.new("TextLabel")
	vsLabel.Name = "VSLabel"
	vsLabel.Size = UDim2.new(0.1, 0, 1, 0)
	vsLabel.Position = UDim2.new(0.45, 0, 0, 0)
	vsLabel.BackgroundTransparency = 1
	vsLabel.Text = "-"
	vsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	vsLabel.TextScaled = true
	vsLabel.Font = Enum.Font.GothamBold
	vsLabel.Parent = frame
	
	-- Blue team score (right side)
	local blueLabel = Instance.new("TextLabel")
	blueLabel.Name = "BlueScoreLabel"
	blueLabel.Size = UDim2.new(0.4, 0, 1, 0)
	blueLabel.Position = UDim2.new(0.55, 0, 0, 0)
	blueLabel.BackgroundTransparency = 1
	blueLabel.Text = "0"
	blueLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
	blueLabel.TextScaled = true
	blueLabel.Font = Enum.Font.GothamBold
	blueLabel.TextXAlignment = Enum.TextXAlignment.Center
	blueLabel.Parent = frame
	
	teamScoreGui = gui
	redScoreLabel = redLabel
	blueScoreLabel = blueLabel
	
	Log.Info(CONTEXT, "Created TeamScoreGui programmatically")
end

-- Finds the team score GUI from Studio's StarterGui or creates one
local function findTeamScoreGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- If we already have valid references, just verify they exist
	if teamScoreGui and teamScoreGui.Parent == playerGui and redScoreLabel and blueScoreLabel then
		Log.Info(CONTEXT, "Using existing TeamScoreGui references")
		return
	end
	
	-- Try to find existing TeamScoreGui from Studio's StarterGui
	local existing = playerGui:FindFirstChild("TeamScoreGui")
	if not existing then
		existing = playerGui:WaitForChild("TeamScoreGui", 1)
	end
	
	if existing and existing:IsA("ScreenGui") then
		teamScoreGui = existing :: ScreenGui
		
		local redLabel = teamScoreGui:FindFirstChild("RedScoreLabel", true)
		if redLabel and redLabel:IsA("TextLabel") then
			redScoreLabel = redLabel :: TextLabel
		end
		
		local blueLabel = teamScoreGui:FindFirstChild("BlueScoreLabel", true)
		if blueLabel and blueLabel:IsA("TextLabel") then
			blueScoreLabel = blueLabel :: TextLabel
		end
		
		if redScoreLabel and blueScoreLabel then
			Log.Info(CONTEXT, "Found TeamScoreGui from Studio")
			return
		else
			Log.Warn(CONTEXT, "TeamScoreGui found but score labels missing")
		end
	end
	
	-- Fallback: Create GUI programmatically
	Log.Info(CONTEXT, "TeamScoreGui not found in PlayerGui, creating programmatically")
	createTeamScoreGui()
end

-- Listen for team score updates
RemoteEvents.TeamScoreUpdateEvent.OnClientEvent:Connect(function(scores: { [string]: number })
	Log.Info(CONTEXT, string.format("Team scores updated - Red: %d, Blue: %d", 
		scores["Red Team"] or 0, scores["Blue Team"] or 0))
	teamScores = scores
	updateScoreUI()
end)

-- Listen for team assignment
RemoteEvents.TeamAssignedEvent.OnClientEvent:Connect(function(assignedPlayer: Player, teamName: string, teamColor: Color3)
	if assignedPlayer == player then
		Log.Info(CONTEXT, string.format("You were assigned to %s", teamName))
		-- Could show a notification or update UI here
	else
		Log.Info(CONTEXT, string.format("%s was assigned to %s", assignedPlayer.Name, teamName))
	end
end)

-- Listen for game reset
RemoteEvents.ResetGameEvent.OnClientEvent:Connect(function()
	teamScores["Red Team"] = 0
	teamScores["Blue Team"] = 0
	updateScoreUI()
	
	if teamScoreGui then
		teamScoreGui.Enabled = false
	end
end)

-- Show GUI when game starts (via timer update as proxy)
RemoteEvents.TimerUpdateEvent.OnClientEvent:Connect(function(remaining: number)
	if teamScoreGui and not teamScoreGui.Enabled then
		teamScoreGui.Enabled = true
		Log.Info(CONTEXT, "Team score GUI now visible")
	end
end)

function TeamController.Init(): nil
	Log.Info(CONTEXT, "TeamController.Init() called")
	findTeamScoreGui()
	updateScoreUI()
	
	-- Hide GUI initially until game starts
	if teamScoreGui then
		teamScoreGui.Enabled = false
		Log.Info(CONTEXT, "Team score GUI hidden until game starts")
	end
end

return TeamController
