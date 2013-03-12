class SmartRailBuilder extends RailBuilder
{
};

function SmartRailBuilder::Possible()
{
if(!IsAllowedSmartCargoTrain())return false;
Info("$: " + this.cost + " / " + GetAvailableMoney());
return this.cost<GetAvailableMoney();
}

function SmartRailBuilder::Go()
{
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin());
for(local i=0; i<retry_limit; i++)
   {
   if(!Possible())return false;
   Important("Scanning for smart rail route");
   trasa = this.FindPairForSmartRailRoute(trasa);  
   if(!trasa.OK) 
      {
      Info("Nothing found!");
      cost = 0;
      return false;
      }

   Important("Scanning for smart rail route completed [ " + desperacja + " ] cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
   if(this.SmartRailRoute())return true;
   else trasa.zakazane.AddItem(trasa.start, 0);
   }
return false;
}

function SmartRailBuilder::SmartRailRoute()
{
Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));
this.StationPreparation();   

if(!this.PathFinder(false, this.GetPathfindingLimit()))return false;

local koszt = this.GetCostOfRoute(path); 
if(koszt==null){
  Info("   Pathfinder failed to find correct route.");
  return false;
  }

Info("Construction can start!")
koszt+=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);
cost=koszt;

if(GetAvailableMoney()<koszt+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	Error("WE NEED MORE CASH TO BUILD OUR PRECIOUS ROUTE!")
	local total_last_year_profit = TotalLastYearProfit();
	if(total_last_year_profit>koszt)
		{
		Error("But we can wait!");
		while(GetAvailableMoney()<koszt+2000){ //TODO: real station cost
			Info("too expensivee, we have only " + GetAvailableMoney() + " And we need " + koszt);
			rodzic.Konserwuj(); //TODO bez wydawania kasy
			AIController.Sleep(1000);
			}
		}
		else{
			Error("And we can not wait!");
			this.cost = koszt;
			return false;
		}
	}
else Info("We have enough money.")
ProvideMoney();
if(!this.StationConstruction()) return false;   
if(!this.RailwayLinkConstruction(path)){
	Info("   But stopped by error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	return false;	  
	}

trasa.depot_tile = this.BuildDepot(path, false);
if(trasa.depot_tile==null){
	Info("   Depot placement error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;	  
	}

local new_engine = this.BuildTrain(trasa, "smart uno");

if(new_engine == null){
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;
	}
this.TrainOrders(new_engine);
Info("   I stage completed");
RepayLoan();

local date=AIDate.GetCurrentDate ();
   
local old_path = path;

if(!this.PathFinder(true, this.GetPathfindingLimit()*4))return true; //TODO: passing lanes
ProvideMoney();
local date=AIDate.GetCurrentDate ();
cost = this.GetCostOfRoute(path); 
if(cost==null){
	Info("   Pathfinder failed to find correct route.");
	Info("Retry");
	if(!this.PathFinder(true, this.GetPathfindingLimit()*4))return true; //TODO: passing lanes
		ProvideMoney();
		local date=AIDate.GetCurrentDate ();
		cost = this.GetCostOfRoute(path); 
		if(cost==null){
		Info("   Pathfinder failed again to find correct route.");{
			//TODO passing lanes
			return true;
			}
		}
	}
if(GetAvailableMoney()<cost+2000)  //TODO replace 2000 with real station costs
    {
	rodzic.MoneyMenagement();
    while(GetAvailableMoney()<cost+2000) 
	   {
	   Info("too expensivee, we have only " + GetAvailableMoney() + " And we need " + cost);
	   rodzic.Konserwuj(); //TODO bez wydawania kasy
	   AIController.Sleep(1000);
	   }
	}

if(!this.RailwayLinkConstruction(path)){
   Info("   But stopped by error");
  //TODO passing lanes
   return true;	  
   }

this.SignalPath(path);
this.SignalPath(old_path);
koszt=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);

if(GetAvailableMoney() <koszt+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	rodzic.MoneyMenagement();
    while(GetAvailableMoney()<koszt+2000) 
	   {
	   Info("too expensivee, we have only " +GetAvailableMoney() + " And we need " + koszt);
	   rodzic.Konserwuj(); //TODO bez wydawania kasy
	   AIController.Sleep(1000);
	   }
	}

new_engine = this.BuildTrain(trasa, "smart duo");
if(new_engine != null)
   {
   this.TrainOrders(new_engine);
   AITown.PerformTownAction(trasa.first_station.location, AITown.TOWN_ACTION_BUILD_STATUE);
   }
return true;
}

