--!strict
-- ModuleScript: TrapController
local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local TeamService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Game"):WaitForChild("TeamService"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "TrapController"

type TrapState = {
    capturedList: {BasePart},
    capturedIndex: {[BasePart]: number},
}

-- Storage to reset traps after game restart
module.ActiveTraps = {} :: {[BasePart]: TrapState}

function module.SetupTrap(trap: BasePart): nil
	Log.Info(CONTEXT, string.format("Setting up trap: %s", trap.Name))
    local Flock = workspace:WaitForChild("Flock") :: Folder
    
	-- Config
	local GRID_COLS: number = 6
	local CELL_SPACING_X: number = 6
	local CELL_SPACING_Z: number = 8
	local Y_OFFSET: number = 2

	-- State tables (must reset on game restart)
	local capturedList: {BasePart} = {}
	local capturedIndex: {[BasePart]: number} = {}

	local function isFlockRoot(hit: BasePart?): boolean
		return hit ~= nil and hit:IsA("BasePart") and hit.Parent == Flock
	end

	local function getSlotCFrame(index: number): CFrame
		local col = (index - 1) % GRID_COLS
		local row = math.floor((index - 1) / GRID_COLS)
		local offset = CFrame.new(
			(col - (GRID_COLS - 1)/2) * CELL_SPACING_X,
			Y_OFFSET,
			row * CELL_SPACING_Z
		)
		return trap.CFrame * offset
	end

	local function placeCaptured(part: BasePart): nil
		local idx = capturedIndex[part]
		if idx then
			part.CFrame = getSlotCFrame(idx)
		end
	end

	local function addCaptured(part: BasePart): nil
		if capturedIndex[part] then return end

		table.insert(capturedList, part)
		local idx = #capturedList
		capturedIndex[part] = idx

		part.Anchored = true
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero

		placeCaptured(part)
	end

	local function applyScore(animal: BasePart): nil
		-- Award points to the team that owns this trap
		local trapTeamName = trap:GetAttribute("Team")
		if not trapTeamName then 
			Log.Warn(CONTEXT, string.format("Trap %s has no Team attribute set!", trap.Name))
			return 
		end
		
		-- Get the animal's point value
		local pointValue = animal:GetAttribute("PointValue") or 1
		
		local teamFullName = trapTeamName .. " Team"
		local team = TeamService.GetTeamByName(teamFullName)
		if team then
			Log.Info(CONTEXT, string.format("Adding %d points to %s", pointValue, teamFullName))
			TeamService.AddTeamScore(team, pointValue)
		else
			Log.Warn(CONTEXT, string.format("Team not found: %s", teamFullName))
		end
	end

	trap.Touched:Connect(function(hit)
		if not isFlockRoot(hit) then return end

		-- Prevent re-capture
		if hit:GetAttribute("Captured") == true then return end
		if hit:GetAttribute("CapturedBy") then return end

		Log.Info(CONTEXT, string.format("Animal captured: %s by trap %s", hit.Name, trap.Name))
		
		hit:SetAttribute("Captured", true)
		hit:SetAttribute("CapturedBy", trap.Name)

		applyScore(hit)
		addCaptured(hit)
	end)

	-- store this trap's state so we can reset later
	module.ActiveTraps[trap] = {
		capturedList = capturedList,
		capturedIndex = capturedIndex,
	}
end

-- Called by game reset to clear trap memory
function module.ResetAllTraps(): nil
	for trap, data in pairs(module.ActiveTraps) do
		table.clear(data.capturedList)
		table.clear(data.capturedIndex)
	end
end

return module
