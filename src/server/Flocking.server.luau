local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Flock = workspace:WaitForChild("Flock")

-- Timestep
local TICK = 1/20

-- Flocking settings
local BASE_SPEED = 0.5
local NEIGHBOR_RADIUS = 25
local SEPARATION_DISTANCE = 6

-- Player interaction
local PLAYER_AVOID_RADIUS = 35
local PLAYER_PANIC_RADIUS = 9

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

-- Neighbor finder (ignores captured animals)
local function getNeighbors(root)
	local neighbors = {}
	for _, other in ipairs(Flock:GetChildren()) do
		if other ~= root
			and other:IsA("BasePart")
			and other:GetAttribute("Captured") ~= true
		then
			if (other.Position - root.Position).Magnitude < NEIGHBOR_RADIUS then
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
		local vel = velocities[root] or Vector3.zero

		-- Player proximity (for panic)
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

		-- Trigger panic if very close to player
		if playerDist < PLAYER_PANIC_RADIUS then
			panicUntil[root] = now + PANIC_TIME
			isPanicking = true
		end

		if isPanicking then
			-- Strong flee, but still lerped for smoothness
			if playerDir.Magnitude > 0 then
				local fleeDir = playerDir.Unit
				local fleeVel = fleeDir * (maxSpeed * PANIC_BOOST)
				vel = vel:Lerp(fleeVel, 0.4)
			end
		else
			-- Standard boids
			local neighbors = getNeighbors(root)
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

			-- Player avoidance (non-panic)
			if playerDist < PLAYER_AVOID_RADIUS and playerDir.Magnitude > 0 then
				local t = 1 - (playerDist / PLAYER_AVOID_RADIUS) -- 0..1
				desired += playerDir.Unit * (t * AVOID_FORCE)
			end

			if desired.Magnitude > 0 then
				desired = desired.Unit * maxSpeed
			end

			-- Decay old momentum slightly
			vel *= MOMENTUM_DECAY

			-- Smoothly turn toward desired
			vel = vel:Lerp(desired, TURN_SMOOTH)
		end

		-- Cap speed (higher cap while panicking)
		local speedCap = isPanicking and (maxSpeed * PANIC_BOOST) or maxSpeed
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
