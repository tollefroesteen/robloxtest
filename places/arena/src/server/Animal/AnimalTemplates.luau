--!strict
-- AnimalTemplates.luau
-- Stylized cartoony animal templates using multiple blocks for visual volume
-- 
-- ORIENTATION: Animals face NEGATIVE Z direction (that's how original template works)
-- - Head/Face: NEGATIVE Z (front)
-- - Tail/Rear: POSITIVE Z (back)
-- - Front legs: NEGATIVE Z offset
-- - Back legs: POSITIVE Z offset
--
-- Hierarchy: AnimalTemplate > Visual > Bouncepart > Legs

local AnimalTemplates = {}

-- Block definition for building volumes
export type BlockDef = {
	Size: Vector3,
	Offset: Vector3,  -- Relative to part center (Z- is front, Z+ is back)
	Color: Color3?,   -- Override color (nil = use animal color)
	Material: Enum.Material?,
	Transparency: number?,
}

-- Leg configuration 
export type LegConfig = {
	Blocks: { BlockDef },  -- Blocks that make up each leg
	OffsetFL: Vector3,     -- Front-left leg position (front = negative Z)
	PivotY: number,        -- Animation pivot Y
}

-- Template configuration
export type TemplateConfig = {
	ID: string,
	Name: string,
	BodyBlocks: { BlockDef },
	Legs: LegConfig,
	HeadBlocks: { BlockDef }?,  -- At NEGATIVE Z (front)
	TailBlocks: { BlockDef }?,  -- At POSITIVE Z (back)
	DecorationBlocks: { BlockDef }?,
}

local Templates: { [string]: TemplateConfig } = {}

--------------------------------------------------------------------------------
-- DEFAULT - Simple blocky sheep (matches original)
--------------------------------------------------------------------------------
Templates.DEFAULT = {
	ID = "DEFAULT",
	Name = "Sheep",
	BodyBlocks = {
		{ Size = Vector3.new(2, 2, 4), Offset = Vector3.new(0, 0, 0) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.5, 1.5, 0.5), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.75, -1.75, -1.75),  -- Front legs at -Z
		PivotY = 0.75,
	},
}

--------------------------------------------------------------------------------
-- FLUFFY - Cartoony woolly sheep with exaggerated fluffy volumes
--------------------------------------------------------------------------------
Templates.FLUFFY = {
	ID = "FLUFFY",
	Name = "Fluffy Sheep",
	BodyBlocks = {
		-- Core wool body - chunky and round
		{ Size = Vector3.new(2.0, 1.8, 3.0), Offset = Vector3.new(0, 0, 0) },
		-- BIG fluffy top poofs (exaggerated cartoon style)
		{ Size = Vector3.new(1.0, 0.8, 1.0), Offset = Vector3.new(-0.5, 1.0, -0.6) },
		{ Size = Vector3.new(1.1, 0.9, 1.1), Offset = Vector3.new(0.4, 0.95, 0.0) },
		{ Size = Vector3.new(0.9, 0.7, 0.9), Offset = Vector3.new(-0.3, 1.05, 0.7) },
		{ Size = Vector3.new(1.0, 0.8, 0.8), Offset = Vector3.new(0.5, 0.9, 1.0) },
		-- Side wool puffs (bigger, rounder)
		{ Size = Vector3.new(0.7, 0.9, 1.0), Offset = Vector3.new(-1.2, 0.2, -0.3) },
		{ Size = Vector3.new(0.7, 0.8, 1.1), Offset = Vector3.new(1.2, 0.3, 0.0) },
		{ Size = Vector3.new(0.6, 0.85, 0.9), Offset = Vector3.new(-1.15, 0.15, 0.8) },
		{ Size = Vector3.new(0.65, 0.8, 0.85), Offset = Vector3.new(1.1, 0.25, 0.7) },
		-- Fluffy butt (at back = +Z)
		{ Size = Vector3.new(1.4, 1.2, 0.8), Offset = Vector3.new(0, 0.3, 1.5) },
		{ Size = Vector3.new(0.8, 0.6, 0.5), Offset = Vector3.new(-0.4, 0.7, 1.7) },
		{ Size = Vector3.new(0.8, 0.6, 0.5), Offset = Vector3.new(0.4, 0.7, 1.7) },
	},
	HeadBlocks = {  -- HEAD AT FRONT (-Z)
		-- Big round cartoon head
		{ Size = Vector3.new(1.2, 1.1, 1.0), Offset = Vector3.new(0, 0.4, -1.9) },
		-- Snout/muzzle (cute and small)
		{ Size = Vector3.new(0.5, 0.4, 0.35), Offset = Vector3.new(0, 0.05, -2.4) },
		-- Nose (bigger, more visible)
		{ Size = Vector3.new(0.25, 0.2, 0.15), Offset = Vector3.new(0, 0.05, -2.6), Color = Color3.fromRGB(40, 30, 30) },
		-- Eyes (cute cartoon eyes)
		{ Size = Vector3.new(0.25, 0.3, 0.15), Offset = Vector3.new(-0.3, 0.55, -2.35), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.25, 0.3, 0.15), Offset = Vector3.new(0.3, 0.55, -2.35), Color = Color3.fromRGB(30, 30, 30) },
		-- Eye highlights
		{ Size = Vector3.new(0.08, 0.1, 0.05), Offset = Vector3.new(-0.25, 0.62, -2.4), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.08, 0.1, 0.05), Offset = Vector3.new(0.35, 0.62, -2.4), Color = Color3.fromRGB(255, 255, 255) },
		-- Big floppy ears (cartoon style)
		{ Size = Vector3.new(0.2, 0.5, 0.4), Offset = Vector3.new(-0.65, 0.5, -1.7) },
		{ Size = Vector3.new(0.2, 0.5, 0.4), Offset = Vector3.new(0.65, 0.5, -1.7) },
		-- Fluffy forehead wool
		{ Size = Vector3.new(0.8, 0.5, 0.4), Offset = Vector3.new(0, 0.85, -1.7) },
	},
	TailBlocks = {  -- TAIL AT BACK (+Z)
		-- Little poofy tail
		{ Size = Vector3.new(0.5, 0.5, 0.45), Offset = Vector3.new(0, 0.5, 2.0) },
		{ Size = Vector3.new(0.35, 0.4, 0.35), Offset = Vector3.new(0.15, 0.65, 2.1) },
		{ Size = Vector3.new(0.35, 0.4, 0.35), Offset = Vector3.new(-0.15, 0.65, 2.1) },
	},
	Legs = {
		Blocks = {
			-- Skinny stick legs (cartoon contrast with fluffy body)
			{ Size = Vector3.new(0.35, 1.4, 0.35), Offset = Vector3.new(0, 0, 0) },
			-- Tiny hooves
			{ Size = Vector3.new(0.4, 0.25, 0.4), Offset = Vector3.new(0, -0.7, 0), Color = Color3.fromRGB(50, 40, 35) },
		},
		OffsetFL = Vector3.new(0.6, -1.5, -1.2),  -- Front at -Z
		PivotY = 0.7,
	},
}

--------------------------------------------------------------------------------
-- SLIME - Gooey bouncy blob with cartoon expressions
--------------------------------------------------------------------------------
Templates.SLIME = {
	ID = "SLIME",
	Name = "Slime",
	BodyBlocks = {
		-- Main jiggly body
		{ Size = Vector3.new(2.6, 1.6, 2.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Transparency = 0.3 },
		-- Glowing inner core
		{ Size = Vector3.new(1.4, 1.0, 1.4), Offset = Vector3.new(0, -0.1, 0), Material = Enum.Material.Neon, Transparency = 0.1 },
		-- Wobbly top blob
		{ Size = Vector3.new(1.2, 0.7, 1.2), Offset = Vector3.new(0, 0.9, 0), Material = Enum.Material.Neon, Transparency = 0.35 },
		{ Size = Vector3.new(0.6, 0.4, 0.6), Offset = Vector3.new(0, 1.35, 0), Material = Enum.Material.Neon, Transparency = 0.4 },
		-- Side wobbles
		{ Size = Vector3.new(0.5, 0.6, 0.7), Offset = Vector3.new(-1.1, 0.3, 0), Material = Enum.Material.Neon, Transparency = 0.35 },
		{ Size = Vector3.new(0.5, 0.6, 0.7), Offset = Vector3.new(1.1, 0.3, 0), Material = Enum.Material.Neon, Transparency = 0.35 },
	},
	HeadBlocks = {  -- Face at front (-Z) - eyes stick OUT from body
		-- Big cartoon eyes (moved further out, bigger, opaque)
		{ Size = Vector3.new(0.5, 0.6, 0.3), Offset = Vector3.new(-0.45, 0.55, -1.35), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.5, 0.6, 0.3), Offset = Vector3.new(0.45, 0.55, -1.35), Color = Color3.fromRGB(255, 255, 255) },
		-- Pupils (larger, further out)
		{ Size = Vector3.new(0.25, 0.35, 0.15), Offset = Vector3.new(-0.45, 0.5, -1.5), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.25, 0.35, 0.15), Offset = Vector3.new(0.45, 0.5, -1.5), Color = Color3.fromRGB(20, 20, 20) },
		-- Eye highlights
		{ Size = Vector3.new(0.1, 0.12, 0.08), Offset = Vector3.new(-0.35, 0.65, -1.55), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.1, 0.12, 0.08), Offset = Vector3.new(0.55, 0.65, -1.55), Color = Color3.fromRGB(255, 255, 255) },
		-- Happy mouth (wider, more visible, further out)
		{ Size = Vector3.new(0.6, 0.2, 0.15), Offset = Vector3.new(0, -0.05, -1.35), Color = Color3.fromRGB(220, 80, 100) },
	},
	Legs = {
		Blocks = {
			-- Blobby pseudopod feet
			{ Size = Vector3.new(0.7, 0.5, 0.7), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Transparency = 0.3 },
		},
		OffsetFL = Vector3.new(0.7, -0.9, -0.7),
		PivotY = 0.25,
	},
}

--------------------------------------------------------------------------------
-- BEETLE - Shiny cartoon bug with big eyes
--------------------------------------------------------------------------------
Templates.BEETLE = {
	ID = "BEETLE",
	Name = "Beetle",
	BodyBlocks = {
		-- Main shell body
		{ Size = Vector3.new(2.4, 1.0, 3.2), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Metal },
		-- Shell dome layers (cartoon shiny effect)
		{ Size = Vector3.new(2.0, 0.6, 2.6), Offset = Vector3.new(0, 0.65, 0.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(1.5, 0.45, 2.0), Offset = Vector3.new(0, 1.05, 0.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.9, 0.3, 1.3), Offset = Vector3.new(0, 1.35, 0.2), Material = Enum.Material.Metal },
		-- Center ridge
		{ Size = Vector3.new(0.15, 0.25, 2.4), Offset = Vector3.new(0, 1.2, 0.2), Material = Enum.Material.Metal },
		-- Wing split line
		{ Size = Vector3.new(0.05, 0.5, 2.0), Offset = Vector3.new(0, 0.85, 0.3), Color = Color3.fromRGB(30, 30, 30) },
	},
	HeadBlocks = {  -- Head at front (-Z)
		-- Small round head
		{ Size = Vector3.new(1.1, 0.8, 0.9), Offset = Vector3.new(0, 0.0, -1.9), Material = Enum.Material.Metal },
		-- BIG cartoon eyes (bug style)
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(-0.4, 0.35, -2.1), Color = Color3.fromRGB(200, 50, 50) },
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0.4, 0.35, -2.1), Color = Color3.fromRGB(200, 50, 50) },
		-- Eye shine
		{ Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(-0.5, 0.45, -2.3), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(0.3, 0.45, -2.3), Color = Color3.fromRGB(255, 255, 255) },
		-- Antennae (bouncy cartoon style)
		{ Size = Vector3.new(0.08, 0.7, 0.08), Offset = Vector3.new(-0.25, 0.7, -1.8), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(-0.25, 1.1, -1.8), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.08, 0.7, 0.08), Offset = Vector3.new(0.25, 0.7, -1.8), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0.25, 1.1, -1.8), Material = Enum.Material.Neon },
	},
	Legs = {
		Blocks = {
			-- Spindly bug legs
			{ Size = Vector3.new(0.15, 0.8, 0.15), Offset = Vector3.new(0, 0.2, 0), Material = Enum.Material.Metal },
			{ Size = Vector3.new(0.12, 0.5, 0.12), Offset = Vector3.new(0.05, -0.35, 0), Material = Enum.Material.Metal },
		},
		OffsetFL = Vector3.new(1.0, -0.75, -1.1),
		PivotY = 0.55,
	},
}

--------------------------------------------------------------------------------
-- BUNNY - Super cute cartoon rabbit
--------------------------------------------------------------------------------
Templates.BUNNY = {
	ID = "BUNNY",
	Name = "Bunny",
	BodyBlocks = {
		-- Round fluffy body
		{ Size = Vector3.new(1.8, 1.9, 2.2), Offset = Vector3.new(0, 0, 0) },
		-- Fluffy chest tuft
		{ Size = Vector3.new(1.2, 1.0, 0.6), Offset = Vector3.new(0, -0.2, -1.1) },
		-- Big fluffy rump (bunnies have big butts!)
		{ Size = Vector3.new(1.7, 1.6, 1.2), Offset = Vector3.new(0, 0.1, 1.0) },
		{ Size = Vector3.new(1.3, 1.0, 0.7), Offset = Vector3.new(0, 0.6, 1.3) },
	},
	HeadBlocks = {  -- Head at front (-Z)
		-- Big round head (cute proportions)
		{ Size = Vector3.new(1.4, 1.3, 1.2), Offset = Vector3.new(0, 0.6, -1.7) },
		-- Chubby cheeks
		{ Size = Vector3.new(0.55, 0.5, 0.4), Offset = Vector3.new(-0.55, 0.3, -2.0) },
		{ Size = Vector3.new(0.55, 0.5, 0.4), Offset = Vector3.new(0.55, 0.3, -2.0) },
		-- Cute little snout
		{ Size = Vector3.new(0.4, 0.3, 0.25), Offset = Vector3.new(0, 0.25, -2.35) },
		-- Pink nose
		{ Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(0, 0.3, -2.5), Color = Color3.fromRGB(255, 150, 180) },
		-- BIG floppy ears (signature bunny feature)
		{ Size = Vector3.new(0.3, 1.6, 0.5), Offset = Vector3.new(-0.4, 1.7, -1.5) },
		{ Size = Vector3.new(0.25, 1.3, 0.4), Offset = Vector3.new(-0.4, 1.8, -1.5), Color = Color3.fromRGB(255, 200, 200) },
		{ Size = Vector3.new(0.3, 1.6, 0.5), Offset = Vector3.new(0.4, 1.7, -1.5) },
		{ Size = Vector3.new(0.25, 1.3, 0.4), Offset = Vector3.new(0.4, 1.8, -1.5), Color = Color3.fromRGB(255, 200, 200) },
		-- Eyes
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(-0.35, 0.7, -2.25), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(0.35, 0.7, -2.25), Color = Color3.fromRGB(30, 30, 30) },
	},
	TailBlocks = {  -- Tail at back (+Z)
		-- Cotton ball tail (super fluffy)
		{ Size = Vector3.new(0.6, 0.6, 0.5), Offset = Vector3.new(0, 0.5, 1.8) },
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0.2, 0.65, 1.9) },
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(-0.2, 0.65, 1.9) },
		{ Size = Vector3.new(0.4, 0.45, 0.35), Offset = Vector3.new(0, 0.75, 1.95) },
	},
	Legs = {
		Blocks = {
			-- Stubby cute legs
			{ Size = Vector3.new(0.5, 1.1, 0.55), Offset = Vector3.new(0, 0, 0) },
			-- Big cartoon feet
			{ Size = Vector3.new(0.55, 0.25, 0.7), Offset = Vector3.new(0, -0.55, -0.1) },
		},
		OffsetFL = Vector3.new(0.5, -1.35, -0.9),
		PivotY = 0.55,
	},
}

