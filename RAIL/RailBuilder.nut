class RailBuilder extends Builder
{
trasa = Route();
path = null;
ignore = null;

//[start_tile, tile_before_start]
start = array(2);
end = array(2);
};

require("RailBuilderPathfinder.nut")
require("RailBuilderDepotConnection.nut")

class tiles
{
a = null;
b = null;
}

function RailBuilder::Konserwuj() 
{
if(AIBase.RandRange(9)==1)this.TrainReplace();
local new_trains = this.Uzupelnij();
if(new_trains!=0) Info(new_trains + " new train(s)");
}

function RailBuilder::Uzupelnij()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
   {
   local station_list=AIStationList(AIStation.STATION_TRAIN);
   for (local aktualna = station_list.Begin(); station_list.HasNext(); aktualna = station_list.Next()) //from Chopper
	  {
	  if(NajmlodszyPojazd(aktualna)>20) //nie dodawaæ masowo
	  if(IsItNeededToImproveThatNoRawStation(aktualna, cargo))
	  {
	  local how_many = this.CountVehicles(aktualna);
	 if(how_many<2)continue; //TODO replace by data stored in station name
	 if(how_many>9)continue; //TODO replace by data stored in station name
		 vehicle_list.Valuate(AIBase.RandItem);
		 vehicle_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
		 local original=vehicle_list.Begin();
		 
		 if(AIVehicle.GetProfitLastYear(original)<0)continue;

		 local end = AIOrder.GetOrderDestination(original, AIOrder.GetOrderCount(original)-2);

	     //if(AITile.GetCargoAcceptance (end, cargo, 1, 7, 5)==0) //TODO: improve it to have real data
		 //   {
		 //	if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(end, "ACCEPTATION STOPPED");
		 //	continue;
		 //	}
		if(this.copyVehicle(original, cargo )) ile++;
		}
	  }
   }
return ile;
}

function RailBuilder::copyVehicle(main_vehicle_id, cargo)
{
if(AIVehicle.IsValidVehicle(main_vehicle_id)==false)return false;
local depot_tile = GetDepot(main_vehicle_id);

//local maksymalnie=11; //TODO - load data from station name
//local ile = list.Count();

//if(ile<maksymalnie)
   {
   local vehicle_id = AIVehicle.CloneVehicle(depot_tile, main_vehicle_id, true);
   if(AIVehicle.IsValidVehicle(vehicle_id))
      {
 	  if(AIVehicle.StartStopVehicle (vehicle_id))return true;
	  //else sell TODO 
	  }
   }   
return false;
}

function RailBuilder::TrainReplace()
{
Info("function RailBuilder::TrainReplace()");
local station_list = AIStationList(AIStation.STATION_TRAIN);
local i=0;
for (local aktualna = station_list.Begin(); station_list.HasNext(); aktualna = station_list.Next()) //from Chopper
	{
	i++;
	//Error(i + " of " + station_list.Count() + " stations [ " + AIStation.GetName(aktualna) + " ] ");
	
	local vehicle_list=AIVehicleList_Station(aktualna);
	if(vehicle_list.Count()==0)continue;
	local j=0;
	for (local vehicle = vehicle_list.Begin(); !vehicle_list.HasNext(); vehicle = vehicle_list.Next()) //from Chopper
	{
	j++;
	//Error(j + " of " + vehicle_list.Count() + " trains [ " + AIVehicle.GetName(vehicle) + " ] ");

	local cargo_list = AICargoList();
	local max = 0;
	local max_cargo;
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) 
	   {
	   if(AIVehicle.GetCapacity(vehicle, cargo)>max) 
	      {
		  max = AIVehicle.GetCapacity(vehicle, cargo);
		  max_cargo = cargo;
		  }
	   }
		  AIRail.SetCurrentRailType(AIRail.GetRailType(GetLoadStation(vehicle)));
		  local wrzut = Route();
		  wrzut.cargo = max_cargo;
		  wrzut.station_size = this.GetStationSize(GetLoadStation(vehicle));
		  wrzut.depot_tile = GetDepot(vehicle);
		  wrzut = RailBuilder.FindTrain(wrzut);
		  local engine = wrzut.engine[0];
		  local wagon = wrzut.engine[1];

			
		  local new_speed = this.GetMaxSpeedOfTrain(engine, wagon);

		  local old_engine = AIVehicle.GetEngineType(vehicle);
		  local old_wagon = AIVehicle.GetWagonEngineType(vehicle, 0);
	
		  local old_speed = this.GetMaxSpeedOfTrain(old_engine, old_wagon);

		  if(new_speed>old_speed)
		      {
			  if(AIAI.CzyNaSprzedaz(vehicle)==false)
			      {
				  local train = this.BuildTrain(wrzut, "replacing");
				  if(train != null)
				    {
					if(AIOrder.ShareOrders(train, vehicle)) AIAI.sellVehicle(vehicle, "replaced");
					}
				  }
			  }	
	}
	}
}

