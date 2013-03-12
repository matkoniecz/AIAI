class StupidRailBuilder extends RailBuilder
{
};

function StupidRailBuilder::Possible()
{
if(!IsAllowedStupidCargoTrain())return false;
Info("estimated cost of a stupid railway connection: " + this.cost + " /  available funds: " + GetAvailableMoney());
return this.cost<GetAvailableMoney();
}

function StupidRailBuilder::Go()
{
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin()); //TODO FIXME - needed in IsGreatPlaceForRailStationSmartRail etc
for(local i=0; i<2; i++)
	{
	if(!Possible())return false;
	Important("Scanning for stupid rail route");
	trasa = this.FindPairForStupidRailRoute(trasa);  
	if(!trasa.OK) 
		{
		Info("Nothing found!");
		cost = 0;
		return false;
		}
	AIRail.SetCurrentRailType(trasa.track_type);

	Important("Scanning for stupid rail route completed [ " + desperation + " ] cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
	if(this.PrepareStupidRailRoute()) 
		{
	  Info("   Contruction started on correct route.");
	  if(this.ConstructionOfStupidRailRoute()) 
	  return true;
	  else trasa.forbidden.AddItem(trasa.start, 0);
	  }
   else
      {
	  Info("   Route preaparings failed.");	  
	  if(trasa.start==null)return false;
	  else trasa.forbidden.AddItem(trasa.start, 0);
	  }
   }
return false;
}

function StupidRailBuilder::ConstructionOfStupidRailRoute()
{
AIRail.SetCurrentRailType(trasa.track_type);
ProvideMoney();

if(!this.StationConstruction()) return false;   

if(!this.RailwayLinkConstruction(path)){
	Info("   But stopped by error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	return false;	  
	}

trasa.depot_tile = this.BuildDepot(path, true);
   
local max_train_count = 1;
rodzic.SetStationName(trasa.first_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
rodzic.SetStationName(trasa.second_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");

if(trasa.depot_tile==null){
   Info("   Depot placement error");
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  this.DumbRemover(path, null)
   return false;	  
   }

local new_engine = this.BuildTrain(trasa, "stupid");

if(new_engine == null)
   {
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  this.DumbRemover(path, null)
   return false;
   }
this.TrainOrders(new_engine);
   Info("   Route constructed!");
return true;
}
   
function StupidRailBuilder::PrepareStupidRailRoute()
{
Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));
this.StationPreparation();   
if(!this.PathFinder(false, this.GetPathfindingLimit()))return false;
local estimated_cost = this.GetCostOfRoute(path); 
if(estimated_cost==null){
  Info("   Pathfinder failed to find correct route.");
  return false;
  }
  
estimated_cost+=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);
cost=estimated_cost;
if(GetAvailableMoney()<estimated_cost+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	ProvideMoney();
	if(GetAvailableMoney()<estimated_cost+2000) 
		{
		Info("too expensivee, we have only " + GetAvailableMoney() + " And we need " + estimated_cost);
		AITile.DemolishTile(trasa.first_station.location);
		AITile.DemolishTile(trasa.second_station.location);
		return false;
		}
	}
return true;
}

function StupidRailBuilder::FindPairForStupidRailRoute(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this); 
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuatorStupidRail = this.distanceBetweenIndustriesValuatorStupidRail.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuatorStupidRail, IndustryToIndustryTrainStupidRailStationAllocator, GetNiceRandomTownStupidRail, IndustryToCityTrainStupidRailStationAllocator, RailBuilder.GetTrain);
}

function StupidRailBuilder::GetNiceRandomTownStupidRail(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistanceStupidRail());
town_list.KeepAboveValue(GetMinDistanceStupidRail());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0)return null;
return town_list.Begin();
}

function StupidRailBuilder::IndustryToIndustryTrainStupidRailStationAllocator(project)
{
project.station_size = 7;

local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;

project.first_station.location = null; 
for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaStupidRail(producer, cargo, project.station_size);
project.second_station = this.ZnajdzStacjeKonsumentaStupidRail(consumer, cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;

return project;
}

function StupidRailBuilder::IndustryToCityTrainStupidRailStationAllocator(project)
{
project.station_size = 7;

project.first_station.location = null; 
for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaStupidRail(project.start, project.cargo, project.station_size);
project.second_station = this.ZnajdzStacjeMiejskaStupidRail(project.end, project.cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;
return project;
}

function StupidRailBuilder::ZnajdzStacjeMiejskaStupidRail(town, cargo, size)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return this.ZnajdzStacjeStupidRail(list, size);
}

function StupidRailBuilder::ZnajdzStacjeKonsumentaStupidRail(consumer, cargo, size)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
list.Valuate(AIMap.DistanceSquare, trasa.end_tile); //pure eyecandy (station near industry)
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);
return this.ZnajdzStacjeStupidRail(list, size);
}

function StupidRailBuilder::ZnajdzStacjeProducentaStupidRail(producer, cargo, size)
{
local list=AITileList_IndustryProducing(producer, 3);
list.Valuate(AIMap.DistanceSquare, trasa.start_tile); //pure eyecandy (station near industry)
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);
return this.ZnajdzStacjeStupidRail(list, size);
}

function StupidRailBuilder::ZnajdzStacjeStupidRail(list, length)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(this.IsOKPlaceForRailStationStupidRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(this.IsOKPlaceForRailStationStupidRail(station, StationDirection.x_is_constant__horizontal, length))
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

function StupidRailBuilder::IsOKPlaceForRailStationStupidRail(station_tile, direction, length)
{
local test = AITestMode();
/* Test Mode */
if(direction == StationDirection.y_is_constant__vertical)
   {
   local tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
   local tile_b = station_tile + AIMap.GetTileIndex(length, 0);
   if(!(AITile.IsBuildable(tile_a) || AITile.IsBuildable(tile_b)))return false;
	if ( AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW) )return true;
	return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
	}
else
   {
   local tile_a = station_tile + AIMap.GetTileIndex(0, -1);
   local tile_b = station_tile + AIMap.GetTileIndex(0, length);
   if (!(AITile.IsBuildable(tile_a) || AITile.IsBuildable(tile_b)))return false;
	if (AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW) )return true;
	return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
   }
}
   
 function StupidRailBuilder::distanceBetweenIndustriesValuatorStupidRail(distance)
{
if(distance>GetMaxDistanceStupidRail())return 0;
if(distance<GetMinDistanceStupidRail()) return 0;

if(desperation>5)
   {
   if(distance>desperation*60)return 1;
   return 4;
   }

if(distance>100+desperation*50)return 1;
if(distance>85) return 2;
if(distance>70) return 3;
if(distance>55) return 4;
if(distance>40) return 3;
if(distance>25) return 2;
if(distance>10) return 1;
return 0;
}

function StupidRailBuilder::GetMinDistanceStupidRail()
{
return 10;
}

function StupidRailBuilder::GetMaxDistanceStupidRail()
{
if(desperation>5) return desperation*75;
return 150+desperation*50;
}