--------------------------------------------------------------------------------
-- PIG - Chubby cartoon piggy
--------------------------------------------------------------------------------
Templates.PIG = {
	ID = "PIG",
	Name = "Pig",
	BodyBlocks = {
		-- Big round barrel body
		{ Size = Vector3.new(2.4, 2.2, 3.4), Offset = Vector3.new(0, 0, 0) },
		-- Extra chubby belly
		{ Size = Vector3.new(2.0, 0.8, 2.2), Offset = Vector3.new(0, -0.95, 0) },
		-- Round rump
		{ Size = Vector3.new(1.8, 1.6, 1.0), Offset = Vector3.new(0, 0.1, 1.5) },
	},
	HeadBlocks = {  -- Head at front (-Z)
		-- Big round head
		{ Size = Vector3.new(1.5, 1.3, 1.2), Offset = Vector3.new(0, 0.3, -2.0) },
		-- Big snout
		{ Size = Vector3.new(0.9, 0.7, 0.6), Offset = Vector3.new(0, -0.05, -2.6) },
		-- Nostrils (cartoon circles)
		{ Size = Vector3.new(0.5, 0.5, 0.15), Offset = Vector3.new(0, -0.05, -2.95), Color = Color3.fromRGB(255, 150, 170) },
		{ Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(-0.12, -0.05, -3.0), Color = Color3.fromRGB(80, 50, 60) },
		{ Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(0.12, -0.05, -3.0), Color = Color3.fromRGB(80, 50, 60) },
		-- Floppy triangle ears
		{ Size = Vector3.new(0.15, 0.6, 0.7), Offset = Vector3.new(-0.65, 0.7, -1.7) },
		{ Size = Vector3.new(0.15, 0.6, 0.7), Offset = Vector3.new(0.65, 0.7, -1.7) },
		-- Cute eyes
		{ Size = Vector3.new(0.25, 0.3, 0.15), Offset = Vector3.new(-0.4, 0.55, -2.5), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.25, 0.3, 0.15), Offset = Vector3.new(0.4, 0.55, -2.5), Color = Color3.fromRGB(30, 30, 30) },
	},
	TailBlocks = {  -- Curly tail at back (+Z)
		{ Size = Vector3.new(0.15, 0.2, 0.25), Offset = Vector3.new(0, 0.6, 2.0) },
		{ Size = Vector3.new(0.2, 0.15, 0.15), Offset = Vector3.new(0.12, 0.7, 2.15) },
		{ Size = Vector3.new(0.15, 0.2, 0.15), Offset = Vector3.new(0.15, 0.6, 2.25) },
		{ Size = Vector3.new(0.2, 0.15, 0.15), Offset = Vector3.new(0.05, 0.5, 2.3) },
	},
	Legs = {
		Blocks = {
			-- Short stubby legs
			{ Size = Vector3.new(0.55, 1.0, 0.55), Offset = Vector3.new(0, 0.15, 0) },
			-- Hooves
			{ Size = Vector3.new(0.6, 0.3, 0.6), Offset = Vector3.new(0, -0.45, 0), Color = Color3.fromRGB(60, 45, 40) },
		},
		OffsetFL = Vector3.new(0.75, -1.25, -1.3),
		PivotY = 0.6,
	},
}

--------------------------------------------------------------------------------
-- TURTLE - Cute slow turtle with dome shell
--------------------------------------------------------------------------------
Templates.TURTLE = {
	ID = "TURTLE",
	Name = "Turtle",
	BodyBlocks = {
		-- Body under shell
		{ Size = Vector3.new(2.0, 0.7, 2.8), Offset = Vector3.new(0, 0, 0) },
		-- DOME SHELL (many layers for cartoon roundness)
		{ Size = Vector3.new(2.4, 0.7, 3.0), Offset = Vector3.new(0, 0.55, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(2.1, 0.6, 2.6), Offset = Vector3.new(0, 1.05, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(1.7, 0.5, 2.1), Offset = Vector3.new(0, 1.45, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(1.2, 0.4, 1.5), Offset = Vector3.new(0, 1.75, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.7, 0.3, 0.9), Offset = Vector3.new(0, 1.95, 0), Material = Enum.Material.Slate },
		-- Shell pattern hexagons (simplified as squares)
		{ Size = Vector3.new(0.7, 0.15, 0.7), Offset = Vector3.new(0, 2.1, 0), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(0.6, 1.65, 0.6), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(-0.6, 1.65, 0.6), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(0.6, 1.65, -0.6), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(-0.6, 1.65, -0.6), Material = Enum.Material.Slate },
	},
	HeadBlocks = {  -- Head at front (-Z)
		-- Long neck
		{ Size = Vector3.new(0.5, 0.45, 0.8), Offset = Vector3.new(0, 0.15, -1.7) },
		-- Round head
		{ Size = Vector3.new(0.8, 0.7, 0.7), Offset = Vector3.new(0, 0.3, -2.2) },
		-- Cute eyes
		{ Size = Vector3.new(0.2, 0.25, 0.15), Offset = Vector3.new(-0.25, 0.5, -2.45), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.2, 0.25, 0.15), Offset = Vector3.new(0.25, 0.5, -2.45), Color = Color3.fromRGB(30, 30, 30) },
		-- Beak/mouth
		{ Size = Vector3.new(0.3, 0.2, 0.2), Offset = Vector3.new(0, 0.15, -2.55), Color = Color3.fromRGB(200, 180, 140) },
	},
	TailBlocks = {  -- Tail at back (+Z)
		{ Size = Vector3.new(0.3, 0.25, 0.6), Offset = Vector3.new(0, 0.05, 1.6) },
	},
	Legs = {
		Blocks = {
			-- Flipper feet
			{ Size = Vector3.new(0.7, 0.35, 0.9), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.95, -0.5, -1.0),
		PivotY = 0.18,
	},
}

--------------------------------------------------------------------------------
-- CRAB - Wide cartoon crab with big claws
--------------------------------------------------------------------------------
Templates.CRAB = {
	ID = "CRAB",
	Name = "Crab",
	BodyBlocks = {
		-- Wide flat body
		{ Size = Vector3.new(3.2, 1.0, 2.2), Offset = Vector3.new(0, 0, 0) },
		-- Shell dome
		{ Size = Vector3.new(2.6, 0.6, 1.8), Offset = Vector3.new(0, 0.65, 0) },
		{ Size = Vector3.new(1.8, 0.4, 1.2), Offset = Vector3.new(0, 1.0, 0) },
	},
	HeadBlocks = {  -- Eyes at front (-Z)
		-- Eye stalks
		{ Size = Vector3.new(0.15, 0.6, 0.15), Offset = Vector3.new(-0.5, 0.7, -0.9) },
		{ Size = Vector3.new(0.15, 0.6, 0.15), Offset = Vector3.new(0.5, 0.7, -0.9) },
		-- Big googly eyeballs
		{ Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(-0.5, 1.15, -0.9), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(0.5, 1.15, -0.9), Color = Color3.fromRGB(255, 255, 255) },
		-- Pupils
		{ Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(-0.5, 1.15, -1.1), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(0.5, 1.15, -1.1), Color = Color3.fromRGB(20, 20, 20) },
	},
	DecorationBlocks = {
		-- BIG cartoon claws (left)
		{ Size = Vector3.new(0.4, 0.4, 1.2), Offset = Vector3.new(-1.8, 0.3, -0.5) },  -- arm
		{ Size = Vector3.new(0.7, 0.5, 0.9), Offset = Vector3.new(-2.0, 0.4, -1.4) },  -- claw base
		{ Size = Vector3.new(0.25, 0.6, 0.5), Offset = Vector3.new(-2.0, 0.65, -1.8) },  -- top pincer
		{ Size = Vector3.new(0.2, 0.35, 0.45), Offset = Vector3.new(-2.0, 0.15, -1.75) },  -- bottom pincer
		-- BIG cartoon claws (right)
		{ Size = Vector3.new(0.4, 0.4, 1.2), Offset = Vector3.new(1.8, 0.3, -0.5) },
		{ Size = Vector3.new(0.7, 0.5, 0.9), Offset = Vector3.new(2.0, 0.4, -1.4) },
		{ Size = Vector3.new(0.25, 0.6, 0.5), Offset = Vector3.new(2.0, 0.65, -1.8) },
		{ Size = Vector3.new(0.2, 0.35, 0.45), Offset = Vector3.new(2.0, 0.15, -1.75) },
	},
	Legs = {
		Blocks = {
			-- Spindly crab legs
			{ Size = Vector3.new(0.15, 0.7, 0.15), Offset = Vector3.new(0, 0.15, 0) },
			{ Size = Vector3.new(0.12, 0.4, 0.12), Offset = Vector3.new(0, -0.35, 0) },
		},
		OffsetFL = Vector3.new(1.3, -0.7, -0.6),
		PivotY = 0.45,
	},
}

--------------------------------------------------------------------------------
-- COW - Big chunky cartoon cow
--------------------------------------------------------------------------------
Templates.COW = {
	ID = "COW",
	Name = "Cow",
	BodyBlocks = {
		-- Big barrel body
		{ Size = Vector3.new(2.6, 2.4, 4.2), Offset = Vector3.new(0, 0, 0) },
		-- Belly
		{ Size = Vector3.new(2.0, 0.7, 2.4), Offset = Vector3.new(0, -1.05, 0) },
		-- Back hump
		{ Size = Vector3.new(1.6, 0.5, 1.8), Offset = Vector3.new(0, 1.2, 0.5) },
	},
	HeadBlocks = {  -- Head at front (-Z)
		-- Big head
		{ Size = Vector3.new(1.4, 1.2, 1.4), Offset = Vector3.new(0, 0.35, -2.5) },
		-- Muzzle
		{ Size = Vector3.new(1.0, 0.8, 0.6), Offset = Vector3.new(0, -0.1, -3.1) },
		-- Big nose
		{ Size = Vector3.new(0.7, 0.5, 0.2), Offset = Vector3.new(0, -0.1, -3.45), Color = Color3.fromRGB(60, 45, 50) },
		-- Nostrils
		{ Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(-0.15, -0.1, -3.5), Color = Color3.fromRGB(30, 25, 30) },
		{ Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(0.15, -0.1, -3.5), Color = Color3.fromRGB(30, 25, 30) },
		-- Horns
		{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(-0.6, 1.0, -2.3), Color = Color3.fromRGB(230, 210, 180) },
		{ Size = Vector3.new(0.15, 0.35, 0.15), Offset = Vector3.new(-0.7, 1.4, -2.2), Color = Color3.fromRGB(220, 200, 170) },
		{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(0.6, 1.0, -2.3), Color = Color3.fromRGB(230, 210, 180) },
		{ Size = Vector3.new(0.15, 0.35, 0.15), Offset = Vector3.new(0.7, 1.4, -2.2), Color = Color3.fromRGB(220, 200, 170) },
		-- Floppy ears
		{ Size = Vector3.new(0.15, 0.35, 0.6), Offset = Vector3.new(-0.75, 0.5, -2.2) },
		{ Size = Vector3.new(0.15, 0.35, 0.6), Offset = Vector3.new(0.75, 0.5, -2.2) },
		-- Eyes
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(-0.4, 0.6, -3.0), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(0.4, 0.6, -3.0), Color = Color3.fromRGB(30, 30, 30) },
	},
	TailBlocks = {  -- Tail at back (+Z)
		{ Size = Vector3.new(0.15, 0.15, 1.0), Offset = Vector3.new(0, 0.4, 2.5) },
		{ Size = Vector3.new(0.12, 0.12, 0.6), Offset = Vector3.new(0, 0.2, 3.1) },
		-- Tail tuft
		{ Size = Vector3.new(0.3, 0.4, 0.25), Offset = Vector3.new(0, 0.05, 3.5) },
	},
	Legs = {
		Blocks = {
			-- Sturdy legs
			{ Size = Vector3.new(0.55, 1.5, 0.55), Offset = Vector3.new(0, 0.1, 0) },
			-- Hooves
			{ Size = Vector3.new(0.6, 0.35, 0.6), Offset = Vector3.new(0, -0.65, 0), Color = Color3.fromRGB(50, 40, 35) },
		},
		OffsetFL = Vector3.new(0.85, -1.55, -1.7),
		PivotY = 0.85,
	},
}

-- Expose default
AnimalTemplates.DEFAULT = Templates.DEFAULT

--------------------------------------------------------------------------------
-- CHICKEN - Fluffy farm bird
--------------------------------------------------------------------------------
Templates.CHICKEN = {
	ID = "CHICKEN",
	Name = "Chicken",
	BodyBlocks = {
		-- Round fluffy body
		{ Size = Vector3.new(1.6, 1.4, 2.0), Offset = Vector3.new(0, 0, 0) },
		-- Fluffy chest
		{ Size = Vector3.new(1.2, 1.0, 0.8), Offset = Vector3.new(0, -0.1, -0.9) },
		-- Fluffy rump
		{ Size = Vector3.new(1.4, 1.2, 0.8), Offset = Vector3.new(0, 0.2, 0.9) },
	},
	HeadBlocks = {
		-- Small round head
		{ Size = Vector3.new(0.9, 0.9, 0.8), Offset = Vector3.new(0, 0.8, -1.3) },
		-- Beak
		{ Size = Vector3.new(0.25, 0.2, 0.4), Offset = Vector3.new(0, 0.6, -1.8), Color = Color3.fromRGB(255, 180, 50) },
		-- Comb (red thing on top)
		{ Size = Vector3.new(0.15, 0.4, 0.5), Offset = Vector3.new(0, 1.3, -1.2), Color = Color3.fromRGB(220, 50, 50) },
		-- Wattle (under beak)
		{ Size = Vector3.new(0.15, 0.25, 0.2), Offset = Vector3.new(0, 0.35, -1.6), Color = Color3.fromRGB(220, 50, 50) },
		-- Eyes
		{ Size = Vector3.new(0.2, 0.22, 0.1), Offset = Vector3.new(-0.3, 0.9, -1.65), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.2, 0.22, 0.1), Offset = Vector3.new(0.3, 0.9, -1.65), Color = Color3.fromRGB(20, 20, 20) },
	},
	TailBlocks = {
		-- Tail feathers (sticking up)
		{ Size = Vector3.new(0.15, 0.8, 0.3), Offset = Vector3.new(0, 0.9, 1.3) },
		{ Size = Vector3.new(0.15, 0.7, 0.25), Offset = Vector3.new(-0.2, 0.85, 1.35) },
		{ Size = Vector3.new(0.15, 0.7, 0.25), Offset = Vector3.new(0.2, 0.85, 1.35) },
	},
	Legs = {
		Blocks = {
			-- Skinny bird legs
			{ Size = Vector3.new(0.15, 0.8, 0.15), Offset = Vector3.new(0, 0, 0), Color = Color3.fromRGB(255, 180, 50) },
			-- Feet
			{ Size = Vector3.new(0.4, 0.1, 0.5), Offset = Vector3.new(0, -0.45, 0), Color = Color3.fromRGB(255, 180, 50) },
		},
		OffsetFL = Vector3.new(0.35, -0.9, -0.5),
		PivotY = 0.4,
	},
}

--------------------------------------------------------------------------------
-- GOAT - Mountain climber with horns
--------------------------------------------------------------------------------
Templates.GOAT = {
	ID = "GOAT",
	Name = "Goat",
	BodyBlocks = {
		-- Sturdy body
		{ Size = Vector3.new(2.0, 1.8, 3.0), Offset = Vector3.new(0, 0, 0) },
		-- Chest
		{ Size = Vector3.new(1.6, 1.4, 1.0), Offset = Vector3.new(0, -0.1, -1.2) },
		-- Fluffy underbelly
		{ Size = Vector3.new(1.4, 0.6, 1.8), Offset = Vector3.new(0, -0.8, 0) },
	},
	HeadBlocks = {
		-- Head
		{ Size = Vector3.new(1.0, 1.0, 1.2), Offset = Vector3.new(0, 0.5, -2.0) },
		-- Snout
		{ Size = Vector3.new(0.6, 0.5, 0.5), Offset = Vector3.new(0, 0.2, -2.6) },
		-- Nose
		{ Size = Vector3.new(0.3, 0.25, 0.15), Offset = Vector3.new(0, 0.2, -2.9), Color = Color3.fromRGB(50, 40, 40) },
		-- Curved horns
		{ Size = Vector3.new(0.2, 0.5, 0.2), Offset = Vector3.new(-0.4, 1.1, -1.8) },
		{ Size = Vector3.new(0.18, 0.4, 0.25), Offset = Vector3.new(-0.5, 1.4, -1.6) },
		{ Size = Vector3.new(0.2, 0.5, 0.2), Offset = Vector3.new(0.4, 1.1, -1.8) },
		{ Size = Vector3.new(0.18, 0.4, 0.25), Offset = Vector3.new(0.5, 1.4, -1.6) },
		-- Floppy ears
		{ Size = Vector3.new(0.15, 0.3, 0.5), Offset = Vector3.new(-0.55, 0.6, -1.8) },
		{ Size = Vector3.new(0.15, 0.3, 0.5), Offset = Vector3.new(0.55, 0.6, -1.8) },
		-- Beard
		{ Size = Vector3.new(0.25, 0.4, 0.2), Offset = Vector3.new(0, -0.1, -2.5) },
		-- Eyes
		{ Size = Vector3.new(0.2, 0.25, 0.12), Offset = Vector3.new(-0.3, 0.65, -2.5), Color = Color3.fromRGB(40, 40, 20) },
		{ Size = Vector3.new(0.2, 0.25, 0.12), Offset = Vector3.new(0.3, 0.65, -2.5), Color = Color3.fromRGB(40, 40, 20) },
	},
	TailBlocks = {
		{ Size = Vector3.new(0.2, 0.35, 0.4), Offset = Vector3.new(0, 0.5, 1.7) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.4, 1.3, 0.4), Offset = Vector3.new(0, 0, 0) },
			-- Hooves
			{ Size = Vector3.new(0.45, 0.25, 0.5), Offset = Vector3.new(0, -0.65, 0), Color = Color3.fromRGB(50, 40, 35) },
		},
		OffsetFL = Vector3.new(0.6, -1.35, -1.1),
		PivotY = 0.65,
	},
}

