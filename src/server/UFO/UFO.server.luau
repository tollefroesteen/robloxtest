local UFOController = require(game.ServerScriptService.Server.UFO.UFOController)

-- Example: controlling the UFO model in Workspace
local UFOModel = workspace:WaitForChild("UFO")
local config = {
	minX = -100, maxX = 100,
	minY = 10, maxY = 60,
	minZ = -60, maxZ = 60,
	speed = 10,
	waitTime = 2,
	maxTilt = math.rad(15)
}

local controller = UFOController.New(UFOModel, config)
controller:Start()
