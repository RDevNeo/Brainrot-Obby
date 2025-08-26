local rs = game:GetService("ReplicatedStorage")
local ds = require(rs.DataStore)
local hlp = require(rs.Helper)
local Players = game:GetService("Players")
local scrollingFrame = game.Workspace.Ranks.Coins.Screen.SurfaceGui.Canvas.ScrollingFrame
local DataStoreService = game:GetService("DataStoreService")
local leaderboardCoinsDataStore = DataStoreService:GetOrderedDataStore("LeaderboardCoins_V2")

local function GetAllCoins()
	local playersCoins = {}

	local success, pages = pcall(function()
		return leaderboardCoinsDataStore:GetSortedAsync(false, 100)
	end)

	if success then
		local data = pages:GetCurrentPage()
		for _, entry in pairs(data) do
			local userId = entry.key
			local coins = entry.value

			local username = Players:GetNameFromUserIdAsync(userId)
			local player = Players:GetPlayerByUserId(userId)

			table.insert(playersCoins, {
				Player = player or username,
				Coins = coins,
				UserId = userId
			})
		end
	else
		warn("Failed to get sorted leaderboard data.", pages)
	end

	return playersCoins
end

local function UpdateLeaderboard()
	local sortedPlayersCoins = GetAllCoins()

	for _, frame in pairs(scrollingFrame:GetChildren()) do
		if frame:IsA("Frame") then
			local position = tonumber(frame.Name)
			if position ~= nil then
				local playerIndex = position + 1
				if sortedPlayersCoins[playerIndex] then
					local data = sortedPlayersCoins[playerIndex]

					local playerImage:ImageLabel = frame:FindFirstChild("1PlayerThumbnail")
					local playerName:TextLabel = frame:FindFirstChild("2PlayerName")
					local playerCoins:TextLabel = frame:FindFirstChild("3PlayerCheckpoint")

					if playerImage then
						playerImage.Image = Players:GetUserThumbnailAsync(
							data.UserId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size48x48
						)
					end
					if playerName then
						playerName.Text = tostring(data.Player.Name or data.Player)
					end
					if playerCoins then
						local playercoinsFromatted = hlp.FormatCurrency(data.Coins)
						playerCoins.Text = tostring(playercoinsFromatted)
					end
				end
			end
		else
			local playerImage:ImageLabel = frame:FindFirstChild("1PlayerThumbnail")
			local playerName:TextLabel = frame:FindFirstChild("2PlayerName")
			local playerCoins:TextLabel = frame:FindFirstChild("3PlayerCheckpoint")

			if playerImage then playerImage.Image = "" end
			if playerName then playerName.Text = "N/A" end
			if playerCoins then playerCoins.Text = "0" end
		end
	end
end

local function ConnectPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins:GetPropertyChangedSignal("Value"):Connect(UpdateLeaderboard)
		end
	end
end

for _, player in pairs(Players:GetPlayers()) do
	ConnectPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
	ConnectPlayer(player)
end)

Players.PlayerRemoving:Connect(UpdateLeaderboard)

UpdateLeaderboard()
task.delay(5, UpdateLeaderboard)
