import("pathfinder.road", "RoadPathFinder", 3);

class Route
{
start=null;
end=null;
zakazane=null;
start_otoczka=null;
koniec_otoczka=null;
depot_tile = null;
start_station = null;
end_station = null;
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
//trasa.type
//0 proceed trasa.cargo
//1 raw
//2 passenger
}

class KRAI
{
desperacja=0;
rodzic=null;
_koszt=0;
detected_rail_crossings = null;
path = null;

trasa = Route();
}

require("KRAIutil.nut");
require("KRAI_level_crossing_menagement_from_clueless_plus.nut");
require("KRAIpathfinder.nut");

function KRAI::IsConnectedIndustry(i, cargo)
{
if(AIStationList(AIStation.STATION_ANY).IsEmpty())return false;

local tile_list=AITileList_IndustryProducing(i, 3); //TODO - to tylko dla truck station
for (local q = tile_list.Begin(); tile_list.HasNext(); q = tile_list.Next()) //from Chopper 
   {
   local station_id = AIStation.GetStationID(q);
   if(AIStation.IsValidStation(station_id))
      {
	  local vehicle_list=AIVehicleList_Station(station_id);
	  if(vehicle_list.Count()!=0)
	  if(AIStation.GetStationID(GetLoadStation(vehicle_list.Begin()))==station_id) //czy full load jest na wykrytej stacji
	  {
	  if(AIVehicle.GetCapacity(vehicle_list.Begin(), cargo)!=0)//i laduje z tej stacji //TERAZ to getcargoload
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
if((new+redundant)>0) this.Info(" Vehicles: " + new + " new, " +  redundant + " redundant send to depot.");
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
if(!AIRoad.BuildDriveThroughRoadStation(trasa.start_station, trasa.start_otoczka[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   this.Info("   Producer station placement impossible due to " + AIError.GetLastErrorString());
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.start_station, AIError.GetLastErrorString());
   return false;
   }
if(!AIRoad.BuildDriveThroughRoadStation(trasa.end_station, trasa.koniec_otoczka[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   this.Info("   Consumer station placement impossible due to " + AIError.GetLastErrorString());
   AIRoad.RemoveRoadStation(trasa.start_station);
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.end_station, AIError.GetLastErrorString());
   return false;
   }
return RoadToStation();
}

function KRAI::ZbudujStacjeAutobusow()
{
if(!AIRoad.BuildDriveThroughRoadStation(trasa.start_station, trasa.start_otoczka[0], AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) 
   {
   this.Info("   Producer station placement impossible due to " + AIError.GetLastErrorString());
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.start_station, AIError.GetLastErrorString());
   return false;
   }
if(!AIRoad.BuildDriveThroughRoadStation(trasa.end_station, trasa.koniec_otoczka[0], AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) 
   {
   this.Info("   Consumer station placement impossible due to " + AIError.GetLastErrorString());
   AIRoad.RemoveRoadStation(trasa.start_station);
   if(rodzic.GetSetting("other_debug_signs")) AISign.BuildSign(trasa.end_station, AIError.GetLastErrorString());
   return false;
   }
return RoadToStation();
}

function KRAI::RoadToStation()
{
if(!AIRoad.BuildRoad(trasa.start_otoczka[1], trasa.start_station))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
	  this.Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.start_station);
      AIRoad.RemoveRoadStation(trasa.end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(trasa.start_station, trasa.start_otoczka[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(trasa.start_station);
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
      AIRoad.RemoveRoadStation(trasa.start_station);
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
      AIRoad.RemoveRoadStation(trasa.start_station);
      AIRoad.RemoveRoadStation(trasa.end_station);
      return false;
	  }
   }
return true;
}

////////////////////////?????????????????????????///////////////

function KRAI::IsProducerOK(ID)
{
local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(ID));
if(cargo_list==null) return false;
if(cargo_list.Count()==0) return false;
if(AIIndustry.IsValidIndustry(ID)==false) //industry closed during preprocessing
   {
   return false;
   }
return true;
}

function KRAI::IsKicked(ID)
{
return trasa.zakazane.HasItem(ID);
}

function KRAI::IsConsumerOK(ID)
{
if(AIIndustry.IsValidIndustry(ID)==false) //industry closed during preprocessing
   {
   return false;
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
return base;
}

function KRAI::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
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
Info("From " + AITown.GetName(trasa.start) + "  to " +  AITown.GetName(trasa.end) );
if(trasa.end == null) return false;
if(BusStationAllocator(trasa.start, trasa.end, rodzic.GetPassengerCargoId()))
	{
	trasa.cargo=rodzic.GetPassengerCargoId();;
	trasa.start_tile = AITown.GetLocation(trasa.start);
	trasa.end_tile = AITown.GetLocation(trasa.end);
	trasa.production = min(AITile.GetCargoAcceptance(trasa.start_station, trasa.cargo, 1, 1, 3), AITile.GetCargoAcceptance(trasa.end_station, trasa.cargo, 1, 1, 3));
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

function KRAI::FindPair()
{
//local IndustryListSource = rodzic.GetIndustryList;
//local industry_list = IndustryListSource(); //Why in is executed in another way than function below?
											//And unable to use local rodzic's variables?

//local industry_list = rodzic.GetIndustryList(); //Working

local binded_f = rodzic.GetIndustryList.bindenv(rodzic);
local industry_list = binded_f();

Error(industry_list.Count()+"");
local traska = Route();
local best=0;
local new;

for (traska.start = industry_list.Begin(); industry_list.HasNext(); traska.start = industry_list.Next()) //from Chopper
   {
   if(this.IsProducerOK(traska.start)==false)continue; /////////////////////////////////
   if(this.IsKicked(traska.start))continue; /////////////////////////////////
   local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(traska.start));
   for (traska.cargo = cargo_list.Begin(); cargo_list.HasNext(); traska.cargo = cargo_list.Next())
   {
   if(rodzic.IsConnectedIndustry(traska.start, traska.cargo))continue; /////////////////////////////////
   local industry_list_accepting_current_cargo = rodzic.GetIndustryList_CargoAccepting(traska.cargo);
   local base = this.ValuateProducer(traska.start, traska.cargo);///////////////////////////////////////////////////
   if(industry_list_accepting_current_cargo.Count()>0)
   {
   for(traska.end = industry_list_accepting_current_cargo.Begin(); industry_list_accepting_current_cargo.HasNext(); traska.end = industry_list_accepting_current_cargo.Next())
        {
		if(this.IsKicked(traska.start))continue; /////////////////////////////////
		if(this.IsConsumerOK(traska.start)==false)continue; /////////////////////////////////
	    new = 	this.ValuateConsumer(traska.end, traska.cargo, base)	////////////////////////////////////////////
		local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(traska.end), AIIndustry.GetLocation(traska.start)); ////////////////////////////////////////////
		new*= this.distanceBetweenIndustriesValuator(distance); ////////////////////////////////////////////

		if(AITile.GetCargoAcceptance (AIIndustry.GetLocation(traska.end), traska.cargo, 1, 1, 4)==0)
              {
			  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(AIIndustry.GetLocation(traska.end), AICargo.GetCargoLabel(traska.cargo) + "refused here");
			  new=0;
			  }
		if(new>best)
			{
			if(StationAllocator(traska.start, traska.end, traska.cargo))	////////////////////////////////////////////Station allocator
				{
				best = new;
				trasa.start=traska.start;
				trasa.end=traska.end;
				trasa.cargo=traska.cargo;
				trasa.start_tile = AIIndustry.GetLocation(traska.start);
				trasa.end_tile = AIIndustry.GetLocation(traska.end);
				trasa.production=AIIndustry.GetLastMonthProduction(trasa.start, trasa.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (trasa.start, trasa.cargo))/100;
				}
			}
		}
	}
	else
	   {
	   local town = GetNiceRandomTown(AIIndustry.GetLocation(traska.start)); ////////////////CITY SCANNER
	   if(town==null)continue;
	   local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(town), AIIndustry.GetLocation(traska.start));
	   new=base;
	   new*= this.distanceBetweenIndustriesValuator(distance); //////////////////////////////////////////////
	   /*if(AIIndustry.GetStockpiledCargo(x, traska.cargo)==0)*/ new*=2;
		if(new>best)
			{
	        Info("Z " + AIIndustry.GetName(traska.start) + " nie ma dokad wysylac. Sorry. Or maybe " + AITown.GetName(town));
			if(CityStationAllocator(traska.start, town, traska.cargo))
				{
				best = new;
				trasa.start=traska.start;
				trasa.end=town;
				trasa.cargo=traska.cargo;
				trasa.start_tile = AIIndustry.GetLocation(traska.start);
				trasa.end_tile = AITown.GetLocation(town);
				trasa.production=AIIndustry.GetLastMonthProduction(trasa.start, trasa.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (trasa.start, trasa.cargo))/100;
				}
			}
		}
	}
	}
this.Info("");
this.Info("(" + best + " points)");

if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(trasa.start))) trasa.type=1;
else trasa.type=0;

if(best==0)return false;
return true;
}

function KRAI::BusStationAllocator(start, town, cargo)
{
local maybe_start_station = this.ZnajdzBusStacje(start, null, cargo);
local maybe_end_station = this.ZnajdzBusStacje(town, AITown.GetLocation(start), cargo);
if((maybe_start_station==null)||(maybe_end_station==null))
  {
  if((maybe_start_station==null)&&(maybe_end_station==null))
    {
	this.Info("   Station placing near "+AITown.GetName(start)+" and "+AITown.GetName(town)+" is impossible.");
    trasa.zakazane.AddItem(trasa.start, 0);
    trasa.zakazane.AddItem(trasa.end, 0);
	}
  if((maybe_start_station==null)&&(maybe_end_station!=null))
    {
    this.Info("   Station placing near "+AITown.GetName(start)+" is impossible.");
    trasa.zakazane.AddItem(trasa.start, 0);
 	}
  if((maybe_start_station!=null)&&(maybe_end_station==null)) 
    {
	this.Info("   Station placing near "+AITown.GetName(town)+" is impossible.");
    trasa.zakazane.AddItem(trasa.end, 0);
 	}
  return false;
  }
this.Info("   Stations planned.");

trasa.start_station = maybe_start_station;
trasa.end_station = maybe_end_station;

trasa.start_otoczka = array(2);
trasa.koniec_otoczka = array(2);

trasa.start_otoczka[0]=trasa.start_station+AIMap.GetTileIndex(0, 1);
trasa.start_otoczka[1]=trasa.start_station+AIMap.GetTileIndex(0, -1);
trasa.koniec_otoczka[0]=trasa.end_station+AIMap.GetTileIndex(0, 1);
trasa.koniec_otoczka[1]=trasa.end_station+AIMap.GetTileIndex(0, -1);
return true;
}

function KRAI::CityStationAllocator(start, town, cargo)
{
local maybe_start_station = this.ZnajdzStacjeProducenta(start, cargo);
local maybe_end_station = this.ZnajdzStacjeMiejska(town, cargo);
if((maybe_start_station==null)||(maybe_end_station==null))
  {
  if((maybe_start_station==null)&&(maybe_end_station==null))
    {
	this.Info("   Station placing near "+AIIndustry.GetName(start)+" and "+AITown.GetName(town)+" is impossible.");
    trasa.zakazane.AddItem(start, 0);
    //trasa.zakazane.AddItem(end, 0);
	}
  if((maybe_start_station==null)&&(maybe_end_station!=null))
    {
    this.Info("   Station placing near "+AIIndustry.GetName(start)+" is impossible.");
    trasa.zakazane.AddItem(start, 0);
 	}
  if((maybe_start_station!=null)&&(maybe_end_station==null)) 
    {
	this.Info("   Station placing near "+AITown.GetName(town)+" is impossible.");
    //trasa.zakazane.AddItem(trasa.end, 0);
 	}
  return false;
  }
this.Info("   Stations planned.");

trasa.start_station = maybe_start_station;
trasa.end_station = maybe_end_station;

trasa.start_otoczka = array(2);
trasa.koniec_otoczka = array(2);

trasa.start_otoczka[0]=trasa.start_station+AIMap.GetTileIndex(0, 1);
trasa.start_otoczka[1]=trasa.start_station+AIMap.GetTileIndex(0, -1);
trasa.koniec_otoczka[0]=trasa.end_station+AIMap.GetTileIndex(0, 1);
trasa.koniec_otoczka[1]=trasa.end_station+AIMap.GetTileIndex(0, -1);
return true;
}

function KRAI::StationAllocator(producer, consumer, cargo)
{
local maybe_start_station = this.ZnajdzStacjeProducenta(producer, cargo);
local maybe_end_station = this.ZnajdzStacjeKonsumenta(consumer, cargo);

if((maybe_start_station==null)||(maybe_end_station==null))
  {
  if((maybe_start_station==null)&&(maybe_end_station==null))
    {
	this.Info("   Station placing near "+AIIndustry.GetName(producer)+" and "+AIIndustry.GetName(consumer)+" is impossible.");
    trasa.zakazane.AddItem(producer, 0);
    trasa.zakazane.AddItem(consumer, 0);
	}
  if((maybe_start_station==null)&&(maybe_end_station!=null))
    {
    this.Info("   Station placing near "+AIIndustry.GetName(producer)+" is impossible.");
    trasa.zakazane.AddItem(producer, 0);
 	}
  if((maybe_start_station!=null)&&(maybe_end_station==null)) 
    {
	this.Info("   Station placing near "+AIIndustry.GetName(consumer)+" is impossible.");
    trasa.zakazane.AddItem(consumer, 0);
 	}
  return false;
  }
this.Info("   Stations planned.");

trasa.start_station = maybe_start_station;
trasa.end_station = maybe_end_station;

trasa.start_otoczka = array(2);
trasa.koniec_otoczka = array(2);

trasa.start_otoczka[0]=maybe_start_station+AIMap.GetTileIndex(0, 1);
trasa.start_otoczka[1]=maybe_start_station+AIMap.GetTileIndex(0, -1);
trasa.koniec_otoczka[0]=maybe_end_station+AIMap.GetTileIndex(0, 1);
trasa.koniec_otoczka[1]=maybe_end_station+AIMap.GetTileIndex(0, -1);
return true;
}

function KRAI::BusRoute()
{
AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
trasa.zakazane = AIList();

for(local i=0; i<20; i++)
   {
   Warning("<==scanning=for=bus=route=");
   if(!this.FindBusPair()) return false;
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
trasa.zakazane = AIList();

for(local i=0; i<20; i++)
   {
   Warning("<==scanning=for=truck=route=");
   if(this.FindPair()==false) return false;
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
if(trasa.start == null)
   {
   this.Info("Nothing found!");
   _koszt = 0;
   return false;
   }

if(rodzic.GetSetting("debug_signs_for_planned_route")) 
    {
    AISign.BuildSign(trasa.start_tile, "trasa.start_tile");
    AISign.BuildSign(trasa.end_tile, "trasa.end_tile");
	}
	
this.Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));

if(this.WybierzRV(trasa.cargo)==null)
  {
  Error("No truck for " + AICargo.GetCargoLabel(trasa.cargo) + " available.");
  if(AIDate.GetYear(AIDate.GetCurrentDate ())<1935)  Error("Default truck are available after 1935! Start game later or try eGRVTS with vehicles from year 1705");
  else Error(" Probably you use newgrf industry without newgrf road vehicles. Try eGRVTS or HEQS with trucks for new cargos.");
  return false;
  }

local forbidden_tiles=array(2);
forbidden_tiles[0]=trasa.end_station;
forbidden_tiles[1]=trasa.start_station;

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

if(path == false || path == null)
  {
  this.Info("   Pathfinder failed to find route. ");
  return false;
  }
  
this.Info("   Pathfinder found sth.");

local koszt = this.sprawdz_droge(path);

if(koszt==null)
  {
  this.Info("   Pathfinder failed to find correct route.");
  return false;
  }

koszt += AIEngine.GetPrice(WybierzRV(trasa.cargo))*5;
_koszt=koszt;

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
    {
	rodzic.MoneyMenagement();
    if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
          {
		  return false;
	      }
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

if(!this.zbuduj_droge(path))
   {
   AIRoad.RemoveRoadStation(trasa.start_station);
   AIRoad.RemoveRoadStation(trasa.end_station);
   this.Info("   But stopped by error");
   return false;	  
   }

//path po kolei szukaj¹c miejsca na depot - droga p³aska, miejsce na depot p³askie niezabudowane
trasa.depot_tile = this.PostawDepot(path);
if(trasa.depot_tile==null)
   {
   this.Info("   Depot placement error");
   return false;	  
   }

 this.Info("   Route constructed!");

this.Info("   working on circle around loading bay");
this.CircleAroundStation(trasa.start_otoczka[0], trasa.start_otoczka[1], trasa.start_station);

local pojazdy_ile_nowych = this.BudujPojazdy();

if(pojazdy_ile_nowych==null)
   {
   Error("Oooops");
   Error("Error");
   AIRoad.RemoveRoadStation(trasa.start_station);
   AIRoad.RemoveRoadStation(trasa.end_station);
   _koszt = 0;
   return false;
   }

this.Info("   Vehicles construction, " + pojazdy_ile_nowych + " vehicles constructed.");

this.Info("   working on circle around unloading bay");
this.CircleAroundStation(trasa.koniec_otoczka[0], trasa.koniec_otoczka[1], trasa.end_station);
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

function KRAI::IsOKPlaceForRVStation(station_tile)
{
//AISign.BuildSign(station_tile, "!");

local t_ts = array(2);
t_ts[0]=station_tile+AIMap.GetTileIndex(0, 1);
t_ts[1]=station_tile+AIMap.GetTileIndex(0, -1);

//AISign.BuildSign(station_tile, "?");

local test = AITestMode();
/* Test Mode */

if(!AIRoad.BuildDriveThroughRoadStation(station_tile, t_ts[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   //Info("   Producer station placement impossible due to " + AIError.GetLastErrorString());
   //local Test = AIExecMode();
   //AISign.BuildSign(station_tile, "X");
   //AISign.BuildSign(t_ts[0], "Y");
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

function KRAI::IsWrongPlaceForRVStation(station)
{
if(rodzic.IsTileWrongToFullUse(station))return true;
if(rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(0, 1)))return true;
if(rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(0, -1)))return true;
if(rodzic.IsTileWithAuthorityRefuse(station))return true;
return false;
}

function KRAI::ZnajdzStacje(list)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
   {
   if(!IsWrongPlaceForRVStation(station))
      {
	  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(station, "V");
	  return station;
	  }
   else
	  {
	  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(station, "X");
	  }
   }
//Info("II phase");
for(local station = list.Begin(); list.HasNext(); station = list.Next())
   {
   if(IsOKPlaceForRVStation(station))return station;
   }
return null;
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
return this.ZnajdzStacje(list);
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

function KRAI::IlePojazdow(new_engine_id)
{
local speed = AIEngine.GetMaxSpeed(new_engine_id);
local distance = AIMap.DistanceManhattan(trasa.start_station, trasa.end_station);
local ile = trasa.production/AIEngine.GetCapacity(new_engine_id);
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

local new_engine_id = this.WybierzRV(trasa.cargo);
if(new_engine_id==null)return null;

local ile = IlePojazdow(new_engine_id);

local vehicle_id = -1;

vehicle_id=AIVehicle.BuildVehicle (trasa.depot_tile, new_engine_id);
while(!AIVehicle.IsValidVehicle(vehicle_id)) 
   {
   vehicle_id=AIVehicle.BuildVehicle (trasa.depot_tile, new_engine_id);
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
	AIOrder.AppendOrder (vehicle_id, trasa.start_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")=="0") AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	else AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED);
	}
else if(trasa.type==0) //0 proceed trasa.cargo
   {
	AIOrder.AppendOrder (vehicle_id, trasa.start_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE );
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
	AIOrder.AppendOrder (vehicle_id, trasa.start_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
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
if(trasa.type==1) string = "Raw trasa.cargo";
else string = "Processed trasa.cargo"; 
local i = AIVehicleList().Count();
for(;!AIVehicle.SetName(vehicle_id, string + " #" + i); i++);
}

for(local i = 0; i<ile; i++) if(this.copyVehicle(vehicle_id, trasa.cargo)) zbudowano++;

return zbudowano;
}
