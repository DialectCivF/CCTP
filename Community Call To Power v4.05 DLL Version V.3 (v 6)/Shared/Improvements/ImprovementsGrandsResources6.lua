print("---ImprovementsGrandsResources6---");
include( "SaveUtils" ); MY_MOD_NAME = "ImprovementsGrandsResources6";

--remote installation registry. Every time after modifying, make sure to call updateSaveData()
local aTipi = {};

local mapMaxX, mapMaxY = Map.GetGridSize();



function onImprovementCreated(iHexX, iHexY)
	local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY));
	if (pPlot~= nil) then
		local improvementType = pPlot:GetImprovementType();
		if(improvementType == GameInfoTypes.IMPROVEMENT_TIPI) then
	
			local plotID = pPlot:GetX() + pPlot:GetY() * mapMaxX;
			
			--local playerTeamID = Game.GetActiveTeam();
			local playerID = pPlot:GetOwner();		
			
			local isPillaged = pPlot:IsImprovementPillaged();		
			
			if(isPillaged) then
				if( aTipi[plotID]~=nil and aTipi[plotID].PlayerID ) then
					--need to take back Manpower resource
					DisconnectManpower( plotID, playerID );
				end
				print("Tipi Pillaged at plot ID:", plotID);
			else
				--we don't want to overwrite data if registered mine already exists on site
				if(aTipi[plotID]==nil) then
					print("Tipi Built or Repaired", plotID);
					ConnectManpower( plotID, playerID );
				end
			end
		
		end
	end
end
Events.SerialEventImprovementCreated.Add(onImprovementCreated)


function onImprovementDestroyed(iHexX, iHexY)
	local plotX, plotY = ToGridFromHex(iHexX, iHexY);
	local plotID = plotX + plotY * mapMaxX;
	
	if(aTipi[plotID]) then
		--local improvementType = pPlot:GetImprovementType();
		--if(improvementType == GameInfoTypes.IMPROVEMENT_TIPI) then

		-- there used to be Tipi here - remove it
		print("onImprovementDestroyed: TipiDestroyed");
		DisconnectManpower( plotID, aTipi[plotID].PlayerID );
	end
	
end
Events.SerialEventImprovementDestroyed.Add(onImprovementDestroyed)


function onPlotOwnershipChange(iHexX, iHexY)
	local plotX, plotY = ToGridFromHex(iHexX, iHexY);
	local plotID = plotX + plotY * mapMaxX;	
	
	if(aTipi[plotID]) then
		print("onPlotOwnershipChange: Tipi Ownership hac changed");
		DisconnectManpower( plotID, aTipi[plotID].PlayerID );
		local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY));
		if(pPlot) then
			local newOwner = pPlot:GetOwner();
			ConnectManpower( plotID, newOwner );
		else
			print("ERROR in TipiControl: Map.GetPlot returned nil");
		end
	end
	
end
Events.SerialEventHexCultureChanged.Add(onPlotOwnershipChange)

--Events.SerialEventCityCaptured.Add(CityCultureOnCapture)


function ConnectManpower( plotID, playerID )
	
	local pPlayer = Players[playerID];
	local iResourceID = GameInfoTypes.RESOURCE_MANPOWER;
	local iResourceNum = 1;

	if(pPlayer) then
		pPlayer:ChangeNumResourceTotal(iResourceID, iResourceNum);
	end

	--register/update mine status
	aTipi[plotID] = {};
	aTipi[plotID].PlayerID = playerID;
	updateSaveData(plotID);
	
	print("Connected resource ", iResourceID, " for player ", playerID, "amount:", iResourceNum);
end


function DisconnectManpower( plotID, playerID )

	local pPlayer = Players[playerID];
	local iResourceID = GameInfoTypes.RESOURCE_MANPOWER;
	local iResourceNum = 1;

	if(pPlayer) then
		pPlayer:ChangeNumResourceTotal(iResourceID, -iResourceNum);
	end
	
	--update Tipi status
	--aTipi[plotID].PlayerID = false;
	aTipi[plotID] = nil;
	updateSaveData(plotID);
	
	print("Disconnected resource ", iResourceID, " for player ", playerID, "amount:", iResourceNum);
end


function updateSaveData(plotID)
	local pPlayer = Players[Game.GetActivePlayer()];
	save( pPlayer, plotID, aTipi[plotID] );
end


function loadSaveData()
	local pPlayer = Players[Game.GetActivePlayer()];
	local wholeTable = load( pPlayer );
	for plotID, v in pairs(wholeTable) do
		print("plotID:",plotID);
		for ii,kk in pairs(v) do
			print(ii,kk);
		end
		
		aTipi[plotID] = v;
		
	end
end
loadSaveData();	--call on startup
