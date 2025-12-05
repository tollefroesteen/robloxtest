--!strict
--[[
	AnimalController.luau (Client-Side)
	
	PURPOSE:
	This controller smoothly interpolates animal visuals to follow server-authoritative
	positions, and adds procedural animation (body bob, leg movement) for visual polish.
	
	HOW IT WORKS:
	1. Server (Flocking.server.luau) calculates positions at 20 ticks/sec using boids algorithm
	2. Server sets "TargetPos" attribute on each animal's root part
	3. This client controller runs every frame (RenderStepped, ~60fps)
	4. Client lerps the Visual/Bouncepart toward TargetPos for smooth motion
	5. Client adds procedural animation on top (bob, leg swing)
	
	HIERARCHY:
	AnimalTemplate (root BasePart - moved by server physics)
	└── Visual (BasePart - client lerps this to follow root)
	    └── Bouncepart (BasePart - client adds bob animation here)
	        ├── LegFL, LegFR, LegBL, LegBR (BaseParts - client animates these)
	        └── Body/Head/Tail blocks (welded, follow Bouncepart)
]]

local RunService = game:GetService("RunService")

local AnimalController = {}

local Flock = workspace:WaitForChild("Flock") :: Folder

-- Debug flag - set to true to see bind pose capture info in output
local DEBUG_BIND_POSE = false

-- ============================================================================
-- BODY FOLLOW TUNING
-- These control how the visible animal follows the server's root position
-- ============================================================================

-- FOLLOW_LERP: How quickly the visual catches up to server position (0-1)
--   Lower (0.1): Floaty, laggy feel - visual trails behind server position
--   Higher (0.5): Snappy, responsive - visual stays close to server position
--   Too high: Can look jittery if server updates are infrequent
local FOLLOW_LERP = 0.6

-- ROTATION_LERP: How quickly the visual rotates to face movement direction (0-1)
--   Lower (0.05): Slow, smooth turning - animals bank into turns gracefully
--   Higher (0.3): Quick snapping - animals instantly face their direction
--   Note: This reads from root.CFrame.LookVector which server controls
local ROTATION_LERP = 0.15

-- HEIGHT_OFFSET: Vertical offset for the Visual above the root part (studs)
--   The root part is at ground level for collision; Visual floats above it
--   Increase for taller animals or if animals appear sunken into ground
local HEIGHT_OFFSET = 2

-- ============================================================================
-- BODY BOUNCE (BOB) ANIMATION
-- Adds a subtle up/down bounce to make animals feel alive when moving
-- ============================================================================

-- BOB_AMPLITUDE: How far up/down the body bounces (studs)
--   Lower (0.2): Subtle, gentle bounce
--   Higher (1.0): Exaggerated cartoon bounce
--   0 = No bounce at all
local BOB_AMPLITUDE = 0.5

-- BOB_FREQUENCY: How fast the body bounces (cycles per second, roughly)
--   Lower (5): Slow, lumbering bounce - good for large animals
--   Higher (20): Fast, energetic bounce - good for small animals
--   Should roughly match perceived movement speed
local BOB_FREQUENCY = 15

-- ============================================================================
-- LEG ANIMATION TUNING
-- Procedural walk cycle - legs swing forward/back with lift
-- ============================================================================

-- LEG_FREQUENCY: How fast legs cycle through walk animation
--   Lower (5): Slow walk cycle - legs move slowly
--   Higher (15): Fast walk cycle - running/scurrying
--   Should feel synchronized with BOB_FREQUENCY for natural motion
local LEG_FREQUENCY = 9

-- LEG_SWING_DEGREES: How far legs rotate forward/backward (degrees)
--   Lower (10): Small steps - shuffling motion
--   Higher (45): Large steps - exaggerated cartoon walk
--   This is the rotation around the leg's pivot point (hip)
local LEG_SWING_DEGREES = 25

-- LEG_LIFT: How high legs lift off ground at peak of step (studs)
--   Lower (0.05): Feet barely leave ground - shuffling
--   Higher (0.3): High stepping - marching or prancing
--   0 = Legs slide without lifting
local LEG_LIFT = 0.15

-- LEG_PUSH: How far legs move forward/backward (studs)
--   Adds translational movement in addition to rotation
--   Creates "reaching" motion - leg extends forward then pushes back
--   0 = Pure rotation only, no forward reach
local LEG_PUSH = 0.10

-- LEG_SWAY: Side-to-side leg movement (studs)
--   Adds lateral wobble to walk cycle
--   Higher values = waddle-like motion
--   0 = No side sway (current setting)
local LEG_SWAY = 0.0

-- LEG_BOUNCE_FACTOR: How much legs bounce with body bob (multiplier)
--   Connects leg motion to body bounce for cohesive feel
--   0 = Legs ignore body bounce
--   1 = Legs bounce same amount as body
local LEG_BOUNCE_FACTOR = 0.2

-- LEG_BOUNCE_PHASE_OFFSET: Timing offset for leg bounce vs body bounce
--   Creates slight delay between body and leg bounce
--   Higher = More separation, can look like "follow-through"
local LEG_BOUNCE_PHASE_OFFSET = 0.15

-- ============================================================================
-- GAIT PATTERN
-- Phase offsets create the diagonal gait (opposite legs move together)
-- ============================================================================

-- LegOffsets: Phase offset for each leg in the walk cycle (radians)
--   0 and π are opposite phases (when one is forward, other is back)
--   Current pattern: FL+BR together, FR+BL together (diagonal/trot gait)
--   
--   Alternative patterns:
--   - Pace gait (same-side legs): FL=0, BL=0, FR=π, BR=π
--   - Walk (sequential): FL=0, FR=π/2, BL=π, BR=3π/2
local LegOffsets: {[string]: number} = {
	LegFL = 0,        -- Front-left: phase 0
	LegFR = math.pi,  -- Front-right: opposite phase
	LegBL = math.pi,  -- Back-left: opposite phase (pairs with FR)
	LegBR = 0         -- Back-right: same phase as FL (diagonal pair)
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
