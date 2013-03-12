import("pathfinder.road", "RoadPathFinder", 3);

class KRAI
{
desperacja=0;
rodzic=null;
_koszt=0;
}

function KRAI::CzyJuzZlinkowane(i, cargo)
{
local tile_list=AITileList_IndustryProducing(i, 3); //TODO - to tylko dla truck station
for (local q = tile_list.Begin(); tile_list.HasNext(); q = tile_list.Next()) //from Chopper 
   {
   local station_id = AIStation.GetStationID(q);
   if(AIStation.IsValidStation(station_id))
      {
	  local vehicle_list=AIVehicleList_Station(station_id);
	  if(AIStation.GetStationID(this.GetLoadStation(vehicle_list.Begin()))==station_id) //czy full load jest na wykrytej stacji
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

function KRAI::Info(string)
{
local date=AIDate.GetCurrentDate ();
AILog.Info(AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date)  + " " + string);
}

function KRAI::Konserwuj()
{
local sold = this.DeleteRVInDepots();
local new = this.ZbudujDodatkowePojazdy();
local redundant = this.UsunNadmiarowePojazdy();
if((new+sold+redundant)>0) this.Info(" Vehicles: " + new + " new, " +  sold + " deleted, " + redundant + " redundant send to depot.");

//local renew=array(2);
//renew[0]=0;
//renew[1]=0;
//if(AICompany.GetLoanAmount()==0) renew=this.RenewRV();
//if((new+sold+renew[0]+renew[1])>0) this.Info(" Vehicles: " + new + " new, " +  sold + " deleted, " + redundant + " redundant send to depot, " + renew[0] + " old replaced by " + renew[1] + " new.");
}

function KRAI::GetLoadStation(vehicle)
{
return AIOrder.GetOrderDestination(vehicle, 0);
}

function KRAI::GetUnLoadStation(vehicle)
{
return AIOrder.GetOrderDestination(vehicle, AIOrder.GetOrderCount(vehicle)-2);
}

function KRAI::GetDepot(vehicle)
{
return AIOrder.GetOrderDestination(vehicle, AIOrder.GetOrderCount(vehicle)-1);
}

class CustomPathfinder extends RoadPathFinder //Made with Zutty's help - thanks for help http://www.tt-forums.net/viewtopic.php?f=65&t=47219
{
   _cost_level_crossing = null; //from SIMPLEAI
   function InitializePath(sources, goals, ignored) {
      local nsources = [];

      foreach (node in sources) {
         nsources.push([node, 0xFF]);
      }

      this._pathfinder.InitializePath(nsources, goals, ignored);
   }

function _Cost(path, new_tile, new_direction, self)//from SIMPLEAI
{
	local cost = ::RoadPathFinder._Cost(path, new_tile, new_direction, self);
	if (AITile.HasTransportType(new_tile, AITile.TRANSPORT_RAIL)) cost += self._cost_level_crossing;
	return cost;
}

function _GetTunnelsBridges(last_node, cur_node, bridge_dir)//from SIMPLEAI
{
	local slope = AITile.GetSlope(cur_node);
	if (slope == AITile.SLOPE_FLAT && AITile.IsBuildable(cur_node + (cur_node - last_node))) return [];
	local tiles = [];
	for (local i = 2; i < this._max_bridge_length; i++) {
		local bridge_list = AIBridgeList_Length(i + 1);
		local target = cur_node + i * (cur_node - last_node);
		if (!bridge_list.IsEmpty() && AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), cur_node, target)) {
			tiles.push([target, bridge_dir]);
		}
	}

	if (slope != AITile.SLOPE_SW && slope != AITile.SLOPE_NW && slope != AITile.SLOPE_SE && slope != AITile.SLOPE_NE) return tiles;
	local other_tunnel_end = AITunnel.GetOtherTunnelEnd(cur_node);
	if (!AIMap.IsValidTile(other_tunnel_end)) return tiles;

	local tunnel_length = AIMap.DistanceManhattan(cur_node, other_tunnel_end);
	local prev_tile = cur_node + (cur_node - other_tunnel_end) / tunnel_length;
	if (AITunnel.GetOtherTunnelEnd(other_tunnel_end) == cur_node && tunnel_length >= 2 &&
			prev_tile == last_node && tunnel_length < _max_tunnel_length && AITunnel.BuildTunnel(AIVehicle.VT_ROAD, cur_node)) {
		tiles.push([other_tunnel_end, bridge_dir]);
	}
	return tiles;
}
   
function Fast()
{
_cost_level_crossing = 30;
cost.tile = 10;
cost.max_cost = 4000;          // = equivalent of 400 tiles
cost.no_existing_road = 1;     // changed//don't care about reusing existing roads
cost.turn = 1;                 // minor penalty for turns
cost.slope =   10;             //changed //  don't care about slopes
cost.bridge_per_tile = 4;      // bridges / tunnels are 50% more expensive per tile than normal tiles
cost.tunnel_per_tile = 4;
cost.coast =   0;              // don't care about coast tiles
cost.max_bridge_length = 15;   // The maximum length of a bridge that will be build.
cost.max_tunnel_length = 15;   // The maximum length of a tunnel that will be build.
}

function CircleAroundStation()
{
_cost_level_crossing = 30;
cost.tile = 10;
cost.max_cost = 200;          // = equivalent of 100 tiles
cost.no_existing_road = 10;   // no rebuilding
cost.turn = 1;                 // minor penalty for turns
cost.slope =   1000;              //  don't care about slopes
cost.bridge_per_tile = 5;      // bridges / tunnels are 50% more expensive per tile than normal tiles
cost.tunnel_per_tile = 5;
cost.coast =   0;              // don't care about coast tiles
cost.max_bridge_length = 0;   // The maximum length of a bridge that will be build.
cost.max_tunnel_length = 0;   // The maximum length of a tunnel that will be build.
}

}

