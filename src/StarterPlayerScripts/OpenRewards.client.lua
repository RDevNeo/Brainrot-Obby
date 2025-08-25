local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OpenIndex:RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UI"):WaitForChild("OpenRewards")
local UiModule = require(ReplicatedStorage.UI)
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("Rewards")
local Canvas = ScreenGui:WaitForChild("Canvas")


OpenIndex.OnClientEvent:Connect(function()
    UiModule.TweenActive(Canvas)
end)