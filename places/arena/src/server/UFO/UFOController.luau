-- UFOController.lua
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
	self.waitTime = config.waitTime or 2
	self.maxTilt = config.maxTilt or math.rad(15)

	-- Easing function
	self.easeInOutSine = function(t)
		return -(math.cos(math.pi * t) - 1) / 2
	end

	-- Internal state
	self.running = false

	return setmetatable(self, { __index = UFOController })
end

function UFOController:Start()
	if self.running then return end
	self.running = true

	spawn(function()
		while self.running do
			-- Pick random target
			local target = Vector3.new(
				math.random(self.minX, self.maxX),
				math.random(self.minY, self.maxY),
				math.random(self.minZ, self.maxZ)
			)

			local startPos = self.ufo.Position
			local direction = (target - startPos).Unit
			local distance = (target - startPos).Magnitude
			local duration = distance / self.speed
			local elapsed = 0

			-- Heartbeat movement
			local connection
			connection = RunService.Heartbeat:Connect(function(dt)
				if elapsed >= duration then
					connection:Disconnect()
					return
				end

				elapsed = elapsed + dt
				local alpha = math.clamp(elapsed / duration, 0, 1)
				local easedAlpha = self.easeInOutSine(alpha)
				local newPos = startPos:Lerp(target, easedAlpha)

				local tiltFactor = math.sin(alpha * math.pi)
				local tiltX = -direction.Z * self.maxTilt * tiltFactor
				local tiltZ = direction.X * self.maxTilt * tiltFactor
				local tiltCFrame = CFrame.Angles(tiltX, 0, tiltZ)

				self.ufo.CFrame = CFrame.new(newPos) * tiltCFrame
			end)

			repeat task.wait() until elapsed >= duration

			-- Hover upright
			local hoverElapsed = 0
			while hoverElapsed < self.waitTime do
				local dt = RunService.Heartbeat:Wait()
				hoverElapsed = hoverElapsed + dt
				self.ufo.CFrame = CFrame.new(self.ufo.Position)
			end
		end
	end)
end

function UFOController:Stop()
	self.running = false
end

return UFOController
