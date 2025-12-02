--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
local ShootEvent = RemoteEvents.ShootEvent
local ButtonEffects = require(script.Parent:WaitForChild("ButtonEffects"))

-- Lazy load GameStateController to avoid circular dependencies
local GameStateController: any = nil
local function getGameStateController()
    if not GameStateController then
        local success, controller = pcall(function()
            return require(script.Parent.Parent:WaitForChild("controllers"):WaitForChild("GameStateController"))
        end)
        if success then
            GameStateController = controller
        end
    end
    return GameStateController
end

local CONTEXT = "MenuController"
local AMMO_ITEM_ID = "AMMO_BASIC"
local player: Player = Players.LocalPlayer

-- UI references for ammo tracking
local shootButtonRef: TextButton? = nil
local shootButtonTextLabel: TextLabel? = nil
local originalButtonColor: Color3? = nil
local currentAmmoCount: number = 0

local MenuController = {}

-- Update shoot button state based on ammo
local function updateShootButtonState(): nil
    if not shootButtonRef then return end
    
    local hasAmmo = currentAmmoCount > 0
    shootButtonRef.Active = hasAmmo
    shootButtonRef.AutoButtonColor = hasAmmo
    
    -- Update the TextLabel inside the button's nested structure
    if shootButtonTextLabel then
        if hasAmmo then
            shootButtonTextLabel.Text = "Shoot (" .. currentAmmoCount .. ")"
        else
            shootButtonTextLabel.Text = "No Ammo"
        end
    end
    
    -- Update the Main frame background color (the visible button part)
    local frame = shootButtonRef:FindFirstChild("Frame")
    local mainFrame = frame and frame:FindFirstChild("Main")
    if mainFrame and mainFrame:IsA("Frame") then
        if hasAmmo then
            if originalButtonColor then
                mainFrame.BackgroundColor3 = originalButtonColor
            end
        else
            mainFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray when no ammo
        end
    end
end

-- Get ammo count from inventory
local function getAmmoFromInventory(inventory: any): number
    if not inventory or not inventory.Items then return 0 end
    local ammoItem = inventory.Items[AMMO_ITEM_ID]
    return ammoItem and ammoItem.Quantity or 0
end

function MenuController.Init(): nil
    local playerGui = player:WaitForChild("PlayerGui")
    local actionsGui = playerGui:WaitForChild("ActionsGui", 5)
    if not actionsGui then
        Log.Warn(CONTEXT, "ActionsGui not found in PlayerGui")
        return
    end

    local frame = actionsGui:WaitForChild("Frame", 5)
    if not frame then
        Log.Warn(CONTEXT, "Frame not found under ActionsGui")
        return
    end

    local shootButton = frame:WaitForChild("ShootButton", 5)
    if not shootButton then
        Log.Warn(CONTEXT, "ShootButton not found under Frame")
        return
    end

    local startButton = frame:WaitForChild("StartButton", 5)
    if not startButton then
        Log.Warn(CONTEXT, "StartButton not found under Frame")
        return
    end

    -- Store shoot button reference for ammo tracking
    shootButtonRef = shootButton
    
    -- Find the TextLabel inside the button's nested structure (Frame -> Main -> TextLabel)
    local buttonFrame = shootButton:FindFirstChild("Frame")
    if buttonFrame then
        local mainFrame = buttonFrame:FindFirstChild("Main")
        if mainFrame then
            local textLabel = mainFrame:FindFirstChild("TextLabel")
            if textLabel and textLabel:IsA("TextLabel") then
                shootButtonTextLabel = textLabel
                -- Store original color for restoring when ammo is available
                originalButtonColor = mainFrame.BackgroundColor3
                Log.Info(CONTEXT, "Found shoot button TextLabel")
            end
        end
    end
    
    -- Add press effects
    ButtonEffects.AddPressEffect(shootButton)
    ButtonEffects.AddPressEffect(startButton)

    shootButton.MouseButton1Click:Connect(function()
        -- Check if game is frozen before allowing shooting
        local gsc = getGameStateController()
        if gsc and gsc.IsGameFrozen() then
            Log.Info(CONTEXT, "Cannot shoot - game is frozen")
            return
        end
        
        -- Check if we have ammo (button state should already prevent this, but double-check)
        if currentAmmoCount <= 0 then
            Log.Info(CONTEXT, "Cannot shoot - no ammo")
            return
        end
        
        ShootEvent:FireServer()
    end)

    -- Use debounce for start button to prevent multiple rapid clicks
    ButtonEffects.AddDebounce(startButton, 1.0, function()
        RemoteEvents.StartGameEvent:FireServer()
        Log.Info(CONTEXT, "Game start requested")
    end)
    
    -- Listen for inventory updates to track ammo
    RemoteEvents.InventoryUpdatedEvent.OnClientEvent:Connect(function(inventory: any)
        currentAmmoCount = getAmmoFromInventory(inventory)
        updateShootButtonState()
        Log.Info(CONTEXT, string.format("Ammo updated: %d", currentAmmoCount))
    end)
    
    -- Initialize button state (will update when inventory is received)
    updateShootButtonState()
end

-- Expose ammo count for other systems if needed
function MenuController.GetAmmoCount(): number
    return currentAmmoCount
end

return MenuController