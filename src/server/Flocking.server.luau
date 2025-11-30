local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Flock = workspace:WaitForChild("Flock")

-- Timestep
local TICK = 1/20

-- Flocking settings (fallback defaults)
local BASE_SPEED = 0.5
local BASE_OBSERVATION_RADIUS = 25
local SEPARATION_DISTANCE = 6

-- Player interaction (fallback defaults)
local BASE_PLAYER_AVOID_RADIUS = 35
local PLAYER_PANIC_RADIUS = 9
local BASE_FEAR_FACTOR = 1.0  -- Multiplier for panic/avoid behavior

-- Motion shaping
local TURN_SMOOTH = 0.22
local MOMENTUM_DECAY = 0.97

-- Panic behavior
local PANIC_TIME = 0.35     -- stay scared this long
local PANIC_BOOST = 2.2     -- panic speed multiplier
local AVOID_FORCE = 1.6     -- base avoid power

-- State
local velocities = {}       -- [BasePart] = Vector3
local panicUntil = {}       -- [BasePart] = timestamp
local acc = 0

-- Neighbor finder (ignores captured animals, uses per-animal ObservationRadius)
local function getNeighbors(root, observationRadius)
	local neighbors = {}
	local radius = observationRadius or BASE_OBSERVATION_RADIUS
	for _, other in ipairs(Flock:GetChildren()) do
		if other ~= root
			and other:IsA("BasePart")
			and other:GetAttribute("Captured") ~= true
		then
			if (other.Position - root.Position).Magnitude < radius then
				table.insert(neighbors, other)
			end
		end
	end
	return neighbors
end

RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < TICK then return end
	local step = acc
	acc = 0

	local now = tick()

	for _, root in ipairs(Flock:GetChildren()) do
		if not root:IsA("BasePart") then continue end

		-- If captured: freeze and skip flocking completely
		if root:GetAttribute("Captured") == true then
			velocities[root] = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			root:SetAttribute("TargetPos", root.Position)
			-- Optional: face forward persistently (skip if you don’t want rotation changes)
			-- root.CFrame = CFrame.lookAt(root.Position, root.Position + root.CFrame.LookVector, Vector3.yAxis)
			continue
		end

		local pos = root.Position
		local maxSpeed = root:GetAttribute("MaxSpeed") or BASE_SPEED
		local observationRadius = root:GetAttribute("ObservationRadius") or BASE_OBSERVATION_RADIUS
		local fearFactor = root:GetAttribute("FearFactor") or BASE_FEAR_FACTOR
		local vel = velocities[root] or Vector3.zero

		-- Player proximity (for panic) - scaled by FearFactor
		local isPanicking = panicUntil[root] and panicUntil[root] > now
		local playerDist = math.huge
		local playerDir = Vector3.zero

		for _, plr in ipairs(Players:GetPlayers()) do
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			local d = (hrp.Position - pos).Magnitude
			if d < playerDist then
				playerDist = d
				playerDir = (pos - hrp.Position)
			end
		end

		-- Trigger panic if very close to player (scaled by FearFactor)
		local panicRadius = PLAYER_PANIC_RADIUS * fearFactor
		if playerDist < panicRadius then
			panicUntil[root] = now + (PANIC_TIME * fearFactor)  -- More fearful = longer panic
			isPanicking = true
		end

		if isPanicking then
			-- Strong flee, but still lerped for smoothness (panic intensity scaled by FearFactor)
			if playerDir.Magnitude > 0 then
				local fleeDir = playerDir.Unit
				local panicBoost = PANIC_BOOST * (0.5 + fearFactor * 0.5)  -- Range: 1.1x to 2.2x
				local fleeVel = fleeDir * (maxSpeed * panicBoost)
				vel = vel:Lerp(fleeVel, 0.4)
			end
		else
			-- Standard boids (use per-animal ObservationRadius)
			local neighbors = getNeighbors(root, observationRadius)
			local separation = Vector3.zero
			local alignment  = Vector3.zero
			local cohesion   = Vector3.zero

			for _, n in ipairs(neighbors) do
				local diff = pos - n.Position
				local dist = diff.Magnitude

				if dist < SEPARATION_DISTANCE and dist > 0 then
					separation += diff.Unit / dist
				end

				alignment += velocities[n] or Vector3.zero
				cohesion += n.Position
			end

			local count = #neighbors
			if count > 0 then
				alignment /= count
				cohesion = ((cohesion / count) - pos).Unit
			end

			local desired = separation + alignment + cohesion

			-- Player avoidance (non-panic) - scaled by FearFactor
			local avoidRadius = BASE_PLAYER_AVOID_RADIUS * fearFactor
			if playerDist < avoidRadius and playerDir.Magnitude > 0 then
				local t = 1 - (playerDist / avoidRadius) -- 0..1
				local avoidForce = AVOID_FORCE * fearFactor
				desired += playerDir.Unit * (t * avoidForce)
			end

			if desired.Magnitude > 0 then
				desired = desired.Unit * maxSpeed
			end

			-- Decay old momentum slightly
			vel *= MOMENTUM_DECAY

			-- Smoothly turn toward desired
			vel = vel:Lerp(desired, TURN_SMOOTH)
		end

		-- Cap speed (higher cap while panicking, scaled by FearFactor)
		local panicBoost = PANIC_BOOST * (0.5 + fearFactor * 0.5)
		local speedCap = isPanicking and (maxSpeed * panicBoost) or maxSpeed
		if vel.Magnitude > speedCap then
			vel = vel.Unit * speedCap
		end

		velocities[root] = vel

		-- Constrain to XZ plane for motion
		vel = Vector3.new(vel.X, 0, vel.Z)
		local newPos = pos + vel * step

		-- Rotate to face motion if moving
		if vel.Magnitude > 0.001 then
			root.CFrame = CFrame.lookAt(newPos, newPos + vel, Vector3.yAxis)
		end

		-- Use physics for motion for better collisions; tune multiplier for feel
		root.AssemblyLinearVelocity = vel * 30

		-- Expose target for client visual smoothing
		root:SetAttribute("TargetPos", newPos)
	end
end)
