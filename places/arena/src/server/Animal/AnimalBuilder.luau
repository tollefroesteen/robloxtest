--!strict
-- AnimalBuilder.luau
-- Builds animal models from templates using multiple blocks for visual volume
-- CRITICAL: Parts must be positioned correctly relative to each other at creation
-- because the client animation controller captures bind poses on first sight.
--
-- Hierarchy: AnimalTemplate (root) > Visual > Bouncepart > [body blocks, legs]
-- Legs must be direct children of Bouncepart named: LegFL, LegFR, LegBL, LegBR

local AnimalTemplates = require(script.Parent.AnimalTemplates)

local AnimalBuilder = {}

-- Reference positions from original template (AnimalTemplate.rbxmx)
local ROOT_POS = Vector3.new(0, 0.5, 0)      -- Root part center
local VISUAL_OFFSET = Vector3.new(0, 1, 0)    -- Visual relative to root
local BODY_OFFSET = Vector3.new(0, 0.5, 0)    -- Bouncepart relative to visual

-- Create a single block part
local function createBlock(
	name: string,
	size: Vector3,
	position: Vector3,
	baseColor: BrickColor,
	overrideColor: Color3?,
	material: Enum.Material?,
	transparency: number?,
	anchored: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Block
	part.Size = size
	part.Position = position
	part.Anchored = if anchored ~= nil then anchored else true
	part.CanCollide = false
	part.Massless = true  -- Prevent welded parts from affecting physics
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	
	if overrideColor then
		part.Color = overrideColor
	else
		part.BrickColor = baseColor
	end
	
	return part
end

-- Create the main Bouncepart with all body volume blocks welded inside
local function createBody(
	template: any,
	bodyCenter: Vector3,
	animalColor: BrickColor
): Part
	-- The main Bouncepart - this is what the animation moves
	-- Size it to encompass the body blocks roughly
	local mainSize = Vector3.new(2, 2, 4)  -- Default size
	if template.BodyBlocks and #template.BodyBlocks > 0 then
		mainSize = template.BodyBlocks[1].Size
	end
	
	local bouncepart = Instance.new("Part")
	bouncepart.Name = "Bouncepart"
	bouncepart.Shape = Enum.PartType.Block
	bouncepart.Size = mainSize
	bouncepart.CFrame = CFrame.new(bodyCenter)  -- Use CFrame, not Position
	bouncepart.Anchored = true
	bouncepart.CanCollide = false
	bouncepart.Material = Enum.Material.SmoothPlastic
	bouncepart.Transparency = 0
	bouncepart.BrickColor = animalColor
	
	-- Add additional body blocks as children, welded to bouncepart
	-- All blocks positioned relative to bouncepart using CFrame
	if template.BodyBlocks then
		for i, blockDef in template.BodyBlocks do
			if i == 1 then continue end  -- Skip first, it's the bouncepart itself
			
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
			
			-- Weld to bouncepart
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

-- Create a leg with all its blocks welded together
-- legOffset is the offset from bouncepart center (not world position)
local function createLeg(
	name: string,
	template: any,
	bouncepart: Part,
	legOffset: Vector3,
	animalColor: BrickColor
): Part
	local legConfig = template.Legs
	local legBlocks = legConfig.Blocks
	
	-- First block is the main leg part
	-- NOTE: Legs stay ANCHORED - the animation controller moves them via CFrame updates
	-- They are NOT welded to the body, they follow via animation logic
	local mainBlock = legBlocks[1]
	local leg = Instance.new("Part")
	leg.Name = name
	leg.Shape = Enum.PartType.Block
	leg.Size = mainBlock.Size
	-- Position relative to bouncepart using CFrame multiplication
	-- This ensures correct relative positioning regardless of where bouncepart is
	leg.CFrame = bouncepart.CFrame * CFrame.new(legOffset + mainBlock.Offset)
	leg.Anchored = true  -- Anchored - animation controller handles movement
	leg.CanCollide = false
	leg.Material = mainBlock.Material or Enum.Material.SmoothPlastic
	leg.Transparency = mainBlock.Transparency or 0
	
	-- Slightly darker color for legs
	if mainBlock.Color then
		leg.Color = mainBlock.Color
	else
		local c = animalColor.Color
		leg.Color = Color3.new(c.R * 0.85, c.G * 0.85, c.B * 0.85)
	end
	
	-- Set animation attributes (same as original template)
	leg:SetAttribute("OffsetX", 0)
	leg:SetAttribute("OffsetY", -0.75)
	leg:SetAttribute("OffsetZ", 0)
	leg:SetAttribute("PivotX", 0)
	leg:SetAttribute("PivotY", legConfig.PivotY)
	leg:SetAttribute("PitvotZ", 0)  -- Note: original has typo "Pitvot"
	
	-- Add additional leg blocks - also positioned relative to bouncepart
	for i = 2, #legBlocks do
		local blockDef = legBlocks[i]
		local block = Instance.new("Part")
		block.Name = name .. "_Part" .. i
		block.Shape = Enum.PartType.Block
		block.Size = blockDef.Size
		-- Position relative to main leg
		block.CFrame = leg.CFrame * CFrame.new(blockDef.Offset - mainBlock.Offset)
		block.Anchored = false  -- Not anchored - weld will hold it
		block.CanCollide = false
		block.Massless = true
		block.Material = blockDef.Material or Enum.Material.SmoothPlastic
		block.Transparency = blockDef.Transparency or 0
		
		-- Color
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

-- Build a complete animal model
-- spawnPos: Optional spawn position. If provided, animal is created at this position.
--           If nil, animal is created at default template position (near origin).
function AnimalBuilder.BuildAnimal(templateID: string, animalColor: BrickColor, spawnPos: Vector3?): Part
	local template = AnimalTemplates.GetTemplate(templateID)
	if not template then
		template = AnimalTemplates.DEFAULT
	end
	
	-- Calculate positions - either at spawn position or default template position
	local rootPos: Vector3
	if spawnPos then
		rootPos = spawnPos
	else
		rootPos = ROOT_POS
	end
	local visualPos = rootPos + VISUAL_OFFSET
	local bodyPos = visualPos + BODY_OFFSET  -- This is where Bouncepart center is
	
	-- Create root part (invisible physics body)
	local root = Instance.new("Part")
	root.Name = "AnimalTemplate"
	root.Size = Vector3.new(4, 1, 4)
	root.CFrame = CFrame.new(rootPos)  -- Use CFrame, not Position
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = true
	root.Shape = Enum.PartType.Block
	
	-- Set default attributes
	root:SetAttribute("Captured", false)
	root:SetAttribute("SpawnX", 10)
	root:SetAttribute("SpawnY", 0)
	root:SetAttribute("SpawnZ", 10)
	root:SetAttribute("Team", "A")
	
	-- Create Visual container (invisible)
	local visual = Instance.new("Part")
	visual.Name = "Visual"
	visual.Size = Vector3.new(4, 1, 2)
	visual.CFrame = CFrame.new(visualPos)  -- Use CFrame, not Position
	visual.Transparency = 1
	visual.Anchored = true
	visual.CanCollide = false
	visual.Parent = root
	
	-- Create Bouncepart with all body blocks
	local bouncepart = createBody(template, bodyPos, animalColor)
	bouncepart.Parent = visual
	
	-- Create all 4 legs as direct children of Bouncepart
	-- ORIENTATION: Animals face -Z direction
	-- OffsetFL is defined with front at -Z (front-left leg position)
	-- Front legs: -Z, Back legs: +Z (mirrored from OffsetFL.Z)
	-- Legs are now created RELATIVE to bouncepart using CFrame math
	local legConfig = template.Legs
	local offsetFL = legConfig.OffsetFL
	
	-- Front Left (as defined - front at -Z)
	local legFL = createLeg("LegFL", template, bouncepart, offsetFL, animalColor)
	legFL.Parent = bouncepart
	
	-- Front Right (mirror X only, keep Z for front)
	local offsetFR = Vector3.new(-offsetFL.X, offsetFL.Y, offsetFL.Z)
	local legFR = createLeg("LegFR", template, bouncepart, offsetFR, animalColor)
	legFR.Parent = bouncepart
	
	-- Back Left (mirror Z to put at back, keep X)
	local offsetBL = Vector3.new(offsetFL.X, offsetFL.Y, -offsetFL.Z)
	local legBL = createLeg("LegBL", template, bouncepart, offsetBL, animalColor)
	legBL.Parent = bouncepart
	
	-- Back Right (mirror both X and Z)
	local offsetBR = Vector3.new(-offsetFL.X, offsetFL.Y, -offsetFL.Z)
	local legBR = createLeg("LegBR", template, bouncepart, offsetBR, animalColor)
	legBR.Parent = bouncepart
	
	return root
end

return AnimalBuilder
