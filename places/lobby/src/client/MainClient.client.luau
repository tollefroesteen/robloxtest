--!strict
-- MainClient.client.luau (Lobby)
-- Main entry point for lobby client-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

-- UI Controllers
local LobbyUIController = require(script.Parent:WaitForChild("LobbyUIController"))
local PlayerMenuController = require(Shared:WaitForChild("ui"):WaitForChild("PlayerMenuController"))
local PortalController = require(script.Parent:WaitForChild("PortalController"))
local LeaderboardController = require(script.Parent:WaitForChild("LeaderboardController"))
local MatchmakingController = require(script.Parent:WaitForChild("MatchmakingController"))

-- Visual Controllers
local PetFollowController = require(script.Parent:WaitForChild("PetFollowController"))

-- Shared Controllers
local LuckyBlockController = require(Shared:WaitForChild("controllers"):WaitForChild("LuckyBlockController"))

local CONTEXT = "LobbyClient"

local player = Players.LocalPlayer

Log.Info(CONTEXT, "Lobby client starting...")

-- Initialize lobby UI (stats display only - play button disabled)
LobbyUIController.Init()

-- Initialize player menu (press I to open)
PlayerMenuController.Init()

-- Initialize portal controller (countdown teleport to arena)
PortalController.Init()

-- Initialize pet follow controller (animates pet companions)
PetFollowController.Init()

-- Initialize leaderboard display (3D billboard)
LeaderboardController.Init()

-- Initialize matchmaking controller (1v1 and 2v2 queue UI)
MatchmakingController.Init()

-- Initialize Lucky Block controller (visual effects and animations)
LuckyBlockController.Initialize()

Log.Info(CONTEXT, "Lobby client initialized for " .. player.Name)
