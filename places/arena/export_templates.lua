-- export_templates.lua
-- Standalone Lua script to export animal templates to OBJ files
-- 
-- Run with: lua export_templates.lua
-- Or with LuaJIT: luajit export_templates.lua
-- 
-- This will create .obj files in the current directory that can be
-- imported directly into Blender.

-- Vector3 polyfill for non-Roblox environments
local Vector3 = {}
Vector3.__index = Vector3

function Vector3.new(x, y, z)
    local self = setmetatable({}, Vector3)
    self.X = x or 0
    self.Y = y or 0
    self.Z = z or 0
    return self
end

function Vector3.__add(a, b)
    return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

-- Color3 polyfill
local Color3 = {}
function Color3.fromRGB(r, g, b)
    return { R = r/255, G = g/255, B = b/255 }
end

-- Enum polyfill
local Enum = {
    Material = {
        SmoothPlastic = "SmoothPlastic",
        Metal = "Metal",
        Neon = "Neon",
        Slate = "Slate",
    }
}

--------------------------------------------------------------------------------
-- TEMPLATE DEFINITIONS (copied from AnimalTemplates.luau)
--------------------------------------------------------------------------------

local Templates = {}

-- DEFAULT
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
        OffsetFL = Vector3.new(0.75, -1.75, -1.75),
        PivotY = 0.75,
    },
}

-- FLUFFY
Templates.FLUFFY = {
    ID = "FLUFFY",
    Name = "Fluffy Sheep",
    BodyBlocks = {
        { Size = Vector3.new(2.0, 1.8, 3.0), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(1.0, 0.8, 1.0), Offset = Vector3.new(-0.5, 1.0, -0.6) },
        { Size = Vector3.new(1.1, 0.9, 1.1), Offset = Vector3.new(0.4, 0.95, 0.0) },
        { Size = Vector3.new(0.9, 0.7, 0.9), Offset = Vector3.new(-0.3, 1.05, 0.7) },
        { Size = Vector3.new(1.0, 0.8, 0.8), Offset = Vector3.new(0.5, 0.9, 1.0) },
        { Size = Vector3.new(0.7, 0.9, 1.0), Offset = Vector3.new(-1.2, 0.2, -0.3) },
        { Size = Vector3.new(0.7, 0.8, 1.1), Offset = Vector3.new(1.2, 0.3, 0.0) },
        { Size = Vector3.new(0.6, 0.85, 0.9), Offset = Vector3.new(-1.15, 0.15, 0.8) },
        { Size = Vector3.new(0.65, 0.8, 0.85), Offset = Vector3.new(1.1, 0.25, 0.7) },
        { Size = Vector3.new(1.4, 1.2, 0.8), Offset = Vector3.new(0, 0.3, 1.5) },
        { Size = Vector3.new(0.8, 0.6, 0.5), Offset = Vector3.new(-0.4, 0.7, 1.7) },
        { Size = Vector3.new(0.8, 0.6, 0.5), Offset = Vector3.new(0.4, 0.7, 1.7) },
    },
    HeadBlocks = {
        { Size = Vector3.new(1.2, 1.1, 1.0), Offset = Vector3.new(0, 0.4, -1.9) },
        { Size = Vector3.new(0.5, 0.4, 0.35), Offset = Vector3.new(0, 0.05, -2.4) },
        { Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(0, 0.0, -2.6), Color = Color3.fromRGB(40, 30, 30) },
        { Size = Vector3.new(0.2, 0.5, 0.4), Offset = Vector3.new(-0.65, 0.5, -1.7) },
        { Size = Vector3.new(0.2, 0.5, 0.4), Offset = Vector3.new(0.65, 0.5, -1.7) },
        { Size = Vector3.new(0.8, 0.5, 0.4), Offset = Vector3.new(0, 0.85, -1.7) },
    },
    TailBlocks = {
        { Size = Vector3.new(0.5, 0.5, 0.45), Offset = Vector3.new(0, 0.5, 2.0) },
        { Size = Vector3.new(0.35, 0.4, 0.35), Offset = Vector3.new(0.15, 0.65, 2.1) },
        { Size = Vector3.new(0.35, 0.4, 0.35), Offset = Vector3.new(-0.15, 0.65, 2.1) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.35, 1.4, 0.35), Offset = Vector3.new(0, 0, 0) },
            { Size = Vector3.new(0.4, 0.25, 0.4), Offset = Vector3.new(0, -0.7, 0), Color = Color3.fromRGB(50, 40, 35) },
        },
        OffsetFL = Vector3.new(0.6, -1.5, -1.2),
        PivotY = 0.7,
    },
}

