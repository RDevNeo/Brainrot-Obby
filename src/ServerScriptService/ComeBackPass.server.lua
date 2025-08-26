local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StartEndGameAnimation = ReplicatedStorage.Remotes.UI.EndGameAnimation
local ds = require(ReplicatedStorage.DataStore) -- Re-add the DataStore module requirement

local gamepassId = 3384036706

local endPart = game.Workspace.BacktoSpawn.Part

local checkpointsFolder = game.Workspace.CheckPoints

local playersWaitingForPurchase = {}
local playerDebounce = {}

local function GetCheckpointPart(checkpointNumber)
	local checkpointModel = checkpointsFolder:FindFirstChild(tostring(checkpointNumber))
	if checkpointModel and checkpointModel:IsA("Model") then
		return checkpointModel.PrimaryPart
	end
	return nil
end

local function SetupCheckpointListeners()
	for _, model in pairs(checkpointsFolder:GetChildren()) do
		if model:IsA("Model") and tonumber(model.Name) then
			for _, part in pairs(model:GetChildren()) do
				if part:IsA("BasePart") then
					part.Touched:Connect(function(hit)
						local player = Players:GetPlayerFromCharacter(hit.Parent)

						if player then
							local gamePassLastCheckpointValue = player:FindFirstChild("LastCheckpoint")
							if not gamePassLastCheckpointValue then return end

							local actualCurrentCheckpoint = ds.GetCheckpoint(player) -- Get actual checkpoint from DataStore
							local touchedCheckpoint = tonumber(model.Name)

							if (touchedCheckpoint == actualCurrentCheckpoint or touchedCheckpoint == (actualCurrentCheckpoint + 1)) and touchedCheckpoint > gamePassLastCheckpointValue.Value then
								gamePassLastCheckpointValue.Value = touchedCheckpoint
							end
						end
					end)
				end
			end
		end
	end
end

endPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)

	if player and not playerDebounce[player.UserId] then
		StartEndGameAnimation:FireClient(player)
		playerDebounce[player.UserId] = true

		local gamePassLastCheckpointValue = player:FindFirstChild("LastCheckpoint")
		if not gamePassLastCheckpointValue then
			playerDebounce[player.UserId] = nil 
			return
		end
		local currentCheckpointForGamePass = gamePassLastCheckpointValue.Value

		if currentCheckpointForGamePass > 1 then
			playersWaitingForPurchase[player.UserId] = true

			local success, message = pcall(function()
				MarketplaceService:PromptProductPurchase(player, gamepassId)
			end)

			if not success then
				warn("Error prompting gamepass purchase for " .. player.Name .. ": " .. tostring(message))
				playersWaitingForPurchase[player.UserId] = nil 
				playerDebounce[player.UserId] = nil 
				return
			end

			task.delay(10, function()
				if playersWaitingForPurchase[player.UserId] then
					playersWaitingForPurchase[player.UserId] = nil
					playerDebounce[player.UserId] = nil

					local spawnCheckpointPart = GetCheckpointPart(1) 
					if spawnCheckpointPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						player.Character:SetPrimaryPartCFrame(spawnCheckpointPart.CFrame + Vector3.new(0, 5, 0))
						print(player.Name .. " did not purchase ComeBackPass and was sent to checkpoint 1.")
					end
				end
				
				playerDebounce[player.UserId] = nil
			end)
		else
		
			playerDebounce[player.UserId] = nil
		end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, purchasedProductId, wasPurchased)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	
	playerDebounce[player.UserId] = nil

	if purchasedProductId == gamepassId and wasPurchased then
		local gamePassLastCheckpointValue = player:FindFirstChild("LastCheckpoint")
		if not gamePassLastCheckpointValue then return end
		local currentCheckpointForGamePass = gamePassLastCheckpointValue.Value

		if currentCheckpointForGamePass > 1 then
			local checkpointPart = GetCheckpointPart(currentCheckpointForGamePass)
			if checkpointPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character:SetPrimaryPartCFrame(checkpointPart.CFrame + Vector3.new(0, 5, 0))
				print(player.Name .. " teleported to checkpoint " .. currentCheckpointForGamePass .. " after purchasing ComeBackPass.")
			else
				warn("Failed to teleport " .. player.Name .. ": Checkpoint part or character not found.")
			end
		end
	else
		
		local spawnCheckpointPart = GetCheckpointPart(1)
		if spawnCheckpointPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character:SetPrimaryPartCFrame(spawnCheckpointPart.CFrame + Vector3.new(0, 5, 0))
			print(player.Name .. " closed the ComeBackPass prompt and was sent to checkpoint 1.")
		else
			warn("Failed to teleport " .. player.Name .. " to checkpoint 1: Checkpoint part or character not found.")
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	local lastCheckpointValue = Instance.new("NumberValue")
	lastCheckpointValue.Name = "LastCheckpoint"
	lastCheckpointValue.Value = 0
	lastCheckpointValue.Parent = player
end)

SetupCheckpointListeners()

