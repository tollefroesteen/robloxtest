--!strict
-- UFOBuilder.luau
-- Builds a refined cartoon UFO model from code
-- Based on the sleek saucer design with neon accents

local UFOBuilder = {}

-- Helper function to create parts with common properties
local function newPart(parent: Instance, props: {
	name: string?,
	material: Enum.Material?,
	color: Color3?,
	size: Vector3?,
	position: Vector3?,
	transparency: number?,
	shape: Enum.PartType?,
}): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Name = props.name or "Part"
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Color = props.color or Color3.new(1, 1, 1)
	part.Size = props.size or Vector3.new(4, 4, 4)
	part.Position = props.position or Vector3.new(0, 25, 0)
	part.Transparency = props.transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	
	if props.shape then
		part.Shape = props.shape
	end
	
	part.Parent = parent
	return part
end

-- Configuration for UFO appearance
export type UFOConfig = {
	-- Saucer settings
	saucerSize: number?,
	saucerFlatness: number?,
	saucerColor: Color3?,
	
	-- Dome settings
	domeSize: number?,
	domeColor: Color3?,
	
	-- Rim settings
	rimColor: Color3?,
	
	-- Edge lights
	lightCount: number?,
	lightRadius: number?,
	lightColor: Color3?,
	
	-- Engine glow
	engineColor: Color3?,
}

local DEFAULT_CONFIG: UFOConfig = {
	saucerSize = 26,
	saucerFlatness = 0.18,
	saucerColor = Color3.fromRGB(118, 132, 150),
	
	domeSize = 13,
	domeColor = Color3.fromRGB(165, 200, 255),
	
	rimColor = Color3.fromRGB(0, 255, 190),
	
	lightCount = 12,
	lightRadius = 13,
	lightColor = Color3.fromRGB(255, 120, 150),
	
	engineColor = Color3.fromRGB(0, 200, 255),
}

-- Build the UFO model
function UFOBuilder.Build(position: Vector3, config: UFOConfig?): Model
	local cfg = config or DEFAULT_CONFIG
	
	-- Merge with defaults
	local saucerSize = cfg.saucerSize or DEFAULT_CONFIG.saucerSize :: number
	local saucerFlatness = cfg.saucerFlatness or DEFAULT_CONFIG.saucerFlatness :: number
	local saucerColor = cfg.saucerColor or DEFAULT_CONFIG.saucerColor :: Color3
	local domeSize = cfg.domeSize or DEFAULT_CONFIG.domeSize :: number
	local domeColor = cfg.domeColor or DEFAULT_CONFIG.domeColor :: Color3
	local rimColor = cfg.rimColor or DEFAULT_CONFIG.rimColor :: Color3
	local lightCount = cfg.lightCount or DEFAULT_CONFIG.lightCount :: number
	local lightRadius = cfg.lightRadius or DEFAULT_CONFIG.lightRadius :: number
	local lightColor = cfg.lightColor or DEFAULT_CONFIG.lightColor :: Color3
	local engineColor = cfg.engineColor or DEFAULT_CONFIG.engineColor :: Color3
	
	-- Create model
	local ufoModel = Instance.new("Model")
	ufoModel.Name = "UFO"
	
	-- 1) SAUCER — very flat sphere for a refined look
	local saucer = newPart(ufoModel, {
		name = "Saucer",
		size = Vector3.new(saucerSize, saucerSize, saucerSize),
		position = position,
		material = Enum.Material.Metal,
		color = saucerColor,
	})
	
	local saucerMesh = Instance.new("SpecialMesh")
	saucerMesh.MeshType = Enum.MeshType.Sphere
	saucerMesh.Scale = Vector3.new(1, saucerFlatness, 1)
	saucerMesh.Parent = saucer
	
	-- Set as primary part for model positioning
	ufoModel.PrimaryPart = saucer
	
	-- 2) CENTER SPHERE — symmetrical aesthetic dome
	local dome = newPart(ufoModel, {
		name = "CenterSphere",
		size = Vector3.new(domeSize, domeSize, domeSize),
		position = position,
		material = Enum.Material.Glass,
		color = domeColor,
		transparency = 0.3,
	})
	
	local domeMesh = Instance.new("SpecialMesh")
	domeMesh.MeshType = Enum.MeshType.Sphere
	domeMesh.Parent = dome
	
	-- 3) Thin neon rim accent
	local rimSize = saucerSize + 2
	local rim = newPart(ufoModel, {
		name = "GlowRim",
		size = Vector3.new(rimSize, 1, rimSize),
		position = position + Vector3.new(0, -1.2, 0),
		material = Enum.Material.Neon,
		color = rimColor,
	})
	
	local rimMesh = Instance.new("SpecialMesh")
	rimMesh.MeshType = Enum.MeshType.Sphere
	rimMesh.Scale = Vector3.new(1, 0.05, 1)
	rimMesh.Parent = rim
	
	-- 4) Edge lights folder
	local lightsFolder = Instance.new("Folder")
	lightsFolder.Name = "EdgeLights"
	lightsFolder.Parent = ufoModel
	
	for i = 1, lightCount do
		local angle = (i / lightCount) * math.pi * 2
		local x = math.cos(angle) * lightRadius
		local z = math.sin(angle) * lightRadius
		
		local orb = newPart(lightsFolder, {
			name = "LightOrb_" .. i,
			size = Vector3.new(0.9, 0.9, 0.9),
			position = position + Vector3.new(x, -0.8, z),
			material = Enum.Material.Neon,
			color = lightColor,
			shape = Enum.PartType.Ball,
		})
		
		-- Point light for glow effect
		local light = Instance.new("PointLight")
		light.Range = 8
		light.Brightness = 0.9
		light.Color = orb.Color
		light.Parent = orb
	end
	
	-- 5) Engine glow inside dome
	local engineLight = Instance.new("PointLight")
	engineLight.Name = "EngineLight"
	engineLight.Range = 18
	engineLight.Brightness = 2
	engineLight.Color = engineColor
	engineLight.Parent = dome
	
	-- Store light configuration for animation
	ufoModel:SetAttribute("LightCount", lightCount)
	ufoModel:SetAttribute("LightRadius", lightRadius)
	
	return ufoModel
