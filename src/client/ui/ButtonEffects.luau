-- ButtonEffects.luau
-- Reusable UI effects for buttons

local ButtonEffects = {}

local DEFAULT_OFFSET = UDim2.fromOffset(-2, 2)

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
		warn("[ButtonEffects] No target frame found for press effect on", button:GetFullName())
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

return ButtonEffects
