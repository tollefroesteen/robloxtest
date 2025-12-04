local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameEvent = ServerEvents.StartGameEvent
local spawnEvent = ServerEvents.FlockSpawnedEvent
local animalsFolder = ServerScriptService.Server.Animal
local PartLibrary = require(animalsFolder:WaitForChild("AnimalLibraryModule"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimalTemplate = ReplicatedStorage:WaitForChild("AnimalTemplate")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local AnimalSpawnedEvent = RemoteEvents.AnimalSpawnedEvent
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))


local UFOModel = workspace.UFO
local ufo = UFOModel.PrimaryPart

local gameEnded = true

local SpawnConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config"):WaitForChild("SpawnConfig"))
local spawnInterval = SpawnConfig.INTERVAL
local burstSize = SpawnConfig.BURST_SIZE
local maxConcurrent = SpawnConfig.MAX_CONCURRENT
local startDelay = SpawnConfig.START_DELAY
local spawnHeight = 10
local partSize = Vector3.new(2, 2, 4)

-- Telemetry: track spawn statistics (UFO-10)
local spawnCount = 0
local spawnStartTime = os.clock()
local lastTelemetryLog = os.clock()

local spawnFolder = workspace:FindFirstChild("Flock") or Instance.new("Folder")
spawnFolder.Name = "Flock"
spawnFolder.Parent = workspace

local RunService = game:GetService("RunService")

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

	local clone = AnimalTemplate:Clone()
	
	-- Calculate offset from template position to spawn position
	local templatePos = clone.Position
	local spawnPos = Vector3.new(ufoPos.X, spawnHeight, ufoPos.Z)
	local offset = spawnPos - templatePos

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

	clone.Visual.Bouncepart.Color = chosenType.Color.Color -- Convert BrickColor to Color3
	
	-- Move all parts to spawn position (all are anchored, so move each individually)
	clone.CFrame = clone.CFrame + offset
	for _, child in ipairs(clone:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CFrame = child.CFrame + offset
		end
	end
	
	clone.Parent = workspace.Flock  -- put in workspace after positioning
	
	clone:SetNetworkOwner(nil) -- server owns, allows client visual control (must be parented to workspace first)

	-- Telemetry: increment spawn count
	spawnCount += 1
	Log.Debug("SpawnAnimal", string.format("Spawned animal #%d (Type: %s, Points: %d)", spawnCount, chosenType.ID, chosenType.PointValue))

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