function RailBuilder::GetStationSize(station_tile)
{
if(AIRail.GetRailStationDirection(station_tile)==AIRail.RAILTRACK_NE_SW) //x_is_constant__horizontal
   {
   for(local i = 0; true; i++)
      {
	  if(AIStation.GetStationID(station_tile + AIMap.GetTileIndex(i, 0))!=AIStation.GetStationID(station_tile))return i;
	  }
   }
else
   {
   for(local i = 0; true; i++)
      {
	  if(AIStation.GetStationID(station_tile + AIMap.GetTileIndex(0, i))!=AIStation.GetStationID(station_tile))return i;
	  }
   }
}

function RailBuilder::GetMaxSpeedOfTrain(engine, wagon)
{
if(engine == null || wagon == null)return 0;
  local speed_wagon = AIEngine.GetMaxSpeed(wagon);
  if(speed_wagon == 0) {speed_wagon = 2500;}
  local speed_engine = AIEngine.GetMaxSpeed(engine);
  if(speed_wagon < speed_engine) return speed_wagon;
  return speed_engine;
}

function RailBuilder::RailwayLinkConstruction(path)
{
AIRail.SetCurrentRailType(trasa.track_type); 
return DumbBuilder(path);
}

function RailBuilder::DumbRemover(path, goal)
{
local prev = null;
local prevprev = null;
while (path != null) {
  if (prevprev != null) {
  //AISign.BuildSign(prev, "prev");
  if(prev==goal)return true;
  
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        AITile.DemolishTile(prev);
      } else {
        AITile.DemolishTile(prev);
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      AIRail.RemoveRail(prevprev, prev, path.GetTile());
    }
  }
  if (path != null) {
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}
return true;
}

function RailBuilder::DumbBuilder(path)
{
local copy = path;
local prev = null;
local prevprev = null;
while (path != null) {
  if (prevprev != null) {
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        if(!AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev))
			     {
		 DumbRemover(copy, prev);
		 return false;
		 }

      } else {
        local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
        bridge_list.Valuate(AIBridge.GetMaxSpeed);
        bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
        if(!AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile()))
	     {
		 DumbRemover(copy, prev);
		 return false;
		 }
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      if(!AIRail.BuildRail(prevprev, prev, path.GetTile())) 
	     {
		 DumbRemover(copy, prev);
		 return false;
		 }
    }
  }
  if (path != null) {
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}
return true;
}

function RailBuilder::GetCostOfRoute(path)
{
local costs = AIAccounting();
costs.ResetCosts ();

/* Exec Mode */
local test = AITestMode();
/* Test Mode */

if(this.DumbBuilder(path))
   {
   return costs.GetCosts();
   }
else return null;
}

class RPathItem
{
	_tile = null;
	_parent = null;

	constructor(tile)
	{
		this._tile = tile;
	}

	function GetTile()
	{
		return this._tile;
	}

	function GetParent()
	{
		return this._parent;
	}
};

function RailBuilder::WeightOfEngine(engine, cargo)
{
local weight = AIEngine.GetWeight(engine);
local capacity = max(AIEngine.GetCapacity(engine), 0);
if(AICargo.IsFreight(cargo)) weight += capacity * AIGameSettings.GetValue("vehicle.freight_trains");
return weight;
}

