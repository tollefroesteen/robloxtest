# Mountain Configuration Commands

This document explains how to use the `/mountain` admin commands to customize the alpine mountain terrain surrounding the play area.

## Quick Reference

| Command | Range | Default | Description |
|---------|-------|---------|-------------|
| `/mountain height <value>` | 0 - 5.0 | 1.5 | Overall mountain height multiplier |
| `/mountain peaks <value>` | 0 - 5.0 | 1.2 | Peak density (peaks per 10k sq units) |
| `/mountain pheight <min> <max>` | min ≥ 0 | 50, 300 | Individual peak height range (studs) |
| `/mountain pradius <min> <max>` | min ≥ 5 | 50, 120 | Peak base radius range (studs) |
| `/mountain steep <value>` | 0 - 3.0 | 1.5 | Peak steepness |
| `/mountain ridge <height> <sharp>` | height: 0-500, sharp: 0-3.0 | 100, 1.5 | Ridge line settings |
| `/mountain ridges on\|off` | - | on | Enable/disable ridge generation |
| `/mountain snow <height> [blend]` | height ≥ 20, blend: 2-30 | 60, 10 | Snow line settings |
| `/mountain rough <value>` | 0 - 3.0 | 1.2 | Surface roughness/texture |
| `/mountain on\|off` | - | on | Enable/disable mountains entirely |

> **Important:** After changing any setting, use `/regen` to regenerate the terrain and see the changes.
> 
> **Tip:** Start with values at 0 to see a flat baseline, then increase incrementally to understand each parameter's effect.

---

## Detailed Command Reference

### `/mountain`
Shows all current mountain configuration values.

---

### `/mountain height <0-5.0>`
**Controls:** Overall mountain elevation multiplier.

| Value | Effect |
|-------|--------|
| 0 | **Flat baseline** - no mountain rise at all (useful for testing) |
| 0.5 | Low, rolling foothills - barely rises above play area |
| 1.0 | Standard mountain height |
| 1.5 | **Default** - Moderately tall mountains |
| 2.0 | Tall, imposing mountains |
| 3.0+ | Very dramatic, towering peaks |

**Clamped to:** 0 - 5.0

**Example:**
```
/mountain height 2.5
/regen
```

---

### `/mountain peaks <0-5.0>`
**Controls:** How many distinct mountain peaks are generated.

| Value | Effect |
|-------|--------|
| 0 | **No peaks** - only base terrain and ridges |
| 0.5 | Few scattered peaks - more open mountain range |
| 1.0 | Moderate peak count |
| 1.2 | **Default** - Natural looking distribution |
| 2.0 | Many peaks - dense mountain range |
| 3.0+ | Very dense, crowded peaks |

**Clamped to:** 0 - 5.0

**Note:** Peak density is calculated as "peaks per 10,000 square studs" of mountain zone.

---

### `/mountain pheight <min> <max>`
**Controls:** The height range of individual peaks (in studs).

| Values | Effect |
|--------|--------|
| 0, 0 | **No peak height** - peaks are flat bumps |
| 10, 30 | Small bumps on the mountains |
| 50, 300 | **Default** - Wide variety from small to tall peaks |
| 100, 500 | All peaks are tall and dramatic |
| 200, 200 | All peaks roughly the same height |

**Constraints:**
- min can be 0 or higher
- max must be at least equal to min

**Example:**
```
/mountain pheight 100 400
/regen
```

---

### `/mountain pradius <min> <max>`
**Controls:** The base size (footprint) of peaks in studs.

| Values | Effect |
|--------|--------|
| 10, 30 | Thin, needle-like peaks |
| 50, 120 | **Default** - Natural mountain proportions |
| 80, 200 | Wide, massive mountain bases |

**Constraints:**
- min must be ≥ 5
- max must be at least min + 5

**Tip:** Larger radius with higher height = more realistic mountains. Small radius with high height = sharp spires.

---

### `/mountain steep <0-3.0>`
**Controls:** How sharply peaks rise from their base.

| Value | Effect |
|-------|--------|
| 0 | **Flat** - peaks don't rise at all (useful for testing) |
| 0.5 | Very gradual slopes - more like large hills |
| 1.0 | Natural, moderate slopes |
| 1.5 | **Default** - Noticeable steepness |
| 2.0 | Sharp, dramatic cliff-like slopes |
| 2.5+ | Extremely steep, almost vertical near peaks |

**Clamped to:** 0 - 3.0

---

### `/mountain ridge <height> <sharpness>`
**Controls:** Ridge lines that connect and enhance peaks.

**Height** (0-500):
| Value | Effect |
|-------|--------|
| 0 | **No ridges** - flat between peaks |
| 10 | Subtle ridges, barely visible |
| 50 | Noticeable ridge lines |
| 100 | **Default** - Prominent ridges |
| 150+ | Dramatic, sharp ridge crests |
| 300+ | Very tall ridge lines |

