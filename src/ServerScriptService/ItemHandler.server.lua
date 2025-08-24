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
            -- Ensure itemName is a string
            itemName = tostring(itemName)
            
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
                    local clone = physicalItem:Clone()
                    clone.Parent = backpack
                end
            end
        end
    end
end

BoughtEvent.OnServerEvent:Connect(function(player, itemName)
    local success = false
    
    -- Debug prints
    print("Purchase attempt by:", player.Name)
    print("Item name received:", itemName, "Type:", type(itemName))
    
    -- Validate inputs
    if not player or not itemName then
        print("Invalid player or itemName")
        BoughtSuccess:FireClient(player, itemName or "", success)
        return
    end
    
    -- Ensure itemName is a string
    itemName = tostring(itemName)
    print("Item name after tostring:", itemName)
    
    -- Check if item exists in the Items module
    if Items[itemName] then
        print("Item found in Items module")
        local backpack = player:WaitForChild("Backpack")
        local playerCoins = DataStoreModule.GetPlayerCoins(player)
        local itemPrice = Items[itemName].price
        local physicalItem = PhysicalItemFolder:FindFirstChild(itemName)
        
        print("Player coins:", playerCoins)
        print("Item price:", itemPrice)
        print("Physical item exists:", physicalItem ~= nil)
        
        -- Check if player has enough coins and item exists
        if playerCoins >= itemPrice and physicalItem then
            print("Purchase conditions met, processing...")
            local clone = physicalItem:Clone()
            clone.Parent = backpack
            DataStoreModule.RemoveCoins(player, itemPrice)
            DataStoreModule.GiveItem(player, itemName)
            success = true
            print("Purchase successful!")
        else
            print("Purchase failed - insufficient coins or item not found")
        end
    else
        print("Item not found in Items module. Available items:")
        for itemKey, _ in pairs(Items) do
            print(" -", itemKey)
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