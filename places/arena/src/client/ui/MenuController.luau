--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("util"):WaitForChild("Log"))
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
local player: Player = Players.LocalPlayer

--============================================================================
-- ACTION MODE SYSTEM
--============================================================================

-- Mode definition type
export type ActionMode = {
    ID: string,
    Name: string,
    Icon: string,
    ItemID: string?,           -- Item consumed when action is used (nil = no item needed)
    Color: Color3,             -- Button color when this mode is active
    DisabledText: string,      -- Text when item is depleted
    OnActivate: (player: Player) -> (), -- Function to call when action button is pressed
}

-- Available action modes (extensible - add new modes here)
local ActionModes: { ActionMode } = {
    {
        ID = "SHOOT",
        Name = "Shoot",
        Icon = "🔫",
        ItemID = "AMMO_BASIC",
        Color = Color3.fromRGB(200, 80, 80),  -- Red
        DisabledText = "No Ammo",
        OnActivate = function(plr: Player)
            RemoteEvents.ShootEvent:FireServer()
            Log.Info(CONTEXT, "Shoot action fired")
        end,
    },
    {
        ID = "FEED",
        Name = "Feed",
        Icon = "🍖",
        ItemID = "FOOD_BAIT",
        Color = Color3.fromRGB(80, 180, 80),  -- Green
        DisabledText = "No Bait",
        OnActivate = function(plr: Player)
            RemoteEvents.FeedEvent:FireServer()
            Log.Info(CONTEXT, "Feed action fired")
        end,
    },
    {
        ID = "SCARE",
        Name = "Scare",
        Icon = "👻",
        ItemID = nil,  -- Scare doesn't consume items
        Color = Color3.fromRGB(150, 80, 200),  -- Purple
        DisabledText = "Can't Scare",
        OnActivate = function(plr: Player)
            RemoteEvents.ScareEvent:FireServer()
            Log.Info(CONTEXT, "Scare action fired")
        end,
    },
    {
        ID = "SHIELD",
        Name = "Shield",
        Icon = "🛡️",
        ItemID = "TOOL_SHIELD",
        Color = Color3.fromRGB(80, 150, 255),  -- Blue
        DisabledText = "No Shield",
        OnActivate = function(plr: Player)
            RemoteEvents.ShieldActivateEvent:FireServer()
            Log.Info(CONTEXT, "Shield action fired")
        end,
    },
}

-- State
local currentModeIndex: number = 1
local cachedInventory: any = nil
local inventoryReceived: boolean = false  -- Track if we've received inventory at least once

-- UI references
local actionButtonRef: TextButton? = nil
local actionButtonTextLabel: TextLabel? = nil
local actionButtonMainFrame: Frame? = nil
local modeButtonRef: TextButton? = nil
local modeButtonTextLabel: TextLabel? = nil

local MenuController = {}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get item count from cached inventory
local function getItemCount(itemID: string?): number
    if not itemID then return 999 end  -- No item required = always available
    if not cachedInventory or not cachedInventory.Items then 
        Log.Info(CONTEXT, string.format("getItemCount: No inventory cached for %s", itemID or "nil"))
        return 0 
    end
    local item = cachedInventory.Items[itemID]
    local count = item and item.Quantity or 0
    Log.Info(CONTEXT, string.format("getItemCount: %s = %d", itemID, count))
    return count
end

-- Get current mode
local function getCurrentMode(): ActionMode
    return ActionModes[currentModeIndex]
end

-- Check if current mode can be used
local function canUseCurrentMode(): boolean
    local mode = getCurrentMode()
    return getItemCount(mode.ItemID) > 0
end

-- Find TextLabel in button's nested structure (Frame -> Main -> TextLabel)
local function findButtonTextLabel(button: TextButton): TextLabel?
    local buttonFrame = button:FindFirstChild("Frame")
    if buttonFrame then
        local mainFrame = buttonFrame:FindFirstChild("Main")
        if mainFrame then
            local textLabel = mainFrame:FindFirstChild("TextLabel")
            if textLabel and textLabel:IsA("TextLabel") then
                return textLabel
            end
        end
    end
    return nil
end

