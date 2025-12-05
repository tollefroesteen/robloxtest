--!strict
-- PetBuilder.luau (Lobby)
-- Builds pet animal models for following the player in the lobby
-- Simplified version of arena's AnimalBuilder - pets are purely visual

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimalTemplates = require(Shared:WaitForChild("data"):WaitForChild("AnimalTemplates"))

local PetBuilder = {}

-- Reference positions
local ROOT_POS = Vector3.new(0, 0.5, 0)
local VISUAL_OFFSET = Vector3.new(0, 1, 0)
local BODY_OFFSET = Vector3.new(0, 0.5, 0)

-- Create the main Bouncepart with all body volume blocks welded inside
local function createBody(
	template: any,
	bodyCenter: Vector3,
	animalColor: BrickColor
): Part
	local mainSize = Vector3.new(2, 2, 4)
	if template.BodyBlocks and #template.BodyBlocks > 0 then
		mainSize = template.BodyBlocks[1].Size
	end
	
	local bouncepart = Instance.new("Part")
	bouncepart.Name = "Bouncepart"
	bouncepart.Shape = Enum.PartType.Block
	bouncepart.Size = mainSize
	bouncepart.CFrame = CFrame.new(bodyCenter)
	bouncepart.Anchored = true
	bouncepart.CanCollide = false
	bouncepart.Material = Enum.Material.SmoothPlastic
	bouncepart.Transparency = 0
	bouncepart.BrickColor = animalColor
	
	-- Add additional body blocks
	if template.BodyBlocks then
		for i, blockDef in template.BodyBlocks do
			if i == 1 then continue end
			
			local block = Instance.new("Part")
			block.Name = "Body" .. i
			block.Shape = Enum.PartType.Block
			block.Size = blockDef.Size
			block.CFrame = bouncepart.CFrame * CFrame.new(blockDef.Offset)
			block.Anchored = false
			block.CanCollide = false
			block.Massless = true
			block.Material = blockDef.Material or Enum.Material.SmoothPlastic
			block.Transparency = blockDef.Transparency or 0
			if blockDef.Color then
				block.Color = blockDef.Color
			else
				block.BrickColor = animalColor
			end
			block.Parent = bouncepart
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = bouncepart
			weld.Part1 = block
			weld.Parent = block
		end
	end
	
	-- Add head blocks
	if template.HeadBlocks then
		for i, blockDef in template.HeadBlocks do
			local block = Instance.new("Part")
			block.Name = "Head" .. i
			block.Shape = Enum.PartType.Block
			block.Size = blockDef.Size
			block.CFrame = bouncepart.CFrame * CFrame.new(blockDef.Offset)
			block.Anchored = false
			block.CanCollide = false
			block.Massless = true
			block.Material = blockDef.Material or Enum.Material.SmoothPlastic
			block.Transparency = blockDef.Transparency or 0
			if blockDef.Color then
				block.Color = blockDef.Color
			else
				block.BrickColor = animalColor
			end
			block.Parent = bouncepart
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = bouncepart
			weld.Part1 = block
			weld.Parent = block
		end
	end
	
	-- Add tail blocks
	if template.TailBlocks then
		for i, blockDef in template.TailBlocks do
			local block = Instance.new("Part")
			block.Name = "Tail" .. i
			block.Shape = Enum.PartType.Block
			block.Size = blockDef.Size
			block.CFrame = bouncepart.CFrame * CFrame.new(blockDef.Offset)
			block.Anchored = false
			block.CanCollide = false
			block.Massless = true
			block.Material = blockDef.Material or Enum.Material.SmoothPlastic
			block.Transparency = blockDef.Transparency or 0
			if blockDef.Color then
				block.Color = blockDef.Color
			else
				block.BrickColor = animalColor
			end
			block.Parent = bouncepart
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = bouncepart
			weld.Part1 = block
			weld.Parent = block
		end
	end
	
	-- Add decoration blocks
	if template.DecorationBlocks then
		for i, blockDef in template.DecorationBlocks do
			local block = Instance.new("Part")
			block.Name = "Deco" .. i
			block.Shape = Enum.PartType.Block
			block.Size = blockDef.Size
			block.CFrame = bouncepart.CFrame * CFrame.new(blockDef.Offset)
			block.Anchored = false
			block.CanCollide = false
			block.Massless = true
			block.Material = blockDef.Material or Enum.Material.SmoothPlastic
			block.Transparency = blockDef.Transparency or 0
			if blockDef.Color then
				block.Color = blockDef.Color
			else
				block.BrickColor = animalColor
			end
			block.Parent = bouncepart
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = bouncepart
			weld.Part1 = block
			weld.Parent = block
		end
	end
	
	return bouncepart
end

