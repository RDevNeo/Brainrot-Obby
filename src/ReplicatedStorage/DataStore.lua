local module = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = workspace

local GetPlayerPetsRF = ReplicatedStorage:FindFirstChild("GetPlayerPets")
local HelperModule = ReplicatedStorage:FindFirstChild("Helper") and require(ReplicatedStorage.Helper)


local checkpointDataStore = DataStoreService:GetDataStore("CheckpointData_V2")
local WinsDataStore = DataStoreService:GetDataStore("WinsData_V2")
local ownedPetsDataStore = DataStoreService:GetDataStore("OwnedPetsData_V2")
local badgeDataStore = DataStoreService:GetDataStore("PlayerBadges_V2")
local leaderboardWinsDataStore = DataStoreService:GetOrderedDataStore("LeaderboardWins_V2")

local playerBadges = {}
local playerOwnedPets = {}
local playerDataLoaded = {}

local function SavePlayerPets(player)
	if not player or not player.UserId then 
		warn("SavePlayerPets: Invalid player")
		return false
	end

	if not playerOwnedPets[player.UserId] then 
		warn("SavePlayerPets: No pet data for player " .. player.Name)
		return false
	end

	local success, err = pcall(function()
		ownedPetsDataStore:SetAsync(player.UserId, playerOwnedPets[player.UserId])
	end)

	if not success then
		warn("Failed to save pets for " .. player.Name .. ": " .. tostring(err))
		return false
	end

	return true
end