-- Find Main frame in button's nested structure
local function findButtonMainFrame(button: TextButton): Frame?
    local buttonFrame = button:FindFirstChild("Frame")
    if buttonFrame then
        local mainFrame = buttonFrame:FindFirstChild("Main")
        if mainFrame and mainFrame:IsA("Frame") then
            return mainFrame
        end
    end
    return nil
end

--============================================================================
-- UI UPDATE FUNCTIONS
--============================================================================

-- Update action button appearance based on current mode and inventory
local function updateActionButton(): nil
    if not actionButtonRef then 
        Log.Warn(CONTEXT, "updateActionButton: actionButtonRef is nil")
        return 
    end
    
    local mode = getCurrentMode()
    local itemCount = getItemCount(mode.ItemID)
    local canUse = itemCount > 0
    
    Log.Info(CONTEXT, string.format("updateActionButton: mode=%s, itemCount=%d, canUse=%s, inventoryReceived=%s", 
        mode.Name, itemCount, tostring(canUse), tostring(inventoryReceived)))
    
    -- Update button interactivity
    actionButtonRef.Active = canUse
    actionButtonRef.AutoButtonColor = canUse
    
    -- Update text
    if actionButtonTextLabel then
        if not inventoryReceived and mode.ItemID then
            -- Show loading state if inventory not received yet and mode requires items
            actionButtonTextLabel.Text = string.format("%s %s (...)", mode.Icon, mode.Name)
        elseif canUse then
            if mode.ItemID then
                actionButtonTextLabel.Text = string.format("%s %s (%d)", mode.Icon, mode.Name, itemCount)
            else
                actionButtonTextLabel.Text = string.format("%s %s", mode.Icon, mode.Name)
            end
        else
            actionButtonTextLabel.Text = string.format("%s %s", mode.Icon, mode.DisabledText)
        end
        Log.Info(CONTEXT, string.format("updateActionButton: text set to '%s'", actionButtonTextLabel.Text))
    else
        Log.Warn(CONTEXT, "updateActionButton: actionButtonTextLabel is nil")
    end
    
    -- Update color
    if actionButtonMainFrame then
        if canUse then
            actionButtonMainFrame.BackgroundColor3 = mode.Color
        else
            actionButtonMainFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Gray when disabled
        end
        Log.Info(CONTEXT, string.format("updateActionButton: color set, canUse=%s", tostring(canUse)))
    else
        Log.Warn(CONTEXT, "updateActionButton: actionButtonMainFrame is nil")
    end
end