**Sharpness** (0-3.0):
| Value | Effect |
|-------|--------|
| 0 | **Flat ridges** - no ridge shape |
| 0.5 | Rounded, soft ridges |
| 1.0 | Natural ridge shape |
| 1.5 | **Default** - Defined ridge lines |
| 2.0+ | Very sharp, knife-edge ridges |

**Example:**
```
/mountain ridge 150 2.0
/regen
```

---

### `/mountain ridges on|off`
**Controls:** Toggle ridge generation entirely.

- `on` - Ridges are generated (default)
- `off` - No ridges, only peaks and base terrain

**Example:**
```
/mountain ridges off
/regen
```

---

### `/mountain snow <height> [blend]`
**Controls:** Where snow appears on mountains.

**Height** (≥20): The elevation where snow starts appearing.
**Blend** (2-30, optional): How gradual the snow transition is.

| Height | Effect |
|--------|--------|
| 40 | Snow starts low - very snowy mountains |
| 60 | **Default** - Snow on upper peaks |
| 100 | Only the tallest peaks have snow |
| 150+ | Almost no snow visible |

| Blend | Effect |
|-------|--------|
| 2-5 | Sharp snow line |
| 10 | **Default** - Natural transition |
| 20-30 | Very gradual snow fade |

**Example:**
```
/mountain snow 50 15
/regen
```

---

### `/mountain rough <0-3.0>`
**Controls:** Surface texture and small-scale detail.

| Value | Effect |
|-------|--------|
| 0 | **Perfectly smooth** - no surface texture |
| 0.5 | Smooth mountain surfaces |
| 1.0 | Some surface variation |
| 1.2 | **Default** - Natural rocky texture |
| 2.0+ | Very rough, craggy surfaces |

**Clamped to:** 0 - 3.0

---

### `/mountain on` / `/mountain off`
**Controls:** Enable or disable mountain generation entirely.

When disabled, the mountain zone will be flat or minimal terrain.

---

## Command Bar Alternatives

For Studio command bar, you can use these `_G` functions:

```lua
_G.Mountain()                    -- Show current config
_G.SetMountainHeight(1.5)        -- Set height multiplier
_G.SetPeakDensity(1.2)           -- Set peak density
_G.SetPeakHeight(50, 300)        -- Set peak height range
_G.SetPeakRadius(50, 120)        -- Set peak radius range
_G.SetPeakSteepness(1.5)         -- Set peak steepness
_G.SetRidges(true, 100, 1.5)     -- Set ridges (enabled, height, sharpness)
_G.SetSnowLine(60, 10)           -- Set snow (height, blend)
_G.SetMountainRoughness(1.2)     -- Set surface roughness
_G.Terrain(1)                    -- Regenerate terrain with seed 1
```

---

## Example Configurations

### Flat Baseline (for testing)
Start with everything at 0 to understand each parameter:
```
/mountain height 0
/mountain peaks 0
/mountain ridge 0 0
/mountain rough 0
/regen
```
Then incrementally add one feature at a time:
```
/mountain height 1
/regen
-- See just base height

/mountain peaks 1
/regen
-- Now add some peaks

/mountain ridge 50 1
/regen
-- Now add ridges
```

### Low Rolling Foothills
```
/mountain height 0.5
/mountain peaks 0.8
/mountain pheight 10 40
/mountain ridges off
/regen
```

### Dramatic Alpine Peaks
```
/mountain height 3.0
/mountain peaks 1.5
/mountain pheight 100 500
/mountain steep 2.0
/mountain ridge 150 2.0
/mountain snow 80 5
/regen
```

### Dense Mountain Range
```
/mountain height 2.0
/mountain peaks 3.0
/mountain pradius 30 80
/mountain pheight 50 200
/regen
```

### Smooth Snow-Capped Mountains
```
/mountain height 2.0
/mountain rough 0.5
/mountain steep 1.0
/mountain snow 40 20
/mountain ridge 50 0.8
/regen
```

---

## Tips

1. **Start with height** - Get the overall scale right first
2. **Adjust peaks second** - Density and individual peak settings shape the silhouette
3. **Fine-tune with ridges** - Ridges add realism and connect peaks
4. **Snow last** - Adjust snow line once you're happy with the shape
5. **Use /regen liberally** - It's fast, experiment freely!

## Current Default Values (MOUNTAIN_CONFIG)

These are set in `TestProceduralEnvironment.server.luau`:

```lua
MOUNTAIN_CONFIG = {
    Enabled = true,
    BaseRiseMultiplier = 1.5,
    PeakDensity = 1.2,
    PeakMinRadius = 50,
    PeakMaxRadius = 120,
    PeakMinHeight = 50,
    PeakMaxHeight = 300,
    PeakSteepness = 1.5,
    RidgeEnabled = true,
    RidgeNoiseScale = 25,
    RidgeHeight = 100,
    RidgeSharpness = 1.5,
    Roughness = 1.2,
    SnowHeight = 60,
    SnowBlend = 10,
}
```

To change defaults permanently, edit `MOUNTAIN_CONFIG` in the test script.
