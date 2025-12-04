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

-- Finds the team score GUI from Studio's StarterGui
local function findTeamScoreGui(): nil
	local playerGui = player:WaitForChild("PlayerGui")
	
	local existing = playerGui:WaitForChild("TeamScoreGui", 5)
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
		else
			Log.Warn(CONTEXT, "TeamScoreGui found but score labels missing")
		end
	else
		Log.Warn(CONTEXT, "TeamScoreGui not found - create it in StarterGui with RedScoreLabel and BlueScoreLabel")
	end
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
