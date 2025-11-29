-- ModuleScript: TrapController
local module = {}

-- Storage to reset traps after game restart
module.ActiveTraps = {}

function module.SetupTrap(trap: BasePart)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ScoreEvent = ReplicatedStorage:WaitForChild("ScoreEvent")
	local Flock = workspace:WaitForChild("Flock")

	-- Config
	local GRID_COLS = 6
	local CELL_SPACING_X = 6
	local CELL_SPACING_Z = 8
	local Y_OFFSET = 2

	-- State tables (must reset on game restart)
	local capturedList = {}
	local capturedIndex = {}
	local ScoresByTrapType = {}

	local function isFlockRoot(hit)
		return hit and hit:IsA("BasePart") and hit.Parent == Flock
	end

	local function getSlotCFrame(index)
		local col = (index - 1) % GRID_COLS
		local row = math.floor((index - 1) / GRID_COLS)
		local offset = CFrame.new(
			(col - (GRID_COLS - 1)/2) * CELL_SPACING_X,
			Y_OFFSET,
			row * CELL_SPACING_Z
		)
		return trap.CFrame * offset
	end

	local function placeCaptured(part)
		local idx = capturedIndex[part]
		if idx then
			part.CFrame = getSlotCFrame(idx)
		end
	end

	local function addCaptured(part)
		if capturedIndex[part] then return end

		table.insert(capturedList, part)
		local idx = #capturedList
		capturedIndex[part] = idx

		part.Anchored = true
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero

		placeCaptured(part)
	end

	local function applyScore(trapType, animalType)
		local delta = (trapType == animalType) and 1 or -1
		ScoresByTrapType[trapType] = (ScoresByTrapType[trapType] or 0) + delta

		ScoreEvent:FireAllClients({
			delta = delta,
			trapType = trapType,
			animalType = animalType,
			totalForTrapType = ScoresByTrapType[trapType],
			trapName = trap.Name,
		})
	end

	trap.Touched:Connect(function(hit)
		if not isFlockRoot(hit) then return end

		-- Prevent re-capture
		if hit:GetAttribute("Captured") == true then return end
		if hit:GetAttribute("CapturedBy") then return end

		hit:SetAttribute("Captured", true)
		hit:SetAttribute("CapturedBy", trap.Name)

		local trapType = trap:GetAttribute("Team")
		local animalType = hit:GetAttribute("Team")

		applyScore(trapType, animalType)
		addCaptured(hit)
	end)

	-- store this trap's state so we can reset later
	module.ActiveTraps[trap] = {
		capturedList = capturedList,
		capturedIndex = capturedIndex,
		ScoresByTrapType = ScoresByTrapType
	}
end

-- Called by game reset to clear trap memory
function module.ResetAllTraps()
	for trap, data in pairs(module.ActiveTraps) do
		table.clear(data.capturedList)
		table.clear(data.capturedIndex)
		table.clear(data.ScoresByTrapType)
	end
end

return module
