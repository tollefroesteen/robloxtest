--!strict
-- AnimalTemplates.luau
-- Defines visual templates for animals using multiple small blocks for volume
-- All templates maintain the hierarchy: AnimalTemplate > Visual > Bouncepart > Legs
--
-- Original sheep reference (from AnimalTemplate.rbxmx):
-- - Root: 4x1x4 (transparent, physics)
-- - Visual: 4x1x2 (transparent, container) at Y+1 from root
-- - Bouncepart: 2x2x4 (body) at Y+0.5 from Visual
-- - Legs: 0.5x1.5x0.5 each, offset X=±0.75, Y=-1.25, Z=±1.75 from Bouncepart center

local AnimalTemplates = {}

-- Block definition for building volumes
export type BlockDef = {
	Size: Vector3,
	Offset: Vector3,  -- Relative to part center
	Color: Color3?,   -- Override color (nil = use animal color)
	Material: Enum.Material?,
	Transparency: number?,
}

-- Leg configuration 
export type LegConfig = {
	Blocks: { BlockDef },  -- Blocks that make up each leg
	OffsetFL: Vector3,     -- Position of front-left leg relative to body center
	PivotY: number,        -- Animation pivot Y
}

-- Template configuration
export type TemplateConfig = {
	ID: string,
	Name: string,
	-- Body blocks (make up the Bouncepart volume)
	BodyBlocks: { BlockDef },
	-- Leg configuration (4 legs derived from OffsetFL by mirroring)
	Legs: LegConfig,
	-- Optional head blocks
	HeadBlocks: { BlockDef }?,
	-- Optional tail blocks
	TailBlocks: { BlockDef }?,
	-- Optional decoration blocks
	DecorationBlocks: { BlockDef }?,
}

local Templates: { [string]: TemplateConfig } = {}

--------------------------------------------------------------------------------
-- DEFAULT (Original Sheep) - simple blocky sheep
--------------------------------------------------------------------------------
Templates.DEFAULT = {
	ID = "DEFAULT",
	Name = "Sheep",
	BodyBlocks = {
		-- Main body - chunky rectangle
		{ Size = Vector3.new(2, 2, 4), Offset = Vector3.new(0, 0, 0) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.5, 1.5, 0.5), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.75, -1.75, 1.75),
		PivotY = 0.75,
	},
}

--------------------------------------------------------------------------------
-- FLUFFY SHEEP - woolly body made of many cubes
--------------------------------------------------------------------------------
Templates.FLUFFY = {
	ID = "FLUFFY",
	Name = "Fluffy Sheep",
	BodyBlocks = {
		-- Core body
		{ Size = Vector3.new(1.8, 1.6, 3.2), Offset = Vector3.new(0, 0, 0) },
		-- Fluffy wool bumps - top
		{ Size = Vector3.new(0.8, 0.6, 0.8), Offset = Vector3.new(-0.6, 0.9, 0.8) },
		{ Size = Vector3.new(0.9, 0.7, 0.9), Offset = Vector3.new(0.5, 0.85, 0.3) },
		{ Size = Vector3.new(0.7, 0.5, 0.7), Offset = Vector3.new(-0.3, 0.95, -0.5) },
		{ Size = Vector3.new(0.85, 0.6, 0.85), Offset = Vector3.new(0.4, 0.9, -0.9) },
		-- Fluffy wool bumps - sides
		{ Size = Vector3.new(0.5, 0.7, 0.9), Offset = Vector3.new(-1.1, 0.2, 0.5) },
		{ Size = Vector3.new(0.5, 0.6, 0.8), Offset = Vector3.new(1.1, 0.3, 0.2) },
		{ Size = Vector3.new(0.5, 0.7, 0.7), Offset = Vector3.new(-1.05, 0.1, -0.6) },
		{ Size = Vector3.new(0.5, 0.6, 0.8), Offset = Vector3.new(1.0, 0.2, -0.7) },
		-- Rear fluff
		{ Size = Vector3.new(1.2, 1.0, 0.6), Offset = Vector3.new(0, 0.3, -1.6) },
	},
	HeadBlocks = {
		-- Head base
		{ Size = Vector3.new(1.0, 0.9, 1.0), Offset = Vector3.new(0, 0.3, 2.0) },
		-- Snout
		{ Size = Vector3.new(0.5, 0.4, 0.4), Offset = Vector3.new(0, 0.0, 2.6) },
		-- Left ear
		{ Size = Vector3.new(0.15, 0.4, 0.3), Offset = Vector3.new(-0.5, 0.6, 1.9) },
		-- Right ear
		{ Size = Vector3.new(0.15, 0.4, 0.3), Offset = Vector3.new(0.5, 0.6, 1.9) },
	},
	TailBlocks = {
		{ Size = Vector3.new(0.4, 0.5, 0.3), Offset = Vector3.new(0, 0.4, -2.0) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.5, 1.5, 0.5), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.65, -1.55, 1.4),
		PivotY = 0.75,
	},
}

