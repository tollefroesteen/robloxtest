--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Shared RemoteEvents (bootstrap should already occur on server)
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "MainClient"

-- Optional list of controller module names expected under Client/ui
local CONTROLLER_FOLDER_NAME = "ui"
local EXPECTED_CONTROLLERS = {
	"MenuController",
	"RunButtonController",
	"ResetButtonController",
	"StaminaController",
	"HealthController",
	"ScoreController",
}

local controllers: { [string]: any } = {}

local function loadControllers()
	local root = script.Parent
	local uiFolder = root:FindFirstChild(CONTROLLER_FOLDER_NAME)
	if not uiFolder then
		return
	end
	for _, name in ipairs(EXPECTED_CONTROLLERS) do
		if controllers[name] == nil then
			local module = uiFolder:FindFirstChild(name)
			if module and module:IsA("ModuleScript") then
				local ok, loaded = pcall(require, module)
				if ok then
					controllers[name] = loaded
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
