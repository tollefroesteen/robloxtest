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

-- Get template by ID
function AnimalTemplates.GetTemplate(templateID: string): TemplateConfig?
	return Templates[templateID] or Templates.DEFAULT
end

-- Get all template IDs
function AnimalTemplates.GetAllTemplateIDs(): { string }
	return { "DEFAULT", "FLUFFY", "SLIME", "BEETLE", "BUNNY", "PIG", "TURTLE", "CRAB", "COW" }
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
