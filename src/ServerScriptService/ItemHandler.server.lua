local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local ItemsModule = require(ReplicatedStorage.Items)
local Items = ItemsModule.Items
local PhysicalItems = ReplicatedStorage.ItemsFolder.Items

local function checkIfOwns(player)
	for itemName, itemData in pairs(Items) do
		local success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, itemData.gamepassId)
		end)

		if success and owns then
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
	end
end

Players.PlayerAdded:Connect(function(player)
	RunService.Heartbeat:Connect(function()
		if player and player.Parent == Players then
			checkIfOwns(player)
		end
	end)
end)
