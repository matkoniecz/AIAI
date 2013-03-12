import("pathfinder.road", "RoadPathFinder", 3);

class KRAI
{
desperacja=0;
rodzic=null;
_koszt=0;
detected_rail_crossings = null;
path = null;

trasa = null;
}

require("KRAIutil.nut");
require("KRAI_level_crossing_menagement_from_clueless_plus.nut");
require("KRAIpathfinder.nut");

function KRAI::IsConnectedIndustry(i, cargo)
{
if(AIStationList(AIStation.STATION_ANY).IsEmpty())return false;

local tile_list=AITileList_IndustryProducing(i, 3);
for (local q = tile_list.Begin(); tile_list.HasNext(); q = tile_list.Next()) //from Chopper 
   {
   local station_id = AIStation.GetStationID(q);
   if(AIStation.IsValidStation(station_id))
      {
	  local vehicle_list=AIVehicleList_Station(station_id);
	  if(vehicle_list.Count()!=0)
	  if(AIStation.GetStationID(GetLoadStation(vehicle_list.Begin()))==station_id) //czy full load jest na wykrytej stacji
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

function KRAI::Konserwuj()
{
local new = this.Uzupelnij() + this.UzupelnijBus();
local redundant = this.UsunNadmiarowePojazdy();
if((new+redundant)>0) this.Info("KRAI: Vehicles: " + new + " new, " +  redundant + " redundant send to depot.");
this.HandleOldLevelCrossings();
}

function KRAI::GetMinDistance()
{
return 10;
}

function KRAI::GetMaxDistance()
{
if(desperacja>5) return desperacja*75;
return 150+desperacja*50;
}

function KRAI::distanceBetweenIndustriesValuator(distance)
{
if(distance>GetMaxDistance())return 0;
if(distance<GetMinDistance()) return 0;

if(desperacja>5)
   {
   if(distance>desperacja*60)return 1;
   return 4;
   }

if(distance>100+desperacja*50)return 1;
if(distance>85) return 2;
if(distance>70) return 3;
if(distance>55) return 4;
if(distance>40) return 3;
if(distance>25) return 2;
if(distance>10) return 1;
return 0;
}

function KRAI::ZbudujStacjeCiezarowek()
{
if(!AIRoad.BuildDriveThroughRoadStation(trasa.first_station.location, trasa.start_otoczka[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   this.Info("   Producer station placement impossible due to " + AIError.GetLastErrorString());
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString());
   return false;
   }
if(!AIRoad.BuildDriveThroughRoadStation(trasa.second_station.location, trasa.koniec_otoczka[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   this.Info("   Consumer station placement impossible due to " + AIError.GetLastErrorString());
   AIRoad.RemoveRoadStation(trasa.first_station.location);
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.end_station, AIError.GetLastErrorString());
   return false;
   }
return RoadToStation();
}

function KRAI::ZbudujStacjeAutobusow()
{
if(!AIRoad.BuildDriveThroughRoadStation(trasa.first_station.location, trasa.start_otoczka[0], AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) 
   {
   this.Info("   Producer station placement impossible due to " + AIError.GetLastErrorString());
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString());
   return false;
   }
if(!AIRoad.BuildDriveThroughRoadStation(trasa.end_station, trasa.koniec_otoczka[0], AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) 
   {
   this.Info("   Consumer station placement impossible due to " + AIError.GetLastErrorString());
   AIRoad.RemoveRoadStation(trasa.first_station.location);
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.end_station, AIError.GetLastErrorString());
   return false;
   }
return RoadToStation();
}

function KRAI::RoadToStation()
{
if(!AIRoad.BuildRoad(trasa.start_otoczka[1], trasa.first_station.location))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
	  this.Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.first_station.location, trasa.start_otoczka[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.koniec_otoczka[1], trasa.end_station))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.end_station, trasa.koniec_otoczka[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.first_station.location);
      AIRoad.RemoveRoadStation(trasa.end_station);
      return false;
	  }
   }
return true;
}

function KRAI::ValuateProducer(ID, cargo)
{
   local base = AIIndustry.GetLastMonthProduction(ID, cargo);
   base*=(100-AIIndustry.GetLastMonthTransportedPercentage (ID, cargo));
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

function KRAI::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
//Info("   " + AIIndustry.GetName(ID) + " is " + score + " point consumer of " + AICargo.GetCargoLabel(cargo));
return score;
}

function KRAI::GetRatherBigRandomTownValuator(town_id)
{
return AITown.GetPopulation(town_id)*AIBase.RandRange(5);
}

function KRAI::GetRatherBigRandomTown()
{
local town_list = AITownList();
town_list.Valuate(this.GetRatherBigRandomTownValuator);
town_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return town_list.Begin();
}

function KRAI::GetBiggestNiceTown(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistance());
town_list.KeepAboveValue(GetMinDistance());
town_list.Valuate(AITown.GetPopulation);
town_list.KeepTop(1);
if(town_list.Count()==0)return null;
return town_list.Begin();
}

function KRAI::FindBusPair()
{
trasa.start = GetRatherBigRandomTown();
trasa.end = GetNiceRandomTown(AITown.GetLocation(trasa.start))
trasa.cargo = rodzic.GetPassengerCargoId();
trasa.engine = this.WybierzRV(trasa.cargo);
if(trasa.engine == null) return false;

if(trasa.end == null) return false;
Info("From " + AITown.GetName(trasa.start) + "  to " +  AITown.GetName(trasa.end) );
trasa.cargo = rodzic.GetPassengerCargoId();

trasa = BusStationAllocator(trasa);

if(!((trasa.first_station.location==null)||(trasa.second_station.location==null)))
	{
	trasa.start_tile = AITown.GetLocation(trasa.start);
	trasa.end_tile = AITown.GetLocation(trasa.end);
	trasa.production = min(AITile.GetCargoAcceptance(trasa.first_station.location, trasa.cargo, 1, 1, 3), AITile.GetCargoAcceptance(trasa.end_station, trasa.cargo, 1, 1, 3));
	trasa.type = 2;
	return true;
	}
return false;
}

function KRAI::GetNiceRandomTown(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistance());
town_list.KeepAboveValue(GetMinDistance());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0)return null;
return town_list.Begin();
}

