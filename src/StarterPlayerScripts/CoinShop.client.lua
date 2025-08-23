local UIEvent = game.ReplicatedStorage.Remotes.UI.UICoin
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CoinUI = PlayerGui:WaitForChild("CoinShop"):WaitForChild("Canvas")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UImodule = require(ReplicatedStorage.UI)


UIEvent.OnClientEvent:Connect(function()
	UImodule.TweenActive(CoinUI)
end)
