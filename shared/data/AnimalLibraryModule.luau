-- ModuleScript: AnimalLibraryModule
-- AnimalLibraryModule.luau
-- Defines all animal types with their stats, appearance, templates, and descriptions
-- This module is shared between client and server

local AnimalLibrary = {}

-- Template IDs from AnimalTemplates.luau:
-- DEFAULT - Original simple sheep
-- FLUFFY - Woolly sheep with multiple fluffy blocks
-- SLIME - Bouncy blob creature
-- BEETLE - Hard-shell insect
-- BUNNY - Cute hopping rabbit
-- PIG - Chubby pink pig
-- TURTLE - Slow shelled creature
-- CRAB - Wide sideways crab
-- COW - Sturdy farm cow
-- CHICKEN - Fluffy farm bird
-- GOAT - Mountain climber with horns
-- DUCK - Waddling water bird
-- FROG - Hoppy amphibian
-- HEDGEHOG - Spiky ball creature
-- MOUSE - Tiny quick rodent
-- PENGUIN - Waddling arctic bird
-- RACCOON - Masked mischief maker
-- SNAIL - Slow spiral shell
-- SQUIRREL - Bushy-tailed nut collector
--
-- === UFO EXPERIMENTAL ANIMALS ===
-- ZORB_SHEEP - Glowing cosmic sheep
-- CHROMA_CHICK - Color-shifting alien chicken
-- GRAVI_TOAD - Gravity-defying mega frog
-- PORKULON - Cyber-pig with antennae
-- BUNNOCTOPUS - Tentacled rabbit hybrid
-- DUCKZILLA - Giant mutant duck
-- MOOSETRONAUT - Space cow with rocket legs
-- HEDGEBORG - Cybernetic hedgehog
-- SNAILSTORM - Lightning-fast electric snail
-- VOID_GOAT - Reality-bending cosmic goat

