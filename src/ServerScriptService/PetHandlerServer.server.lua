local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStore = require(ReplicatedStorage.DataStore)
local AllPetsModule = require(ReplicatedStorage.AllPets)
local AllPetsTable = AllPetsModule.allPets

local AllPetsModelFolder = workspace:FindFirstChild("AllPetsModels")
local PhysicalPetsFolder = ReplicatedStorage:FindFirstChild("PhysicalPets")
local PlayerPetsFolderRoot = workspace:FindFirstChild("PlayerPets")

local NewPetEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pets"):WaitForChild("NewPet")
local NewPetAnimation = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pets"):WaitForChild("UICollectPet")

local debouncePlayer = {}
local DebounceTime = 3.5

local function isPetValidForPlayerCheckpoint(player, petName)
	if not player then return false end

	local ok, cp = pcall(function()
		return DataStore.GetCheckpoint(player)
	end)
	if not ok or not cp then return false end

	for i = 1, cp do
		local entry = AllPetsTable[tostring(i)]
		if entry and entry.name and tostring(entry.name) == tostring(petName) then
			return true
		end
	end

	return false
end


local function addPetToPlayerFolder(player, petName)
	if not player or not petName then return false end

	if not PlayerPetsFolderRoot then
		warn("[PetHandler] PlayerPets folder not found in Workspace")
		return false
	end

	local playerPetFolder = PlayerPetsFolderRoot:FindFirstChild(player.Name)
	if not playerPetFolder then
		playerPetFolder = Instance.new("Folder")
		playerPetFolder.Name = player.Name
		playerPetFolder.Parent = PlayerPetsFolderRoot
	end

	if playerPetFolder:FindFirstChild(petName) then
		return true
	end

	if not PhysicalPetsFolder then
		warn("[PetHandler] PhysicalPets folder not found in ReplicatedStorage")
		return false
	end

	local petModel = PhysicalPetsFolder:FindFirstChild(petName)
	if not petModel then
		warn("[PetHandler] Physical pet model '" .. tostring(petName) .. "' not found in PhysicalPets")
		return false
	end

	local success, petClone = pcall(function() return petModel:Clone() end)
	if success and petClone then
		petClone.Parent = playerPetFolder
		return true
	else
		warn("[PetHandler] Failed to clone pet model '" .. tostring(petName) .. "' for " .. tostring(player.Name))
		return false
	end
end

local function givePlayerPet(player, petName)
	if not player or not petName then return end

	if not isPetValidForPlayerCheckpoint(player, petName) then return end

	local ownedPets = nil
	local ok, owned = pcall(function()
		return DataStore.GetOwnedPets(player)
	end)
	if ok and type(owned) == "table" then
		ownedPets = owned
	else
		ownedPets = {}
	end

	for _, name in pairs(ownedPets) do
		if tostring(name) == tostring(petName) then
			return
		end
	end

	local successGive = false
	local okGive, result = pcall(function()
		return DataStore.GivePet(player, petName)
	end)
	if okGive and result == true then
		successGive = true
	end

	if successGive then
		addPetToPlayerFolder(player, petName)

		NewPetEvent:FireClient(player, petName)
		NewPetAnimation:FireClient(player, petName)
	else
		warn("[PetHandler] DataStore.GivePet failed for " .. tostring(player.Name) .. " pet: " .. tostring(petName))
	end
end

local function connectModelTouch(model)
	if not model or not model:IsA("Model") then return end

	local touchPart = model.PrimaryPart
	if not touchPart then
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BasePart") then
				touchPart = child
				break
			end
		end
	end

	if not touchPart then
		warn("[PetHandler] No touchable part found for model: " .. tostring(model.Name))
		return
	end

	touchPart.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local last = debouncePlayer[player.UserId] or 0
		local now = tick()
		if now - last < DebounceTime then
			return
		end
		debouncePlayer[player.UserId] = now

		local petName = model.Name
		givePlayerPet(player, petName)
	end)
end

if AllPetsModelFolder then
	for _, model in ipairs(AllPetsModelFolder:GetChildren()) do
		connectModelTouch(model)
	end

	AllPetsModelFolder.ChildAdded:Connect(function(child)
		task.wait(0.05)
		connectModelTouch(child)
	end)
else
	warn("[PetHandler] AllPetsModels folder not found in workspace")
end

local function loadPlayerPets(player)
	if not player then return false end

	if not PlayerPetsFolderRoot then
		warn("[PetHandler] PlayerPets folder not found in workspace")
		return false
	end

	local existingFolder = PlayerPetsFolderRoot:FindFirstChild(player.Name)
	if existingFolder then
		existingFolder:Destroy()
	end

	local playerPetFolder = Instance.new("Folder")
	playerPetFolder.Name = player.Name
	playerPetFolder.Parent = PlayerPetsFolderRoot

	local playerPets = nil
	local ok, owned = pcall(function() return DataStore.GetOwnedPets(player) end)
	if ok and type(owned) == "table" then
		playerPets = owned
	else
		playerPets = {}
	end

	local loaded = 0
	if PhysicalPetsFolder then
		for _, petname in ipairs(playerPets) do
			if petname and petname ~= "" then
				local petModel = PhysicalPetsFolder:FindFirstChild(tostring(petname))
				if petModel then
					local success, petClone = pcall(function() return petModel:Clone() end)
					if success and petClone then
						petClone.Parent = playerPetFolder
						loaded = loaded + 1
					else
						warn("[PetHandler] Failed to clone physical pet '" .. tostring(petname) .. "' for " .. tostring(player.Name))
					end
					end
				end
			end
	else
		warn("[PetHandler] PhysicalPets folder missing; cannot load physical pets for " .. tostring(player.Name))
	end

	return true
end

Players.PlayerAdded:Connect(function(player)
	task.wait(5)
	loadPlayerPets(player)
end)

Players.PlayerRemoving:Connect(function(player)
	if PlayerPetsFolderRoot then
		local folder = PlayerPetsFolderRoot:FindFirstChild(player.Name)
		if folder then folder:Destroy() end
	end
	debouncePlayer[player.UserId] = nil
end)
