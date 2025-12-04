--!strict
-- MainClient.client.luau (Lobby)
-- Main entry point for lobby client-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

-- UI Controllers
local LobbyUIController = require(script.Parent:WaitForChild("LobbyUIController"))
local PlayerMenuController = require(script.Parent:WaitForChild("ui"):WaitForChild("PlayerMenuController"))
local PortalController = require(script.Parent:WaitForChild("PortalController"))

local CONTEXT = "LobbyClient"

local player = Players.LocalPlayer

Log.Info(CONTEXT, "Lobby client starting...")

-- Initialize lobby UI (stats display only - play button disabled)
LobbyUIController.Init()

-- Initialize player menu (press I to open)
PlayerMenuController.Init()

-- Initialize portal controller (countdown teleport to arena)
PortalController.Init()

Log.Info(CONTEXT, "Lobby client initialized for " .. player.Name)