local function LoadPlayerData(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Wins = Instance.new("NumberValue")
	Wins.Name = "Wins"
	Wins.Value = 0
	Wins.Parent = leaderstats

	local checkpoint = Instance.new("NumberValue")
	checkpoint.Name = "Checkpoint"
	checkpoint.Value = 0
	checkpoint.Parent = leaderstats

	local successCheckpoint, checkpointData = pcall(function()
		return checkpointDataStore:GetAsync(player.UserId)
	end)
	checkpoint.Value = (successCheckpoint and checkpointData) or 0

	local successWins, WinsData = pcall(function()
		return WinsDataStore:GetAsync(player.UserId)
	end)
	Wins.Value = (successWins and WinsData) or 0

	local successBadges, badgeData = pcall(function()
		return badgeDataStore:GetAsync(player.UserId)
	end)
	playerBadges[player.UserId] = (successBadges and badgeData) or {}

	local successPets, savedPets = pcall(function()
		return ownedPetsDataStore:GetAsync(player.UserId)
	end)

	if successPets and savedPets and type(savedPets) == "table" then
		playerOwnedPets[player.UserId] = savedPets
	else
		playerOwnedPets[player.UserId] = {}
	end

	

	playerDataLoaded[player.UserId] = true
end

local function SavePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local checkpoint = leaderstats:FindFirstChild("Checkpoint")
	if checkpoint then
		pcall(function()
			checkpointDataStore:SetAsync(player.UserId, checkpoint.Value)
		end)
	end

	local Wins = leaderstats:FindFirstChild("Wins")
	if Wins then
		pcall(function()
			WinsDataStore:SetAsync(player.UserId, Wins.Value)
			leaderboardWinsDataStore:SetAsync(player.UserId, Wins.Value) -- Save to ordered data store
		end)
	end

	local badges = playerBadges[player.UserId]
	if badges then
		pcall(function()
			badgeDataStore:SetAsync(player.UserId, badges)
		end)
	end

	SavePlayerPets(player)

	playerBadges[player.UserId] = nil
	playerOwnedPets[player.UserId] = nil
	playerDataLoaded[player.UserId] = nil
end

function module.SetCheckpoint(player, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local checkpoint = leaderstats:FindFirstChild("Checkpoint")
		if checkpoint then checkpoint.Value = value end
	end
end

function module.GetCheckpoint(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local checkpoint = leaderstats:FindFirstChild("Checkpoint")
		return checkpoint and checkpoint.Value or 0
	end
	return 0
end

function module.GetWins(player)
	if not player then return 0 end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Wins = leaderstats:FindFirstChild("Wins")
		return Wins and Wins.Value or 0
	end
	return 0
end

function module.SetWins(player, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Wins = leaderstats:FindFirstChild("Wins")
		if Wins then Wins.Value = value end
	end
end

function module.AddWins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Wins = leaderstats:FindFirstChild("Wins")
		if Wins then 
			Wins.Value = Wins.Value + amount 
			pcall(function()
				leaderboardWinsDataStore:SetAsync(player.UserId, Wins.Value)
			end)
		end
	end
end

function module.SavePlayerBadge(player, badgeId)
	if not playerBadges[player.UserId] then
		playerBadges[player.UserId] = {}
	end
	playerBadges[player.UserId][tostring(badgeId)] = true
	pcall(function()
		badgeDataStore:SetAsync(player.UserId, playerBadges[player.UserId])
	end)
end

function module.PlayerHasBadge(player, badgeId)
	return playerBadges[player.UserId] and playerBadges[player.UserId][tostring(badgeId)]
end

function module.GivePet(player, petName)
	if not player or not player.UserId then
		warn("GivePet: Invalid player")
		return false
	end
	if not petName or petName == "" then
		warn("GivePet: Invalid pet name")
		return false
	end
	if not playerOwnedPets[player.UserId] then
		playerOwnedPets[player.UserId] = {}
	end
	if not table.find(playerOwnedPets[player.UserId], petName) then
		table.insert(playerOwnedPets[player.UserId], petName)
		return SavePlayerPets(player)
	else
		return true
	end
end

function module.RemovePet(player, petName)
	if not player or not player.UserId then
		warn("RemovePet: Invalid player")
		return false
	end

	if not playerOwnedPets[player.UserId] then 
		warn("RemovePet: No pet data for player " .. player.Name)
		return false
	end

	for i, name in ipairs(playerOwnedPets[player.UserId]) do
		if name == petName then
			table.remove(playerOwnedPets[player.UserId], i)
			return SavePlayerPets(player)
		end
	end

	warn("RemovePet: Pet '" .. petName .. "' not found for player " .. player.Name)
	return false
end

function module.RemoveAllPhysicalPets(player)
	if not player or not player.UserId then warn("RemoveAllPhysicalPets: Invalid player") return {} end

	local PlayerPetsWK = workspace:FindFirstChild("PlayerPets")
	if not PlayerPetsWK then warn("RemoveAllPhysicalPets: PlayerPets folder not found") return {} end

	local playerPetFolder = PlayerPetsWK:FindFirstChild(player.Name)
	if not playerPetFolder then warn("RemoveAllPhysicalPets: Player folder not found for " .. player.Name) return {} end

	for _, pets in pairs(playerPetFolder:GetChildren()) do
		pets:Destroy()
	end
end

function module.RemoveAllPets(player)
	if not player or not player.UserId then
		warn("RemoveAllPets: Invalid player")
		return false
	end

	playerOwnedPets[player.UserId] = {}

	module.RemoveAllPhysicalPets(player)

	SavePlayerPets(player)
end

function module.GetOwnedPets(player)
	if not player or not player.UserId then
		warn("GetOwnedPets: Invalid player")
		return {}
	end

	if not playerDataLoaded[player.UserId] then
		local attempts = 0
		while not playerDataLoaded[player.UserId] and attempts < 50 do
			task.wait(0.1)
			attempts = attempts + 1
		end

		if not playerDataLoaded[player.UserId] then
			warn("GetOwnedPets: Timeout waiting for data to load for " .. player.Name)
			return {}
		end
	end

	local pets = playerOwnedPets[player.UserId] or {}
	return pets
end

function module.PlayerHasPet(player, petName)
	if not player or not player.UserId then return false end
	local pets = playerOwnedPets[player.UserId]
	return pets and table.find(pets, petName) ~= nil
end

function module.IsPlayerDataLoaded(player)
	return playerDataLoaded[player.UserId] == true
end

Players.PlayerAdded:Connect(function(player)
	LoadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	SavePlayerData(player)
end)


GetPlayerPetsRF.OnServerInvoke = function(player)
	return module.GetOwnedPets(player)
end

return module
