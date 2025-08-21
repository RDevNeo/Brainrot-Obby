local rs = game:GetService("ReplicatedStorage")
local checkpointNotifier = rs:WaitForChild("Remotes").Checkpoint.CheckpointNotifier
local uiModule = require(rs:WaitForChild("Modules"):WaitForChild("UI"))

checkpointNotifier.OnClientEvent:Connect(function()
	uiModule.reachedCheckpoint()
end)