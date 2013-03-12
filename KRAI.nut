import("pathfinder.road", "RoadPathFinder", 3);

class KRAI
{
desperacja=0;
rodzic=null;
_koszt=0;
detected_rail_crossings = null;

forbidden = null;
start_station = null;
end_station = null;
start_tile = null;
end_tile = null;
ts = null;
te = null;
start = null;
end = null;
path = null;
depot_tile = null;
cargo = null; 
_production = null;
type = null;
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
local new = this.Uzupelnij();
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

class Route
{
start=null;
end=null;
cargo=null;
zakazane=null;
}

function KRAI::ZbudujStacjeCiezarowek(start_station, ts, end_station, te)
{
if(!AIRoad.BuildDriveThroughRoadStation(start_station, ts[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   this.Info("   Producer station placement impossible due to " + AIError.GetLastErrorString());
   return false;
   }
if(!AIRoad.BuildDriveThroughRoadStation(end_station, te[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) 
   {
   this.Info("   Consumer station placement impossible due to " + AIError.GetLastErrorString());
   AIRoad.RemoveRoadStation(start_station);
   return false;
   }
if(!AIRoad.BuildRoad(ts[1], start_station))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
	  this.Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(start_station);
      AIRoad.RemoveRoadStation(end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(start_station, ts[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(start_station);
      AIRoad.RemoveRoadStation(end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(te[1], end_station))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(start_station);
      AIRoad.RemoveRoadStation(end_station);
      return false;
	  }
   }
if(!AIRoad.BuildRoad(end_station, te[0]))
   {
   if(AIError.GetLastError()!=AIError.ERR_ALREADY_BUILT)
   if(AIError.GetLastError()!=AIError.ERR_NONE)
      {
  	  this.Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
      AIRoad.RemoveRoadStation(start_station);
      AIRoad.RemoveRoadStation(end_station);
      return false;
	  }
   }
return true;
}

function KRAI::IsLegalProducer(i, cargo)
{
if(AIIndustry.IsValidIndustry(i)==false) //industry closed during preprocessing
   {
   return false;
   }
if(forbidden.HasItem(i))return false;

if(rodzic.IsConnectedIndustry(i, cargo))
   {
   forbidden.AddItem(i, 0);
   return false;
   }
return true;
}

function KRAI::FindPair()
{
local industry_list = rodzic.GetIndustryList();
Error(industry_list.Count()+"");
local trasa = Route();
local best=0;
local start=null;
local end=null;
local _cargo;
local _production;
local new;

for (local i = industry_list.Begin(); industry_list.HasNext(); i = industry_list.Next()) //from Chopper
   {
   if(AIIndustry.IsValidIndustry(i)==false) //industry closed during preprocessing
      {
	  continue;
	  }
   local x;
   local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(i));
   if(cargo_list.Count()==0) continue;
   local cargo;
   cargo_list.Valuate(AIBase.RandItem);
   cargo_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);

   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
   {
   if(IsLegalProducer(i, cargo)==false)
      {
	  continue;
	  }
	
   local industry_list_for_that_for = rodzic.GetIndustryList_CargoAccepting(cargo);
   
   local base = AIIndustry.GetLastMonthProduction(i, cargo);
   base*=(100-AIIndustry.GetLastMonthTransportedPercentage (i, cargo));
   base*=AICargo.GetCargoIncome(cargo, 10, 50);
   if(base!=0)
	  if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(i)))
		{
		//base*=3;
	    //base/=2;
		base+=10000;
	    }

   if(industry_list_for_that_for.Count()>0)
   {
   for (x = industry_list_for_that_for.Begin(); industry_list_for_that_for.HasNext(); x = industry_list_for_that_for.Next()) //from Chopper
        {
        if(AIIndustry.IsValidIndustry(x)==false) //industry closed during preprocessing
          {
	      continue;
	      }
		if(forbidden.HasItem(x))continue;
	    new =  base;
	    local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(x), AIIndustry.GetLocation(i));
		new*= this.distanceBetweenIndustriesValuator(distance);
		if(AIIndustry.GetStockpiledCargo(x, cargo)==0) new*=2;

		if(AITile.GetCargoAcceptance (AIIndustry.GetLocation(x), cargo, 1, 1, 4)==0)
              {
			  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(AIIndustry.GetLocation(x), AICargo.GetCargoLabel(cargo) + "refused here");
			  new=0;
			  }
		if(new>best)
			{
			if(StationAllocator(i, x, cargo))
				{
				//local string = "Para " + AIIndustry.GetName(i) + ", " + AIIndustry.GetName(x) + " otrzymala " + new + " punktow i bije wroga.";
				//Error(string);
				best = new;
				start=i;
				end=x;
				_cargo=cargo;
				start_tile = AIIndustry.GetLocation(start);
				end_tile = AIIndustry.GetLocation(end);
				}
			}
		}
	}
	else
	   {
	   local town_list = AITownList();
	   town_list.Valuate(AITown.GetDistanceManhattanToTile, AIIndustry.GetLocation(i));
	   town_list.KeepBelowValue(GetMaxDistance());
	   town_list.KeepAboveValue(GetMinDistance());
	   town_list.Valuate(AIBase.RandItem);
	   town_list.KeepTop(1);
	   local town = town_list.Begin();
	   local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(town), AIIndustry.GetLocation(i));
	   new=base;
	   new*= this.distanceBetweenIndustriesValuator(distance);
	   /*if(AIIndustry.GetStockpiledCargo(x, cargo)==0)*/ new*=2;

		if(new>best)
			{
	        Info("Z " + AIIndustry.GetName(i) + " nie ma dokad wysylac. Sorry. Or maybe " + AITown.GetName(town));
			if(CityStationAllocator(i, town, cargo))
				{
				Warning("In");
				//local string = "Para " + AIIndustry.GetName(i) + ", " + AIIndustry.GetName(x) + " otrzymala " + new + " punktow i bije wroga.";
				//Error(string);
				best = new;
				start=i;
				end=town;
				_cargo=cargo;
				start_tile = null;
				end_tile = null;
				start_tile = AIIndustry.GetLocation(start);
				end_tile = AITown.GetLocation(end);
				}
			}
		}
	
	/*
	if(x!=null)
       {
		  local string = "Para " + AIIndustry.GetName(i) + ", " + AIIndustry.GetName(x) + " otrzymala " + new + " punktow.";
	      if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(i))) Info(string);
		  Warning(string);
	   }     
	*/
    }
	}
trasa.start=start;
trasa.end=end;
trasa.cargo=_cargo;
trasa.zakazane=forbidden;
this.Info("");
this.Info("(" + best + " points)");
return trasa;
}

