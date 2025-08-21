local Players = game:GetService("Players")
local checkpointFolder = workspace:WaitForChild("CheckPoints")
local rs = game:GetService("ReplicatedStorage")
local CheckpointEvent = rs.Remotes.Checkpoint.CheckpointTouch
local CheckpointNotifier = rs.Remotes.Checkpoint.CheckpointNotifier
local CoinsUIEvent = rs.Remotes.UI.ShowCoinsUI
local ds = require(rs.Modules.DataStore)

local CoinsQuantity = 10

local function onCheckpointTouched(player, checkpoint)
	local checkpointNumber = tonumber(checkpoint.Name)
	if not checkpointNumber then return end

	local currentCheckpoint = ds.GetCheckpoint(player)

	if checkpointNumber ~= (currentCheckpoint + 1) then return end

	ds.SetCheckpoint(player, checkpointNumber)


	local coinsAdded = ds.AddCoins(player, CoinsQuantity)
	CoinsUIEvent:FireClient(player, coinsAdded)

	CheckpointNotifier:FireClient(player)
	CheckpointEvent:Fire(checkpoint, player)

end

for _, checkpoint in ipairs(checkpointFolder:GetChildren()) do
	if checkpoint:IsA("Model") then
		local touchParts = {}
		if checkpoint.PrimaryPart then
			table.insert(touchParts, checkpoint.PrimaryPart)
		else
			for _, descendant in ipairs(checkpoint:GetDescendants()) do
				if descendant:IsA("BasePart") then
					table.insert(touchParts, descendant)
				end
			end
		end

		for _, part in ipairs(touchParts) do
			part.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then return end
				onCheckpointTouched(player, checkpoint)
			end)
		end
	end
end