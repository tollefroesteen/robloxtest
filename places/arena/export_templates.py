#!/usr/bin/env python3
"""
Animal Template OBJ Exporter

Exports Roblox animal templates to Wavefront OBJ format for import into Blender.

Usage:
    python export_templates.py

This will create .obj files in the current directory that can be imported
directly into Blender via File > Import > Wavefront (.obj)
"""

import os

class Vector3:
    def __init__(self, x=0, y=0, z=0):
        self.X = x
        self.Y = y
        self.Z = z
    
    def __add__(self, other):
        return Vector3(self.X + other.X, self.Y + other.Y, self.Z + other.Z)

def Color3_fromRGB(r, g, b):
    return {"R": r/255, "G": g/255, "B": b/255}

# Template definitions
TEMPLATES = {}

# DEFAULT - Simple blocky sheep
TEMPLATES["DEFAULT"] = {
    "ID": "DEFAULT",
    "Name": "Sheep",
    "BodyBlocks": [
        {"Size": Vector3(2, 2, 4), "Offset": Vector3(0, 0, 0)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.5, 1.5, 0.5), "Offset": Vector3(0, 0, 0)},
        ],
        "OffsetFL": Vector3(0.75, -1.75, -1.75),
        "PivotY": 0.75,
    },
}

# FLUFFY - Woolly sheep with exaggerated fluffy volumes
TEMPLATES["FLUFFY"] = {
    "ID": "FLUFFY",
    "Name": "Fluffy Sheep",
    "BodyBlocks": [
        {"Size": Vector3(2.0, 1.8, 3.0), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(1.0, 0.8, 1.0), "Offset": Vector3(-0.5, 1.0, -0.6)},
        {"Size": Vector3(1.1, 0.9, 1.1), "Offset": Vector3(0.4, 0.95, 0.0)},
        {"Size": Vector3(0.9, 0.7, 0.9), "Offset": Vector3(-0.3, 1.05, 0.7)},
        {"Size": Vector3(1.0, 0.8, 0.8), "Offset": Vector3(0.5, 0.9, 1.0)},
        {"Size": Vector3(0.7, 0.9, 1.0), "Offset": Vector3(-1.2, 0.2, -0.3)},
        {"Size": Vector3(0.7, 0.8, 1.1), "Offset": Vector3(1.2, 0.3, 0.0)},
        {"Size": Vector3(0.6, 0.85, 0.9), "Offset": Vector3(-1.15, 0.15, 0.8)},
        {"Size": Vector3(0.65, 0.8, 0.85), "Offset": Vector3(1.1, 0.25, 0.7)},
        {"Size": Vector3(1.4, 1.2, 0.8), "Offset": Vector3(0, 0.3, 1.5)},
        {"Size": Vector3(0.8, 0.6, 0.5), "Offset": Vector3(-0.4, 0.7, 1.7)},
        {"Size": Vector3(0.8, 0.6, 0.5), "Offset": Vector3(0.4, 0.7, 1.7)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(1.2, 1.1, 1.0), "Offset": Vector3(0, 0.4, -1.9)},
        {"Size": Vector3(0.5, 0.4, 0.35), "Offset": Vector3(0, 0.05, -2.4)},
        {"Size": Vector3(0.2, 0.15, 0.1), "Offset": Vector3(0, 0.0, -2.6)},
        {"Size": Vector3(0.2, 0.5, 0.4), "Offset": Vector3(-0.65, 0.5, -1.7)},
        {"Size": Vector3(0.2, 0.5, 0.4), "Offset": Vector3(0.65, 0.5, -1.7)},
        {"Size": Vector3(0.8, 0.5, 0.4), "Offset": Vector3(0, 0.85, -1.7)},
    ],
    "TailBlocks": [
        {"Size": Vector3(0.5, 0.5, 0.45), "Offset": Vector3(0, 0.5, 2.0)},
        {"Size": Vector3(0.35, 0.4, 0.35), "Offset": Vector3(0.15, 0.65, 2.1)},
        {"Size": Vector3(0.35, 0.4, 0.35), "Offset": Vector3(-0.15, 0.65, 2.1)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.35, 1.4, 0.35), "Offset": Vector3(0, 0, 0)},
            {"Size": Vector3(0.4, 0.25, 0.4), "Offset": Vector3(0, -0.7, 0)},
        ],
        "OffsetFL": Vector3(0.6, -1.5, -1.2),
        "PivotY": 0.7,
    },
}

