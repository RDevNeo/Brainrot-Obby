local rs = game:GetService("ReplicatedStorage")
local event = rs.Remotes.UI.ResetPlayerData
local ds = require(rs.DataStore)
local helperModule = require(game.ReplicatedStorage.Helper)

event.OnServerEvent:Connect(function(player:Player, whatToReset:string)
	local resetNumber = 0 
	
	if whatToReset == "Checkpoint" then
		ds.SetCheckpoint(player, 1)
		
	elseif whatToReset == "MaxCheckpoint" then
		ds.SetCheckpoint(player, helperModule.GetAllCheckpoints())
		
	elseif whatToReset == "RemovePets" then
		ds.RemoveAllPets(player)
	end
end)