function RailBuilder::BuildEngine(depot_tile, bestEngine)
{
local engineId = AIVehicle.BuildVehicle(depot_tile, bestEngine);
if(AIVehicle.IsValidVehicle(engineId) == false) 
   {
   Info("Failed to build engine '" + AIEngine.GetName(bestEngine) +"':" + AIError.GetLastErrorString());
   return null;
   }
AIVehicle.RefitVehicle(engineId, trasa.cargo);
return engineId;
}

function RailBuilder::BuildWagons(engineId, bestEngine, bestWagon, depotTile, stationSize, cargoIndex)
{
local max_number_of_wagons = 1000;
local maximal_weight = AIEngine.GetMaxTractiveEffort(bestEngine) * 3;
local weight_of_engine;
local capacity_of_engine;
local weight_of_wagon;
	
for(local i = 0; i<max_number_of_wagons; i++)
	{
	if(AIGameSettings.GetValue("vehicle.train_acceleration_model")==1)
		{
		if(i==0)
			{
			capacity_of_engine = AIVehicle.GetCapacity(engineId, cargoIndex);
			weight_of_engine = AIEngine.GetWeight(bestEngine) + (capacity_of_engine * AIGameSettings.GetValue("vehicle.freight_trains"));		
			}
		if(i==1)
			{
			weight_of_wagon = AIEngine.GetWeight(bestWagon);
			weight_of_wagon += (AIVehicle.GetCapacity(engineId, cargoIndex) - capacity_of_engine) * AIGameSettings.GetValue("vehicle.freight_trains");		
			max_number_of_wagons = (maximal_weight-weight_of_engine)/weight_of_wagon;
			}
		}
	local newWagon = AIVehicle.BuildVehicle(depotTile, bestWagon);        
	AIVehicle.RefitVehicle(newWagon, cargoIndex);
    if(!AIVehicle.MoveWagon(newWagon, 0, engineId, 0))
		{
		Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
		if(i==0)
			{
			Error("Couldn't join any wagon to train: " + AIError.GetLastErrorString());   
			return null;
			}
		}
	if(AIVehicle.GetLength(engineId)>stationSize*16)
	   {
	   if(!AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1))
			{
			Error(AIError.GetLastErrorString());
			return null;
			}
	   break;
	   }	
	//Info("max_number_of_wagons: " + max_number_of_wagons + ", AIVehicle.GetLength(engineId): " + AIVehicle.GetLength(engineId));
	}
return max_number_of_wagons;
}

function RailBuilder::BuildTrain(trasa, string) //from denver & RioGrande
{
local costs = AIAccounting();
costs.ResetCosts ();

local bestEngine = trasa.engine[0];
local bestWagon = trasa.engine[1];
local depotTile = trasa.depot_tile;
local stationSize = trasa.station_size;
local cargoIndex = trasa.cargo;
   
local engineId = RailBuilder.BuildEngine(depotTile, bestEngine);
if(engineId==null)return null;

local max_number_of_wagons = RailBuilder.BuildWagons(engineId, bestEngine, bestWagon, depotTile, stationSize, cargoIndex);
if(max_number_of_wagons==null)return null;

//multiplier: for weak locos it may be possible to merge multiple trains ito one (2*loco + 10*wagon, instead of loco+5 wagons)
//multiplier = how many trains are merged into one
local multiplier = GetAvailableMoney()/costs.GetCosts();
   
multiplier = min(multiplier, trasa.station_size*16/AIVehicle.GetLength(engineId));
multiplier--; //one part of train is already constructed
   
for(local x=0; x<multiplier; x++){
   	local newengineId = AIVehicle.BuildVehicle(trasa.depot_tile, bestEngine);
	AIVehicle.RefitVehicle(newengineId, trasa.cargo);
    AIVehicle.MoveWagon(newengineId, 0, engineId, 0);

   	for(local i = 0; i<max_number_of_wagons; i++){
		if(AIVehicle.GetLength(engineId)>trasa.station_size*16){
			AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1);
			break;
			}
		local newWagon = AIVehicle.BuildVehicle(trasa.depot_tile, bestWagon);        
		AIVehicle.RefitVehicle(newWagon, cargoIndex);
		if(!AIVehicle.MoveWagon(newWagon, 0, engineId, AIVehicle.GetNumWagons(engineId)-1)){
			Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
			}
		}
	}
   
SetNameOfVehicle(engineId, string);
AIVehicle.StartStopVehicle(engineId);
return engineId;
}

