-- ModuleScript: AnimalLibraryModule (Server Redirect)
-- This file redirects to the shared AnimalLibraryModule for data consistency
-- The actual animal data is now in shared/data/AnimalLibraryModule.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedAnimalLibrary = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("data"):WaitForChild("AnimalLibraryModule"))

-- Re-export the shared module so server scripts still work
return SharedAnimalLibrary
