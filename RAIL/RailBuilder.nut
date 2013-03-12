class RailBuilder extends Builder
{
trasa = Route();
path = null; //TODO move it to RailStupid
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
if(AIBase.RandRange(10)==0)this.TrainReplace();
local new_trains = this.Uzupelnij();
if(new_trains!=0) Info(new_trains + " new train(s)");
}

function RailBuilder::Uzupelnij()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); !cargo_list.IsEnd(); cargo = cargo_list.Next()) //from Chopper
   {
   local station_list=AIStationList(AIStation.STATION_TRAIN);
   for (local aktualna = station_list.Begin(); !station_list.IsEnd(); aktualna = station_list.Next()) //from Chopper
	  {
	  if(NajmlodszyPojazd(aktualna)>20) //nie dodawaæ masowo
	  if(IsItNeededToImproveThatNoRawStation(aktualna, cargo))
	  {
	     local vehicle_list=AIVehicleList_Station(aktualna);
		 if(vehicle_list.Count()<2)continue; //TODO replace by data stored in station name
		 if(vehicle_list.Count()>9)continue; //TODO replace by data stored in station name
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
Error("function RailBuilder::TrainReplace()");
local station_list = AIStationList(AIStation.STATION_TRAIN);
local i=0;
for (local aktualna = station_list.Begin(); !station_list.IsEnd(); aktualna = station_list.Next()) //from Chopper
	{
	i++;
	Error(i + " of " + station_list.Count() + " stations [ " + AIStation.GetName(aktualna) + " ] ");
	
	local vehicle_list=AIVehicleList_Station(aktualna);
	if(vehicle_list.Count()==0)continue;
	local j=0;
	for (local vehicle = vehicle_list.Begin(); !vehicle_list.IsEnd(); vehicle = vehicle_list.Next()) //from Chopper
	{
	j++;
	Error(j + " of " + vehicle_list.Count() + " trains [ " + AIVehicle.GetName(vehicle) + " ] ");

	local cargo_list = AICargoList();
	local max = 0;
	local max_cargo;
	for (local cargo = cargo_list.Begin(); !cargo_list.IsEnd(); cargo = cargo_list.Next()) 
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
				  Error("this.BuildTrain(wrzut) 1");
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

function RailBuilder::BuildTrain(trasa, string) //from denver & RioGrande
{
local costs = AIAccounting();
costs.ResetCosts ();

local cargoIndex = trasa.cargo;
local bestWagon = trasa.engine[1];
local bestEngine = trasa.engine[0];
   
   local max_number_of_wagons = 1000;
   
   local engineId = AIVehicle.BuildVehicle(trasa.depot_tile, bestEngine);
   if(AIVehicle.IsValidVehicle(engineId) == false) 
   {
    AILog.Warning("Failed to build engine '" + AIEngine.GetName(bestEngine) +"':" + AIError.GetLastErrorString());
    return null;
   }
   AIVehicle.RefitVehicle(engineId, trasa.cargo);
   
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
			capacity_of_engine = AIVehicle.GetCapacity(engineId, trasa.cargo);
			weight_of_engine = AIEngine.GetWeight(bestEngine) + (capacity_of_engine * AIGameSettings.GetValue("vehicle.freight_trains"));		
			}
		if(i==1)
			{
			weight_of_wagon = AIEngine.GetWeight(bestWagon);
			weight_of_wagon += (AIVehicle.GetCapacity(engineId, trasa.cargo) - capacity_of_engine) * AIGameSettings.GetValue("vehicle.freight_trains");		
			max_number_of_wagons = (maximal_weight-weight_of_engine)/weight_of_wagon;
			}
		}

	if(AIVehicle.GetLength(engineId)>trasa.station_size*16)
	   {
	   if(!AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1))
		{
		Error(AIError.GetLastErrorString());
		assert(false);
		}
	   break;
	   }	
	local newWagon = AIVehicle.BuildVehicle(trasa.depot_tile, bestWagon);        
	AIVehicle.RefitVehicle(newWagon, cargoIndex);
    if(!AIVehicle.MoveWagon(newWagon, 0, engineId, 0))
    {
    AILog.Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
    if(i==0)
      {
      AILog.Error("Couldn't join any wagon to train: " + AIError.GetLastErrorString());   
      return null;
      }
    }
   }
   
   local mnoznik = GetAvailableMoney()/costs.GetCosts();
   
   mnoznik = min(mnoznik, trasa.station_size*16/AIVehicle.GetLength(engineId));
   Error("mnoznik: " + mnoznik);
   mnoznik--;
   
   for(local x=0; x<mnoznik; x++)
   {
   	local newengineId = AIVehicle.BuildVehicle(trasa.depot_tile, bestEngine);
	AIVehicle.RefitVehicle(newengineId, trasa.cargo);
    AIVehicle.MoveWagon(newengineId, 0, engineId, 0);

   	for(local i = 0; i<max_number_of_wagons; i++)
	{
	if(AIVehicle.GetLength(engineId)>trasa.station_size*16)
	   {
	   AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1);
	   break;
	   }
	
	local newWagon = AIVehicle.BuildVehicle(trasa.depot_tile, bestWagon);        
	AIVehicle.RefitVehicle(newWagon, cargoIndex);
    if(!AIVehicle.MoveWagon(newWagon, 0, engineId, AIVehicle.GetNumWagons(engineId)-1))
    {
    AILog.Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
    }
   }
   }
   
   Error("Multipling completed!");
   SetNameOfVehicle(engineId, string);
   Error("SetNameOfVehicle executed!");
   
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
				//AISign.BuildSign(path.GetTile(), ""+tiles_skipped)
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
	AIOrder.AppendOrder (engineId, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	}
else if(trasa.type==0) //0 proceed trasa.cargo
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.end_station, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	}
else if(trasa.type == 2) //2 passenger
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.end_station, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.depot_tile,  AIOrder.AIOF_NON_STOP_INTERMEDIATE );
   }
