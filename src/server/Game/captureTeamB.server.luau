local TrapController = require(game.ServerScriptService.Server.Game.TrapController)
local Workspace = game:GetService("Workspace")

-- Prefer a specific part in Workspace; fallback to script.Parent if present
local trap: BasePart? = nil
local goalB = Workspace:FindFirstChild("GoalB")
if goalB then
    local teamB = goalB:FindFirstChild("Team B")
    if teamB and teamB:IsA("BasePart") then
        trap = teamB
    end
end

if not trap and script.Parent and script.Parent:IsA("BasePart") then
    trap = script.Parent :: BasePart
end

if trap then
    TrapController.SetupTrap(trap)
else
    warn("[captureTeamB] Trap part not found. Expected Workspace.GoalB.Team B or script.Parent.")
end