--------------------------------------------------------------------------------
-- DUCK - Waddling water bird
--------------------------------------------------------------------------------
Templates.DUCK = {
	ID = "DUCK",
	Name = "Duck",
	BodyBlocks = {
		-- Oval body
		{ Size = Vector3.new(1.6, 1.3, 2.2), Offset = Vector3.new(0, 0, 0) },
		-- Fluffy chest
		{ Size = Vector3.new(1.3, 1.0, 0.8), Offset = Vector3.new(0, -0.1, -0.9) },
		-- Tail area
		{ Size = Vector3.new(1.0, 0.8, 0.6), Offset = Vector3.new(0, 0.3, 1.0) },
	},
	HeadBlocks = {
		-- Round head
		{ Size = Vector3.new(1.0, 1.0, 1.0), Offset = Vector3.new(0, 0.7, -1.4) },
		-- Flat bill
		{ Size = Vector3.new(0.5, 0.2, 0.6), Offset = Vector3.new(0, 0.4, -2.0), Color = Color3.fromRGB(255, 160, 50) },
		{ Size = Vector3.new(0.45, 0.15, 0.5), Offset = Vector3.new(0, 0.25, -1.95), Color = Color3.fromRGB(255, 140, 40) },
		-- Eyes
		{ Size = Vector3.new(0.22, 0.25, 0.12), Offset = Vector3.new(-0.35, 0.85, -1.8), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.22, 0.25, 0.12), Offset = Vector3.new(0.35, 0.85, -1.8), Color = Color3.fromRGB(20, 20, 20) },
	},
	TailBlocks = {
		-- Cute tail feathers
		{ Size = Vector3.new(0.3, 0.4, 0.3), Offset = Vector3.new(0, 0.5, 1.3) },
		{ Size = Vector3.new(0.2, 0.3, 0.25), Offset = Vector3.new(0, 0.7, 1.4) },
	},
	Legs = {
		Blocks = {
			-- Webbed feet
			{ Size = Vector3.new(0.15, 0.5, 0.15), Offset = Vector3.new(0, 0, 0), Color = Color3.fromRGB(255, 160, 50) },
			{ Size = Vector3.new(0.5, 0.1, 0.6), Offset = Vector3.new(0, -0.3, 0), Color = Color3.fromRGB(255, 160, 50) },
		},
		OffsetFL = Vector3.new(0.4, -0.8, -0.5),
		PivotY = 0.25,
	},
}

--------------------------------------------------------------------------------
-- FROG - Hoppy amphibian
--------------------------------------------------------------------------------
Templates.FROG = {
	ID = "FROG",
	Name = "Frog",
	BodyBlocks = {
		-- Squat body
		{ Size = Vector3.new(2.0, 1.2, 2.0), Offset = Vector3.new(0, 0, 0) },
		-- Rounded back
		{ Size = Vector3.new(1.6, 0.6, 1.6), Offset = Vector3.new(0, 0.7, 0) },
	},
	HeadBlocks = {
		-- Wide flat head (merged with body for frogs)
		{ Size = Vector3.new(2.2, 0.8, 1.0), Offset = Vector3.new(0, 0.4, -1.2) },
		-- Big bulging eyes
		{ Size = Vector3.new(0.6, 0.6, 0.5), Offset = Vector3.new(-0.6, 1.0, -1.0), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.6, 0.6, 0.5), Offset = Vector3.new(0.6, 1.0, -1.0), Color = Color3.fromRGB(255, 255, 255) },
		-- Pupils
		{ Size = Vector3.new(0.25, 0.35, 0.15), Offset = Vector3.new(-0.6, 1.0, -1.3), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.25, 0.35, 0.15), Offset = Vector3.new(0.6, 1.0, -1.3), Color = Color3.fromRGB(20, 20, 20) },
		-- Wide mouth
		{ Size = Vector3.new(1.2, 0.15, 0.3), Offset = Vector3.new(0, 0.1, -1.5), Color = Color3.fromRGB(200, 80, 80) },
	},
	Legs = {
		Blocks = {
			-- Strong hopping legs
			{ Size = Vector3.new(0.5, 0.8, 0.5), Offset = Vector3.new(0, 0, 0) },
			-- Webbed feet
			{ Size = Vector3.new(0.7, 0.15, 0.8), Offset = Vector3.new(0, -0.45, 0.1) },
		},
		OffsetFL = Vector3.new(0.9, -0.75, -0.6),
		PivotY = 0.4,
	},
}

--------------------------------------------------------------------------------
-- HEDGEHOG - Spiky ball creature
--------------------------------------------------------------------------------
Templates.HEDGEHOG = {
	ID = "HEDGEHOG",
	Name = "Hedgehog",
	BodyBlocks = {
		-- Round body
		{ Size = Vector3.new(1.8, 1.4, 2.2), Offset = Vector3.new(0, 0, 0) },
		-- Spiky back dome
		{ Size = Vector3.new(1.6, 0.8, 1.8), Offset = Vector3.new(0, 0.8, 0.1), Material = Enum.Material.Grass },
		{ Size = Vector3.new(1.2, 0.5, 1.4), Offset = Vector3.new(0, 1.2, 0.1), Material = Enum.Material.Grass },
		-- Spikes (simplified as small blocks)
		{ Size = Vector3.new(0.2, 0.4, 0.2), Offset = Vector3.new(-0.4, 1.4, -0.3), Material = Enum.Material.Grass },
		{ Size = Vector3.new(0.2, 0.4, 0.2), Offset = Vector3.new(0.4, 1.4, -0.3), Material = Enum.Material.Grass },
		{ Size = Vector3.new(0.2, 0.4, 0.2), Offset = Vector3.new(0, 1.5, 0), Material = Enum.Material.Grass },
		{ Size = Vector3.new(0.2, 0.4, 0.2), Offset = Vector3.new(-0.3, 1.35, 0.4), Material = Enum.Material.Grass },
		{ Size = Vector3.new(0.2, 0.4, 0.2), Offset = Vector3.new(0.3, 1.35, 0.4), Material = Enum.Material.Grass },
	},
	HeadBlocks = {
		-- Pointy snout
		{ Size = Vector3.new(0.8, 0.7, 0.9), Offset = Vector3.new(0, 0.1, -1.3) },
		{ Size = Vector3.new(0.5, 0.4, 0.5), Offset = Vector3.new(0, 0.0, -1.8) },
		-- Nose
		{ Size = Vector3.new(0.2, 0.18, 0.15), Offset = Vector3.new(0, 0.05, -2.1), Color = Color3.fromRGB(30, 25, 25) },
		-- Beady eyes
		{ Size = Vector3.new(0.18, 0.2, 0.1), Offset = Vector3.new(-0.25, 0.3, -1.6), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.18, 0.2, 0.1), Offset = Vector3.new(0.25, 0.3, -1.6), Color = Color3.fromRGB(20, 20, 20) },
		-- Ears
		{ Size = Vector3.new(0.2, 0.25, 0.15), Offset = Vector3.new(-0.35, 0.5, -1.2) },
		{ Size = Vector3.new(0.2, 0.25, 0.15), Offset = Vector3.new(0.35, 0.5, -1.2) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.35, 0.5, 0.4), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.55, -0.85, -0.7),
		PivotY = 0.25,
	},
}

--------------------------------------------------------------------------------
-- MOUSE - Tiny quick rodent
--------------------------------------------------------------------------------
Templates.MOUSE = {
	ID = "MOUSE",
	Name = "Mouse",
	BodyBlocks = {
		-- Small oval body
		{ Size = Vector3.new(1.0, 0.8, 1.4), Offset = Vector3.new(0, 0, 0) },
		-- Rounded back
		{ Size = Vector3.new(0.8, 0.5, 1.0), Offset = Vector3.new(0, 0.4, 0) },
	},
	HeadBlocks = {
		-- Pointy head
		{ Size = Vector3.new(0.7, 0.6, 0.7), Offset = Vector3.new(0, 0.2, -0.9) },
		{ Size = Vector3.new(0.4, 0.35, 0.4), Offset = Vector3.new(0, 0.15, -1.3) },
		-- Nose
		{ Size = Vector3.new(0.15, 0.12, 0.1), Offset = Vector3.new(0, 0.15, -1.55), Color = Color3.fromRGB(255, 150, 150) },
		-- Big round ears
		{ Size = Vector3.new(0.1, 0.5, 0.4), Offset = Vector3.new(-0.35, 0.6, -0.7), Color = Color3.fromRGB(255, 180, 180) },
		{ Size = Vector3.new(0.1, 0.5, 0.4), Offset = Vector3.new(0.35, 0.6, -0.7), Color = Color3.fromRGB(255, 180, 180) },
		-- Eyes
		{ Size = Vector3.new(0.18, 0.2, 0.1), Offset = Vector3.new(-0.2, 0.35, -1.15), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.18, 0.2, 0.1), Offset = Vector3.new(0.2, 0.35, -1.15), Color = Color3.fromRGB(20, 20, 20) },
		-- Whiskers (simplified)
		{ Size = Vector3.new(0.4, 0.03, 0.05), Offset = Vector3.new(-0.3, 0.15, -1.3) },
		{ Size = Vector3.new(0.4, 0.03, 0.05), Offset = Vector3.new(0.3, 0.15, -1.3) },
	},
	TailBlocks = {
		-- Long thin tail
		{ Size = Vector3.new(0.1, 0.1, 0.8), Offset = Vector3.new(0, 0.1, 1.0), Color = Color3.fromRGB(255, 180, 180) },
		{ Size = Vector3.new(0.08, 0.08, 0.6), Offset = Vector3.new(0, 0.05, 1.7), Color = Color3.fromRGB(255, 180, 180) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.2, 0.4, 0.25), Offset = Vector3.new(0, 0, 0) },
		},
		OffsetFL = Vector3.new(0.3, -0.55, -0.45),
		PivotY = 0.2,
	},
}

