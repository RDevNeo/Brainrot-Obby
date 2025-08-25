local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MutationRequestEvent = ReplicatedStorage.Remotes.Pets.MutationRequest
local PetMutationsModule = require(ReplicatedStorage.PetMutations)
local PetMutations = PetMutationsModule.Mutations
local DataStore = require(ReplicatedStorage.DataStore)

MutationRequestEvent.OnServerEvent:Connect(function(player, PetToMutate, RandomMutation)
	local PlayerPetsFolder = game.Workspace.PlayerPets:WaitForChild(player.Name, 60)
	local MutationsFolder = game.ReplicatedStorage.Mutations
	local PhysicalPetToMutate:Model = PlayerPetsFolder:FindFirstChild(PetToMutate)
	local PhysicalMutation:ParticleEmitter = MutationsFolder:FindFirstChild(RandomMutation.name)

	if not PhysicalPetToMutate then
		warn("Pet not found:", PetToMutate)
		return
	end
	if not PhysicalMutation then
		warn("Mutation effect not found:", RandomMutation.name)
		return
	end
	if not PhysicalPetToMutate.PrimaryPart then
		warn("Pet has no PrimaryPart:", PetToMutate)
		return
	end

	print("Applying mutation:", RandomMutation.name, "to pet:", PetToMutate)

	for _, child in pairs(PhysicalPetToMutate.PrimaryPart:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child:Destroy()
			print("Removed existing mutation effect:", child.Name)
		end
	end

	local existingMutationFolder = PhysicalPetToMutate:FindFirstChild("PetMutation")
	if existingMutationFolder then
		existingMutationFolder:Destroy()
	end

	local existingSaved = DataStore.GetPetMutation(player, PetToMutate)
	if existingSaved then
		local ok, err = pcall(function()
			DataStore.RemovePetMutation(player, PetToMutate)
		end)
		if ok then
			print("Removed previous saved mutation for pet:", PetToMutate, "(", tostring(existingSaved.name), ")")
		else
			warn("Failed to remove previous saved mutation for pet:", PetToMutate, err)
		end
	end

	if RandomMutation.name == "Mega" then
		local IncreaseAmount = RandomMutation.scale
		for _, parts in pairs(PhysicalPetToMutate:GetChildren()) do
			if parts:IsA("BasePart") then
				parts.Size = parts.Size + Vector3.new(IncreaseAmount, IncreaseAmount, IncreaseAmount)
			end
		end
	elseif RandomMutation.name == "Tiny" then
		local DecreaseAmount = RandomMutation.scale
		for _, parts in pairs(PhysicalPetToMutate:GetChildren()) do
			if parts:IsA("BasePart") then
				parts.Size = parts.Size - Vector3.new(DecreaseAmount, DecreaseAmount, DecreaseAmount)
			end
		end
	end

	local Mutation = PhysicalMutation:Clone()
	Mutation.Parent = PhysicalPetToMutate.PrimaryPart

	local ok2, err2 = pcall(function()
		DataStore.AddPetMutation(player, PetToMutate, PhysicalMutation.Name)
	end)
	if not ok2 then
		warn("Failed to save new pet mutation to DB for", player.Name, PetToMutate, err2)
	else
		print("Saved new mutation to DB for pet:", PetToMutate, PhysicalMutation.Name)
	end

	DataStore.RemoveGoldenCoins(player, 1)
end)