function RailBuilder::SignalPath(path) //admiral
{
	local prev = null;
	local prevprev = null;
	local tiles_skipped = 50;
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
				//AISign.BuildSign(path.GetTile(), "tiles skipped: "+tiles_skipped)
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

function RailBuilder::TrainOrders(engineId)
{
if(trasa.type==1) //1 raw
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_SERVICE_IF_NEEDED); //trains are not replaced by autoreplace!
	}
else if(trasa.type==0) //0 proceed trasa.cargo
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_SERVICE_IF_NEEDED ); //trains are not replaced by autoreplace!
	}
else if(trasa.type == 2) //2 passenger
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_SERVICE_IF_NEEDED ); //trains are not replaced by autoreplace!
   }
else
   {
   Error("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
   local zero=0/0;
   }
}

function RailBuilder::SetRailType(skip) //modified //from DenverAndRioGrande
{
local types = AIRailTypeList();
if(types.Count() == 0)
	{
	Error("No rail types!");
	return false;
	}
	
  types.Valuate(AIRail.IsRailTypeAvailable);
  types.KeepValue(1);
  if(types.Count() == 0)
  {
  Error("No available rail types!");
  return false;
  }
  
//  types.Valuate(AIRail.GetMaxSpeed);  //TODO what with nutracks
//  types.RemoveValue(0);
//  if(types.Count() == 0)
//  {
//  Error("No usable this types!");
//  return false;
//  }

  
for (local rail_type = types.Begin(); types.HasNext(); rail_type = types.Next())
   {
   if(skip==0)
      {
		AIRail.SetCurrentRailType(rail_type);
		//Info("this type selected.");
		return true;
	  }
   skip--;
   }
Error("Too many RailTypes failed");
return false;
}

function RailBuilder::FindTrain(trasa)//from DenverAndRioGrande
{
local wagon = RailBuilder.FindBestWagon(trasa.cargo)
local engine = RailBuilder.FindBestEngine(wagon, trasa.station_size, trasa.cargo);
trasa.engine = array(2);
trasa.engine[0] = engine;
trasa.engine[1] = wagon;
return trasa;
}

function RailBuilder::GetTrain(trasa)//from DenverAndRioGrande
{

for(local i = 0; RailBuilder.SetRailType(i); i++)
{
trasa = RailBuilder.FindTrain(trasa);
if(AIEngine.IsBuildable(trasa.engine[0]) && AIEngine.IsBuildable(trasa.engine[1])) 
   {
   //Info("Return OK: " + trasa.engine);
   //Info("engine:" + trasa.engine[0] + "wagon:" + trasa.engine[1] )
   //Info("engine:" + AIEngine.GetName(trasa.engine[0]) + "wagon:" + AIEngine.GetName(trasa.engine[1]) )
   trasa.track_type = AIRail.GetCurrentRailType();
   return trasa;
   }
}

trasa.engine = null;
//Info("Return bad: " + trasa.engine);
//   Info("engine:" + engine + "wagon:" + wagon )
//   Info("engine:" + AIEngine.GetName(engine) + "wagon:" + AIEngine.GetName(wagon) )
return trasa;
}

function RailBuilder::FindWagons(cargoIndex)//from DenverAndRioGrande
{
    //Info("Looking for " + AICargo.GetCargoLabel(cargoIndex) + " wagons.");
    local wagons = AIEngineList(AIVehicle.VT_RAIL);
    wagons.Valuate(AIEngine.IsWagon);
    wagons.RemoveValue(0);
    //print(wagons.Count() + " wagons." );
    wagons.Valuate(AIEngine.IsBuildable);
    wagons.RemoveValue(0);
    //print(wagons.Count() + " Valid and buildable." );
    wagons.Valuate(AIEngine.CanRefitCargo, cargoIndex);
    wagons.RemoveValue(0);
    //print(wagons.Count() + " Can refit to cargo." );    
    wagons.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
    wagons.RemoveValue(0);
    //print(wagons.Count() + " Can run on this." ); 
    //wagons.AddList(nonRefitWagons);
    if(wagons.Count() == 0){
    Info("No wagons can pull or be refitted to this cargo on the current track.");
    }
    return wagons;
}

