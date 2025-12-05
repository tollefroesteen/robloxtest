# Procedural Environment System - Development Plan

## Overview

A seeded procedural generation system for creating animal herding landscapes in Roblox. The system generates grassy plains suitable for herding animals, surrounded by rocky mountain barriers that naturally contain the animals within the play area.

---

## Game Area Specification

```
        Z-axis (350 units)
    ←─────────────────────────→
    
    ┌─────────────────────────┐  ↑
    │ ░░░ MOUNTAINS ░░░░░░░░░ │  │
    │ ░┌───────────────────┐░ │  │
    │ ░│                   │░ │  │
    │ ░│   GRASSY PLAINS   │░ │  X-axis
    │ ░│    (Play Area)    │░ │  (280 units)
    │ ░│      Origin       │░ │  │
    │ ░│        ●          │░ │  │
    │ ░│                   │░ │  │
    │ ░└───────────────────┘░ │  │
    │ ░░░░░░░░░░░░░░░░░░░░░░░ │  ↓
    └─────────────────────────┘
    
    Inner Box (Play Area): -175 to +175 Z, -140 to +140 X
    Transition Zone: ~30-50 units (grass → rocky hills)
    Outer Mountains: Natural barrier, impassable terrain
```

### Terrain Zones

| Zone | Description | Terrain Type |
|------|-------------|--------------|
| **Play Area** | Flat to gently rolling grassland | Grass, occasional dirt patches |
| **Transition** | Gradual slope increase, grass to rock | Mixed grass/rock, steeper |
| **Mountains** | Steep rocky barriers | Rock, snow peaks, impassable |

---

## Architecture

```
places/arena/src/
  server/
    ProceduralEnvironment/
      SeedManager.luau              -- Core seeding & RNG
      TerrainGenerator.luau         -- Terrain heightmap & materials
      FoliageGenerator.luau         -- Grass, trees, bushes, rocks
      EnvironmentOrchestrator.luau  -- Coordinates all generators
  shared/
    config/
      ProceduralConfig.luau         -- Generation parameters & zone definitions
```

---

## Incremental Development Plan

### Phase 1: Foundation - Seed Manager
**Goal:** Deterministic random number generation

**Module:** `SeedManager.luau`

Features:
- Convert string/number seeds to consistent numeric seed
- Seeded RNG functions:
  - `NextNumber(min, max)` - Float in range
  - `NextInteger(min, max)` - Integer in range
  - `NextVector2()` - Random unit vector
  - `NextVector3()` - Random unit vector
- 2D Perlin noise with seed offset
- Sub-seed generation (terrain, foliage get different but deterministic seeds)

```lua
-- Example API
local SeedManager = require(SeedManager)
local rng = SeedManager.Create("MyWorld123")

local height = rng:Noise2D(x, z, scale, octaves)
local value = rng:NextNumber(0, 1)
local terrainRng = rng:SubSeed("terrain")
```

**Deliverable:** Identical random sequences for identical seeds.

---

### Phase 2: Configuration
**Goal:** Define world parameters and zone boundaries

**Module:** `ProceduralConfig.luau`

```lua
return {
    -- World bounds
    WorldSize = Vector3.new(500, 200, 450),  -- Total generation area
    
    -- Play area (centered on origin)
    PlayArea = {
        SizeX = 280,
        SizeZ = 350,
        -- Bounds: X = -140 to +140, Z = -175 to +175
    },
    
    -- Transition zone
    Transition = {
        Width = 40,  -- How wide the grass-to-mountain transition is
    },
    
    -- Terrain settings
    Terrain = {
        -- Play area: gentle rolling hills
        PlayAreaMaxHeight = 8,      -- Max height variation in play area
        PlayAreaSmoothness = 0.8,   -- Higher = smoother terrain
        
        -- Mountains: steep rocky barriers
        MountainMinHeight = 30,
        MountainMaxHeight = 80,
        MountainRoughness = 0.6,
    },
    
    -- Foliage density (items per 100 square units)
    Foliage = {
        GrassClumps = 15,
        Bushes = 2,
        Trees = 0.5,
        Rocks = 1,  -- Play area rocks (decorative)
        MountainRocks = 5,  -- Transition/mountain rocks
    },
    
    -- Generation
    ChunkSize = 32,
    Resolution = 4,  -- Terrain voxels per unit
}
```

**Deliverable:** Central configuration for all generation parameters.

---

### Phase 3: Terrain Generator
**Goal:** Generate heightmap terrain with zone-based rules

**Module:** `TerrainGenerator.luau`

**Zone Logic:**
```
Distance from center → Zone determination:

d = max(|x|/140, |z|/175)  -- Normalized distance (1.0 = edge of play area)

if d < 1.0:
    PLAY_AREA - Gentle grass hills
elif d < 1.0 + transitionNorm:
    TRANSITION - Blend from grass to mountains  
else:
    MOUNTAINS - Rocky barriers
```