--------------------------------------------------------------------------------
-- PENGUIN - Waddling arctic bird
--------------------------------------------------------------------------------
Templates.PENGUIN = {
	ID = "PENGUIN",
	Name = "Penguin",
	BodyBlocks = {
		-- Oval upright body
		{ Size = Vector3.new(1.6, 2.2, 1.4), Offset = Vector3.new(0, 0, 0) },
		-- White belly
		{ Size = Vector3.new(1.0, 1.6, 0.5), Offset = Vector3.new(0, -0.1, -0.5), Color = Color3.fromRGB(255, 255, 255) },
	},
	HeadBlocks = {
		-- Round head
		{ Size = Vector3.new(1.2, 1.0, 1.0), Offset = Vector3.new(0, 1.4, -0.1) },
		-- White face patch
		{ Size = Vector3.new(0.8, 0.6, 0.3), Offset = Vector3.new(0, 1.3, -0.5), Color = Color3.fromRGB(255, 255, 255) },
		-- Beak
		{ Size = Vector3.new(0.3, 0.2, 0.4), Offset = Vector3.new(0, 1.2, -0.7), Color = Color3.fromRGB(255, 140, 50) },
		-- Eyes
		{ Size = Vector3.new(0.2, 0.22, 0.1), Offset = Vector3.new(-0.3, 1.5, -0.5), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.2, 0.22, 0.1), Offset = Vector3.new(0.3, 1.5, -0.5), Color = Color3.fromRGB(20, 20, 20) },
	},
	DecorationBlocks = {
		-- Flippers
		{ Size = Vector3.new(0.2, 1.0, 0.5), Offset = Vector3.new(-0.9, 0.2, 0) },
		{ Size = Vector3.new(0.2, 1.0, 0.5), Offset = Vector3.new(0.9, 0.2, 0) },
	},
	Legs = {
		Blocks = {
			-- Short stubby legs
			{ Size = Vector3.new(0.3, 0.3, 0.3), Offset = Vector3.new(0, 0, 0) },
			-- Webbed feet
			{ Size = Vector3.new(0.5, 0.1, 0.6), Offset = Vector3.new(0, -0.2, 0), Color = Color3.fromRGB(255, 140, 50) },
		},
		OffsetFL = Vector3.new(0.35, -1.25, -0.3),
		PivotY = 0.15,
	},
}

--------------------------------------------------------------------------------
-- RACCOON - Masked mischief maker
--------------------------------------------------------------------------------
Templates.RACCOON = {
	ID = "RACCOON",
	Name = "Raccoon",
	BodyBlocks = {
		-- Chunky body
		{ Size = Vector3.new(1.8, 1.6, 2.6), Offset = Vector3.new(0, 0, 0) },
		-- Round belly
		{ Size = Vector3.new(1.5, 1.0, 1.6), Offset = Vector3.new(0, -0.5, 0) },
	},
	HeadBlocks = {
		-- Pointed head
		{ Size = Vector3.new(1.2, 1.0, 1.0), Offset = Vector3.new(0, 0.5, -1.6) },
		-- Snout
		{ Size = Vector3.new(0.5, 0.4, 0.5), Offset = Vector3.new(0, 0.25, -2.1) },
		-- Nose
		{ Size = Vector3.new(0.2, 0.15, 0.12), Offset = Vector3.new(0, 0.3, -2.4), Color = Color3.fromRGB(30, 25, 25) },
		-- Mask (dark patches around eyes)
		{ Size = Vector3.new(1.0, 0.35, 0.3), Offset = Vector3.new(0, 0.6, -1.9), Color = Color3.fromRGB(40, 35, 35) },
		-- Eyes (white visible in mask)
		{ Size = Vector3.new(0.22, 0.25, 0.15), Offset = Vector3.new(-0.28, 0.65, -2.0), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.22, 0.25, 0.15), Offset = Vector3.new(0.28, 0.65, -2.0), Color = Color3.fromRGB(255, 255, 255) },
		-- Pupils
		{ Size = Vector3.new(0.1, 0.15, 0.08), Offset = Vector3.new(-0.28, 0.62, -2.1), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.1, 0.15, 0.08), Offset = Vector3.new(0.28, 0.62, -2.1), Color = Color3.fromRGB(20, 20, 20) },
		-- Ears
		{ Size = Vector3.new(0.25, 0.35, 0.2), Offset = Vector3.new(-0.4, 1.1, -1.5) },
		{ Size = Vector3.new(0.25, 0.35, 0.2), Offset = Vector3.new(0.4, 1.1, -1.5) },
	},
	TailBlocks = {
		-- Striped bushy tail
		{ Size = Vector3.new(0.5, 0.5, 0.6), Offset = Vector3.new(0, 0.4, 1.5) },
		{ Size = Vector3.new(0.45, 0.45, 0.5), Offset = Vector3.new(0, 0.5, 2.0), Color = Color3.fromRGB(50, 45, 40) },
		{ Size = Vector3.new(0.4, 0.4, 0.5), Offset = Vector3.new(0, 0.55, 2.4) },
		{ Size = Vector3.new(0.35, 0.35, 0.4), Offset = Vector3.new(0, 0.55, 2.8), Color = Color3.fromRGB(50, 45, 40) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.4, 0.9, 0.4), Offset = Vector3.new(0, 0, 0) },
			-- Paws
			{ Size = Vector3.new(0.35, 0.2, 0.45), Offset = Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(40, 35, 35) },
		},
		OffsetFL = Vector3.new(0.55, -1.1, -0.9),
		PivotY = 0.45,
	},
}

--------------------------------------------------------------------------------
-- SNAIL - Slow spiral shell
--------------------------------------------------------------------------------
Templates.SNAIL = {
	ID = "SNAIL",
	Name = "Snail",
	BodyBlocks = {
		-- Squishy body/foot
		{ Size = Vector3.new(1.4, 0.6, 2.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		-- Shell base
		{ Size = Vector3.new(1.4, 1.2, 1.4), Offset = Vector3.new(0, 0.8, 0.3), Material = Enum.Material.Slate },
		-- Shell spiral layers
		{ Size = Vector3.new(1.2, 1.0, 1.2), Offset = Vector3.new(0.1, 1.1, 0.4), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.9, 0.8, 0.9), Offset = Vector3.new(0.15, 1.35, 0.5), Material = Enum.Material.Slate },
		{ Size = Vector3.new(0.6, 0.5, 0.6), Offset = Vector3.new(0.2, 1.55, 0.55), Material = Enum.Material.Slate },
	},
	HeadBlocks = {
		-- Head blob
		{ Size = Vector3.new(0.8, 0.7, 0.7), Offset = Vector3.new(0, 0.4, -1.3), Material = Enum.Material.SmoothPlastic },
		-- Eye stalks
		{ Size = Vector3.new(0.1, 0.6, 0.1), Offset = Vector3.new(-0.2, 0.9, -1.4), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.1, 0.6, 0.1), Offset = Vector3.new(0.2, 0.9, -1.4), Material = Enum.Material.SmoothPlastic },
		-- Eyes on stalks
		{ Size = Vector3.new(0.2, 0.2, 0.2), Offset = Vector3.new(-0.2, 1.3, -1.4), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.2, 0.2, 0.2), Offset = Vector3.new(0.2, 1.3, -1.4), Color = Color3.fromRGB(30, 30, 30) },
		-- Tentacles (feelers)
		{ Size = Vector3.new(0.08, 0.35, 0.08), Offset = Vector3.new(-0.25, 0.6, -1.6), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.08, 0.35, 0.08), Offset = Vector3.new(0.25, 0.6, -1.6), Material = Enum.Material.SmoothPlastic },
	},
	Legs = {
		Blocks = {
			-- Snails don't have legs, just tiny foot waves
			{ Size = Vector3.new(0.3, 0.15, 0.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		},
		OffsetFL = Vector3.new(0.4, -0.35, -0.7),
		PivotY = 0.08,
	},
}

--------------------------------------------------------------------------------
-- SQUIRREL - Bushy-tailed nut collector
--------------------------------------------------------------------------------
Templates.SQUIRREL = {
	ID = "SQUIRREL",
	Name = "Squirrel",
	BodyBlocks = {
		-- Small agile body
		{ Size = Vector3.new(1.2, 1.2, 1.8), Offset = Vector3.new(0, 0, 0) },
		-- Fluffy chest
		{ Size = Vector3.new(0.9, 0.8, 0.6), Offset = Vector3.new(0, -0.1, -0.8) },
	},
	HeadBlocks = {
		-- Round head
		{ Size = Vector3.new(1.0, 0.9, 0.9), Offset = Vector3.new(0, 0.6, -1.2) },
		-- Snout
		{ Size = Vector3.new(0.4, 0.35, 0.4), Offset = Vector3.new(0, 0.4, -1.7) },
		-- Nose
		{ Size = Vector3.new(0.15, 0.12, 0.1), Offset = Vector3.new(0, 0.45, -1.95), Color = Color3.fromRGB(30, 25, 25) },
		-- Big cute eyes
		{ Size = Vector3.new(0.28, 0.32, 0.12), Offset = Vector3.new(-0.28, 0.75, -1.55), Color = Color3.fromRGB(20, 20, 20) },
		{ Size = Vector3.new(0.28, 0.32, 0.12), Offset = Vector3.new(0.28, 0.75, -1.55), Color = Color3.fromRGB(20, 20, 20) },
		-- Tufted ears
		{ Size = Vector3.new(0.2, 0.45, 0.2), Offset = Vector3.new(-0.35, 1.2, -1.1) },
		{ Size = Vector3.new(0.15, 0.2, 0.15), Offset = Vector3.new(-0.35, 1.5, -1.1) },
		{ Size = Vector3.new(0.2, 0.45, 0.2), Offset = Vector3.new(0.35, 1.2, -1.1) },
		{ Size = Vector3.new(0.15, 0.2, 0.15), Offset = Vector3.new(0.35, 1.5, -1.1) },
		-- Cheeks (for storing nuts!)
		{ Size = Vector3.new(0.3, 0.25, 0.2), Offset = Vector3.new(-0.4, 0.45, -1.4) },
		{ Size = Vector3.new(0.3, 0.25, 0.2), Offset = Vector3.new(0.4, 0.45, -1.4) },
	},
	TailBlocks = {
		-- MAGNIFICENT bushy tail (curving up)
		{ Size = Vector3.new(0.6, 0.6, 0.8), Offset = Vector3.new(0, 0.4, 1.1) },
		{ Size = Vector3.new(0.7, 0.7, 0.7), Offset = Vector3.new(0, 0.8, 1.3) },
		{ Size = Vector3.new(0.8, 0.8, 0.6), Offset = Vector3.new(0, 1.2, 1.2) },
		{ Size = Vector3.new(0.7, 0.7, 0.5), Offset = Vector3.new(0, 1.5, 1.0) },
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0, 1.7, 0.7) },
	},
	Legs = {
		Blocks = {
			{ Size = Vector3.new(0.3, 0.7, 0.35), Offset = Vector3.new(0, 0, 0) },
			-- Tiny paws
			{ Size = Vector3.new(0.25, 0.15, 0.35), Offset = Vector3.new(0, -0.4, 0) },
		},
		OffsetFL = Vector3.new(0.4, -0.85, -0.6),
		PivotY = 0.35,
	},
}

--------------------------------------------------------------------------------
-- ███████╗ UFO EXPERIMENTAL ANIMALS ███████╗
-- These bizarre creatures were beamed down from the mysterious UFO.
-- They resemble Earth animals but something is... off.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ZORB_SHEEP - Glowing cosmic sheep that absorbed cosmic radiation
--------------------------------------------------------------------------------
Templates.ZORB_SHEEP = {
	ID = "ZORB_SHEEP",
	Name = "Zorbsheep",
	BodyBlocks = {
		-- Core ethereal body - slightly translucent feel
		{ Size = Vector3.new(2.2, 2.0, 3.2), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Transparency = 0.2 },
		-- Glowing wool puffs (irregular, cosmic)
		{ Size = Vector3.new(1.2, 1.0, 1.2), Offset = Vector3.new(-0.6, 1.2, -0.5), Material = Enum.Material.Neon, Transparency = 0.3 },
		{ Size = Vector3.new(1.3, 1.1, 1.0), Offset = Vector3.new(0.5, 1.15, 0.2), Material = Enum.Material.Neon, Transparency = 0.25 },
		{ Size = Vector3.new(1.0, 0.9, 1.1), Offset = Vector3.new(-0.4, 1.3, 0.8), Material = Enum.Material.Neon, Transparency = 0.35 },
		{ Size = Vector3.new(1.1, 0.95, 0.9), Offset = Vector3.new(0.6, 1.1, 1.0), Material = Enum.Material.Neon, Transparency = 0.3 },
		-- Floating cosmic orbs around body
		{ Size = Vector3.new(0.4, 0.4, 0.4), Offset = Vector3.new(-1.8, 0.8, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.3, 0.3, 0.3), Offset = Vector3.new(1.9, 1.2, 0.3), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(0, 2.2, 0), Material = Enum.Material.Neon },
		-- Side ethereal wisps
		{ Size = Vector3.new(0.5, 1.0, 1.2), Offset = Vector3.new(-1.4, 0.3, -0.2), Material = Enum.Material.Neon, Transparency = 0.4 },
		{ Size = Vector3.new(0.5, 0.9, 1.3), Offset = Vector3.new(1.4, 0.4, 0.1), Material = Enum.Material.Neon, Transparency = 0.4 },
		-- Glowing rump
		{ Size = Vector3.new(1.6, 1.4, 1.0), Offset = Vector3.new(0, 0.4, 1.6), Material = Enum.Material.Neon, Transparency = 0.25 },
	},
	HeadBlocks = {
		-- Ethereal floating head
		{ Size = Vector3.new(1.3, 1.2, 1.1), Offset = Vector3.new(0, 0.6, -2.1), Material = Enum.Material.Neon, Transparency = 0.15 },
		-- Third eye (cosmic awareness)
		{ Size = Vector3.new(0.3, 0.3, 0.15), Offset = Vector3.new(0, 1.0, -2.55), Color = Color3.fromRGB(255, 100, 255), Material = Enum.Material.Neon },
		-- Regular eyes (glowing)
		{ Size = Vector3.new(0.28, 0.32, 0.15), Offset = Vector3.new(-0.35, 0.7, -2.55), Color = Color3.fromRGB(200, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.28, 0.32, 0.15), Offset = Vector3.new(0.35, 0.7, -2.55), Color = Color3.fromRGB(200, 255, 255), Material = Enum.Material.Neon },
		-- Snout
		{ Size = Vector3.new(0.5, 0.4, 0.35), Offset = Vector3.new(0, 0.2, -2.5), Material = Enum.Material.Neon, Transparency = 0.2 },
		-- Cosmic antenna ears
		{ Size = Vector3.new(0.15, 0.8, 0.15), Offset = Vector3.new(-0.5, 1.3, -1.9), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.2), Offset = Vector3.new(-0.5, 1.8, -1.9), Color = Color3.fromRGB(255, 200, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.8, 0.15), Offset = Vector3.new(0.5, 1.3, -1.9), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.2), Offset = Vector3.new(0.5, 1.8, -1.9), Color = Color3.fromRGB(255, 200, 255), Material = Enum.Material.Neon },
	},
	TailBlocks = {
		-- Cosmic energy tail
		{ Size = Vector3.new(0.4, 0.4, 0.6), Offset = Vector3.new(0, 0.6, 2.0), Material = Enum.Material.Neon, Transparency = 0.3 },
		{ Size = Vector3.new(0.3, 0.3, 0.5), Offset = Vector3.new(0, 0.8, 2.4), Material = Enum.Material.Neon, Transparency = 0.4 },
		{ Size = Vector3.new(0.2, 0.2, 0.4), Offset = Vector3.new(0, 1.0, 2.7), Material = Enum.Material.Neon, Transparency = 0.5 },
	},
	Legs = {
		Blocks = {
			-- Thin ethereal legs
			{ Size = Vector3.new(0.35, 1.4, 0.35), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Transparency = 0.3 },
			-- Glowing hooves
			{ Size = Vector3.new(0.4, 0.25, 0.45), Offset = Vector3.new(0, -0.7, 0), Material = Enum.Material.Neon },
		},
		OffsetFL = Vector3.new(0.7, -1.6, -1.1),
		PivotY = 0.7,
	},
}

