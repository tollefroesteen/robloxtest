local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SprintEvent = ReplicatedStorage:WaitForChild("SprintEvent")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Config
local RESUME_THRESHOLD = 20

-- State
local sprinting = false
local requestInFlight = false
local currentStamina = 100
local sprintButtonDown = false

local RunButtonController = {}

local runButton = nil

local function requestSprint(state)
    if requestInFlight or state == sprinting then
        return
    end
    requestInFlight = true
    SprintEvent:FireServer(state)
end

local function updateButton()
    if not runButton then return end
    
    if sprinting then
        runButton.Text = "Sprinting..."
        runButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    elseif currentStamina <= 0 then
        runButton.Text = "Exhausted"
        runButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    elseif currentStamina < RESUME_THRESHOLD then
        runButton.Text = "Resting..."
        runButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    else
        runButton.Text = "Sprint"
        runButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end

-- Connect server → client listener IMMEDIATELY (before any other requires or Init)
SprintEvent.OnClientEvent:Connect(function(isSprinting, stamina)
    sprinting = isSprinting
    currentStamina = stamina or currentStamina
    requestInFlight = false

    -- Only auto-resume if player is holding button
    if not sprinting and sprintButtonDown and currentStamina > RESUME_THRESHOLD then
        requestSprint(true)
    end

    updateButton()
end)

-- Require ButtonEffects AFTER connecting listener (to avoid delay)
local ButtonEffects = require(script.Parent:WaitForChild("ButtonEffects"))

-- Signal subscription to server so it knows this client is ready to receive updates
task.spawn(function()
    -- small yield to ensure the RemoteEvent exists
    task.wait()
    SprintEvent:FireServer("subscribe")
end)

function RunButtonController.Init()
    local playerGui = player:WaitForChild("PlayerGui")
    local actionsGui = playerGui:WaitForChild("ActionsGui", 5)
    if not actionsGui then
        warn("[RunButtonController] ActionsGui not found in PlayerGui")
        return
    end

    local frame = actionsGui:WaitForChild("Frame", 5)
    if not frame then
        warn("[RunButtonController] Frame not found under ActionsGui")
        return
    end

    runButton = frame:WaitForChild("RunButton", 5)
    if not runButton then
        warn("[RunButtonController] RunButton not found under Frame")
        return
    end

    -- Add press effect
    ButtonEffects.AddPressEffect(runButton)

    -- Button pressed
    runButton.MouseButton1Down:Connect(function()
        sprintButtonDown = true
        requestSprint(true)
    end)

    -- Button released
    runButton.MouseButton1Up:Connect(function()
        sprintButtonDown = false
        requestSprint(false)
    end)

    -- Keyboard support: hold Shift to sprint
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            sprintButtonDown = true
            requestSprint(true)
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            sprintButtonDown = false
            requestSprint(false)
        end
    end)

    updateButton()
end

return RunButtonController