--------------------------------------------------------------------------------
-- SLIME - blobby bouncy creature
--------------------------------------------------------------------------------
Templates.SLIME = {
	ID = "SLIME",
	Name = "Slime",
	BodyBlocks = {
		-- Main blob body - wide and squat
		{ Size = Vector3.new(2.4, 1.4, 2.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Transparency = 0.25 },
		-- Inner glow core
		{ Size = Vector3.new(1.2, 0.8, 1.2), Offset = Vector3.new(0, -0.1, 0), Material = Enum.Material.Neon, Transparency = 0.1 },
		-- Top bulge
		{ Size = Vector3.new(1.0, 0.5, 1.0), Offset = Vector3.new(0, 0.8, 0), Material = Enum.Material.Neon, Transparency = 0.3 },
		-- Front bulge
		{ Size = Vector3.new(0.8, 0.6, 0.6), Offset = Vector3.new(0, 0.2, 1.0), Material = Enum.Material.Neon, Transparency = 0.3 },
	},
	Legs = {
		Blocks = {
			-- Stubby blob feet
			{ Size = Vector3.new(0.6, 0.5, 0.6), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Transparency = 0.25 },
		},
		OffsetFL = Vector3.new(0.7, -0.85, 0.7),
		PivotY = 0.25,
	},
}

--------------------------------------------------------------------------------
-- BEETLE - hard shell insect
--------------------------------------------------------------------------------
Templates.BEETLE = {
	ID = "BEETLE",
	Name = "Beetle",
	BodyBlocks = {
		-- Shell base (flat and wide)
		{ Size = Vector3.new(2.2, 0.8, 3.0), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Metal },
		-- Shell dome top
		{ Size = Vector3.new(1.8, 0.5, 2.4), Offset = Vector3.new(0, 0.55, -0.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(1.4, 0.3, 1.8), Offset = Vector3.new(0, 0.85, -0.3), Material = Enum.Material.Metal },
		-- Shell ridge (center line)
		{ Size = Vector3.new(0.2, 0.2, 2.2), Offset = Vector3.new(0, 0.95, -0.2), Material = Enum.Material.Metal },
	},
	HeadBlocks = {
		-- Head
		{ Size = Vector3.new(1.0, 0.6, 0.8), Offset = Vector3.new(0, -0.1, 1.8), Material = Enum.Material.Metal },
		-- Left antenna
		{ Size = Vector3.new(0.08, 0.6, 0.08), Offset = Vector3.new(-0.3, 0.4, 2.1), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.1, 0.3), Offset = Vector3.new(-0.3, 0.7, 2.2), Material = Enum.Material.Metal },
		-- Right antenna
		{ Size = Vector3.new(0.08, 0.6, 0.08), Offset = Vector3.new(0.3, 0.4, 2.1), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.1, 0.3), Offset = Vector3.new(0.3, 0.7, 2.2), Material = Enum.Material.Metal },
	},
	Legs = {
		Blocks = {
			-- Segmented insect leg
			{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(0, 0.3, 0), Material = Enum.Material.Metal },
			{ Size = Vector3.new(0.15, 0.5, 0.15), Offset = Vector3.new(0, -0.25, 0), Material = Enum.Material.Metal },
		},
		OffsetFL = Vector3.new(0.9, -0.7, 1.0),
		PivotY = 0.55,
	},
}