-- Create a leg
local function createLeg(
	name: string,
	template: any,
	bouncepart: Part,
	legOffset: Vector3,
	animalColor: BrickColor
): Part
	local legConfig = template.Legs
	local legBlocks = legConfig.Blocks
	
	local mainBlock = legBlocks[1]
	local leg = Instance.new("Part")
	leg.Name = name
	leg.Shape = Enum.PartType.Block
	leg.Size = mainBlock.Size
	leg.CFrame = bouncepart.CFrame * CFrame.new(legOffset + mainBlock.Offset)
	leg.Anchored = true
	leg.CanCollide = false
	leg.Material = mainBlock.Material or Enum.Material.SmoothPlastic
	leg.Transparency = mainBlock.Transparency or 0
	
	if mainBlock.Color then
		leg.Color = mainBlock.Color
	else
		local c = animalColor.Color
		leg.Color = Color3.new(c.R * 0.85, c.G * 0.85, c.B * 0.85)
	end
	
	-- Animation attributes
	leg:SetAttribute("OffsetX", 0)
	leg:SetAttribute("OffsetY", -0.75)
	leg:SetAttribute("OffsetZ", 0)
	leg:SetAttribute("PivotX", 0)
	leg:SetAttribute("PivotY", legConfig.PivotY)
	leg:SetAttribute("PitvotZ", 0)
	
	-- Additional leg blocks
	for i = 2, #legBlocks do
		local blockDef = legBlocks[i]
		local block = Instance.new("Part")
		block.Name = name .. "_Part" .. i
		block.Shape = Enum.PartType.Block
		block.Size = blockDef.Size
		block.CFrame = leg.CFrame * CFrame.new(blockDef.Offset - mainBlock.Offset)
		block.Anchored = false
		block.CanCollide = false
		block.Massless = true
		block.Material = blockDef.Material or Enum.Material.SmoothPlastic
		block.Transparency = blockDef.Transparency or 0
		
		if blockDef.Color then
			block.Color = blockDef.Color
		else
			local c = animalColor.Color
			block.Color = Color3.new(c.R * 0.85, c.G * 0.85, c.B * 0.85)
		end
		
		block.Parent = leg
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = leg
		weld.Part1 = block
		weld.Parent = block
	end
	
	return leg
end

-- Build a complete pet animal model
function PetBuilder.BuildPet(templateID: string, animalColor: BrickColor, spawnPos: Vector3?): Part
	local template = AnimalTemplates.GetTemplate(templateID)
	if not template then
		template = AnimalTemplates.GetTemplate("DEFAULT")
	end
	
	local rootPos: Vector3 = spawnPos or ROOT_POS
	local visualPos = rootPos + VISUAL_OFFSET
	local bodyPos = visualPos + BODY_OFFSET
	
	-- Create root part (invisible)
	local root = Instance.new("Part")
	root.Name = "Pet"
	root.Size = Vector3.new(4, 1, 4)
	root.CFrame = CFrame.new(rootPos)
	root.Transparency = 1
	root.Anchored = true  -- Pets are anchored, moved by server
	root.CanCollide = false
	root.Shape = Enum.PartType.Block
	
	-- Create Visual container
	local visual = Instance.new("Part")
	visual.Name = "Visual"
	visual.Size = Vector3.new(4, 1, 2)
	visual.CFrame = CFrame.new(visualPos)
	visual.Transparency = 1
	visual.Anchored = true
	visual.CanCollide = false
	visual.Parent = root
	
	-- Create Bouncepart with body
	local bouncepart = createBody(template, bodyPos, animalColor)
	bouncepart.Parent = visual
	
	-- Create legs
	local legConfig = template.Legs
	local offsetFL = legConfig.OffsetFL
	
	local legFL = createLeg("LegFL", template, bouncepart, offsetFL, animalColor)
	legFL.Parent = bouncepart
	
	local offsetFR = Vector3.new(-offsetFL.X, offsetFL.Y, offsetFL.Z)
	local legFR = createLeg("LegFR", template, bouncepart, offsetFR, animalColor)
	legFR.Parent = bouncepart
	
	local offsetBL = Vector3.new(offsetFL.X, offsetFL.Y, -offsetFL.Z)
	local legBL = createLeg("LegBL", template, bouncepart, offsetBL, animalColor)
	legBL.Parent = bouncepart
	
	local offsetBR = Vector3.new(-offsetFL.X, offsetFL.Y, -offsetFL.Z)
	local legBR = createLeg("LegBR", template, bouncepart, offsetBR, animalColor)
	legBR.Parent = bouncepart
	
	-- Mark as ready immediately (no flocking delay needed for pets)
	root:SetAttribute("ReadyForFlocking", true)
	
	return root
end

return PetBuilder