function KRAI::distanceBetweenIndustriesValuator(distance, station_counter)
{
if(distance<10) return 0;

if(desperacja>5)
   {
   if(distance>desperacja*100)return 0;
   if(distance>desperacja*60)return 1;
   return 4;
   }
if(station_counter==0)
   {
   if(distance>100) return 0;
   if(distance<20) return 0;
   return 30;
   }

if(distance>desperacja*70)return 0;
if(distance>200) return 1;
if(distance>150) return 10;
if(distance>100) return 20;
if(distance>80) return 30;
if(distance>=40) return 20;
if(distance<40) return 10;
if(distance<20) return 1;
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

function KRAI::FindRoute(forbidden)
{
local industry_list = AIIndustryList();
local trasa = Route();
local best=0;
local start=null;
local end=null;
local _cargo;
local _production;

for (local i = industry_list.Begin(); industry_list.HasNext(); i = industry_list.Next()) //from Chopper
   {
   if(forbidden.HasItem(i))continue;
   local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(i));
   if(cargo_list==null)continue; //without that sometimes crashes
   if(cargo_list.Count()==0)continue;
   
   local cargo;
   
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
   {
   if(!(AIStationList(AIStation.STATION_ANY)).IsEmpty())
      {
	  if(this.CzyJuzZlinkowane(i, cargo))
	     {
		 if(i!=null)forbidden.AddItem(i, 0);
		 continue;
	     }
	  }
	
    local industry_list_for_that_for = AIIndustryList_CargoAccepting(cargo);
	for (local x = industry_list_for_that_for.Begin(); industry_list_for_that_for.HasNext(); x = industry_list_for_that_for.Next()) //from Chopper
        {
		if(forbidden.HasItem(x))continue;
	    local new;
		if(i!=null) 
		   {
		   new =  AIIndustry.GetLastMonthProduction(i, cargo);

		   local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(x), AIIndustry.GetLocation(i));
		   new*= this.distanceBetweenIndustriesValuator
		       (distance, (AIStationList(AIStation.STATION_ANY)).Count());

		   new*=(100-AIIndustry.GetLastMonthTransportedPercentage (i, cargo));

		   new*=AICargo.GetCargoIncome(cargo, 10, 50);

		   if(AIIndustry.GetStockpiledCargo(x, cargo)==0) new*=2;
		   
		   if(new!=0)
		      if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(i)))
			     {
				 new*=2;
				 new+=1000;
				 }

		  if(AITile.GetCargoAcceptance (AIIndustry.GetLocation(x), cargo, 1, 1, 4)==0)
              {
			  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(AIIndustry.GetLocation(x), AICargo.GetCargoLabel(cargo) + "refused here");
			  new=0;
			  }
		   }
		else 
		   {
		   continue;
		   }
		if(new>best)
	       {
   	       best = new;
	       start=i;
	       end=x;
	       _cargo=cargo;
		   }
		 if(desperacja>9)
		    {
			if(new>10)
			   {
			   trasa.start=start;
			   trasa.end=end;
			   trasa.cargo=_cargo;
			   trasa.zakazane=forbidden;
			   this.Info("");
			   this.Info("(" + best + " points)");
			   return trasa;
			   }
			}
		}
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

