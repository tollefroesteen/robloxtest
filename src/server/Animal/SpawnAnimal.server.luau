local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local TimerEndedEvent = ServerEvents.TimerEndedEvent
local StartGameEvent = ServerEvents.StartGameEvent
local spawnEvent = ServerEvents.FlockSpawnedEvent
local animalsFolder = ServerScriptService.Server.Animal
local PartLibrary = require(animalsFolder:WaitForChild("AnimalLibraryModule"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimalTemplate = ReplicatedStorage:WaitForChild("AnimalTemplate")
local AnimalSpawnedEvent = ReplicatedStorage:WaitForChild("AnimalSpawnedEvent")


local UFOModel = workspace.UFO
local ufo = UFOModel.PrimaryPart

local gameEnded = true

local spawnInterval = 10
local spawnHeight = 10
local partSize = Vector3.new(2, 2, 4)

local spawnFolder = workspace:FindFirstChild("Flock") or Instance.new("Folder")
spawnFolder.Name = "Flock"
spawnFolder.Parent = workspace

local RunService = game:GetService("RunService")

local function spawnPart()
	if gameEnded then return end
	local pos = ufo.Position
	local chosenType = PartLibrary.GetRandomType()

	local clone = AnimalTemplate:Clone()


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

	clone:SetNetworkOwner(nil) -- server owns, allows client visual control

	clone.Visual.Bouncepart.Color = chosenType.Color
	
	clone.Parent = workspace.Flock  -- put in workspace first so it replicates

	AnimalSpawnedEvent:FireAllClients(clone)
	spawnEvent:Fire(clone)
end



-- Loop
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator >= spawnInterval then
		accumulator = 0
		spawnPart()
	end
end)


-- React to timer ending
TimerEndedEvent.Event:Connect(function()
	gameEnded = true
end)

-- Listen for StartGameEvent
StartGameEvent.Event:Connect(function()
	gameEnded = false
end)
