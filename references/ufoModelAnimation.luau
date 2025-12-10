--[[
    Refined Cartoon UFO (Sleeker Saucer Version)
    - Very flat saucer sphere
    - Center sphere protrudes top & bottom (clean design)
    - Subtle neon accents
    - Professional cartoon proportions
]]

--------------------------------------------------
-- Helper
--------------------------------------------------
local function newPart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Name = props.name or "Part"
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Color = props.color or Color3.new(1, 1, 1)
	p.Size = props.size or Vector3.new(4, 4, 4)
	p.Position = props.position or Vector3.new(0, 25, 0)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

--------------------------------------------------
-- Model
--------------------------------------------------
local UFO = Instance.new("Model")
UFO.Name = "RefinedSlimUFO"
UFO.Parent = workspace

local origin = Vector3.new(0, 25, 0)

--------------------------------------------------
-- 1) SAUCER — very flat sphere for a more refined look
--------------------------------------------------
local saucer = newPart(UFO, {
	name = "Saucer",
	size = Vector3.new(26, 26, 26),
	position = origin,
	material = Enum.Material.Metal,
	color = Color3.fromRGB(118, 132, 150) -- subtle neutral sci-fi tone
})

local saucerMesh = Instance.new("SpecialMesh")
saucerMesh.MeshType = Enum.MeshType.Sphere
-- MUCH flatter saucer now — about 18% height
saucerMesh.Scale = Vector3.new(1, 0.18, 1)
saucerMesh.Parent = saucer

--------------------------------------------------
-- 2) CENTER SPHERE — symmetrical aesthetic dome
--------------------------------------------------
local dome = newPart(UFO, {
	name = "CenterSphere",
	size = Vector3.new(13, 13, 13),
	position = origin,
	material = Enum.Material.Glass,
	color = Color3.fromRGB(165, 200, 255)
})

local domeMesh = Instance.new("SpecialMesh")
domeMesh.MeshType = Enum.MeshType.Sphere
domeMesh.Parent = dome

--------------------------------------------------
-- 3) Thin neon rim accent (more elegant)
--------------------------------------------------
local rim = newPart(UFO, {
	name = "GlowRim",
	size = Vector3.new(28, 1, 28),
	position = origin + Vector3.new(0, -1.2, 0),
	material = Enum.Material.Neon,
	color = Color3.fromRGB(0, 255, 190)
})

local rimMesh = Instance.new("SpecialMesh")
rimMesh.MeshType = Enum.MeshType.Sphere
rimMesh.Scale = Vector3.new(1, 0.05, 1) -- razor thin glow band
rimMesh.Parent = rim

--------------------------------------------------
-- 4) Edge lights — refined, smaller, softer glow
--------------------------------------------------
local lightsFolder = Instance.new("Folder")
lightsFolder.Name = "EdgeLights"
lightsFolder.Parent = UFO

local ORB_COUNT = 12
local ORB_RADIUS = 13

for i = 1, ORB_COUNT do
	local orb = newPart(lightsFolder, {
		name = "LightOrb_" .. i,
		size = Vector3.new(0.9, 0.9, 0.9),
		material = Enum.Material.Neon,
		color = Color3.fromRGB(255, 120, 150),
	})
	orb.Shape = Enum.PartType.Ball
	orb.Position = origin

	-- softer, controlled light
	local light = Instance.new("PointLight")
	light.Range = 8
	light.Brightness = 0.9
	light.Color = orb.Color
	light.Parent = orb
end

--------------------------------------------------
-- 5) Engine glow inside dome — subtle, not toy-like
--------------------------------------------------
local engine = Instance.new("PointLight")
engine.Parent = dome
engine.Range = 18
engine.Brightness = 2
engine.Color = Color3.fromRGB(0, 200, 255)

--------------------------------------------------
-- 6) Hover + refined light animation
--------------------------------------------------
task.spawn(function()
	local t = 0

	while true do
		t += 0.02

		-- Very smooth hover
		local hover = math.sin(t * 1.15) * 0.45
		local basePos = origin + Vector3.new(0, hover, 0)

		saucer.Position = basePos
		dome.Position = basePos
		rim.Position = basePos + Vector3.new(0, -1.2, 0)

		-- Edge light rotation
		for i, orb in ipairs(lightsFolder:GetChildren()) do
			local angle = (i / ORB_COUNT) * math.pi * 2 + t * 1.1
			local x = math.cos(angle) * ORB_RADIUS
			local z = math.sin(angle) * ORB_RADIUS

			orb.Position = basePos + Vector3.new(x, -0.8, z)

			-- slight shimmer, not rainbow
			local pulse = (math.sin(t * 2.8 + i) + 1) / 2
			orb.Color = Color3.fromRGB(
				220 + pulse * 30,
				70 + pulse * 20,
				110 + pulse * 25
			)

			local pl = orb:FindFirstChildOfClass("PointLight")
			if pl then
				pl.Color = orb.Color
				pl.Brightness = 0.8 + pulse * 0.6
			end
		end

		-- Engine pulse inside dome
		engine.Brightness = 1.8 + math.sin(t * 2.2) * 1.1

		task.wait()
	end
end)
