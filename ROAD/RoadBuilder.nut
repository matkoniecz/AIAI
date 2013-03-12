import("pathfinder.road", "RoadPathFinder", 3);

class RoadBuilder extends Builder
{
desperation=0;
rodzic=null;
cost=0;
detected_rail_crossings = null;
path = null;

trasa = null;
}

require("KRAI_level_crossing_menagement_from_clueless_plus.nut");
require("KRAIpathfinder.nut");

/////////////////////////////////////////////////
/// Age of the youngest vehicle (in days)
/////////////////////////////////////////////////
function RoadBuilder::IsConnectedIndustry(industry_id, cargo)
{
if(AIStationList(AIStation.STATION_ANY).IsEmpty()) return false;

local tile_list=AITileList_IndustryProducing(industry_id, 3);
for(local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next())
   {
   local station_id = AIStation.GetStationID(tile);
   if(AIStation.IsValidStation(station_id))
      {
	  local vehicle_list=AIVehicleList_Station(station_id);
	  if(vehicle_list.Count()!=0)
	  if(AIStation.GetStationID(GetLoadStationLocation(vehicle_list.Begin()))==station_id) //czy full load jest na wykrytej stacji
	  {
	  if(AIVehicle.GetCapacity(vehicle_list.Begin(), cargo)!=0)//i laduje z tej stacji
	     {
		 return true;
		 }
	  }
	  }
   }
return false;
}

function RoadBuilder::Maintenance()
{
local new = this.AddTruck() + this.AddBus();
local redundant = this.RemoveRedundantRV();
if((new+redundant)>0) Info("RoadBuilder: Vehicles: " + new + " new, " +  redundant + " redundant send to depot.");
}

function RoadBuilder::GetMinDistance()
{
return 10;
}

function RoadBuilder::GetMaxDistance()
{
if(desperation>5) return desperation*75;
return 150+desperation*50;
}

function RoadBuilder::distanceBetweenIndustriesValuator(distance)
{
if(distance>GetMaxDistance()) return 0;
if(distance<GetMinDistance()) return 0;

if(desperation>5)
   {
   if(distance>desperation*60) return 1;
   return 4;
   }

if(distance>100+desperation*50) return 1;
if(distance>85) return 2;
if(distance>70) return 3;
if(distance>55) return 4;
if(distance>40) return 3;
if(distance>25) return 2;
if(distance>10) return 1;
return 0;
}

function RoadBuilder::BuildRVStation(type)
{
	if(!AIRoad.BuildDriveThroughRoadStation(trasa.first_station.location, trasa.start_otoczka[0], type, AIStation.STATION_NEW)) 
	{
		Warning("<")
		rodzic.HandleFailedStationConstruction(trasa.first_station.location, AIError.GetLastError());
		Warning(">")
		if(!AIRoad.BuildDriveThroughRoadStation(trasa.first_station.location, trasa.start_otoczka[0], type, AIStation.STATION_NEW))
		{
			Info("   Producer station placement impossible due to A " + AIError.GetLastErrorString());
			if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString());
			return false;
		}
	}
	if(!AIRoad.BuildDriveThroughRoadStation(trasa.second_station.location, trasa.koniec_otoczka[0], type, AIStation.STATION_NEW)) 
	{
		Warning("<")
		rodzic.HandleFailedStationConstruction(trasa.second_station.location, AIError.GetLastError());
		Warning(">")
		if(!AIRoad.BuildDriveThroughRoadStation(trasa.second_station.location, trasa.koniec_otoczka[0], type, AIStation.STATION_NEW)) 
		{
			Info("   Consumer station placement impossible due to B " + AIError.GetLastErrorString());
			AIRoad.RemoveRoadStation(trasa.first_station.location);
			if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString());
			return false;
		}
	}
	return RoadToStation();
}
	
function RoadBuilder::RoadToStation()
{
if(!AIRoad.BuildRoad(trasa.start_otoczka[1], trasa.first_station.location))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
	  Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.second_station.location);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.first_station.location, trasa.start_otoczka[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.second_station.location);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.koniec_otoczka[1], trasa.second_station.location))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.second_station.location);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.second_station.location, trasa.koniec_otoczka[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.second_station.location);
      return false;
	  }
   }
return true;
}

function RoadBuilder::ValuateProducer(ID, cargo)
{
   local base = AIIndustry.GetLastMonthProduction(ID, cargo);
   base*=(100-AIIndustry.GetLastMonthTransportedPercentage (ID, cargo));
   if(AIIndustry.GetLastMonthTransportedPercentage (ID, cargo)==0)base*=3;
   base*=AICargo.GetCargoIncome(cargo, 10, 50);
   if(base!=0)
	  if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(ID)))
		{
		//base*=3;
	    //base/=2;
		base+=10000;
	    }
	  else
	    {
		base-=base/2;
		}
//Info(AIIndustry.GetName(ID) + " is " + base + " point producer of " + AICargo.GetCargoLabel(cargo));
return base;
}