**Height Calculation:**
- **Play Area:** Low-amplitude Perlin noise (gentle hills)
- **Transition:** Lerp between play area and mountain heights
- **Mountains:** High-amplitude noise + base height increase with distance

**Material Assignment:**
| Zone | Primary | Secondary | Based On |
|------|---------|-----------|----------|
| Play Area | Grass | Ground/Mud | Low areas, paths |
| Transition | Grass → Rock | Ground | Height blend |
| Mountains | Rock | Snow | Height threshold |

**Features:**
- Chunk-based generation for performance
- Roblox Terrain API (FillBlock, WriteVoxels)
- Water plane at Y=0 (optional ponds in play area)

**Deliverable:** Grassy plains surrounded by impassable mountains.

---

### Phase 4: Foliage Generator
**Goal:** Populate terrain with vegetation and rocks

**Module:** `FoliageGenerator.luau`

**Foliage Types:**

| Type | Zone | Description |
|------|------|-------------|
| Grass Clumps | Play Area | Tall grass patches |
| Bushes | Play Area | Small shrubs |
| Trees | Play Area edges | Scattered trees (not blocking gameplay) |
| Small Rocks | Play Area | Decorative boulders |
| Large Rocks | Transition | Increasing density toward mountains |
| Boulders | Mountains | Large impassable rocks |

**Placement Algorithm:**
1. Poisson disk sampling for natural distribution
2. Query terrain height at each point
3. Filter by slope (no trees on steep slopes)
4. Zone check (right foliage for right zone)
5. Spawn model/part at position + rotation

**Foliage Models:**
- Can use simple Part-based procedural models initially
- Replace with actual models later (from ReplicatedStorage)

```lua
-- Example: Procedural tree
local function createSimpleTree(position, rng)
    local trunk = Instance.new("Part")
    trunk.Size = Vector3.new(2, rng:NextNumber(8, 12), 2)
    trunk.Color = Color3.fromRGB(101, 67, 33)
    -- ... leaves as sphere/parts
end
```

**Deliverable:** Natural-looking vegetation distribution.

---

### Phase 5: Environment Orchestrator
**Goal:** Single entry point for world generation

**Module:** `EnvironmentOrchestrator.luau`

```lua
local EnvironmentOrchestrator = {}

function EnvironmentOrchestrator.Generate(seed: string | number, options: GenerateOptions?)
    local config = require(ProceduralConfig)
    local rng = SeedManager.Create(seed)
    
    -- Clear existing
    EnvironmentOrchestrator.Clear()
    
    -- Generate in order
    TerrainGenerator.Generate(rng:SubSeed("terrain"), config)
    FoliageGenerator.Generate(rng:SubSeed("foliage"), config)
    
    return {
        seed = seed,
        bounds = { ... }
    }
end

function EnvironmentOrchestrator.Clear()
    -- Remove generated terrain and foliage
    workspace.Terrain:Clear()
    -- Clear foliage folder
end

function EnvironmentOrchestrator.GetSeed(): string | number
    return currentSeed
end

return EnvironmentOrchestrator
```

**Usage:**
```lua
-- In arena server script
local Environment = require(EnvironmentOrchestrator)

-- Generate with specific seed
Environment.Generate("Arena_Season1_Map3")

-- Or random seed
Environment.Generate(os.time())
```

**Deliverable:** Complete world generation with one function call.

---

## Implementation Order

| Step | Task | Module | Effort |
|------|------|--------|--------|
| 1 | Create folder structure | - | 5 min |
| 2 | Seed Manager with RNG + noise | SeedManager | 1-2 hrs |
| 3 | Configuration file | ProceduralConfig | 30 min |
| 4 | Basic heightmap terrain | TerrainGenerator | 2-3 hrs |
| 5 | Zone-based materials | TerrainGenerator | 1 hr |
| 6 | Mountain barriers | TerrainGenerator | 1 hr |
| 7 | Basic foliage spawning | FoliageGenerator | 2 hrs |
| 8 | Zone-appropriate foliage | FoliageGenerator | 1 hr |
| 9 | Orchestrator integration | EnvironmentOrchestrator | 1 hr |
| 10 | Testing & tuning | All | 2+ hrs |

**Total Estimate:** 12-15 hours

---

## Future Enhancements

- **Paths/Trails:** Dirt paths through the grass for visual interest
- **Water Features:** Small ponds or streams in play area
- **Weather Integration:** Seed-based weather patterns
- **Dynamic Regeneration:** Regenerate specific chunks
- **Arena Variants:** Different biome presets (savanna, tundra, etc.)
- **Performance LOD:** Reduce foliage detail at distance

---

## Testing Seeds

Reserve these seeds for testing consistency:
- `"test_flat"` - Minimal height variation for debugging
- `"test_hilly"` - Maximum play area variation
- `"test_dense"` - High foliage density
- `"arena_default"` - Production default

---

**Ready to begin with Phase 1 (SeedManager)?**
