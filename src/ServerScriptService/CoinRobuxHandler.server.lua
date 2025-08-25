local gamepassIDone = 3384035028
local gamepassIDtwo = 3384035197
local gamepassIDthree = 3384034813

local MarketplaceService = game:GetService("MarketplaceService")
local DataStore = require(game.ReplicatedStorage.DataStore)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local amountToGive = 0

	if productId == gamepassIDone then
		amountToGive = 199
	elseif productId == gamepassIDtwo then
		amountToGive = 399
	elseif productId == gamepassIDthree then
		amountToGive = 599
	end

	if amountToGive > 0 then
		DataStore.AddCoins(player, amountToGive)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end