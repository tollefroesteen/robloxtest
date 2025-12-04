--!strict
local RunService = game:GetService("RunService")

local AnimalController = {}

local Flock = workspace:WaitForChild("Flock") :: Folder

-- Debug flag - set to true to see bind pose capture info
local DEBUG_BIND_POSE = false

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

-- ✅ Bind pose storage
-- [root] = {
--   visualLocal = CFrame,
--   bounceLocal = CFrame,
--   legs = { [legName] = CFrame },  -- Use NAME as key, not Part reference
--   visualPart = BasePart,
--   bouncePart = BasePart
-- }
local bindPose = {}
local lastPos = {}

local function captureBindPose(root)
	if bindPose[root] then return end
	
	-- Don't capture bind pose until animal is ready (positions are finalized)
	if root:GetAttribute("ReadyForFlocking") ~= true then return end

	local data = {
		legs = {}
	}

	-- locate visual
	for _, c in ipairs(root:GetChildren()) do
		if c:IsA("BasePart") and c ~= root then
			local visual = c
			data.visualLocal = root.CFrame:ToObjectSpace(visual.CFrame)
			data.visualPart = visual

			-- find bounce
			for _, b in ipairs(visual:GetChildren()) do
				if b:IsA("BasePart") then
					local bounce = b
					data.bounceLocal = visual.CFrame:ToObjectSpace(bounce.CFrame)
					data.bouncePart = bounce

					-- find legs - ONLY parts named LegFL, LegFR, LegBL, LegBR
					-- Store by NAME not by Part reference
					local legCount = 0
					local maxLegDistance = 0
					local legDebugInfo = {}
					for _, l in ipairs(bounce:GetChildren()) do
						if l:IsA("BasePart") and (l.Name == "LegFL" or l.Name == "LegFR" or l.Name == "LegBL" or l.Name == "LegBR") then
							local legLocal = bounce.CFrame:ToObjectSpace(l.CFrame)
							data.legs[l.Name] = legLocal  -- Use NAME as key
							legCount += 1
							
							local legDist = legLocal.Position.Magnitude
							if legDist > maxLegDistance then
								maxLegDistance = legDist
							end
							
							table.insert(legDebugInfo, string.format("%s: dist=%.2f pos=(%.1f,%.1f,%.1f)", 
								l.Name, legDist, legLocal.Position.X, legLocal.Position.Y, legLocal.Position.Z))
						end
					end
					
					if DEBUG_BIND_POSE then
						print(string.format("[BindPose] Animal %s: found %d legs, maxDist=%.2f", 
							tostring(root), legCount, maxLegDistance))
						for _, info in legDebugInfo do
							print("  " .. info)
						end
						print(string.format("  Bounce world pos: (%.1f, %.1f, %.1f)", 
							bounce.Position.X, bounce.Position.Y, bounce.Position.Z))
					end
					
					-- Only save if we found all 4 legs and they're within reasonable distance
					if legCount == 4 and maxLegDistance < 10 then
						bindPose[root] = data
						if DEBUG_BIND_POSE then
							print(string.format("[BindPose] ✅ SAVED bind pose for %s", tostring(root)))
						end
					else
						if DEBUG_BIND_POSE then
							print(string.format("[BindPose] ❌ REJECTED - legCount=%d, maxDist=%.2f", legCount, maxLegDistance))
						end
					end
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

			-- Don't process animals that aren't ready yet
			if root:GetAttribute("ReadyForFlocking") ~= true then continue end

			-- First-ever sighting → capture bind pose
			captureBindPose(root)
			local conf = bindPose[root]
			if not conf then continue end

			local target = root:GetAttribute("TargetPos")
			if not target then continue end

			local bodyPhase = ensurePhase(root)
			local visualLocal = conf.visualLocal
			local bounceLocal = conf.bounceLocal

			-- Use cached visual reference
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

			-- Use cached bounce reference
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

			-- animate legs - look up by NAME each frame
			for legName, baseLegLocal in pairs(conf.legs) do
				local leg = bounce:FindFirstChild(legName)
				if not leg or not leg:IsA("BasePart") then continue end

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

				local phaseOffset = LegOffsets[legName] or 0
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