--------------------------------------------------------------------------------
-- CHROMA_CHICK - Color-shifting alien chicken from another dimension
--------------------------------------------------------------------------------
Templates.CHROMA_CHICK = {
	ID = "CHROMA_CHICK",
	Name = "Chromachick",
	BodyBlocks = {
		-- Iridescent body core
		{ Size = Vector3.new(1.8, 1.6, 2.2), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Glass, Transparency = 0.1 },
		-- Color-shift panels (different colors showing through)
		{ Size = Vector3.new(1.4, 1.2, 0.9), Offset = Vector3.new(0, -0.1, -0.9), Color = Color3.fromRGB(255, 100, 200), Material = Enum.Material.Neon, Transparency = 0.3 },
		{ Size = Vector3.new(1.5, 1.3, 0.9), Offset = Vector3.new(0, 0.3, 0.9), Color = Color3.fromRGB(100, 255, 200), Material = Enum.Material.Neon, Transparency = 0.3 },
		-- Crystalline feather ridges
		{ Size = Vector3.new(0.15, 0.5, 1.0), Offset = Vector3.new(-0.9, 0.9, 0), Color = Color3.fromRGB(200, 100, 255), Material = Enum.Material.Glass },
		{ Size = Vector3.new(0.15, 0.5, 1.0), Offset = Vector3.new(0.9, 0.9, 0), Color = Color3.fromRGB(100, 200, 255), Material = Enum.Material.Glass },
		-- Floating crystal feathers
		{ Size = Vector3.new(0.3, 0.3, 0.15), Offset = Vector3.new(-1.3, 0.6, -0.3), Color = Color3.fromRGB(255, 50, 150), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.25, 0.25, 0.12), Offset = Vector3.new(1.4, 0.8, 0.2), Color = Color3.fromRGB(50, 255, 200), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.28, 0.28, 0.14), Offset = Vector3.new(-1.2, 1.0, 0.5), Color = Color3.fromRGB(255, 255, 50), Material = Enum.Material.Neon },
	},
	HeadBlocks = {
		-- Prismatic head
		{ Size = Vector3.new(1.0, 1.0, 0.9), Offset = Vector3.new(0, 0.9, -1.4), Material = Enum.Material.Glass, Transparency = 0.15 },
		-- Antenna comb (alien receiver)
		{ Size = Vector3.new(0.08, 0.6, 0.4), Offset = Vector3.new(0, 1.6, -1.3), Color = Color3.fromRGB(255, 50, 100), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.08, 0.5, 0.3), Offset = Vector3.new(0, 1.5, -1.5), Color = Color3.fromRGB(255, 100, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.08, 0.4, 0.2), Offset = Vector3.new(0, 1.4, -1.65), Color = Color3.fromRGB(255, 200, 50), Material = Enum.Material.Neon },
		-- Crystalline beak
		{ Size = Vector3.new(0.3, 0.25, 0.5), Offset = Vector3.new(0, 0.7, -1.9), Color = Color3.fromRGB(255, 200, 100), Material = Enum.Material.Glass },
		-- Multi-spectrum eyes
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(-0.3, 1.0, -1.8), Color = Color3.fromRGB(255, 0, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(0.3, 1.0, -1.8), Color = Color3.fromRGB(0, 255, 255), Material = Enum.Material.Neon },
		-- Inner eye glow
		{ Size = Vector3.new(0.15, 0.18, 0.08), Offset = Vector3.new(-0.3, 1.05, -1.88), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.18, 0.08), Offset = Vector3.new(0.3, 1.05, -1.88), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
	},
	TailBlocks = {
		-- Prismatic tail feathers
		{ Size = Vector3.new(0.1, 0.9, 0.3), Offset = Vector3.new(0, 1.0, 1.4), Color = Color3.fromRGB(255, 50, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.85, 0.25), Offset = Vector3.new(-0.25, 0.95, 1.45), Color = Color3.fromRGB(50, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.85, 0.25), Offset = Vector3.new(0.25, 0.95, 1.45), Color = Color3.fromRGB(50, 50, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.75, 0.2), Offset = Vector3.new(-0.4, 0.9, 1.5), Color = Color3.fromRGB(255, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.75, 0.2), Offset = Vector3.new(0.4, 0.9, 1.5), Color = Color3.fromRGB(255, 50, 255), Material = Enum.Material.Neon },
	},
	DecorationBlocks = {
		-- Floating crystalline eggs
		{ Size = Vector3.new(0.4, 0.5, 0.35), Offset = Vector3.new(-1.5, -0.3, 0.5), Color = Color3.fromRGB(200, 100, 255), Material = Enum.Material.Glass },
		{ Size = Vector3.new(0.35, 0.45, 0.3), Offset = Vector3.new(1.6, -0.2, -0.3), Color = Color3.fromRGB(100, 255, 200), Material = Enum.Material.Glass },
	},
	Legs = {
		Blocks = {
			-- Crystal legs
			{ Size = Vector3.new(0.15, 0.9, 0.15), Offset = Vector3.new(0, 0, 0), Color = Color3.fromRGB(255, 200, 255), Material = Enum.Material.Glass },
			-- Prismatic feet
			{ Size = Vector3.new(0.45, 0.1, 0.55), Offset = Vector3.new(0, -0.5, 0), Color = Color3.fromRGB(255, 150, 200), Material = Enum.Material.Neon },
		},
		OffsetFL = Vector3.new(0.4, -1.0, -0.6),
		PivotY = 0.45,
	},
}

--------------------------------------------------------------------------------
-- GRAVI_TOAD - Gravity-defying mega frog with impossible abilities
--------------------------------------------------------------------------------
Templates.GRAVI_TOAD = {
	ID = "GRAVI_TOAD",
	Name = "Gravitoad",
	BodyBlocks = {
		-- Bloated anti-gravity body
		{ Size = Vector3.new(2.8, 1.8, 2.8), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		-- Pulsing belly (lighter)
		{ Size = Vector3.new(2.2, 1.0, 2.0), Offset = Vector3.new(0, -0.6, 0), Color = Color3.fromRGB(180, 150, 255), Material = Enum.Material.Neon, Transparency = 0.2 },
		-- Back warts/bumps (alien growths)
		{ Size = Vector3.new(0.5, 0.4, 0.5), Offset = Vector3.new(-0.7, 1.0, -0.5), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.4, 0.35, 0.4), Offset = Vector3.new(0.8, 1.05, 0.3), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.45, 0.4, 0.45), Offset = Vector3.new(-0.3, 1.1, 0.7), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.55, 0.45, 0.55), Offset = Vector3.new(0.5, 0.95, -0.8), Material = Enum.Material.Neon },
		-- Anti-gravity rings (hovering around body)
		{ Size = Vector3.new(3.5, 0.15, 3.5), Offset = Vector3.new(0, -1.0, 0), Color = Color3.fromRGB(150, 100, 255), Material = Enum.Material.Neon, Transparency = 0.4 },
		{ Size = Vector3.new(2.8, 0.1, 2.8), Offset = Vector3.new(0, -1.3, 0), Color = Color3.fromRGB(100, 50, 255), Material = Enum.Material.Neon, Transparency = 0.5 },
	},
	HeadBlocks = {
		-- Wide flat head merged with body
		{ Size = Vector3.new(3.0, 1.0, 1.4), Offset = Vector3.new(0, 0.5, -1.6), Material = Enum.Material.SmoothPlastic },
		-- MASSIVE bulging eyes (independently rotating)
		{ Size = Vector3.new(1.0, 1.0, 0.9), Offset = Vector3.new(-1.0, 1.4, -1.4), Color = Color3.fromRGB(255, 255, 200), Material = Enum.Material.Neon },
		{ Size = Vector3.new(1.0, 1.0, 0.9), Offset = Vector3.new(1.0, 1.4, -1.4), Color = Color3.fromRGB(255, 255, 200), Material = Enum.Material.Neon },
		-- Hypnotic spiral pupils
		{ Size = Vector3.new(0.5, 0.5, 0.2), Offset = Vector3.new(-1.0, 1.4, -1.9), Color = Color3.fromRGB(100, 0, 200), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.5, 0.5, 0.2), Offset = Vector3.new(1.0, 1.4, -1.9), Color = Color3.fromRGB(200, 0, 100), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.1), Offset = Vector3.new(-1.0, 1.4, -2.0), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.1), Offset = Vector3.new(1.0, 1.4, -2.0), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		-- Extra eye stalks (alien mutation)
		{ Size = Vector3.new(0.15, 0.5, 0.15), Offset = Vector3.new(0, 1.6, -1.2) },
		{ Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(0, 2.0, -1.2), Color = Color3.fromRGB(255, 200, 100), Material = Enum.Material.Neon },
		-- Wide gaping mouth
		{ Size = Vector3.new(1.8, 0.2, 0.5), Offset = Vector3.new(0, 0.1, -2.0), Color = Color3.fromRGB(150, 50, 100), Material = Enum.Material.SmoothPlastic },
		-- 30-FOOT TONGUE (coiled for now)
		{ Size = Vector3.new(0.3, 0.15, 2.5), Offset = Vector3.new(0, 0.0, -3.5), Color = Color3.fromRGB(255, 100, 150), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.25, 0.12, 1.5), Offset = Vector3.new(0, -0.05, -5.5), Color = Color3.fromRGB(255, 80, 130), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.2, 0.1, 0.8), Offset = Vector3.new(0, -0.1, -6.8), Color = Color3.fromRGB(255, 60, 110), Material = Enum.Material.SmoothPlastic },
	},
	Legs = {
		Blocks = {
			-- Massive muscular hopping legs
			{ Size = Vector3.new(0.8, 1.4, 0.8), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
			-- Oversized webbed feet with suction cups
			{ Size = Vector3.new(1.2, 0.2, 1.4), Offset = Vector3.new(0, -0.8, 0.2), Material = Enum.Material.SmoothPlastic },
			-- Suction pad glow
			{ Size = Vector3.new(0.8, 0.1, 1.0), Offset = Vector3.new(0, -0.95, 0.2), Color = Color3.fromRGB(150, 100, 255), Material = Enum.Material.Neon },
		},
		OffsetFL = Vector3.new(1.3, -1.1, -0.9),
		PivotY = 0.7,
	},
}

--------------------------------------------------------------------------------
-- PORKULON - Cyber-pig with alien tech implants
--------------------------------------------------------------------------------
Templates.PORKULON = {
	ID = "PORKULON",
	Name = "Porkulon",
	BodyBlocks = {
		-- Metallic armored body
		{ Size = Vector3.new(2.4, 2.0, 3.2), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Metal },
		-- Glowing circuit panels
		{ Size = Vector3.new(0.8, 0.1, 1.5), Offset = Vector3.new(-1.25, 0.3, 0), Color = Color3.fromRGB(255, 100, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.8, 0.1, 1.5), Offset = Vector3.new(1.25, 0.3, 0), Color = Color3.fromRGB(255, 100, 0), Material = Enum.Material.Neon },
		-- Tech spine ridge
		{ Size = Vector3.new(0.4, 0.4, 2.5), Offset = Vector3.new(0, 1.2, 0), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(0.2, 0.3, 0.2), Offset = Vector3.new(0, 1.5, -0.8), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.3, 0.2), Offset = Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.3, 0.2), Offset = Vector3.new(0, 1.5, 0.8), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		-- Belly exhaust vents
		{ Size = Vector3.new(1.5, 0.3, 0.8), Offset = Vector3.new(0, -0.9, 0), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(1.0, 0.15, 0.5), Offset = Vector3.new(0, -1.1, 0), Color = Color3.fromRGB(255, 150, 50), Material = Enum.Material.Neon },
	},
	HeadBlocks = {
		-- Armored snout
		{ Size = Vector3.new(1.4, 1.3, 1.3), Offset = Vector3.new(0, 0.1, -1.8), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.9, 0.8, 0.7), Offset = Vector3.new(0, -0.1, -2.5), Material = Enum.Material.Metal },
		-- Robotic snout plate
		{ Size = Vector3.new(0.7, 0.6, 0.2), Offset = Vector3.new(0, -0.1, -2.95), Material = Enum.Material.DiamondPlate },
		-- Glowing nostrils
		{ Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(-0.2, -0.05, -3.0), Color = Color3.fromRGB(255, 100, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(0.2, -0.05, -3.0), Color = Color3.fromRGB(255, 100, 0), Material = Enum.Material.Neon },
		-- Cyber eyes
		{ Size = Vector3.new(0.35, 0.35, 0.15), Offset = Vector3.new(-0.4, 0.4, -2.4), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.35, 0.35, 0.15), Offset = Vector3.new(0.4, 0.4, -2.4), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		-- Scanner visor
		{ Size = Vector3.new(1.2, 0.15, 0.1), Offset = Vector3.new(0, 0.4, -2.5), Color = Color3.fromRGB(255, 200, 100), Material = Enum.Material.Neon, Transparency = 0.3 },
		-- MAIN ANTENNA (signal receiver)
		{ Size = Vector3.new(0.15, 1.2, 0.15), Offset = Vector3.new(0, 1.3, -1.6), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.4, 0.15, 0.4), Offset = Vector3.new(0, 2.0, -1.6), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(0.25, 0.25, 0.25), Offset = Vector3.new(0, 2.3, -1.6), Color = Color3.fromRGB(255, 0, 0), Material = Enum.Material.Neon },
		-- Side antennas
		{ Size = Vector3.new(0.1, 0.5, 0.1), Offset = Vector3.new(-0.6, 0.9, -1.5), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.5, 0.1), Offset = Vector3.new(0.6, 0.9, -1.5), Material = Enum.Material.Metal },
		-- Metal ears
		{ Size = Vector3.new(0.15, 0.5, 0.3), Offset = Vector3.new(-0.7, 0.7, -1.6), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(0.15, 0.5, 0.3), Offset = Vector3.new(0.7, 0.7, -1.6), Material = Enum.Material.DiamondPlate },
	},
	TailBlocks = {
		-- Exhaust pipe tail
		{ Size = Vector3.new(0.3, 0.3, 0.6), Offset = Vector3.new(0, 0.4, 1.8), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.4, 0.4, 0.3), Offset = Vector3.new(0, 0.4, 2.2), Material = Enum.Material.DiamondPlate },
		-- Flame exhaust
		{ Size = Vector3.new(0.25, 0.25, 0.4), Offset = Vector3.new(0, 0.4, 2.5), Color = Color3.fromRGB(255, 150, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.15, 0.3), Offset = Vector3.new(0, 0.4, 2.8), Color = Color3.fromRGB(255, 200, 100), Material = Enum.Material.Neon, Transparency = 0.3 },
	},
	Legs = {
		Blocks = {
			-- Hydraulic leg
			{ Size = Vector3.new(0.5, 1.2, 0.5), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.DiamondPlate },
			-- Piston detail
			{ Size = Vector3.new(0.2, 0.8, 0.2), Offset = Vector3.new(0.2, 0.1, 0), Material = Enum.Material.Metal },
			-- Rocket hoof
			{ Size = Vector3.new(0.6, 0.35, 0.7), Offset = Vector3.new(0, -0.65, 0), Material = Enum.Material.DiamondPlate },
			-- Thruster glow
			{ Size = Vector3.new(0.4, 0.15, 0.5), Offset = Vector3.new(0, -0.85, 0), Color = Color3.fromRGB(255, 100, 0), Material = Enum.Material.Neon },
		},
		OffsetFL = Vector3.new(0.8, -1.4, -1.1),
		PivotY = 0.6,
	},
}