# SLIME - Gooey bouncy blob
TEMPLATES["SLIME"] = {
    "ID": "SLIME",
    "Name": "Slime",
    "BodyBlocks": [
        {"Size": Vector3(2.6, 1.6, 2.4), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(1.4, 1.0, 1.4), "Offset": Vector3(0, -0.1, 0)},
        {"Size": Vector3(1.2, 0.7, 1.2), "Offset": Vector3(0, 0.9, 0)},
        {"Size": Vector3(0.6, 0.4, 0.6), "Offset": Vector3(0, 1.35, 0)},
        {"Size": Vector3(0.5, 0.6, 0.7), "Offset": Vector3(-1.1, 0.3, 0)},
        {"Size": Vector3(0.5, 0.6, 0.7), "Offset": Vector3(1.1, 0.3, 0)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(0.4, 0.5, 0.2), "Offset": Vector3(-0.4, 0.5, -1.1)},
        {"Size": Vector3(0.4, 0.5, 0.2), "Offset": Vector3(0.4, 0.5, -1.1)},
        {"Size": Vector3(0.2, 0.25, 0.1), "Offset": Vector3(-0.4, 0.45, -1.2)},
        {"Size": Vector3(0.2, 0.25, 0.1), "Offset": Vector3(0.4, 0.45, -1.2)},
        {"Size": Vector3(0.5, 0.15, 0.1), "Offset": Vector3(0, -0.1, -1.15)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.7, 0.5, 0.7), "Offset": Vector3(0, 0, 0)},
        ],
        "OffsetFL": Vector3(0.7, -0.9, -0.7),
        "PivotY": 0.25,
    },
}

# BEETLE - Shiny cartoon bug
TEMPLATES["BEETLE"] = {
    "ID": "BEETLE",
    "Name": "Beetle",
    "BodyBlocks": [
        {"Size": Vector3(2.4, 1.0, 3.2), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(2.0, 0.6, 2.6), "Offset": Vector3(0, 0.65, 0.2)},
        {"Size": Vector3(1.5, 0.45, 2.0), "Offset": Vector3(0, 1.05, 0.2)},
        {"Size": Vector3(0.9, 0.3, 1.3), "Offset": Vector3(0, 1.35, 0.2)},
        {"Size": Vector3(0.15, 0.25, 2.4), "Offset": Vector3(0, 1.2, 0.2)},
        {"Size": Vector3(0.05, 0.5, 2.0), "Offset": Vector3(0, 0.85, 0.3)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(1.1, 0.8, 0.9), "Offset": Vector3(0, 0.0, -1.9)},
        {"Size": Vector3(0.5, 0.5, 0.4), "Offset": Vector3(-0.4, 0.35, -2.1)},
        {"Size": Vector3(0.5, 0.5, 0.4), "Offset": Vector3(0.4, 0.35, -2.1)},
        {"Size": Vector3(0.15, 0.15, 0.1), "Offset": Vector3(-0.5, 0.45, -2.3)},
        {"Size": Vector3(0.15, 0.15, 0.1), "Offset": Vector3(0.3, 0.45, -2.3)},
        {"Size": Vector3(0.08, 0.7, 0.08), "Offset": Vector3(-0.25, 0.7, -1.8)},
        {"Size": Vector3(0.15, 0.15, 0.15), "Offset": Vector3(-0.25, 1.1, -1.8)},
        {"Size": Vector3(0.08, 0.7, 0.08), "Offset": Vector3(0.25, 0.7, -1.8)},
        {"Size": Vector3(0.15, 0.15, 0.15), "Offset": Vector3(0.25, 1.1, -1.8)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.15, 0.8, 0.15), "Offset": Vector3(0, 0.2, 0)},
            {"Size": Vector3(0.12, 0.5, 0.12), "Offset": Vector3(0.05, -0.35, 0)},
        ],
        "OffsetFL": Vector3(1.0, -0.75, -1.1),
        "PivotY": 0.55,
    },
}

