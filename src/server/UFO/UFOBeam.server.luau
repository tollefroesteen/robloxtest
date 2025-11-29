local UFOModel = workspace.UFO
local ufo = UFOModel.PrimaryPart -- Make sure PrimaryPart is set
local ServerScriptService = game:GetService("ServerScriptService")
local eventsFolder = ServerScriptService:FindFirstChild("ServerEvents")
local spawnEvent = eventsFolder:FindFirstChild("FlockSpawnedEvent")

-- Beam configuration
local sphereCount = 50
local spacing = 1.5
local baseSize = Vector3.new(1, 1, 1)
local beamSpeed = 15
local beamLength = sphereCount * spacing
local maxScale = 20
local vibrationAmount = 0.2
local beamDuration = 3          -- seconds to show the beam after spawn

-- Storage
local spheres = {}
local beamActive = false
local beamEndTime = 0

-- Create spheres (hidden initially)
for i = 1, sphereCount do
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = baseSize
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Material = Enum.Material.Neon
	sphere.BrickColor = BrickColor.new("Bright blue")
	sphere.Transparency = 1 -- hidden
	sphere.Parent = workspace
	table.insert(spheres, sphere)
end

local RunService = game:GetService("RunService")

-- Function to activate beam
local function activateBeam()
	beamActive = true
	beamEndTime = tick() + beamDuration
	for _, sphere in ipairs(spheres) do
		sphere.Transparency = 0.7 -- initial visible state
	end
end

spawnEvent.Event:Connect(activateBeam)

-- Update loop
RunService.Heartbeat:Connect(function(dt)
	if not beamActive then return end

	local ufoPos = ufo.Position
	local time = tick()

	for i, sphere in ipairs(spheres) do
		-- Continuous vertical position using modulo to loop
		local offset = (i - 1) * spacing
		local y = ufoPos.Y - ((time * beamSpeed + offset) % beamLength)
		sphere.Position = Vector3.new(ufoPos.X, y, ufoPos.Z)

		-- Growth factor based on distance from UFO
		local distanceFromTop = ufoPos.Y - y
		local t = math.clamp(distanceFromTop / beamLength, 0, 1)
		local growth = 1 + (maxScale - 1) * t

		-- Vibration
		local vibration = math.sin(time * 10 + i) * vibrationAmount
		local scale = baseSize * (growth + vibration)
		sphere.Size = scale

		-- Transparency gradient
		sphere.Transparency = 0.7 * (1 - t)
	end

	-- Disable beam after duration
	if tick() > beamEndTime then
		beamActive = false
		for _, sphere in ipairs(spheres) do
			sphere.Transparency = 1
		end
	end
end)
