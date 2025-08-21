local rs = game:GetService("ReplicatedStorage")
local event = rs.Remotes.UI.ResetPlayerData
local ds = require(rs.Modules.DataStore)

event.OnServerEvent:Connect(function(player:Player, whatToReset:string)
	local resetNumber = 0 
	
	if whatToReset == "Checkpoint" then
		ds.SetCheckpoint(player, 1)
		
	elseif whatToReset == "Coins" then
		ds.SetCoins(player, resetNumber)
		
	elseif whatToReset == "Pets" then
		ds.RemoveAllPets(player)
		
	elseif whatToReset == "All" then
		ds.SetCheckpoint(player, 1)
		ds.SetCoins(player, resetNumber)
		ds.RemoveAllPets(player)
		ds.SetRebirths(player, 0)
		
	elseif whatToReset == "MaxCheckpoint" then
		ds.SetCheckpoint(player, 30)
	end
end)