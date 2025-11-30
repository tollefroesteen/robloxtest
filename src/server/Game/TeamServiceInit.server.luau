--!strict
-- TeamServiceInit.server.luau
-- Initializes TeamService and connects event listeners

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local TeamService = require(ServerScriptService.Server.Game.TeamService)
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "TeamServiceInit"

-- Initialize teams on server start
TeamService.CreateTeams()

-- Listen for game start to assign teams
ServerEvents.StartGameEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game started - assigning players to teams")
	TeamService.ResetTeamScores()
	TeamService.AssignAllPlayersToTeams()
end)

-- Listen for timer end (game over)
ServerEvents.TimerEndedEvent.Event:Connect(function()
	Log.Info(CONTEXT, "Game ended")
	-- Teams persist, scores remain for end-game display
end)

-- Listen for game reset
RemoteEvents.ResetGameEvent.OnServerEvent:Connect(function(player: Player)
	Log.Info(CONTEXT, string.format("Game reset by %s", player.Name))
	TeamService.ResetTeamScores()
	-- Note: Team assignments persist until next game start
end)

-- Handle player scoring (connect to your capture/scoring system)
RemoteEvents.PlayerScoredEvent.OnServerEvent:Connect(function(player: Player, points: number)
	TeamService.AddPlayerTeamScore(player, points)
end)

Log.Info(CONTEXT, "TeamService initialized")