--------------------------------------------------------------------------------
-- BUNNOCTOPUS - Tentacled rabbit hybrid abomination
--------------------------------------------------------------------------------
Templates.BUNNOCTOPUS = {
	ID = "BUNNOCTOPUS",
	Name = "Bunnoctopus",
	BodyBlocks = {
		-- Squishy bunny-cephalopod body
		{ Size = Vector3.new(2.0, 1.8, 2.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		-- Bulbous underbelly
		{ Size = Vector3.new(1.8, 1.2, 2.0), Offset = Vector3.new(0, -0.6, 0), Color = Color3.fromRGB(220, 180, 255), Material = Enum.Material.SmoothPlastic },
		-- Slime patches
		{ Size = Vector3.new(0.8, 0.3, 1.0), Offset = Vector3.new(-0.9, 0.5, 0.3), Color = Color3.fromRGB(200, 150, 255), Material = Enum.Material.Neon, Transparency = 0.4 },
		{ Size = Vector3.new(0.7, 0.25, 0.9), Offset = Vector3.new(0.85, 0.6, -0.2), Color = Color3.fromRGB(200, 150, 255), Material = Enum.Material.Neon, Transparency = 0.4 },
	},
	HeadBlocks = {
		-- Round bunny head
		{ Size = Vector3.new(1.4, 1.3, 1.2), Offset = Vector3.new(0, 0.7, -1.5), Material = Enum.Material.SmoothPlastic },
		-- Cute nose
		{ Size = Vector3.new(0.25, 0.2, 0.15), Offset = Vector3.new(0, 0.45, -2.1), Color = Color3.fromRGB(255, 150, 180) },
		-- Huge innocent eyes
		{ Size = Vector3.new(0.4, 0.5, 0.15), Offset = Vector3.new(-0.35, 0.85, -2.0), Color = Color3.fromRGB(30, 30, 30) },
		{ Size = Vector3.new(0.4, 0.5, 0.15), Offset = Vector3.new(0.35, 0.85, -2.0), Color = Color3.fromRGB(30, 30, 30) },
		-- Eye highlights
		{ Size = Vector3.new(0.15, 0.18, 0.08), Offset = Vector3.new(-0.28, 0.95, -2.08), Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.15, 0.18, 0.08), Offset = Vector3.new(0.42, 0.95, -2.08), Color = Color3.fromRGB(255, 255, 255) },
		-- 8 EAR-TENTACLES (instead of normal ears)
		-- Front pair
		{ Size = Vector3.new(0.25, 1.0, 0.25), Offset = Vector3.new(-0.5, 1.6, -1.3), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(-0.6, 2.4, -1.0), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.25, 1.0, 0.25), Offset = Vector3.new(0.5, 1.6, -1.3), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(0.6, 2.4, -1.0), Material = Enum.Material.SmoothPlastic },
		-- Middle pair
		{ Size = Vector3.new(0.22, 0.9, 0.22), Offset = Vector3.new(-0.65, 1.5, -1.5), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.18, 0.5, 0.18), Offset = Vector3.new(-0.8, 2.2, -1.6), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.22, 0.9, 0.22), Offset = Vector3.new(0.65, 1.5, -1.5), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.18, 0.5, 0.18), Offset = Vector3.new(0.8, 2.2, -1.6), Material = Enum.Material.SmoothPlastic },
		-- Back pair
		{ Size = Vector3.new(0.2, 0.8, 0.2), Offset = Vector3.new(-0.55, 1.4, -1.2), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.15, 0.45, 0.15), Offset = Vector3.new(-0.45, 2.0, -0.9), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.2, 0.8, 0.2), Offset = Vector3.new(0.55, 1.4, -1.2), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.15, 0.45, 0.15), Offset = Vector3.new(0.45, 2.0, -0.9), Material = Enum.Material.SmoothPlastic },
		-- Rear pair (shorter)
		{ Size = Vector3.new(0.18, 0.6, 0.18), Offset = Vector3.new(-0.4, 1.3, -1.1), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.18, 0.6, 0.18), Offset = Vector3.new(0.4, 1.3, -1.1), Material = Enum.Material.SmoothPlastic },
		-- Suction cup tips on tentacles
		{ Size = Vector3.new(0.15, 0.1, 0.15), Offset = Vector3.new(-0.6, 2.85, -0.9), Color = Color3.fromRGB(255, 150, 200), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.15, 0.1, 0.15), Offset = Vector3.new(0.6, 2.85, -0.9), Color = Color3.fromRGB(255, 150, 200), Material = Enum.Material.SmoothPlastic },
	},
	TailBlocks = {
		-- Fluffy bunny tail (but slimy)
		{ Size = Vector3.new(0.6, 0.6, 0.5), Offset = Vector3.new(0, 0.2, 1.4) },
		{ Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0, 0.3, 1.7), Color = Color3.fromRGB(200, 150, 255), Material = Enum.Material.Neon, Transparency = 0.3 },
	},
	Legs = {
		Blocks = {
			-- Tentacle legs with suction cups
			{ Size = Vector3.new(0.4, 1.0, 0.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
			{ Size = Vector3.new(0.35, 0.6, 0.35), Offset = Vector3.new(0.1, -0.7, 0), Material = Enum.Material.SmoothPlastic },
			-- Suction cup foot
			{ Size = Vector3.new(0.5, 0.15, 0.5), Offset = Vector3.new(0.1, -1.05, 0), Color = Color3.fromRGB(255, 150, 200), Material = Enum.Material.SmoothPlastic },
		},
		OffsetFL = Vector3.new(0.7, -1.0, -0.8),
		PivotY = 0.5,
	},
}

--------------------------------------------------------------------------------
-- DUCKZILLA - Giant mutant duck kaiju
--------------------------------------------------------------------------------
Templates.DUCKZILLA = {
	ID = "DUCKZILLA",
	Name = "Duckzilla",
	BodyBlocks = {
		-- MASSIVE body (2x normal duck)
		{ Size = Vector3.new(3.2, 2.6, 4.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		-- Armored chest plates
		{ Size = Vector3.new(2.6, 2.0, 1.6), Offset = Vector3.new(0, -0.2, -1.8), Material = Enum.Material.DiamondPlate },
		-- Mutant muscle bulges
		{ Size = Vector3.new(1.0, 0.8, 1.4), Offset = Vector3.new(-1.6, 0.3, 0), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(1.0, 0.8, 1.4), Offset = Vector3.new(1.6, 0.3, 0), Material = Enum.Material.SmoothPlastic },
		-- BACK SPIKES (kaiju style)
		{ Size = Vector3.new(0.3, 0.8, 0.4), Offset = Vector3.new(0, 1.6, -0.8) },
		{ Size = Vector3.new(0.35, 1.1, 0.45), Offset = Vector3.new(0, 1.8, -0.2) },
		{ Size = Vector3.new(0.4, 1.3, 0.5), Offset = Vector3.new(0, 2.0, 0.4) },
		{ Size = Vector3.new(0.35, 1.1, 0.45), Offset = Vector3.new(0, 1.8, 1.0) },
		{ Size = Vector3.new(0.3, 0.8, 0.4), Offset = Vector3.new(0, 1.6, 1.6) },
		-- Side spikes
		{ Size = Vector3.new(0.6, 0.4, 0.3), Offset = Vector3.new(-1.7, 0.9, -0.5) },
		{ Size = Vector3.new(0.6, 0.4, 0.3), Offset = Vector3.new(1.7, 0.9, -0.5) },
		{ Size = Vector3.new(0.5, 0.35, 0.25), Offset = Vector3.new(-1.6, 0.8, 0.5) },
		{ Size = Vector3.new(0.5, 0.35, 0.25), Offset = Vector3.new(1.6, 0.8, 0.5) },
		-- Steam vents
		{ Size = Vector3.new(0.4, 0.3, 0.4), Offset = Vector3.new(-1.4, 1.2, 0), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(0.4, 0.3, 0.4), Offset = Vector3.new(1.4, 1.2, 0), Material = Enum.Material.DiamondPlate },
		-- Steam plumes
		{ Size = Vector3.new(0.3, 0.6, 0.3), Offset = Vector3.new(-1.4, 1.7, 0), Color = Color3.fromRGB(200, 200, 200), Material = Enum.Material.Neon, Transparency = 0.5 },
		{ Size = Vector3.new(0.3, 0.6, 0.3), Offset = Vector3.new(1.4, 1.7, 0), Color = Color3.fromRGB(200, 200, 200), Material = Enum.Material.Neon, Transparency = 0.5 },
	},
	HeadBlocks = {
		-- Massive angry head
		{ Size = Vector3.new(2.0, 2.0, 2.0), Offset = Vector3.new(0, 1.4, -2.8), Material = Enum.Material.SmoothPlastic },
		-- Armored bill (weaponized)
		{ Size = Vector3.new(1.0, 0.5, 1.4), Offset = Vector3.new(0, 0.9, -4.0), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(100, 80, 60) },
		{ Size = Vector3.new(0.9, 0.35, 1.2), Offset = Vector3.new(0, 0.6, -3.9), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(80, 60, 40) },
		-- Bill serrations (teeth-like)
		{ Size = Vector3.new(0.8, 0.15, 0.1), Offset = Vector3.new(0, 0.75, -4.6), Color = Color3.fromRGB(255, 255, 200) },
		-- ANGRY eyes
		{ Size = Vector3.new(0.5, 0.4, 0.2), Offset = Vector3.new(-0.55, 1.8, -3.6), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.5, 0.4, 0.2), Offset = Vector3.new(0.55, 1.8, -3.6), Color = Color3.fromRGB(255, 50, 0), Material = Enum.Material.Neon },
		-- Angry brow ridges
		{ Size = Vector3.new(0.7, 0.2, 0.3), Offset = Vector3.new(-0.55, 2.1, -3.5) },
		{ Size = Vector3.new(0.7, 0.2, 0.3), Offset = Vector3.new(0.55, 2.1, -3.5) },
		-- Head crest/crown
		{ Size = Vector3.new(0.25, 0.6, 0.4), Offset = Vector3.new(0, 2.6, -2.8) },
		{ Size = Vector3.new(0.2, 0.5, 0.35), Offset = Vector3.new(-0.3, 2.5, -2.9) },
		{ Size = Vector3.new(0.2, 0.5, 0.35), Offset = Vector3.new(0.3, 2.5, -2.9) },
	},
	TailBlocks = {
		-- Spiked kaiju tail
		{ Size = Vector3.new(0.8, 0.8, 1.0), Offset = Vector3.new(0, 0.6, 2.4) },
		{ Size = Vector3.new(0.6, 0.6, 0.8), Offset = Vector3.new(0, 0.8, 3.0) },
		{ Size = Vector3.new(0.4, 0.5, 0.6), Offset = Vector3.new(0, 1.0, 3.5) },
		-- Tail spikes
		{ Size = Vector3.new(0.2, 0.4, 0.2), Offset = Vector3.new(0, 1.1, 2.6) },
		{ Size = Vector3.new(0.18, 0.35, 0.18), Offset = Vector3.new(0, 1.2, 3.1) },
	},
	Legs = {
		Blocks = {
			-- Thick monster legs
			{ Size = Vector3.new(0.6, 1.2, 0.6), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic },
			-- Clawed monster feet
			{ Size = Vector3.new(1.0, 0.25, 1.2), Offset = Vector3.new(0, -0.7, 0), Color = Color3.fromRGB(100, 80, 60), Material = Enum.Material.DiamondPlate },
			-- Claws
			{ Size = Vector3.new(0.15, 0.15, 0.4), Offset = Vector3.new(-0.3, -0.8, -0.5), Color = Color3.fromRGB(60, 50, 40) },
			{ Size = Vector3.new(0.15, 0.15, 0.4), Offset = Vector3.new(0, -0.8, -0.6), Color = Color3.fromRGB(60, 50, 40) },
			{ Size = Vector3.new(0.15, 0.15, 0.4), Offset = Vector3.new(0.3, -0.8, -0.5), Color = Color3.fromRGB(60, 50, 40) },
		},
		OffsetFL = Vector3.new(0.8, -1.6, -1.0),
		PivotY = 0.6,
	},
}

--------------------------------------------------------------------------------
-- MOOSETRONAUT - Space cow that was the UFO's test pilot
--------------------------------------------------------------------------------
Templates.MOOSETRONAUT = {
	ID = "MOOSETRONAUT",
	Name = "Moosetronaut",
	BodyBlocks = {
		-- Space suit body
		{ Size = Vector3.new(2.6, 2.2, 3.8), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 210, 220) },
		-- Life support pack (back)
		{ Size = Vector3.new(1.8, 1.4, 1.0), Offset = Vector3.new(0, 0.8, 1.5), Material = Enum.Material.DiamondPlate },
		-- Oxygen tanks
		{ Size = Vector3.new(0.4, 1.0, 0.4), Offset = Vector3.new(-0.6, 0.9, 1.9), Material = Enum.Material.Metal, Color = Color3.fromRGB(100, 150, 200) },
		{ Size = Vector3.new(0.4, 1.0, 0.4), Offset = Vector3.new(0.6, 0.9, 1.9), Material = Enum.Material.Metal, Color = Color3.fromRGB(100, 150, 200) },
		-- Suit panels/patches
		{ Size = Vector3.new(1.5, 0.15, 2.0), Offset = Vector3.new(0, 1.15, -0.3), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 255, 255) },
		{ Size = Vector3.new(0.8, 0.1, 0.8), Offset = Vector3.new(-1.1, 0.3, -0.5), Color = Color3.fromRGB(50, 100, 200), Material = Enum.Material.Neon },
		-- Status lights
		{ Size = Vector3.new(0.2, 0.2, 0.1), Offset = Vector3.new(-1.35, 0.6, -0.8), Color = Color3.fromRGB(50, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.1), Offset = Vector3.new(-1.35, 0.6, -0.4), Color = Color3.fromRGB(50, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.1), Offset = Vector3.new(-1.35, 0.6, 0), Color = Color3.fromRGB(255, 200, 50), Material = Enum.Material.Neon },
		-- Belly patches
		{ Size = Vector3.new(1.2, 0.8, 1.4), Offset = Vector3.new(0, -0.9, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(50, 50, 50) },
	},
	HeadBlocks = {
		-- HELMET (cracked glass dome)
		{ Size = Vector3.new(1.8, 1.7, 1.7), Offset = Vector3.new(0, 0.7, -2.2), Material = Enum.Material.Glass, Transparency = 0.3, Color = Color3.fromRGB(200, 220, 255) },
		-- Helmet frame
		{ Size = Vector3.new(2.0, 0.2, 0.2), Offset = Vector3.new(0, 1.6, -2.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.2, 1.8, 0.2), Offset = Vector3.new(-0.9, 0.7, -2.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.2, 1.8, 0.2), Offset = Vector3.new(0.9, 0.7, -2.2), Material = Enum.Material.Metal },
		-- Crack lines in helmet
		{ Size = Vector3.new(0.05, 0.6, 0.05), Offset = Vector3.new(-0.3, 1.0, -3.0), Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 200, 200), Transparency = 0.5 },
		{ Size = Vector3.new(0.05, 0.4, 0.05), Offset = Vector3.new(-0.15, 0.7, -3.05), Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 200, 200), Transparency = 0.5 },
		-- Cow head inside helmet
		{ Size = Vector3.new(1.3, 1.2, 1.0), Offset = Vector3.new(0, 0.5, -2.1) },
		-- Snout
		{ Size = Vector3.new(0.8, 0.6, 0.5), Offset = Vector3.new(0, 0.1, -2.6) },
		-- Nostrils
		{ Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(-0.2, 0.0, -2.9), Color = Color3.fromRGB(50, 40, 40) },
		{ Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(0.2, 0.0, -2.9), Color = Color3.fromRGB(50, 40, 40) },
		-- Spaced-out eyes
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(-0.4, 0.7, -2.55), Color = Color3.fromRGB(100, 150, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(0.4, 0.7, -2.55), Color = Color3.fromRGB(100, 150, 255), Material = Enum.Material.Neon },
		-- Star reflections in eyes
		{ Size = Vector3.new(0.08, 0.08, 0.05), Offset = Vector3.new(-0.35, 0.8, -2.6), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.08, 0.08, 0.05), Offset = Vector3.new(0.45, 0.75, -2.6), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		-- Ears (inside helmet - squished)
		{ Size = Vector3.new(0.15, 0.4, 0.25), Offset = Vector3.new(-0.55, 0.9, -1.9) },
		{ Size = Vector3.new(0.15, 0.4, 0.25), Offset = Vector3.new(0.55, 0.9, -1.9) },
		-- Radio antenna on helmet
		{ Size = Vector3.new(0.1, 0.8, 0.1), Offset = Vector3.new(0.7, 1.8, -2.0), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0.7, 2.3, -2.0), Color = Color3.fromRGB(255, 50, 50), Material = Enum.Material.Neon },
	},
	TailBlocks = {
		-- Space-suited tail
		{ Size = Vector3.new(0.25, 0.25, 0.8), Offset = Vector3.new(0, 0.4, 2.2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 210, 220) },
		{ Size = Vector3.new(0.35, 0.35, 0.3), Offset = Vector3.new(0, 0.4, 2.8), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 210, 220) },
	},
	Legs = {
		Blocks = {
			-- ROCKET BOOSTER LEGS
			{ Size = Vector3.new(0.6, 1.0, 0.6), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.DiamondPlate },
			-- Thruster housing
			{ Size = Vector3.new(0.7, 0.5, 0.7), Offset = Vector3.new(0, -0.6, 0), Material = Enum.Material.Metal },
			-- Thruster nozzle
			{ Size = Vector3.new(0.5, 0.3, 0.5), Offset = Vector3.new(0, -0.9, 0), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(60, 60, 60) },
			-- Thruster flame
			{ Size = Vector3.new(0.35, 0.5, 0.35), Offset = Vector3.new(0, -1.25, 0), Color = Color3.fromRGB(100, 150, 255), Material = Enum.Material.Neon },
			{ Size = Vector3.new(0.25, 0.3, 0.25), Offset = Vector3.new(0, -1.5, 0), Color = Color3.fromRGB(150, 200, 255), Material = Enum.Material.Neon, Transparency = 0.3 },
		},
		OffsetFL = Vector3.new(0.9, -1.5, -1.3),
		PivotY = 0.5,
	},
}

