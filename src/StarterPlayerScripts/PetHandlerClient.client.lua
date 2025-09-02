local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local GetPlayerPetsRF = ReplicatedStorage:WaitForChild("GetPlayerPets")
local NewPetEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pets"):WaitForChild("NewPet")
local UIModule = require(ReplicatedStorage.UI)

local currentPlayerPets = {}

local function movePetToClient(petName)
	if not petName or petName == "" then return false end


	local allPetsModelWK = game.Workspace:FindFirstChild("AllPetsModels") 
	if not allPetsModelWK then return false end

	local petModel = allPetsModelWK:FindFirstChild(petName)
	if petModel and petModel:IsA("Model") then
		local success = pcall(function()
			petModel:Destroy()
		end)

		if success then
			return true
		else 
			return false
		end
	end
end



local function moveAllOwnedPetsToClient()
	local allPetsModelWK = game.Workspace:WaitForChild("AllPetsModels", 10)
	if not allPetsModelWK then return false end

	local success, playerPets = pcall(function()
		return GetPlayerPetsRF:InvokeServer()
	end)

	if not success or not playerPets then warn("[PetHandlerClient] Failed to retrieve player pets from server or no pets found.") return false end

	for _, petName in pairs(playerPets) do
		movePetToClient(petName)
	end

	currentPlayerPets = playerPets
	return true
end



NewPetEvent.OnClientEvent:Connect(function(petName)
	if movePetToClient(petName) then
		if not table.find(currentPlayerPets, petName) then
			table.insert(currentPlayerPets, petName)
		end
	end

	UIModule.PetCollected(petName)
	UIModule.PlayPetSound(petName)
end)

local function onCharacterAdded(character)
	task.delay(0.8, function()
		pcall(moveAllOwnedPetsToClient)
	end)
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

