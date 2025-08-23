local rs = game:GetService("ReplicatedStorage")
local ds = require(rs.DataStore)
local RewardsData = require(rs.Rewards)
local Rewards = RewardsData.Rewards
local RewardsEvent = rs.Remotes.UI.Reward

RewardsEvent.OnServerEvent:Connect(function(player, rewardId)

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

	local coinsToReward = reward.coinsToReward
	if not coinsToReward then 
		warn("No coins to reward for ID: " .. tostring(rewardId))
		return 
	end

	ds.AddCoins(player, coinsToReward)
end)