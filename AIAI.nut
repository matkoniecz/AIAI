function AIAI::IsTileWrongToFullUse(tile)
{
return ((!AITile.IsBuildable(tile))||!(AITile.SLOPE_FLAT == AITile.GetSlope(tile)));
}

function AIAI::IsTileWithAuthorityRefuse(tile)
{
local town_id=AITile.GetClosestTown (tile);
if(AITown.GetRating (town_id, AICompany.COMPANY_SELF) == AITown.TOWN_RATING_APPALLING) 
   {
   return true;
   }
if(AITown.GetRating (town_id, AICompany.COMPANY_SELF) == AITown.TOWN_RATING_VERY_POOR)
   {
   return true;
   }
return false;
}

function AIAI::ZbudujStatue()
{
local veh_list = AIVehicleList();
veh_list.Valuate(AIBase.RandItem);
veh_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
for (local veh = veh_list.Begin(); veh_list.HasNext(); veh = veh_list.Next()) 
   {
   AILog.Error(AIVehicle.GetName(veh));
   for(local i=0; i<AIOrder.GetOrderCount(veh); i++)
      {
	  AILog.Warning(i+"");
	  local location = AIOrder.GetOrderDestination(veh, i);
	  if(AITile.IsStationTile(location))
		{
  	    AILog.Warning("OK");
	    if(AIOrder.GetOrderFlags(veh, i)!=AIOrder.AIOF_NO_LOAD)
		   {
  	       AILog.Info("OK");
		   if(AITown.PerformTownAction(AITile.GetClosestTown(location), AITown.TOWN_ACTION_BUILD_STATUE)) 
		      {
			  return true;
			  }
		   else
		      {
			  AILog.Error(AIError.GetLastErrorString());
		      if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) return false;
			  }
		   }
		}
	  }
   }

return false;
AILog.Error("Fail");
   
local list = AIStationList(AIStation.STATION_ANY);
for (local aktualna = list.Begin(); list.HasNext(); aktualna = list.Next()) 
    {
	if(AITown.PerformTownAction(AITile.GetClosestTown (AIStation.GetLocation(aktualna)), AITown.TOWN_ACTION_BUILD_STATUE))return true;
		   //jesli za malo kasy to return false;
	}
return false;
}

function AIAI::HQ() //from Rondje
{
if(AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) return;//from simpleai

// Find biggest town for HQ
local towns = AITownList();
towns.Valuate(AITown.GetPopulation);
towns.Sort(AIAbstractList.SORT_BY_VALUE, false);
local town = towns.Begin();

// Find empty 2x2 square as close to town centre as possible
local maxRange = Sqrt(AITown.GetPopulation(town)/100) + 5; //TODO check value correctness
local HQArea = AITileList();
		
HQArea.AddRectangle(AITown.GetLocation(town) - AIMap.GetTileIndex(maxRange, maxRange), AITown.GetLocation(town) + AIMap.GetTileIndex(maxRange, maxRange));
HQArea.Valuate(AITile.IsBuildableRectangle, 2, 2);
HQArea.KeepValue(1);
HQArea.Valuate(AIMap.DistanceManhattan, AITown.GetLocation(town));
HQArea.Sort(AIList.SORT_BY_VALUE, true);

Debug("Building company HQ...");
for (local tile = HQArea.Begin(); HQArea.HasNext(); tile = HQArea.Next()) 
    {
	if (AICompany.BuildCompanyHQ(tile)) {
			AISign.BuildSign(tile, "AIAI HQ");
			return;
		} 
	}
		
Debug("No possible HQ location found");
}
