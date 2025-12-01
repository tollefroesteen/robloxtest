--!strict
-- ModuleScript: TrapController
local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local TeamService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Game"):WaitForChild("TeamService"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

-- Lazy load AchievementsService to avoid circular dependency
local AchievementsService: any = nil
local function getAchievementsService()
	if not AchievementsService then
		local success, service = pcall(function()
			return require(ServerScriptService:WaitForChild("Server"):WaitForChild("Player"):WaitForChild("AchievementsService"))
		end)
		if success then
			AchievementsService = service
		end
	end
	return AchievementsService
end

local CONTEXT = "TrapController"

type TrapState = {
    capturedList: {BasePart},
    capturedIndex: {[BasePart]: number},
}

-- Storage to reset traps after game restart
module.ActiveTraps = {} :: {[BasePart]: TrapState}

-- Track captured animals by team name (for game end processing)
-- Format: { [teamName]: { animalID1, animalID2, ... } }
local capturedAnimalsByTeam: { [string]: { string } } = {}

-- Game state - can be set to disable captures
local gameActive = true

function module.SetGameActive(active: boolean): nil
	gameActive = active
	Log.Info(CONTEXT, string.format("Game active state: %s", tostring(active)))
end

function module.IsGameActive(): boolean
	return gameActive
end

-- Get all captured animal IDs for a team
function module.GetCapturedAnimalsByTeam(teamName: string): { string }
	return capturedAnimalsByTeam[teamName] or {}
end

-- Reset captured animals tracking (called on game reset)
function module.ResetCapturedAnimals(): nil
	capturedAnimalsByTeam = {}
end

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
		
		-- Get the animal's point value and ID
		local pointValue = animal:GetAttribute("PointValue") or 1
		local animalID = animal:GetAttribute("ID") or "Unknown"
		
		local teamFullName = trapTeamName .. " Team"
		local team = TeamService.GetTeamByName(teamFullName)
		if team then
			Log.Info(CONTEXT, string.format("Adding %d points to %s", pointValue, teamFullName))
			TeamService.AddTeamScore(team, pointValue)
			
			-- Track this animal for the team (for end-game processing)
			if not capturedAnimalsByTeam[teamFullName] then
				capturedAnimalsByTeam[teamFullName] = {}
			end
			table.insert(capturedAnimalsByTeam[teamFullName], animalID)
			
			-- Record capture for all players on this team (achievements/stats)
			local achievementsService = getAchievementsService()
			if achievementsService then
				for _, player in team:GetPlayers() do
					achievementsService.RecordAnimalCapture(player, animalID)
				end
			end
		else
			Log.Warn(CONTEXT, string.format("Team not found: %s", teamFullName))
		end
	end

	trap.Touched:Connect(function(hit)
		-- Check if game is active
		if not gameActive then return end
		
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
