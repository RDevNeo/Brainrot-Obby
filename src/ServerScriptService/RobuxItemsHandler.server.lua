local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local itemsModule = require(ReplicatedStorage.Modules.RobuxItems)
local items = itemsModule.Items

local itemFolder = ReplicatedStorage:WaitForChild("ItemsFolder"):WaitForChild("RobuxShopItems")

local function giveItem(player, itemName)
	local template = itemFolder:FindFirstChild(itemName)
	if not template then
		warn("No tool named", itemName, "inside ShopItems folder")
		return
	end

	local clone1 = template:Clone()
	clone1.Parent = player.Backpack

	local clone2 = template:Clone()
	clone2.Parent = player:WaitForChild("StarterGear")
end

local gamepassLookup = {}
for name, info in pairs(items) do
	gamepassLookup[info.gamepassId] = name
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end

	local itemName = gamepassLookup[passId]
	if itemName then
		giveItem(player, itemName)
	end
end)

local function checkPlayerGamepasses(player)
	for itemName, itemInfo in pairs(items) do
		local gamepassId = itemInfo.gamepassId

		local owns = false
		local success, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)
		if success and result then
			owns = true
		end

		if owns then
			giveItem(player, itemName)
		end
	end
end

Players.PlayerAdded:Connect(checkPlayerGamepasses)
