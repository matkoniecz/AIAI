function IsForSell(vehicle_id)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle " + vehicle_id);
local name=AIVehicle.GetName(vehicle_id)+"            ";
local forsell="for sell";

for(local i=0; i<forsell.len(); i++)
if(name[i]!=forsell[i]) return false;
return true;
}

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

function SetNameOfVehicle(vehicle_id, string)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle " + vehicle_id);
local i = 1;
for(;!AIVehicle.SetName(vehicle_id, string + " #" + i); i++)
	{
	//Error("SetNameOfVehicle: " + AIError.GetLastErrorString() + ": " + string);
	if(AIError.GetLastError() == AIError.ERR_PRECONDITION_STRING_TOO_LONG) SetNameOfVehicle(vehicle_id, "PRECONDITION_FAILED");
	}
}

function IsItNeededToImproveThatStation(station, cargo)
{
return AIStation.GetCargoWaiting(station, cargo)>50 || (AIStation.GetCargoRating(station, cargo)<40&&AIStation.GetCargoWaiting(station, cargo)>0) ;
}

function IsItNeededToImproveThatNoRawStation(station, cargo)
{
return AIStation.GetCargoWaiting(station, cargo)>150 || (AIStation.GetCargoRating(station, cargo)<40&&AIStation.GetCargoWaiting(station, cargo)>0) ;
}

function GetDepotLocation(vehicle)
{
if (!AIVehicle.IsValidVehicle(vehicle)) abort("invalid vehicle: " + vehicle);
local depot_location = LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(GetLoadStationLocation(vehicle)), "[]");
if(AIMap.IsValidTile(depot_location)) return depot_location;
//for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) if(AIOrder.IsGotoDepotOrder(vehicle, i)) return AIOrder.GetOrderDestination(vehicle, i);
abort("Explosion caused by vehicle " + AIVehicle.GetName(vehicle)+ " depot_location from station name is "+depot_location);
}

function GetLoadStationLocation(vehicle)
{
if (!AIVehicle.IsValidVehicle(vehicle)) abort("invalid vehicle: " + vehicle);
for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) if(AIOrder.IsGotoStationOrder(vehicle, i)) return AIOrder.GetOrderDestination(vehicle, i);
abort("Explosion caused by vehicle " + AIVehicle.GetName(vehicle));
}

function GetUnloadStationLocation(vehicle)
{
if (!AIVehicle.IsValidVehicle(vehicle)) abort("invalid vehicle: " + vehicle);

local onoff = false;
for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) {
   if(AIOrder.IsGotoStationOrder(vehicle, i)) {
	  if(onoff==true) return AIOrder.GetOrderDestination(vehicle, i);
	  onoff=true
	  }
   }
abort("Explosion caused by vehicle " + AIVehicle.GetName(vehicle));
}

function Name()
	{
	if((AICompany.GetName(AICompany.COMPANY_SELF)!="AIAI")&&(AIVehicleList().Count()>0)){
		while(true){
			Info("Company created by other ai. As such it is not possible for AIAI to menage that company.");
			Info("Zzzzz...")
			Sleep(1000);
			}
		}
	AICompany.SetPresidentName("http://tinyurl.com/ottdaiai");
	AICompany.SetName("AIAI");
	if (AICompany.GetName(AICompany.COMPANY_SELF)!="AIAI"){
			if(!AICompany.SetName("Suicide AIAI")){
			local i = 2;
			while (!AICompany.SetName("Suicide AIAI #" + i))i++;
			}
		Money.BurnMoney();
		while(true) Sleep(1000);
		}
	}

	
function AIAI::HQ() //from Rondje
	{
	if(AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) return;//from simpleai
	// Find biggest town for HQ
	local towns = AITownList();
	towns.Valuate(AITown.GetPopulation);
	towns.Sort(AIList.SORT_BY_VALUE, false);
	local town = towns.Begin();
	
	// Find empty 2x2 square as close to town centre as possible
	local maxRange = Sqrt(AITown.GetPopulation(town)/100) + 5;
	local HQArea = AITileList();
			
	HQArea.AddRectangle(AITown.GetLocation(town) - AIMap.GetTileIndex(maxRange, maxRange), AITown.GetLocation(town) + AIMap.GetTileIndex(maxRange, maxRange));
	HQArea.Valuate(AITile.IsBuildableRectangle, 2, 2);
	HQArea.KeepValue(1);
	HQArea.Valuate(AIMap.DistanceManhattan, AITown.GetLocation(town));
	HQArea.Sort(AIList.SORT_BY_VALUE, true);

	Info("Building company HQ...");
	for (local tile = HQArea.Begin(); HQArea.HasNext(); tile = HQArea.Next()){
		if(AICompany.BuildCompanyHQ(tile)){
			if(AIAI.GetSetting("hide_ad") != 1)
			{
				AISign.BuildSign(tile, "In case of strange or stupid")
				AISign.BuildSign(tile+AIMap.GetTileIndex(1, 1), "AIAI behaviour, please");
				AISign.BuildSign(tile+AIMap.GetTileIndex(2, 2), "report it on");
				AISign.BuildSign(tile+AIMap.GetTileIndex(3, 3), "http://tinyurl.com/ottdaiai");
			}
			return;
			} 
		}
		
	Info("No possible HQ location found");
	}

function IsConnectedIndustryUsingThisAirport(industry, cargo_id, airport_type)
{
local radius = AIAirport.GetAirportCoverageRadius(airport_type);

local tile_list=AITileList_IndustryProducing(industry, radius);
for (local q = tile_list.Begin(); tile_list.HasNext(); q = tile_list.Next()) //from Chopper 
	{
	local station_id = AIStation.GetStationID(q);
	if(AIAirport.IsAirportTile(q))
	if(AIAirport.GetAirportType(q)==airport_type)
		{
		if(IsCargoLoadedOnThisStation(station_id, cargo_id))return true;
		}
	}
return false;
}

function IsConnectedIndustry(industry_id, cargo_id)
{
if(AIStationList(AIStation.STATION_ANY).IsEmpty()) return false;

local tile_list=AITileList_IndustryProducing(industry_id, AIStation.GetCoverageRadius(AIStation.STATION_TRAIN));
for(local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next())
	{
	local station_id = AIStation.GetStationID(tile);
	if(AIStation.IsValidStation(station_id))
		if(AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL)) //check for railstation (workaround, as there is no equivalent of IsAirportTile. this hack will fail with eyecandy station tiles without rail)
			if(IsCargoLoadedOnThisStation(station_id, cargo_id))return true;
	}

local tile_list=AITileList_IndustryProducing(industry_id, AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP)); //assumes that STATION_BUS_STOP have the same coverage
for(local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next())
	{
	local station_id = AIStation.GetStationID(tile);
	if(AIStation.IsValidStation(station_id))
		if(AITile.HasTransportType(tile, AITile.TRANSPORT_ROAD)) //check for railstation (workaround, as there is no equivalent of IsAirportTile. this hack will fail with eyecandy station tiles without rail)
			if(IsCargoLoadedOnThisStation(station_id, cargo_id))return true;
	}

if(IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_LARGE)) return true;
if(IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_METROPOLITAN)) return true;
if(IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_COMMUTER)) return true;
if(IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_SMALL)) return true;
return false;
}