-- Define your animals with SpawnChance and unique ID
AnimalLibrary.List = {
	-- === COMMON ANIMALS (High spawn chance) ===
	{
		ID = "WS01",
		Name = "Woolsworth",
		Color = BrickColor.new("Institutional white"),
		Template = "FLUFFY",
		Description = "A fluffy cloud of wool on legs. Woolsworth is the classic shepherd's companion - docile, easily spooked, and always looking for the nearest patch of grass.",
		PointValue = 1,
		MaxSpeed = 0.35,
		Hungriness = 0.6,
		FearFactor = 0.9,
		ObservationRadius = 25,
		SpawnChance = 50
	},
	{
		ID = "CK01",
		Name = "Cluckbert",
		Color = BrickColor.new("Bright orange"),
		Template = "CHICKEN",
		Description = "A plucky farm chicken with attitude. Cluckbert struts around like they own the place and will peck at anything shiny.",
		PointValue = 1,
		MaxSpeed = 0.45,
		Hungriness = 0.8,
		FearFactor = 0.7,
		ObservationRadius = 20,
		SpawnChance = 40
	},
	{
		ID = "DK01",
		Name = "Quackston",
		Color = BrickColor.new("Bright yellow"),
		Template = "DUCK",
		Description = "A cheerful waddling duck who quacks at everything. Quackston prefers puddles but will follow anyone with bread.",
		PointValue = 1,
		MaxSpeed = 0.38,
		Hungriness = 0.7,
		FearFactor = 0.6,
		ObservationRadius = 22,
		SpawnChance = 35
	},
	{
		ID = "PG01",
		Name = "Hamlet",
		Color = BrickColor.new("Light reddish violet"),
		Template = "PIG",
		Description = "A round pink piggy with an insatiable appetite. Hamlet will eat anything that isn't nailed down and some things that are.",
		PointValue = 2,
		MaxSpeed = 0.32,
		Hungriness = 0.95,
		FearFactor = 0.5,
		ObservationRadius = 30,
		SpawnChance = 30
	},
	{
		ID = "BN01",
		Name = "Flopsy",
		Color = BrickColor.new("Pastel brown"),
		Template = "BUNNY",
		Description = "An adorable rabbit with ears too big for its head. Flopsy is incredibly fast when startled but easily distracted by carrots.",
		PointValue = 2,
		MaxSpeed = 0.65,
		Hungriness = 0.75,
		FearFactor = 0.95,
		ObservationRadius = 35,
		SpawnChance = 25
	},
	
	-- === UNCOMMON ANIMALS (Medium spawn chance) ===
	{
		ID = "GT01",
		Name = "Gruffington",
		Color = BrickColor.new("Brick yellow"),
		Template = "GOAT",
		Description = "A stubborn mountain goat who refuses to go where you want. Gruffington will headbutt obstacles and occasionally shepherds.",
		PointValue = 3,
		MaxSpeed = 0.55,
		Hungriness = 0.4,
		FearFactor = 0.3,
		ObservationRadius = 40,
		SpawnChance = 18
	},
	{
		ID = "CW01",
		Name = "Bessie",
		Color = BrickColor.new("Institutional white"),
		Template = "COW",
		Description = "A large, slow-moving dairy cow. Bessie is calm and steady, rarely spooked, but takes forever to change direction.",
		PointValue = 3,
		MaxSpeed = 0.25,
		Hungriness = 0.5,
		FearFactor = 0.2,
		ObservationRadius = 35,
		SpawnChance = 15
	},
	{
		ID = "FR01",
		Name = "Ribberto",
		Color = BrickColor.new("Bright green"),
		Template = "FROG",
		Description = "A bouncy frog who moves in unpredictable hops. Ribberto can leap great distances and loves catching flies mid-air.",
		PointValue = 3,
		MaxSpeed = 0.7,
		Hungriness = 0.65,
		FearFactor = 0.6,
		ObservationRadius = 25,
		SpawnChance = 15
	},
	{
		ID = "MS01",
		Name = "Squeakers",
		Color = BrickColor.new("Medium stone grey"),
		Template = "MOUSE",
		Description = "A tiny mouse with lightning reflexes. Squeakers can fit through the smallest gaps and is nearly impossible to corner.",
		PointValue = 2,
		MaxSpeed = 0.8,
		Hungriness = 0.6,
		FearFactor = 0.99,
		ObservationRadius = 15,
		SpawnChance = 20
	},
	{
		ID = "SQ01",
		Name = "Nutkin",
		Color = BrickColor.new("Nougat"),
		Template = "SQUIRREL",
		Description = "A hyperactive squirrel with a magnificent fluffy tail. Nutkin hoards everything shiny and moves in erratic bursts.",
		PointValue = 3,
		MaxSpeed = 0.75,
		Hungriness = 0.7,
		FearFactor = 0.85,
		ObservationRadius = 30,
		SpawnChance = 12
	},
	{
		ID = "HH01",
		Name = "Prickles",
		Color = BrickColor.new("Medium stone grey"),
		Template = "HEDGEHOG",
		Description = "A defensive hedgehog who curls into a ball when scared. Prickles is slow but immune to being pushed when rolled up.",
		PointValue = 3,
		MaxSpeed = 0.3,
		Hungriness = 0.5,
		FearFactor = 0.4,
		ObservationRadius = 15,
		SpawnChance = 12
	},
	{
		ID = "RC01",
		Name = "Bandit",
		Color = BrickColor.new("Dark stone grey"),
		Template = "RACCOON",
		Description = "A mischievous raccoon with a signature mask. Bandit loves shiny objects and will steal items from other animals' pens.",
		PointValue = 4,
		MaxSpeed = 0.55,
		Hungriness = 0.8,
		FearFactor = 0.45,
		ObservationRadius = 40,
		SpawnChance = 10
	},
	{
		ID = "TT01",
		Name = "Shelldon",
		Color = BrickColor.new("Earth green"),
		Template = "TURTLE",
		Description = "An ancient turtle who has seen it all. Shelldon moves at a glacial pace but is worth the patience.",
		PointValue = 4,
		MaxSpeed = 0.15,
		Hungriness = 0.3,
		FearFactor = 0.1,
		ObservationRadius = 20,
		SpawnChance = 10
	},
	
	-- === RARE ANIMALS (Low spawn chance) ===
	{
		ID = "PN01",
		Name = "Waddles",
		Color = BrickColor.new("Black"),
		Template = "PENGUIN",
		Description = "A tuxedo-wearing penguin far from home. Waddles slides on their belly when in a hurry and prefers cold areas.",
		PointValue = 5,
		MaxSpeed = 0.45,
		Hungriness = 0.6,
		FearFactor = 0.5,
		ObservationRadius = 30,
		SpawnChance = 8
	},
	{
		ID = "CB01",
		Name = "Snippy",
		Color = BrickColor.new("Bright red"),
		Template = "CRAB",
		Description = "A feisty crab who walks sideways. Snippy has powerful claws and isn't afraid to use them on ankles.",
		PointValue = 5,
		MaxSpeed = 0.35,
		Hungriness = 0.4,
		FearFactor = 0.2,
		ObservationRadius = 20,
		SpawnChance = 6
	},
	{
		ID = "SN01",
		Name = "Escarglow",
		Color = BrickColor.new("Lavender"),
		Template = "SNAIL",
		Description = "A luminescent snail with a spiral shell. Escarglow leaves a glittery trail and moves at a hypnotically slow pace.",
		PointValue = 6,
		MaxSpeed = 0.1,
		Hungriness = 0.2,
		FearFactor = 0.05,
		ObservationRadius = 10,
		SpawnChance = 50
	},
	{
		ID = "BT01",
		Name = "Glimmer",
		Color = BrickColor.new("Bright yellow"),
		Template = "BEETLE",
		Description = "A shimmering golden beetle with an iridescent shell. Glimmer is fast and elusive, prized by collectors.",
		PointValue = 6,
		MaxSpeed = 0.85,
		Hungriness = 0.3,
		FearFactor = 0.95,
		ObservationRadius = 15,
		SpawnChance = 50
	},
	{
		ID = "SL01",
		Name = "Gloopy",
		Color = BrickColor.new("Lime green"),
		Template = "SLIME",
		Description = "A wobbly slime creature from the marshlands. Gloopy bounces unpredictably and can squeeze through fences.",
		PointValue = 5,
		MaxSpeed = 0.6,
		Hungriness = 0.85,
		FearFactor = 0.4,
		ObservationRadius = 35,
		SpawnChance = 50
	},
	
	-- === EXPERIMENTAL UFO ANIMALS (Alien-Hybrid Creatures) ===
	-- These bizarre creatures were beamed down from the mysterious UFO.
	-- They resemble Earth animals but something is... off.
	
	{
		ID = "XZ01",
		Name = "Zorbsheep",
		Color = BrickColor.new("Toothpaste"),
		Template = "ZORB_SHEEP",
		Description = "A sheep that absorbed cosmic radiation in the UFO. Zorbsheep floats slightly above ground, has translucent wool that glows at night, and baas in reverse. Scientists are baffled.",
		PointValue = 8,
		MaxSpeed = 0.4,
		Hungriness = 0.1,
		FearFactor = 0.3,
		ObservationRadius = 50,
		SpawnChance = 50
	},
	{
		ID = "XC01",
		Name = "Chromachick",
		Color = BrickColor.new("Hot pink"),
		Template = "CHROMA_CHICK",
		Description = "A chicken that phases through multiple color spectrums. Chromachick lays eggs that hatch into tiny rainbows. Its crow sounds like a dial-up modem connecting to the mothership.",
		PointValue = 7,
		MaxSpeed = 0.55,
		Hungriness = 0.3,
		FearFactor = 0.6,
		ObservationRadius = 25,
		SpawnChance = 50
	},
	{
		ID = "XG01",
		Name = "Gravitoad",
		Color = BrickColor.new("Royal purple"),
		Template = "GRAVI_TOAD",
		Description = "A frog that defies gravity. Gravitoad can hop upward indefinitely, has eyes that rotate independently in their sockets, and its tongue is 30 feet long. It catches birds instead of flies.",
		PointValue = 9,
		MaxSpeed = 0.9,
		Hungriness = 0.95,
		FearFactor = 0.2,
		ObservationRadius = 60,
		SpawnChance = 50
	},
	{
		ID = "XP01",
		Name = "Porkulon",
		Color = BrickColor.new("Neon orange"),
		Template = "PORKULON",
		Description = "A pig implanted with alien tech. Porkulon has antennae, metallic hooves, and oinks in morse code. It absorbs electricity and sometimes accidentally broadcasts alien radio signals.",
		PointValue = 8,
		MaxSpeed = 0.5,
		Hungriness = 0.99,
		FearFactor = 0.15,
		ObservationRadius = 45,
		SpawnChance = 50
	},
	{
		ID = "XB01",
		Name = "Bunnoctopus",
		Color = BrickColor.new("Pastel violet"),
		Template = "BUNNOCTOPUS",
		Description = "A bunny spliced with tentacles. Bunnoctopus has eight floppy ears that function as limbs, can climb walls, and leaves a trail of sparkly slime. Still loves carrots though.",
		PointValue = 10,
		MaxSpeed = 0.7,
		Hungriness = 0.8,
		FearFactor = 0.5,
		ObservationRadius = 40,
		SpawnChance = 50
	},
	{
		ID = "XD01",
		Name = "Duckzilla",
		Color = BrickColor.new("Really red"),
		Template = "DUCKZILLA",
		Description = "A duck grown to terrifying proportions by alien growth serum. Duckzilla has spikes down its back, breathes steam, and its quack creates shockwaves. Secretly just wants bread.",
		PointValue = 12,
		MaxSpeed = 0.3,
		Hungriness = 0.7,
		FearFactor = 0.0,
		ObservationRadius = 70,
		SpawnChance = 50
	},
	{
		ID = "XM01",
		Name = "Moosetronaut",
		Color = BrickColor.new("Sand blue"),
		Template = "MOOSETRONAUT",
		Description = "A cow that was the UFO's test pilot. Moosetronaut wears a cracked helmet, has rocket boosters for legs, and constantly mumbles about 'the stars'. Produces zero-gravity milk.",
		PointValue = 10,
		MaxSpeed = 0.65,
		Hungriness = 0.4,
		FearFactor = 0.25,
		ObservationRadius = 55,
		SpawnChance = 50
	},
	{
		ID = "XH01",
		Name = "Hedgeborg",
		Color = BrickColor.new("Silver"),
		Template = "HEDGEBORG",
		Description = "A hedgehog with cybernetic enhancements. Hedgeborg's spines are now metal antennae, it has a laser eye, and it compulsively organizes objects into perfect geometric patterns.",
		PointValue = 9,
		MaxSpeed = 0.45,
		Hungriness = 0.0,
		FearFactor = 0.1,
		ObservationRadius = 100,
		SpawnChance = 50
	},
	{
		ID = "XS01",
		Name = "Snailstorm",
		Color = BrickColor.new("Electric blue"),
		Template = "SNAILSTORM",
		Description = "A snail infused with lightning. Snailstorm is paradoxically the fastest creature in the game, leaving electrical trails and causing blackouts. Its shell spins like a turbine.",
		PointValue = 15,
		MaxSpeed = 1.0,
		Hungriness = 0.5,
		FearFactor = 0.8,
		ObservationRadius = 80,
		SpawnChance = 50
	},
	{
		ID = "XV01",
		Name = "Voidgoat",
		Color = BrickColor.new("Really black"),
		Template = "VOID_GOAT",
		Description = "A goat that gazed into the cosmic void. Voidgoat has stars in its eyes, phases through solid objects, and speaks in ominous prophecies. Its horns bend reality. The UFO's most dangerous experiment.",
		PointValue = 20,
		MaxSpeed = 0.6,
		Hungriness = 0.0,
		FearFactor = 0.0,
		ObservationRadius = 150,
		SpawnChance = 50
	},
}

