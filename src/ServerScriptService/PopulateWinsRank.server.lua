local rs = game:GetService("ReplicatedStorage")
local ds = require(rs.DataStore)
local hlp = require(rs.Helper)
local Players = game:GetService("Players")
local scrollingFrame = game.Workspace.Ranks.Wins.Screen.SurfaceGui.Canvas.ScrollingFrame
local DataStoreService = game:GetService("DataStoreService")
local leaderboardWinsDataStore = DataStoreService:GetOrderedDataStore("LeaderboardWins_V2")

local function GetAllWins()
	local playersWins = {}

	local success, pages = pcall(function()
		return leaderboardWinsDataStore:GetSortedAsync(false, 100)
	end)

	if success and pages then
		local data = pages:GetCurrentPage()
		for _, entry in pairs(data) do
			local rawKey = entry.key
			local userId = tonumber(rawKey) or rawKey
			local wins = entry.value

			local username
			local okName, nameErr = pcall(function()
				username = Players:GetNameFromUserIdAsync(userId)
			end)
			if not okName then
				username = tostring(userId)
			end

			local player = Players:GetPlayerByUserId(tonumber(userId) or -1)

			table.insert(playersWins, {
				Player = player or username,
				Wins = wins,
				UserId = tonumber(userId) or userId
			})
		end
	else
		warn("Failed to get sorted leaderboard data.", pages)
	end

	return playersWins
end

local function UpdateLeaderboard()
	local sortedPlayersWins = GetAllWins()

	for _, frame in pairs(scrollingFrame:GetChildren()) do
		if frame:IsA("Frame") then
			local position = tonumber(frame.Name)
			if position ~= nil then
				local playerIndex = position + 1
				if sortedPlayersWins[playerIndex] then
					local data = sortedPlayersWins[playerIndex]

					local playerImage:ImageLabel = frame:FindFirstChild("1PlayerThumbnail")
					local playerName:TextLabel = frame:FindFirstChild("2PlayerName")
					local playerWins:TextLabel = frame:FindFirstChild("3PlayerCheckpoint")

					if playerImage then
						local uid = tonumber(data.UserId) or data.UserId
						local okThumb, thumb = pcall(function()
							return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
						end)
						if okThumb and thumb then
							playerImage.Image = thumb
						else
							playerImage.Image = ""
						end
					end

					if playerName then
						playerName.Text = tostring((type(data.Player) == "userdata" and data.Player.Name) or data.Player)
					end

					if playerWins then
						local playerwinsFromatted = hlp.FormatCurrency(data.Wins)
						playerWins.Text = tostring(playerwinsFromatted)
					end
				else
					local playerImage:ImageLabel = frame:FindFirstChild("1PlayerThumbnail")
					local playerName:TextLabel = frame:FindFirstChild("2PlayerName")
					local playerWins:TextLabel = frame:FindFirstChild("3PlayerCheckpoint")

					if playerImage then playerImage.Image = "" end
					if playerName then playerName.Text = "Loading..." end
					if playerWins then playerWins.Text = "Loading..." end
				end
			end
		end
	end
end

local function ConnectPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local wins = leaderstats:FindFirstChild("Wins")
		if wins then
			wins:GetPropertyChangedSignal("Value"):Connect(UpdateLeaderboard)
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
