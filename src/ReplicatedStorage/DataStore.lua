-- Full Player Data + Pet Mutations Module (wait-for-Pets robustness + clearer apply logs)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = workspace

local PlayerInventoryRemote = ReplicatedStorage:FindFirstChild("PlayerInventory")
local GetPlayerPetsRF = ReplicatedStorage:FindFirstChild("GetPlayerPets")
local HelperModule = ReplicatedStorage:FindFirstChild("Helper") and require(ReplicatedStorage.Helper)
local PetMutations = require(ReplicatedStorage.PetMutations)

local GetPlayerPetsBuffs = ReplicatedStorage:FindFirstChild("GetPlayerPetsBuffs") or Instance.new("RemoteFunction")
if not GetPlayerPetsBuffs.Parent then
	GetPlayerPetsBuffs.Name = "GetPlayerPetsBuffs"
	GetPlayerPetsBuffs.Parent = ReplicatedStorage
end

local module = {}

-- DataStores
local coinsDataStore = DataStoreService:GetDataStore("CoinsData_V2")
local itemsDataStore = DataStoreService:GetDataStore("PurchasedItems_V2")
local checkpointDataStore = DataStoreService:GetDataStore("CheckpointData_V2")
local WinsDataStore = DataStoreService:GetDataStore("WinsData_V2")
local ownedPetsDataStore = DataStoreService:GetDataStore("OwnedPetsData_V2")
local goldenCoinsDataStore = DataStoreService:GetDataStore("GoldenCoinsData_V2")
local petMutationsDataStore = DataStoreService:GetDataStore("PetMutationsData_V2")
local badgeDataStore = DataStoreService:GetDataStore("PlayerBadges_V2")
local leaderboardCoinsDataStore = DataStoreService:GetOrderedDataStore("LeaderboardCoins_V2")
local leaderboardWinsDataStore = DataStoreService:GetOrderedDataStore("LeaderboardWins_V2")

-- Server memory
local playerOwnedItems = {}
local playerBadges = {}
local playerOwnedPets = {}
local playerGoldenCoins = {}
local playerPetMutations = {}
local playerDataLoaded = {}

-- Helper: wait for a child in ReplicatedStorage (non-blocking but bounded)
local function waitForReplicatedChild(name, timeout)
	timeout = timeout or 5
	local start = tick()
	while tick() - start < timeout do
		local child = ReplicatedStorage:FindFirstChild(name)
		if child then
			return child
		end
		task.wait(0.1)
	end
	return nil
end

-- -------------------------
-- Persistence helpers (DB-only logs for mutations)
-- -------------------------
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

local function SavePlayerPetMutations(player)
	if not player or not player.UserId then 
		warn("SavePlayerPetMutations: Invalid player")
		return false
	end

	if not playerPetMutations[player.UserId] then 
		playerPetMutations[player.UserId] = {}
	end

	local userId = player.UserId
	local payload = playerPetMutations[userId]

	-- DB log: show what we're trying to save
	if type(payload) == "table" then
		local count = 0
		for petName, data in pairs(payload) do
			count = count + 1
		end
	else
		print("[DB] Payload is not a table; saving empty table.")
	end

	local success, err = pcall(function()
		petMutationsDataStore:SetAsync(userId, payload)
	end)

	if not success then
		print(string.format("[DB] Failed to save pet mutations for userId=%s: %s", tostring(userId), tostring(err)))
		return false
	end

	return true
end

