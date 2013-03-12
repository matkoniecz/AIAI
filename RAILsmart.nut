function RAIL::SmartRailConnection()
{
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin());
for(local i=0; i<20; i++)
   {
   Warning("<==scanning=for=Smart=rail=route=");
   trasa = this.FindPairForSmartRailRoute(trasa);  
   if(!trasa.OK) 
      {
      Info("Nothing found!");
      _koszt = 0;
      return false;
      }

   Warning("==scanning=for=Smart=rail=route=completed=> cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
   if(this.SmartRailRoute()) 
      {
	  return true;
	  }
  else trasa.zakazane.AddItem(trasa.start, 0);
   }
return false;
}

function RAIL::SmartRailRoute()
{
this.Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));

local pathfinder = Rail();
pathfinder.estimate_multiplier = 3;
pathfinder.cost.bridge_per_tile = 500;
pathfinder.cost.tunnel_per_tile = 0;
pathfinder.cost.diagonal_tile = 35;
pathfinder.cost.coast = 0;
pathfinder.cost.max_bridge_length = 30;   // The maximum length of a bridge that will be build.
pathfinder.cost.max_tunnel_length = 30;   // The maximum length of a tunnel that will be build.

//local pathfinder = MyRailPF();
//pathfinder.Fast();

//[start_tile, tile_before_start]
local start = array(2);
local end = array(2);

if(trasa.first_station.direction != StationDirection.x_is_constant__horizontal)
   {
   //BuildNewGRFRailStation (TileIndex tile, RailTrack direction, uint num_platforms, uint platform_length, StationID station_id, CargoID cargo_id, IndustryType source_industry, IndustryType goal_industry, int distance, bool source_station)
   if(!AIRail.BuildNewGRFRailStation(trasa.first_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, 1, 1, 50, true)) //TODO to 1, 1 miasto (patrz tt moj temat)
      {
	  AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString()+"Sa");
	  trasa.zakazane.AddItem(trasa.start, 0);
	  return false;
	  }
   start[0] = [trasa.first_station.location+AIMap.GetTileIndex(-1, 0), trasa.first_station.location] 
   start[1] = [trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size, 0), trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size -1, 0)] 
   }
else
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.first_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, 1, 1, 50, true)) 
      {
	  AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString()+"Sb");
	  trasa.zakazane.AddItem(trasa.start, 0);
	  return false;
	  }
   start[0] = [trasa.first_station.location + AIMap.GetTileIndex(0, -1), trasa.first_station.location] //TODO drugi koniedc
   start[1] = [trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
   }

if(trasa.second_station.direction != StationDirection.x_is_constant__horizontal)
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.second_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, 1, 1, 50, false))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+"Ea");
	  trasa.zakazane.AddItem(trasa.end, 0); //TODO a miasta?
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(-1, 0), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size, 0), trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size -1, 0)] 
   }
else
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.second_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, 1, 1, 50, false))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+"Eb");
	  trasa.zakazane.AddItem(trasa.end, 0); //TODO a miasta?
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(0, -1), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
   }
  
  
pathfinder.InitializePath(start, end);
path = false
path = false;
local guardian=0;
local time;
local limit = min((desperacja+20)*AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile)/20, 25);
while (path == false) {
  path = pathfinder.FindPath(2000);
  rodzic.Konserwuj();
  AIController.Sleep(1);
  this.Info("   Pathfinding ("+guardian+" / " + limit + ")");
  guardian++;
  time = guardian;
  if(guardian>limit )break;
}

if(path == false || path == null){
  Info("   Pathfinder failed to find route. ");
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  return false;
  }
  
this.Info("   Pathfinder found sth.");

local koszt = RAIL.GetCostOfRoute(path); 
if(koszt==null){
  this.Info("   Pathfinder failed to find correct route.");
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  return false;
  }

koszt+=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);
_koszt=koszt;

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	rodzic.MoneyMenagement();
    while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
	   rodzic.Konserwuj(); //TODO bez wydawania kasy
	   AIController.Sleep(1000);
	   }
	}

if(!this.RailwayLinkConstruction(path)){
   //AIRail.RemoveRailStationTileRect(trasa.first_station); ........... //TODO DO IT
   this.Info("   But stopped by error");
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
   return false;	  
   }

trasa.depot_tile = RAIL.BuildDepot(path, true);
   
if(trasa.depot_tile==null){
   this.Info("   Depot placement error");
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  RAIL.DumbRemover(path, null)
   return false;	  
   }

local new_engine = this.BuildTrain(trasa);

if(new_engine == null)
   {
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  RAIL.DumbRemover(path, null)
   return false;
   }
this.TrainOrders(new_engine);
   Info("   I stage completed");