function RoadBuilder::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
//Info("   " + AIIndustry.GetName(ID) + " is " + score + " point consumer of " + AICargo.GetCargoLabel(cargo));
return score;
}

function RoadBuilder::GetBiggestNiceTown(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistance());
town_list.KeepAboveValue(GetMinDistance());
town_list.Valuate(AITown.GetPopulation);
town_list.KeepTop(1);
if(town_list.Count()==0) return null;
return town_list.Begin();
}

function RoadBuilder::GetNiceRandomTown(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistance());
town_list.KeepAboveValue(GetMinDistance());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0) return null;
return town_list.Begin();
}

function RoadBuilder::BusStationAllocator(project)
{
local start = project.start;
local town = project.end;
local cargo = project.cargo;

local maybe_start_station = this.FindBusStation(start, null, cargo);
local maybe_second_station = this.FindBusStation(town, AITown.GetLocation(start), cargo);

project.first_station = maybe_start_station;
project.second_station = maybe_second_station;

project.second_station.location = project.second_station.location;

maybe_start_station = project.first_station.location;
//maybe_second_station = project.second_station.location;

if((project.first_station.location==null)||(project.second_station.location==null))
  {
  if((maybe_start_station==null)&&(project.second_station.location==null))
    {
	Info("   Station placing near "+AITown.GetName(start)+" and "+AITown.GetName(town)+" is impossible.");
    project.forbidden.AddItem(project.start, 0);
    project.forbidden.AddItem(project.end, 0);
	}
  if((maybe_start_station==null)&&(project.second_station.location!=null))
    {
    Info("   Station placing near "+AITown.GetName(start)+" is impossible.");
    project.forbidden.AddItem(project.start, 0);
 	}
  if((maybe_start_station!=null)&&(project.second_station.location==null)) 
    {
	Info("   Station placing near "+AITown.GetName(town)+" is impossible.");
    project.forbidden.AddItem(project.end, 0);
 	}
  return project;
  }
Info("   Stations planned.");

project.start_otoczka = array(2);
project.koniec_otoczka = array(2);

if(project.first_station.direction == StationDirection.x_is_constant__horizontal)
	{
	project.start_otoczka[0]=project.first_station.location+AIMap.GetTileIndex(0, 1);
	project.start_otoczka[1]=project.first_station.location+AIMap.GetTileIndex(0, -1);
	}
else
	{
	project.start_otoczka[0]=project.first_station.location+AIMap.GetTileIndex(1, 0);
	project.start_otoczka[1]=project.first_station.location+AIMap.GetTileIndex(-1, 0);
	}
	
if(project.second_station.direction == StationDirection.x_is_constant__horizontal)
	{
	project.koniec_otoczka[0]=project.second_station.location+AIMap.GetTileIndex(0, 1);
	project.koniec_otoczka[1]=project.second_station.location+AIMap.GetTileIndex(0, -1);
	}
else
	{
	project.koniec_otoczka[0]=project.second_station.location+AIMap.GetTileIndex(1, 0);
	project.koniec_otoczka[1]=project.second_station.location+AIMap.GetTileIndex(-1, 0);
	}

return project;
}

function RoadBuilder::IndustryToIndustryTruckStationAllocator(project)
{
local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;
local maybe_start_station = this.FindStationProducenta(producer, cargo);
local maybe_second_station = this.FindStationKonsumenta(consumer, cargo);

project.first_station = maybe_start_station;
project.second_station = maybe_second_station;

project.second_station.location = project.second_station.location;

return RoadBuilder.UniversalStationAllocator(project);
}

function RoadBuilder::IndustryToCityTruckStationAllocator(project)
{
local start = project.start;
local town = project.end;
local cargo = project.cargo;

local maybe_start_station = this.FindStationProducenta(start, cargo);
local maybe_second_station = this.FindStationMiejska(town, cargo);

project.first_station = maybe_start_station;
project.second_station = maybe_second_station;

project.second_station.location = project.second_station.location;

return RoadBuilder.UniversalStationAllocator(project);
}

function RoadBuilder::UniversalStationAllocator(project)
{
if((project.first_station.location==null)||(project.second_station.location==null))
  {
  if((project.first_station.location==null)&&(project.second_station.location==null))
    {
    project.forbidden.AddItem(project.start, 0);
	}
  if((project.first_station.location==null)&&(project.second_station.location!=null))
    {
    project.forbidden.AddItem(project.start, 0);
 	}
  if((project.first_station.location!=null)&&(project.second_station.location==null)) 
    {
 	}
  return project;
  }
Info("   Stations planned.");

project.start_otoczka = array(2);
project.koniec_otoczka = array(2);

if(project.first_station.direction == StationDirection.x_is_constant__horizontal)
	{
	project.start_otoczka[0]=project.first_station.location+AIMap.GetTileIndex(0, 1);
	project.start_otoczka[1]=project.first_station.location+AIMap.GetTileIndex(0, -1);
	}
else
	{
	project.start_otoczka[0]=project.first_station.location+AIMap.GetTileIndex(1, 0);
	project.start_otoczka[1]=project.first_station.location+AIMap.GetTileIndex(-1, 0);
	}
	
if(project.second_station.direction == StationDirection.x_is_constant__horizontal)
	{
	project.koniec_otoczka[0]=project.second_station.location+AIMap.GetTileIndex(0, 1);
	project.koniec_otoczka[1]=project.second_station.location+AIMap.GetTileIndex(0, -1);
	}
else
	{
	project.koniec_otoczka[0]=project.second_station.location+AIMap.GetTileIndex(1, 0);
	project.koniec_otoczka[1]=project.second_station.location+AIMap.GetTileIndex(-1, 0);
	}

return project;
}

