--!strict
-- AnimalPreviewBuilder.luau
-- Builds simplified animal models for UI ViewportFrame previews
-- This is a client-side version that creates static preview models

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimalTemplates = require(Shared:WaitForChild("data"):WaitForChild("AnimalTemplates"))
local AnimalLibraryModule = require(Shared:WaitForChild("data"):WaitForChild("AnimalLibraryModule"))

local AnimalPreviewBuilder = {}

-- Build a preview model for an animal (simplified, no animations)
function AnimalPreviewBuilder.BuildPreview(animalID: string): Model?
	local animalDef = AnimalLibraryModule.GetByID(animalID)
	if not animalDef then
		return nil
	end
	
	local templateID = animalDef.Template or "DEFAULT"
	local template = AnimalTemplates.GetTemplate(templateID)
	if not template then
		template = AnimalTemplates.GetTemplate("DEFAULT")
	end
	if not template then
		return nil
	end
	
	local animalColor = animalDef.Color
	if typeof(animalColor) == "BrickColor" then
		-- Keep as BrickColor
	elseif typeof(animalColor) == "Color3" then
		animalColor = BrickColor.new(animalColor)
	else
		animalColor = BrickColor.new("Medium stone grey")
	end
	
	-- Create model container
	local model = Instance.new("Model")
	model.Name = animalID .. "_Preview"
	
	-- Build body blocks
	local primaryPart: Part? = nil
	
	if template.BodyBlocks then
		for i, blockDef in template.BodyBlocks do
			local part = Instance.new("Part")
			part.Name = "Body" .. i
			part.Shape = Enum.PartType.Block
			part.Size = blockDef.Size
			part.CFrame = CFrame.new(blockDef.Offset)
			part.Anchored = true
			part.CanCollide = false
			part.Material = blockDef.Material or Enum.Material.SmoothPlastic
			part.Transparency = blockDef.Transparency or 0
			
			if blockDef.Color then
				part.Color = blockDef.Color
			else
				part.BrickColor = animalColor
			end
			
			part.Parent = model
			
			if i == 1 then
				primaryPart = part
			end
		end
	end
	
	-- Build head blocks
	if template.HeadBlocks then
		for i, blockDef in template.HeadBlocks do
			local part = Instance.new("Part")
			part.Name = "Head" .. i
			part.Shape = Enum.PartType.Block
			part.Size = blockDef.Size
			part.CFrame = CFrame.new(blockDef.Offset)
			part.Anchored = true
			part.CanCollide = false
			part.Material = blockDef.Material or Enum.Material.SmoothPlastic
			part.Transparency = blockDef.Transparency or 0
			
			if blockDef.Color then
				part.Color = blockDef.Color
			else
				part.BrickColor = animalColor
			end
			
			part.Parent = model
		end
	end
	
	-- Build tail blocks
	if template.TailBlocks then
		for i, blockDef in template.TailBlocks do
			local part = Instance.new("Part")
			part.Name = "Tail" .. i
			part.Shape = Enum.PartType.Block
			part.Size = blockDef.Size
			part.CFrame = CFrame.new(blockDef.Offset)
			part.Anchored = true
			part.CanCollide = false
			part.Material = blockDef.Material or Enum.Material.SmoothPlastic
			part.Transparency = blockDef.Transparency or 0
			
			if blockDef.Color then
				part.Color = blockDef.Color
			else
				part.BrickColor = animalColor
			end
			
			part.Parent = model
		end
	end
	
	-- Build decoration blocks
	if template.DecorationBlocks then
		for i, blockDef in template.DecorationBlocks do
			local part = Instance.new("Part")
			part.Name = "Deco" .. i
			part.Shape = Enum.PartType.Block
			part.Size = blockDef.Size
			part.CFrame = CFrame.new(blockDef.Offset)
			part.Anchored = true
			part.CanCollide = false
			part.Material = blockDef.Material or Enum.Material.SmoothPlastic
			part.Transparency = blockDef.Transparency or 0
			
			if blockDef.Color then
				part.Color = blockDef.Color
			else
				part.BrickColor = animalColor
			end
			
			part.Parent = model
		end
	end
	
	-- Build legs (simplified - just the blocks, no animation)
	if template.Legs and template.Legs.Blocks then
		local legOffsets = {
			FL = template.Legs.OffsetFL or Vector3.new(0.75, -1.5, -1.5),
		}
		-- Calculate other leg positions by mirroring
		legOffsets.FR = Vector3.new(-legOffsets.FL.X, legOffsets.FL.Y, legOffsets.FL.Z)
		legOffsets.BL = Vector3.new(legOffsets.FL.X, legOffsets.FL.Y, -legOffsets.FL.Z)
		legOffsets.BR = Vector3.new(-legOffsets.FL.X, legOffsets.FL.Y, -legOffsets.FL.Z)
		
		for legName, legOffset in legOffsets do
			for i, blockDef in template.Legs.Blocks do
				local part = Instance.new("Part")
				part.Name = "Leg" .. legName .. i
				part.Shape = Enum.PartType.Block
				part.Size = blockDef.Size
				part.CFrame = CFrame.new(legOffset + blockDef.Offset)
				part.Anchored = true
				part.CanCollide = false
				part.Material = blockDef.Material or Enum.Material.SmoothPlastic
				part.Transparency = blockDef.Transparency or 0
				
				if blockDef.Color then
					part.Color = blockDef.Color
				else
					part.BrickColor = animalColor
				end
				
				part.Parent = model
			end
		end
	end
	
	-- Set primary part
	if primaryPart then
		model.PrimaryPart = primaryPart
	end
	
	return model
end

-- Create a ViewportFrame with an animal preview
function AnimalPreviewBuilder.CreateViewportPreview(animalID: string, size: UDim2, parent: Instance): ViewportFrame?
	local model = AnimalPreviewBuilder.BuildPreview(animalID)
	if not model then
		return nil
	end
	
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "AnimalPreview"
	viewport.Size = size
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	
	-- Parent the model to viewport
	model.Parent = viewport
	
	-- Create and configure camera
	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	
	-- Calculate camera position based on model extents
	local extents = model:GetExtentsSize()
	local center = model:GetBoundingBox().Position
	
	-- Position camera to show the animal at a nice angle (front-right, slightly above)
	local distance = math.max(extents.Magnitude * 0.9, 4)
	local cameraOffset = Vector3.new(distance * 0.6, distance * 0.4, -distance * 0.7)
	camera.CFrame = CFrame.new(center + cameraOffset, center)
	
	-- Set viewport lighting properties for better visibility
	viewport.Ambient = Color3.fromRGB(150, 150, 150)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1).Unit
	
	viewport.Parent = parent
	
	return viewport
end

-- Create a mystery/locked preview (silhouette)
function AnimalPreviewBuilder.CreateLockedPreview(size: UDim2, parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "LockedPreview"
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	frame.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	
	local questionMark = Instance.new("TextLabel")
	questionMark.Name = "QuestionMark"
	questionMark.Size = UDim2.new(1, 0, 1, 0)
	questionMark.BackgroundTransparency = 1
	questionMark.Text = "?"
	questionMark.TextColor3 = Color3.fromRGB(80, 80, 85)
	questionMark.TextSize = 32
	questionMark.Font = Enum.Font.GothamBold
	questionMark.Parent = frame
	
	frame.Parent = parent
	
	return frame
end

return AnimalPreviewBuilder
