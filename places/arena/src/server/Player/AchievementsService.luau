--!strict
-- AchievementsService.luau (Arena Wrapper)
-- DEPRECATED: This file is now a pass-through to the shared AchievementsService
-- Use require(ReplicatedStorage.Shared.services.AchievementsService) directly in new code

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Return the shared service directly
return require(Shared:WaitForChild("services"):WaitForChild("AchievementsService"))
