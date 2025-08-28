local UIEvent = game.ReplicatedStorage.Remotes.UI.OpenShop
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ShopContainer = PlayerGui:WaitForChild("Shop")
local ShopUI = ShopContainer:WaitForChild("Canvas")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UImodule = require(ReplicatedStorage.UI)


UIEvent.OnClientEvent:Connect(function()
	UImodule.TweenActive(ShopUI)
end)