-- SLIME
Templates.SLIME = {
    ID = "SLIME",
    Name = "Slime",
    BodyBlocks = {
        { Size = Vector3.new(2.6, 1.6, 2.4), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(1.4, 1.0, 1.4), Offset = Vector3.new(0, -0.1, 0) },
        { Size = Vector3.new(1.2, 0.7, 1.2), Offset = Vector3.new(0, 0.9, 0) },
        { Size = Vector3.new(0.6, 0.4, 0.6), Offset = Vector3.new(0, 1.35, 0) },
        { Size = Vector3.new(0.5, 0.6, 0.7), Offset = Vector3.new(-1.1, 0.3, 0) },
        { Size = Vector3.new(0.5, 0.6, 0.7), Offset = Vector3.new(1.1, 0.3, 0) },
    },
    HeadBlocks = {
        { Size = Vector3.new(0.4, 0.5, 0.2), Offset = Vector3.new(-0.4, 0.5, -1.1), Color = Color3.fromRGB(255, 255, 255) },
        { Size = Vector3.new(0.4, 0.5, 0.2), Offset = Vector3.new(0.4, 0.5, -1.1), Color = Color3.fromRGB(255, 255, 255) },
        { Size = Vector3.new(0.2, 0.25, 0.1), Offset = Vector3.new(-0.4, 0.45, -1.2), Color = Color3.fromRGB(20, 20, 20) },
        { Size = Vector3.new(0.2, 0.25, 0.1), Offset = Vector3.new(0.4, 0.45, -1.2), Color = Color3.fromRGB(20, 20, 20) },
        { Size = Vector3.new(0.5, 0.15, 0.1), Offset = Vector3.new(0, -0.1, -1.15), Color = Color3.fromRGB(200, 100, 100) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.7, 0.5, 0.7), Offset = Vector3.new(0, 0, 0) },
        },
        OffsetFL = Vector3.new(0.7, -0.9, -0.7),
        PivotY = 0.25,
    },
}

-- BEETLE
Templates.BEETLE = {
    ID = "BEETLE",
    Name = "Beetle",
    BodyBlocks = {
        { Size = Vector3.new(2.4, 1.0, 3.2), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(2.0, 0.6, 2.6), Offset = Vector3.new(0, 0.65, 0.2) },
        { Size = Vector3.new(1.5, 0.45, 2.0), Offset = Vector3.new(0, 1.05, 0.2) },
        { Size = Vector3.new(0.9, 0.3, 1.3), Offset = Vector3.new(0, 1.35, 0.2) },
        { Size = Vector3.new(0.15, 0.25, 2.4), Offset = Vector3.new(0, 1.2, 0.2) },
        { Size = Vector3.new(0.05, 0.5, 2.0), Offset = Vector3.new(0, 0.85, 0.3), Color = Color3.fromRGB(30, 30, 30) },
    },
    HeadBlocks = {
        { Size = Vector3.new(1.1, 0.8, 0.9), Offset = Vector3.new(0, 0.0, -1.9) },
        { Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(-0.4, 0.35, -2.1), Color = Color3.fromRGB(200, 50, 50) },
        { Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0.4, 0.35, -2.1), Color = Color3.fromRGB(200, 50, 50) },
        { Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(-0.5, 0.45, -2.3), Color = Color3.fromRGB(255, 255, 255) },
        { Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(0.3, 0.45, -2.3), Color = Color3.fromRGB(255, 255, 255) },
        { Size = Vector3.new(0.08, 0.7, 0.08), Offset = Vector3.new(-0.25, 0.7, -1.8) },
        { Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(-0.25, 1.1, -1.8) },
        { Size = Vector3.new(0.08, 0.7, 0.08), Offset = Vector3.new(0.25, 0.7, -1.8) },
        { Size = Vector3.new(0.15, 0.15, 0.15), Offset = Vector3.new(0.25, 1.1, -1.8) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.15, 0.8, 0.15), Offset = Vector3.new(0, 0.2, 0) },
            { Size = Vector3.new(0.12, 0.5, 0.12), Offset = Vector3.new(0.05, -0.35, 0) },
        },
        OffsetFL = Vector3.new(1.0, -0.75, -1.1),
        PivotY = 0.55,
    },
}