local old_path = path;
pathfinder.InitializePath(end, start);
path = false
path = false;
guardian=0;
limit = min(min((desperacja+20)*AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile)/20, 25), 2*time+10);
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
  //TODO passing lanes
  return false;
  }
  
this.Info("   Pathfinder found sth.");

local koszt = RAIL.GetCostOfRoute(path); 
if(koszt==null){
  this.Info("   Pathfinder failed to find correct route.");
  //TODO passing lanes
  return false;
  }

_koszt=koszt;

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	rodzic.MoneyMenagement();
    while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
	   rodzic.Konserwuj(); //TODO bez wydawania kasy
	   AIController.Sleep(1000);
	   }
	}

if(!this.RailwayLinkConstruction(path)){
   this.Info("   But stopped by error");
  //TODO passing lanes
   return false;	  
   }

RAIL.SignalPath(path);
RAIL.SignalPath(old_path);
koszt=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	rodzic.MoneyMenagement();
    while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
	   rodzic.Konserwuj(); //TODO bez wydawania kasy
	   AIController.Sleep(1000);
	   }
	}

new_engine = this.BuildTrain(trasa);
if(new_engine == null)
   {
   //TODO handle that
   }
this.TrainOrders(new_engine);
AITown.PerformTownAction(trasa.first_station.location, AITown.TOWN_ACTION_BUILD_STATUE);
return true;
}

function RAIL::FindPairForSmartRailRoute(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this); 
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuatorSmartRail = this.distanceBetweenIndustriesValuatorSmartRail.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuatorSmartRail, IndustryToIndustryTrainSmartRailStationAllocator, GetNiceRandomTownSmartRail, IndustryToCityTrainSmartRailStationAllocator, DenverAndRioGrande.GetTrain);
}

function RAIL::GetNiceRandomTownSmartRail(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistanceSmartRail());
town_list.KeepAboveValue(GetMinDistanceSmartRail());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0)return null;
return town_list.Begin();
}

function RAIL::IndustryToIndustryTrainSmartRailStationAllocator(project)
{
project.station_size = 7;

local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;

project.first_station.location = null; 
for(; project.station_size>1; project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaSmartRail(producer, cargo, project.station_size);
project.second_station = this.ZnajdzStacjeKonsumentaSmartRail(consumer, cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.end_station = project.second_station.location;

return project;
}

function RAIL::IndustryToCityTrainSmartRailStationAllocator(project)
{
project.station_size = 7;

project.first_station.location = null; 
for(; project.station_size>1; project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaSmartRail(project.start, project.cargo, project.station_size);
project.second_station = this.ZnajdzStacjeMiejskaSmartRail(project.end, project.cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.end_station = project.second_station.location;
return project;
}

function RAIL::ZnajdzStacjeMiejskaSmartRail(town, cargo, size)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return this.ZnajdzStacjeSmartRail(list, size);
}

function RAIL::ZnajdzStacjeKonsumentaSmartRail(consumer, cargo, size)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
return this.ZnajdzStacjeSmartRail(list, size);
}

function RAIL::ZnajdzStacjeProducentaSmartRail(producer, cargo, size)
{
local list=AITileList_IndustryProducing(producer, 3);
return this.ZnajdzStacjeSmartRail(list, size);
}

function RAIL::ZnajdzStacjeSmartRail(list, length)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(RAIL.IsGreatPlaceForRailStationSmartRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(RAIL.IsGreatPlaceForRailStationSmartRail(station, StationDirection.x_is_constant__horizontal, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.x_is_constant__horizontal;
		return returnik;
		}
	}
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(RAIL.IsOKPlaceForRailStationSmartRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(RAIL.IsOKPlaceForRailStationSmartRail(station, StationDirection.x_is_constant__horizontal, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.x_is_constant__horizontal;
		return returnik;
		}
	}
local returnik = Station();
returnik.location = null;
return returnik;
}

function RAIL::IsGreatPlaceForRailStationSmartRail(station_tile, direction, length)
{
local test = AITestMode();
/* Test Mode */
if(direction == StationDirection.y_is_constant__vertical)
   {
   local tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
   local tile_b = station_tile + AIMap.GetTileIndex(length, 0);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   if(!(Utils_Tile.IsNearlyFlatTile(tile_a) && Utils_Tile.IsNearlyFlatTile(tile_b)))return false;
   
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW);
	}
else
   {
   local tile_a = station_tile + AIMap.GetTileIndex(0, -1);
   local tile_b = station_tile + AIMap.GetTileIndex(0, length);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   if(!(Utils_Tile.IsNearlyFlatTile(tile_a) && Utils_Tile.IsNearlyFlatTile(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW);
   }
}

function RAIL::IsOKPlaceForRailStationSmartRail(station_tile, direction, length)
{
local test = AITestMode();
/* Test Mode */
if(direction == StationDirection.y_is_constant__vertical)
   {
   local tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
   local tile_b = station_tile + AIMap.GetTileIndex(length, 0);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW);
	}
else
   {
   local tile_a = station_tile + AIMap.GetTileIndex(0, -1);
   local tile_b = station_tile + AIMap.GetTileIndex(0, length);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW);
   }
}
   
 function RAIL::distanceBetweenIndustriesValuatorSmartRail(distance)
{
if(distance>GetMaxDistanceSmartRail())return 0;
if(distance<GetMinDistanceSmartRail()) return 0;

if(desperacja>5)
   {
   if(distance>100+desperacja*60)return 1;
   return 4;
   }

if(distance>200+desperacja*50)return 1;
if(distance>185) return 2;
if(distance>170) return 3;
if(distance>155) return 4;
if(distance>120) return 3;
if(distance>80) return 2;
if(distance>40) return 1;
return 0;
}

function RAIL::GetMinDistanceSmartRail()
{
return 10;
}

function RAIL::GetMaxDistanceSmartRail()
{
if(desperacja>5) return 100+desperacja*75;
return 250+desperacja*50;
}

function RAIL::TrainOrders(engineId)
{
if(trasa.type==1) //1 raw
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")=="0") AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	else AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED);
	}
else if(trasa.type==0) //0 proceed trasa.cargo
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")=="0") AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	else AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED);
	}
else if(trasa.type == 2) //2 passenger
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.end_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")=="0") AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	else AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_SERVICE_IF_NEEDED);
   }
