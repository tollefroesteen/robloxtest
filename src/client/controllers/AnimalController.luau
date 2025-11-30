--!strict
local RunService = game:GetService("RunService")

local AnimalController = {}

local Flock = workspace:WaitForChild("Flock") :: Folder

-- === BODY FOLLOW TUNING ===
local FOLLOW_LERP    = 0.28
local ROTATION_LERP  = 0.15
local HEIGHT_OFFSET  = 2

-- === BODY BOUNCE ===
local BOB_AMPLITUDE  = 0.5
local BOB_FREQUENCY  = 15

-- === LEG ANIMATION TUNING ===
local LEG_FREQUENCY       = 9
local LEG_SWING_DEGREES   = 25
local LEG_LIFT            = 0.15
local LEG_PUSH            = 0.10
local LEG_SWAY            = 0.0
local LEG_BOUNCE_FACTOR   = 0.2
local LEG_BOUNCE_PHASE_OFFSET = 0.15

-- Gait phase
local LegOffsets: {[string]: number} = {
	LegFL = 0,
	LegFR = math.pi,
	LegBL = math.pi,
	LegBR = 0
}

local function ensurePhase(root)
	local p = root:GetAttribute("BouncePhase")
	if not p then
		p = math.random() * math.pi * 2
		root:SetAttribute("BouncePhase", p)
	end
	return p
end

local function getPivotLocal(leg)
	return Vector3.new(
		leg:GetAttribute("PivotX") or 0,
		leg:GetAttribute("PivotY") or 0,
		leg:GetAttribute("PivotZ") or 0
	)
end

local function getOffset(leg)
	return Vector3.new(
		leg:GetAttribute("OffsetX") or 0,
		leg:GetAttribute("OffsetY") or 0,
		leg:GetAttribute("OffsetZ") or 0
	)
end

-- ✅ Bind pose storage + cached part references (LO-1)
-- [root] = {
--   visualLocal = CFrame,
--   bounceLocal = CFrame,
--   legs = { [leg] = CFrame },
--   visualPart = BasePart,
--   bouncePart = BasePart
-- }
local bindPose = {}
local lastPos = {}

local function captureBindPose(root)
	if bindPose[root] then return end

	local data = {
		legs = {}
	}

	-- locate visual
	for _, c in ipairs(root:GetChildren()) do
		if c:IsA("BasePart") and c ~= root then
			local visual = c
			data.visualLocal = root.CFrame:ToObjectSpace(visual.CFrame)
			data.visualPart = visual  -- ✅ cache reference

			-- find bounce
			for _, b in ipairs(visual:GetChildren()) do
				if b:IsA("BasePart") then
					local bounce = b
					data.bounceLocal = visual.CFrame:ToObjectSpace(bounce.CFrame)
					data.bouncePart = bounce  -- ✅ cache reference

					-- find legs
					for _, l in ipairs(bounce:GetChildren()) do
						if l:IsA("BasePart") then
							data.legs[l] = bounce.CFrame:ToObjectSpace(l.CFrame)
						end
					end

					bindPose[root] = data
					return
				end
			end
		end
	end
end

function AnimalController.Init()
	RunService.RenderStepped:Connect(function()
		local t = tick()

		for _, root in ipairs(Flock:GetChildren()) do
			if not root:IsA("BasePart") then continue end

			-- First-ever sighting → capture Studio bind pose
			captureBindPose(root)
			local conf = bindPose[root]
			if not conf then continue end

			local target = root:GetAttribute("TargetPos")
			if not target then continue end

			local bodyPhase = ensurePhase(root)
			local visualLocal = conf.visualLocal
			local bounceLocal = conf.bounceLocal

			-- Use cached visual reference (no tree scan)
			local visual = conf.visualPart
			if not visual or not visual.Parent then continue end

			-- movement follow
			local targetPos = Vector3.new(target.X, target.Y + HEIGHT_OFFSET, target.Z)
			local newPos = visual.Position:Lerp(targetPos, FOLLOW_LERP)
			local facing = root.CFrame.LookVector
			local desired = CFrame.lookAt(newPos, newPos + facing)
			visual.CFrame = visual.CFrame:Lerp(desired, ROTATION_LERP)

			-- bounce
			local bob = math.sin(t * BOB_FREQUENCY + bodyPhase) * BOB_AMPLITUDE
			local bodyPos = Vector3.new(newPos.X, newPos.Y + bob, newPos.Z)
			local bounceCF = CFrame.new(bodyPos, bodyPos + facing)

			-- Use cached bounce reference (no tree scan)
			local bounce = conf.bouncePart
			if not bounce or not bounce.Parent then continue end

			bounce.CFrame = bounceCF

			-- detect movement
			local prev = lastPos[visual]
			local moving = prev and ((visual.Position - prev).Magnitude > 0.001)
			lastPos[visual] = visual.Position

			-- leg base follow
			local legYOffset = bob * 0.35
			local legBaseCF =
				CFrame.new(newPos.X, newPos.Y + legYOffset, newPos.Z)
				* CFrame.fromOrientation(visual.CFrame:ToOrientation())

			-- animate legs
			for leg, baseLegLocal in pairs(conf.legs) do
				if not leg.Parent then continue end -- leg might get removed

				local stance = getOffset(leg)
				local pivot = getPivotLocal(leg)

				if not moving then
					local idleLift = bob * LEG_BOUNCE_FACTOR
					leg.CFrame =
						legBaseCF
						* CFrame.new(stance)
						* baseLegLocal
						* CFrame.new(0, idleLift, 0)
					continue
				end

				local phaseOffset = LegOffsets[leg.Name] or 0
				local step = t * LEG_FREQUENCY + bodyPhase + phaseOffset

				local swing = math.rad(LEG_SWING_DEGREES) * math.sin(step)
				local lift = math.abs(math.cos(step)) * LEG_LIFT
				local push = math.sin(step) * LEG_PUSH
				local sway = math.sin(step) * LEG_SWAY

				local legBob =
					math.sin(t * BOB_FREQUENCY + bodyPhase + phaseOffset * LEG_BOUNCE_PHASE_OFFSET)
					* BOB_AMPLITUDE * LEG_BOUNCE_FACTOR

				local anim =
					(CFrame.new(pivot)
						* CFrame.Angles(swing, 0, 0)
						* CFrame.new(-pivot))
					* CFrame.new(sway, lift + legBob, push)

				leg.CFrame =
					legBaseCF
					* CFrame.new(stance)
					* baseLegLocal
					* anim
			end
		end
	end)
end

return AnimalController