-- -------------------------
-- Load / Save player data
-- -------------------------
local function LoadPlayerData(player)
	-- create leaderstats and standard fields
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

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	-- Load coins
	local success, coinData = pcall(function()
		return coinsDataStore:GetAsync(player.UserId)
	end)
	coins.Value = (success and coinData) or 0

	-- Load checkpoint
	local successCheckpoint, checkpointData = pcall(function()
		return checkpointDataStore:GetAsync(player.UserId)
	end)
	checkpoint.Value = (successCheckpoint and checkpointData) or 0

	-- Load items
	local successItems, savedItems = pcall(function()
		return itemsDataStore:GetAsync(player.UserId)
	end)
	playerOwnedItems[player.UserId] = (successItems and savedItems) or {}

	-- Load Wins
	local successWins, WinsData = pcall(function()
		return WinsDataStore:GetAsync(player.UserId)
	end)
	Wins.Value = (successWins and WinsData) or 0

	-- Load badges
	local successBadges, badgeData = pcall(function()
		return badgeDataStore:GetAsync(player.UserId)
	end)
	playerBadges[player.UserId] = (successBadges and badgeData) or {}

	-- Load owned pets
	local successPets, savedPets = pcall(function()
		return ownedPetsDataStore:GetAsync(player.UserId)
	end)

	if successPets and savedPets and type(savedPets) == "table" then
		playerOwnedPets[player.UserId] = savedPets
	else
		playerOwnedPets[player.UserId] = {}
	end

	-- Golden coins
	local goldenCoinsValue = Instance.new("NumberValue")
	goldenCoinsValue.Name = "GoldenCoins"
	goldenCoinsValue.Parent = player

	local successGoldenCoins, savedGoldenCoins = pcall(function()
		return goldenCoinsDataStore:GetAsync(player.UserId)
	end)

	if successGoldenCoins and type(savedGoldenCoins) == "number" then
		goldenCoinsValue.Value = savedGoldenCoins
		playerGoldenCoins[player.UserId] = savedGoldenCoins
	else
		goldenCoinsValue.Value = 0
		playerGoldenCoins[player.UserId] = 0
	end

	-- Load pet mutations (DB logs included)
	local successMutations, savedMutations = pcall(function()
		return petMutationsDataStore:GetAsync(player.UserId)
	end)

	if successMutations and savedMutations and type(savedMutations) == "table" then
		playerPetMutations[player.UserId] = savedMutations
		local count = 0
		for petName, data in pairs(savedMutations) do
			count = count + 1
		end
	else
		playerPetMutations[player.UserId] = {}
		if successMutations then
			print(string.format("[DB] No pet mutations table found for userId=%s (player %s). Initialized empty table.", tostring(player.UserId), player.Name))
		else
			print(string.format("[DB] Failed to fetch pet mutations for userId=%s (player %s). Error or nil result.", tostring(player.UserId), player.Name))
		end
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
			leaderboardCoinsDataStore:SetAsync(player.UserId, coins.Value) -- Save to ordered data store
		end)
	end

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
	SavePlayerPetMutations(player)

	playerBadges[player.UserId] = nil
	playerOwnedPets[player.UserId] = nil

	local goldenCoinsValue = player:FindFirstChild("GoldenCoins")
	if goldenCoinsValue then
		pcall(function()
			goldenCoinsDataStore:SetAsync(player.UserId, goldenCoinsValue.Value)
		end)
	end
	playerGoldenCoins[player.UserId] = nil
	playerPetMutations[player.UserId] = nil

	playerDataLoaded[player.UserId] = nil
end

-- -------------------------
-- Utilities / currency
-- -------------------------
function module.AddCoins(player, quantity)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end

	local coins = leaderstats:FindFirstChild("Coins")
	local Wins = leaderstats:FindFirstChild("Wins")
	if not coins then return 0 end

	local friendCount = 0
	if HelperModule and HelperModule.CountFriendsInServer then
		friendCount = HelperModule.CountFriendsInServer(player)
	end
	local friendBonus = 0.10 * friendCount

	local WinsBonus = 0
	if Wins and Wins.Value > 0 then
		WinsBonus = 0.10 * Wins.Value
	end

	local mutationBonus = module.CalculateMutationBonus(player)

	local total = math.floor(quantity * (1 + friendBonus + WinsBonus + mutationBonus))

	coins.Value = coins.Value + total

	return total
end

function module.RemoveCoins(player, quantity)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value = coins.Value - quantity end
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

function module.AddGoldenCoins(player, quantity)
	if not player then return 0 end
	local goldenCoinsValue = player:FindFirstChild("GoldenCoins")
	if goldenCoinsValue then
		goldenCoinsValue.Value = goldenCoinsValue.Value + quantity
		playerGoldenCoins[player.UserId] = goldenCoinsValue.Value
		return goldenCoinsValue.Value
	end
	return 0
end

function module.RemoveGoldenCoins(player, quantity)
	if not player then return 0 end
	local goldenCoinsValue = player:FindFirstChild("GoldenCoins")
	if goldenCoinsValue then
		goldenCoinsValue.Value = math.max(0, goldenCoinsValue.Value - quantity)
		playerGoldenCoins[player.UserId] = goldenCoinsValue.Value
		return goldenCoinsValue.Value
	end
	return 0
end

function module.GetGoldenCoins(player)
	if not player then return 0 end
	local goldenCoinsValue = player:FindFirstChild("GoldenCoins")
	if goldenCoinsValue then
		return goldenCoinsValue.Value
	end
	return playerGoldenCoins[player.UserId] or 0
end

function module.SetGoldenCoins(player, value)
	if not player then return end
	local goldenCoinsValue = player:FindFirstChild("GoldenCoins")
	if goldenCoinsValue then
		goldenCoinsValue.Value = value
		playerGoldenCoins[player.UserId] = value
	end
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

