--!strict
-- MainClient.client.luau (Lobby)
-- Main entry point for lobby client-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

local CONTEXT = "LobbyClient"

local player = Players.LocalPlayer

Log.Info(CONTEXT, "Lobby client starting...")

-- TODO: Initialize lobby UI controllers
-- - Stats display
-- - Inventory preview
-- - Shop UI
-- - Matchmaking/Play button
-- - Leaderboards

Log.Info(CONTEXT, "Lobby client initialized for " .. player.Name)
