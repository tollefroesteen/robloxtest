--!strict
-- ModuleScript: TrapController
local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local ScoreService = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Game"):WaitForChild("ScoreService"))

type TrapState = {
    capturedList: {BasePart},
    capturedIndex: {[BasePart]: number},
}

-- Storage to reset traps after game restart
module.ActiveTraps = {} :: {[BasePart]: TrapState}

function module.SetupTrap(trap: BasePart): nil
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

	local function applyScore(trapType: string, animalType: string): nil
		-- Delegate to centralized ScoreService
		ScoreService.ApplyScore(trapType, animalType, trap.Name)
	end

	trap.Touched:Connect(function(hit)
		if not isFlockRoot(hit) then return end

		-- Prevent re-capture
		if hit:GetAttribute("Captured") == true then return end
		if hit:GetAttribute("CapturedBy") then return end

		hit:SetAttribute("Captured", true)
		hit:SetAttribute("CapturedBy", trap.Name)

		local trapTypeAttr = trap:GetAttribute("Team")
		local animalTypeAttr = hit:GetAttribute("Team")
		if typeof(trapTypeAttr) == "string" and typeof(animalTypeAttr) == "string" then
			applyScore(trapTypeAttr, animalTypeAttr)
		else
			warn("[TrapController] Missing Team attributes on trap/animal")
		end
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