-- -------------------------
-- Inventory / badges / pets
-- -------------------------
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

if PlayerInventoryRemote then
	PlayerInventoryRemote.OnServerInvoke = function(player)
		return module.GetOwnedItems(player)
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

-- Ownership
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
			-- Also remove the pet's mutation when removing the pet
			module.RemovePetMutation(player, petName)
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
	playerPetMutations[player.UserId] = {} -- Also clear all mutations

	module.RemoveAllPhysicalPets(player)

	SavePlayerPets(player)
	return SavePlayerPetMutations(player)
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

-- -------------------------
-- PET MUTATIONS: save-only simple API (with DB logs)
-- -------------------------
function module.AddPetMutation(player, petName, mutationName)
	if not player or not player.UserId then
		warn("AddPetMutation: Invalid player")
		return false
	end
	if not petName or petName == "" then
		warn("AddPetMutation: Invalid pet name")
		return false
	end
	if not mutationName or mutationName == "" then
		warn("AddPetMutation: Invalid mutation name")
		return false
	end

	if not playerPetMutations[player.UserId] then
		playerPetMutations[player.UserId] = {}
	end

	playerPetMutations[player.UserId][petName] = { name = mutationName }

	-- DB log
	print(string.format("[DB] AddPetMutation: userId=%s player=%s pet=%s mutation=%s",
		tostring(player.UserId), player.Name, tostring(petName), tostring(mutationName)))

	return SavePlayerPetMutations(player)
end

function module.RemovePetMutation(player, petName)
	if not player or not player.UserId then
		warn("RemovePetMutation: Invalid player")
		return false
	end

	if not petName or petName == "" then
		warn("RemovePetMutation: Invalid pet name")
		return false
	end

	if not playerPetMutations[player.UserId] then
		playerPetMutations[player.UserId] = {}
	end

	if playerPetMutations[player.UserId][petName] then
		local prev = playerPetMutations[player.UserId][petName]
		playerPetMutations[player.UserId][petName] = nil

		-- DB log
		print(string.format("[DB] RemovePetMutation: userId=%s player=%s pet=%s removedMutation=%s",
			tostring(player.UserId), player.Name, tostring(petName), tostring(prev and prev.name or "nil")))

		return SavePlayerPetMutations(player)
	end

	return true
end

function module.GetPetMutation(player, petName)
	if not player or not player.UserId then
		warn("GetPetMutation: Invalid player")
		return nil
	end

	if not playerPetMutations[player.UserId] then
		return nil
	end

	return playerPetMutations[player.UserId][petName]
end

function module.GetAllPlayerPetMutations(player)
	if not player or not player.UserId then
		warn("GetAllPlayerPetMutations: Invalid player")
		return {}
	end

	return playerPetMutations[player.UserId] or {}
end

-- -------------------------
-- Apply Mutation logic (follows exact steps you described) with concise APPLY logs
-- -------------------------
local function getPrimaryPartFromModel(model)
	if not model then return nil end

	-- 1) If there's a child literally named "PrimaryPart"
	local declared = model:FindFirstChild("PrimaryPart")
	if declared then
		if declared:IsA("BasePart") then
			return declared
		end
		if declared:IsA("StringValue") then
			local name = declared.Value
			if type(name) == "string" and name ~= "" then
				local p = model:FindFirstChild(name)
				if p and p:IsA("BasePart") then
					return p
				end
			end
		end
		if declared:IsA("ObjectValue") and declared.Value and declared.Value:IsA("BasePart") then
			return declared.Value
		end
	end

	-- 2) If Model.PrimaryPart property is set and valid
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end

	-- 3) Try common part names
	local commonNames = { "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head" }
	for _, n in ipairs(commonNames) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end

	-- 4) Fallback: first BasePart descendant
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			return desc
		end
	end

	return nil
end

