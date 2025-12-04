--!strict
-- ButtonEffects.luau
-- Reusable UI effects for buttons (LO-2: debounce + scale press)

local ButtonEffects = {}

local DEFAULT_OFFSET = UDim2.fromOffset(-2, 2)
local DEFAULT_SCALE_PRESSED = 0.95
local DEFAULT_SCALE_NORMAL = 1.0

-- Debounce state tracker
local debounceState: {[GuiButton]: boolean} = {}

--- Adds a press effect to a button by moving a target frame
--- @param button GuiButton The button or frame to listen to input on
--- @param targetFrame GuiObject Optional: The frame to move (defaults to button:FindFirstChild("Frame"):FindFirstChild("Main"))
--- @param offset UDim2 Optional: The offset to apply when pressed (defaults to -2, 2)
function ButtonEffects.AddPressEffect(button: GuiButton, targetFrame: GuiObject?, offset: UDim2?)
	offset = offset or DEFAULT_OFFSET
	
	-- Auto-detect target if not provided
	if not targetFrame then
		local frame = button:FindFirstChild("Frame")
		if frame then
			targetFrame = frame:FindFirstChild("Main")
		end
	end
	
	if not targetFrame then
		warn("[ButtonEffects] No target frame found for press effect on " .. button:GetFullName())
		return
	end
	
	local originalPos = targetFrame.Position
	local pressedPos = originalPos + offset
	
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			targetFrame.Position = pressedPos
		end
	end)
	
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			targetFrame.Position = originalPos
		end
	end)
end

--- Adds a scale-based press effect to a button (shrinks slightly when pressed)
--- @param button GuiButton The button to apply the effect to
--- @param scalePressed number Optional: The scale when pressed (default 0.95)
--- @param scaleNormal number Optional: The scale when released (default 1.0)
function ButtonEffects.AddScalePressEffect(button: GuiButton, scalePressed: number?, scaleNormal: number?)
	scalePressed = scalePressed or DEFAULT_SCALE_PRESSED
	scaleNormal = scaleNormal or DEFAULT_SCALE_NORMAL
	
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			button.Size = UDim2.fromScale(
				button.Size.X.Scale * scalePressed,
				button.Size.Y.Scale * scalePressed
			)
		end
	end)
	
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			button.Size = UDim2.fromScale(
				button.Size.X.Scale / scalePressed * scaleNormal,
				button.Size.Y.Scale / scalePressed * scaleNormal
			)
		end
	end)
end

--- Wraps a button callback with debounce logic to prevent rapid repeated triggers
--- @param button GuiButton The button to debounce
--- @param cooldown number The debounce cooldown in seconds (default 0.5)
--- @param callback function The function to call on successful click
function ButtonEffects.AddDebounce(button: GuiButton, cooldown: number, callback: () -> ())
	cooldown = cooldown or 0.5
	
	button.Activated:Connect(function()
		if debounceState[button] then
			return -- Still cooling down
		end
		
		debounceState[button] = true
		callback()
		
		task.delay(cooldown, function()
			debounceState[button] = nil
		end)
	end)
end

return ButtonEffects