function SmartRailBuilder::FindPairForSmartRailRoute(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this); 
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuatorSmartRail = this.distanceBetweenIndustriesValuatorSmartRail.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuatorSmartRail, IndustryToIndustryTrainSmartRailStationAllocator, GetNiceRandomTownSmartRail, IndustryToCityTrainSmartRailStationAllocator, RailBuilder.GetTrain);
}

function SmartRailBuilder::GetNiceRandomTownSmartRail(location)
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

function SmartRailBuilder::IndustryToIndustryTrainSmartRailStationAllocator(project)
{
project.station_size = 7;

local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;

project.first_station.location = null; 
for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaSmartRail(producer, cargo, project.station_size);
project.second_station = this.ZnajdzStacjeKonsumentaSmartRail(consumer, cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;

return project;
}

function SmartRailBuilder::IndustryToCityTrainSmartRailStationAllocator(project)
{
project.station_size = 7;

project.first_station.location = null; 
for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaSmartRail(project.start, project.cargo, project.station_size);
project.second_station = this.ZnajdzStacjeMiejskaSmartRail(project.end, project.cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;
return project;
}

function SmartRailBuilder::ZnajdzStacjeMiejskaSmartRail(town, cargo, size)
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

function SmartRailBuilder::ZnajdzStacjeKonsumentaSmartRail(consumer, cargo, size)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
list.Valuate(AIMap.DistanceSquare, trasa.end_tile); //pure eyecandy (station near industry)
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);
return this.ZnajdzStacjeSmartRail(list, size);
}

function SmartRailBuilder::ZnajdzStacjeProducentaSmartRail(producer, cargo, size)
{
local list=AITileList_IndustryProducing(producer, 3);
list.Valuate(AIMap.DistanceSquare, trasa.start_tile); //pure eyecandy (station near industry)
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);
return this.ZnajdzStacjeSmartRail(list, size);
}

function SmartRailBuilder::ZnajdzStacjeSmartRail(list, length)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(this.IsGreatPlaceForRailStationSmartRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(this.IsGreatPlaceForRailStationSmartRail(station, StationDirection.x_is_constant__horizontal, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.x_is_constant__horizontal;
		return returnik;
		}
	}
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(this.IsOKPlaceForRailStationSmartRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(this.IsOKPlaceForRailStationSmartRail(station, StationDirection.x_is_constant__horizontal, length))
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

function SmartRailBuilder::IsGreatPlaceForRailStationSmartRail(station_tile, direction, length)
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
	if ( AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW) )return true;
	return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
	}
else
   {
   local tile_a = station_tile + AIMap.GetTileIndex(0, -1);
   local tile_b = station_tile + AIMap.GetTileIndex(0, length);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   if(!(Utils_Tile.IsNearlyFlatTile(tile_a) && Utils_Tile.IsNearlyFlatTile(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	if( AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW)) return true;
	return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
   }
}

function SmartRailBuilder::IsOKPlaceForRailStationSmartRail(station_tile, direction, length)
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
   
 function SmartRailBuilder::distanceBetweenIndustriesValuatorSmartRail(distance)
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

function SmartRailBuilder::GetMinDistanceSmartRail()
{
return 10;
}

function SmartRailBuilder::GetMaxDistanceSmartRail()
{
if(desperacja>5) return 100+desperacja*75;
return 250+desperacja*50;
}