-- BUNNY
Templates.BUNNY = {
    ID = "BUNNY",
    Name = "Bunny",
    BodyBlocks = {
        { Size = Vector3.new(1.8, 1.9, 2.2), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(1.2, 1.0, 0.6), Offset = Vector3.new(0, -0.2, -1.1) },
        { Size = Vector3.new(1.7, 1.6, 1.2), Offset = Vector3.new(0, 0.1, 1.0) },
        { Size = Vector3.new(1.3, 1.0, 0.7), Offset = Vector3.new(0, 0.6, 1.3) },
    },
    HeadBlocks = {
        { Size = Vector3.new(1.4, 1.3, 1.2), Offset = Vector3.new(0, 0.6, -1.7) },
        { Size = Vector3.new(0.55, 0.5, 0.4), Offset = Vector3.new(-0.55, 0.3, -2.0) },
        { Size = Vector3.new(0.55, 0.5, 0.4), Offset = Vector3.new(0.55, 0.3, -2.0) },
        { Size = Vector3.new(0.4, 0.3, 0.25), Offset = Vector3.new(0, 0.25, -2.35) },
        { Size = Vector3.new(0.2, 0.15, 0.1), Offset = Vector3.new(0, 0.3, -2.5), Color = Color3.fromRGB(255, 150, 180) },
        { Size = Vector3.new(0.3, 1.6, 0.5), Offset = Vector3.new(-0.4, 1.7, -1.5) },
        { Size = Vector3.new(0.25, 1.3, 0.4), Offset = Vector3.new(-0.4, 1.8, -1.5), Color = Color3.fromRGB(255, 200, 200) },
        { Size = Vector3.new(0.3, 1.6, 0.5), Offset = Vector3.new(0.4, 1.7, -1.5) },
        { Size = Vector3.new(0.25, 1.3, 0.4), Offset = Vector3.new(0.4, 1.8, -1.5), Color = Color3.fromRGB(255, 200, 200) },
        { Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(-0.35, 0.7, -2.25), Color = Color3.fromRGB(30, 30, 30) },
        { Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(0.35, 0.7, -2.25), Color = Color3.fromRGB(30, 30, 30) },
    },
    TailBlocks = {
        { Size = Vector3.new(0.6, 0.6, 0.5), Offset = Vector3.new(0, 0.5, 1.8) },
        { Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(0.2, 0.65, 1.9) },
        { Size = Vector3.new(0.5, 0.5, 0.4), Offset = Vector3.new(-0.2, 0.65, 1.9) },
        { Size = Vector3.new(0.4, 0.45, 0.35), Offset = Vector3.new(0, 0.75, 1.95) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.5, 1.1, 0.55), Offset = Vector3.new(0, 0, 0) },
            { Size = Vector3.new(0.55, 0.25, 0.7), Offset = Vector3.new(0, -0.55, -0.1) },
        },
        OffsetFL = Vector3.new(0.5, -1.35, -0.9),
        PivotY = 0.55,
    },
}