function RailBuilder::WagonValuator(engineId)//from DenverAndRioGrande
{
  return  AIEngine.GetCapacity(engineId) * AIEngine.GetMaxSpeed(engineId);
}

function RailBuilder::FindBestWagon(cargoIndex)//from DenverAndRioGrande
{   
    local wagons = RailBuilder.FindWagons(cargoIndex);
    wagons.Valuate(RailBuilder.WagonValuator);
    return wagons.Begin();
}

function RailBuilder::FindBestEngine(wagonId, trainsize, cargoId)//from DenverAndRioGrande
{
    
  local minHP = 175 * trainsize;
  
  local speed = AIEngine.GetMaxSpeed(wagonId);
  if(speed == 0) {speed = 2500;}
  local engines = AIEngineList(AIVehicle.VT_RAIL);
  engines.Valuate(AIEngine.IsWagon);
  engines.RemoveValue(1);
  
  engines.Valuate(AIEngine.IsBuildable);
  engines.RemoveValue(0);
  engines.Valuate(AIEngine.CanPullCargo, cargoId);
  engines.RemoveValue(0);
  engines.Valuate(AIEngine.HasPowerOnRail, AIRail.GetCurrentRailType());
  engines.RemoveValue(0);
  //engines.Valuate(AIEngine.TrainCanRunOnRail, AIRail.GetCurrentRailType()); TODO activate it
  //engines.RemoveValue(0);
  
  engines.Valuate(AIEngine.GetPower);
  
  engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
  if(engines.GetValue(engines.Begin()) < minHP ) //no engine can pull the wagon at it's top speed.
  {
   //print("No engine has enough horsepower to pull all the wagons well.");
  }
  else
  {
    engines.RemoveBelowValue(minHP);
  }
  
  
  engines.Valuate(AIEngine.GetMaxSpeed);
  engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
  
  if(engines.GetValue(engines.Begin()) < speed ) //no engine can pull the wagon at it's top speed.
  {
   //Info("No engine has top speed of wagon. Checking Fastest.");
   //Info("The fastest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
   local cash = GetAvailableMoney();
   if(cash > AIEngine.GetPrice(engines.Begin()) * 2 || AIVehicleList().Count() > 10)//if there are 10 trains, just return the best one and let it fail.
   {
    return engines.Begin();
   }
   else
   {
    //Info("The company is poor. Picking a slower, cheaper engine.");
    engines.Valuate(AIEngine.GetPrice);
    engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
    //Info("The Cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'  is '" + AIEngine.GetName(engines.Begin()) +"'" );
    return engines.Begin();
   }
  }
  
  engines.RemoveBelowValue(speed);
  engines.Valuate(AIEngine.GetPrice);
  engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
  
  //Info("The cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
  return engines.Begin();
}

function RailBuilder::ValuateProducer(ID, cargo)
{
if(AIIndustry.GetLastMonthProduction(ID, cargo)<50-4*desperacja)return 0; //protection from tiny industries servised by giant trains

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
		}
//Info(AIIndustry.GetName(ID) + " is " + base + " point producer of " + AICargo.GetCargoLabel(cargo));
return base;
}

function RailBuilder::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
//Info("   " + AIIndustry.GetName(ID) + " is " + score + " point consumer of " + AICargo.GetCargoLabel(cargo));
return score;
}

function RailBuilder::GetMinimalStationSize()
{
return max(1, min(4 - (desperacja/2), AIGameSettings.GetValue("station.station_spread")));
}

function RailBuilder::StationPreparation() 
{
ignore = [];
if(trasa.first_station.direction != StationDirection.x_is_constant__horizontal)
   {
   start[0] = [trasa.first_station.location+AIMap.GetTileIndex(-1, 0), trasa.first_station.location] 
   start[1] = [trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size, 0), trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size -1, 0)] 
   for(local tile = trasa.first_station.location; tile!=trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size, 0) ;tile+=AIMap.GetTileIndex(1, 0))
		{
		ignore.append(tile);
		}
   }
else
   {
   start[0] = [trasa.first_station.location + AIMap.GetTileIndex(0, -1), trasa.first_station.location] //TODO drugi koniedc
   start[1] = [trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
   for(local tile = trasa.first_station.location; tile!=trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size); tile+=AIMap.GetTileIndex(0, 1))
		{
		ignore.append(tile);
		}
   }

