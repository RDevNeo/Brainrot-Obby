local blackwallModel = game.Workspace.End.BlackWall
local StartEndgameAnimation = game.ReplicatedStorage.Remotes.UI.EndGameAnimation

local playerDebounce = {}
local DEBOUNCE_TIME = 30

for _, parts in pairs(blackwallModel:GetChildren()) do
	if parts:IsA("BasePart") then
		parts.Touched:Connect(function(hit)
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				local playerCheckpoint = player.leaderstats.Checkpoint.Value
				if playerCheckpoint == 30 then
					local currentTime = tick()
					local lastTriggerTime = playerDebounce[player.UserId]

					if not lastTriggerTime or (currentTime - lastTriggerTime) >= DEBOUNCE_TIME then
						playerDebounce[player.UserId] = currentTime
						StartEndgameAnimation:FireClient(player)
					end
				end
			end
		end)
	end
end

game.Players.PlayerRemoving:Connect(function(player)
	playerDebounce[player.UserId] = nil
end)