function KRAI::skonstruj_trase()
{
local bic_producentow = AIBase.RandRange(2);

local best;
local start;
local end;
local cargo;
local _production;
local forbidden = AIList();
local depot_tile;
local start_station;
local end_station;
local ts=array(2);
local te=array(2);

while (true)
{
local trasa=Route();
trasa = this.FindRoute(forbidden);
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

local start_tile = AIIndustry.GetLocation(start);
local end_tile = AIIndustry.GetLocation(end);
	
if(rodzic.GetSetting("debug_signs_for_planned_route")) 
    {
    AISign.BuildSign(start_tile, "start_tile");
    AISign.BuildSign(end_tile, "end_tile");
	}
	
this.Info("   Company started route planning between " + AIIndustry.GetName(start) + " and " + AIIndustry.GetName(end) + 
". Distance: " + AIMap.DistanceManhattan(start_tile, end_tile));

if(this.WybierzRV(cargo)==null)
  {
  AILog.Error("No truck for " + AICargo.GetCargoLabel(cargo) + " available.");
  if(AIDate.GetYear(AIDate.GetCurrentDate ())<1935)  AILog.Error("Default truck are available after 1935! Start game later or try eGRVTS with vehicles from year 1705");
  else AILog.Error(" Probably you use newgrf industry without newgrf road vehicles. Try eGRVTS or HEQS with trucks for new cargos.");
  forbidden.AddItem(start, 0);
  continue;
  }

start_station = this.ZnajdzStacjeProducenta(start);
end_station = this.ZnajdzStacjeKonsumenta(end, cargo);

if((start_station==null)||(end_station==null))
  {
  if((start_station==null)&&(end_station==null))
    {
	this.Info("   Station placing near "+AIIndustry.GetName(start)+" and "+AIIndustry.GetName(end)+" is impossible.");
    forbidden.AddItem(start, 0);
    forbidden.AddItem(end, 0);
	}
  if((start_station==null)&&(end_station!=null))
    {
    this.Info("   Station placing near "+AIIndustry.GetName(start)+" is impossible.");
    forbidden.AddItem(start, 0);
	}
  if((start_station!=null)&&(end_station==null)) 
    {
	this.Info("   Station placing near "+AIIndustry.GetName(end)+" is impossible.");
    forbidden.AddItem(end, 0);
	}
  continue;
  }
this.Info("   Stations planned.");

ts[0]=start_station+AIMap.GetTileIndex(0, 1);
ts[1]=start_station+AIMap.GetTileIndex(0, -1);
te[0]=end_station+AIMap.GetTileIndex(0, 1);
te[1]=end_station+AIMap.GetTileIndex(0, -1);

local forbidden_tiles=array(2);
forbidden_tiles[0]=end_station;
forbidden_tiles[1]=start_station;

local pathfinder = CustomPathfinder();
pathfinder.Fast();
AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
pathfinder.InitializePath(te, ts, forbidden_tiles);

local path = false;
local guardian=0;
//this.Info("   Library pathfindrer started");
while (path == false) {
  path = pathfinder.FindPath(1000);
  rodzic.Konserwuj();
  AIController.Sleep(1);
  //this.Info("   Pathfinding ("+guardian+")");
  guardian++;
  if(guardian>desperacja+30)break;
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

koszt += AIEngine.GetPrice(WybierzRV(cargo))*3;
  
if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
    {
	this.Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
      {
	  if(start!=null) forbidden.AddItem(start, 0);
	  _koszt=koszt;
	  continue;	  
	  }
	}

this.Info("   Contruction started on correct route.");

if(!this.ZbudujStacjeCiezarowek(start_station, ts, end_station, te))
   {
   if(start!=null) forbidden.AddItem(start, 0);
   continue;	  
   }

if(!this.zbuduj_droge(path))
   {
   AIRoad.RemoveRoadStation(start_station);
   AIRoad.RemoveRoadStation(end_station);
   this.Info("   But stopped by error");
   if(start!=null) forbidden.AddItem(start, 0);
   continue;
   }

//path po kolei szukaj¹c miejsca na depot - droga p³aska, miejsce na depot p³askie niezabudowane, //TODO droga wolna od kolei!

depot_tile = this.PostawDepot(path);
if(depot_tile==null)
   {
   AIRoad.RemoveRoadStation(start_station);
   AIRoad.RemoveRoadStation(end_station);
   this.Info("   Depot placement error");
   if(start!=null) forbidden.AddItem(start, 0);
   continue;
   }
break;   
}
this.Info("   Route constructed!");

while( AICompany.GetBankBalance(AICompany.COMPANY_SELF) < 4000)
   {
   this.Info("   Not enough money for vehicles. Waiting. ");
   rodzic.Konserwuj();
   AIController.Sleep(1000);
   }


this.Info("   working on circle around loading bay");
if(!this.CircleAroundStation(ts[0], ts[1], start_station))
   {
   AIController.Sleep(100);
   this.CircleAroundStation(ts[0], ts[1], start_station);
   }

local raw=AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(start));
local pojazdy_ile_nowych = this.BudujPojazdy(depot_tile, start_station, end_station, cargo, _production, raw);

if(pojazdy_ile_nowych==null)
   {
   AILog.Error("Oooops");
   AILog.Error("TOO MANY RV");
   AIRoad.RemoveRoadStation(start_station);
   AIRoad.RemoveRoadStation(end_station);
   _koszt = 0;
   return false;
   }

this.Info("   Vehicles construction, " + pojazdy_ile_nowych + " vehicles constructed.");

this.Info("   working on circle around unloading bay");
if(!this.CircleAroundStation(te[0], te[1], end_station))
   {
   AIController.Sleep(100);
   this.CircleAroundStation(te[0], te[1], end_station);
   }

return true;
}