-- PIG
Templates.PIG = {
    ID = "PIG",
    Name = "Pig",
    BodyBlocks = {
        { Size = Vector3.new(2.4, 2.2, 3.4), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(2.0, 0.8, 2.2), Offset = Vector3.new(0, -0.95, 0) },
        { Size = Vector3.new(1.8, 1.6, 1.0), Offset = Vector3.new(0, 0.1, 1.5) },
    },
    HeadBlocks = {
        { Size = Vector3.new(1.5, 1.3, 1.2), Offset = Vector3.new(0, 0.3, -2.0) },
        { Size = Vector3.new(0.9, 0.7, 0.6), Offset = Vector3.new(0, -0.05, -2.6) },
        { Size = Vector3.new(0.5, 0.5, 0.15), Offset = Vector3.new(0, -0.05, -2.95), Color = Color3.fromRGB(255, 150, 170) },
        { Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(-0.12, -0.05, -3.0), Color = Color3.fromRGB(80, 50, 60) },
        { Size = Vector3.new(0.15, 0.15, 0.1), Offset = Vector3.new(0.12, -0.05, -3.0), Color = Color3.fromRGB(80, 50, 60) },
        { Size = Vector3.new(0.15, 0.6, 0.7), Offset = Vector3.new(-0.65, 0.7, -1.7) },
        { Size = Vector3.new(0.15, 0.6, 0.7), Offset = Vector3.new(0.65, 0.7, -1.7) },
        { Size = Vector3.new(0.25, 0.3, 0.15), Offset = Vector3.new(-0.4, 0.55, -2.5), Color = Color3.fromRGB(30, 30, 30) },
        { Size = Vector3.new(0.25, 0.3, 0.15), Offset = Vector3.new(0.4, 0.55, -2.5), Color = Color3.fromRGB(30, 30, 30) },
    },
    TailBlocks = {
        { Size = Vector3.new(0.15, 0.2, 0.25), Offset = Vector3.new(0, 0.6, 2.0) },
        { Size = Vector3.new(0.2, 0.15, 0.15), Offset = Vector3.new(0.12, 0.7, 2.15) },
        { Size = Vector3.new(0.15, 0.2, 0.15), Offset = Vector3.new(0.15, 0.6, 2.25) },
        { Size = Vector3.new(0.2, 0.15, 0.15), Offset = Vector3.new(0.05, 0.5, 2.3) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.55, 1.0, 0.55), Offset = Vector3.new(0, 0.15, 0) },
            { Size = Vector3.new(0.6, 0.3, 0.6), Offset = Vector3.new(0, -0.45, 0), Color = Color3.fromRGB(60, 45, 40) },
        },
        OffsetFL = Vector3.new(0.75, -1.25, -1.3),
        PivotY = 0.6,
    },
}