function RoadBuilder::PrepareRoute()
{
//if(rodzic.GetSetting("debug_signs_for_planned_route")){ (setting removed)
//   AISign.BuildSign(trasa.start_tile, "trasa.start_tile");
//    AISign.BuildSign(trasa.end_tile, "trasa.end_tile");
//	}
Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));

local forbidden_tiles=array(2);
forbidden_tiles[0]=trasa.second_station.location;
forbidden_tiles[1]=trasa.first_station.location;

local pathfinder = CustomPathfinder();
pathfinder.Fast();
pathfinder.InitializePath(trasa.koniec_otoczka, trasa.start_otoczka, forbidden_tiles);
path = false;
local guardian=0;
local limit = this.GetPathfindingLimit();
while (path == false) {
  Info("   Pathfinding ("+guardian+" / " + limit + ") started");
  path = pathfinder.FindPath(2000);
  Info("   Pathfinding ("+guardian+" / " + limit + ") ended");
  rodzic.Maintenance();
  AIController.Sleep(1);
  guardian++;
  if(guardian>limit )break;
}

if(path == false || path == null){
  Info("   Pathfinder failed to find route. ");
  return false;
  }
  
Info("   Road pathfinder found sth.");
local estimated_cost = this.sprawdz_droge(path);
if(estimated_cost==null){
  Info("   Pathfinder failed to find correct route.");
  return false;
  }

estimated_cost += AIEngine.GetPrice(trasa.engine)*5;
cost=estimated_cost;

if(GetAvailableMoney()<estimated_cost) 
    {
    Info("too expensivee, we have only " + GetAvailableMoney() + " And we need " + estimated_cost);
	return false;
	}
ProvideMoney();
return true;   
}

function RoadBuilder::ConstructionOfRVRoute()
{
if(!this.BuildRoad(path)){
   AIRoad.RemoveRoadStation(trasa.first_station.location);
   AIRoad.RemoveRoadStation(trasa.second_station.location);
   Info("   But stopped by error");
   return false;	  
   }

trasa.depot_tile = this.BuildRoadDepotOnRoute(path);
if(trasa.depot_tile==null){
   Info("   Depot placement error");
   return false;	  
   }

rodzic.SetStationName(trasa.first_station.location, "["+trasa.depot_tile+"]");
rodzic.SetStationName(trasa.second_station.location, "["+trasa.depot_tile+"]");

Info("   Route constructed!");

Info("   working on circle around loading bay");
this.CircleAroundStation(trasa.start_otoczka[0], trasa.start_otoczka[1], trasa.first_station.location);
AIRoad.BuildRoadDepot (trasa.start_otoczka[0], trasa.first_station.location);
AIRoad.BuildRoadDepot (trasa.start_otoczka[1], trasa.first_station.location);

local how_many_new_vehicles = this.BuildVehicles();

if(how_many_new_vehicles==null)
   {
   Error("Vehicles construction failed");
   AIRoad.RemoveRoadStation(trasa.first_station.location);
   AIRoad.RemoveRoadStation(trasa.second_station.location);
   cost = 0;
   return false;
   }

Info("   Vehicles construction, " + how_many_new_vehicles + " vehicles constructed.");

Info("   working on circle around unloading bay");
this.CircleAroundStation(trasa.koniec_otoczka[0], trasa.koniec_otoczka[1], trasa.second_station.location);
AIRoad.BuildRoadDepot (trasa.koniec_otoczka[0], trasa.second_station.location);
AIRoad.BuildRoadDepot (trasa.koniec_otoczka[1], trasa.second_station.location);

return true;
}

