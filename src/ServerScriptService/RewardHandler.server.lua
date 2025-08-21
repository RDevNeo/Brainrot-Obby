local rs = game:GetService("ReplicatedStorage")
local ds = require(rs.Modules.DataStore)
local RewardsData = require(rs.Modules.Rewards)
local Rewards = RewardsData.Rewards
local RewardsEvent = rs.Remotes.UI.Reward

RewardsEvent.OnServerEvent:Connect(function(player, rewardId)
	print("event - received")

	local reward = nil
	for _, rewardData in ipairs(Rewards) do
		if rewardData.id == rewardId then
			reward = rewardData
			break
		end
	end

	if not reward then 
		warn("Reward not found for ID: " .. tostring(rewardId))
		return 
	end
	print("reward exists")

	local coinsToReward = reward.coinsToReward
	if not coinsToReward then 
		warn("No coins to reward for ID: " .. tostring(rewardId))
		return 
	end

	print("coins to reward exists: " .. coinsToReward)

	ds.AddCoins(player, coinsToReward)
	print("coins given to " .. player.Name .. ": " .. coinsToReward)
end)