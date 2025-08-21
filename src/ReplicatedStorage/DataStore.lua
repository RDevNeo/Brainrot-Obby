local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local badgeDataStore = DataStoreService:GetDataStore("PlayerBadges")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInventoryRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlayerInventory")

local HelperModule = require(ReplicatedStorage.Modules.Helper)
local GetPlayerPetsRF = ReplicatedStorage.Remotes.Pets.GetPlayerPets

local module = {}

local coinsDataStore = DataStoreService:GetDataStore("CoinsData")
local itemsDataStore = DataStoreService:GetDataStore("PurchasedItems")
local checkpointDataStore = DataStoreService:GetDataStore("CheckpointData")
local rebirthsDataStore = DataStoreService:GetDataStore("RebirthsData")
local ownedPetsDataStore = DataStoreService:GetDataStore("OwnedPetsData")

local playerOwnedItems = {}
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

	local success, errorMessage = pcall(function()
		ownedPetsDataStore:SetAsync(player.UserId, playerOwnedPets[player.UserId])
	end)

	if not success then
		warn("Failed to save pets for " .. player.Name .. ": " .. tostring(errorMessage))
		return false
	else
		print("Successfully saved pets for " .. player.Name)
		return true
	end
end

local function LoadPlayerData(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local checkpoint = Instance.new("NumberValue")
	checkpoint.Name = "Checkpoint"
	checkpoint.Value = 0
	checkpoint.Parent = leaderstats

	local rebirths = Instance.new("NumberValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local success, coinData = pcall(function()
		return coinsDataStore:GetAsync(player.UserId)
	end)
	coins.Value = (success and coinData) or 0

	local successCheckpoint, checkpointData = pcall(function()
		return checkpointDataStore:GetAsync(player.UserId)
	end)
	checkpoint.Value = (successCheckpoint and checkpointData) or 0

	local successItems, savedItems = pcall(function()
		return itemsDataStore:GetAsync(player.UserId)
	end)
	playerOwnedItems[player.UserId] = (successItems and savedItems) or {}

	local successRebirth, rebirthData = pcall(function()
		return rebirthsDataStore:GetAsync(player.UserId)
	end)
	rebirths.Value = (successRebirth and rebirthData) or 0

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

	local coins = leaderstats:FindFirstChild("Coins")
	if coins then
		pcall(function()
			coinsDataStore:SetAsync(player.UserId, coins.Value)
		end)
	end

	local checkpoint = leaderstats:FindFirstChild("Checkpoint")
	if checkpoint then
		pcall(function()
			checkpointDataStore:SetAsync(player.UserId, checkpoint.Value)
		end)
	end

	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if rebirths then
		pcall(function()
			rebirthsDataStore:SetAsync(player.UserId, rebirths.Value)
		end)
	end

	local items = playerOwnedItems[player.UserId]
	if items then
		pcall(function()
			itemsDataStore:SetAsync(player.UserId, items)
		end)
	end

	local badges = playerBadges[player.UserId]
	if badges then
		pcall(function()
			badgeDataStore:SetAsync(player.UserId, badges)
		end)
	end

	SavePlayerPets(player)

	playerDataLoaded[player.UserId] = nil
	playerOwnedItems[player.UserId] = nil
	playerBadges[player.UserId] = nil
	playerOwnedPets[player.UserId] = nil
end

function module.AddCoins(player, quantity)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end

	local coins = leaderstats:FindFirstChild("Coins")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if not coins then return 0 end

	local friendCount = 0
	if HelperModule and HelperModule.CountFriendsInServer then
		friendCount = HelperModule.CountFriendsInServer(player)
	end
	local friendBonus = 0.10 * friendCount

	local rebirthBonus = 0
	if rebirths and rebirths.Value > 0 then
		rebirthBonus = 0.10 * rebirths.Value
	end

	local total = math.floor(quantity * (1 + friendBonus + rebirthBonus))

	coins.Value += total

	return total
end

function module.RemoveCoins(player, quantity)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value -= quantity end
	end
end

function module.SetCoins(player, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value = value end
	end
end

function module.GetPlayerCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		return coins and coins.Value or 0
	end
	return 0
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

function module.GetRebirths(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		return rebirths and rebirths.Value or 0
	end
	return 0
end

function module.SetRebirths(player, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then rebirths.Value = value end
	end
end

function module.AddRebirth(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then rebirths.Value += amount end
	end
end

function module.PlayerHasItem(player, itemName)
	local items = playerOwnedItems[player.UserId]
	return items and table.find(items, itemName) ~= nil
end

function module.GiveItem(player, itemName)
	if not playerOwnedItems[player.UserId] then return end
	if not module.PlayerHasItem(player, itemName) then
		table.insert(playerOwnedItems[player.UserId], itemName)
	end
end

function module.GetOwnedItems(player)
	return playerOwnedItems[player.UserId] or {}
end

PlayerInventoryRemote.OnServerInvoke = function(player)
	return module.GetOwnedItems(player)
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
		print("Added pet '" .. petName .. "' to " .. player.Name)
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
			print("Removed pet '" .. petName .. "' from " .. player.Name)
			return SavePlayerPets(player)
		end
	end

	warn("RemovePet: Pet '" .. petName .. "' not found for player " .. player.Name)
	return false
end

function module.RemoveAllPhysicalPets(player)
	if not player or not player.UserId then warn("RemoveAllPhysicalPets: Invalid player") return {} end
	
	local PlayerPetsWK = game.Workspace:FindFirstChild("PlayerPets")
	if not PlayerPetsWK then warn("RemoveAllPhysicalPets: PlayerPets folder not found") return {} end
	
	local playerPetFolder = PlayerPetsWK:FindFirstChild(player.Name)
	if not playerPetFolder then warn("RemoveAllPhysicalPets: Player folder not found for " .. player.Name) return {} end
	
	for _, pets in pairs(playerPetFolder:GetChildren()) do
		pets:Destroy()
	end
end

function module.RemoveAllPets(player: Player)	
	
	if not player or not player.UserId then
		warn("RemoveAllPets: Invalid player")
		return false
	end

	playerOwnedPets[player.UserId] = {}
	print("Removed all pets from " .. player.Name)
	
	module.RemoveAllPhysicalPets(player)
	print("Removed all physicals pets from " .. player.Name)
	
	return SavePlayerPets(player)
end

function module.GetOwnedPets(player)
	if not player or not player.UserId then
		warn("GetOwnedPets: Invalid player")
		return {}
	end

	if not playerDataLoaded[player.UserId] then
		warn("GetOwnedPets: Data not loaded yet for " .. player.Name)
		local attempts = 0
		while not playerDataLoaded[player.UserId] and attempts < 50 do
			task.wait(0.1)
			attempts += 1
		end

		if not playerDataLoaded[player.UserId] then
			warn("GetOwnedPets: Timeout waiting for data to load for " .. player.Name)
			return {}
		end
	end

	local pets = playerOwnedPets[player.UserId] or {}
	print("GetOwnedPets returning for " .. player.Name .. ":", pets)
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

GetPlayerPetsRF.OnServerInvoke = function(player)
	local pets = module.GetOwnedPets(player)
	return pets
end

Players.PlayerAdded:Connect(LoadPlayerData)
Players.PlayerRemoving:Connect(function(player)
	SavePlayerData(player)
end)

return module