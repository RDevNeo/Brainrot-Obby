local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local BoughtEvent = ReplicatedStorage.Remotes.UI.BoughtItems
local BoughtSuccess = ReplicatedStorage.Remotes.UI.BoughtSuccesfull
local ItemsModule = require(ReplicatedStorage.CoinsItems)
local Items = ItemsModule.Items
local DataStoreModule = require(ReplicatedStorage.DataStore)
local PhysicalItemFolder = ReplicatedStorage.ItemsFolder.CoinShopItems

local function giveOwnedItems(player)
	local backpack = player:WaitForChild("Backpack")
	local character = player.Character

	local ownedItems = DataStoreModule.GetOwnedItems(player)
	if type(ownedItems) == "table" then
		for _, itemName in ipairs(ownedItems) do
			local alreadyHas = false

			if backpack:FindFirstChild(itemName) then
				alreadyHas = true
			end

			if character and character:FindFirstChild(itemName) then
				alreadyHas = true
			end

			if not alreadyHas then
				local physicalItem = PhysicalItemFolder:FindFirstChild(itemName)
				if physicalItem then
					physicalItem:Clone().Parent = backpack
				end
			end
		end
	end
end


BoughtEvent.OnServerEvent:Connect(function(player, itemName)
	local success = false
	if player and itemName and Items[itemName] then
		local backpack = player:WaitForChild("Backpack")
		local playerCoins = DataStoreModule.GetPlayerCoins(player)
		local itemPrice = Items[itemName].price
		local physicalItem = PhysicalItemFolder:FindFirstChild(itemName)

		if playerCoins >= itemPrice and physicalItem then
			local clone = physicalItem:Clone()
			clone.Parent = backpack

			DataStoreModule.RemoveCoins(player, itemPrice)
			DataStoreModule.GiveItem(player, itemName)
			success = true
		end
	end

	BoughtSuccess:FireClient(player, itemName, success)
end)

Players.PlayerAdded:Connect(function(player)
	task.delay(3, function()
		giveOwnedItems(player)
	end)

	player.CharacterAdded:Connect(function()
		task.delay(1, function()
			giveOwnedItems(player)
		end)
	end)
end)
