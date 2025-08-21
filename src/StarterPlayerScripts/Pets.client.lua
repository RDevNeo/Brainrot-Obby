local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local GetPlayerPetsRF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pets"):WaitForChild("GetPlayerPets")
local NewPetEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pets"):WaitForChild("NewPet")
local RebirthShowPets = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pets"):WaitForChild("RebirthShowPets")
local UIModule = require(ReplicatedStorage.Modules.UI)

local PetsModelRP = ReplicatedStorage:FindFirstChild("PetsModelFolder")
if not PetsModelRP then
	PetsModelRP = Instance.new("Folder")
	PetsModelRP.Name = "PetsModelFolder"
	PetsModelRP.Parent = ReplicatedStorage
end

local currentPlayerPets = {}

local function movePetToClient(petName)
	if not petName or petName == "" then  
		return false 
	end

	if PetsModelRP:FindFirstChild(petName) then 
		return true	
	end

	local allPetsModelWK = game.Workspace:FindFirstChild("AllPetsModels") 
	if not allPetsModelWK then 
		return false 
	end

	local petModel = allPetsModelWK:FindFirstChild(petName)
	if petModel and petModel:IsA("Model") then
		local success = pcall(function()
			petModel.Parent = PetsModelRP
		end)

		if success then
			return true
		else 
			return false
		end
	else 
		return false
	end
end

local function movePetBackToWorkspace(petName)
	if not petName or petName == "" then
		return false
	end

	local allPetsModelWK = game.Workspace:FindFirstChild("AllPetsModels")
	if not allPetsModelWK then
		warn("AllPetsModels folder not found in Workspace")
		return false
	end

	if allPetsModelWK:FindFirstChild(petName) then
		return true
	end

	local petModel = PetsModelRP:FindFirstChild(petName)
	if petModel and petModel:IsA("Model") then
		local success = pcall(function()
			petModel.Parent = allPetsModelWK
		end)

		if success then
			print("Moved pet '" .. petName .. "' back to Workspace")
			return true
		else
			warn("Failed to move pet '" .. petName .. "' back to Workspace")
			return false
		end
	else
		return true
	end
end

local function moveAllOwnedPetsToClient()
	local allPetsModelWK = game.Workspace:WaitForChild("AllPetsModels", 10)
	if not allPetsModelWK then 	
		return false	
	end

	local success, playerPets = pcall(function()
		return GetPlayerPetsRF:InvokeServer()
	end)

	if not success or not playerPets then 
		return false 
	end

	for _, petName in pairs(playerPets) do
		movePetToClient(petName)
	end

	currentPlayerPets = playerPets
	return true
end

local function moveAllPetsBackToWorkspace()
	print("Moving all pets back to workspace (client-side)")

	local petsToMove = {}
	for _, pet in pairs(PetsModelRP:GetChildren()) do
		if pet:IsA("Model") then
			table.insert(petsToMove, pet.Name)
		end
	end

	for _, petName in pairs(petsToMove) do
		movePetBackToWorkspace(petName)
	end

	currentPlayerPets = {}

	print("Finished moving " .. #petsToMove .. " pets back to workspace (client-side)")
end

NewPetEvent.OnClientEvent:Connect(function(petName)
	if movePetToClient(petName) then
		if not table.find(currentPlayerPets, petName) then
			table.insert(currentPlayerPets, petName)
		end
	end
	pcall(function()
		UIModule.PetCollected(petName)
		UIModule.PlayPetSound(petName)
	end)
end)

RebirthShowPets.OnClientEvent:Connect(function()
	print("Rebirth event received - showing all pets")
	moveAllPetsBackToWorkspace()
end)

local function onCharacterAdded(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(function()
			pcall(moveAllPetsBackToWorkspace)
		end)
	end

	task.delay(0.8, function()
		pcall(moveAllOwnedPetsToClient)
	end)
end

local function onCharacterRemoving()
	pcall(moveAllPetsBackToWorkspace)
end

local function waitForDataAndMovePets()
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then 
		return	
	end

	task.wait(2)
	moveAllOwnedPetsToClient()
end

task.spawn(waitForDataAndMovePets)

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)

Players.PlayerRemoving:Connect(function(plr)
	if plr == player then
		pcall(moveAllPetsBackToWorkspace)
	end
end)