function KRAI::FindPair(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this);
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, IndustryToIndustryTruckStationAllocator, GetNiceRandomTown, IndustryToCityTruckStationAllocator, WybierzRVForFindPair);
}

function KRAI::BusStationAllocator(project)
{
local start = project.start;
local town = project.end;
local cargo = project.cargo;

local maybe_start_station = this.ZnajdzBusStacje(start, null, cargo);
local maybe_end_station = this.ZnajdzBusStacje(town, AITown.GetLocation(start), cargo);

project.first_station = maybe_start_station;
project.second_station = maybe_end_station;

project.end_station = project.second_station.location;

maybe_start_station = project.first_station.location;
//maybe_end_station = project.end_station;

if((project.first_station.location==null)||(project.second_station.location==null))
  {
  if((maybe_start_station==null)&&(project.second_station.location==null))
    {
	this.Info("   Station placing near "+AITown.GetName(start)+" and "+AITown.GetName(town)+" is impossible.");
    project.zakazane.AddItem(project.start, 0);
    project.zakazane.AddItem(project.end, 0);
	}
  if((maybe_start_station==null)&&(project.second_station.location!=null))
    {
    this.Info("   Station placing near "+AITown.GetName(start)+" is impossible.");
    project.zakazane.AddItem(project.start, 0);
 	}
  if((maybe_start_station!=null)&&(project.second_station.location==null)) 
    {
	this.Info("   Station placing near "+AITown.GetName(town)+" is impossible.");
    project.zakazane.AddItem(project.end, 0);
 	}
  return project;
  }
this.Info("   Stations planned.");

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
	project.koniec_otoczka[0]=project.end_station+AIMap.GetTileIndex(0, 1);
	project.koniec_otoczka[1]=project.end_station+AIMap.GetTileIndex(0, -1);
	}
else
	{
	project.koniec_otoczka[0]=project.end_station+AIMap.GetTileIndex(1, 0);
	project.koniec_otoczka[1]=project.end_station+AIMap.GetTileIndex(-1, 0);
	}

return project;
//TODO make findbuspair better
}

function KRAI::IndustryToIndustryTruckStationAllocator(project)
{
local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;
local maybe_start_station = this.ZnajdzStacjeProducenta(producer, cargo);
local maybe_end_station = this.ZnajdzStacjeKonsumenta(consumer, cargo);

project.first_station = maybe_start_station;
project.second_station = maybe_end_station;

project.end_station = project.second_station.location;

return KRAI.UniversalStationAllocator(project);
}

