local TrapController = require(game.ServerScriptService.Server.Game.TrapController)
local Workspace = game:GetService("Workspace")

-- Prefer a specific part in Workspace; fallback to script.Parent if present
local trap: BasePart? = Workspace.GoalA:FindFirstChild("Team A")
if not trap and script.Parent and script.Parent:IsA("BasePart") then
	trap = script.Parent :: BasePart
end

if trap then
	TrapController.SetupTrap(trap)
else
	warn("[captureTeamA] Trap part not found. Expected Workspace.GoalA.Team A or script.Parent.")
end