--------------------------------------------------------------------------------
-- HEDGEBORG - Cybernetic hedgehog with full upgrades
--------------------------------------------------------------------------------
Templates.HEDGEBORG = {
	ID = "HEDGEBORG",
	Name = "Hedgeborg",
	BodyBlocks = {
		-- Metal armored body
		{ Size = Vector3.new(2.0, 1.6, 2.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(150, 160, 170) },
		-- Glowing circuit underbelly
		{ Size = Vector3.new(1.4, 0.4, 1.8), Offset = Vector3.new(0, -0.7, 0), Color = Color3.fromRGB(0, 200, 255), Material = Enum.Material.Neon, Transparency = 0.2 },
		-- ANTENNA SPINES (instead of organic spines)
		{ Size = Vector3.new(0.1, 0.8, 0.1), Offset = Vector3.new(-0.4, 1.2, -0.6), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.9, 0.1), Offset = Vector3.new(0.4, 1.3, -0.4), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 1.0, 0.1), Offset = Vector3.new(0, 1.4, -0.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.95, 0.1), Offset = Vector3.new(-0.3, 1.35, 0.2), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.85, 0.1), Offset = Vector3.new(0.35, 1.25, 0.3), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.75, 0.1), Offset = Vector3.new(0, 1.15, 0.6), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.7, 0.1), Offset = Vector3.new(-0.25, 1.1, 0.7), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.1, 0.65, 0.1), Offset = Vector3.new(0.3, 1.05, 0.75), Material = Enum.Material.Metal },
		-- Antenna tips (glowing)
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(-0.4, 2.0, -0.6), Color = Color3.fromRGB(255, 0, 100), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0.4, 2.2, -0.4), Color = Color3.fromRGB(0, 255, 200), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0, 2.4, -0.2), Color = Color3.fromRGB(255, 200, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(-0.3, 2.25, 0.2), Color = Color3.fromRGB(100, 100, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0.35, 2.1, 0.3), Color = Color3.fromRGB(255, 100, 100), Material = Enum.Material.Neon },
		-- Data ports
		{ Size = Vector3.new(0.3, 0.2, 0.15), Offset = Vector3.new(-1.05, 0.3, 0), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(0.3, 0.2, 0.15), Offset = Vector3.new(1.05, 0.3, 0), Material = Enum.Material.DiamondPlate },
	},
	HeadBlocks = {
		-- Mechanical head casing
		{ Size = Vector3.new(0.9, 0.8, 1.0), Offset = Vector3.new(0, 0.2, -1.4), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(150, 160, 170) },
		-- Robotic snout
		{ Size = Vector3.new(0.5, 0.4, 0.6), Offset = Vector3.new(0, 0.05, -2.0), Material = Enum.Material.Metal },
		-- Sensor nose
		{ Size = Vector3.new(0.25, 0.2, 0.15), Offset = Vector3.new(0, 0.1, -2.35), Color = Color3.fromRGB(0, 200, 255), Material = Enum.Material.Neon },
		-- LASER EYE (right side - red)
		{ Size = Vector3.new(0.35, 0.35, 0.2), Offset = Vector3.new(0.3, 0.4, -1.85), Color = Color3.fromRGB(255, 0, 0), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.3), Offset = Vector3.new(0.3, 0.4, -2.05), Color = Color3.fromRGB(255, 50, 50), Material = Enum.Material.Neon },
		-- Normal cyber eye (left side - blue)
		{ Size = Vector3.new(0.25, 0.28, 0.15), Offset = Vector3.new(-0.3, 0.4, -1.85), Color = Color3.fromRGB(0, 200, 255), Material = Enum.Material.Neon },
		-- Scanner visor
		{ Size = Vector3.new(0.8, 0.12, 0.05), Offset = Vector3.new(0, 0.4, -1.95), Color = Color3.fromRGB(0, 255, 200), Material = Enum.Material.Neon, Transparency = 0.3 },
		-- Mechanical ears
		{ Size = Vector3.new(0.2, 0.3, 0.2), Offset = Vector3.new(-0.4, 0.6, -1.3), Material = Enum.Material.DiamondPlate },
		{ Size = Vector3.new(0.2, 0.3, 0.2), Offset = Vector3.new(0.4, 0.6, -1.3), Material = Enum.Material.DiamondPlate },
		-- Ear sensors
		{ Size = Vector3.new(0.1, 0.15, 0.1), Offset = Vector3.new(-0.4, 0.85, -1.3), Color = Color3.fromRGB(0, 255, 100), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.15, 0.1), Offset = Vector3.new(0.4, 0.85, -1.3), Color = Color3.fromRGB(0, 255, 100), Material = Enum.Material.Neon },
	},
	Legs = {
		Blocks = {
			-- Mechanical piston leg
			{ Size = Vector3.new(0.35, 0.6, 0.35), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.DiamondPlate },
			-- Hydraulic detail
			{ Size = Vector3.new(0.15, 0.4, 0.15), Offset = Vector3.new(0.12, -0.1, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(100, 110, 120) },
			-- Gripper foot
			{ Size = Vector3.new(0.4, 0.2, 0.5), Offset = Vector3.new(0, -0.4, 0), Material = Enum.Material.DiamondPlate },
			-- Foot glow
			{ Size = Vector3.new(0.3, 0.08, 0.4), Offset = Vector3.new(0, -0.52, 0), Color = Color3.fromRGB(0, 200, 255), Material = Enum.Material.Neon },
		},
		OffsetFL = Vector3.new(0.6, -0.95, -0.8),
		PivotY = 0.3,
	},
}

--------------------------------------------------------------------------------
-- SNAILSTORM - Lightning-fast electric snail (paradox creature)
--------------------------------------------------------------------------------
Templates.SNAILSTORM = {
	ID = "SNAILSTORM",
	Name = "Snailstorm",
	BodyBlocks = {
		-- Aerodynamic body/foot
		{ Size = Vector3.new(1.6, 0.7, 2.8), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(50, 150, 255) },
		-- Speed lines (energy trails)
		{ Size = Vector3.new(0.1, 0.2, 1.5), Offset = Vector3.new(-0.7, 0.2, 0.5), Color = Color3.fromRGB(200, 255, 255), Material = Enum.Material.Neon, Transparency = 0.4 },
		{ Size = Vector3.new(0.1, 0.2, 1.5), Offset = Vector3.new(0.7, 0.2, 0.5), Color = Color3.fromRGB(200, 255, 255), Material = Enum.Material.Neon, Transparency = 0.4 },
		{ Size = Vector3.new(0.1, 0.15, 1.2), Offset = Vector3.new(-0.5, 0.4, 0.7), Color = Color3.fromRGB(255, 255, 200), Material = Enum.Material.Neon, Transparency = 0.5 },
		{ Size = Vector3.new(0.1, 0.15, 1.2), Offset = Vector3.new(0.5, 0.4, 0.7), Color = Color3.fromRGB(255, 255, 200), Material = Enum.Material.Neon, Transparency = 0.5 },
		-- TURBINE SHELL (spinning)
		{ Size = Vector3.new(1.6, 1.4, 1.6), Offset = Vector3.new(0, 1.0, 0.3), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(80, 100, 120) },
		-- Turbine blades (spiral pattern)
		{ Size = Vector3.new(1.8, 0.15, 0.3), Offset = Vector3.new(0, 1.0, 0.3), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.3, 0.15, 1.8), Offset = Vector3.new(0, 1.0, 0.3), Material = Enum.Material.Metal },
		{ Size = Vector3.new(1.4, 0.15, 0.25), Offset = Vector3.new(0, 1.3, 0.3), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.25, 0.15, 1.4), Offset = Vector3.new(0, 1.3, 0.3), Material = Enum.Material.Metal },
		-- Turbine core (glowing)
		{ Size = Vector3.new(0.6, 0.8, 0.6), Offset = Vector3.new(0, 1.6, 0.3), Color = Color3.fromRGB(255, 255, 100), Material = Enum.Material.Neon },
		-- Lightning crackling around shell
		{ Size = Vector3.new(0.1, 0.6, 0.1), Offset = Vector3.new(-1.0, 1.4, 0), Color = Color3.fromRGB(255, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.5, 0.1), Offset = Vector3.new(1.0, 1.5, 0.3), Color = Color3.fromRGB(255, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.55, 0.1), Offset = Vector3.new(0.3, 1.8, 0.8), Color = Color3.fromRGB(255, 255, 50), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.1, 0.45, 0.1), Offset = Vector3.new(-0.5, 1.7, -0.2), Color = Color3.fromRGB(255, 255, 50), Material = Enum.Material.Neon },
	},
	HeadBlocks = {
		-- Streamlined head
		{ Size = Vector3.new(0.9, 0.8, 0.9), Offset = Vector3.new(0, 0.5, -1.5), Material = Enum.Material.Neon, Color = Color3.fromRGB(50, 150, 255) },
		-- Eye stalks (lightning rods)
		{ Size = Vector3.new(0.12, 0.8, 0.12), Offset = Vector3.new(-0.25, 1.1, -1.6), Material = Enum.Material.Metal },
		{ Size = Vector3.new(0.12, 0.8, 0.12), Offset = Vector3.new(0.25, 1.1, -1.6), Material = Enum.Material.Metal },
		-- Electric eyes
		{ Size = Vector3.new(0.3, 0.3, 0.3), Offset = Vector3.new(-0.25, 1.6, -1.6), Color = Color3.fromRGB(255, 255, 100), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.3, 0.3, 0.3), Offset = Vector3.new(0.25, 1.6, -1.6), Color = Color3.fromRGB(255, 255, 100), Material = Enum.Material.Neon },
		-- Eye sparks
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(-0.25, 1.85, -1.6), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0.25, 1.85, -1.6), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		-- Aerodynamic feelers
		{ Size = Vector3.new(0.08, 0.5, 0.08), Offset = Vector3.new(-0.35, 0.7, -1.9), Material = Enum.Material.Neon, Color = Color3.fromRGB(100, 200, 255) },
		{ Size = Vector3.new(0.08, 0.5, 0.08), Offset = Vector3.new(0.35, 0.7, -1.9), Material = Enum.Material.Neon, Color = Color3.fromRGB(100, 200, 255) },
	},
	TailBlocks = {
		-- Exhaust trail
		{ Size = Vector3.new(0.8, 0.4, 0.6), Offset = Vector3.new(0, 0.2, 1.6), Color = Color3.fromRGB(100, 200, 255), Material = Enum.Material.Neon, Transparency = 0.3 },
		{ Size = Vector3.new(0.6, 0.3, 0.8), Offset = Vector3.new(0, 0.15, 2.2), Color = Color3.fromRGB(150, 220, 255), Material = Enum.Material.Neon, Transparency = 0.5 },
		{ Size = Vector3.new(0.4, 0.2, 1.0), Offset = Vector3.new(0, 0.1, 2.9), Color = Color3.fromRGB(200, 240, 255), Material = Enum.Material.Neon, Transparency = 0.7 },
	},
	Legs = {
		Blocks = {
			-- Energy propulsion pads
			{ Size = Vector3.new(0.4, 0.2, 0.5), Offset = Vector3.new(0, 0, 0), Color = Color3.fromRGB(100, 200, 255), Material = Enum.Material.Neon },
			-- Hover glow
			{ Size = Vector3.new(0.5, 0.1, 0.6), Offset = Vector3.new(0, -0.15, 0), Color = Color3.fromRGB(200, 255, 255), Material = Enum.Material.Neon, Transparency = 0.4 },
		},
		OffsetFL = Vector3.new(0.5, -0.45, -0.9),
		PivotY = 0.1,
	},
}

