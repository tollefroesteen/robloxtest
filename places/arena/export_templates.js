#!/usr/bin/env node
/**
 * Animal Template OBJ Exporter
 * 
 * Exports Roblox animal templates to Wavefront OBJ format for import into Blender.
 * 
 * Usage:
 *     node export_templates.js
 * 
 * This will create .obj files in an animal_models directory that can be imported
 * directly into Blender via File > Import > Wavefront (.obj)
 */

const fs = require('fs');
const path = require('path');

class Vector3 {
    constructor(x = 0, y = 0, z = 0) {
        this.X = x;
        this.Y = y;
        this.Z = z;
    }

    add(other) {
        return new Vector3(this.X + other.X, this.Y + other.Y, this.Z + other.Z);
    }
}

// Template definitions
const TEMPLATES = {
    DEFAULT: {
        ID: "DEFAULT",
        Name: "Sheep",
        BodyBlocks: [
            { Size: new Vector3(2, 2, 4), Offset: new Vector3(0, 0, 0) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.5, 1.5, 0.5), Offset: new Vector3(0, 0, 0) },
            ],
            OffsetFL: new Vector3(0.75, -1.75, -1.75),
            PivotY: 0.75,
        },
    },

    FLUFFY: {
        ID: "FLUFFY",
        Name: "Fluffy Sheep",
        BodyBlocks: [
            { Size: new Vector3(2.0, 1.8, 3.0), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(1.0, 0.8, 1.0), Offset: new Vector3(-0.5, 1.0, -0.6) },
            { Size: new Vector3(1.1, 0.9, 1.1), Offset: new Vector3(0.4, 0.95, 0.0) },
            { Size: new Vector3(0.9, 0.7, 0.9), Offset: new Vector3(-0.3, 1.05, 0.7) },
            { Size: new Vector3(1.0, 0.8, 0.8), Offset: new Vector3(0.5, 0.9, 1.0) },
            { Size: new Vector3(0.7, 0.9, 1.0), Offset: new Vector3(-1.2, 0.2, -0.3) },
            { Size: new Vector3(0.7, 0.8, 1.1), Offset: new Vector3(1.2, 0.3, 0.0) },
            { Size: new Vector3(0.6, 0.85, 0.9), Offset: new Vector3(-1.15, 0.15, 0.8) },
            { Size: new Vector3(0.65, 0.8, 0.85), Offset: new Vector3(1.1, 0.25, 0.7) },
            { Size: new Vector3(1.4, 1.2, 0.8), Offset: new Vector3(0, 0.3, 1.5) },
            { Size: new Vector3(0.8, 0.6, 0.5), Offset: new Vector3(-0.4, 0.7, 1.7) },
            { Size: new Vector3(0.8, 0.6, 0.5), Offset: new Vector3(0.4, 0.7, 1.7) },
        ],
        HeadBlocks: [
            { Size: new Vector3(1.2, 1.1, 1.0), Offset: new Vector3(0, 0.4, -1.9) },
            { Size: new Vector3(0.5, 0.4, 0.35), Offset: new Vector3(0, 0.05, -2.4) },
            { Size: new Vector3(0.2, 0.15, 0.1), Offset: new Vector3(0, 0.0, -2.6) },
            { Size: new Vector3(0.2, 0.5, 0.4), Offset: new Vector3(-0.65, 0.5, -1.7) },
            { Size: new Vector3(0.2, 0.5, 0.4), Offset: new Vector3(0.65, 0.5, -1.7) },
            { Size: new Vector3(0.8, 0.5, 0.4), Offset: new Vector3(0, 0.85, -1.7) },
        ],
        TailBlocks: [
            { Size: new Vector3(0.5, 0.5, 0.45), Offset: new Vector3(0, 0.5, 2.0) },
            { Size: new Vector3(0.35, 0.4, 0.35), Offset: new Vector3(0.15, 0.65, 2.1) },
            { Size: new Vector3(0.35, 0.4, 0.35), Offset: new Vector3(-0.15, 0.65, 2.1) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.35, 1.4, 0.35), Offset: new Vector3(0, 0, 0) },
                { Size: new Vector3(0.4, 0.25, 0.4), Offset: new Vector3(0, -0.7, 0) },
            ],
            OffsetFL: new Vector3(0.6, -1.5, -1.2),
            PivotY: 0.7,
        },
    },

    SLIME: {
        ID: "SLIME",
        Name: "Slime",
        BodyBlocks: [
            { Size: new Vector3(2.6, 1.6, 2.4), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(1.4, 1.0, 1.4), Offset: new Vector3(0, -0.1, 0) },
            { Size: new Vector3(1.2, 0.7, 1.2), Offset: new Vector3(0, 0.9, 0) },
            { Size: new Vector3(0.6, 0.4, 0.6), Offset: new Vector3(0, 1.35, 0) },
            { Size: new Vector3(0.5, 0.6, 0.7), Offset: new Vector3(-1.1, 0.3, 0) },
            { Size: new Vector3(0.5, 0.6, 0.7), Offset: new Vector3(1.1, 0.3, 0) },
        ],
        HeadBlocks: [
            { Size: new Vector3(0.4, 0.5, 0.2), Offset: new Vector3(-0.4, 0.5, -1.1) },
            { Size: new Vector3(0.4, 0.5, 0.2), Offset: new Vector3(0.4, 0.5, -1.1) },
            { Size: new Vector3(0.2, 0.25, 0.1), Offset: new Vector3(-0.4, 0.45, -1.2) },
            { Size: new Vector3(0.2, 0.25, 0.1), Offset: new Vector3(0.4, 0.45, -1.2) },
            { Size: new Vector3(0.5, 0.15, 0.1), Offset: new Vector3(0, -0.1, -1.15) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.7, 0.5, 0.7), Offset: new Vector3(0, 0, 0) },
            ],
            OffsetFL: new Vector3(0.7, -0.9, -0.7),
            PivotY: 0.25,
        },
    },

    BEETLE: {
        ID: "BEETLE",
        Name: "Beetle",
        BodyBlocks: [
            { Size: new Vector3(2.4, 1.0, 3.2), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(2.0, 0.6, 2.6), Offset: new Vector3(0, 0.65, 0.2) },
            { Size: new Vector3(1.5, 0.45, 2.0), Offset: new Vector3(0, 1.05, 0.2) },
            { Size: new Vector3(0.9, 0.3, 1.3), Offset: new Vector3(0, 1.35, 0.2) },
            { Size: new Vector3(0.15, 0.25, 2.4), Offset: new Vector3(0, 1.2, 0.2) },
            { Size: new Vector3(0.05, 0.5, 2.0), Offset: new Vector3(0, 0.85, 0.3) },
        ],
        HeadBlocks: [
            { Size: new Vector3(1.1, 0.8, 0.9), Offset: new Vector3(0, 0.0, -1.9) },
            { Size: new Vector3(0.5, 0.5, 0.4), Offset: new Vector3(-0.4, 0.35, -2.1) },
            { Size: new Vector3(0.5, 0.5, 0.4), Offset: new Vector3(0.4, 0.35, -2.1) },
            { Size: new Vector3(0.15, 0.15, 0.1), Offset: new Vector3(-0.5, 0.45, -2.3) },
            { Size: new Vector3(0.15, 0.15, 0.1), Offset: new Vector3(0.3, 0.45, -2.3) },
            { Size: new Vector3(0.08, 0.7, 0.08), Offset: new Vector3(-0.25, 0.7, -1.8) },
            { Size: new Vector3(0.15, 0.15, 0.15), Offset: new Vector3(-0.25, 1.1, -1.8) },
            { Size: new Vector3(0.08, 0.7, 0.08), Offset: new Vector3(0.25, 0.7, -1.8) },
            { Size: new Vector3(0.15, 0.15, 0.15), Offset: new Vector3(0.25, 1.1, -1.8) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.15, 0.8, 0.15), Offset: new Vector3(0, 0.2, 0) },
                { Size: new Vector3(0.12, 0.5, 0.12), Offset: new Vector3(0.05, -0.35, 0) },
            ],
            OffsetFL: new Vector3(1.0, -0.75, -1.1),
            PivotY: 0.55,
        },
    },

    BUNNY: {
        ID: "BUNNY",
        Name: "Bunny",
        BodyBlocks: [
            { Size: new Vector3(1.8, 1.9, 2.2), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(1.2, 1.0, 0.6), Offset: new Vector3(0, -0.2, -1.1) },
            { Size: new Vector3(1.7, 1.6, 1.2), Offset: new Vector3(0, 0.1, 1.0) },
            { Size: new Vector3(1.3, 1.0, 0.7), Offset: new Vector3(0, 0.6, 1.3) },
        ],
        HeadBlocks: [
            { Size: new Vector3(1.4, 1.3, 1.2), Offset: new Vector3(0, 0.6, -1.7) },
            { Size: new Vector3(0.55, 0.5, 0.4), Offset: new Vector3(-0.55, 0.3, -2.0) },
            { Size: new Vector3(0.55, 0.5, 0.4), Offset: new Vector3(0.55, 0.3, -2.0) },
            { Size: new Vector3(0.4, 0.3, 0.25), Offset: new Vector3(0, 0.25, -2.35) },
            { Size: new Vector3(0.2, 0.15, 0.1), Offset: new Vector3(0, 0.3, -2.5) },
            { Size: new Vector3(0.3, 1.6, 0.5), Offset: new Vector3(-0.4, 1.7, -1.5) },
            { Size: new Vector3(0.25, 1.3, 0.4), Offset: new Vector3(-0.4, 1.8, -1.5) },
            { Size: new Vector3(0.3, 1.6, 0.5), Offset: new Vector3(0.4, 1.7, -1.5) },
            { Size: new Vector3(0.25, 1.3, 0.4), Offset: new Vector3(0.4, 1.8, -1.5) },
            { Size: new Vector3(0.3, 0.35, 0.15), Offset: new Vector3(-0.35, 0.7, -2.25) },
            { Size: new Vector3(0.3, 0.35, 0.15), Offset: new Vector3(0.35, 0.7, -2.25) },
        ],
        TailBlocks: [
            { Size: new Vector3(0.6, 0.6, 0.5), Offset: new Vector3(0, 0.5, 1.8) },
            { Size: new Vector3(0.5, 0.5, 0.4), Offset: new Vector3(0.2, 0.65, 1.9) },
            { Size: new Vector3(0.5, 0.5, 0.4), Offset: new Vector3(-0.2, 0.65, 1.9) },
            { Size: new Vector3(0.4, 0.45, 0.35), Offset: new Vector3(0, 0.75, 1.95) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.5, 1.1, 0.55), Offset: new Vector3(0, 0, 0) },
                { Size: new Vector3(0.55, 0.25, 0.7), Offset: new Vector3(0, -0.55, -0.1) },
            ],
            OffsetFL: new Vector3(0.5, -1.35, -0.9),
            PivotY: 0.55,
        },
    },

    PIG: {
        ID: "PIG",
        Name: "Pig",
        BodyBlocks: [
            { Size: new Vector3(2.4, 2.2, 3.4), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(2.0, 0.8, 2.2), Offset: new Vector3(0, -0.95, 0) },
            { Size: new Vector3(1.8, 1.6, 1.0), Offset: new Vector3(0, 0.1, 1.5) },
        ],
        HeadBlocks: [
            { Size: new Vector3(1.5, 1.3, 1.2), Offset: new Vector3(0, 0.3, -2.0) },
            { Size: new Vector3(0.9, 0.7, 0.6), Offset: new Vector3(0, -0.05, -2.6) },
            { Size: new Vector3(0.5, 0.5, 0.15), Offset: new Vector3(0, -0.05, -2.95) },
            { Size: new Vector3(0.15, 0.15, 0.1), Offset: new Vector3(-0.12, -0.05, -3.0) },
            { Size: new Vector3(0.15, 0.15, 0.1), Offset: new Vector3(0.12, -0.05, -3.0) },
            { Size: new Vector3(0.15, 0.6, 0.7), Offset: new Vector3(-0.65, 0.7, -1.7) },
            { Size: new Vector3(0.15, 0.6, 0.7), Offset: new Vector3(0.65, 0.7, -1.7) },
            { Size: new Vector3(0.25, 0.3, 0.15), Offset: new Vector3(-0.4, 0.55, -2.5) },
            { Size: new Vector3(0.25, 0.3, 0.15), Offset: new Vector3(0.4, 0.55, -2.5) },
        ],
        TailBlocks: [
            { Size: new Vector3(0.15, 0.2, 0.25), Offset: new Vector3(0, 0.6, 2.0) },
            { Size: new Vector3(0.2, 0.15, 0.15), Offset: new Vector3(0.12, 0.7, 2.15) },
            { Size: new Vector3(0.15, 0.2, 0.15), Offset: new Vector3(0.15, 0.6, 2.25) },
            { Size: new Vector3(0.2, 0.15, 0.15), Offset: new Vector3(0.05, 0.5, 2.3) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.55, 1.0, 0.55), Offset: new Vector3(0, 0.15, 0) },
                { Size: new Vector3(0.6, 0.3, 0.6), Offset: new Vector3(0, -0.45, 0) },
            ],
            OffsetFL: new Vector3(0.75, -1.25, -1.3),
            PivotY: 0.6,
        },
    },

    TURTLE: {
        ID: "TURTLE",
        Name: "Turtle",
        BodyBlocks: [
            { Size: new Vector3(2.0, 0.7, 2.8), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(2.4, 0.7, 3.0), Offset: new Vector3(0, 0.55, 0) },
            { Size: new Vector3(2.1, 0.6, 2.6), Offset: new Vector3(0, 1.05, 0) },
            { Size: new Vector3(1.7, 0.5, 2.1), Offset: new Vector3(0, 1.45, 0) },
            { Size: new Vector3(1.2, 0.4, 1.5), Offset: new Vector3(0, 1.75, 0) },
            { Size: new Vector3(0.7, 0.3, 0.9), Offset: new Vector3(0, 1.95, 0) },
            { Size: new Vector3(0.7, 0.15, 0.7), Offset: new Vector3(0, 2.1, 0) },
            { Size: new Vector3(0.5, 0.12, 0.5), Offset: new Vector3(0.6, 1.65, 0.6) },
            { Size: new Vector3(0.5, 0.12, 0.5), Offset: new Vector3(-0.6, 1.65, 0.6) },
            { Size: new Vector3(0.5, 0.12, 0.5), Offset: new Vector3(0.6, 1.65, -0.6) },
            { Size: new Vector3(0.5, 0.12, 0.5), Offset: new Vector3(-0.6, 1.65, -0.6) },
        ],
        HeadBlocks: [
            { Size: new Vector3(0.5, 0.45, 0.8), Offset: new Vector3(0, 0.15, -1.7) },
            { Size: new Vector3(0.8, 0.7, 0.7), Offset: new Vector3(0, 0.3, -2.2) },
            { Size: new Vector3(0.2, 0.25, 0.15), Offset: new Vector3(-0.25, 0.5, -2.45) },
            { Size: new Vector3(0.2, 0.25, 0.15), Offset: new Vector3(0.25, 0.5, -2.45) },
            { Size: new Vector3(0.3, 0.2, 0.2), Offset: new Vector3(0, 0.15, -2.55) },
        ],
        TailBlocks: [
            { Size: new Vector3(0.3, 0.25, 0.6), Offset: new Vector3(0, 0.05, 1.6) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.7, 0.35, 0.9), Offset: new Vector3(0, 0, 0) },
            ],
            OffsetFL: new Vector3(0.95, -0.5, -1.0),
            PivotY: 0.18,
        },
    },

    CRAB: {
        ID: "CRAB",
        Name: "Crab",
        BodyBlocks: [
            { Size: new Vector3(3.2, 1.0, 2.2), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(2.6, 0.6, 1.8), Offset: new Vector3(0, 0.65, 0) },
            { Size: new Vector3(1.8, 0.4, 1.2), Offset: new Vector3(0, 1.0, 0) },
        ],
        HeadBlocks: [
            { Size: new Vector3(0.15, 0.6, 0.15), Offset: new Vector3(-0.5, 0.7, -0.9) },
            { Size: new Vector3(0.15, 0.6, 0.15), Offset: new Vector3(0.5, 0.7, -0.9) },
            { Size: new Vector3(0.35, 0.35, 0.35), Offset: new Vector3(-0.5, 1.15, -0.9) },
            { Size: new Vector3(0.35, 0.35, 0.35), Offset: new Vector3(0.5, 1.15, -0.9) },
            { Size: new Vector3(0.15, 0.2, 0.1), Offset: new Vector3(-0.5, 1.15, -1.1) },
            { Size: new Vector3(0.15, 0.2, 0.1), Offset: new Vector3(0.5, 1.15, -1.1) },
        ],
        DecorationBlocks: [
            { Size: new Vector3(0.4, 0.4, 1.2), Offset: new Vector3(-1.8, 0.3, -0.5) },
            { Size: new Vector3(0.7, 0.5, 0.9), Offset: new Vector3(-2.0, 0.4, -1.4) },
            { Size: new Vector3(0.25, 0.6, 0.5), Offset: new Vector3(-2.0, 0.65, -1.8) },
            { Size: new Vector3(0.2, 0.35, 0.45), Offset: new Vector3(-2.0, 0.15, -1.75) },
            { Size: new Vector3(0.4, 0.4, 1.2), Offset: new Vector3(1.8, 0.3, -0.5) },
            { Size: new Vector3(0.7, 0.5, 0.9), Offset: new Vector3(2.0, 0.4, -1.4) },
            { Size: new Vector3(0.25, 0.6, 0.5), Offset: new Vector3(2.0, 0.65, -1.8) },
            { Size: new Vector3(0.2, 0.35, 0.45), Offset: new Vector3(2.0, 0.15, -1.75) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.15, 0.7, 0.15), Offset: new Vector3(0, 0.15, 0) },
                { Size: new Vector3(0.12, 0.4, 0.12), Offset: new Vector3(0, -0.35, 0) },
            ],
            OffsetFL: new Vector3(1.3, -0.7, -0.6),
            PivotY: 0.45,
        },
    },

    COW: {
        ID: "COW",
        Name: "Cow",
        BodyBlocks: [
            { Size: new Vector3(2.6, 2.4, 4.2), Offset: new Vector3(0, 0, 0) },
            { Size: new Vector3(2.0, 0.7, 2.4), Offset: new Vector3(0, -1.05, 0) },
            { Size: new Vector3(1.6, 0.5, 1.8), Offset: new Vector3(0, 1.2, 0.5) },
        ],
        HeadBlocks: [
            { Size: new Vector3(1.4, 1.2, 1.4), Offset: new Vector3(0, 0.35, -2.5) },
            { Size: new Vector3(1.0, 0.8, 0.6), Offset: new Vector3(0, -0.1, -3.1) },
            { Size: new Vector3(0.7, 0.5, 0.2), Offset: new Vector3(0, -0.1, -3.45) },
            { Size: new Vector3(0.15, 0.2, 0.1), Offset: new Vector3(-0.15, -0.1, -3.5) },
            { Size: new Vector3(0.15, 0.2, 0.1), Offset: new Vector3(0.15, -0.1, -3.5) },
            { Size: new Vector3(0.2, 0.6, 0.2), Offset: new Vector3(-0.6, 1.0, -2.3) },
            { Size: new Vector3(0.15, 0.35, 0.15), Offset: new Vector3(-0.7, 1.4, -2.2) },
            { Size: new Vector3(0.2, 0.6, 0.2), Offset: new Vector3(0.6, 1.0, -2.3) },
            { Size: new Vector3(0.15, 0.35, 0.15), Offset: new Vector3(0.7, 1.4, -2.2) },
            { Size: new Vector3(0.15, 0.35, 0.6), Offset: new Vector3(-0.75, 0.5, -2.2) },
            { Size: new Vector3(0.15, 0.35, 0.6), Offset: new Vector3(0.75, 0.5, -2.2) },
            { Size: new Vector3(0.3, 0.35, 0.15), Offset: new Vector3(-0.4, 0.6, -3.0) },
            { Size: new Vector3(0.3, 0.35, 0.15), Offset: new Vector3(0.4, 0.6, -3.0) },
        ],
        TailBlocks: [
            { Size: new Vector3(0.15, 0.15, 1.0), Offset: new Vector3(0, 0.4, 2.5) },
            { Size: new Vector3(0.12, 0.12, 0.6), Offset: new Vector3(0, 0.2, 3.1) },
            { Size: new Vector3(0.3, 0.4, 0.25), Offset: new Vector3(0, 0.05, 3.5) },
        ],
        Legs: {
            Blocks: [
                { Size: new Vector3(0.55, 1.5, 0.55), Offset: new Vector3(0, 0.1, 0) },
                { Size: new Vector3(0.6, 0.35, 0.6), Offset: new Vector3(0, -0.65, 0) },
            ],
            OffsetFL: new Vector3(0.85, -1.55, -1.7),
            PivotY: 0.85,
        },
    },
};

