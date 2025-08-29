local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local MarketplaceService = game:GetService("MarketplaceService")
local GlobalMessagesEvent = game.ReplicatedStorage.Remotes.GlobalMessages
local GlobalMessagesHelper = require(ReplicatedStorage.GlobalMessagesHelper)
local AllItems = GlobalMessagesHelper.Items
local systemChannel = TextChatService:WaitForChild("TextChannels"):FindFirstChild("RBXSystem")
local playerName = game.Players.LocalPlayer.Name

GlobalMessagesEvent.OnClientEvent:Connect(function(productId)
    local foundItem = nil
    for _, item in pairs(AllItems) do
        if item.gamepassId == productId then
            foundItem = item
            break
        end
    end

    if foundItem then
        local type = foundItem.type
        local robuxCode = "\u{E002}"

        if type == "Gamepass" then
            local info = MarketplaceService:GetProductInfo(productId, Enum.InfoType.GamePass)
            local itemName = info.Name
            local itemPrice = info.PriceInRobux

            local text = playerName .. " has bought the " .. itemName .. " for " .. itemPrice .. robuxCode
            systemChannel:DisplaySystemMessage(text)

        elseif type == "Developer" then
            local info = MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
            local itemName = info.Name
            local itemPrice = info.PriceInRobux

            local text = playerName .. " has bought the " .. itemName .. " for " .. itemPrice .. robuxCode
            systemChannel:DisplaySystemMessage(text)

        end
    end
end)