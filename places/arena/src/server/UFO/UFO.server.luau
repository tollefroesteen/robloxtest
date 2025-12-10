local UFOController = require(game.ServerScriptService.Server.UFO.UFOController)
local UFOBuilder = require(game.ServerScriptService.Server.UFO.UFOBuilder)

-- Build the UFO model from code
local spawnPosition = Vector3.new(0, 35, 0)
local UFOModel = UFOBuilder.Build(spawnPosition, {
	saucerSize = 26,
	saucerFlatness = 0.18,
	saucerColor = Color3.fromRGB(118, 132, 150),
	domeSize = 13,
	domeColor = Color3.fromRGB(165, 200, 255),
	rimColor = Color3.fromRGB(0, 255, 190),
	lightCount = 12,
	lightRadius = 13,
	lightColor = Color3.fromRGB(255, 120, 150),
	engineColor = Color3.fromRGB(0, 200, 255),
})
UFOModel.Parent = workspace

-- Start ambient light animations
UFOBuilder.StartAmbientAnimation(UFOModel)

-- Configure UFO movement
local config = {
	minX = -150, maxX = 150,
	minY = 40, maxY = 80,
	minZ = -150, maxZ = 150,
	speed = 20,
	waitTime = 2,
	maxTilt = math.rad(15)
}

local controller = UFOController.New(UFOModel, config)
controller:Start()