# BUNNY - Super cute cartoon rabbit
TEMPLATES["BUNNY"] = {
    "ID": "BUNNY",
    "Name": "Bunny",
    "BodyBlocks": [
        {"Size": Vector3(1.8, 1.9, 2.2), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(1.2, 1.0, 0.6), "Offset": Vector3(0, -0.2, -1.1)},
        {"Size": Vector3(1.7, 1.6, 1.2), "Offset": Vector3(0, 0.1, 1.0)},
        {"Size": Vector3(1.3, 1.0, 0.7), "Offset": Vector3(0, 0.6, 1.3)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(1.4, 1.3, 1.2), "Offset": Vector3(0, 0.6, -1.7)},
        {"Size": Vector3(0.55, 0.5, 0.4), "Offset": Vector3(-0.55, 0.3, -2.0)},
        {"Size": Vector3(0.55, 0.5, 0.4), "Offset": Vector3(0.55, 0.3, -2.0)},
        {"Size": Vector3(0.4, 0.3, 0.25), "Offset": Vector3(0, 0.25, -2.35)},
        {"Size": Vector3(0.2, 0.15, 0.1), "Offset": Vector3(0, 0.3, -2.5)},
        {"Size": Vector3(0.3, 1.6, 0.5), "Offset": Vector3(-0.4, 1.7, -1.5)},
        {"Size": Vector3(0.25, 1.3, 0.4), "Offset": Vector3(-0.4, 1.8, -1.5)},
        {"Size": Vector3(0.3, 1.6, 0.5), "Offset": Vector3(0.4, 1.7, -1.5)},
        {"Size": Vector3(0.25, 1.3, 0.4), "Offset": Vector3(0.4, 1.8, -1.5)},
        {"Size": Vector3(0.3, 0.35, 0.15), "Offset": Vector3(-0.35, 0.7, -2.25)},
        {"Size": Vector3(0.3, 0.35, 0.15), "Offset": Vector3(0.35, 0.7, -2.25)},
    ],
    "TailBlocks": [
        {"Size": Vector3(0.6, 0.6, 0.5), "Offset": Vector3(0, 0.5, 1.8)},
        {"Size": Vector3(0.5, 0.5, 0.4), "Offset": Vector3(0.2, 0.65, 1.9)},
        {"Size": Vector3(0.5, 0.5, 0.4), "Offset": Vector3(-0.2, 0.65, 1.9)},
        {"Size": Vector3(0.4, 0.45, 0.35), "Offset": Vector3(0, 0.75, 1.95)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.5, 1.1, 0.55), "Offset": Vector3(0, 0, 0)},
            {"Size": Vector3(0.55, 0.25, 0.7), "Offset": Vector3(0, -0.55, -0.1)},
        ],
        "OffsetFL": Vector3(0.5, -1.35, -0.9),
        "PivotY": 0.55,
    },
}

# PIG - Chubby cartoon piggy
TEMPLATES["PIG"] = {
    "ID": "PIG",
    "Name": "Pig",
    "BodyBlocks": [
        {"Size": Vector3(2.4, 2.2, 3.4), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(2.0, 0.8, 2.2), "Offset": Vector3(0, -0.95, 0)},
        {"Size": Vector3(1.8, 1.6, 1.0), "Offset": Vector3(0, 0.1, 1.5)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(1.5, 1.3, 1.2), "Offset": Vector3(0, 0.3, -2.0)},
        {"Size": Vector3(0.9, 0.7, 0.6), "Offset": Vector3(0, -0.05, -2.6)},
        {"Size": Vector3(0.5, 0.5, 0.15), "Offset": Vector3(0, -0.05, -2.95)},
        {"Size": Vector3(0.15, 0.15, 0.1), "Offset": Vector3(-0.12, -0.05, -3.0)},
        {"Size": Vector3(0.15, 0.15, 0.1), "Offset": Vector3(0.12, -0.05, -3.0)},
        {"Size": Vector3(0.15, 0.6, 0.7), "Offset": Vector3(-0.65, 0.7, -1.7)},
        {"Size": Vector3(0.15, 0.6, 0.7), "Offset": Vector3(0.65, 0.7, -1.7)},
        {"Size": Vector3(0.25, 0.3, 0.15), "Offset": Vector3(-0.4, 0.55, -2.5)},
        {"Size": Vector3(0.25, 0.3, 0.15), "Offset": Vector3(0.4, 0.55, -2.5)},
    ],
    "TailBlocks": [
        {"Size": Vector3(0.15, 0.2, 0.25), "Offset": Vector3(0, 0.6, 2.0)},
        {"Size": Vector3(0.2, 0.15, 0.15), "Offset": Vector3(0.12, 0.7, 2.15)},
        {"Size": Vector3(0.15, 0.2, 0.15), "Offset": Vector3(0.15, 0.6, 2.25)},
        {"Size": Vector3(0.2, 0.15, 0.15), "Offset": Vector3(0.05, 0.5, 2.3)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.55, 1.0, 0.55), "Offset": Vector3(0, 0.15, 0)},
            {"Size": Vector3(0.6, 0.3, 0.6), "Offset": Vector3(0, -0.45, 0)},
        ],
        "OffsetFL": Vector3(0.75, -1.25, -1.3),
        "PivotY": 0.6,
    },
}

