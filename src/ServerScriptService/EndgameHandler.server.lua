local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStore = require(ReplicatedStorage.DataStore)
local WinsEvent = ReplicatedStorage.Remotes.UI.WinsButton

local CP1 = game.Workspace.CheckPoints:FindFirstChild("1").PrimaryPart

WinsEvent.OnServerEvent:Connect(function(player)
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		
		DataStore.AddWins(player, 1)
		DataStore.SetCheckpoint(player, 1)
		humanoidRootPart.CFrame = CP1.CFrame + Vector3.new(0, 5, 0)
	end
end)