function exportToOBJ(template) {
    const lines = [];
    lines.push(`# Animal Template: ${template.Name}`);
    lines.push('# Exported from AnimalTemplates');
    lines.push('# Import into Blender: File > Import > Wavefront (.obj)');
    lines.push('');

    let vertexIndex = 1;

    function addCube(name, size, offset) {
        lines.push(`o ${name}`);

        const hx = size.X / 2, hy = size.Y / 2, hz = size.Z / 2;
        const cx = offset.X, cy = offset.Y, cz = offset.Z;

        // 8 vertices of the cube
        lines.push(`v ${(cx - hx).toFixed(4)} ${(cy - hy).toFixed(4)} ${(cz - hz).toFixed(4)}`);
        lines.push(`v ${(cx + hx).toFixed(4)} ${(cy - hy).toFixed(4)} ${(cz - hz).toFixed(4)}`);
        lines.push(`v ${(cx + hx).toFixed(4)} ${(cy + hy).toFixed(4)} ${(cz - hz).toFixed(4)}`);
        lines.push(`v ${(cx - hx).toFixed(4)} ${(cy + hy).toFixed(4)} ${(cz - hz).toFixed(4)}`);
        lines.push(`v ${(cx - hx).toFixed(4)} ${(cy - hy).toFixed(4)} ${(cz + hz).toFixed(4)}`);
        lines.push(`v ${(cx + hx).toFixed(4)} ${(cy - hy).toFixed(4)} ${(cz + hz).toFixed(4)}`);
        lines.push(`v ${(cx + hx).toFixed(4)} ${(cy + hy).toFixed(4)} ${(cz + hz).toFixed(4)}`);
        lines.push(`v ${(cx - hx).toFixed(4)} ${(cy + hy).toFixed(4)} ${(cz + hz).toFixed(4)}`);

        // 6 faces (quads)
        const v = vertexIndex;
        lines.push(`f ${v+0} ${v+1} ${v+2} ${v+3}`);  // front
        lines.push(`f ${v+5} ${v+4} ${v+7} ${v+6}`);  // back
        lines.push(`f ${v+4} ${v+0} ${v+3} ${v+7}`);  // left
        lines.push(`f ${v+1} ${v+5} ${v+6} ${v+2}`);  // right
        lines.push(`f ${v+3} ${v+2} ${v+6} ${v+7}`);  // top
        lines.push(`f ${v+4} ${v+5} ${v+1} ${v+0}`);  // bottom

        lines.push('');
        vertexIndex += 8;
    }

    // Export body blocks
    template.BodyBlocks.forEach((block, i) => {
        addCube(`Body_${i + 1}`, block.Size, block.Offset);
    });

    // Export head blocks
    if (template.HeadBlocks) {
        template.HeadBlocks.forEach((block, i) => {
            addCube(`Head_${i + 1}`, block.Size, block.Offset);
        });
    }

    // Export tail blocks
    if (template.TailBlocks) {
        template.TailBlocks.forEach((block, i) => {
            addCube(`Tail_${i + 1}`, block.Size, block.Offset);
        });
    }

    // Export decoration blocks
    if (template.DecorationBlocks) {
        template.DecorationBlocks.forEach((block, i) => {
            addCube(`Deco_${i + 1}`, block.Size, block.Offset);
        });
    }

    // Export legs (all 4)
    const legConfig = template.Legs;
    const ofl = legConfig.OffsetFL;

    legConfig.Blocks.forEach((block, i) => {
        addCube(`LegFL_${i + 1}`, block.Size, ofl.add(block.Offset));
        addCube(`LegFR_${i + 1}`, block.Size, new Vector3(-ofl.X, ofl.Y, ofl.Z).add(block.Offset));
        addCube(`LegBL_${i + 1}`, block.Size, new Vector3(ofl.X, ofl.Y, -ofl.Z).add(block.Offset));
        addCube(`LegBR_${i + 1}`, block.Size, new Vector3(-ofl.X, ofl.Y, -ofl.Z).add(block.Offset));
    });

    return lines.join('\n');
}

function main() {
    console.log('Animal Template OBJ Exporter');
    console.log('============================');
    console.log('');

    // Create output directory
    const outputDir = path.join(__dirname, 'animal_models');
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    const templateIds = ['DEFAULT', 'FLUFFY', 'SLIME', 'BEETLE', 'BUNNY', 'PIG', 'TURTLE', 'CRAB', 'COW'];

    for (const templateId of templateIds) {
        if (TEMPLATES[templateId]) {
            const template = TEMPLATES[templateId];
            const filename = path.join(outputDir, `Animal_${templateId}.obj`);
            const content = exportToOBJ(template);

            fs.writeFileSync(filename, content);
            console.log(`Created: ${filename}`);
        } else {
            console.log(`WARNING: Template ${templateId} not found`);
        }
    }

    console.log('');
    console.log(`Export complete! OBJ files saved to: ${outputDir}`);
    console.log('');
    console.log('Tips for Blender:');
    console.log('  - Import via File > Import > Wavefront (.obj)');
    console.log('  - Select all objects and Join (Ctrl+J) to combine');
    console.log('  - Use "Shade Smooth" for smoother look');
    console.log('  - Add subdivision surface modifier for rounder shapes');
}

main();