function KRAI::PostawDepot(path)
{
local ile = 0;
local odstep = 40;
local licznik = odstep+1;
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

function KRAI::WybierzRV(cargo)
{
local new_engine_id = null;
//from admiral AI
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

function KRAI::ZnajdzStacje(test)
{
local station=test.Begin();
while
(
rodzic.IsTileWrongToFullUse(station)
||
rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(0, 1))
||
rodzic.IsTileWrongToFullUse(station+AIMap.GetTileIndex(0, -1))
||
rodzic.IsTileWithAuthorityRefuse(station)
)
{
if(test.HasNext()) 
{
station=test.Next();
}
else return null;
}
return station;
}

function KRAI::ZnajdzStacjeProducenta(start)
{
local test=AITileList_IndustryProducing(start, 3);
return this.ZnajdzStacje(test);
}

function KRAI::ZnajdzStacjeKonsumenta(start, cargo)
{
local test=AITileList_IndustryAccepting(start, 3);
test.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
test.RemoveValue(0);
return this.ZnajdzStacje(test);
}

function KRAI::ZbudujKawalateczekDrogi(path, par, depth)
{
if(depth==6)
   {
	this.Info("Construction terminated: "+AIError.GetLastErrorString()); 
	if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
   }

if(depth>=6)return false;

local rezultat;
if (AIMap.DistanceManhattan(path, par) == 1 ) 
   {
   rezultat = AIRoad.BuildRoad(path, par);
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
		 rezultat = AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path);
		 } 
      else 
	     {
         local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path, par) + 1);
         bridge_list.Valuate(AIBridge.GetMaxSpeed);
         bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
         rezultat = AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path, par);
        }
      }
    }
	
