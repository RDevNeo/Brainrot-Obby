local UIEvent = game.ReplicatedStorage.Remotes.UI.UICoin
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CoinUIContainer = PlayerGui:WaitForChild("CoinShop")
local CoinUI = CoinUIContainer:WaitForChild("Canvas")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UImodule = require(ReplicatedStorage.UI)


UIEvent.OnClientEvent:Connect(function()
	if CoinUI then
		print("CoinShop UI active: ", CoinUI.Name, CoinUI.Position)
		UImodule.TweenActive(CoinUI)
	else
		warn("CoinShop UI (Canvas) not found!")
	end
end)
