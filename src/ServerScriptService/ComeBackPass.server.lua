local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local GlobalMessagesEvent = game.ReplicatedStorage.Remotes.GlobalMessages
local ds = require(ReplicatedStorage.DataStore)

local SpecialPart:BasePart = game.Workspace.BacktoSpawn.Part
local checkpointsFolder = game.Workspace.CheckPoints

local PRODUCT_ID = 3384036706
local purchasingPlayers = {}

local function GetCheckpointPart(checkpointNumber)
	local model = checkpointsFolder:FindFirstChild(tostring(checkpointNumber))
	if model and model:IsA("Model") and model.PrimaryPart then
		return model.PrimaryPart
	end
	return nil
end

local function SafeTeleport(player, targetCFrame)
	if not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0)
end

local function TeleportToSpawn(player)
	local spawnPart = GetCheckpointPart(1)
	if spawnPart then
		SafeTeleport(player, spawnPart.CFrame)
	else
		player:LoadCharacter()
	end
end

local function TeleportToCheckpoint(player, checkpointNumber)
	local checkpointPart = GetCheckpointPart(checkpointNumber)
	if checkpointPart then
		SafeTeleport(player, checkpointPart.CFrame)
	else
		TeleportToSpawn(player)
	end
end

function MarketplaceService.ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == PRODUCT_ID then
		GlobalMessagesEvent:FireClient(player, PRODUCT_ID)
		
		purchasingPlayers[player.UserId] = nil  
	
		local lastCheckpoint = player:FindFirstChild("LastCheckpoint")
		if lastCheckpoint then
			local cp = lastCheckpoint.Value
	
			if cp <= 1 then
				TeleportToSpawn(player)
			else
				TeleportToCheckpoint(player, cp)
			end
		else
			TeleportToSpawn(player)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	if productId ~= PRODUCT_ID then return end
	
	local player = Players:GetPlayerByUserId(userId)
	if not player then 
		print("Player not found for userId:", userId)
		return 
	end
	
	local purchaseData = purchasingPlayers[userId]
	if not purchaseData then
		purchaseData = { timedOut = true, completed = false }
	end
	
	if isPurchased then
		purchaseData.completed = true
		purchasingPlayers[userId] = nil
		
		GlobalMessagesEvent:FireClient(player, PRODUCT_ID)
		
		local lastCheckpoint = player:FindFirstChild("LastCheckpoint")
		if lastCheckpoint then
			local cp = lastCheckpoint.Value
	
			if cp <= 1 then
				TeleportToSpawn(player)
			else
				TeleportToCheckpoint(player, cp)
			end
		else
			TeleportToSpawn(player)
		end
	else
		if not purchaseData.timedOut then
			purchasingPlayers[userId] = nil
			TeleportToSpawn(player)
		end
	end
end)

SpecialPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local lastCheckpoint = player:FindFirstChild("LastCheckpoint")
	if not lastCheckpoint then return end

	if lastCheckpoint.Value == 0 or lastCheckpoint.Value == 1 then
		TeleportToSpawn(player)
		return
	end

	if not purchasingPlayers[player.UserId] then
		purchasingPlayers[player.UserId] = {
			checkpointValue = lastCheckpoint.Value,
			timedOut = false,
			completed = false
		}
		
		MarketplaceService:PromptProductPurchase(player, PRODUCT_ID)

		task.delay(5, function()
			local purchaseData = purchasingPlayers[player.UserId]
			if not purchaseData then return end

			if not purchaseData.completed then
				purchaseData.timedOut = true
				TeleportToSpawn(player)
			end
		end)
	end
end)

local function SetupCheckpointListeners()
	for _, model in pairs(checkpointsFolder:GetChildren()) do
		if model:IsA("Model") and tonumber(model.Name) then
			for _, part in pairs(model:GetChildren()) do
				if part:IsA("BasePart") then
					part.Touched:Connect(function(hit)
						local player = Players:GetPlayerFromCharacter(hit.Parent)
						if player then
							local lastCheckpoint = player:FindFirstChild("LastCheckpoint")
							if not lastCheckpoint then return end

							local actualCheckpoint = ds.GetCheckpoint(player)
							local touchedCheckpoint = tonumber(model.Name)

							if touchedCheckpoint <= (actualCheckpoint + 1)
								and touchedCheckpoint > lastCheckpoint.Value then
								lastCheckpoint.Value = touchedCheckpoint
							end
						end
					end)
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local lastCheckpoint = Instance.new("NumberValue")
	lastCheckpoint.Name = "LastCheckpoint"
	lastCheckpoint.Value = 0
	lastCheckpoint.Parent = player
end)

Players.PlayerRemoving:Connect(function(player)
	purchasingPlayers[player.UserId] = nil
end)

SetupCheckpointListeners()