-- TURTLE
Templates.TURTLE = {
    ID = "TURTLE",
    Name = "Turtle",
    BodyBlocks = {
        { Size = Vector3.new(2.0, 0.7, 2.8), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(2.4, 0.7, 3.0), Offset = Vector3.new(0, 0.55, 0) },
        { Size = Vector3.new(2.1, 0.6, 2.6), Offset = Vector3.new(0, 1.05, 0) },
        { Size = Vector3.new(1.7, 0.5, 2.1), Offset = Vector3.new(0, 1.45, 0) },
        { Size = Vector3.new(1.2, 0.4, 1.5), Offset = Vector3.new(0, 1.75, 0) },
        { Size = Vector3.new(0.7, 0.3, 0.9), Offset = Vector3.new(0, 1.95, 0) },
        { Size = Vector3.new(0.7, 0.15, 0.7), Offset = Vector3.new(0, 2.1, 0) },
        { Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(0.6, 1.65, 0.6) },
        { Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(-0.6, 1.65, 0.6) },
        { Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(0.6, 1.65, -0.6) },
        { Size = Vector3.new(0.5, 0.12, 0.5), Offset = Vector3.new(-0.6, 1.65, -0.6) },
    },
    HeadBlocks = {
        { Size = Vector3.new(0.5, 0.45, 0.8), Offset = Vector3.new(0, 0.15, -1.7) },
        { Size = Vector3.new(0.8, 0.7, 0.7), Offset = Vector3.new(0, 0.3, -2.2) },
        { Size = Vector3.new(0.2, 0.25, 0.15), Offset = Vector3.new(-0.25, 0.5, -2.45), Color = Color3.fromRGB(30, 30, 30) },
        { Size = Vector3.new(0.2, 0.25, 0.15), Offset = Vector3.new(0.25, 0.5, -2.45), Color = Color3.fromRGB(30, 30, 30) },
        { Size = Vector3.new(0.3, 0.2, 0.2), Offset = Vector3.new(0, 0.15, -2.55), Color = Color3.fromRGB(200, 180, 140) },
    },
    TailBlocks = {
        { Size = Vector3.new(0.3, 0.25, 0.6), Offset = Vector3.new(0, 0.05, 1.6) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.7, 0.35, 0.9), Offset = Vector3.new(0, 0, 0) },
        },
        OffsetFL = Vector3.new(0.95, -0.5, -1.0),
        PivotY = 0.18,
    },
}

-- CRAB
Templates.CRAB = {
    ID = "CRAB",
    Name = "Crab",
    BodyBlocks = {
        { Size = Vector3.new(3.2, 1.0, 2.2), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(2.6, 0.6, 1.8), Offset = Vector3.new(0, 0.65, 0) },
        { Size = Vector3.new(1.8, 0.4, 1.2), Offset = Vector3.new(0, 1.0, 0) },
    },
    HeadBlocks = {
        { Size = Vector3.new(0.15, 0.6, 0.15), Offset = Vector3.new(-0.5, 0.7, -0.9) },
        { Size = Vector3.new(0.15, 0.6, 0.15), Offset = Vector3.new(0.5, 0.7, -0.9) },
        { Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(-0.5, 1.15, -0.9), Color = Color3.fromRGB(255, 255, 255) },
        { Size = Vector3.new(0.35, 0.35, 0.35), Offset = Vector3.new(0.5, 1.15, -0.9), Color = Color3.fromRGB(255, 255, 255) },
        { Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(-0.5, 1.15, -1.1), Color = Color3.fromRGB(20, 20, 20) },
        { Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(0.5, 1.15, -1.1), Color = Color3.fromRGB(20, 20, 20) },
    },
    DecorationBlocks = {
        { Size = Vector3.new(0.4, 0.4, 1.2), Offset = Vector3.new(-1.8, 0.3, -0.5) },
        { Size = Vector3.new(0.7, 0.5, 0.9), Offset = Vector3.new(-2.0, 0.4, -1.4) },
        { Size = Vector3.new(0.25, 0.6, 0.5), Offset = Vector3.new(-2.0, 0.65, -1.8) },
        { Size = Vector3.new(0.2, 0.35, 0.45), Offset = Vector3.new(-2.0, 0.15, -1.75) },
        { Size = Vector3.new(0.4, 0.4, 1.2), Offset = Vector3.new(1.8, 0.3, -0.5) },
        { Size = Vector3.new(0.7, 0.5, 0.9), Offset = Vector3.new(2.0, 0.4, -1.4) },
        { Size = Vector3.new(0.25, 0.6, 0.5), Offset = Vector3.new(2.0, 0.65, -1.8) },
        { Size = Vector3.new(0.2, 0.35, 0.45), Offset = Vector3.new(2.0, 0.15, -1.75) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.15, 0.7, 0.15), Offset = Vector3.new(0, 0.15, 0) },
            { Size = Vector3.new(0.12, 0.4, 0.12), Offset = Vector3.new(0, -0.35, 0) },
        },
        OffsetFL = Vector3.new(1.3, -0.7, -0.6),
        PivotY = 0.45,
    },
}

