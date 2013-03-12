/*
local airport_type = (AIAirport.IsValidAirportType(AIAirport.AT_LARGE) ? AIAirport.AT_LARGE : AIAirport.AT_SMALL);
if(airport_type==AIAirport.AT_LARGE)
   {
      if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_METROPOLITAN))
         {
		 return true;
		 }
	  else if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_LARGE))
	     {
		 return true;
		 }
	  else if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_COMMUTER))
	     {
		 return true;
		 }
   }
return BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_SMALL);
*/

function KWAI::FindPairIndustryToTownAllocator(route)
{
route.first_station.location = null;
route.end_station = null;
return route;
//TODO

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_METROPOLITAN, route.start);
route.end_station = FindSuitableAirportSpotInTheTown(AIAirport.AT_METROPOLITAN, route.end, route.cargo);
route.station_size = AIAirport.AT_METROPOLITAN;
if(route.first_station.location != null && route.end_station != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_LARGE, route.start);
route.end_station = FindSuitableAirportSpotInTheTown(AIAirport.AT_LARGE, route.end, route.cargo);
route.station_size = AIAirport.AT_LARGE;
if(route.first_station.location != null && route.end_station != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_COMMUTER, route.start);
route.end_station = FindSuitableAirportSpotInTheTown(AIAirport.AT_COMMUTER, route.end, route.cargo);
route.station_size = AIAirport.AT_COMMUTER;
if(route.first_station.location != null && route.end_station != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_SMALL, route.start);
route.end_station = FindSuitableAirportSpotInTheTown(AIAirport.AT_SMALL, route.end, route.cargo);
route.station_size = AIAirport.AT_SMALL;
return route;
}

function KWAI::FindPairDualIndustryAllocator(route)
{
route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_METROPOLITAN, route.start);
route.end_station = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_METROPOLITAN, route.end, route.cargo);
route.station_size = AIAirport.AT_METROPOLITAN;
if(route.first_station.location != null && route.end_station != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_LARGE, route.start);
route.end_station = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_LARGE, route.end, route.cargo);
route.station_size = AIAirport.AT_LARGE;
if(route.first_station.location != null && route.end_station != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_COMMUTER, route.start);
route.end_station = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_COMMUTER, route.end, route.cargo);
route.station_size = AIAirport.AT_COMMUTER;
if(route.first_station.location != null && route.end_station != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_SMALL, route.start);
route.end_station = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_SMALL, route.end, route.cargo);
route.station_size = AIAirport.AT_SMALL;
return route;
}


function KWAI::FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(airport_type, industry_id)
{
local airport_x, airport_y, airport_rad;
local good_tile = 0;
airport_x = AIAirport.GetAirportWidth(airport_type);
airport_y = AIAirport.GetAirportHeight(airport_type);
airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

local tile_list=AITileList_IndustryProducing (industry_id, airport_rad)

tile_list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
tile_list.KeepValue(1);
return FindSuitableAirportSpotNearIndustryWithAirportType(tile_list, airport_type);
}

function KWAI::FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(airport_type, consumer, cargo)
{
local airport_x, airport_y, airport_rad;
local good_tile = 0;
airport_x = AIAirport.GetAirportWidth(airport_type);
airport_y = AIAirport.GetAirportHeight(airport_type);
airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

local list=AITileList_IndustryAccepting(consumer, 3);

list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
list.KeepValue(1);

list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
return FindSuitableAirportSpotNearIndustryWithAirportType(list, airport_type);
}

function KWAI::FindSuitableAirportSpotNearIndustryWithAirportType(tile_list, airport_type)
{
	local test = AITestMode();
    for (local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next()) 
		{
		if (AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) return tile;
		}
/* Did we found a place to build the airport on? */
return null;
}

function KWAI::FindSuitableAirportSpotInTown(airport_type, center_tile)
{
if(AIAI.GetSetting("deep_debugged_function_calling"))Info("FindSuitableAirportSpotInTown<");
	local airport_x, airport_y, airport_rad;

	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);
	local town_list = AITownList();

	//Info(town_list.Count());
	
	town_list.Valuate(AITown.GetLocation);
	
	town_list.Valuate(this.PopulationWithRandValuator);
	town_list.KeepAboveValue(500-desperacja);

	if (center_tile != 0) {
    town_list.Valuate(AITown.GetDistanceManhattanToTile, center_tile);
	town_list.KeepAboveValue(this.GetMinDistance());    
	town_list.KeepBelowValue(this.GetMaxDistance());    
	}
	
	town_list.Valuate(this.DistanceWithRandValuator, center_tile);
	//TODO - wed³ug dystansu optimum to 500
	   
	town_list.KeepBottom(50);

	//Info(town_list.Count());
	
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next()) {

    	local tile = AITown.GetLocation(town);

		local list = AITileList();
		local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
		SafeAddRectangle(list, tile, range);

		//Info("tiles " + list.Count());
	
		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
		list.KeepValue(1);

		//Info(list.Count());
	
		list.Valuate(rodzic.IsConnectedDistrict);
		list.KeepValue(0);

		//Info(list.Count());
	
		/* Sort on acceptance, remove places that don't have acceptance */
		list.Valuate(AITile.GetCargoAcceptance, rodzic.GetPassengerCargoId(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(50);

		//Info(list.Count());
	
		list.Valuate(AITile.GetCargoAcceptance, rodzic.GetMailCargoId(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(10);

		//Info(list.Count());
	
		/* Couldn't find a suitable place for this town, skip to the next */
		if (list.Count() == 0) continue;
		/* Walk all the tiles and see if we can build the airport at all */
		{
			local good_tile = 0;
			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
				if(!IsItPossibleToHaveAirport(tile, airport_type, AIStation.STATION_NEW))
				   {
				   //Error("BAD " + tile);
				   //AISign.BuildSign(tile, "X");
				   continue;
				   }
			   Error("OK");
				good_tile = tile;
				break;
			}

			/* Did we found a place to build the airport on? */
			if (good_tile == 0) continue;
		}

		AILog.Info("Found a good spot for an airport in town " + town + " at tile " + tile);
if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">FindSuitableAirportSpotInTown");

		return tile;
	}

	AILog.Info("Couldn't find a suitable town to build an airport in");
if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">FindSuitableAirportSpotInTown");
	return -1;
}

function KWAI::FindSuitableAirportSpotInTheTown(town, cargo)
{
 	local tile = AITown.GetLocation(town);
	local list = AITileList();
	local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
	SafeAddRectangle(list, tile, range);

	list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
	list.KeepValue(1);

	/* Sort on acceptance, remove places that don't have acceptance */
	list.Valuate(AITile.GetCargoAcceptance, rodzic.GetPassengerCargoId(), airport_x, airport_y, airport_rad);
	list.RemoveBelowValue(50);

	//Info(list.Count());

	list.Valuate(AITile.GetCargoAcceptance, rodzic.GetMailCargoId(), airport_x, airport_y, airport_rad);
	list.RemoveBelowValue(10);

	//Info(list.Count());
	
	/* Couldn't find a suitable place for this town, skip to the next */
	if (list.Count() == 0) return null;
	/* Walk all the tiles and see if we can build the airport at all */
		local good_tile = 0;
		for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
			if(!IsItPossibleToHaveAirport(tile, airport_type, AIStation.STATION_NEW))continue;
		    else
			  {
			  return tile;
			  }
		}

return null;
}
