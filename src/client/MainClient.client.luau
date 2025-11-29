print("Hello world, from client!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for RemoteEvents module to be available
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))

-- Send a greeting to the server
RemoteEvents.GreetingEvent:FireServer("Hello from the client!")

-- Listen for server response
RemoteEvents.GreetingEvent.OnClientEvent:Connect(function(message)
	print("[Client] Received from server:", message)
end)
