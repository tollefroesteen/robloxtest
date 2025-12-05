--!strict
-- PetFollowController.luau (Lobby Client)
-- Handles smooth visual interpolation and animation for pet animals
-- Similar to arena's AnimalController but simplified for pets

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PetFollowController = {}

local LocalPlayer = Players.LocalPlayer

-- Wait for Pets folder (created by server)
local PetsFolder: Folder? = nil

-- ============================================================================
-- BODY FOLLOW TUNING
-- ============================================================================
local FOLLOW_LERP = 0.25      -- How quickly visual follows root position
local ROTATION_LERP = 0.12    -- How quickly visual rotates to face direction
local HEIGHT_OFFSET = 1       -- Visual height above root (lower than arena since pets are ground-level)

-- ============================================================================
-- BODY BOUNCE (BOB) ANIMATION
-- ============================================================================
local BOB_AMPLITUDE = 0.4     -- Up/down bounce amount
local BOB_FREQUENCY = 12      -- Bounce speed

-- ============================================================================
-- LEG ANIMATION
-- ============================================================================
local LEG_FREQUENCY = 8           -- Walk cycle speed
local LEG_SWING_DEGREES = 20      -- Leg rotation amount
local LEG_LIFT = 0.12             -- How high legs lift
local LEG_PUSH = 0.08             -- Forward/back leg movement
local LEG_BOUNCE_FACTOR = 0.15    -- Leg response to body bob

-- Gait pattern (diagonal)
local LegOffsets: {[string]: number} = {
	LegFL = 0,
	LegFR = math.pi,
	LegBL = math.pi,
	LegBR = 0
}

-- ============================================================================
-- STATE
-- ============================================================================

-- Bind pose storage per pet
local bindPose: { [BasePart]: {
	visualLocal: CFrame,
	bounceLocal: CFrame,
	legs: { [string]: CFrame },
	visualPart: BasePart,
	bouncePart: BasePart
} } = {}

local lastPos: { [BasePart]: Vector3 } = {}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function ensurePhase(root: BasePart): number
	local p = root:GetAttribute("BouncePhase")
	if not p then
		p = math.random() * math.pi * 2
		root:SetAttribute("BouncePhase", p)
	end
	return p :: number
end

local function getPivotLocal(leg: BasePart): Vector3
	return Vector3.new(
		leg:GetAttribute("PivotX") or 0,
		leg:GetAttribute("PivotY") or 0,
		leg:GetAttribute("PivotZ") or 0
	)
end

local function getOffset(leg: BasePart): Vector3
	return Vector3.new(
		leg:GetAttribute("OffsetX") or 0,
		leg:GetAttribute("OffsetY") or 0,
		leg:GetAttribute("OffsetZ") or 0
	)
end

-- Capture the bind pose of a pet on first sighting
local function captureBindPose(root: BasePart)
	if bindPose[root] then return end
	if root:GetAttribute("ReadyForFlocking") ~= true then return end
	
	local data: any = { legs = {} }
	
	-- Find Visual
	for _, c in root:GetChildren() do
		if c:IsA("BasePart") and c ~= root then
			local visual = c
			data.visualLocal = root.CFrame:ToObjectSpace(visual.CFrame)
			data.visualPart = visual
			
			-- Find Bouncepart
			for _, b in visual:GetChildren() do
				if b:IsA("BasePart") then
					local bounce = b
					data.bounceLocal = visual.CFrame:ToObjectSpace(bounce.CFrame)
					data.bouncePart = bounce
					
					-- Find legs
					local legCount = 0
					for _, l in bounce:GetChildren() do
						if l:IsA("BasePart") and (l.Name == "LegFL" or l.Name == "LegFR" or l.Name == "LegBL" or l.Name == "LegBR") then
							local legLocal = bounce.CFrame:ToObjectSpace(l.CFrame)
							data.legs[l.Name] = legLocal
							legCount += 1
						end
					end
					
					if legCount == 4 then
						bindPose[root] = data
					end
					return
				end
			end
		end
	end
end

-- ============================================================================
-- MAIN UPDATE LOOP
-- ============================================================================

