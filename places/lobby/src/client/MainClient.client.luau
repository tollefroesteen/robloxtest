--!strict
-- MainClient.client.luau (Lobby)
-- Main entry point for lobby client-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("util"):WaitForChild("Log"))

-- UI Controllers
local LobbyUIController = require(script.Parent:WaitForChild("LobbyUIController"))

local CONTEXT = "LobbyClient"

local player = Players.LocalPlayer

Log.Info(CONTEXT, "Lobby client starting...")

-- Initialize lobby UI
LobbyUIController.Init()

Log.Info(CONTEXT, "Lobby client initialized for " .. player.Name)
