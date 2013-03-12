class StupidRailBuilder extends RailBuilder
{//FIXME - merge it 
};

function StupidRailBuilder::Possible()
{
if(!IsAllowedCargoTrain()) return false;
Info("estimated cost of a railway connection: " + this.cost + " /  available funds: " + GetAvailableMoney());
return this.cost<GetAvailableMoney();
}

function StupidRailBuilder::Go()
{
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin()); //TODO FIXME - needed in IsGreatPlaceForRailStationRail etc
for(local i=0; i<2; i++)
	{
	if(!Possible()) return false;
	Info("Scanning for rail route");
	trasa = this.FindPairForStupidRailRoute(trasa);  
	if(!trasa.OK) 
		{
		Info("Nothing found!");
		cost = 0;
		return false;
		}
	AIRail.SetCurrentRailType(trasa.track_type);

	local main_part_of_message = "Scanning for rail route completed. Desperation: " + desperation + " cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start);
	if(!trasa.second_station.is_city)
		{
		Info(main_part_of_message + " End: " + AIIndustry.GetName(trasa.end));
		}
	else if(trasa.second_station.is_city)
		{
		Info(main_part_of_message + " End: " + AITown.GetName(trasa.end));
		}
	else abort("wtf")
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
	  if(trasa.start==null) return false;
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
   
if(trasa.depot_tile==null){
   Info("   Depot placement error");
  AITile.DemolishTile(trasa.first_station.location);
  AITile.DemolishTile(trasa.second_station.location);
  this.DumbRemover(path, null)
   return false;	  
   }

local new_engine = this.BuildTrain(trasa, "stupid");

if(new_engine == null) {
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;
	}
this.TrainOrders(new_engine);
Info("   Route constructed!");

ProvideMoney();
local max_train_count = this.AddPassingLanes(path);

if(max_train_count==0) max_train_count = 1;
if(max_train_count>=2 && max_train_count < 10)max_train_count = 2 + (max_train_count-2)/2;
if(max_train_count>=10 && max_train_count < 20)max_train_count = 5 + (max_train_count-9)/3;
if(max_train_count>=20)max_train_count = 2 + (max_train_count-19)/4;

rodzic.SetStationName(trasa.first_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
rodzic.SetStationName(trasa.second_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");

if(max_train_count>1) 
	{
	new_engine = this.BuildTrain(trasa, "muhahaha");
	if(new_engine != null) {
		this.TrainOrders(new_engine);
		}
	}
return true;
}
   
function StupidRailBuilder::PrepareStupidRailRoute()
{
Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));
this.StationPreparation();   
if(!this.PathFinder(false, this.GetPathfindingLimit())) return false;
local estimated_cost = this.GetCostOfRoute(path); 
if(estimated_cost==null){
  Info("   Pathfinder failed to find correct route.");
  return false;
  }
Info("Route is OK!")
  
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
Info("Route found!")
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
local distanceBetweenIndustriesValuatorRail = this.distanceBetweenIndustriesValuatorRail.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuatorRail, IndustryToIndustryTrainStupidRailStationAllocator, GetNiceRandomTownStupidRail, IndustryToCityTrainStupidRailStationAllocator, RailBuilder.GetTrain);
}

function StupidRailBuilder::GetNiceRandomTownStupidRail(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistanceRail());
town_list.KeepAboveValue(GetMinDistanceRail());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0) return null;
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
project.first_station = this.FindStationProducerStupidRail(producer, cargo, project.station_size);
project.second_station = this.FindStationConsumerStupidRail(consumer, cargo, project.station_size);
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
project.first_station = this.FindStationProducerStupidRail(project.start, project.cargo, project.station_size);
project.second_station = this.FindStationMiejskaStupidRail(project.end, project.cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;
return project;
}

function StupidRailBuilder::FindStationMiejskaStupidRail(town, cargo, size)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
return this.FindStationStupidRail(list, size);
}

function StupidRailBuilder::FindStationConsumerStupidRail(consumer, cargo, size)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
list.Valuate(AIMap.DistanceSquare, trasa.end_tile); //pure eyecandy (station near industry)
list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
return this.FindStationStupidRail(list, size);
}

function StupidRailBuilder::FindStationProducerStupidRail(producer, cargo, size)
{
local list=AITileList_IndustryProducing(producer, 3);
list.Valuate(AIMap.DistanceSquare, trasa.start_tile); //pure eyecandy (station near industry)
list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
return this.FindStationStupidRail(list, size);
}

function StupidRailBuilder::FindStationStupidRail(list, length)
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
local tile_a = null;
local tile_b = null;
local railtrack = null;

if(direction == StationDirection.y_is_constant__vertical)
	{
	tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
	tile_b = station_tile + AIMap.GetTileIndex(length, 0);
	railtrack = AIRail.RAILTRACK_NE_SW;
	}
else
	{
	tile_a = station_tile + AIMap.GetTileIndex(0, -1);
	tile_b = station_tile + AIMap.GetTileIndex(0, length);
	railtrack = AIRail.RAILTRACK_NW_SE
	}

if(AIRail.IsRailStationTile(tile_a))
	if(AIRail.GetRailStationDirection(tile_a) == railtrack)
		return false;

if(AIRail.IsRailStationTile(tile_b))
	if(AIRail.GetRailStationDirection(tile_b) == railtrack)
		return false;
		
if (!(AITile.IsBuildable(tile_a) || AITile.IsBuildable(tile_b))) return false;
if (!AIRail.BuildRailStation(station_tile, railtrack, 1, length, AIStation.STATION_NEW) ) 
	{
	local error = AIError.GetLastError();
	rodzic.HandleFailedStationConstruction(station_tile, error);
	if (error != AIError.ERR_NOT_ENOUGH_CASH) return false;
	}
return true;
}