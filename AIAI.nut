function AIAI::GetIndustryList()
{
local list = AIIndustryList();
list.Valuate(AIIndustry.GetDistanceManhattanToTile, root_tile);
list.KeepBottom(200);
return list;
}

function AIAI::GetIndustryList_CargoAccepting(cargo)
{
local list = AIIndustryList_CargoAccepting(cargo);
list.Valuate(AIIndustry.GetDistanceManhattanToTile, root_tile);
list.KeepBottom(200);
return list;
}

function AIAI::GetIndustryList_CargoProducing(cargo)
{
local list = AIIndustryList_CargoProducing(cargo);
list.Valuate(AIIndustry.GetDistanceManhattanToTile, root_tile);
list.KeepBottom(200);
return list;
}

function AIAI::DeleteVehiclesInDepots()
	{
	local counter=0;
	local list=AIVehicleList();
	for (local q = list.Begin(); list.HasNext(); q = list.Next()){ //from Chopper 
		if(AIVehicle.IsStoppedInDepot(q)){
			AIVehicle.SellVehicle(q);
			counter++;
		}
	}
	return counter;
	}

function AIAI::IsTileWrongToFullUse(tile)
	{
	return ((!AITile.IsBuildable(tile))||!(AITile.SLOPE_FLAT == AITile.GetSlope(tile)));
	}

function AIAI::IsTileWithAuthorityRefuse(tile)
	{
	local town_id=AITile.GetClosestTown (tile);
	if(AITown.GetRating (town_id, AICompany.COMPANY_SELF) == AITown.TOWN_RATING_APPALLING)return true;
	if(AITown.GetRating (town_id, AICompany.COMPANY_SELF) == AITown.TOWN_RATING_VERY_POOR)return true;
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
	local maxRange = Sqrt(AITown.GetPopulation(town)/100) + 5;
	local HQArea = AITileList();
			
	HQArea.AddRectangle(AITown.GetLocation(town) - AIMap.GetTileIndex(maxRange, maxRange), AITown.GetLocation(town) + AIMap.GetTileIndex(maxRange, maxRange));
	HQArea.Valuate(AITile.IsBuildableRectangle, 2, 2);
	HQArea.KeepValue(1);
	HQArea.Valuate(AIMap.DistanceManhattan, AITown.GetLocation(town));
	HQArea.Sort(AIList.SORT_BY_VALUE, true);

	Debug("Building company HQ...");
	for (local tile = HQArea.Begin(); HQArea.HasNext(); tile = HQArea.Next()){
		if(AICompany.BuildCompanyHQ(tile)){
			AISign.BuildSign(tile, "In case of strange or stupid AIAI behaviour send mail on bulwersator@gmail.com");
			return;
			} 
		}
		
	Debug("No possible HQ location found");
	}

function AIAI::Autoreplace()
{
Info("Autoreplace started");
AutoreplaceRV();
AutoreplaceSmallPlane();
AutoreplaceBigPlane();
Info("Autoreplace list updated by Autoreplace() from AIAI.nut");
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
	
   if(AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = (AirBuilder(this, 0)).FindAircraft(AIAirport.AT_LARGE, cargo, 1, 100000000)
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
engine_list.KeepValue(AIAirport.PT_SMALL_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = (AirBuilder(this, 0)).FindAircraft(AIAirport.AT_SMALL, cargo, 1, 100000000)
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
	
   if(AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = (RoadBuilder(this, 0)).GetReplace(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing), cargo);
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}