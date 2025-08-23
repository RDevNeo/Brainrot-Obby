local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStore = require(ReplicatedStorage.DataStore)
local RebirthEvent = ReplicatedStorage.Remotes.UI.RebirthButton
local NoRebirthEvent = ReplicatedStorage.Remotes.UI.noRebirthButton
local RebirthShowPets = ReplicatedStorage.Remotes.Pets.RebirthShowPets

local CP1 = game.Workspace.CheckPoints:FindFirstChild("1").PrimaryPart

RebirthEvent.OnServerEvent:Connect(function(player)
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		
		DataStore.AddRebirth(player, 1)
		DataStore.SetCheckpoint(player, 1)
		DataStore.RemoveAllPets(player)
		
		humanoidRootPart.CFrame = CP1.CFrame + Vector3.new(0, 5, 0)
		RebirthShowPets:FireClient(player)
	end
end)


NoRebirthEvent.OnServerEvent:Connect(function(player)
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CFrame = CP1.CFrame + Vector3.new(0, 5, 0)
	end
	
end)