function KRAI::CityStationAllocator(start, town, cargo)
{
local maybe_start_station = this.ZnajdzStacjeProducenta(start);
local maybe_end_station = this.ZnajdzStacjeMiejska(town, cargo);
if((maybe_start_station==null)||(maybe_end_station==null))
  {
  if((maybe_start_station==null)&&(maybe_end_station==null))
    {
	this.Info("   Station placing near "+AIIndustry.GetName(start)+" and "+AITown.GetName(town)+" is impossible.");
    forbidden.AddItem(start, 0);
    //forbidden.AddItem(end, 0);
	}
  if((maybe_start_station==null)&&(maybe_end_station!=null))
    {
    this.Info("   Station placing near "+AIIndustry.GetName(start)+" is impossible.");
    forbidden.AddItem(start, 0);
 	}
  if((maybe_start_station!=null)&&(maybe_end_station==null)) 
    {
	this.Info("   Station placing near "+AITown.GetName(town)+" is impossible.");
    //forbidden.AddItem(end, 0);
 	}
  return false;
  }
this.Info("   Stations planned.");

start_station = maybe_start_station;
end_station = maybe_end_station;

ts = array(2);
te = array(2);

ts[0]=start_station+AIMap.GetTileIndex(0, 1);
ts[1]=start_station+AIMap.GetTileIndex(0, -1);
te[0]=end_station+AIMap.GetTileIndex(0, 1);
te[1]=end_station+AIMap.GetTileIndex(0, -1);
return true;
}

function KRAI::StationAllocator(start, end, cargo)
{
local maybe_start_station = this.ZnajdzStacjeProducenta(start);
local maybe_end_station = this.ZnajdzStacjeKonsumenta(end, cargo);

if((maybe_start_station==null)||(maybe_end_station==null))
  {
  if((maybe_start_station==null)&&(maybe_end_station==null))
    {
	this.Info("   Station placing near "+AIIndustry.GetName(start)+" and "+AIIndustry.GetName(end)+" is impossible.");
    forbidden.AddItem(start, 0);
    forbidden.AddItem(end, 0);
	}
  if((maybe_start_station==null)&&(maybe_end_station!=null))
    {
    this.Info("   Station placing near "+AIIndustry.GetName(start)+" is impossible.");
    forbidden.AddItem(start, 0);
 	}
  if((maybe_start_station!=null)&&(maybe_end_station==null)) 
    {
	this.Info("   Station placing near "+AIIndustry.GetName(end)+" is impossible.");
    forbidden.AddItem(end, 0);
 	}
  return false;
  }
this.Info("   Stations planned.");

start_station = maybe_start_station;
end_station = maybe_end_station;

ts = array(2);
te = array(2);

ts[0]=start_station+AIMap.GetTileIndex(0, 1);
ts[1]=start_station+AIMap.GetTileIndex(0, -1);
te[0]=end_station+AIMap.GetTileIndex(0, 1);
te[1]=end_station+AIMap.GetTileIndex(0, -1);
return true;
}