else
   {
   Error("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
   local zero=0/0;
   }
}

function RailBuilder::SetRailType(skip) //modified //from DenverAndRioGrande
{
  local types = AIList();
  types.AddList(AIRailTypeList());
  if(types.Count() == 0)
  {
  Error("No this types!");
    return false;
  }
	
  types.Valuate(AIRail.IsRailTypeAvailable);
  types.KeepValue(1);
  if(types.Count() == 0)
  {
  Error("No available this types!");
  return false;
  }
  
//  types.Valuate(AIRail.GetMaxSpeed);  //TODO what with nutracks
//  types.RemoveValue(0);
//  if(types.Count() == 0)
//  {
//  Error("No usable this types!");
//  return false;
//  }

  
for (local rail_type = types.Begin(); !types.IsEnd(); rail_type = types.Next())
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
   //Warning("Return OK: " + trasa.engine);
   //Info("engine:" + trasa.engine[0] + "wagon:" + trasa.engine[1] )
   //Info("engine:" + AIEngine.GetName(trasa.engine[0]) + "wagon:" + AIEngine.GetName(trasa.engine[1]) )
   return trasa;
   }
}

trasa.engine = null;
//Warning("Return bad: " + trasa.engine);
//   Info("engine:" + engine + "wagon:" + wagon )
//   Info("engine:" + AIEngine.GetName(engine) + "wagon:" + AIEngine.GetName(wagon) )
return trasa;
}

function RailBuilder::FindWagons(cargoIndex)//from DenverAndRioGrande
{
    //AILog.Info("Looking for " + AICargo.GetCargoLabel(cargoIndex) + " wagons.");
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
    if(wagons.Count() == 0)
    {
      AILog.Warning("Warning, no wagons can pull or be refitted to this cargo on the current track.");
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
   //AILog.Info("No engine has top speed of wagon. Checking Fastest.");
   //AILog.Info("The fastest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
   local cash = GetAvailableMoney();
   if(cash > AIEngine.GetPrice(engines.Begin()) * 2 || AIVehicleList().Count() > 10)//if there are 10 trains, just return the best one and let it fail.
   {
    return engines.Begin();
   }
   else
   {
    //AILog.Info("The company is poor. Picking a slower, cheaper engine.");
    engines.Valuate(AIEngine.GetPrice);
    engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
    //AILog.Info("The Cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'  is '" + AIEngine.GetName(engines.Begin()) +"'" );
    return engines.Begin();
   }
  }
  
  engines.RemoveBelowValue(speed);
  engines.Valuate(AIEngine.GetPrice);
  engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
  
  //AILog.Info("The cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
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