--------------------------------------------------------------------------------
-- BUNNY - cute hopping rabbit
--------------------------------------------------------------------------------
Templates.BUNNY = {
	ID = "BUNNY",
	Name = "Bunny",
	BodyBlocks = {
		-- Main round body
		{ Size = Vector3.new(1.8, 1.8, 2.4), Offset = Vector3.new(0, 0, 0) },
		-- Fluffy chest
		{ Size = Vector3.new(1.4, 1.2, 0.8), Offset = Vector3.new(0, -0.1, 1.2) },
		-- Fluffy rump
		{ Size = Vector3.new(1.6, 1.4, 1.0), Offset = Vector3.new(0, 0.1, -1.0) },
	},
	HeadBlocks = {
		-- Head
		{ Size = Vector3.new(1.2, 1.0, 1.1), Offset = Vector3.new(0, 0.6, 1.8) },
		-- Cheeks
		{ Size = Vector3.new(0.5, 0.4, 0.4), Offset = Vector3.new(-0.5, 0.3, 2.1) },
		{ Size = Vector3.new(0.5, 0.4, 0.4), Offset = Vector3.new(0.5, 0.3, 2.1) },
		-- Nose
		{ Size = Vector3.new(0.25, 0.2, 0.2), Offset = Vector3.new(0, 0.3, 2.5), Color = Color3.fromRGB(255, 180, 180) },
		-- Left ear
		{ Size = Vector3.new(0.25, 1.2, 0.4), Offset = Vector3.new(-0.35, 1.5, 1.6) },
		-- Right ear
		{ Size = Vector3.new(0.25, 1.2, 0.4), Offset = Vector3.new(0.35, 1.5, 1.6) },
	},
	TailBlocks = {
		-- Cotton tail (multiple blocks for poof)
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0, 0.3, -1.6) },
		{ Size = Vector3.new(0.35, 0.4, 0.3), Offset = Vector3.new(0.2, 0.45, -1.7) },
		{ Size = Vector3.new(0.35, 0.4, 0.3), Offset = Vector3.new(-0.2, 0.45, -1.7) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.45, 1.2, 0.5), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.55, -1.4, 1.0),
		PivotY = 0.6,
	},
}

--------------------------------------------------------------------------------
-- PIG - chubby pink pig
--------------------------------------------------------------------------------
Templates.PIG = {
	ID = "PIG",
	Name = "Pig",
	BodyBlocks = {
		-- Main barrel body
		{ Size = Vector3.new(2.2, 2.0, 3.6), Offset = Vector3.new(0, 0, 0) },
		-- Belly bulge
		{ Size = Vector3.new(1.8, 0.6, 2.0), Offset = Vector3.new(0, -0.9, 0) },
		-- Back fat rolls
		{ Size = Vector3.new(1.6, 0.4, 1.0), Offset = Vector3.new(0, 0.95, 0.3) },
		{ Size = Vector3.new(1.4, 0.3, 0.8), Offset = Vector3.new(0, 0.9, -0.6) },
	},
	HeadBlocks = {
		-- Head
		{ Size = Vector3.new(1.3, 1.1, 1.0), Offset = Vector3.new(0, 0.2, 2.0) },
		-- Snout
		{ Size = Vector3.new(0.7, 0.5, 0.5), Offset = Vector3.new(0, -0.1, 2.6) },
		-- Snout tip (nostrils)
		{ Size = Vector3.new(0.5, 0.35, 0.15), Offset = Vector3.new(0, -0.1, 2.9), Color = Color3.fromRGB(255, 150, 150) },
		-- Left ear (floppy)
		{ Size = Vector3.new(0.15, 0.5, 0.5), Offset = Vector3.new(-0.6, 0.6, 1.8) },
		-- Right ear (floppy)
		{ Size = Vector3.new(0.15, 0.5, 0.5), Offset = Vector3.new(0.6, 0.6, 1.8) },
	},
	TailBlocks = {
		-- Curly tail segments
		{ Size = Vector3.new(0.15, 0.15, 0.3), Offset = Vector3.new(0, 0.5, -2.0) },
		{ Size = Vector3.new(0.15, 0.25, 0.15), Offset = Vector3.new(0.1, 0.6, -2.2) },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0, 0.7, -2.3) },
	},
	Legs = {
		Blocks = {
			-- Chunky pig legs with hooves
			{ Size = Vector3.new(0.5, 1.0, 0.5), Offset = Vector3.new(0, 0.2, 0) },
			{ Size = Vector3.new(0.55, 0.3, 0.55), Offset = Vector3.new(0, -0.45, 0), Color = Color3.fromRGB(60, 40, 30) }, -- hoof
		},
		OffsetFL = Vector3.new(0.7, -1.3, 1.4),
		PivotY = 0.65,
	},
}