function KRAI::IndustryToCityTruckStationAllocator(project)
{
local start = project.start;
local town = project.end;
local cargo = project.cargo;

local maybe_start_station = this.ZnajdzStacjeProducenta(start, cargo);
local maybe_end_station = this.ZnajdzStacjeMiejska(town, cargo);

project.first_station = maybe_start_station;
project.second_station = maybe_end_station;

project.end_station = project.second_station.location;

return KRAI.UniversalStationAllocator(project);
}

function KRAI::UniversalStationAllocator(project)
{
if((project.first_station.location==null)||(project.end_station==null))
  {
  if((project.first_station.location==null)&&(project.end_station==null))
    {
    project.zakazane.AddItem(project.start, 0);
	}
  if((project.first_station.location==null)&&(project.end_station!=null))
    {
    project.zakazane.AddItem(project.start, 0);
 	}
  if((project.first_station.location!=null)&&(project.end_station==null)) 
    {
 	}
  return project;
  }
this.Info("   Stations planned.");

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
	project.koniec_otoczka[0]=project.end_station+AIMap.GetTileIndex(0, 1);
	project.koniec_otoczka[1]=project.end_station+AIMap.GetTileIndex(0, -1);
	}
else
	{
	project.koniec_otoczka[0]=project.end_station+AIMap.GetTileIndex(1, 0);
	project.koniec_otoczka[1]=project.end_station+AIMap.GetTileIndex(-1, 0);
	}

return project;
}

function KRAI::BusRoute()
{
AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
trasa = Route();

for(local i=0; i<20; i++)
   {
   Warning("<==scanning=for=bus=route=");
   if(!this.FindBusPair())
      {
	  Info("Nothing found!");
	  _koszt = 0;
	  return false;
      }
   Warning("==scanning=completed=>");
   if(this.PrepareRoute())
      {
	  Info("   Contruction started on correct route.");
	  if(this.ConstructionOfBusRoute())
	  return true;
	  else trasa.zakazane.AddItem(trasa.start, 0);
	  }
   else
      {
	  if(trasa.start==null)return false;
	  else trasa.zakazane.AddItem(trasa.start, 0);
	  }
   }
return false;
}

function KRAI::TruckRoute()
{
Error("==================================");
AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
trasa = Route();

for(local i=0; i<20; i++)
   {
   Warning("<==scanning=for=truck=route=");
   trasa = this.FindPair(trasa); 
   if(!trasa.OK) 
      {
      Info("Nothing found!");
      _koszt = 0;
      return false;
      }

   Warning("==scanning=completed=> cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
   if(this.PrepareRoute())
      {
	  Info("   Contruction started on correct route.");
	  if(this.ConstructionOfTruckRoute())
	  return true;
	  else trasa.zakazane.AddItem(trasa.start, 0);
	  }
   else
      {
	  Info("   Route preaparings failed.");	  
	  if(trasa.start==null)return false;
	  else trasa.zakazane.AddItem(trasa.start, 0);
	  }
   }
return false;
}

function KRAI::PrepareRoute()
{
if(rodzic.GetSetting("debug_signs_for_planned_route")){
    AISign.BuildSign(trasa.start_tile, "trasa.start_tile");
    AISign.BuildSign(trasa.end_tile, "trasa.end_tile");
	}
this.Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));

local forbidden_tiles=array(2);
forbidden_tiles[0]=trasa.end_station;
forbidden_tiles[1]=trasa.first_station.location;

local pathfinder = CustomPathfinder();
pathfinder.Fast();
pathfinder.InitializePath(trasa.koniec_otoczka, trasa.start_otoczka, forbidden_tiles);
path = false;
local guardian=0;
local limit = (desperacja*3+20)*((AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile)/50) + 1)/2;
while (path == false) {
  path = pathfinder.FindPath(2000);
  rodzic.Konserwuj();
  AIController.Sleep(1);
  this.Info("   Pathfinding ("+guardian+" / " + limit + ")");
  guardian++;
  if(guardian>limit )break;
}

if(path == false || path == null){
  Info("   Pathfinder failed to find route. ");
  return false;
  }
  
this.Info("   Pathfinder found sth.");
local koszt = this.sprawdz_droge(path);
if(koszt==null){
  this.Info("   Pathfinder failed to find correct route.");
  return false;
  }

koszt += AIEngine.GetPrice(trasa.engine)*5;
_koszt=koszt;

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
    {
	rodzic.MoneyMenagement();
    if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
	   return false;
	   }
	}
return true;   
}

function KRAI::ConstructionOfTruckRoute()
{
if(!this.ZbudujStacjeCiezarowek())
   {
   trasa.zakazane.AddItem(trasa.start, 0);
   return false;	  
   }
return this.ConstructionOfRVRoute();
}