local function updatePets()
	if not PetsFolder then
		PetsFolder = workspace:FindFirstChild("Pets") :: Folder?
		if not PetsFolder then return end
	end
	
	local t = tick()
	
	for _, root in PetsFolder:GetChildren() do
		if not root:IsA("BasePart") then continue end
		if root:GetAttribute("ReadyForFlocking") ~= true then continue end
		
		-- Only animate pets owned by local player (others will be animated by their clients)
		-- Actually, animate all pets for visual consistency
		
		-- Capture bind pose on first sighting
		captureBindPose(root)
		local conf = bindPose[root]
		if not conf then continue end
		
		local target = root:GetAttribute("TargetPos")
		if not target then continue end
		
		local bodyPhase = ensurePhase(root)
		
		-- Get cached parts
		local visual = conf.visualPart
		if not visual or not visual.Parent then continue end
		
		local bounce = conf.bouncePart
		if not bounce or not bounce.Parent then continue end
		
		-- Movement follow
		local targetPos = Vector3.new(target.X, target.Y + HEIGHT_OFFSET, target.Z)
		local newPos = visual.Position:Lerp(targetPos, FOLLOW_LERP)
		local facing = root.CFrame.LookVector
		local desired = CFrame.lookAt(newPos, newPos + facing)
		visual.CFrame = visual.CFrame:Lerp(desired, ROTATION_LERP)
		
		-- Body bounce
		local bob = math.sin(t * BOB_FREQUENCY + bodyPhase) * BOB_AMPLITUDE
		local bodyPos = Vector3.new(newPos.X, newPos.Y + bob, newPos.Z)
		local bounceCF = CFrame.new(bodyPos, bodyPos + facing)
		bounce.CFrame = bounceCF
		
		-- Detect movement
		local prev = lastPos[visual]
		local moving = prev and ((visual.Position - prev).Magnitude > 0.01)
		lastPos[visual] = visual.Position
		
		-- Leg animation base
		local legYOffset = bob * 0.35
		local legBaseCF = CFrame.new(newPos.X, newPos.Y + legYOffset, newPos.Z)
			* CFrame.fromOrientation(visual.CFrame:ToOrientation())
		
		-- Animate each leg
		for legName, baseLegLocal in conf.legs do
			local leg = bounce:FindFirstChild(legName)
			if not leg or not leg:IsA("BasePart") then continue end
			
			local stance = getOffset(leg)
			local pivot = getPivotLocal(leg)
			
			if not moving then
				-- Idle pose with subtle bob
				local idleLift = bob * LEG_BOUNCE_FACTOR
				leg.CFrame = legBaseCF
					* CFrame.new(stance)
					* baseLegLocal
					* CFrame.new(0, idleLift, 0)
				continue
			end
			
			-- Walking animation
			local phaseOffset = LegOffsets[legName] or 0
			local step = t * LEG_FREQUENCY + bodyPhase + phaseOffset
			
			local swing = math.rad(LEG_SWING_DEGREES) * math.sin(step)
			local lift = math.abs(math.cos(step)) * LEG_LIFT
			local push = math.sin(step) * LEG_PUSH
			
			local legBob = math.sin(t * BOB_FREQUENCY + bodyPhase + phaseOffset * 0.15)
				* BOB_AMPLITUDE * LEG_BOUNCE_FACTOR
			
			local anim = (CFrame.new(pivot)
				* CFrame.Angles(swing, 0, 0)
				* CFrame.new(-pivot))
				* CFrame.new(0, lift + legBob, push)
			
			leg.CFrame = legBaseCF
				* CFrame.new(stance)
				* baseLegLocal
				* anim
		end
	end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

local function cleanupPet(root: BasePart)
	bindPose[root] = nil
	lastPos[root] = nil
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PetFollowController.Init()
	-- Connect to render loop
	RunService.RenderStepped:Connect(updatePets)
	
	-- Watch for pets being removed
	task.spawn(function()
		while not PetsFolder do
			PetsFolder = workspace:FindFirstChild("Pets") :: Folder?
			if not PetsFolder then
				task.wait(0.5)
			end
		end
		
		PetsFolder.ChildRemoved:Connect(function(child)
			if child:IsA("BasePart") then
				cleanupPet(child)
			end
		end)
	end)
end

return PetFollowController