# TURTLE - Cute slow turtle
TEMPLATES["TURTLE"] = {
    "ID": "TURTLE",
    "Name": "Turtle",
    "BodyBlocks": [
        {"Size": Vector3(2.0, 0.7, 2.8), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(2.4, 0.7, 3.0), "Offset": Vector3(0, 0.55, 0)},
        {"Size": Vector3(2.1, 0.6, 2.6), "Offset": Vector3(0, 1.05, 0)},
        {"Size": Vector3(1.7, 0.5, 2.1), "Offset": Vector3(0, 1.45, 0)},
        {"Size": Vector3(1.2, 0.4, 1.5), "Offset": Vector3(0, 1.75, 0)},
        {"Size": Vector3(0.7, 0.3, 0.9), "Offset": Vector3(0, 1.95, 0)},
        {"Size": Vector3(0.7, 0.15, 0.7), "Offset": Vector3(0, 2.1, 0)},
        {"Size": Vector3(0.5, 0.12, 0.5), "Offset": Vector3(0.6, 1.65, 0.6)},
        {"Size": Vector3(0.5, 0.12, 0.5), "Offset": Vector3(-0.6, 1.65, 0.6)},
        {"Size": Vector3(0.5, 0.12, 0.5), "Offset": Vector3(0.6, 1.65, -0.6)},
        {"Size": Vector3(0.5, 0.12, 0.5), "Offset": Vector3(-0.6, 1.65, -0.6)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(0.5, 0.45, 0.8), "Offset": Vector3(0, 0.15, -1.7)},
        {"Size": Vector3(0.8, 0.7, 0.7), "Offset": Vector3(0, 0.3, -2.2)},
        {"Size": Vector3(0.2, 0.25, 0.15), "Offset": Vector3(-0.25, 0.5, -2.45)},
        {"Size": Vector3(0.2, 0.25, 0.15), "Offset": Vector3(0.25, 0.5, -2.45)},
        {"Size": Vector3(0.3, 0.2, 0.2), "Offset": Vector3(0, 0.15, -2.55)},
    ],
    "TailBlocks": [
        {"Size": Vector3(0.3, 0.25, 0.6), "Offset": Vector3(0, 0.05, 1.6)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.7, 0.35, 0.9), "Offset": Vector3(0, 0, 0)},
        ],
        "OffsetFL": Vector3(0.95, -0.5, -1.0),
        "PivotY": 0.18,
    },
}

# CRAB - Wide cartoon crab
TEMPLATES["CRAB"] = {
    "ID": "CRAB",
    "Name": "Crab",
    "BodyBlocks": [
        {"Size": Vector3(3.2, 1.0, 2.2), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(2.6, 0.6, 1.8), "Offset": Vector3(0, 0.65, 0)},
        {"Size": Vector3(1.8, 0.4, 1.2), "Offset": Vector3(0, 1.0, 0)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(0.15, 0.6, 0.15), "Offset": Vector3(-0.5, 0.7, -0.9)},
        {"Size": Vector3(0.15, 0.6, 0.15), "Offset": Vector3(0.5, 0.7, -0.9)},
        {"Size": Vector3(0.35, 0.35, 0.35), "Offset": Vector3(-0.5, 1.15, -0.9)},
        {"Size": Vector3(0.35, 0.35, 0.35), "Offset": Vector3(0.5, 1.15, -0.9)},
        {"Size": Vector3(0.15, 0.2, 0.1), "Offset": Vector3(-0.5, 1.15, -1.1)},
        {"Size": Vector3(0.15, 0.2, 0.1), "Offset": Vector3(0.5, 1.15, -1.1)},
    ],
    "DecorationBlocks": [
        {"Size": Vector3(0.4, 0.4, 1.2), "Offset": Vector3(-1.8, 0.3, -0.5)},
        {"Size": Vector3(0.7, 0.5, 0.9), "Offset": Vector3(-2.0, 0.4, -1.4)},
        {"Size": Vector3(0.25, 0.6, 0.5), "Offset": Vector3(-2.0, 0.65, -1.8)},
        {"Size": Vector3(0.2, 0.35, 0.45), "Offset": Vector3(-2.0, 0.15, -1.75)},
        {"Size": Vector3(0.4, 0.4, 1.2), "Offset": Vector3(1.8, 0.3, -0.5)},
        {"Size": Vector3(0.7, 0.5, 0.9), "Offset": Vector3(2.0, 0.4, -1.4)},
        {"Size": Vector3(0.25, 0.6, 0.5), "Offset": Vector3(2.0, 0.65, -1.8)},
        {"Size": Vector3(0.2, 0.35, 0.45), "Offset": Vector3(2.0, 0.15, -1.75)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.15, 0.7, 0.15), "Offset": Vector3(0, 0.15, 0)},
            {"Size": Vector3(0.12, 0.4, 0.12), "Offset": Vector3(0, -0.35, 0)},
        ],
        "OffsetFL": Vector3(1.3, -0.7, -0.6),
        "PivotY": 0.45,
    },
}