--------------------------------------------------------------------------------
-- TURTLE - slow shelled creature
--------------------------------------------------------------------------------
Templates.TURTLE = {
	ID = "TURTLE",
	Name = "Turtle",
	BodyBlocks = {
		-- Flat body base
		{ Size = Vector3.new(2.0, 0.6, 2.6), Offset = Vector3.new(0, 0, 0) },
		-- Shell layers (dome effect)
		{ Size = Vector3.new(2.2, 0.6, 2.8), Offset = Vector3.new(0, 0.5, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(1.9, 0.5, 2.4), Offset = Vector3.new(0, 0.95, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(1.5, 0.4, 1.9), Offset = Vector3.new(0, 1.3, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(1.0, 0.3, 1.3), Offset = Vector3.new(0, 1.55, 0), Material = Enum.Material.Slate },
		-- Shell pattern blocks
		{ Size = Vector3.new(0.6, 0.15, 0.6), Offset = Vector3.new(0, 1.7, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(0.5, 1.4, 0.5), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(-0.5, 1.4, 0.5), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(0.5, 1.4, -0.5), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(-0.5, 1.4, -0.5), Material = Enum.Material.Slate },
	},
	HeadBlocks = {
		-- Head on long neck
		{ Size = Vector3.new(0.5, 0.4, 0.6), Offset = Vector3.new(0, 0.1, 1.5) },  -- neck
		{ Size = Vector3.new(0.7, 0.6, 0.7), Offset = Vector3.new(0, 0.2, 2.0) },  -- head
	},
	TailBlocks = {
		{ Size = Vector3.new(0.25, 0.2, 0.5), Offset = Vector3.new(0, 0.0, -1.5) },
	},
	Legs = {
		Blocks = {
			-- Flipper-like legs
			{ Size = Vector3.new(0.6, 0.35, 0.8), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.9, -0.45, 0.9),
		PivotY = 0.18,
	},
}

--------------------------------------------------------------------------------
-- CRAB - sideways walking crab
--------------------------------------------------------------------------------
Templates.CRAB = {
	ID = "CRAB",
	Name = "Crab",
	BodyBlocks = {
		-- Main shell (wide and flat)
		{ Size = Vector3.new(3.0, 0.8, 2.0), Offset = Vector3.new(0, 0, 0) },
		-- Shell top dome
		{ Size = Vector3.new(2.4, 0.5, 1.6), Offset = Vector3.new(0, 0.55, 0) },
		{ Size = Vector3.new(1.6, 0.3, 1.0), Offset = Vector3.new(0, 0.85, 0) },
	},
	HeadBlocks = {
		-- Eye stalks
		{ Size = Vector3.new(0.12, 0.5, 0.12), Offset = Vector3.new(-0.4, 0.6, 0.8) },
		{ Size = Vector3.new(0.18, 0.18, 0.18), Offset = Vector3.new(-0.4, 0.95, 0.8), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.12, 0.5, 0.12), Offset = Vector3.new(0.4, 0.6, 0.8) },
		{ Size = Vector3.new(0.18, 0.18, 0.18), Offset = Vector3.new(0.4, 0.95, 0.8), Color = Color3.fromRGB(20, 20, 20) },
	},
	DecorationBlocks = {
		-- Left claw arm
		{ Size = Vector3.new(0.3, 0.35, 0.9), Offset = Vector3.new(-1.6, 0.2, 0.6) },
		-- Left claw pincer top
		{ Size = Vector3.new(0.5, 0.25, 0.6), Offset = Vector3.new(-1.7, 0.35, 1.3) },
		-- Left claw pincer bottom
		{ Size = Vector3.new(0.4, 0.15, 0.5), Offset = Vector3.new(-1.7, 0.1, 1.25) },
		-- Right claw arm
		{ Size = Vector3.new(0.3, 0.35, 0.9), Offset = Vector3.new(1.6, 0.2, 0.6) },
		-- Right claw pincer top
		{ Size = Vector3.new(0.5, 0.25, 0.6), Offset = Vector3.new(1.7, 0.35, 1.3) },
		-- Right claw pincer bottom
		{ Size = Vector3.new(0.4, 0.15, 0.5), Offset = Vector3.new(1.7, 0.1, 1.25) },
	},
	Legs = {
		Blocks = {
			-- Thin crab legs
			{ Size = Vector3.new(0.15, 0.6, 0.15), Offset = Vector3.new(0, 0.15, 0) },
			{ Size = Vector3.new(0.12, 0.35, 0.12), Offset = Vector3.new(0, -0.3, 0) },
		},
		OffsetFL = Vector3.new(1.2, -0.6, 0.5),
		PivotY = 0.45,
	},
}

--------------------------------------------------------------------------------
-- COW - sturdy farm cow
--------------------------------------------------------------------------------
Templates.COW = {
	ID = "COW",
	Name = "Cow",
	BodyBlocks = {
		-- Main barrel body
		{ Size = Vector3.new(2.4, 2.2, 4.0), Offset = Vector3.new(0, 0, 0) },
		-- Udder area
		{ Size = Vector3.new(1.0, 0.5, 1.2), Offset = Vector3.new(0, -1.0, -0.5) },
		-- Back hump
		{ Size = Vector3.new(1.4, 0.4, 1.5), Offset = Vector3.new(0, 1.1, 0.5) },
	},
	HeadBlocks = {
		-- Head
		{ Size = Vector3.new(1.2, 1.0, 1.3), Offset = Vector3.new(0, 0.3, 2.4) },
		-- Snout/muzzle
		{ Size = Vector3.new(0.8, 0.6, 0.5), Offset = Vector3.new(0, -0.1, 3.0) },
		-- Nose
		{ Size = Vector3.new(0.5, 0.3, 0.15), Offset = Vector3.new(0, -0.1, 3.3), Color = Color3.fromRGB(50, 30, 30) },
		-- Left horn
		{ Size = Vector3.new(0.15, 0.5, 0.15), Offset = Vector3.new(-0.5, 1.0, 2.2), Color = Color3.fromRGB(230, 210, 180) },
		{ Size = Vector3.new(0.12, 0.25, 0.12), Offset = Vector3.new(-0.55, 1.35, 2.15), Color = Color3.fromRGB(230, 210, 180) },
		-- Right horn
		{ Size = Vector3.new(0.15, 0.5, 0.15), Offset = Vector3.new(0.5, 1.0, 2.2), Color = Color3.fromRGB(230, 210, 180) },
		{ Size = Vector3.new(0.12, 0.25, 0.12), Offset = Vector3.new(0.55, 1.35, 2.15), Color = Color3.fromRGB(230, 210, 180) },
		-- Left ear
		{ Size = Vector3.new(0.1, 0.3, 0.5), Offset = Vector3.new(-0.65, 0.6, 2.0) },
		-- Right ear
		{ Size = Vector3.new(0.1, 0.3, 0.5), Offset = Vector3.new(0.65, 0.6, 2.0) },
	},
	TailBlocks = {
		-- Tail segments
		{ Size = Vector3.new(0.15, 0.15, 0.8), Offset = Vector3.new(0, 0.3, -2.4) },
		{ Size = Vector3.new(0.12, 0.12, 0.5), Offset = Vector3.new(0, 0.1, -2.9) },
		-- Tail tuft
		{ Size = Vector3.new(0.25, 0.35, 0.2), Offset = Vector3.new(0, 0.0, -3.2) },
	},
	Legs = {
		Blocks = {
			-- Sturdy cow legs with hooves
			{ Size = Vector3.new(0.5, 1.3, 0.5), Offset = Vector3.new(0, 0.15, 0) },
			{ Size = Vector3.new(0.55, 0.35, 0.55), Offset = Vector3.new(0, -0.55, 0), Color = Color3.fromRGB(50, 35, 25) },
		},
		OffsetFL = Vector3.new(0.8, -1.45, 1.6),
		PivotY = 0.8,
	},
}

-- Expose default
AnimalTemplates.DEFAULT = Templates.DEFAULT

-- Get template by ID
function AnimalTemplates.GetTemplate(templateID: string): TemplateConfig?
	return Templates[templateID] or Templates.DEFAULT
end

-- Get all template IDs
function AnimalTemplates.GetAllTemplateIDs(): { string }
	return { "DEFAULT", "FLUFFY", "SLIME", "BEETLE", "BUNNY", "PIG", "TURTLE", "CRAB", "COW" }
end

return AnimalTemplates