-- COW
Templates.COW = {
    ID = "COW",
    Name = "Cow",
    BodyBlocks = {
        { Size = Vector3.new(2.6, 2.4, 4.2), Offset = Vector3.new(0, 0, 0) },
        { Size = Vector3.new(2.0, 0.7, 2.4), Offset = Vector3.new(0, -1.05, 0) },
        { Size = Vector3.new(1.6, 0.5, 1.8), Offset = Vector3.new(0, 1.2, 0.5) },
    },
    HeadBlocks = {
        { Size = Vector3.new(1.4, 1.2, 1.4), Offset = Vector3.new(0, 0.35, -2.5) },
        { Size = Vector3.new(1.0, 0.8, 0.6), Offset = Vector3.new(0, -0.1, -3.1) },
        { Size = Vector3.new(0.7, 0.5, 0.2), Offset = Vector3.new(0, -0.1, -3.45), Color = Color3.fromRGB(60, 45, 50) },
        { Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(-0.15, -0.1, -3.5), Color = Color3.fromRGB(30, 25, 30) },
        { Size = Vector3.new(0.15, 0.2, 0.1), Offset = Vector3.new(0.15, -0.1, -3.5), Color = Color3.fromRGB(30, 25, 30) },
        { Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(-0.6, 1.0, -2.3), Color = Color3.fromRGB(230, 210, 180) },
        { Size = Vector3.new(0.15, 0.35, 0.15), Offset = Vector3.new(-0.7, 1.4, -2.2), Color = Color3.fromRGB(220, 200, 170) },
        { Size = Vector3.new(0.2, 0.6, 0.2), Offset = Vector3.new(0.6, 1.0, -2.3), Color = Color3.fromRGB(230, 210, 180) },
        { Size = Vector3.new(0.15, 0.35, 0.15), Offset = Vector3.new(0.7, 1.4, -2.2), Color = Color3.fromRGB(220, 200, 170) },
        { Size = Vector3.new(0.15, 0.35, 0.6), Offset = Vector3.new(-0.75, 0.5, -2.2) },
        { Size = Vector3.new(0.15, 0.35, 0.6), Offset = Vector3.new(0.75, 0.5, -2.2) },
        { Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(-0.4, 0.6, -3.0), Color = Color3.fromRGB(30, 30, 30) },
        { Size = Vector3.new(0.3, 0.35, 0.15), Offset = Vector3.new(0.4, 0.6, -3.0), Color = Color3.fromRGB(30, 30, 30) },
    },
    TailBlocks = {
        { Size = Vector3.new(0.15, 0.15, 1.0), Offset = Vector3.new(0, 0.4, 2.5) },
        { Size = Vector3.new(0.12, 0.12, 0.6), Offset = Vector3.new(0, 0.2, 3.1) },
        { Size = Vector3.new(0.3, 0.4, 0.25), Offset = Vector3.new(0, 0.05, 3.5) },
    },
    Legs = {
        Blocks = {
            { Size = Vector3.new(0.55, 1.5, 0.55), Offset = Vector3.new(0, 0.1, 0) },
            { Size = Vector3.new(0.6, 0.35, 0.6), Offset = Vector3.new(0, -0.65, 0), Color = Color3.fromRGB(50, 40, 35) },
        },
        OffsetFL = Vector3.new(0.85, -1.55, -1.7),
        PivotY = 0.85,
    },
}

--------------------------------------------------------------------------------
-- OBJ EXPORT FUNCTIONS
--------------------------------------------------------------------------------

