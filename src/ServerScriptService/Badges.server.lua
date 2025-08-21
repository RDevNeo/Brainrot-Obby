local badge = game:GetService("BadgeService")
local rs = game:GetService("ReplicatedStorage")
local ds = require(rs.Modules.DataStore)
local badgesModule = require(rs.Modules.Badges)
local Badges = badgesModule.Items

local event = rs.Remotes.Checkpoint.CheckpointTouch

event.Event:Connect(function(checkpoint, player)
	local badgeCheckpoint = tostring(checkpoint)
	local badgeInfo = badgesModule.Items[badgeCheckpoint]
	if not badgeInfo then return end

	local badgeId = badgeInfo.badgeId
	if not ds.PlayerHasBadge(player,badgeId) then
		local success, err = pcall(function()
			game:GetService("BadgeService"):AwardBadge(player.UserId, badgeId)
		end)

		if success then
			ds.PlayerHasBadge(player, badgeId)
			ds.SavePlayerBadge(player, badgeId)
			print("Awarded badge", badgeId, "to", player.Name)
		else
			warn("Failed to award badge:", err)
		end
	end
end)
