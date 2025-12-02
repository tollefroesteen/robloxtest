--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Shared RemoteEvents (bootstrap should already occur on server)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "MainClient"

-- Controllers in the ui folder
local UI_CONTROLLER_FOLDER = "ui"
local UI_CONTROLLERS = {
	"MenuController",
	"RunButtonController",
	"StaminaController",
	"HealthController",
	"TimerController",
	"TeamController",
	"CoinsController",
	"XPController",
	"AchievementNotificationController",
	"PlayerMenuController",
	"RespawnController",
	"GameEndController",
}

-- Controllers in the controllers folder
local CONTROLLERS_FOLDER = "controllers"
local OTHER_CONTROLLERS = {
	"AnimalController",
	"GameStateController",
}

local controllers: { [string]: any } = {}

local function loadControllers()
	local root = script.Parent
	
	-- Load UI controllers
	local uiFolder = root:FindFirstChild(UI_CONTROLLER_FOLDER)
	if uiFolder then
		for _, name in ipairs(UI_CONTROLLERS) do
			if controllers[name] == nil then
				local module = uiFolder:FindFirstChild(name)
				if module and module:IsA("ModuleScript") then
					local ok, loaded = pcall(require, module)
					if ok then
						controllers[name] = loaded
					else
						Log.Warn(CONTEXT, "Failed to load controller: " .. name .. " -> " .. tostring(loaded))
					end
				end
			end
		end
	end
	
	-- Load other controllers
	local controllersFolder = root:FindFirstChild(CONTROLLERS_FOLDER)
	if controllersFolder then
		for _, name in ipairs(OTHER_CONTROLLERS) do
			if controllers[name] == nil then
				local module = controllersFolder:FindFirstChild(name)
				if module and module:IsA("ModuleScript") then
					local ok, loaded = pcall(require, module)
					if ok then
						controllers[name] = loaded
					else
						Log.Warn(CONTEXT, "Failed to load controller: " .. name .. " -> " .. tostring(loaded))
					end
				end
			end
		end
	end
end

local function initControllers()
	loadControllers()
	for name, controller in pairs(controllers) do
		local initFunc = controller and controller.Init
		if type(initFunc) == "function" then
			local success, err = pcall(initFunc)
			if not success then
				Log.Warn(CONTEXT, "Controller init failed: " .. name .. " -> " .. tostring(err))
			end
		end
	end
end

local function initialize(character: Model?)
	initControllers()
end

-- First-time initialization (character may already exist if joining from a reload)
initialize(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

-- Re-initialize controllers after every respawn (UI-1)
LocalPlayer.CharacterAdded:Connect(function(char)
	-- Defer slightly to allow PlayerGui elements to be recreated
	task.defer(function()
		initialize(char)
	end)
end)