function RoadBuilder::BuildRoadDepotOnRoute(path)
{
local ile = 0;
local odstep = 70;
local licznik = odstep-2;
local returnik = null;
while (path != null) 
  {
  if(returnik!=null) return returnik; //ubija wielokrotnoœæ
  local par = path.GetParent();
  if (par != null) 
     {
     local last_node = path.GetTile();
	 local distance = AIMap.DistanceManhattan(path.GetTile(), par.GetTile());
	 licznik+=distance;
     if (distance == 1 ) 
		{
		if(licznik>odstep)
		if(AITile.IsBuildable(path.GetTile()+AIMap.GetTileIndex(0, 1))) 
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()+AIMap.GetTileIndex(0, 1)))
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()))
		  {
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(0, 1), path.GetTile()))
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(0, 1), path.GetTile()))
 	      {
		  licznik=0;
		  if(returnik==null)
 		  returnik = path.GetTile()+AIMap.GetTileIndex(0, 1);
		  }
		  }
		if(licznik>odstep)
		if(AITile.IsBuildable(path.GetTile()+AIMap.GetTileIndex(0, -1))) 
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()+AIMap.GetTileIndex(0, -1)))
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()))
		  {
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(0, -1), path.GetTile()))
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(0, -1), path.GetTile())) 
 	      {
		  licznik=0;
		  if(returnik==null)
		  returnik = path.GetTile()+AIMap.GetTileIndex(0, -1);
		  }
		  }
		if(licznik>odstep)
		if(AITile.IsBuildable(path.GetTile()+AIMap.GetTileIndex(1, 0))) 
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()+AIMap.GetTileIndex(1, 0)))
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()))
		  {
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(1, 0), path.GetTile()))
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(1, 0), path.GetTile())) 
 	      {
		  licznik=0;
		  if(returnik==null)
		  returnik = path.GetTile()+AIMap.GetTileIndex(1, 0);
		  }
		  }
		if(licznik>odstep)
		if(AITile.IsBuildable(path.GetTile()+AIMap.GetTileIndex(-1, 0))) 
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()+AIMap.GetTileIndex(-1, 0)))
		if(AITile.SLOPE_FLAT == AITile.GetSlope(path.GetTile()))
		  {		
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(-1, 0), path.GetTile()))
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(-1, 0), path.GetTile())) 
 	      {
		  licznik=0;
		  if(returnik==null)
		  returnik = path.GetTile()+AIMap.GetTileIndex(-1, 0);
		  }
		  }
	  }
     else //skip! 
        {
	    path = par;
		if(path != null) par = path.GetParent();
		}
     }
  path = par;
  }
return returnik;
}

function RoadBuilder::GetReplace(existing_vehicle, cargo)
{
return this.WybierzRV(cargo);
}

function WybierzRVForFindPair(route)
{
route.engine = WybierzRV(route.cargo);
if(route.engine == null) return route;
route.engine_count = HowManyVehiclesForNewStation(route);
return route;
}

function RoadBuilder::WybierzRV(cargo) //from admiral AI
{
local new_engine_id = null;
local list = AIEngineList(AIVehicle.VT_ROAD);
list.Valuate(AIEngine.GetRoadType);
list.KeepValue(AIRoad.ROADTYPE_ROAD);
list.Valuate(AIEngine.CanRefitCargo, cargo);
list.KeepValue(1);
list.Valuate(AIEngine.GetMaxSpeed);
list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

list.KeepAboveValue(AIEngine.GetMaxSpeed(list.Begin())*85/100);

list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);

if (list.Count() != 0) 
   {
   new_engine_id = list.Begin();
   }
return new_engine_id;
}

function RoadBuilder::IsOKPlaceForRVStation(station_tile, direction)
{
local t_ts = array(2);

if(direction == StationDirection.x_is_constant__horizontal)
   {
	t_ts[0]=station_tile+AIMap.GetTileIndex(0, 1);
	t_ts[1]=station_tile+AIMap.GetTileIndex(0, -1);
	}
else
   {
	t_ts[0]=station_tile+AIMap.GetTileIndex(1, 0);
	t_ts[1]=station_tile+AIMap.GetTileIndex(-1, 0);
   }

local test = AITestMode();
/* Test Mode */

if(!AIRoad.BuildDriveThroughRoadStation(station_tile, t_ts[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   if(AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) return false;
   }
if(!AIRoad.BuildRoad(t_ts[1], station_tile))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
	  //Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      return false;
	  }
   }
if(!AIRoad.BuildRoad(station_tile, t_ts[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  //Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      return false;
	  }
   }
return true;
}

function RoadBuilder::IsWrongPlaceForRVStation(station_tile, direction)
{
	if(IsTileWithAuthorityRefuse(station_tile)) {
		rodzic.HandleFailedStationConstruction(station_tile, AIError.ERR_LOCAL_AUTHORITY_REFUSES);
		if(IsTileWithAuthorityRefuse(station_tile))
			{
			return false;
			}
		}
	if(IsTileFlatAndBuildable(station_tile)) return true;
	if(direction == StationDirection.x_is_constant__horizontal) {
		if(IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(0, 1))) return true;
		if(IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(0, -1))) return true;
	}
	else {
		if(IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(1, 0))) return true;
		if(IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(-1, 0))) return true;
	}
	return false;
}