local function exportToOBJ(template)
    local lines = {}
    table.insert(lines, "# Animal Template: " .. template.Name)
    table.insert(lines, "# Exported from AnimalTemplates")
    table.insert(lines, "# Import into Blender: File > Import > Wavefront (.obj)")
    table.insert(lines, "")
    
    local vertexIndex = 1
    
    -- Helper to add a cube
    local function addCube(name, size, offset)
        table.insert(lines, "o " .. name)
        
        local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
        local cx, cy, cz = offset.X, offset.Y, offset.Z
        
        -- 8 vertices
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy - hy, cz - hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy - hy, cz - hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy + hy, cz - hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy + hy, cz - hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy - hy, cz + hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy - hy, cz + hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx + hx, cy + hy, cz + hz))
        table.insert(lines, string.format("v %.4f %.4f %.4f", cx - hx, cy + hy, cz + hz))
        
        -- 6 faces
        local v = vertexIndex
        table.insert(lines, string.format("f %d %d %d %d", v+0, v+1, v+2, v+3))
        table.insert(lines, string.format("f %d %d %d %d", v+5, v+4, v+7, v+6))
        table.insert(lines, string.format("f %d %d %d %d", v+4, v+0, v+3, v+7))
        table.insert(lines, string.format("f %d %d %d %d", v+1, v+5, v+6, v+2))
        table.insert(lines, string.format("f %d %d %d %d", v+3, v+2, v+6, v+7))
        table.insert(lines, string.format("f %d %d %d %d", v+4, v+5, v+1, v+0))
        
        table.insert(lines, "")
        vertexIndex = vertexIndex + 8
    end
    
    -- Export body
    for i, block in ipairs(template.BodyBlocks) do
        addCube("Body_" .. i, block.Size, block.Offset)
    end
    
    -- Export head
    if template.HeadBlocks then
        for i, block in ipairs(template.HeadBlocks) do
            addCube("Head_" .. i, block.Size, block.Offset)
        end
    end
    
    -- Export tail
    if template.TailBlocks then
        for i, block in ipairs(template.TailBlocks) do
            addCube("Tail_" .. i, block.Size, block.Offset)
        end
    end
    
    -- Export decorations
    if template.DecorationBlocks then
        for i, block in ipairs(template.DecorationBlocks) do
            addCube("Deco_" .. i, block.Size, block.Offset)
        end
    end
    
    -- Export legs
    local legConfig = template.Legs
    local ofl = legConfig.OffsetFL
    
    for i, block in ipairs(legConfig.Blocks) do
        addCube("LegFL_" .. i, block.Size, ofl + block.Offset)
        addCube("LegFR_" .. i, block.Size, Vector3.new(-ofl.X, ofl.Y, ofl.Z) + block.Offset)
        addCube("LegBL_" .. i, block.Size, Vector3.new(ofl.X, ofl.Y, -ofl.Z) + block.Offset)
        addCube("LegBR_" .. i, block.Size, Vector3.new(-ofl.X, ofl.Y, -ofl.Z) + block.Offset)
    end
    
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- MAIN - Export all templates to files
--------------------------------------------------------------------------------

print("Animal Template OBJ Exporter")
print("============================")
print("")

local templateIDs = { "DEFAULT", "FLUFFY", "SLIME", "BEETLE", "BUNNY", "PIG", "TURTLE", "CRAB", "COW" }

for _, id in ipairs(templateIDs) do
    local template = Templates[id]
    if template then
        local filename = "Animal_" .. id .. ".obj"
        local content = exportToOBJ(template)
        
        local file = io.open(filename, "w")
        if file then
            file:write(content)
            file:close()
            print("Created: " .. filename)
        else
            print("ERROR: Could not create " .. filename)
        end
    end
end

print("")
print("Export complete! Import .obj files into Blender with:")
print("  File > Import > Wavefront (.obj)")
print("")
print("Tips for Blender:")
print("  - Select all objects and Join (Ctrl+J) to combine")
print("  - Use 'Shade Smooth' for smoother look")
print("  - Add subdivision surface modifier for rounder shapes")