# COW - Big chunky cartoon cow
TEMPLATES["COW"] = {
    "ID": "COW",
    "Name": "Cow",
    "BodyBlocks": [
        {"Size": Vector3(2.6, 2.4, 4.2), "Offset": Vector3(0, 0, 0)},
        {"Size": Vector3(2.0, 0.7, 2.4), "Offset": Vector3(0, -1.05, 0)},
        {"Size": Vector3(1.6, 0.5, 1.8), "Offset": Vector3(0, 1.2, 0.5)},
    ],
    "HeadBlocks": [
        {"Size": Vector3(1.4, 1.2, 1.4), "Offset": Vector3(0, 0.35, -2.5)},
        {"Size": Vector3(1.0, 0.8, 0.6), "Offset": Vector3(0, -0.1, -3.1)},
        {"Size": Vector3(0.7, 0.5, 0.2), "Offset": Vector3(0, -0.1, -3.45)},
        {"Size": Vector3(0.15, 0.2, 0.1), "Offset": Vector3(-0.15, -0.1, -3.5)},
        {"Size": Vector3(0.15, 0.2, 0.1), "Offset": Vector3(0.15, -0.1, -3.5)},
        {"Size": Vector3(0.2, 0.6, 0.2), "Offset": Vector3(-0.6, 1.0, -2.3)},
        {"Size": Vector3(0.15, 0.35, 0.15), "Offset": Vector3(-0.7, 1.4, -2.2)},
        {"Size": Vector3(0.2, 0.6, 0.2), "Offset": Vector3(0.6, 1.0, -2.3)},
        {"Size": Vector3(0.15, 0.35, 0.15), "Offset": Vector3(0.7, 1.4, -2.2)},
        {"Size": Vector3(0.15, 0.35, 0.6), "Offset": Vector3(-0.75, 0.5, -2.2)},
        {"Size": Vector3(0.15, 0.35, 0.6), "Offset": Vector3(0.75, 0.5, -2.2)},
        {"Size": Vector3(0.3, 0.35, 0.15), "Offset": Vector3(-0.4, 0.6, -3.0)},
        {"Size": Vector3(0.3, 0.35, 0.15), "Offset": Vector3(0.4, 0.6, -3.0)},
    ],
    "TailBlocks": [
        {"Size": Vector3(0.15, 0.15, 1.0), "Offset": Vector3(0, 0.4, 2.5)},
        {"Size": Vector3(0.12, 0.12, 0.6), "Offset": Vector3(0, 0.2, 3.1)},
        {"Size": Vector3(0.3, 0.4, 0.25), "Offset": Vector3(0, 0.05, 3.5)},
    ],
    "Legs": {
        "Blocks": [
            {"Size": Vector3(0.55, 1.5, 0.55), "Offset": Vector3(0, 0.1, 0)},
            {"Size": Vector3(0.6, 0.35, 0.6), "Offset": Vector3(0, -0.65, 0)},
        ],
        "OffsetFL": Vector3(0.85, -1.55, -1.7),
        "PivotY": 0.85,
    },
}