function RoadBuilder::FindStation(list)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
   {
   if(!IsWrongPlaceForRVStation(station, StationDirection.x_is_constant__horizontal))
      {
	  local returnik = Station();
	  returnik.location = station;
	  returnik.direction = StationDirection.x_is_constant__horizontal;
	  return returnik;
	  }
   else if(!IsWrongPlaceForRVStation(station, StationDirection.y_is_constant__vertical))
      {
	  local returnik = Station();
	  returnik.location = station;
	  returnik.direction = StationDirection.y_is_constant__vertical;
	  return returnik;
	  }
   else
	  {
	  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(station, "X");
	  }
   }

   //Info("II phase");
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(IsOKPlaceForRVStation(station, StationDirection.x_is_constant__horizontal))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.x_is_constant__horizontal;
		return returnik;
		}
	if(IsOKPlaceForRVStation(station, StationDirection.y_is_constant__vertical))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	}
local returnik = Station();
returnik.location = null;
return returnik;
}

function RoadBuilder::FindStationMiejska(town, cargo)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
return this.FindStation(list);
}

function RoadBuilder::FindStationKonsumenta(consumer, cargo)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
return this.FindStation(list);
}

function RoadBuilder::FindStationProducenta(producer, cargo)
{
local list=AITileList_IndustryProducing(producer, 3);
return this.FindStation(list);
}

function RoadBuilder::FindBusStation(town, start, cargo)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(max(25, 50-desperation));

if(start != null)
   {
   list.Valuate(AIMap.DistanceManhattan, start);
   list.RemoveBelowValue(20);
   }

list.Valuate(rodzic.IsConnectedDistrict);
list.KeepValue(0);

list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
return (this.FindStation(list));
}

function RoadBuilder::HowManyVehiclesForNewStation(traska)
{
local speed = AIEngine.GetMaxSpeed(traska.engine);
local distance = AIMap.DistanceManhattan(traska.first_station.location, traska.second_station.location);
local ile = trasa.production/AIEngine.GetCapacity(traska.engine);
local mnoznik = ((distance*88)/(50*speed));
if(mnoznik==0)mnoznik=1;
ile*=mnoznik;
ile+=3;
return ile;
}

function RoadBuilder::sellVehicleStoppedInDepotDueToFoo(vehicle_id, foo)
	{
	Error("RV (" + AIVehicle.GetName(vehicle_id) + ") "+ foo + " failed due to " + AIError.GetLastErrorString()+".");
	if(AIVehicle.SellVehicle(vehicle_id)) 
		Info("Vehicle sold");
	else 
		Error("RV selling failed due to " + AIError.GetLastErrorString()+".");
	return null;
	}

function RoadBuilder::BuildVehicles()
	{
	//trasa.type
	//0 proceed trasa.cargo
	//1 raw
	//2 passenger
	local constructed=0;
	if(trasa.engine==null) return null;
	local ile = trasa.engine_count;	
	local vehicle_id = -1;
	vehicle_id=AIAI.BuildVehicle (trasa.depot_tile, trasa.engine);
	if(!AIVehicle.IsValidVehicle(vehicle_id)) return null;
	{
	constructed++;

	if(trasa.type==1) //1 raw
		{
		if(!(AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE )&&
		AIOrder.AppendOrder (vehicle_id, trasa.second_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD ))){
			this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "order appending");
			return null;
			}
		}
	else if(trasa.type==0) //0 proceed trasa.cargo
		{
		local pozycja_porownywacza=1;
		local pozycja_przeskakiwacza=3;

		if(!(AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE )&&
		AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.OF_NON_STOP_INTERMEDIATE )&&
		AIOrder.AppendOrder (vehicle_id, trasa.second_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD )&&
		AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.OF_NON_STOP_INTERMEDIATE )&&
	
		AIOrder.InsertConditionalOrder (vehicle_id, pozycja_porownywacza, 2)&&
		AIOrder.SetOrderCompareValue(vehicle_id, pozycja_porownywacza, 0)&&
		AIOrder.SetOrderCondition (vehicle_id, pozycja_porownywacza, AIOrder.OC_LOAD_PERCENTAGE)&&
		AIOrder.SetOrderCompareFunction(vehicle_id, pozycja_porownywacza, AIOrder.CF_MORE_THAN)&&
	
		AIOrder.InsertConditionalOrder (vehicle_id, pozycja_przeskakiwacza, 0)&&
		AIOrder.SetOrderCompareValue(vehicle_id, pozycja_przeskakiwacza, 0)&&
		AIOrder.SetOrderCondition (vehicle_id, pozycja_przeskakiwacza, AIOrder.OC_UNCONDITIONALLY))){
			this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "order appending");
			return null;
			}
		}
	else if(trasa.type == 2) //2 passenger
		{
		if(!(AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE )&&
		AIOrder.AppendOrder (vehicle_id, trasa.second_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE ))){
			this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "order appending");
			return null;
			}
		}
	else{
		abort("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
		}
	if(!AIVehicle.RefitVehicle (vehicle_id, trasa.cargo)){
		this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "refitting");
		return null;
		}

	if(!AIVehicle.StartStopVehicle (vehicle_id)){
		this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "starting");
		return null;
		}

	local string;
	if(trasa.type==1) string = "Raw cargo";
	else if(trasa.type==0) string = "Processed cargo"; 
	else if(trasa.type==2) string = "Bus line";
	else string = "WTF?"; 

	SetNameOfVehicle(vehicle_id, string);
	}

