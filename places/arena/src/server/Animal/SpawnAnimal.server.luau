local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameEvent = ServerEvents.StartGameEvent
local spawnEvent = ServerEvents.FlockSpawnedEvent
local animalsFolder = ServerScriptService.Server.Animal
local PartLibrary = require(animalsFolder:WaitForChild("AnimalLibraryModule"))
local AnimalBuilder = require(animalsFolder:WaitForChild("AnimalBuilder"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Keep AnimalTemplate as fallback if builder fails
local AnimalTemplate = ReplicatedStorage:FindFirstChild("AnimalTemplate")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local AnimalSpawnedEvent = RemoteEvents.AnimalSpawnedEvent
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

-- Configuration flag: set to true to use new template system, false for legacy template
local USE_DYNAMIC_TEMPLATES = true


local UFOModel = workspace.UFO
local ufo = UFOModel.PrimaryPart

local gameEnded = true

local SpawnConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArenaConfig"):WaitForChild("SpawnConfig"))
local spawnInterval = SpawnConfig.INTERVAL
local burstSize = SpawnConfig.BURST_SIZE
local maxConcurrent = SpawnConfig.MAX_CONCURRENT
local startDelay = SpawnConfig.START_DELAY
local partSize = Vector3.new(2, 2, 4)

-- Telemetry: track spawn statistics (UFO-10)
local spawnCount = 0
local spawnStartTime = os.clock()
local lastTelemetryLog = os.clock()

local spawnFolder = workspace:FindFirstChild("Flock") or Instance.new("Folder")
spawnFolder.Name = "Flock"
spawnFolder.Parent = workspace

local RunService = game:GetService("RunService")

-- Raycast to find TERRAIN surface position only
local function getTerrainSurfacePosition(x: number, z: number, startY: number): Vector3
	local rayOrigin = Vector3.new(x, startY + 100, z)
	local rayDirection = Vector3.new(0, -300, 0)
	
	-- Only hit terrain, ignore all other objects
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { workspace.Terrain }
	raycastParams.IgnoreWater = false
	
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if result then
		local terrainY = result.Position.Y + 2  -- 2 studs above terrain
		
		-- Check if there's an obstacle at this position
		local checkParams = RaycastParams.new()
		checkParams.FilterType = Enum.RaycastFilterType.Exclude
		checkParams.FilterDescendantsInstances = { workspace.Terrain, spawnFolder, UFOModel }
		
		local obstacleCheck = workspace:Raycast(
			Vector3.new(x, terrainY + 10, z),
			Vector3.new(0, -12, 0),
			checkParams
		)
		
		if obstacleCheck then
			-- There's something here, try a slight offset
			local offsetAngle = math.random() * math.pi * 2
			local offsetDist = 3 + math.random() * 4
			return Vector3.new(
				x + math.cos(offsetAngle) * offsetDist,
				terrainY,
				z + math.sin(offsetAngle) * offsetDist
			)
		end
		
		return Vector3.new(x, terrainY, z)
	end
	
	-- Fallback
	return Vector3.new(x, startY, z)
end

local function canSpawn(): boolean
	local flock = workspace:FindFirstChild("Flock")
	if not flock then return false end
	local count = #flock:GetChildren()
	return count < maxConcurrent
end

local function spawnPart()
	if gameEnded then 
		Log.Debug("SpawnAnimal", "Spawn skipped: game ended")
		return 
	end
	if not canSpawn() then 
		Log.Debug("SpawnAnimal", string.format("Spawn skipped: at capacity (%d/%d)", #workspace.Flock:GetChildren(), maxConcurrent))
		return 
	end
	local ufoPos = ufo.Position
	local chosenType = PartLibrary.GetRandomType()
	
	-- Use raycasting to find terrain surface
	local spawnPos = getTerrainSurfacePosition(ufoPos.X, ufoPos.Z, ufoPos.Y)

	local clone
	
	if USE_DYNAMIC_TEMPLATES then
		-- Build animal dynamically from template configuration AT spawn position
		local templateID = chosenType.Template or "BASIC_QUADRUPED"
		clone = AnimalBuilder.BuildAnimal(templateID, chosenType.Color, spawnPos)
		clone:SetAttribute("TemplateID", templateID)
		Log.Debug("SpawnAnimal", string.format("Built animal using template: %s", templateID))
	else
		-- Legacy: clone static template from ReplicatedStorage
		if AnimalTemplate then
			clone = AnimalTemplate:Clone()
			-- Legacy mode still needs to move parts
			local templatePos = clone.Position
			local offset = spawnPos - templatePos
			clone.CFrame = clone.CFrame + offset
			for _, child in ipairs(clone:GetDescendants()) do
				if child:IsA("BasePart") then
					child.CFrame = child.CFrame + offset
				end
			end
		else
			Log.Warn("SpawnAnimal", "AnimalTemplate not found in ReplicatedStorage")
			return
		end
	end

	-- Attributes
	clone:SetAttribute("PointValue", chosenType.PointValue)
	clone:SetAttribute("CurrentPointValue", chosenType.PointValue)
	clone:SetAttribute("MaxSpeed", chosenType.MaxSpeed)
	clone:SetAttribute("Hungriness", chosenType.Hungriness)
	clone:SetAttribute("FearFactor", chosenType.FearFactor)
	clone:SetAttribute("ObservationRadius", chosenType.ObservationRadius)
	clone:SetAttribute("ID", chosenType.ID)	
	clone:SetAttribute("Team", "None")
	clone:SetAttribute("InCage", false)
	clone:SetAttribute("MovementState", "Falling")

	-- Set color on body (Bouncepart)
	local visual = clone:FindFirstChild("Visual")
	if visual then
		local bouncepart = visual:FindFirstChild("Bouncepart")
		if bouncepart then
			bouncepart.Color = chosenType.Color.Color -- Convert BrickColor to Color3
		end
	end
	
	-- Animal is already at correct position - just parent to workspace
	clone.Parent = workspace.Flock
	
	clone:SetNetworkOwner(nil)
	
	-- Mark as ready for flocking AFTER positions have replicated to clients
	-- Use delay to give network time to sync part positions
	task.delay(0.5, function()
		if clone and clone.Parent then
			clone:SetAttribute("ReadyForFlocking", true)
		end
	end)

	-- Telemetry: increment spawn count
	spawnCount += 1
	Log.Debug("SpawnAnimal", string.format("Spawned animal #%d (Type: %s, Points: %d, Template: %s)", 
		spawnCount, chosenType.ID, chosenType.PointValue, chosenType.Template or "BASIC_QUADRUPED"))

	AnimalSpawnedEvent:FireAllClients(clone)
	spawnEvent:Fire(clone)
end



-- Telemetry: log spawn rate every 60 seconds (UFO-10)
local function logTelemetry()
	local now = os.clock()
	local elapsedSinceLog = now - lastTelemetryLog
	
	if elapsedSinceLog >= 60 then
		local totalElapsed = now - spawnStartTime
		local spawnsPerMinute = if totalElapsed > 0 then (spawnCount / totalElapsed) * 60 else 0
		local currentFlock = workspace:FindFirstChild("Flock")
		local currentCount = if currentFlock then #currentFlock:GetChildren() else 0
		
		Log.Info("SpawnAnimal", string.format(
			"Telemetry | Total Spawns: %d | Rate: %.1f/min | Current Flock: %d/%d | Uptime: %.1fs",
			spawnCount,
			spawnsPerMinute,
			currentCount,
			maxConcurrent,
			totalElapsed
		))
		
		lastTelemetryLog = now
	end
end

-- Loop
local accumulator = 0
task.delay(startDelay, function()
	Log.Info("SpawnAnimal", string.format("Spawner started (Delay: %.1fs, Interval: %.1fs, Burst: %d, Max: %d)", 
		startDelay, spawnInterval, burstSize, maxConcurrent))
	
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		
		-- Telemetry logging
		logTelemetry()
		
		if accumulator >= spawnInterval then
			accumulator = 0
			for i = 1, burstSize do
				spawnPart()
			end
		end
	end)
end)


-- React to timer ending
TimerEndedEvent.Event:Connect(function()
	Log.Info("SpawnAnimal", string.format("Spawner stopped (Total spawns this session: %d)", spawnCount))
	gameEnded = true
end)

-- Listen for StartGameEvent
StartGameEvent.Event:Connect(function()
	Log.Info("SpawnAnimal", "Game started - spawner active")
	gameEnded = false
	-- Reset telemetry for new game session
	spawnCount = 0
	spawnStartTime = os.clock()
	lastTelemetryLog = os.clock()
end)