--------------------------------------------------------------------------------
-- VOID_GOAT - Reality-bending cosmic goat (the UFO's most dangerous experiment)
--------------------------------------------------------------------------------
Templates.VOID_GOAT = {
	ID = "VOID_GOAT",
	Name = "Voidgoat",
	BodyBlocks = {
		-- Ethereal void body (phases in and out)
		{ Size = Vector3.new(2.2, 2.0, 3.2), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.ForceField, Transparency = 0.3 },
		-- Visible shadow core
		{ Size = Vector3.new(1.8, 1.6, 2.6), Offset = Vector3.new(0, 0, 0), Color = Color3.fromRGB(20, 10, 30), Material = Enum.Material.SmoothPlastic },
		-- Void particles (floating around body)
		{ Size = Vector3.new(0.3, 0.3, 0.3), Offset = Vector3.new(-1.6, 0.5, -0.5), Color = Color3.fromRGB(80, 0, 120), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.25, 0.25, 0.25), Offset = Vector3.new(1.7, 0.8, 0.3), Color = Color3.fromRGB(100, 20, 150), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.2, 0.2, 0.2), Offset = Vector3.new(-0.8, 1.5, 0.6), Color = Color3.fromRGB(60, 0, 100), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(0.5, 1.7, -0.3), Color = Color3.fromRGB(120, 30, 180), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.22, 0.22, 0.22), Offset = Vector3.new(1.4, 1.2, 0.8), Color = Color3.fromRGB(90, 10, 140), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.28, 0.28, 0.28), Offset = Vector3.new(-1.5, 1.0, 1.0), Color = Color3.fromRGB(70, 0, 110), Material = Enum.Material.Neon },
		-- Void rifts (cracks in reality)
		{ Size = Vector3.new(0.05, 0.8, 0.05), Offset = Vector3.new(-0.9, 0.8, 0), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.05, 0.6, 0.05), Offset = Vector3.new(0.7, 0.9, 0.5), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.05, 0.7, 0.05), Offset = Vector3.new(0.3, 1.0, -0.6), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.Neon },
		-- Phasing underbelly
		{ Size = Vector3.new(1.6, 0.6, 2.0), Offset = Vector3.new(0, -0.9, 0), Material = Enum.Material.ForceField, Transparency = 0.5 },
	},
	HeadBlocks = {
		-- Void-touched head
		{ Size = Vector3.new(1.1, 1.1, 1.3), Offset = Vector3.new(0, 0.6, -2.1), Material = Enum.Material.ForceField, Transparency = 0.2 },
		{ Size = Vector3.new(0.9, 0.9, 1.1), Offset = Vector3.new(0, 0.6, -2.1), Color = Color3.fromRGB(20, 10, 30), Material = Enum.Material.SmoothPlastic },
		-- Snout
		{ Size = Vector3.new(0.6, 0.5, 0.5), Offset = Vector3.new(0, 0.3, -2.7), Color = Color3.fromRGB(30, 15, 40), Material = Enum.Material.SmoothPlastic },
		-- Void nose
		{ Size = Vector3.new(0.3, 0.25, 0.15), Offset = Vector3.new(0, 0.3, -3.0), Color = Color3.fromRGB(100, 50, 150), Material = Enum.Material.Neon },
		-- STARFIELD EYES (windows to the cosmos)
		{ Size = Vector3.new(0.35, 0.4, 0.2), Offset = Vector3.new(-0.35, 0.75, -2.55), Color = Color3.fromRGB(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.35, 0.4, 0.2), Offset = Vector3.new(0.35, 0.75, -2.55), Color = Color3.fromRGB(0, 0, 0), Material = Enum.Material.SmoothPlastic },
		-- Stars in eyes
		{ Size = Vector3.new(0.08, 0.08, 0.05), Offset = Vector3.new(-0.4, 0.85, -2.6), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.05, 0.05, 0.03), Offset = Vector3.new(-0.3, 0.7, -2.6), Color = Color3.fromRGB(255, 255, 200), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.06, 0.06, 0.03), Offset = Vector3.new(-0.38, 0.68, -2.6), Color = Color3.fromRGB(200, 200, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.08, 0.08, 0.05), Offset = Vector3.new(0.3, 0.8, -2.6), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.05, 0.05, 0.03), Offset = Vector3.new(0.4, 0.72, -2.6), Color = Color3.fromRGB(255, 200, 255), Material = Enum.Material.Neon },
		{ Size = Vector3.new(0.06, 0.06, 0.03), Offset = Vector3.new(0.32, 0.88, -2.6), Color = Color3.fromRGB(200, 255, 255), Material = Enum.Material.Neon },
		-- REALITY-BENDING HORNS (warped, twisted)
		{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(-0.45, 1.2, -1.9), Color = Color3.fromRGB(40, 20, 60) },
		{ Size = Vector3.new(0.18, 0.5, 0.25), Offset = Vector3.new(-0.55, 1.6, -1.7), Color = Color3.fromRGB(50, 25, 70) },
		{ Size = Vector3.new(0.15, 0.4, 0.3), Offset = Vector3.new(-0.7, 1.9, -1.4), Color = Color3.fromRGB(60, 30, 80) },
		{ Size = Vector3.new(0.12, 0.3, 0.25), Offset = Vector3.new(-0.85, 2.1, -1.1), Color = Color3.fromRGB(70, 35, 90) },
		-- Horn void glow
		{ Size = Vector3.new(0.1, 0.2, 0.15), Offset = Vector3.new(-0.9, 2.3, -0.9), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.Neon },
		-- Right horn (mirrored and twisted opposite direction)
		{ Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(0.45, 1.2, -1.9), Color = Color3.fromRGB(40, 20, 60) },
		{ Size = Vector3.new(0.18, 0.5, 0.25), Offset = Vector3.new(0.55, 1.6, -1.7), Color = Color3.fromRGB(50, 25, 70) },
		{ Size = Vector3.new(0.15, 0.4, 0.3), Offset = Vector3.new(0.7, 1.9, -1.4), Color = Color3.fromRGB(60, 30, 80) },
		{ Size = Vector3.new(0.12, 0.3, 0.25), Offset = Vector3.new(0.85, 2.1, -1.1), Color = Color3.fromRGB(70, 35, 90) },
		-- Horn void glow
		{ Size = Vector3.new(0.1, 0.2, 0.15), Offset = Vector3.new(0.9, 2.3, -0.9), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.Neon },
		-- Void beard (dripping reality)
		{ Size = Vector3.new(0.25, 0.5, 0.2), Offset = Vector3.new(0, 0.0, -2.6), Material = Enum.Material.ForceField, Transparency = 0.4 },
		{ Size = Vector3.new(0.2, 0.3, 0.15), Offset = Vector3.new(0, -0.3, -2.5), Color = Color3.fromRGB(80, 0, 120), Material = Enum.Material.Neon, Transparency = 0.5 },
		-- Floppy void ears
		{ Size = Vector3.new(0.15, 0.35, 0.5), Offset = Vector3.new(-0.6, 0.7, -1.85), Material = Enum.Material.ForceField, Transparency = 0.3 },
		{ Size = Vector3.new(0.15, 0.35, 0.5), Offset = Vector3.new(0.6, 0.7, -1.85), Material = Enum.Material.ForceField, Transparency = 0.3 },
	},
	TailBlocks = {
		-- Void tail (dissipating into nothing)
		{ Size = Vector3.new(0.25, 0.25, 0.5), Offset = Vector3.new(0, 0.5, 1.8), Color = Color3.fromRGB(30, 15, 45), Material = Enum.Material.SmoothPlastic },
		{ Size = Vector3.new(0.2, 0.2, 0.4), Offset = Vector3.new(0, 0.55, 2.2), Material = Enum.Material.ForceField, Transparency = 0.3 },
		{ Size = Vector3.new(0.15, 0.15, 0.3), Offset = Vector3.new(0, 0.6, 2.5), Material = Enum.Material.ForceField, Transparency = 0.5 },
		{ Size = Vector3.new(0.1, 0.1, 0.2), Offset = Vector3.new(0, 0.65, 2.7), Material = Enum.Material.ForceField, Transparency = 0.7 },
	},
	Legs = {
		Blocks = {
			-- Phasing ethereal legs
			{ Size = Vector3.new(0.4, 1.4, 0.4), Offset = Vector3.new(0, 0, 0), Material = Enum.Material.ForceField, Transparency = 0.2 },
			-- Inner leg core
			{ Size = Vector3.new(0.3, 1.2, 0.3), Offset = Vector3.new(0, 0, 0), Color = Color3.fromRGB(20, 10, 30), Material = Enum.Material.SmoothPlastic },
			-- Void hooves
			{ Size = Vector3.new(0.45, 0.25, 0.5), Offset = Vector3.new(0, -0.7, 0), Color = Color3.fromRGB(80, 0, 120), Material = Enum.Material.Neon },
			-- Ground corruption (where it steps)
			{ Size = Vector3.new(0.6, 0.1, 0.6), Offset = Vector3.new(0, -0.85, 0), Color = Color3.fromRGB(50, 0, 80), Material = Enum.Material.Neon, Transparency = 0.5 },
		},
		OffsetFL = Vector3.new(0.7, -1.4, -1.2),
		PivotY = 0.7,
	},
}

-- Get template by ID
function AnimalTemplates.GetTemplate(templateID: string): TemplateConfig?
	return Templates[templateID] or Templates.DEFAULT
end

-- Get all template IDs
function AnimalTemplates.GetAllTemplateIDs(): { string }
	return { "DEFAULT", "FLUFFY", "SLIME", "BEETLE", "BUNNY", "PIG", "TURTLE", "CRAB", "COW", "CHICKEN", "GOAT", "DUCK", "FROG", "HEDGEHOG", "MOUSE", "PENGUIN", "RACCOON", "SNAIL", "SQUIRREL", "ZORB_SHEEP", "CHROMA_CHICK", "GRAVI_TOAD", "PORKULON", "BUNNOCTOPUS", "DUCKZILLA", "MOOSETRONAUT", "HEDGEBORG", "SNAILSTORM", "VOID_GOAT" }
end

--------------------------------------------------------------------------------
-- EXPORT FUNCTIONS - Generate OBJ format for Blender import
--------------------------------------------------------------------------------

-- Export a single template to OBJ format string
function AnimalTemplates.ExportToOBJ(templateID: string): string
	local template = Templates[templateID]
	if not template then
		return "# Error: Template not found"
	end
	
	local lines = {}
	table.insert(lines, "# Animal Template: " .. template.Name)
	table.insert(lines, "# Exported from AnimalTemplates.luau")
	table.insert(lines, "# Import into Blender: File > Import > Wavefront (.obj)")
	table.insert(lines, "")
	
	local vertexIndex = 1
	
	-- Helper to add a cube (8 vertices, 6 faces)
	local function addCube(name: string, size: Vector3, offset: Vector3)
		table.insert(lines, "o " .. name)
		
		local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
		local cx, cy, cz = offset.X, offset.Y, offset.Z
		
		-- 8 vertices of the cube
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy - hy, cz - hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy - hy, cz - hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy + hy, cz - hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy + hy, cz - hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy - hy, cz + hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy - hy, cz + hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy + hy, cz + hz))
		table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy + hy, cz + hz))
		
		-- 6 faces (quads)
		local v = vertexIndex
		table.insert(lines, string.format("f %d %d %d %d", v+0, v+1, v+2, v+3))  -- front
		table.insert(lines, string.format("f %d %d %d %d", v+5, v+4, v+7, v+6))  -- back
		table.insert(lines, string.format("f %d %d %d %d", v+4, v+0, v+3, v+7))  -- left
		table.insert(lines, string.format("f %d %d %d %d", v+1, v+5, v+6, v+2))  -- right
		table.insert(lines, string.format("f %d %d %d %d", v+3, v+2, v+6, v+7))  -- top
		table.insert(lines, string.format("f %d %d %d %d", v+4, v+5, v+1, v+0))  -- bottom
		
		table.insert(lines, "")
		vertexIndex = vertexIndex + 8
	end
	
	-- Export body blocks
	for i, block in template.BodyBlocks do
		addCube("Body_" .. i, block.Size, block.Offset)
	end
	
	-- Export head blocks
	if template.HeadBlocks then
		for i, block in template.HeadBlocks do
			addCube("Head_" .. i, block.Size, block.Offset)
		end
	end
	
	-- Export tail blocks
	if template.TailBlocks then
		for i, block in template.TailBlocks do
			addCube("Tail_" .. i, block.Size, block.Offset)
		end
	end
	
	-- Export decoration blocks
	if template.DecorationBlocks then
		for i, block in template.DecorationBlocks do
			addCube("Deco_" .. i, block.Size, block.Offset)
		end
	end
	
	-- Export legs (all 4)
	local legConfig = template.Legs
	local ofl = legConfig.OffsetFL
	
	for i, block in legConfig.Blocks do
		addCube("LegFL_" .. i, block.Size, ofl + block.Offset)
		addCube("LegFR_" .. i, block.Size, Vector3.new(-ofl.X, ofl.Y, ofl.Z) + block.Offset)
		addCube("LegBL_" .. i, block.Size, Vector3.new(ofl.X, ofl.Y, -ofl.Z) + block.Offset)
		addCube("LegBR_" .. i, block.Size, Vector3.new(-ofl.X, ofl.Y, -ofl.Z) + block.Offset)
	end
	
	return table.concat(lines, "\n")
end

-- Export all templates to a table of OBJ strings
function AnimalTemplates.ExportAllToOBJ(): { [string]: string }
	local exports = {}
	for _, id in AnimalTemplates.GetAllTemplateIDs() do
		exports[id] = AnimalTemplates.ExportToOBJ(id)
	end
	return exports
end

return AnimalTemplates
