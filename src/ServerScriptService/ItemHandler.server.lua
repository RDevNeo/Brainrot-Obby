local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local GlobalMessagesEvent = ReplicatedStorage.Remotes.GlobalMessages
local ItemsModule = require(ReplicatedStorage.Items)
local Items = ItemsModule.Items
local PhysicalItems = ReplicatedStorage.ItemsFolder.Items

local function giveItemToPlayer(player, itemName)
    if not player then return end
    if not player:FindFirstChild("Backpack") or not player:FindFirstChild("StarterGear") then
        repeat task.wait() until player:FindFirstChild("Backpack") and player:FindFirstChild("StarterGear")
    end

    if not player.Backpack:FindFirstChild(itemName) and not player.StarterGear:FindFirstChild(itemName) then
        local physicalItem = PhysicalItems:FindFirstChild(itemName)
        if physicalItem then
            local clone1 = physicalItem:Clone()
            clone1.Parent = player.Backpack

            local clone2 = physicalItem:Clone()
            clone2.Parent = player.StarterGear
        else
            warn("Physical item not found for: " .. itemName)
        end
    end
end

local function checkIfOwns(player)
    for itemName, itemData in pairs(Items) do
        local ok, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, itemData.gamepassId)
        end)

        if ok and owns then
            giveItemToPlayer(player, itemName)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    checkIfOwns(player)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    if not wasPurchased then return end

    local ok, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
    end)

    if not ok or not owns then
        warn(("Purchase confirmation failed for %s (passId=%s). owns=%s, ok=%s"):format(
            player.Name, tostring(gamePassId), tostring(owns), tostring(ok)
        )) return end

    for itemName, itemData in pairs(Items) do
        if itemData.gamepassId == gamePassId then
            giveItemToPlayer(player, itemName)
            break
        end
    end

	if GlobalMessagesEvent then
        GlobalMessagesEvent:FireClient(player, gamePassId)
    end
end)