else
   {
   Error("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
   local zero=0/0;
   }
}
  
function RAIL::BuildTrain(trasa) //from denver & RioGrande
{
local cargoIndex = trasa.cargo;
   local bestWagon = trasa.engine[1];
   local bestEngine = trasa.engine[0];
   
   local engineId = AIVehicle.BuildVehicle(trasa.depot_tile, bestEngine);
   local err = AIError.GetLastErrorString();
   local name = AIEngine.GetName(bestEngine);

   if(AIVehicle.IsValidVehicle(engineId) == false) 
   {

    AILog.Warning("Failed to build engine '" + name +"':" + err);
    return null;
   }
   
	AIVehicle.RefitVehicle(engineId, trasa.cargo);
   
   for(local i = 0; true; i++)
   {
	if(AIVehicle.GetLength(engineId)>trasa.station_size*16)
	   {
	   AIVehicle.SellWagon(engineId, 1);
	   break;
	   }
    local newWagon = AIVehicle.BuildVehicle(trasa.depot_tile, bestWagon);
        
    AIVehicle.RefitVehicle(newWagon, cargoIndex);
    local result = AIVehicle.MoveWagon(newWagon, newWagon, engineId, engineId);
              
    if(result == false)
    {
      //AILog.Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
      result = AIVehicle.MoveWagon(newWagon, 0, engineId, 0);
      if(result == false)
      {
        //AILog.Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
        result = AIVehicle.MoveWagon(0, newWagon, 0, engineId);
        if(result == false)
        {                  
          if(i==0)
          {
            AILog.Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());         
            return null;
          }
        }
      }
    }
   }
   AIVehicle.StartStopVehicle(engineId);
   return engineId;
}

function RAIL::SignalPath(path) //admiral
{
	local prev = null;
	local prevprev = null;
	local tiles_skipped = 39;
	local lastbuild_tile = null;
	local lastbuild_front_tile = null;
	while (path != null) {
		if (prevprev != null) {
			if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
				tiles_skipped += 10 * AIMap.DistanceManhattan(prev, path.GetTile());
			} else {
				if (path.GetTile() - prev != prev - prevprev) {
					tiles_skipped += 7;
				} else {
					tiles_skipped += 10;
				}
				if (AIRail.GetSignalType(prev, path.GetTile()) != AIRail.SIGNALTYPE_NONE) tiles_skipped = 0;
				if (tiles_skipped > 49 && path.GetParent() != null) {
					if (AIRail.BuildSignal(prev, path.GetTile(), AIRail.SIGNALTYPE_PBS_ONEWAY)) {
						tiles_skipped = 0;
						lastbuild_tile = prev;
						lastbuild_front_tile = path.GetTile();
					}
				}
			}
		}
		prevprev = prev;
		prev = path.GetTile();
		path = path.GetParent();
	}
	/* Although this provides better signalling (trains cannot get stuck half in the station),
	 * it is also the cause of using the same track of rails both ways, possible causing deadlocks.
	if (tiles_skipped < 50 && lastbuild_tile != null) {
		AIRail.RemoveSignal(lastbuild_tile, lastbuild_front_tile);
	}*/
}
