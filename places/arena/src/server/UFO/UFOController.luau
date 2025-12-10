-- UFOController.lua
-- Smooth, organic UFO movement with natural banking and fluid motion
local RunService = game:GetService("RunService")

local UFOController = {}

-- Create state per UFO
function UFOController.New(ufoModel, config)
	assert(ufoModel.PrimaryPart, "UFO model must have a PrimaryPart")

	local self = {}
	self.model = ufoModel
	self.ufo = ufoModel.PrimaryPart

	-- Configurable parameters
	self.minX = config.minX or -100
	self.maxX = config.maxX or 100
	self.minY = config.minY or 10
	self.maxY = config.maxY or 60
	self.minZ = config.minZ or -60
	self.maxZ = config.maxZ or 60
	self.speed = config.speed or 10
	self.hoverTime = config.waitTime or 2
	self.maxBankAngle = config.maxTilt or math.rad(12)
	
	-- Smoothing parameters
	self.bankSmoothing = 0.08  -- How quickly the UFO banks (lower = smoother)
	self.positionSmoothing = 0.04  -- How quickly position changes
	self.rotationSmoothing = 0.06  -- How quickly rotation changes
	
	-- Current state
	self.currentVelocity = Vector3.zero
	self.currentBankX = 0
	self.currentBankZ = 0
	self.currentYaw = 0
	self.targetYaw = 0

	-- Internal state
	self.running = false

	return setmetatable(self, { __index = UFOController })
end

-- Smooth lerp helper
local function smoothDamp(current, target, smoothing, dt)
	return current + (target - current) * math.min(1, smoothing * dt * 60)
end

-- Generate a random waypoint within bounds
function UFOController:GetRandomWaypoint()
	return Vector3.new(
		math.random(self.minX, self.maxX),
		math.random(self.minY, self.maxY),
		math.random(self.minZ, self.maxZ)
	)
end

function UFOController:Start()
	if self.running then return end
	self.running = true
	
	-- Initialize yaw from current orientation
	local _, currentYaw, _ = self.ufo.CFrame:ToEulerAnglesYXZ()
	self.currentYaw = currentYaw
	self.targetYaw = currentYaw

	task.spawn(function()
		local currentTarget = self:GetRandomWaypoint()
		local timeAtTarget = 0
		local isHovering = false
		local hoverDuration = self.hoverTime + math.random() * 2  -- Randomize hover time
		
		local connection
		connection = RunService.Heartbeat:Connect(function(dt)
			if not self.running then
				connection:Disconnect()
				return
			end
			
			local currentPos = self.ufo.Position
			local toTarget = currentTarget - currentPos
			local distanceToTarget = toTarget.Magnitude
			
			-- Check if we've reached the target
			if distanceToTarget < 3 then
				if not isHovering then
					isHovering = true
					timeAtTarget = 0
					hoverDuration = self.hoverTime + math.random() * 2
				end
				
				timeAtTarget = timeAtTarget + dt
				
				if timeAtTarget >= hoverDuration then
					-- Pick new target
					currentTarget = self:GetRandomWaypoint()
					isHovering = false
				end
			end
			
			-- Calculate desired velocity toward target
			local direction = toTarget.Unit
			if distanceToTarget < 0.1 then
				direction = Vector3.zero
			end
			
			-- Speed ramps down as we approach target (smooth arrival)
			local speedMultiplier = math.clamp(distanceToTarget / 30, 0.1, 1)
			local targetVelocity = direction * self.speed * speedMultiplier
			
			-- Smoothly interpolate velocity
			self.currentVelocity = self.currentVelocity:Lerp(targetVelocity, self.positionSmoothing * dt * 60)
			
			-- Apply velocity to position
			local newPos = currentPos + self.currentVelocity * dt
			
			-- Add subtle hover bob
			local time = tick()
			local hoverBob = math.sin(time * 1.2) * 0.3 + math.sin(time * 0.7) * 0.15
			newPos = newPos + Vector3.new(0, hoverBob * dt * 10, 0)
			
			-- Calculate banking based on horizontal velocity
			local horizontalVel = Vector3.new(self.currentVelocity.X, 0, self.currentVelocity.Z)
			local speed = horizontalVel.Magnitude
			
			-- Target bank angles based on movement direction
			local targetBankX = 0
			local targetBankZ = 0
			
			if speed > 0.5 then
				local normalizedVel = horizontalVel.Unit
				local bankIntensity = math.clamp(speed / self.speed, 0, 1)
				
				-- Bank in the direction of movement (tilt forward and into turns)
				targetBankX = -normalizedVel.Z * self.maxBankAngle * bankIntensity
				targetBankZ = normalizedVel.X * self.maxBankAngle * bankIntensity * 0.7
				
				-- Update target yaw to face movement direction
				self.targetYaw = math.atan2(-normalizedVel.X, -normalizedVel.Z)
			end
			
			-- Smoothly interpolate banking
			self.currentBankX = smoothDamp(self.currentBankX, targetBankX, self.bankSmoothing, dt)
			self.currentBankZ = smoothDamp(self.currentBankZ, targetBankZ, self.bankSmoothing, dt)
			
			-- Smoothly interpolate yaw rotation
			local yawDiff = self.targetYaw - self.currentYaw
			-- Handle angle wrapping
			while yawDiff > math.pi do yawDiff = yawDiff - math.pi * 2 end
			while yawDiff < -math.pi do yawDiff = yawDiff + math.pi * 2 end
			self.currentYaw = self.currentYaw + yawDiff * self.rotationSmoothing * dt * 60
			
			-- Add subtle idle wobble when hovering
			local wobbleX = 0
			local wobbleZ = 0
			if isHovering then
				wobbleX = math.sin(time * 0.8) * math.rad(1.5)
				wobbleZ = math.cos(time * 0.6) * math.rad(1)
			end
			
			-- Build final CFrame
			local rotation = CFrame.Angles(self.currentBankX + wobbleX, self.currentYaw, self.currentBankZ + wobbleZ)
			self.model:PivotTo(CFrame.new(newPos) * rotation)
		end)
	end)
end

function UFOController:Stop()
	self.running = false
end

return UFOController