if(!rezultat)
   {
   local error=AIError.GetLastError();
   if(error==AIError.ERR_ALREADY_BUILT)return true;
   if(error==AIError.ERR_VEHICLE_IN_THE_WAY)
   {
   AIController.Sleep(20);
   return this.ZbudujKawalateczekDrogi(path, par, depth+1);
   }
   return false;
   }
return true;
}

function KRAI::sprawdz_droge(path)
{
local costs = AIAccounting();
costs.ResetCosts ();

 /* Exec Mode */
{
local test = AITestMode();
/* Test Mode */

if(path==null)return false;
while (path != null) {
  local par = path.GetParent();
  if (par != null) {
    local last_node = path.GetTile();
	if(!this.ZbudujKawalateczekDrogi(path.GetTile(),  par.GetTile(), 0))
	    {
		AILog.Error(AIError.GetLastErrorString());
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

function KRAI::zbuduj_droge(path)
{
if(path==null)return false;
while (path != null) {
  local par = path.GetParent();
  if (par != null) {
    local last_node = path.GetTile();
	if(!this.ZbudujKawalateczekDrogi(path.GetTile(),  par.GetTile(), 0))
	    {
		return false;
		}
  }
  path = par;
}
return true;
}

function KRAI::RawVehicle(vehicle)
{
if(AIOrder.GetOrderCount(vehicle)==3)return true;
return false;
}

function KRAI::ZbudujDodatkowePojazdy()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
   {
   local station_list=AIStationList(AIStation.STATION_TRUCK_STOP);
   for (local aktualna = station_list.Begin(); station_list.HasNext(); aktualna = station_list.Next()) //from Chopper
	  {
	  if(NajmlodszyPojazd(aktualna)>20) //nie dodawaæ masowo
	  if(AIStation.GetCargoWaiting(aktualna, cargo)>50 || (AIStation.GetCargoRating(aktualna, cargo)<40&&AIStation.GetCargoWaiting(aktualna, cargo)>0) ) //HARDCODED OPTION
	  {
	     local vehicle_list=AIVehicleList_Station(aktualna);
		 
		 vehicle_list.Valuate(AIBase.RandItem);
		 vehicle_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
		 local original=vehicle_list.Begin();
		 
		 if(AIVehicle.GetProfitLastYear(original)<0)continue;

		 //WTF NIE DZIA£A
		 //local end = this.GetUnloadStation(original);
		 //return AIOrder.GetOrderDestination(vehicle, AIOrder.GetOrderCount(vehicle)-2);
		 
		 local end = AIOrder.GetOrderDestination(original, AIOrder.GetOrderCount(original)-2);

	     if(AITile.GetCargoAcceptance (end, cargo, 1, 1, 4)==0)
		    {
			if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(end, "ACCEPTATION STOPPED");
			continue;
			}
		 if(this.RawVehicle(original)) 
		    {
			if(this.copyVehicle(original, cargo )) ile++;
			}
		 else 
		    {
			if(AIStation.GetCargoWaiting(aktualna, cargo)>150 || (AIStation.GetCargoRating(aktualna, cargo)<40&&AIStation.GetCargoWaiting(aktualna, cargo)>0)) 
			   {
			   if(this.copyVehicle(original, cargo)) ile++;
			   }
			}
		}
	  }
   }
return ile;
}

function KRAI::DeleteRVInDepots()
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

function KRAI::CzyNaSprzedaz(car)
{
local name=AIVehicle.GetName(car)+"            ";
local forsell="for sell";
local n=6;

for(local i=0; i<n; i++)
if(name[i]!=forsell[i])return false;
return true;
}

function KRAI::copyVehicle(main_vehicle_id, cargo)
{
if(AIVehicle.IsValidVehicle(main_vehicle_id)==false)return false;

local depot_tile = this.GetDepot(main_vehicle_id);

local speed = AIEngine.GetMaxSpeed(this.WybierzRV(cargo));
local distance = AIMap.DistanceManhattan(this.GetLoadStation(main_vehicle_id), this.GetUnLoadStation(main_vehicle_id));

//OPTION
//1 na tile przy 25 km/h

local maksymalnie=distance*50/(speed+10);

local station_tile = this.GetLoadStation(main_vehicle_id);
local station_id = AIStation.GetStationID(station_tile);
local list = AIVehicleList_Station(station_id);   	
local ile = list.Count();

//this.Info("Ile: "+ile+" na " + maksymalnie);

if(ile<maksymalnie)
   {
   local vehicle_id = AIVehicle.BuildVehicle (depot_tile, this.WybierzRV(cargo));
   if(AIVehicle.IsValidVehicle(vehicle_id))
      {
	  AIOrder.CopyOrders (vehicle_id, main_vehicle_id)
	  AIVehicle.RefitVehicle(vehicle_id, cargo);
	  AIVehicle.StartStopVehicle (vehicle_id);
	  return true;
	  }
   }
return false;
}

function KRAI::sellVehicle(main_vehicle_id)
{
if(this.CzyNaSprzedaz(main_vehicle_id)==true)return false;

if(AIVehicle.SendVehicleToDepot(main_vehicle_id))
   {
   if(!AIVehicle.SetName(main_vehicle_id, "for sell"))
      {
	  local o=1;
	  while(!AIVehicle.SetName(main_vehicle_id, "for sell # "+o)){o++;}
	  }
   return true;
   }
return false;
}

/*
function KRAI::RenewRV()
{
local ile=array(2);
ile[0]=0; //old
ile[1]=0; //new


local list=AIVehicleList();
local cargo_list = AICargoList();
for (local main_vehicle_id = list.Begin(); list.HasNext(); main_vehicle_id = list.Next()) //from Chopper 
   {
   if(!this.CzyNaSprzedaz(main_vehicle_id))
   if(AIVehicle.GetAge(main_vehicle_id)>900)
      {
	  for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper 
	  if(AIVehicle.GetCapacity (main_vehicle_id, cargo)>0)
	  if(AIVehicle.GetCargoLoad (main_vehicle_id, cargo)==0)
         {
		 local station_id = AIStation.GetStationID(this.GetLoadStation(main_vehicle_id));

		 if(AIStation.GetCargoWaiting(station_id, cargo)>200)continue;

		 if(AIVehicleList_Station(station_id).Count()==0)
		   {
	       copyVehicle(main_vehicle_id, cargo);
		   }
		 local percent = (AIBase.RandRange(100));

		 if(percent<85)
		    {
    		if(this.copyVehicle(main_vehicle_id, cargo)) 
			   {
			   this.sellVehicle(main_vehicle_id);
			   ile[1]++;
               ile[0]++;
			   }
		    }
		 else
            {
			this.sellVehicle(main_vehicle_id);
            ile[0]++;
			}		 
		 }	  
	  }
   }

return ile;
}
*/

function KRAI::UsunNadmiarowePojazdy()
{
local ile=0;
local cargo_list = AICargoList();

local station_list = AIStationList(AIStation.STATION_TRUCK_STOP);
for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next()) //from Chopper 
   {
   if(NajmlodszyPojazd(station)<70)continue;
   local vehicle_list = AIVehicleList_Station(station);
   local counter=0;
   local cargo;
	
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper 
      {
	  if(AIVehicle.GetCapacity (vehicle_list.Begin(), cargo)>0)
	      {
		  break;
		  }
	  }
	
	local czy_load=vehicle_list.Begin();
	local station_id = AIStation.GetStationID(this.GetLoadStation(czy_load));

   //this.Info("Station with " + AIStation.GetCargoWaiting(station, cargo) + " of " + AICargo.GetCargoLabel(cargo));
	
   if(station==station_id)	
   if(AIStation.GetCargoWaiting(station, cargo)<150)
      {   
	  for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next()) //from Chopper 
       {
	   if(AIVehicle.GetCargoLoad (vehicle, cargo)==0)
	   if(AIVehicle.GetAge(vehicle)>60)
	   if(!this.CzyNaSprzedaz(vehicle))
	   if(AIStation.GetDistanceManhattanToTile(station, AIVehicle.GetLocation(vehicle))<=2) //OPTION
	      {
    	  //this.Info(AIVehicle.GetName(vehicle)+" ***"+AIStation.GetDistanceManhattanToTile (station, AIVehicle.GetLocation(vehicle))+"*** <"+counter);
		  counter++;
		  
		  if(AIVehicle.GetCurrentSpeed(vehicle)<20)counter++;
		  if(AIVehicle.GetCurrentSpeed(vehicle)>40)counter--;
		  
		  if(counter>5) //OPTION
	         {
		     ile++;
		     this.sellVehicle(vehicle);
		     }
		  }
	   }
	  }
   }

return ile;
}

function KRAI::CircleAroundStation(tile_s, tile_e, tile_i)
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

  if(path==null)return false;

  rodzic.Konserwuj();

  AIController.Sleep(1);
  }

return this.zbuduj_droge(path);
}