function KRAI::TruckRoute()
{
AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
if(!this.PrepareTruckRoute()) return false;
//this.ShowTruckRoute();
return this.ConstructionOfTruckRoute();
}

function KRAI::PrepareTruckRoute()
{
local bic_producentow = AIBase.RandRange(2);

local best;
forbidden = AIList();

while (true)
{
local trasa=Route();
Warning("<==scanning=for=route=");
trasa = this.FindPair();
Warning("==scanning=completed=>");
start = trasa.start;
end = trasa.end;
cargo = trasa.cargo;
forbidden = trasa.zakazane;
if(start == null)
   {
   this.Info("Nothing found!");
   _koszt = 0;
   return false;
   }
_production=AIIndustry.GetLastMonthProduction(start, cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (start, cargo))/100;

if(rodzic.GetSetting("debug_signs_for_planned_route")) 
    {
    AISign.BuildSign(start_tile, "start_tile");
    AISign.BuildSign(end_tile, "end_tile");
	}
	
this.Info("   Company started route planning from " + AIIndustry.GetName(start) + ". Distance: " + AIMap.DistanceManhattan(start_tile, end_tile));

if(this.WybierzRV(cargo)==null)
  {
  AILog.Error("No truck for " + AICargo.GetCargoLabel(cargo) + " available.");
  if(AIDate.GetYear(AIDate.GetCurrentDate ())<1935)  AILog.Error("Default truck are available after 1935! Start game later or try eGRVTS with vehicles from year 1705");
  else AILog.Error(" Probably you use newgrf industry without newgrf road vehicles. Try eGRVTS or HEQS with trucks for new cargos.");
  forbidden.AddItem(start, 0);
  continue;
  }

local forbidden_tiles=array(2);
forbidden_tiles[0]=end_station;
forbidden_tiles[1]=start_station;

local pathfinder = CustomPathfinder();
pathfinder.Fast();
pathfinder.InitializePath(te, ts, forbidden_tiles);
path = false;
local guardian=0;
local limit = (desperacja*3+20)*((AIMap.DistanceManhattan(start_tile, end_tile)/50) + 1)/2;
//this.Info("   Library pathfindrer started");
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
  if(bic_producentow)
     {
	 forbidden.AddItem(start, 0);
	 }
  else 
     {
	 forbidden.AddItem(end, 0);
	 }
  if(start!=null)forbidden.AddItem(start, 0);
  this.Info("   Pathfinder failed to find route. ");
  continue;
  }
  
this.Info("   Pathfinder found sth.");

local koszt = this.sprawdz_droge(path);

if(koszt==null)
  {
  if(start!=null)forbidden.AddItem(start, 0);
  this.Info("   Pathfinder failed to find correct route.");
  continue;
  }

koszt += AIEngine.GetPrice(WybierzRV(cargo))*5;
_koszt=koszt;

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
    {
	rodzic.MoneyMenagement();
    if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
          {
	      if(start!=null) forbidden.AddItem(start, 0);
	      continue;	  
	      }
	   }
	}
if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(start))) type=1;
else type=0;
this.Info("   Contruction started on correct route.");
return true;   
}
}

function KRAI::ShowTruckRoute()
{
AISign.BuildSign(start_station, "start_station");
AISign.BuildSign(end_station, "end_station");
}


function KRAI::ConstructionOfTruckRoute()
{
if(!this.ZbudujStacjeCiezarowek(start_station, ts, end_station, te))
   {
   if(start!=null) forbidden.AddItem(start, 0);
   return false;	  
   }
return this.ConstructionOfRVRoute();
}