function KRAI::ConstructionOfBusRoute()
{
if(!this.ZbudujStacjeAutobusow())
   {
   if(trasa.start!=null) trasa.zakazane.AddItem(trasa.start, 0);
   return false;	  
   }
return this.ConstructionOfRVRoute();
}

function KRAI::ConstructionOfRVRoute()
{
if(!this.zbuduj_droge(path)){
   AIRoad.RemoveRoadStation(trasa.first_station.location);
   AIRoad.RemoveRoadStation(trasa.end_station);
   this.Info("   But stopped by error");
   return false;	  
   }

trasa.depot_tile = this.PostawDepot(path);
if(trasa.depot_tile==null){
   this.Info("   Depot placement error");
   return false;	  
   }

Info("   Route constructed!");

Info("   working on circle around loading bay");
this.CircleAroundStation(trasa.start_otoczka[0], trasa.start_otoczka[1], trasa.first_station.location);
AIRoad.BuildRoadDepot (trasa.start_otoczka[0], trasa.first_station.location);
AIRoad.BuildRoadDepot (trasa.start_otoczka[1], trasa.first_station.location);

local pojazdy_ile_nowych = this.BudujPojazdy();

if(pojazdy_ile_nowych==null)
   {
   Error("Oooops");
   AIRoad.RemoveRoadStation(trasa.first_station.location);
   AIRoad.RemoveRoadStation(trasa.end_station);
   _koszt = 0;
   return false;
   }

this.Info("   Vehicles construction, " + pojazdy_ile_nowych + " vehicles constructed.");

this.Info("   working on circle around unloading bay");
this.CircleAroundStation(trasa.koniec_otoczka[0], trasa.koniec_otoczka[1], trasa.end_station);
AIRoad.BuildRoadDepot (trasa.koniec_otoczka[0], trasa.end_station);
AIRoad.BuildRoadDepot (trasa.koniec_otoczka[1], trasa.end_station);

return true;
}

function KRAI::PostawDepot(path)
{
local ile = 0;
local odstep = 70;
local licznik = odstep-2;
local returnik = null;
while (path != null) 
  {
  if(returnik!=null)return returnik; //ubija wielokrotnoœæ
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

function KRAI::GetReplace(existing_vehicle, cargo)
{
return this.WybierzRV(cargo);
}

function WybierzRVForFindPair(route)
{
route.engine = WybierzRV(route.cargo);
if(route.engine == null) return route;
route.engine_count = IlePojazdow(route);
return route;
}

function KRAI::WybierzRV(cargo) //from admiral AI
{
local new_engine_id = null;
local list = AIEngineList(AIVehicle.VT_ROAD);
list.Valuate(AIEngine.GetRoadType);
list.KeepValue(AIRoad.ROADTYPE_ROAD);
//list.Valuate(AIEngine.IsArticulated); BuildDriveThroughRoadStation ;)
//list.KeepValue(0);
list.Valuate(AIEngine.CanRefitCargo, cargo);
list.KeepValue(1);
list.Valuate(AIEngine.GetMaxSpeed);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);

list.KeepAboveValue(AIEngine.GetMaxSpeed(list.Begin())*85/100);

list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);

if (list.Count() != 0) 
   {
   new_engine_id = list.Begin();
   }
return new_engine_id;
}

function KRAI::IsOKPlaceForRVStation(station_tile, direction)
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

//AISign.BuildSign(station_tile, "?");

local test = AITestMode();
/* Test Mode */

if(!AIRoad.BuildDriveThroughRoadStation(station_tile, t_ts[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   return false;
   }
if(!AIRoad.BuildRoad(t_ts[1], station_tile))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
	  //Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      return false;
	  }
   }
if(!AIRoad.BuildRoad(station_tile, t_ts[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  //Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      return false;
	  }
   }
return true;
}

function KRAI::IsWrongPlaceForRVStation(station, direction)
{
if(direction == StationDirection.x_is_constant__horizontal)
{
if(rodzic.IsTileWrongToFullUse(station))return true;
if(rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(0, 1)))return true;
if(rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(0, -1)))return true;
if(rodzic.IsTileWithAuthorityRefuse(station))return true;
return false;
}
else
{
if(rodzic.IsTileWrongToFullUse(station))return true;
if(rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(1, 0)))return true;
if(rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(-1, 0)))return true;
if(rodzic.IsTileWithAuthorityRefuse(station))return true;
return false;
}
}

