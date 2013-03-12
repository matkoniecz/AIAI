function AIAI::GetIndustryList()
{
local list = AIIndustryList();
list.Valuate(AIIndustry.GetDistanceManhattanToTile, root_tile);
list.KeepTop(300);
return list;
}

function AIAI::GetIndustryList_CargoAccepting(cargo)
{
local list = AIIndustryList_CargoAccepting(cargo);
list.Valuate(AIIndustry.GetDistanceManhattanToTile, root_tile);
list.KeepTop(300);
return list;
}

function AIAI::GetIndustryList_CargoProducing(cargo)
{
local list = AIIndustryList_CargoProducing(cargo);
list.Valuate(AIIndustry.GetDistanceManhattanToTile, root_tile);
list.KeepTop(300);
return list;
}

function AIAI::DeleteVehiclesInDepots()
{
local ile=0;

local list=AIVehicleList();
for (local q = list.Begin(); list.HasNext(); q = list.Next()) //from Chopper 
   {
   if(AIVehicle.IsStoppedInDepot(q))
      {
	  AIVehicle.SellVehicle(q);
	  ile++;
	  }
   }
return ile;
}

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
   for(local i=0; i<AIOrder.GetOrderCount(veh); i++)
      {
	  local location = AIOrder.GetOrderDestination(veh, i);
	  if(AITile.IsStationTile(location))
		{
	    if(AIOrder.GetOrderFlags(veh, i)!=AIOrder.AIOF_NO_LOAD)
		{
		local station = AIStation.GetStationID(location);
		local suma = 0;
		local cargo_list = AICargoList();
		for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) suma+=AIStation.GetCargoWaiting(station, cargo);
		if(suma<200) //HARDCODED
		   {
		   if(AITown.PerformTownAction(AITile.GetClosestTown(location), AITown.TOWN_ACTION_BUILD_STATUE)) 
		      {
			  Warning("Statue for " + AIVehicle.GetName(veh));
			  return true;
			  }
		   else
		      {
		      if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) return false;
			  }
		   }
		  }
		}
	  }
   }

Error("Fail");
return false;
   
local list = AIStationList(AIStation.STATION_ANY);
for (local aktualna = list.Begin(); list.HasNext(); aktualna = list.Next()) 
    {
	if(AITown.PerformTownAction(AITile.GetClosestTown (AIStation.GetLocation(aktualna)), AITown.TOWN_ACTION_BUILD_STATUE))return true;
    if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) return false;
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
			AISign.BuildSign(tile, "In case of strange or stupid AIAI behaviour send mail on bulwersator@gmail.com");
			return;
		} 
	}
		
Debug("No possible HQ location found");
}

function AIAI::Autoreplace()
{
AutoreplaceRV();
AutoreplaceSmallPlane();
AutoreplaceBigPlane();
Warning("Autoreplace list updated by Autoreplace() from util.nut");
}

function AIAI::AutoreplaceBigPlane()
{
local engine_list=AIEngineList(AIVehicle.VT_AIR);
engine_list.Valuate(AIEngine.GetPlaneType);
engine_list.KeepValue(AIAirport.PT_BIG_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsValidEngine(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = KWAI.FindAircraft(AIAirport.AT_LARGE, cargo, 1, 100000000)
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function AIAI::AutoreplaceSmallPlane()
{
local engine_list=AIEngineList(AIVehicle.VT_AIR);
engine_list.Valuate(AIEngine.GetPlaneType);
engine_list.RemoveValue(AIAirport.PT_BIG_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsValidEngine(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = KWAI.FindAircraft(AIAirport.AT_SMALL, cargo, 1, 100000000)
	  if(engine_best != null)
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function AIAI::GetMailCargoId()
{
local list = AICargoList();
for (local i = list.Begin(); list.HasNext(); i = list.Next()) 
	{
	if(AICargo.GetTownEffect(i)==AICargo.TE_MAIL)
		{
		return i;
		}
	}
return null;
}

function AIAI::GetPassengerCargoId()
{
local cargo_list = AICargoList();
cargo_list.Valuate(AICargo.HasCargoClass, AICargo.CC_PASSENGERS);
cargo_list.KeepValue(1);
cargo_list.Valuate(AICargo.GetTownEffect);
cargo_list.KeepValue(AICargo.TE_PASSENGERS);
cargo_list.Valuate(AICargo.GetTownEffect);
cargo_list.KeepValue(AICargo.TE_PASSENGERS);

if(!AICargo.IsValidCargo(cargo_list.Begin()))
{
	Error("PAX Cargo do not exist");
}

cargo_list.Valuate(AICargo.GetCargoIncome, 1, 1); //Elimination ECS tourists
cargo_list.KeepBottom(1);

return cargo_list.Begin();
}


function AIAI::AutoreplaceRV()
{
local engine_list=AIEngineList(AIVehicle.VT_ROAD);
engine_list.Valuate(AIEngine.GetRoadType);
engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsValidEngine(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = RV.GetReplace(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing), cargo);
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}