if(trasa.second_station.direction != StationDirection.x_is_constant__horizontal)
   {
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(-1, 0), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size, 0), trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size -1, 0)] 
   for(local tile = trasa.second_station.location; tile!=trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size, 0) ;tile+=AIMap.GetTileIndex(1, 0))
		{
		ignore.append(tile);
		}
   }
else
   {
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(0, -1), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
   for(local tile = trasa.second_station.location; tile!=trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size); tile+=AIMap.GetTileIndex(0, 1))
		{
		ignore.append(tile);
		}
   }
}

function RailBuilder::StationConstruction() 
{
//BuildNewGRFRailStation (TileIndex tile, RailTrack direction, uint num_platforms, uint platform_length, StationID station_id, 
//						CargoID cargo_id, IndustryType source_industry, IndustryType goal_industry, int distance, bool source_station)
AIRail.SetCurrentRailType(trasa.track_type); 
local source_industry;
local goal_industry;
if(trasa.first_station.is_city) source_industry = 0xFF;
else source_industry = AIIndustry.GetIndustryType(trasa.start);

if(trasa.second_station.is_city) goal_industry = 0xFF;
else goal_industry = AIIndustry.GetIndustryType(trasa.end);

local distance = 50;

if(trasa.first_station.direction != StationDirection.x_is_constant__horizontal)
   {
   //BuildNewGRFRailStation (TileIndex tile, RailTrack direction, uint num_platforms, uint platform_length, StationID station_id, CargoID cargo_id, IndustryType source_industry, IndustryType goal_industry, int distance, bool source_station)
   if(!AIRail.BuildNewGRFRailStation(trasa.first_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, true)) //TODO to 1, 1 miasto (patrz tt moj temat)
   if(!AIRail.BuildRailStation(trasa.first_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW))
   {
	  AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString()+" Smart Sa");
	  if(!trasa.first_station.is_city) trasa.zakazane.AddItem(trasa.start, 0);
	  return false;
	  }
   }
else
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.first_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, true)) 
   if(!AIRail.BuildRailStation(trasa.first_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString()+" Smart Sb");
	  if(!trasa.first_station.is_city) trasa.zakazane.AddItem(trasa.start, 0);
	  return false;
	  }
   }

if(trasa.second_station.direction != StationDirection.x_is_constant__horizontal)
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.second_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, false))
   if(!AIRail.BuildRailStation(trasa.second_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+" Smart Ea");
	  if(!trasa.second_station.is_city) trasa.zakazane.AddItem(trasa.end, 0);
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   }
else
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.second_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, false))
   if(!AIRail.BuildRailStation(trasa.second_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+" Smart Eb");
	  if(!trasa.second_station.is_city) trasa.zakazane.AddItem(trasa.end, 0); 
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   }

rodzic.SetStationName(trasa.first_station.location);
rodzic.SetStationName(trasa.second_station.location);
return true;
}

function RailBuilder::PathFinder(reverse, limit) 
{
/*
trasa
ignore is used
*/
local pathfinder = Rail();
pathfinder.estimate_multiplier = 3;
pathfinder.cost.bridge_per_tile = 500;
pathfinder.cost.tunnel_per_tile = 35;
pathfinder.cost.diagonal_tile = 35;
pathfinder.cost.coast = 0;
pathfinder.cost.max_bridge_length = 40;   // The maximum length of a bridge that will be build.
pathfinder.cost.max_tunnel_length = 40;   // The maximum length of a tunnel that will be build.

pathfinder.InitializePath(end, start, ignore);
if(reverse)pathfinder.InitializePath(start, end, ignore);

path = false;
local guardian=0;
while (path == false) {
  Info("   Pathfinding ("+guardian+" / " + limit + ") started");
  path = pathfinder.FindPath(2000);
  Info("   Pathfinding ("+guardian+" / " + limit + ") ended");
  rodzic.Konserwuj();
  AIController.Sleep(1);
  guardian++;
  if(guardian>limit )break;
}

if(path == false || path == null){
  Info("   Pathfinder failed to find route. ");
  return false;
  }
Info("   Pathfinder found sth.");
return true;
}