function KRAI::ZnajdzStacje(list)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
   {
   if(!IsWrongPlaceForRVStation(station, StationDirection.x_is_constant__horizontal))
      {
	  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(station, "V");
	  local returnik = Station();
	  returnik.location = station;
	  returnik.direction = StationDirection.x_is_constant__horizontal;
	  return returnik;
	  }
   else if(!IsWrongPlaceForRVStation(station, StationDirection.y_is_constant__vertical))
      {
	  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(station, "V");
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

function KRAI::ZnajdzStacjeMiejska(town, cargo)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return this.ZnajdzStacje(list);
}

function KRAI::ZnajdzStacjeKonsumenta(consumer, cargo)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
return this.ZnajdzStacje(list);
}

function KRAI::ZnajdzStacjeProducenta(producer, cargo)
{
local list=AITileList_IndustryProducing(producer, 3);
return this.ZnajdzStacje(list);
}

function KRAI::ZnajdzBusStacje(town, start, cargo)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(max(25, 50-desperacja));

if(start != null)
   {
   list.Valuate(AIMap.DistanceManhattan, start);
   list.RemoveBelowValue(20);
   }

list.Valuate(rodzic.IsConnectedDistrict);
list.KeepValue(0);

list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return (this.ZnajdzStacje(list));
}

function KRAI::IlePojazdow(traska)
{
local speed = AIEngine.GetMaxSpeed(traska.engine);
local distance = AIMap.DistanceManhattan(traska.first_station.location, traska.end_station);
local ile = trasa.production/AIEngine.GetCapacity(traska.engine);
local mnoznik = ((distance*88)/(50*speed));
if(mnoznik==0)mnoznik=1;
ile*=mnoznik;
ile+=3;
return ile;
}

function KRAI::BudujPojazdy()
{
//trasa.type
//0 proceed trasa.cargo
//1 raw
//2 passenger

local zbudowano=0;

if(trasa.engine==null)return null;

local ile = trasa.engine_count;

local vehicle_id = -1;

vehicle_id=AIVehicle.BuildVehicle (trasa.depot_tile, trasa.engine);
while(!AIVehicle.IsValidVehicle(vehicle_id)) 
   {
   vehicle_id=AIVehicle.BuildVehicle (trasa.depot_tile, trasa.engine);
   this.Info("Vehicle building fail "+AIError.GetLastErrorString());
   if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH)
      {
	  Error(AIError.GetLastErrorString()+"++++++++++++")
	  return null;
	  }
   AIController.Sleep(100);
   }
{
zbudowano++;

if(trasa.type==1) //1 raw
   {
	AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")=="0") AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	else AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED);
	}
else if(trasa.type==0) //0 proceed trasa.cargo
   {
	AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );

	local pozycja_porownywacza=1;
	AIOrder.InsertConditionalOrder (vehicle_id, pozycja_porownywacza, 2);
	AIOrder.SetOrderCompareValue(vehicle_id, pozycja_porownywacza, 0); 
	AIOrder.SetOrderCondition (vehicle_id, pozycja_porownywacza, AIOrder.OC_LOAD_PERCENTAGE);
	AIOrder.SetOrderCompareFunction(vehicle_id, pozycja_porownywacza, AIOrder.CF_MORE_THAN);

	local pozycja_porownywacza=3;
	AIOrder.InsertConditionalOrder (vehicle_id, pozycja_porownywacza, 0);
	AIOrder.SetOrderCompareValue(vehicle_id, pozycja_porownywacza, 0); 
	AIOrder.SetOrderCondition (vehicle_id, pozycja_porownywacza, AIOrder.OC_UNCONDITIONALLY);
	}
else if(trasa.type == 2) //2 passenger
   {
	AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, trasa.end_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")=="0") AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	else AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED);
   }
else
   {
   Error("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
   local zero=0/0;
   }
AIVehicle.RefitVehicle (vehicle_id, trasa.cargo);
AIVehicle.StartStopVehicle (vehicle_id);

local string;
if(trasa.type==1) string = "Raw cargo";
else if(trasa.type==0) string = "Processed cargo"; 
else if(trasa.type==2) string = "Bus line";
else string = "WTF?"; 
local i = AIVehicleList().Count();
for(;!AIVehicle.SetName(vehicle_id, string + " #" + i); i++);
}

for(local i = 0; i<ile; i++) if(this.copyVehicle(vehicle_id, trasa.cargo)) zbudowano++;

return zbudowano;
}
