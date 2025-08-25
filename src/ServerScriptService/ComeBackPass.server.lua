local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

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
							local lastCheckpointValue = player:FindFirstChild("LastCheckpoint")
							
							if not lastCheckpointValue then return end

							local currentCheckpoint = lastCheckpointValue.Value
							local touchedCheckpoint = tonumber(model.Name)

							if touchedCheckpoint > currentCheckpoint then
								lastCheckpointValue.Value = touchedCheckpoint
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
		-- Set debounce to prevent rapid re-prompting
		playerDebounce[player.UserId] = true

		local lastCheckpointValue = player:FindFirstChild("LastCheckpoint")

		if not lastCheckpointValue then 
			playerDebounce[player.UserId] = nil -- Clear debounce if no checkpoint value
			return 
		end

		local currentCheckpoint = lastCheckpointValue.Value

		if currentCheckpoint > 1 then
			playersWaitingForPurchase[player.UserId] = true -- Mark player as waiting

			local success, message = pcall(function()
				MarketplaceService:PromptProductPurchase(player, gamepassId)
			end)

			if not success then
				warn("Error prompting gamepass purchase for " .. player.Name .. ": " .. tostring(message))
				playersWaitingForPurchase[player.UserId] = nil -- Clear waiting state on error
				playerDebounce[player.UserId] = nil -- Clear debounce on error
				return
			end

			task.delay(10, function()
				if playersWaitingForPurchase[player.UserId] then
					-- If player is still waiting after 10 seconds, send to checkpoint 1
					playersWaitingForPurchase[player.UserId] = nil -- Clear waiting state
					playerDebounce[player.UserId] = nil -- Clear debounce

					local spawnCheckpointPart = GetCheckpointPart(1) -- Assuming checkpoint 1 is the spawn
					if spawnCheckpointPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						player.Character:SetPrimaryPartCFrame(spawnCheckpointPart.CFrame + Vector3.new(0, 5, 0))
						print(player.Name .. " did not purchase ComeBackPass and was sent to checkpoint 1.")
					end
				end
				-- Ensure debounce is cleared here even if the player just closed the prompt
				playerDebounce[player.UserId] = nil
			end)
		else
			-- If currentCheckpoint is not > 1, clear debounce immediately
			playerDebounce[player.UserId] = nil
		end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, purchasedProductId, wasPurchased)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end -- Player might have left the game

	-- Clear waiting state and debounce regardless of purchase success, as the prompt has finished.
	playersWaitingForPurchase[player.UserId] = nil
	playerDebounce[player.UserId] = nil

	if purchasedProductId == gamepassId and wasPurchased then
		local lastCheckpointValue = player:FindFirstChild("LastCheckpoint")

		if not lastCheckpointValue then return end

		local currentCheckpoint = lastCheckpointValue.Value

		if currentCheckpoint > 1 then
			local checkpointPart = GetCheckpointPart(currentCheckpoint)
			if checkpointPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character:SetPrimaryPartCFrame(checkpointPart.CFrame + Vector3.new(0, 5, 0))
				print(player.Name .. " teleported to checkpoint " .. currentCheckpoint .. " after purchasing ComeBackPass.")
			else
				warn("Failed to teleport " .. player.Name .. ": Checkpoint part or character not found.")
			end
		end
	else
		-- Player closed the prompt without purchasing, send to spawn (Checkpoint 1)
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

