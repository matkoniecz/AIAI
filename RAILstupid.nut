function RAIL::StupidRailConnection()
{
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin());
for(local i=0; i<20; i++)
   {
   Warning("<==scanning=for=stupid=rail=route=");
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
	  if(this.ConstructionOfStupidRailRoute()) 
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

function RAIL::ConstructionOfStupidRailRoute()
{
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


if(!this.BuildTrain())
   {
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  RAIL.DumbRemover(path, null)
   return false;
   }
Info("   Route constructed!");
return true;
}
   
function RAIL::PrepareRoute()
{
this.Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));

local pathfinder = MyRailPF();
pathfinder.Fast();

//[start_tile, tile_before_start]
local start = array(2);
local end = array(2);

if(trasa.first_station.direction != StationDirection.x_is_constant__horizontal)
   {
   if(!AIRail.BuildRailStation(trasa.first_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW))
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
   if(!AIRail.BuildRailStation(trasa.first_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW)) 
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
   if(!AIRail.BuildRailStation(trasa.second_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW))
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
   if(!AIRail.BuildRailStation(trasa.second_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+"Eb");
	  trasa.zakazane.AddItem(trasa.end, 0); //TODO a miasta?
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(0, -1), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
   }
  
  
pathfinder.InitializePath(end, start);
path = false;
local guardian=0;
local limit = 3*((desperacja*3+20)*((AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile)/50) + 1)/2);
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
    if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<koszt+2000) 
	   {
	   Info("too expensivee, we have only " + AICompany.GetBankBalance(AICompany.COMPANY_SELF) + " And we need " + koszt);
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
	   return false;
	   }
	}
return true;
}


function RAIL::FindPair(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this); 
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, IndustryToIndustryTrainStationAllocator, GetNiceRandomTown, IndustryToCityTrainStationAllocator, DenverAndRioGrande.GetTrain);
}

function RAIL::ValuateProducer(ID, cargo)
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
		base+=base/2;
		}
//Info(AIIndustry.GetName(ID) + " is " + base + " point producer of " + AICargo.GetCargoLabel(cargo));
return base;
}

function RAIL::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
//Info("   " + AIIndustry.GetName(ID) + " is " + score + " point consumer of " + AICargo.GetCargoLabel(cargo));
return score;
}

function RAIL::GetNiceRandomTown(location)
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

function RAIL::IndustryToIndustryTrainStationAllocator(project)
{
project.station_size = 7;

local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;

project.first_station.location = null; 
for(; project.station_size>0; project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducenta(producer, cargo, project.station_size);
project.second_station = this.ZnajdzStacjeKonsumenta(consumer, cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.end_station = project.second_station.location;

return project;
}

function RAIL::IndustryToCityTrainStationAllocator(project)
{
project.station_size = 7;

project.first_station.location = null; 
for(; project.station_size>0; project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducenta(project.start, project.cargo, project.station_size);
project.second_station = this.ZnajdzStacjeMiejska(project.end, project.cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.end_station = project.second_station.location;
return project;
}

function RAIL::ZnajdzStacjeMiejska(town, cargo, size)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return this.ZnajdzStacje(list, size);
}

function RAIL::ZnajdzStacjeKonsumenta(consumer, cargo, size)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
return this.ZnajdzStacje(list, size);
}

function RAIL::ZnajdzStacjeProducenta(producer, cargo, size)
{
local list=AITileList_IndustryProducing(producer, 3);
return this.ZnajdzStacje(list, size);
}

function RAIL::ZnajdzStacje(list, length)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(RAIL.IsOKPlaceForRailStation(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(RAIL.IsOKPlaceForRailStation(station, StationDirection.x_is_constant__horizontal, length))
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

function RAIL::IsOKPlaceForRailStation(station_tile, direction, length)
{
local test = AITestMode();
/* Test Mode */
if(direction == StationDirection.y_is_constant__vertical)
   {
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW);
	}
else
   {
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW);
   }
}

function RAIL::distanceBetweenIndustriesValuator(distance)
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

function RAIL::GetMinDistance()
{
return 10;
}

function RAIL::GetMaxDistance()
{
if(desperacja>5) return desperacja*75;
return 150+desperacja*50;
}

function RAIL::BuildTrain() //from denver & RioGrande
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
    return false;
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
            return false;
          }
        }
      }
    }
	
   }
   
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
   
   
   local name = AIVehicle.GetName(engineId);
   local cargoId = AICargo.GetCargoLabel(cargoIndex);
   AIVehicle.SetName(engineId, name + " (" + Name + ") " + cargoId);
   
   AIVehicle.StartStopVehicle(engineId);
   return true;
}