-- Update mode button to show next available mode
local function updateModeButton(): nil
    if not modeButtonTextLabel then return end
    
    -- Show the current mode name/icon on the mode button
    local mode = getCurrentMode()
    local nextIndex = (currentModeIndex % #ActionModes) + 1
    local nextMode = ActionModes[nextIndex]
    
    -- Show what the NEXT mode will be
    modeButtonTextLabel.Text = string.format("→ %s", nextMode.Icon)
end

-- Cycle to next mode
local function cycleMode(): nil
    currentModeIndex = (currentModeIndex % #ActionModes) + 1
    local mode = getCurrentMode()
    Log.Info(CONTEXT, string.format("Switched to mode: %s", mode.Name))
    
    updateActionButton()
    updateModeButton()
end

-- Perform the current action (shared between button click and keyboard)
local function performAction(): nil
    -- Check if game is frozen
    local gsc = getGameStateController()
    if gsc and gsc.IsGameFrozen() then
        Log.Info(CONTEXT, "Cannot perform action - game is frozen")
        return
    end
    
    -- Check if action can be used
    if not canUseCurrentMode() then
        Log.Info(CONTEXT, "Cannot perform action - insufficient items")
        return
    end
    
    -- Execute the action
    local mode = getCurrentMode()
    mode.OnActivate(player)
end

--============================================================================
-- KEYBOARD INPUT
--============================================================================

-- Debounce for keyboard input
local lastModeChangeTime = 0
local MODE_CHANGE_COOLDOWN = 0.2  -- 200ms cooldown between mode changes

-- Set up keyboard shortcuts
local function setupKeyboardInput(): nil
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
        -- Ignore if typing in a text box or game already processed it
        if gameProcessedEvent then return end
        
        -- E key = Action (same as action button)
        if input.KeyCode == Enum.KeyCode.E then
            performAction()
        end
        
        -- Q key = Cycle Mode (same as mode button) with debounce
        if input.KeyCode == Enum.KeyCode.Q then
            local now = tick()
            if now - lastModeChangeTime >= MODE_CHANGE_COOLDOWN then
                lastModeChangeTime = now
                cycleMode()
            end
        end
    end)
    
    Log.Info(CONTEXT, "Keyboard shortcuts enabled: E=Action, Q=Cycle Mode")
end

--============================================================================
-- INITIALIZATION
--============================================================================

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

    -- Action button (formerly ShootButton)
    local actionButton = frame:WaitForChild("ShootButton", 5)
    if not actionButton then
        Log.Warn(CONTEXT, "ShootButton (Action) not found under Frame")
        return
    end

    local startButton = frame:WaitForChild("StartButton", 5)
    if not startButton then
        Log.Warn(CONTEXT, "StartButton not found under Frame")
        return
    end
    
    -- Mode button (try to find existing or use RunButton temporarily)
    -- In a full implementation, you'd create a dedicated ModeButton in Studio
    local modeButton = frame:FindFirstChild("ModeButton") or frame:FindFirstChild("RunButton")
    
    -- Store references
    actionButtonRef = actionButton
    actionButtonTextLabel = findButtonTextLabel(actionButton)
    actionButtonMainFrame = findButtonMainFrame(actionButton)
    
    if modeButton and modeButton:IsA("TextButton") then
        modeButtonRef = modeButton
        modeButtonTextLabel = findButtonTextLabel(modeButton)
    end
    
    -- Add press effects
    ButtonEffects.AddPressEffect(actionButton)
    ButtonEffects.AddPressEffect(startButton)
    if modeButtonRef then
        ButtonEffects.AddPressEffect(modeButtonRef)
    end

    -- Action button click handler
    actionButton.MouseButton1Click:Connect(function()
        performAction()
    end)
    
    -- Mode button click handler
    if modeButtonRef then
        modeButtonRef.MouseButton1Click:Connect(function()
            cycleMode()
        end)
    end

    -- Start button with debounce
    ButtonEffects.AddDebounce(startButton, 1.0, function()
        RemoteEvents.StartGameEvent:FireServer()
        Log.Info(CONTEXT, "Game start requested")
    end)
    
    -- Listen for inventory updates
    RemoteEvents.InventoryUpdatedEvent.OnClientEvent:Connect(function(inventory: any)
        Log.Info(CONTEXT, "Received inventory update")
        cachedInventory = inventory
        inventoryReceived = true
        updateActionButton()
        
        local mode = getCurrentMode()
        if mode.ItemID then
            Log.Info(CONTEXT, string.format("%s count: %d", mode.Name, getItemCount(mode.ItemID)))
        end
    end)
    
    -- Debug: Log UI references found
    Log.Info(CONTEXT, string.format("UI refs - actionButton: %s, textLabel: %s, mainFrame: %s", 
        tostring(actionButtonRef ~= nil),
        tostring(actionButtonTextLabel ~= nil),
        tostring(actionButtonMainFrame ~= nil)))
    
    -- Initialize button states
    updateActionButton()
    updateModeButton()
    
    -- Set up keyboard shortcuts
    setupKeyboardInput()
    
    Log.Info(CONTEXT, string.format("MenuController initialized with %d action modes", #ActionModes))
end

--============================================================================
-- PUBLIC API
--============================================================================

-- Get current mode info
function MenuController.GetCurrentMode(): ActionMode
    return getCurrentMode()
end

-- Get current mode ID
function MenuController.GetCurrentModeID(): string
    return getCurrentMode().ID
end

-- Set mode by ID
function MenuController.SetMode(modeID: string): boolean
    for i, mode in ActionModes do
        if mode.ID == modeID then
            currentModeIndex = i
            updateActionButton()
            updateModeButton()
            return true
        end
    end
    return false
end

-- Get all available modes
function MenuController.GetAllModes(): { ActionMode }
    return ActionModes
end

-- Get item count for current mode
function MenuController.GetCurrentModeItemCount(): number
    local mode = getCurrentMode()
    return getItemCount(mode.ItemID)
end

-- Register a new action mode dynamically
function MenuController.RegisterMode(mode: ActionMode): nil
    table.insert(ActionModes, mode)
    Log.Info(CONTEXT, string.format("Registered new action mode: %s", mode.Name))
end

return MenuController