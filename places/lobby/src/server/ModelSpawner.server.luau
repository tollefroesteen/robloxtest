--!strict
-- ModelSpawner.server.luau
-- Spawns static models in the lobby world at specified positions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "ModelSpawner"

-- Configuration for models to spawn
-- Add new models here with their spawn position and optional rotation
export type ModelSpawnConfig = {
	modelName: string,        -- Name of the model in Workspace.Models
	position: Vector3,        -- World position to spawn at
	rotation: Vector3?,       -- Optional rotation in degrees (X, Y, Z)
	scale: number?,           -- Optional scale factor
}

local MODELS_TO_SPAWN: {ModelSpawnConfig} = {
	{
		modelName = "Stabbur",
		position = Vector3.new(50, 0, 50),
		rotation = Vector3.new(0, 45, 0), -- Rotated 45 degrees on Y axis
	},
	-- Add more models here as needed:
	-- {
	-- 	modelName = "AnotherModel",
	-- 	position = Vector3.new(100, 0, -50),
	-- },
}

-- Get or create the spawn folder in workspace
local function getSpawnFolder(): Folder
	local folder = Workspace:FindFirstChild("SpawnedModels")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SpawnedModels"
		folder.Parent = Workspace
	end
	return folder :: Folder
end

-- Spawn a single model at the specified configuration
local function spawnModel(config: ModelSpawnConfig): Model?
	-- Models are stored in Workspace.Models (from the .rbxmx files via Rojo)
	local modelsFolder = Workspace:FindFirstChild("Models")
	if not modelsFolder then
		Log.Warn(CONTEXT, "Models folder not found in Workspace!")
		return nil
	end
	
	local template = modelsFolder:FindFirstChild(config.modelName)
	if not template then
		Log.Warn(CONTEXT, string.format("Model template '%s' not found!", config.modelName))
		return nil
	end
	
	-- Clone the model
	local model = template:Clone()
	
	-- Build the CFrame with position and optional rotation
	local cf = CFrame.new(config.position)
	if config.rotation then
		cf = cf * CFrame.Angles(
			math.rad(config.rotation.X),
			math.rad(config.rotation.Y),
			math.rad(config.rotation.Z)
		)
	end
	
	-- Position the model using PivotTo for proper placement
	if model:IsA("Model") then
		model:PivotTo(cf)
		
		-- Apply scale if specified
		if config.scale and config.scale ~= 1 then
			model:ScaleTo(config.scale)
		end
	elseif model:IsA("BasePart") then
		model.CFrame = cf
	end
	
	-- Parent to spawn folder
	model.Parent = getSpawnFolder()
	
	Log.Info(CONTEXT, string.format(
		"Spawned '%s' at position (%.1f, %.1f, %.1f)",
		config.modelName,
		config.position.X,
		config.position.Y,
		config.position.Z
	))
	
	return model :: Model
end

-- Initialize: spawn all configured models
local function initialize()
	Log.Info(CONTEXT, "Initializing model spawner...")
	
	-- Wait a moment for models to be loaded by Rojo
	task.wait(0.5)
	
	local spawnedCount = 0
	for _, config in ipairs(MODELS_TO_SPAWN) do
		local model = spawnModel(config)
		if model then
			spawnedCount += 1
		end
	end
	
	Log.Info(CONTEXT, string.format("Model spawner initialized. Spawned %d models.", spawnedCount))
end

-- Run initialization
initialize()
