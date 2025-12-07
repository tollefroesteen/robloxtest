--!strict
-- ExportTemplates.server.luau
-- Run this script to export all animal templates to OBJ format
-- Copy the output and save to .obj files for Blender import
--
-- To use: 
-- 1. Run this script in Roblox Studio (it will only run once)
-- 2. Check the Output window for the OBJ data
-- 3. Copy each template's OBJ content and save as TemplateName.obj
-- 4. Import into Blender: File > Import > Wavefront (.obj)

-- DISABLED: Set to false to enable this script
local DISABLED = true
if DISABLED then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimalTemplates = require(Shared:WaitForChild("data"):WaitForChild("AnimalTemplates"))

-- Only run once (disable after first run)
local hasRun = script:GetAttribute("HasRun")
if hasRun then
	return
end
script:SetAttribute("HasRun", true)

print("\n" .. string.rep("=", 60))
print("ANIMAL TEMPLATE OBJ EXPORTER")
print(string.rep("=", 60))

-- Export all templates
local exports = AnimalTemplates.ExportAllToOBJ()

for templateID, objContent in exports do
	print("\n")
	print(string.rep("-", 60))
	print("TEMPLATE: " .. templateID)
	print("Copy everything between the START and END markers below:")
	print(string.rep("-", 60))
	print("--- START " .. templateID .. ".obj ---")
	print(objContent)
	print("--- END " .. templateID .. ".obj ---")
end

print("\n" .. string.rep("=", 60))
print("Export complete! Copy each template and save as .obj files")
print(string.rep("=", 60) .. "\n")
