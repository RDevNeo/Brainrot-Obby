local gameId = 138645146195597
local player = game.Players.LocalPlayer
local AvatarEditorService = game:GetService("AvatarEditorService")


local function promptFavorite(player)
	AvatarEditorService:PromptSetFavorite(gameId, Enum.AvatarItemType.Asset, true)
end

if player then
	task.wait(10)
	promptFavorite()
end