for(local i = 0; i<ile; i++) if(this.copyVehicle(vehicle_id, trasa.cargo)) constructed++;

return constructed;
}

function RoadBuilder::RawVehicle(vehicle_id)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) return null;
return AIVehicle.GetName(vehicle_id)[0]=='R';
}

function RoadBuilder::ProcessedCargoVehicle(vehicle_id)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) return null;
return AIVehicle.GetName(vehicle_id)[0]=='P';
}

function RoadBuilder::PassengerCargoVehicle(vehicle_id)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) return null;
return AIVehicle.GetName(vehicle_id)[0]=='B';
}

function RoadBuilder::sprawdz_droge(path)
{
local costs = AIAccounting();
costs.ResetCosts ();

 /* Exec Mode */
{
local test = AITestMode();
/* Test Mode */

if(RoadBuilder.BuildRoad(path))
   {
   return costs.GetCosts();
   }
else return null;

if(path==null) return false;
while (path != null) {
  local par = path.GetParent();
  if (par != null) {
    local last_node = path.GetTile();
	if(!this.BuildRoadSegment(path.GetTile(),  par.GetTile(), 0))
	    {
		Error(AIError.GetLastErrorString());
		return null;
		}
  }
  path = par;
}

}
/* Exec Mode */
//print("Costs for route is: " + costs.GetCosts());
return costs.GetCosts();
}

function RoadBuilder::BuildRoad(path)
{
if(path==null) return false;
while (path != null) {
  local par = path.GetParent();
  if (par != null) {
    local last_node = path.GetTile();
	if(!this.BuildRoadSegment(path.GetTile(),  par.GetTile(), 0))
	    {
		return false;
		}
  }
  path = par;
}
return true;
}

function RoadBuilder::CircleAroundStation(tile_s, tile_e, tile_i)
{
local pathfinder = CustomPathfinder();
pathfinder.CircleAroundStation();
local t1=array(1);
local t2=array(1);
local i=array(1);
t1[0]=tile_s;
t2[0]=tile_e;
i[0]=tile_i;
pathfinder.InitializePath(t1, t2, i);

local path = false;
while (path == false) 
  {
  path = pathfinder.FindPath(1000);

  if(path==null) return false;

  rodzic.Maintenance();

  AIController.Sleep(1);
  }

return this.BuildRoad(path);
}

function RoadBuilder::AddTruck()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
   {
   local station_list=AIStationList(AIStation.STATION_TRUCK_STOP);
   for (local station_id = station_list.Begin(); station_list.HasNext(); station_id = station_list.Next()) //from Chopper
	  {
	  if(AgeOfTheYoungestVehicle(station_id)>20) //nie dodawaæ masowo
	  if(IsItNeededToImproveThatStation(station_id, cargo))
	  {
	     local vehicle_list=AIVehicleList_Station(station_id);
		 
		 vehicle_list.Valuate(AIBase.RandItem);
		 vehicle_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		 local original=vehicle_list.Begin();
		 
		 if(AIVehicle.GetProfitLastYear(original)<0)continue;
		if(HowManyVehiclesFromThisStationAreStopped(station_id) != 0)continue;
		 local end = AIOrder.GetOrderDestination(original, AIOrder.GetOrderCount(original)-2);

	     if(AITile.GetCargoAcceptance (end, cargo, 1, 1, 4)==0)
		    {
			if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(end, "ACCEPTATION STOPPED");
			continue;
			}
		local raw = this.RawVehicle(original);
		 if(raw && raw != null) 
		    {
			if(this.copyVehicle(original, cargo )) ile++;
			}
		 else 
		    {
			if(IsItNeededToImproveThatNoRawStation(station_id, cargo)) 
			   {
			   if(this.copyVehicle(original, cargo)) ile++;
			   }
			}
		}
	  }
   }
return ile;
}

function RoadBuilder::AddBus()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
   {
   local station_list=AIStationList(AIStation.STATION_BUS_STOP);
   for (local station_id = station_list.Begin(); station_list.HasNext(); station_id = station_list.Next()) //from Chopper
	  {
	  if(AgeOfTheYoungestVehicle(station_id)>20) //nie dodawaæ masowo
	  if(IsItNeededToImproveThatNoRawStation(station_id, cargo))
	  {
	     local vehicle_list=AIVehicleList_Station(station_id);
		 
		 vehicle_list.Valuate(AIBase.RandItem);
		 vehicle_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		 local original=vehicle_list.Begin();
		 
		 if(AIVehicle.GetProfitLastYear(original)<0)continue;

/*
TODO DUAL END
		 local end = AIOrder.GetOrderDestination(original, AIOrder.GetOrderCount(original)-2);

	     if(AITile.GetCargoAcceptance (end, cargo, 1, 1, 4)==0)
		    {
			if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(end, "ACCEPTATION STOPPED");
			continue;
			}
*/
		local another_station = AIStation.GetStationID(GetUnloadStationLocation(original));
		if(station_id == another_station ) another_station = AIStation.GetStationID(GetLoadStationLocation(original));
		if(IsItNeededToImproveThatStation(another_station, cargo))
		   {
		   if(this.copyVehicle(original, cargo )) ile++;
		   }
		else
		   {
		   if(!RoadBuilder.DynamicFullLoadManagement(station_id, another_station, original))
		      {
			  if(this.copyVehicle(original, cargo )) ile++;
			  }
		   }
		}
	  }
   }