function module.ApplyMutationFromDB(player, petName)
	if not player or not player.UserId then
		warn("[APPLY] Invalid player")
		return false
	end
	if not petName or petName == "" then
		warn("[APPLY] Invalid pet name")
		return false
	end

	-- 1) Get saved mutation record for this pet
	local rec = module.GetPetMutation(player, petName)
	if not rec or not rec.name then
		return false
	end
	local mutationName = tostring(rec.name)

	-- 2) Get PlayerPets folder and the pet model
	local PlayerPetsWK = workspace:FindFirstChild("PlayerPets")
	if not PlayerPetsWK then
		warn("[APPLY] workspace.PlayerPets not found")
		return false
	end
	local playerPetFolder = PlayerPetsWK:FindFirstChild(player.Name)
	if not playerPetFolder then
		warn(string.format("[APPLY] PlayerPets folder for %s not found", player.Name))
		return false
	end

	local petModel = playerPetFolder:FindFirstChild(petName)
	if not petModel then
		warn(string.format("[APPLY] Pet model '%s' not found in workspace.PlayerPets.%s", petName, player.Name))
		return false
	end

	-- 3) Get the PrimaryPart
	local primaryPart = getPrimaryPartFromModel(petModel)
	if not primaryPart then
		warn(string.format("[APPLY] Could not find PrimaryPart for pet '%s' (player %s)", petName, player.Name))
		return false
	end

	-- 4) Get mutation template from ReplicatedStorage.Mutations
	local MutationsFolder = ReplicatedStorage:FindFirstChild("Mutations")
	if not MutationsFolder then
		warn("[APPLY] ReplicatedStorage.Mutations folder not found")
		return false
	end

	local template = MutationsFolder:FindFirstChild(mutationName)
	if not template then
		warn(string.format("[APPLY] Mutation template '%s' not found in ReplicatedStorage.Mutations", mutationName))
		return false
	end

	-- Remove existing ParticleEmitters on primaryPart
	local removed = 0
	for _, child in ipairs(primaryPart:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child:Destroy()
			removed = removed + 1
		end
	end
	if removed > 0 then
		print(string.format("[APPLY] Removed %d existing ParticleEmitter(s) from primary part '%s' for pet '%s'", removed, primaryPart.Name, petName))
	end

	-- Clone & parent emitters
	local ok, cloned = pcall(function() return template:Clone() end)
	if not ok or not cloned then
		warn("[APPLY] Failed to clone mutation template: " .. tostring(mutationName))
		return false
	end

	local addedEmitters = 0
	if cloned:IsA("ParticleEmitter") then
		cloned.Parent = primaryPart
		addedEmitters = 1
	else
		for _, descendant in ipairs(cloned:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				local ok2, em = pcall(function() return descendant:Clone() end)
				if ok2 and em then
					em.Parent = primaryPart
					addedEmitters = addedEmitters + 1
				end
			end
		end
		pcall(function() cloned:Destroy() end)
	end

	if addedEmitters > 0 then
	else
		warn(string.format("[APPLY] Template '%s' contained no ParticleEmitters to add for pet '%s' (player %s)", mutationName, petName, player.Name))
	end

	-- Save small folder on the physical pet for reference
	local existingFolder = petModel:FindFirstChild("PetMutation")
	if existingFolder then existingFolder:Destroy() end
	local mf = Instance.new("Folder")
	mf.Name = "PetMutation"
	mf.Parent = petModel
	local sv = Instance.new("StringValue")
	sv.Name = "Name"
	sv.Value = mutationName
	sv.Parent = mf

	return true
end

function module.ApplySavedMutationsToExistingPets(player)
	if not player or not player.UserId then return false end

	local PlayerPetsWK = workspace:FindFirstChild("PlayerPets")
	if not PlayerPetsWK then return false end

	local playerPetFolder = PlayerPetsWK:FindFirstChild(player.Name)
	if not playerPetFolder then return false end

	for _, petModel in pairs(playerPetFolder:GetChildren()) do
		if petModel and petModel:IsA("Model") then
			local ok, err = pcall(function()
				module.ApplyMutationFromDB(player, petModel.Name)
			end)
			if not ok then
				warn("ApplySavedMutationsToExistingPets: error applying mutation to ".. tostring(petModel.Name) ..": ".. tostring(err))
			end
		end
	end

	return true
end

function module.ClonePetsWithMutations(player)
	if not player or not player.UserId then
		warn("ClonePetsWithMutations: Invalid player")
		return false
	end

	-- Wait for player data to load
	if not playerDataLoaded[player.UserId] then
		local attempts = 0
		while not playerDataLoaded[player.UserId] and attempts < 50 do
			task.wait(0.1)
			attempts = attempts + 1
		end
	end

	local playerPets = module.GetOwnedPets(player)
	if not playerPets or #playerPets == 0 then
		print("No pets to clone for player: " .. player.Name)
		return true
	end

	-- Try to ensure we have Pets folder (wait a bit)
	local PetsFolder = ReplicatedStorage:FindFirstChild("Pets") or waitForReplicatedChild("Pets", 5)
	if not PetsFolder then
		warn("ClonePetsWithMutations: Pets folder not found in ReplicatedStorage (after waiting).")
		return false
	end

	-- Create/find PlayerPets folder
	local PlayerPetsWK = workspace:FindFirstChild("PlayerPets")
	if not PlayerPetsWK then
		PlayerPetsWK = Instance.new("Folder")
		PlayerPetsWK.Name = "PlayerPets"
		PlayerPetsWK.Parent = workspace
	end

	local playerPetFolder = PlayerPetsWK:FindFirstChild(player.Name)
	if not playerPetFolder then
		playerPetFolder = Instance.new("Folder")
		playerPetFolder.Name = player.Name
		playerPetFolder.Parent = PlayerPetsWK
	end

	-- Clear existing pets
	for _, pet in pairs(playerPetFolder:GetChildren()) do
		pet:Destroy()
	end

	-- Clone pets from PetsFolder
	for _, petName in ipairs(playerPets) do
		local petTemplate = PetsFolder:FindFirstChild(petName)
		if petTemplate then
			local petClone = petTemplate:Clone()
			petClone.Parent = playerPetFolder

			-- Best-effort primary part detection (no forced property set)
			pcall(function()
				if not petClone.PrimaryPart then
					getPrimaryPartFromModel(petClone)
				end
			end)

			-- Apply saved mutation visuals
			local ok, err = pcall(function()
				module.ApplyMutationFromDB(player, petClone.Name)
			end)
			if not ok then
				warn("ClonePetsWithMutations: error applying mutation to ".. tostring(petClone.Name) ..": ".. tostring(err))
			end

		else
			warn("Pet template not found in Pets folder: " .. petName)
		end
	end

	return true
end

-- -------------------------
-- Player add/remove handling (apply mutations on rejoin) - robust pathing & logs
-- -------------------------
Players.PlayerAdded:Connect(function(player)
	LoadPlayerData(player)

	task.defer(function()
		local attempts = 0
		while not playerDataLoaded[player.UserId] and attempts < 50 do
			task.wait(0.1)
			attempts = attempts + 1
		end

		local PlayerPetsWK = workspace:FindFirstChild("PlayerPets")
		local playerPetFolder = PlayerPetsWK and PlayerPetsWK:FindFirstChild(player.Name)
		if playerPetFolder and #playerPetFolder:GetChildren() > 0 then
			module.ApplySavedMutationsToExistingPets(player)
			return
		end

		-- 2) No existing physical pets — try to get ReplicatedStorage.Pets (wait up to 5s)
		local PetsFolder = ReplicatedStorage:FindFirstChild("Pets") or waitForReplicatedChild("Pets", 5)
		if PetsFolder then
			local ok, err = pcall(function() module.ClonePetsWithMutations(player) end)
			if not ok then
				warn("[JOIN] ClonePetsWithMutations failed: " .. tostring(err))
			end
			return
		end

		-- 3) Pets folder not found; wait a small window for another system to spawn physical pets
		local found = false
		local start = tick()
		while tick() - start < 5 do
			PlayerPetsWK = workspace:FindFirstChild("PlayerPets")
			playerPetFolder = PlayerPetsWK and PlayerPetsWK:FindFirstChild(player.Name)
			if playerPetFolder and #playerPetFolder:GetChildren() > 0 then
				found = true
				break
			end
			task.wait(0.2)
		end

		if found then
			module.ApplySavedMutationsToExistingPets(player)
			return
		end

		-- 4) Can't find Pets templates nor physical pets — log clearly
		warn(string.format("[JOIN] Could not apply pet mutations for player %s: no ReplicatedStorage.Pets and no workspace.PlayerPets.%s present. DB mutations load was successful but application is deferred.", player.Name, player.Name))
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	SavePlayerData(player)
end)

-- Remote invoke to get owned pets (if available)
if GetPlayerPetsRF then
	GetPlayerPetsRF.OnServerInvoke = function(player)
		local pets = module.GetOwnedPets(player)
		return pets
	end
end

if GetPlayerPetsBuffs then
	GetPlayerPetsBuffs.OnServerInvoke = function(player)
		local buff = module.CalculateMutationBonus(player)
		return string.format("%.0f%%", buff * 100) -- Format as "XX%"
	end
end

function module.CalculateMutationBonus(player)
	local totalBuff = 0
	local playerMutations = module.GetAllPlayerPetMutations(player)

	for petName, mutationData in pairs(playerMutations) do
		if mutationData and mutationData.name and PetMutations.Mutations[mutationData.name] then
			totalBuff = totalBuff + PetMutations.Mutations[mutationData.name].buff
		end
	end

	return totalBuff / 100 -- Convert to percentage
end

return module