function KRAI::BudujPojazdy(depot_tile, start_station, end_station, cargo, _production, raw)
{
local zbudowano=0;

local new_engine_id = this.WybierzRV(cargo);
if(new_engine_id==null)return null;
local speed = AIEngine.GetMaxSpeed(this.WybierzRV(cargo));
local distance = AIMap.DistanceManhattan(start_station, end_station);
local ile = _production/AIEngine.GetCapacity(new_engine_id);
local mnoznik = ((distance*88)/(50*speed));
if(mnoznik==0)mnoznik=1;
ile*=mnoznik;
ile+=3;

//this.Info("ile: "+ile);
local vehicle_id = -1;

vehicle_id=AIVehicle.BuildVehicle (depot_tile, new_engine_id);
while(!AIVehicle.IsValidVehicle(vehicle_id)) 
   {
   vehicle_id=AIVehicle.BuildVehicle (depot_tile, new_engine_id);
   this.Info("Vehicle building fail "+AIError.GetLastErrorString());
   if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_BUILD_DISABLED)return null;
   if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_TOO_MANY)return null;
   if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_WRONG_DEPOT)return 0;
   AIController.Sleep(100);
   }
{
zbudowano++;
if(raw)
   {
	AIOrder.AppendOrder (vehicle_id, start_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	}
else
   {
	AIOrder.AppendOrder (vehicle_id, start_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (vehicle_id, end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (vehicle_id, depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED | AIOrder.AIOF_NON_STOP_INTERMEDIATE );

	local pozycja_porownywacza=1;
	AIOrder.InsertConditionalOrder (vehicle_id, pozycja_porownywacza, 2);
	AIOrder.SetOrderCompareValue(vehicle_id, pozycja_porownywacza, 0); 
	AIOrder.SetOrderCondition (vehicle_id, pozycja_porownywacza, AIOrder.OC_LOAD_PERCENTAGE);
	AIOrder.SetOrderCompareFunction(vehicle_id, pozycja_porownywacza, AIOrder.CF_MORE_THAN);

	local pozycja_porownywacza=3;
	AIOrder.InsertConditionalOrder (vehicle_id, pozycja_porownywacza, 0);
	AIOrder.SetOrderCompareValue(vehicle_id, pozycja_porownywacza, 0); 
	AIOrder.SetOrderCondition (vehicle_id, pozycja_porownywacza, AIOrder.OC_UNCONDITIONALLY);
	//AIOrder.SetOrderCompareFunction(vehicle_id, pozycja_porownywacza, AIOrder.CF_MORE_THAN);
	/*
InsertConditionalOrder (VehicleID vehicle_id, OrderPosition order_position, OrderPosition jump_to)
Appends a conditional order before the given order_position into the vehicle's order list. */
	}
AIVehicle.RefitVehicle (vehicle_id, cargo);
AIVehicle.StartStopVehicle (vehicle_id);
}

for(local i = 0; i<ile; i++) if(this.copyVehicle(vehicle_id, cargo)) zbudowano++;

return zbudowano;
}