return ile;
}

function RoadBuilder::DynamicFullLoadManagement(full_station, empty_station, RV)
{
local first_station_is_full = (AIStation.GetStationID(GetLoadStationLocation(RV)) == full_station);

if(first_station_is_full)
   {
   if(AIOrder.GetOrderFlags(RV, 0)!= (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE))
      {
	  if(AIBase.RandRange(3)!=0) return true; //To wait for effects of action and avoid RV flood

	  Info(AIVehicle.GetName(RV) + "wykonano zmiane typu 1");
	  AIOrder.SetOrderFlags(RV, 0, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE);
	  return true;
	  }
   else
      {
      if(AIOrder.GetOrderFlags(RV, 1)== (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE))
      {
	  if(AIBase.RandRange(3)!=0) return true; //To wait for effects of action and avoid RV flood

	  Info(AIVehicle.GetName(RV) + "wykonano zmiane typu 2");
	  AIOrder.SetOrderFlags(RV, 1, AIOrder.OF_NON_STOP_INTERMEDIATE);
	  return true;
	  }
	  }
   }
else
   {
   if(AIOrder.GetOrderFlags(RV, 1)!= (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE))
      {
	  if(AIBase.RandRange(3)!=0) return true; //To wait for effects of action and avoid RV flood

	  Info(AIVehicle.GetName(RV) + "wykonano zmiane typu 3");
	  AIOrder.SetOrderFlags(RV, 1, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE);
	  return true;
	  }
   else
      {
      if(AIOrder.GetOrderFlags(RV, 0)== (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE))
      {
	  if(AIBase.RandRange(3)!=0) return true; //To wait for effects of action and avoid RV flood

	  Info(AIVehicle.GetName(RV) + "wykonano zmiane typu 4");
	  AIOrder.SetOrderFlags(RV, 0, AIOrder.OF_NON_STOP_INTERMEDIATE);
	  return true;
	  }
	  }
   }
return false;   
/*
static boolean AIOrder::SetOrderFlags  	(  	VehicleID   	 vehicle_id,
		OrderPosition  	order_position,
		AIOrderFlags  	order_flags	 
	)
	
static AIOrderFlags AIOrder::GetOrderFlags  	(  	VehicleID   	 vehicle_id,
		OrderPosition  	order_position	 
	) 	
*/
}

function RoadBuilder::copyVehicle(main_vehicle_id, cargo)
{
if(AIVehicle.IsValidVehicle(main_vehicle_id)==false) return false;
local depot_tile = GetDepotLocation(main_vehicle_id);

local speed = AIEngine.GetMaxSpeed(this.WybierzRV(cargo));
local distance = AIMap.DistanceManhattan(GetLoadStationLocation(main_vehicle_id), GetUnloadStationLocation(main_vehicle_id));

//OPTION TODO
//1 na tile przy 25 km/h
//mo¿na obs³u¿yæ 22 miesiêcznie
//30 dni
//52 tiles
//48 km/h
// w dwie strony
//maksymalnie = 22*(distance/51)/(speed/48)*2
local maksymalnie = 22*distance*48/51/speed*2;
//local maksymalnie=distance*50/(speed+10); - old

local load_station_tile = GetLoadStationLocation(main_vehicle_id);
local load_station_id = AIStation.GetStationID(load_station_tile);
local list = AIVehicleList_Station(load_station_id);   	
local ile = list.Count();

if(rodzic.GetSetting("other_debug_signs")){
	Helper.SetSign(load_station_tile+AIMap.GetTileIndex(-1, 0), "Ile: "+ile+" na " + maksymalnie);
	Helper.SetSign(load_station_tile+AIMap.GetTileIndex(-2, 0), "distance " + distance);
	}

	if(ile>maksymalnie){
		if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(load_station_tile, "maxed!");
		Warning("Too many vehicles on this route!");
		return false;
	}

	local vehicle_id = AIVehicle.CloneVehicle(depot_tile, main_vehicle_id, true);
	if(!AIVehicle.StartStopVehicle (vehicle_id)){
		sellVehicleStoppedInDepotDueToFoo(vehicle_id, "starting");
		return false;
	}

	local string;
	local raw = this.RawVehicle(main_vehicle_id);
	local processed = this.ProcessedCargoVehicle(main_vehicle_id);
	local passengers = this.PassengerCargoVehicle(main_vehicle_id);

	if(raw && raw != null) string = "Raw cargo "; 
	else if(processed && processed != null) string = "Processed cargo"; 
	else if(passengers && passengers != null) string = "Bus line";
	else {
		return false; //TODO - cancel sell order
	}
	SetNameOfVehicle(vehicle_id, string);
    return true;
}

