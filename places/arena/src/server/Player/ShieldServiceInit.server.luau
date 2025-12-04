--!strict
-- ShieldServiceInit.server.luau
-- Initializes the ShieldService module

local ServerScriptService = game:GetService("ServerScriptService")

-- Simply requiring the ShieldService will initialize it
-- (connects the RemoteEvent listener)
require(ServerScriptService.Server.Player.ShieldService)