-- Helper: get a random animal type using weighted probabilities
function AnimalLibrary.GetRandomType()
	local list = AnimalLibrary.List
	local totalWeight = 0

	for _, animalType in ipairs(list) do
		totalWeight += animalType.SpawnChance or 0
	end

	if totalWeight <= 0 then
		warn("No valid SpawnChance values found. Returning first animal.")
		return list[1]
	end

	local rand = math.random(1, totalWeight)
	local cumulative = 0

	for _, animalType in ipairs(list) do
		cumulative += animalType.SpawnChance or 0
		if rand <= cumulative then
			return animalType
		end
	end

	return list[#list]
end

-- Optional helper to get animal type by ID
function AnimalLibrary.GetByID(id)
	for _, animalType in ipairs(AnimalLibrary.List) do
		if animalType.ID == id then
			return animalType
		end
	end
	return nil
end

-- Helper: Get rarity based on spawn chance
function AnimalLibrary.GetRarity(spawnChance: number): string
	if spawnChance >= 25 then
		return "Common"
	elseif spawnChance >= 10 then
		return "Uncommon"
	elseif spawnChance >= 3 then
		return "Rare"
	else
		return "Legendary"
	end
end

-- Helper: Get total count of animals
function AnimalLibrary.GetTotalCount(): number
	return #AnimalLibrary.List
end

return AnimalLibrary