function RoadBuilder::RemoveRedundantRV()
{
local station_list = AIStationList(AIStation.STATION_TRUCK_STOP);
local ile = RoadBuilder.RemoveRedundantRVFromStation(station_list);
local station_list = AIStationList(AIStation.STATION_BUS_STOP);
ile+=RoadBuilder.RemoveRedundantRVFromStation(station_list);
return ile;
}

function RoadBuilder::RemoveRedundantRVFromStation(station_list)
{
local full_delete_count=0;
local cargo_list = AICargoList();

for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next()) //from Chopper 
	{
	local waiting_counter=0;
	local active_counter=0;
	local cargo;
	if(AgeOfTheYoungestVehicle(station)<150)continue;
	local vehicle_list = AIVehicleList_Station(station);
	if(vehicle_list.Count()==0)continue;
	
	for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper 
		{
		if(AIVehicle.GetCapacity (vehicle_list.Begin(), cargo)>0)
			{
			break;
			}
		}
	
	local front_vehicle = vehicle_list.Begin();
	local station_id = AIStation.GetStationID(GetLoadStationLocation(front_vehicle)); 
	if(station==station_id)
		{
		//Info("Station with " + AIStation.GetCargoWaiting(station, cargo) + " of " + AICargo.GetCargoLabel(cargo));
		if(!IsItNeededToImproveThatStation(station, cargo))
			{
			for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next()) //from Chopper 
				{
				if(rodzic.ForSell(vehicle) || AIVehicle.GetAge(vehicle)<60)
					{
					waiting_counter=0;
					break;
					}
				if(AIVehicle.GetCargoLoad (vehicle, cargo)==0 && AIStation.GetDistanceManhattanToTile(station, AIVehicle.GetLocation(vehicle))<=4) //OPTION
					{
					//Info(AIVehicle.GetName(vehicle)+" ***"+AIStation.GetDistanceManhattanToTile (station, AIVehicle.GetLocation(vehicle))+"*** <"+counter);
					if(AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION)
					waiting_counter++;
					if(AIVehicle.GetCurrentSpeed(vehicle)==0)waiting_counter++; //TODO - max speed <20!
					else waiting_counter--;
					}
				else
					{
					active_counter++;
					}
				}		
			local delete_goal;
			local delete_count=0;

			local delete1=waiting_counter-5; //OPTION
			local delete2 =waiting_counter-active_counter;
			if(active_counter == 0)
				local delete2=1;
			if(delete2>delete1)delete_goal=delete2;
			else delete_goal=delete1;
			vehicle_list.Valuate(rodzic.ForSell);
			vehicle_list.KeepValue(0);
			vehicle_list.Valuate(AIVehicle.GetAge);
			vehicle_list.KeepAboveValue(60);
			vehicle_list.Valuate(AIVehicle.GetCargoLoad, cargo)
			vehicle_list.KeepValue(0);
			for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next()) //from Chopper 
				{
				if(delete_goal-delete_count<0)
					{
					//Info("DELETION END")
					break;
					}
				Info(delete_count+" of "+delete_goal+" deleted.")
				local result = null;
				if(rodzic.sellVehicle(vehicle, "kolejkowicze"))
					{
					result = vehicle;
					delete_count++;
					}
				}
			full_delete_count+=delete_count;
			}
		}
	}
return full_delete_count;
}

function RoadBuilder::BuildRoadSegment(path, par, depth)
{
if(depth>=6)
    {
	Info("Construction terminated! "+AIError.GetLastErrorString()); 
	if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
 	return false;
    }
local result;
if (AIMap.DistanceManhattan(path, par) == 1 ) 
   {
   result = AIRoad.BuildRoad(path, par);
   }
else 
   {
   /* Build a bridge or tunnel. */
   if (!AIBridge.IsBridgeTile(path) && !AITunnel.IsTunnelTile(path)) 
      {
      /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
      if (AIRoad.IsRoadTile(path)) AITile.DemolishTile(path);
      
	  if (AITunnel.GetOtherTunnelEnd(path) == par) 
	     {
		 result = AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path);
		 } 
      else 
	     {
         result = rodzic.BuildBridge(AIVehicle.VT_ROAD, path, par);
        }
      }
    }
	
if(!result)
   {
   local error=AIError.GetLastError();
   if(error==AIError.ERR_ALREADY_BUILT) return true;
   if(error==AIError.ERR_VEHICLE_IN_THE_WAY)
   {
   AIController.Sleep(20);
   return this.BuildRoadSegment(path, par, depth+1);
   }
   Info("Construction terminated! "+AIError.GetLastErrorString()); 
   if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
   return false;
   }
return true;
}


