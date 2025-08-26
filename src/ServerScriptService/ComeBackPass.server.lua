local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ds = require(ReplicatedStorage.DataStore)

local SpecialPart:BasePart = game.Workspace.BacktoSpawn.Part
local checkpointsFolder = game.Workspace.CheckPoints

local PRODUCT_ID = 3384036706

local purchasingPlayers = {}

local function GetCheckpointPart(checkpointNumber)
	local checkpointModel = checkpointsFolder:FindFirstChild(tostring(checkpointNumber))
	if checkpointModel and checkpointModel:IsA("Model") then
		return checkpointModel.PrimaryPart
	end
	return nil
end

local function TeleportPlayerToSpawn(player)
	local spawnCheckpoint = GetCheckpointPart(1)
	if spawnCheckpoint and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = spawnCheckpoint.CFrame + Vector3.new(0, 5, 0)
	else
		player:LoadCharacter()
	end
end

local function TeleportPlayerToCheckpoint(player, checkpointNumber)
	local checkpointPart = GetCheckpointPart(checkpointNumber)
	if checkpointPart then
		player.Character:SetPrimaryPartCFrame(checkpointPart.CFrame + Vector3.new(0, 5, 0))
	else
		TeleportPlayerToSpawn(player)
	end
end

SpecialPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		local lastCheckpointValue = player:FindFirstChild("LastCheckpoint")
		if not lastCheckpointValue then return end

		if lastCheckpointValue.Value == 0 or lastCheckpointValue.Value == 1 then
			TeleportPlayerToSpawn(player)
			return
		end

		local success, result = pcall(function()
			return MarketplaceService:PromptProductPurchase(player, PRODUCT_ID)
		end)

		if success then
			purchasingPlayers[player.UserId] = false
			MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
				if isPurchased then
					purchasingPlayers[userId] = true
					TeleportPlayerToCheckpoint(player, player:FindFirstChild("LastCheckpoint").Value)
					purchasingPlayers[userId] = nil
				else
					TeleportPlayerToSpawn(player)
					purchasingPlayers[userId] = nil
				end
			end)

			task.delay(2.5, function()
				if purchasingPlayers[player.UserId] == false then
					TeleportPlayerToSpawn(player)
				end
				purchasingPlayers[player.UserId] = nil
			end)
		else
			warn("Error prompting product purchase:", result)
			TeleportPlayerToSpawn(player)
		end
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
							local gamePassLastCheckpointValue = player:FindFirstChild("LastCheckpoint")
							if not gamePassLastCheckpointValue then return end

							local actualCurrentCheckpoint = ds.GetCheckpoint(player)
							local touchedCheckpoint = tonumber(model.Name)

							if touchedCheckpoint <= (actualCurrentCheckpoint + 1) and touchedCheckpoint > gamePassLastCheckpointValue.Value then
								gamePassLastCheckpointValue.Value = touchedCheckpoint
							end
						end
					end)
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local lastCheckpointValue = Instance.new("NumberValue")
	lastCheckpointValue.Name = "LastCheckpoint"
	lastCheckpointValue.Value = 0
	lastCheckpointValue.Parent = player
end)

SetupCheckpointListeners()