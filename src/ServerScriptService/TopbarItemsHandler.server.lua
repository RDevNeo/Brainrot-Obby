local TopbarItemsModule = require(game.ReplicatedStorage.TopBarItems)
local MarketplaceService = game:GetService("MarketplaceService")
local TopbarItems = TopbarItemsModule.Items
local Event = game.ReplicatedStorage.Remotes.BoughtTopbarButtons
local GlobalMessagesEvent = game.ReplicatedStorage.Remotes.GlobalMessages
local DataStore = require(game.ReplicatedStorage.DataStore)

Event.OnServerEvent:Connect(function(player, name)
	local item = TopbarItems[name]
	if not item then return end

	local productId = item.gamepassId
	MarketplaceService:PromptProductPurchase(player, productId)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	if productId == 3385282664 then -- kill all
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				plr.Character.HumanoidRootPart.CFrame = game.Workspace.CheckPoints:FindFirstChild("1").PrimaryPart.CFrame + Vector3.new(0, 3, 0)
				GlobalMessagesEvent:FireClient(player, productId)
			end
		end

	elseif productId == 3385283948 then -- skip stage
		local playercurrentCheckpoint = DataStore.GetCheckpoint(player)
		local nextCheckpoint = playercurrentCheckpoint + 1
		DataStore.SetCheckpoint(player, nextCheckpoint)

		local checkpointsFolder = game.Workspace:FindFirstChild("CheckPoints")
		if checkpointsFolder and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local checkpointModel = checkpointsFolder:FindFirstChild(tostring(nextCheckpoint))
			if checkpointModel and checkpointModel.PrimaryPart then
				player.Character.HumanoidRootPart.CFrame = checkpointModel.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
				GlobalMessagesEvent:FireClient(player, productId)
			end
		end

	elseif productId == 3385284803 then -- skip to end
		local toGoCheckpoint = 30
		DataStore.SetCheckpoint(player, 30)
		
		local checkpointsFolder = game.Workspace.CheckPoints
		if checkpointsFolder and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local checkpointModel = checkpointsFolder:FindFirstChild(tostring(toGoCheckpoint))
			if checkpointModel and checkpointModel.PrimaryPart then
				player.Character.HumanoidRootPart.CFrame = checkpointModel.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
				GlobalMessagesEvent:FireClient(player, productId)
			end
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