function KRAI::ConstructionOfRVRoute()
{

if(!this.zbuduj_droge(path))
   {
   AIRoad.RemoveRoadStation(start_station);
   AIRoad.RemoveRoadStation(end_station);
   this.Info("   But stopped by error");
   if(start!=null) forbidden.AddItem(start, 0);
   return false;	  
   }

//path po kolei szukaj¹c miejsca na depot - droga p³aska, miejsce na depot p³askie niezabudowane
depot_tile = this.PostawDepot(path);
if(depot_tile==null)
   {
   this.Info("   Depot placement error");
   if(start!=null) forbidden.AddItem(start, 0);
   return false;	  
   }

 this.Info("   Route constructed!");

this.Info("   working on circle around loading bay");
this.CircleAroundStation(ts[0], ts[1], start_station);

local pojazdy_ile_nowych = this.BudujPojazdy(depot_tile, start_station, end_station, cargo, _production, type);

if(pojazdy_ile_nowych==null)
   {
   AILog.Error("Oooops");
   AILog.Error("Error");
   AIRoad.RemoveRoadStation(start_station);
   AIRoad.RemoveRoadStation(end_station);
   _koszt = 0;
   return false;
   }

this.Info("   Vehicles construction, " + pojazdy_ile_nowych + " vehicles constructed.");

this.Info("   working on circle around unloading bay");
this.CircleAroundStation(te[0], te[1], end_station);
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
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(0, 1), path.GetTile()))
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(0, 1), path.GetTile()))
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
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(0, -1), path.GetTile())) 
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(0, -1), path.GetTile()))
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
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(1, 0), path.GetTile())) 
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(1, 0), path.GetTile()))
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
		  if(AIRoad.BuildRoadDepot (path.GetTile()+AIMap.GetTileIndex(-1, 0), path.GetTile())) 
		  if(AIRoad.BuildRoad(path.GetTile()+AIMap.GetTileIndex(-1, 0), path.GetTile()))
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
   //local test = AIExecMode();
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

function KRAI::ZnajdzStacje(test)
{
for(local station = test.Begin(); test.HasNext(); station = test.Next())
   {
   if(!IsWrongPlaceForRVStation(station))return station;
   }
   
for(local station = test.Begin(); test.HasNext(); station = test.Next())
   {
   if(IsOKPlaceForRVStation(station))return station;
   }
return null;
}

function KRAI::ZnajdzStacjeProducenta(start)
{
local test=AITileList_IndustryProducing(start, 3);
return this.ZnajdzStacje(test);
}

function KRAI::ZnajdzStacjeMiejska(town, cargo)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
return this.ZnajdzStacje(list);
}

function KRAI::ZnajdzStacjeKonsumenta(start, cargo)
{
local test=AITileList_IndustryAccepting(start, 3);
test.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
test.RemoveValue(0);
return this.ZnajdzStacje(test);
}

function KRAI::IlePojazdow(new_engine_id, start_station, end_station)
{
local speed = AIEngine.GetMaxSpeed(new_engine_id);
local distance = AIMap.DistanceManhattan(start_station, end_station);
local ile = _production/AIEngine.GetCapacity(new_engine_id);
local mnoznik = ((distance*88)/(50*speed));
if(mnoznik==0)mnoznik=1;
ile*=mnoznik;
ile+=3;
return ile;
}

function KRAI::BudujPojazdy(depot_tile, start_station, end_station, cargo, _production, type)
{
//type
//0 proceed cargo
//1 raw
//2 passenger

local zbudowano=0;

local new_engine_id = this.WybierzRV(cargo);
if(new_engine_id==null)return null;

local ile = IlePojazdow(new_engine_id, start_station, end_station);

local vehicle_id = -1;

vehicle_id=AIVehicle.BuildVehicle (depot_tile, new_engine_id);
while(!AIVehicle.IsValidVehicle(vehicle_id)) 
   {
   vehicle_id=AIVehicle.BuildVehicle (depot_tile, new_engine_id);
   this.Info("Vehicle building fail "+AIError.GetLastErrorString());
   if(AIError.GetLastError()!=AIVehicle.ERR_NOT_ENOUGH_CASH)
      {
	  AILog.Error(AIError.GetLastErrorString()+"++++++++++++")
	  return null;
	  }
   AIController.Sleep(100);
   }
{
zbudowano++;
if(type==1)
   {
	AIOrder.AppendOrder (vehicle_id, start_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	}
else if(type==0)
   {
	AIOrder.AppendOrder (vehicle_id, start_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );

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
else if(type == 2)
   {
   	AIOrder.AppendOrder (vehicle_id, start_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
   }
else
   {
   Error("Wrong value in type. (" + type + ") Prepare for explosion.");
   local zero=0/0;
   }
AIVehicle.RefitVehicle (vehicle_id, cargo);
AIVehicle.StartStopVehicle (vehicle_id);

local string;
if(type==1) string = "Raw cargo";
else string = "Processed cargo"; 
local i = AIVehicleList().Count();
for(;!AIVehicle.SetName(vehicle_id, string + " #" + i); i++);
}

for(local i = 0; i<ile; i++) if(this.copyVehicle(vehicle_id, cargo)) zbudowano++;

return zbudowano;
}