end

-- Start the ambient animation (spinning lights + color effects)
function UFOBuilder.StartAmbientAnimation(ufoModel: Model)
	local saucer = ufoModel:FindFirstChild("Saucer") :: Part?
	local dome = ufoModel:FindFirstChild("CenterSphere") :: Part?
	local lightsFolder = ufoModel:FindFirstChild("EdgeLights") :: Folder?
	
	local engineLight = dome and dome:FindFirstChild("EngineLight") :: PointLight?
	
	-- Get light configuration
	local lightCount = ufoModel:GetAttribute("LightCount") or 12
	local lightRadius = ufoModel:GetAttribute("LightRadius") or 13
	
	task.spawn(function()
		local t = 0
		local spinSpeed = 0.8  -- Radians per second for light rotation
		
		while ufoModel and ufoModel.Parent do
			local dt = task.wait(0.025)  -- ~40 FPS update rate
			t += dt
			
			-- Get current UFO CFrame (includes position AND rotation)
			local saucerCFrame = saucer and saucer.CFrame or CFrame.new()
			
			-- Spin and animate edge lights
			if lightsFolder then
				local lights = lightsFolder:GetChildren()
				for i, orb in ipairs(lights) do
					if orb:IsA("BasePart") then
						-- Calculate spinning position around the UFO in LOCAL space
						local baseAngle = (i / #lights) * math.pi * 2
						local currentAngle = baseAngle + t * spinSpeed
						local localOffset = Vector3.new(
							math.cos(currentAngle) * lightRadius,
							-0.8,
							math.sin(currentAngle) * lightRadius
						)
						
						-- Transform local offset to world space using UFO's CFrame
						-- This makes lights follow UFO rotation (tilting)
						local worldPos = saucerCFrame:PointToWorldSpace(localOffset)
						orb.Position = worldPos
						
						-- Color shimmer effect
						local pulse = (math.sin(t * 2.8 + i) + 1) / 2
						orb.Color = Color3.fromRGB(
							math.floor(220 + pulse * 30),
							math.floor(70 + pulse * 20),
							math.floor(110 + pulse * 25)
						)
						
						local pointLight = orb:FindFirstChildOfClass("PointLight")
						if pointLight then
							pointLight.Color = orb.Color
							pointLight.Brightness = 0.8 + pulse * 0.6
						end
					end
				end
			end
			
			-- Engine pulse inside dome
			if engineLight then
				engineLight.Brightness = 1.8 + math.sin(t * 2.2) * 1.1
			end
		end
	end)
end

-- Raycast down to find terrain surface position
-- Returns the surface position, or nil if no terrain found
function UFOBuilder.GetTerrainSurfacePosition(position: Vector3, maxDistance: number?): Vector3?
	local Workspace = game:GetService("Workspace")
	
	local rayDistance = maxDistance or 500
	local rayOrigin = position + Vector3.new(0, 50, 0)  -- Start from above
	local rayDirection = Vector3.new(0, -rayDistance, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {}  -- Could add UFO model here if needed
	raycastParams.IgnoreWater = false
	
	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if result then
		-- Return position slightly above the surface
		return result.Position + Vector3.new(0, 0.5, 0)
	end
	
	return nil
end

-- Get a safe spawn position on terrain below a given point
-- Useful for spawning animals, items, lucky blocks from UFO
function UFOBuilder.GetSafeSpawnPosition(ufoPosition: Vector3, spreadRadius: number?): Vector3?
	local radius = spreadRadius or 10
	
	-- Random offset within spread radius
	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius
	local offsetX = math.cos(angle) * distance
	local offsetZ = math.sin(angle) * distance
	
	local targetPos = ufoPosition + Vector3.new(offsetX, 0, offsetZ)
	
	-- Raycast down to find terrain
	return UFOBuilder.GetTerrainSurfacePosition(targetPos)
end

-- Spawn something at a safe terrain position below the UFO
-- callback receives the safe position and should create/position the object
function UFOBuilder.SpawnAtTerrain(ufoModel: Model, spreadRadius: number?, callback: (position: Vector3) -> ()): boolean
	local saucer = ufoModel:FindFirstChild("Saucer") :: Part?
	if not saucer then
		warn("UFOBuilder: Cannot spawn - no saucer found")
		return false
	end
	
	local safePos = UFOBuilder.GetSafeSpawnPosition(saucer.Position, spreadRadius)
	if safePos then
		callback(safePos)
		return true
	else
		warn("UFOBuilder: Could not find terrain below UFO")
		return false
	end
end

return UFOBuilder