def export_to_obj(template):
    """Export a template to OBJ format string."""
    lines = []
    lines.append(f"# Animal Template: {template['Name']}")
    lines.append("# Exported from AnimalTemplates")
    lines.append("# Import into Blender: File > Import > Wavefront (.obj)")
    lines.append("")
    
    vertex_index = 1
    
    def add_cube(name, size, offset):
        nonlocal vertex_index
        lines.append(f"o {name}")
        
        hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
        cx, cy, cz = offset.X, offset.Y, offset.Z
        
        # 8 vertices of the cube
        lines.append(f"v {cx - hx:.4f} {cy - hy:.4f} {cz - hz:.4f}")
        lines.append(f"v {cx + hx:.4f} {cy - hy:.4f} {cz - hz:.4f}")
        lines.append(f"v {cx + hx:.4f} {cy + hy:.4f} {cz - hz:.4f}")
        lines.append(f"v {cx - hx:.4f} {cy + hy:.4f} {cz - hz:.4f}")
        lines.append(f"v {cx - hx:.4f} {cy - hy:.4f} {cz + hz:.4f}")
        lines.append(f"v {cx + hx:.4f} {cy - hy:.4f} {cz + hz:.4f}")
        lines.append(f"v {cx + hx:.4f} {cy + hy:.4f} {cz + hz:.4f}")
        lines.append(f"v {cx - hx:.4f} {cy + hy:.4f} {cz + hz:.4f}")
        
        # 6 faces (quads)
        v = vertex_index
        lines.append(f"f {v+0} {v+1} {v+2} {v+3}")  # front
        lines.append(f"f {v+5} {v+4} {v+7} {v+6}")  # back
        lines.append(f"f {v+4} {v+0} {v+3} {v+7}")  # left
        lines.append(f"f {v+1} {v+5} {v+6} {v+2}")  # right
        lines.append(f"f {v+3} {v+2} {v+6} {v+7}")  # top
        lines.append(f"f {v+4} {v+5} {v+1} {v+0}")  # bottom
        
        lines.append("")
        vertex_index += 8
    
    # Export body blocks
    for i, block in enumerate(template["BodyBlocks"], 1):
        add_cube(f"Body_{i}", block["Size"], block["Offset"])
    
    # Export head blocks
    if "HeadBlocks" in template:
        for i, block in enumerate(template["HeadBlocks"], 1):
            add_cube(f"Head_{i}", block["Size"], block["Offset"])
    
    # Export tail blocks
    if "TailBlocks" in template:
        for i, block in enumerate(template["TailBlocks"], 1):
            add_cube(f"Tail_{i}", block["Size"], block["Offset"])
    
    # Export decoration blocks
    if "DecorationBlocks" in template:
        for i, block in enumerate(template["DecorationBlocks"], 1):
            add_cube(f"Deco_{i}", block["Size"], block["Offset"])
    
    # Export legs (all 4)
    leg_config = template["Legs"]
    ofl = leg_config["OffsetFL"]
    
    for i, block in enumerate(leg_config["Blocks"], 1):
        add_cube(f"LegFL_{i}", block["Size"], ofl + block["Offset"])
        add_cube(f"LegFR_{i}", block["Size"], Vector3(-ofl.X, ofl.Y, ofl.Z) + block["Offset"])
        add_cube(f"LegBL_{i}", block["Size"], Vector3(ofl.X, ofl.Y, -ofl.Z) + block["Offset"])
        add_cube(f"LegBR_{i}", block["Size"], Vector3(-ofl.X, ofl.Y, -ofl.Z) + block["Offset"])
    
    return "\n".join(lines)


def main():
    print("Animal Template OBJ Exporter")
    print("============================")
    print("")
    
    # Create output directory
    output_dir = os.path.dirname(os.path.abspath(__file__))
    models_dir = os.path.join(output_dir, "animal_models")
    os.makedirs(models_dir, exist_ok=True)
    
    template_ids = ["DEFAULT", "FLUFFY", "SLIME", "BEETLE", "BUNNY", "PIG", "TURTLE", "CRAB", "COW"]
    
    for template_id in template_ids:
        if template_id in TEMPLATES:
            template = TEMPLATES[template_id]
            filename = os.path.join(models_dir, f"Animal_{template_id}.obj")
            content = export_to_obj(template)
            
            with open(filename, "w") as f:
                f.write(content)
            
            print(f"Created: {filename}")
        else:
            print(f"WARNING: Template {template_id} not found")
    
    print("")
    print(f"Export complete! OBJ files saved to: {models_dir}")
    print("")
    print("Tips for Blender:")
    print("  - Import via File > Import > Wavefront (.obj)")
    print("  - Select all objects and Join (Ctrl+J) to combine")
    print("  - Use 'Shade Smooth' for smoother look")
    print("  - Add subdivision surface modifier for rounder shapes")


if __name__ == "__main__":
    main()
