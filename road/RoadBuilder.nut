class RoadBuilder extends Builder
{
	desperation = 0;
	AIAI_instance = null;
	cost = 0;
	list_of_detected_rail_crossings = null;
	path = null;

	trasa = null;
}

class RoadStation extends Station
{
	road_loop = null;
}

require("level_crossing_menagement_from_clueless_plus.nut");
require("RoadPathfinder.nut");

function RoadBuilder::IsAllowed() {
	if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD)) {
		Warning("AIs are not allowed to build road vehicles in this game (see advanced settings, section 'Competitors', subsection 'Computer players')!");
		return false;
	}

	local veh_list = AIVehicleList();
	veh_list.Valuate(AIVehicle.GetVehicleType);
	veh_list.KeepValue(AIVehicle.VT_ROAD);
	local count = veh_list.Count();
	local allowed = AIGameSettings.GetValue("vehicle.max_roadveh");

	if (allowed == 0) {
		return false;
	}
	if (allowed==0) {
		Warning("Max road vehicle count is set to 0 (see advanced settings, section 'vehicles'). ");
		return false;
	}
	if (count==0) {
		return true;
	}
	if (((count*100)/(allowed))>90) {
		Warning("Max road vehicle count is too low to consider more road vehicles (see advanced settings, section 'vehicles'). ");
		return false;
	}
	if ((allowed - count)<5) {
		Warning("Max road vehicle count is too low to consider more road vehicles (see advanced settings, section 'vehicles'). ");
		return false;
	}
	return true;
}

function RoadBuilder::Maintenance() {
	local new = this.AddNewNecessaryRV();
	local redundant = this.RemoveRedundantRV();
	if ((new+redundant) > 0) {
		Info("RoadBuilder: Vehicles: " + new + " new, " +  redundant + " redundant send to depot.");
	}
}

function RoadBuilder::GetMinDistance() {
	return 10 - desperation/50;
}

function RoadBuilder::GetMaxDistance() {
	if (desperation>5) {
		return desperation*75;
	} else {
		return 150+desperation*50;
	}
}

function RoadBuilder::distanceBetweenIndustriesValuator(distance) {
	if (distance>GetMaxDistance()) {
		return 0;
	}
	if (distance<GetMinDistance()) {
		return 0;
	}

	if (desperation>5) {
		if (distance>desperation*60) {
			return 1;
		}
		return 4;
	}

	if (distance>100+desperation*50) return 1;
	if (distance>85) return 2;
	if (distance>70) return 3;
	if (distance>55) return 4;
	if (distance>40) return 3;
	if (distance>25) return 2;
	if (distance>10) return 1;
	return 0;
}

function RoadBuilder::BuildRVStation(type) {
	if (!AIRoad.BuildDriveThroughRoadStation(trasa.first_station.location, trasa.first_station.road_loop[0], type, AIStation.STATION_NEW)) {
		HandleFailedStationConstruction(trasa.first_station.location, AIError.GetLastError());
		if (!AIRoad.BuildDriveThroughRoadStation(trasa.first_station.location, trasa.first_station.road_loop[0], type, AIStation.STATION_NEW)) {
			Info("   Producer station placement impossible due to A " + AIError.GetLastErrorString());
			if (AIAI.GetSetting("other_debug_signs")) {
				AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString());
			}
			return false;
		}
	}
	if (!AIRoad.BuildDriveThroughRoadStation(trasa.second_station.location, trasa.second_station.road_loop[0], type, AIStation.STATION_NEW)) {
		HandleFailedStationConstruction(trasa.second_station.location, AIError.GetLastError());
		if (!AIRoad.BuildDriveThroughRoadStation(trasa.second_station.location, trasa.second_station.road_loop[0], type, AIStation.STATION_NEW)) {
			Info("   Consumer station placement impossible due to B " + AIError.GetLastErrorString());
			AIRoad.RemoveRoadStation(trasa.first_station.location);
			if (AIAI.GetSetting("other_debug_signs")) {
				AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString());
			}
			return false;
		}
	}
	return RoadToStation();
}

function RoadBuilder::RoadToStation() {
	//with infrastructure maintemance add road removal (but only new parts!) TODO
	if (!AIRoad.BuildRoad(trasa.first_station.road_loop[1], trasa.first_station.location)) {
		if (RoadBuilder.IsLastErrorImplyingRoadConstructionFailure()) {
			Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
			AIRoad.RemoveRoadStation(trasa.first_station.location);
			AIRoad.RemoveRoadStation(trasa.second_station.location);
			return false;
		}
	}
	if (!AIRoad.BuildRoad(trasa.first_station.location, trasa.first_station.road_loop[0])) {
		if (RoadBuilder.IsLastErrorImplyingRoadConstructionFailure()) {
			Info("   Road to producer station placement impossible due to " + AIError.GetLastErrorString());
			AIRoad.RemoveRoadStation(trasa.first_station.location);
			AIRoad.RemoveRoadStation(trasa.second_station.location);
			return false;
		}
	}
	if (!AIRoad.BuildRoad(trasa.second_station.road_loop[1], trasa.second_station.location)) {
		if (RoadBuilder.IsLastErrorImplyingRoadConstructionFailure()) {
			Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
			AIRoad.RemoveRoadStation(trasa.first_station.location);
			AIRoad.RemoveRoadStation(trasa.second_station.location);
			return false;
		}
	}
	if (!AIRoad.BuildRoad(trasa.second_station.location, trasa.second_station.road_loop[0])) {
		if (RoadBuilder.IsLastErrorImplyingRoadConstructionFailure()) {
			Info("   Road to consumer station placement impossible due to " + AIError.GetLastErrorString());
			AIRoad.RemoveRoadStation(trasa.first_station.location);
			AIRoad.RemoveRoadStation(trasa.second_station.location);
			return false;
		}
	}
	return true;
}

function RoadBuilder::ValuateProducer(ID, cargo) {
	return Builder.ValuateProducer(ID, cargo);
}

function RoadBuilder::GetBiggestNiceTown(location) {
	local town_list = AITownList();
	town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
	town_list.KeepBelowValue(GetMaxDistance());
	town_list.KeepAboveValue(GetMinDistance());
	town_list.Valuate(AITown.GetPopulation);
	town_list.KeepTop(1);
	if (town_list.Count()==0) {
		return null;
	}
	return town_list.Begin();
}

function RoadBuilder::InitRoadLoop(project) {
	project.first_station.road_loop = array(2);
	project.second_station.road_loop = array(2);

	if (project.first_station.direction == StationDirection.x_is_constant__horizontal) {
		project.first_station.road_loop[0]=project.first_station.location+AIMap.GetTileIndex(0, 1);
		project.first_station.road_loop[1]=project.first_station.location+AIMap.GetTileIndex(0, -1);
	} else {
		project.first_station.road_loop[0]=project.first_station.location+AIMap.GetTileIndex(1, 0);
		project.first_station.road_loop[1]=project.first_station.location+AIMap.GetTileIndex(-1, 0);
	}
	if (project.second_station.direction == StationDirection.x_is_constant__horizontal) {
		project.second_station.road_loop[0]=project.second_station.location+AIMap.GetTileIndex(0, 1);
		project.second_station.road_loop[1]=project.second_station.location+AIMap.GetTileIndex(0, -1);
	} else {
		project.second_station.road_loop[0]=project.second_station.location+AIMap.GetTileIndex(1, 0);
		project.second_station.road_loop[1]=project.second_station.location+AIMap.GetTileIndex(-1, 0);
	}
	return project;
}

function RoadBuilder::TownCargoStationAllocator(project) {
	local start = project.start;
	local town = project.end;
	local cargo = project.cargo;

	local maybe_start_station = this.FindTownCargoSupplyStation(start, null, cargo);
	local maybe_second_station = this.FindTownCargoSupplyStation(town, AITown.GetLocation(start), cargo);

	project.first_station = maybe_start_station;
	project.second_station = maybe_second_station;

	project.second_station.location = project.second_station.location;

	maybe_start_station = project.first_station.location;
	//maybe_second_station = project.second_station.location;

	if ((project.first_station.location==null) || (project.second_station.location==null)) {
		if ((maybe_start_station==null) && (project.second_station.location==null)) {
			Info("   Station placing near "+AITown.GetName(start)+" and "+AITown.GetName(town)+" is impossible.");
			project.forbidden_industries.AddItem(project.start, 0);
			project.forbidden_industries.AddItem(project.end, 0);
		}
		if ((maybe_start_station==null) && (project.second_station.location!=null)) {
			Info("   Station placing near "+AITown.GetName(start)+" is impossible.");
			project.forbidden_industries.AddItem(project.start, 0);
		}
		if ((maybe_start_station!=null) && (project.second_station.location==null))  {
			Info("   Station placing near "+AITown.GetName(town)+" is impossible.");
			project.forbidden_industries.AddItem(project.end, 0);
		}
		return project;
	}
	//Info("   Stations planned.");
	project = RoadBuilder.InitRoadLoop(project);
	return project;
}

function RoadBuilder::UniversalStationAllocator(project) {
	if ((project.first_station.location==null) || (project.second_station.location==null)) {
		if (project.first_station.location == null) {
			project.forbidden_industries.AddItem(project.start, 0);
		}
		if (project.second_station.location==null) {
			//TODO - why no receiving industry is blacklisted?
		}
		return project;
	}
	//Info("   Stations planned.");
	project = RoadBuilder.InitRoadLoop(project);
	return project;
}

function RoadBuilder::PrepareRoute() {
	Info("   Road route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));

	local forbidden_tiles = array(2);
	forbidden_tiles[0] = trasa.second_station.location;
	forbidden_tiles[1] = trasa.first_station.location;

	local pathfinder = CustomPathfinder();
	pathfinder.Fast();
	pathfinder.InitializePath(trasa.second_station.road_loop, trasa.first_station.road_loop, forbidden_tiles);
	path = false;
	local guardian = 0;
	local pathfinding_split = 5; //to make maintemance more often - for example plane skipping
	local limit = this.GetPathfindingLimit()*pathfinding_split;
	local time_for_pathfinding_run = 2000/pathfinding_split;
	while (path == false) {
		Info("   Pathfinding ("+guardian+" / " + limit + ") started");
		path = pathfinder.FindPath(time_for_pathfinding_run);
		Info("   Pathfinding ("+guardian+" / " + limit + ") ended");
		AIAI_instance.Maintenance();
		AIController.Sleep(1);
		guardian++;
		if (guardian>limit) {
			break;
		}
		if (AIAI.GetSetting("abort_pathfinding") == 1) {
			Warning("pathfinding stopped on request");
			break;
		}
	}

	if (path == false || path == null) {
		Info("   Pathfinder failed to find route. ");
		return false;
	}

	Info("   Road pathfinder found sth.");
	local estimated_cost = this.CheckRoad(path);
	if (estimated_cost==null) {
		Info("   Pathfinder failed to find correct route.");
		return false;
	}

	estimated_cost += AIEngine.GetPrice(trasa.engine) * 5;
	cost = estimated_cost;

	if (GetAvailableMoney()<estimated_cost) {
		Warning("too expensivee, we have only " + GetAvailableMoney() + " And we need " + estimated_cost + " ( " + (GetAvailableMoney()*100/estimated_cost) + "% )");
		return false;
	}
	return true;   
}

function RoadBuilder::ConstructionOfRVRoute() {
	trasa.depot_tile = null;
	ProvideMoney();
	if (!this.BuildRVStation(AIRoad.GetRoadVehicleTypeForCargo(trasa.cargo))) {
		return false;
	}

	if (!this.BuildRoad(path)) {
		HandleFailedConstructionOfRoute(trasa);
		Info("   But stopped by error");
		return false;
	}

	trasa.depot_tile = MakePlaceForReversingVehicles(trasa.first_station, "loading bay");

	if (trasa.depot_tile == null) {
		trasa.depot_tile = Road.BuildDepotNextToRoad(trasa.first_station.location, 0, 200);
	}
	if (trasa.depot_tile == null) {
		HandleFailedConstructionOfRoute(trasa);
		Info("   Depot placement error");
		return false;
	}
	assert(AIRoad.IsRoadDepotTile(trasa.depot_tile));
	
	NameStations(trasa);

	Info("   Route constructed!");

	local how_many_new_vehicles = this.BuildVehicles();

	if (how_many_new_vehicles==null) {
		Error("Vehicles construction failed");
		HandleFailedConstructionOfRoute(trasa);
		cost = 0;
		return false;
	}

	Info("   Vehicles construction, " + how_many_new_vehicles + " vehicles constructed.");

	Info("MakeAdditionalStations at unload")
	MakeAdditionalStations(trasa.second_station.location);

	Info("MakeAdditionalStations at load")
	MakeAdditionalStations(trasa.first_station.location);

	MakePlaceForReversingVehicles(trasa.second_station, "unloading bay");
	return true;
}

function RoadBuilder::MakeAdditionalStations(station_location) {
	local next_to_road_count = 0;
	local unlocking_count = 100;
	Info(" AdditionalStationsIncreasingCapture")
	AdditionalStationsIncreasingCapture(station_location, unlocking_count);
	Info(" AdditionalAccessibleStations")
	AdditionalAccessibleStations(station_location, next_to_road_count);
}

function RoadBuilder::AdditionalStationsIncreasingCapture(station_location, unlocking_count) {
	local max_spread = AIGameSettings.GetValue("station.station_spread");
	local station_range = 3; //TODO - use here and in other places rather AIStation::GetCoverageRadius  (   AIStation::StationType    station_type   )
	//TODO - be evil and use rail stations? Airports?

	local tiles_for_serving = TilesForServingInRange(station_location, station_range, max_spread);

	//TODO - smarter checking, rather than walk over list it may be possible 
	//to get minimum number of stations needed for coverage

	tiles_for_serving.Valuate(RandomValuator);
	tiles_for_serving.Sort(AIList.SORT_BY_VALUE, true);

	while(unlocking_count > 0) {
		if(tiles_for_serving.Count() == 0){
			break;
		}
		local tile = tiles_for_serving.Begin();
		local potential_stop_locations = AITileList();
		SafeAddRectangle(potential_stop_locations, tile, station_range);
		local type = AIRoad.GetRoadVehicleTypeForCargo(trasa.cargo);
		local station_id = AIStation.GetStationID(station_location);
		for(local new_stop = potential_stop_locations.Begin(); potential_stop_locations.HasNext(); new_stop = potential_stop_locations.Next()) {
			if(TryBothRVStationDirection(new_stop, type, station_id)){
				SafeRemoveRectangle(tiles_for_serving, new_stop, station_range); //now served
				unlocking_count -= 1;
				break;
			}
		}
		tiles_for_serving.RemoveTile(tile); //impossible to serve this one
	}
}

function RoadBuilder::AdditionalAccessibleStations(station_location, next_to_road_count) {
	local max_spread = AIGameSettings.GetValue("station.station_spread");
	local station_id = AIStation.GetStationID(station_location);
	local tile = null;
	local walker = MinchinWeb.SpiralWalker();
	walker.Start(station_location)

	do {
		tile = walker.GetTile();
		walker.Walk();
		if(next_to_road_count <= 0) {
			break;
		}
		if(AIRoad.IsRoadTile(tile)){
			if(TryBothRVStationDirection(tile, type, station_id)) {
				next_to_road_count -= 1; //TODO - this may make some stations from previous round pointless
			}
		}
	} while(AIMap.DistanceManhattan(station_location, tile) < max_spread)
}

function RoadBuilder::TilesForServingInRange(station_location, station_range, max_spread){
	local tiles_for_serving = AITileList();

	local new_tiles_in_range = AITileList();
	SafeAddRectangle(new_tiles_in_range, station_location, station_range + max_spread);
	SafeRemoveRectangle(new_tiles_in_range, station_location, station_range); //already served

	while(new_tiles_in_range.Count() > 0) {
		local tile = new_tiles_in_range.Begin();
		new_tiles_in_range.RemoveTile(tile);
		if(AITile.GetCargoAcceptance(tile, trasa.cargo, 1, 1, 0) > 0) {
			tiles_for_serving.AddTile(tile);
		} else if(AITile.GetCargoProduction(tile, trasa.cargo, 1, 1, 0) > 0) {
			tiles_for_serving.AddTile(tile);
		}
	}
	return tiles_for_serving;
}

function RoadBuilder::TryBothRVStationDirection(tile, type, station_id){
	local next_a = tile+AIMap.GetTileIndex(0, 1);
	local next_b = tile+AIMap.GetTileIndex(1, 0);
	if(AIRoad.BuildDriveThroughRoadStation(tile, next_a, type, station_id)){
		return true;
	}
	if(AIRoad.BuildDriveThroughRoadStation(tile, next_b, type, station_id)){
		return true;
	}
	return false;
}

function RoadBuilder::NameStations(route) {
	AIAI_instance.SetStationName(route.first_station.location, "["+route.depot_tile+"]");
	AIAI_instance.SetStationName(route.second_station.location, "["+route.depot_tile+"]");
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(route.first_station.location), "[]") == route.depot_tile);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(route.second_station.location), "[]") == route.depot_tile);
}

function RoadBuilder::HandleFailedConstructionOfRoute(route) {
	AIRoad.RemoveRoadStation(route.first_station.location);
	AIRoad.RemoveRoadStation(route.second_station.location);
	//TODO: remove also road in case of infrastructure costs/small maps - but remove only just newly constructed to avoid destruction of an old route
}

// additional road/depot has minor costs and makes RV more efficient as turning place is close.
// without that in some situations vehicles must travel far away before turning is possible - in extreme cases across the maps
// in case of road failing to be constructed station is capped by depot
// 
// this function assumes that road is already constructed and depots may be placed without causing deadlock
//
// @returns location of constructed depot, null if no depot was placed
function RoadBuilder::MakePlaceForReversingVehicles(station, name){
	Info("   working on circle around " + name);
	this.BuildLoopAroundStation(station.road_loop[0], station.road_loop[1], station.location);
	if(AIRoad.BuildRoadDepot (station.road_loop[0], station.location)) { 
		return station.road_loop[0]
	}
	if(AIRoad.BuildRoadDepot (station.road_loop[1], station.location)) { //to make more likely that RV have place to reverse
		return station.road_loop[1]
	}
	return null;
}

function RoadBuilder::GetReplace(existing_vehicle, cargo) {
	return this.FindRV(cargo);
}

function FindEngineForRoute(route) {
	route.engine = FindRV(route.cargo);
	if (route.engine == null) {
		return route;
	}
	route.engine_count = HowManyVehiclesForNewStation(route);
	return route;
}

function RoadBuilder::FindRVValuator(engine) {
	//rating points for station:  (Speed (km/h) - 85) / 4 
	//max rating points from speed: 17% (255 points - 100%, 17% - 43,35) 
	//rating points more important than anything (almost)
	return min(43, max((AIEngine.GetMaxSpeed(engine) - 85) /4, 0)) * 1500 + AIEngine.GetCapacity(engine)*AIEngine.GetMaxSpeed(engine);
}

function RoadBuilder::FindRV(cargo) {
	local list = AIEngineList(AIVehicle.VT_ROAD);

	list.Valuate(AIEngine.GetRoadType);
	list.KeepValue(AIRoad.GetCurrentRoadType());

	list.Valuate(AIEngine.CanRefitCargo, cargo);
	list.KeepValue(1);

	list.Valuate(this.FindRVValuator);
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

	if (list.Count() != 0) {
		local first_engine_id = list.Begin();
		local new_engine_id = first_engine_id
		for(local engine = list.Begin(); list.HasNext(); engine = list.Next()) {
			local speed_ratio_to_first = (AIEngine.GetMaxSpeed(engine)*100)/(AIEngine.GetMaxSpeed(first_engine_id));
			if ((speed_ratio_to_first>90) && AIEngine.GetCapacity(engine)/2 > AIEngine.GetCapacity(new_engine_id)) {
				new_engine_id = engine;
			}
			if ((speed_ratio_to_first>80) && AIEngine.GetCapacity(engine)/2 > AIEngine.GetCapacity(new_engine_id) && AIEngine.GetCapacity(new_engine_id) < 10) {
				new_engine_id = engine;
			}
			if ((speed_ratio_to_first>70) && AIEngine.GetCapacity(engine)/2 > AIEngine.GetCapacity(new_engine_id) && AIEngine.GetCapacity(new_engine_id) < 5) {
				new_engine_id = engine;
			}
		}
		return new_engine_id;
	}
	return null;
}

function RoadBuilder::IsLastErrorImplyingRoadConstructionFailure() {
	if (AIError.GetLastError() == AIError.ERR_ALREADY_BUILT) {
		return false;
	}
	if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
		return false;
	}
	if (AIError.GetLastError() == AIError.ERR_NONE) {
		return false;
	}
	return false;
}

function RoadBuilder::IsOKPlaceForRVStation(station_tile, direction) {
	local t_ts = array(2);

	if (direction == StationDirection.x_is_constant__horizontal) {
		t_ts[0]=station_tile+AIMap.GetTileIndex(0, 1);
		t_ts[1]=station_tile+AIMap.GetTileIndex(0, -1);
	} else {
		t_ts[0]=station_tile+AIMap.GetTileIndex(1, 0);
		t_ts[1]=station_tile+AIMap.GetTileIndex(-1, 0);
	}

	local test = AITestMode();
	/* Test Mode */

	if (!AIRoad.BuildDriveThroughRoadStation(station_tile, t_ts[0], AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) {
		if (AIError.GetLastError() != AIError.ERR_NOT_ENOUGH_CASH) {
			return false;
		}
	}
	if (!AIRoad.BuildRoad(t_ts[1], station_tile)) {
		if (RoadBuilder.IsLastErrorImplyingRoadConstructionFailure()) {
			return false;
		}
	}
	if (!AIRoad.BuildRoad(station_tile, t_ts[0])) {
		if (RoadBuilder.IsLastErrorImplyingRoadConstructionFailure()) {
			return false;
		}
	}
	return true;
}

function RoadBuilder::IsWrongPlaceForRVStation(station_tile, direction) {
	if (IsTileWithAuthorityRefuse(station_tile)) {
		HandleFailedStationConstruction(station_tile, AIError.ERR_LOCAL_AUTHORITY_REFUSES);
		if (IsTileWithAuthorityRefuse(station_tile)) {
			return true;
		}
	}
	if (!IsTileFlatAndBuildable(station_tile)) {
		return true;
	}
	if (direction == StationDirection.x_is_constant__horizontal) {
		if (!IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(0, 1))) {
			return true;
		}
		if (!IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(0, -1))) {
			return true;
		}
	} else {
		if (!IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(1, 0))) {
			return true;
		}
		if (!IsTileFlatAndBuildable(station_tile+AIMap.GetTileIndex(-1, 0))) {
			return true;
		}
	}
	return false;
}

function RoadBuilder::FindStation(list) {
	for(local station = list.Begin(); list.HasNext(); station = list.Next()) {
		if (!IsWrongPlaceForRVStation(station, StationDirection.x_is_constant__horizontal)) {
			local returned = RoadStation();
			returned.location = station;
			returned.direction = StationDirection.x_is_constant__horizontal;
			return returned;
		} else if (!IsWrongPlaceForRVStation(station, StationDirection.y_is_constant__vertical)) {
			local returned = RoadStation();
			returned.location = station;
			returned.direction = StationDirection.y_is_constant__vertical;
			return returned;
		} else {
			if (AIAI.GetSetting("other_debug_signs")) {
				AISign.BuildSign(station, "X");
			}
		}
	}

	for(local station = list.Begin(); list.HasNext(); station = list.Next()) {
		if (IsOKPlaceForRVStation(station, StationDirection.x_is_constant__horizontal)) {
			local returned = RoadStation();
			returned.location = station;
			returned.direction = StationDirection.x_is_constant__horizontal;
			return returned;
		}
		if (IsOKPlaceForRVStation(station, StationDirection.y_is_constant__vertical)) {
			local returned = RoadStation();
			returned.location = station;
			returned.direction = StationDirection.y_is_constant__vertical;
			return returned;
		}
	}
	local returned = RoadStation();
	returned.location = null;
	return returned;
}

function RoadBuilder::FindCityStation(town, cargo) {
	local tile = AITown.GetLocation(town);
	local list = AITileList();
	local range = Helper.Sqrt(AITown.GetPopulation(town)/100) + 15;
	SafeAddRectangle(list, tile, range);
	list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
	list.KeepAboveValue(10);
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	return this.FindStation(list);
}

function RoadBuilder::FindConsumerStation(consumer, cargo) {
	local list=AITileList_IndustryAccepting(consumer, 3);
	list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
	list.RemoveValue(0);
	return this.FindStation(list);
}

function RoadBuilder::FindProducentStation(producer, cargo) {
	local list=AITileList_IndustryProducing(producer, 3);
	return this.FindStation(list);
}

function RoadBuilder::FindTownCargoSupplyStation(town, start, cargo) {
	local tile = AITown.GetLocation(town);
	local list = AITileList();
	local range = Helper.Sqrt(AITown.GetPopulation(town)/100) + 15;
	SafeAddRectangle(list, tile, range);
	list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
	list.KeepAboveValue(max(25, 50-desperation));

	if (start != null) {
		list.Valuate(AIMap.DistanceManhattan, start);
		list.RemoveBelowValue(20-desperation/20);
	}

	list.Valuate(IsCityTileUsed, cargo);
	list.KeepValue(0);

	list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	return (this.FindStation(list));
}

function RoadBuilder::HowManyVehiclesForNewStation(route) {
	local speed = AIEngine.GetMaxSpeed(route.engine);
	local distance = AIMap.DistanceManhattan(route.first_station.location, route.second_station.location);
	local how_many = route.production/AIEngine.GetCapacity(route.engine);
	local multiplier = ((distance*88)/(50*speed));
	if (multiplier == 0) {
		multiplier = 1;
	}
	how_many *= multiplier;
	how_many += 3;
	return how_many;
}

function RoadBuilder::sellVehicleStoppedInDepotDueToFoo(vehicle_id, foo) {
	Error("RV (" + AIVehicle.GetName(vehicle_id) + ") "+ foo + " failed due to " + AIError.GetLastErrorString()+".");
	if (AIVehicle.SellVehicle(vehicle_id))  {
		Info("Vehicle sold");
	} else {
		Error("RV selling failed due to " + AIError.GetLastErrorString()+".");
	}
	return null;
}

function RoadBuilder::SetOrdersForVehicle(vehicle_id) {
	if (trasa.type == RouteType.rawCargo) {
		if (!(AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE )&&
					AIOrder.AppendOrder (vehicle_id, trasa.second_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD ))) {
			this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "order appending");
			return null;
		}
	} else if (trasa.type == RouteType.processedCargo) {
		local conditionalOrderPosition=1;
		local unconditionalJumpPosition=3;

		if (!(AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE )&&
					AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.OF_NON_STOP_INTERMEDIATE )&&
					AIOrder.AppendOrder (vehicle_id, trasa.second_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD )&&
					AIOrder.AppendOrder (vehicle_id, trasa.depot_tile,  AIOrder.OF_NON_STOP_INTERMEDIATE )&&
					
					AIOrder.InsertConditionalOrder (vehicle_id, conditionalOrderPosition, 2)&&
					AIOrder.SetOrderCompareValue(vehicle_id, conditionalOrderPosition, 0)&&
					AIOrder.SetOrderCondition (vehicle_id, conditionalOrderPosition, AIOrder.OC_LOAD_PERCENTAGE)&&
					AIOrder.SetOrderCompareFunction(vehicle_id, conditionalOrderPosition, AIOrder.CF_MORE_THAN)&&
					
					AIOrder.InsertConditionalOrder (vehicle_id, unconditionalJumpPosition, 0)&&
					AIOrder.SetOrderCompareValue(vehicle_id, unconditionalJumpPosition, 0)&&
					AIOrder.SetOrderCondition (vehicle_id, unconditionalJumpPosition, AIOrder.OC_UNCONDITIONALLY))) {
			this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "order appending");
			return null;
		}
	} else if (trasa.type == RouteType.townCargo) {
		if (!(AIOrder.AppendOrder (vehicle_id, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE )&&
					AIOrder.AppendOrder (vehicle_id, trasa.second_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE ))) {
			this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "order appending");
			return null;
		}
	} else {
		abort("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
	}
}

function RoadBuilder::BuildVehicles() {
	local constructed = 0;
	if (trasa.engine == null) {
		return null;
	}
	local how_many = trasa.engine_count;
	local vehicle_id = -1;
	vehicle_id=AIVehicle.BuildVehicle (trasa.depot_tile, trasa.engine);
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		return null;
	}
	constructed++;

	this.SetOrdersForVehicle(vehicle_id);
	if (!AIVehicle.RefitVehicle (vehicle_id, trasa.cargo)) {
		this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "refitting");
		return null;
	}

	if (!AIVehicle.StartStopVehicle (vehicle_id)) {
		//TODO blacklist and respect blacklisting in finding RV
		this.sellVehicleStoppedInDepotDueToFoo(vehicle_id, "starting");
		return null;
	}

	local string;
	if (trasa.type == RouteType.rawCargo) {
		string = "Raw cargo";
	} else if (trasa.type == RouteType.processedCargo) {
		string = "Processed cargo"; 
	} else if (trasa.type == RouteType.townCargo) {
		string = "Bus line";
	} else {
		string = "WTF?"; 
		if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
			abort("invalid enum value");
		}
	}
	AIVehicle.SetName(vehicle_id, string);

	for(local i = 0; i<how_many; i++) {
		if (this.copyVehicle(vehicle_id, trasa.cargo)) {
			constructed++;
		}
	}
	
	return constructed;
}

function RoadBuilder::IsRawVehicle(vehicle_id) {
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		return null;
	}
	return AIVehicle.GetName(vehicle_id)[0]=='R';
}

function RoadBuilder::IsProcessedCargoVehicle(vehicle_id) {
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		return null;
	}
	return AIVehicle.GetName(vehicle_id)[0]=='P';
}

function RoadBuilder::IstownCargoVehicle(vehicle_id) {
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		return null;
	}
	return AIVehicle.GetName(vehicle_id)[0]=='B';
}

function RoadBuilder::CheckRoad(path) {
	local costs = AIAccounting();
	costs.ResetCosts ();

	/* Exec Mode */
	{
		local test = AITestMode();
		/* Test Mode */

		if (RoadBuilder.BuildRoad(path)) {
			return costs.GetCosts();
		} else {
			return null;
		}

		if (path == null) {
			return false;
		}
		while (path != null) {
			local par = path.GetParent();
			if (par != null) {
				local last_node = path.GetTile();
				if (!this.BuildRoadSegment(path.GetTile(),  par.GetTile(), 0)) {
					Error(AIError.GetLastErrorString());
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

function RoadBuilder::BuildRoad(path) {
	if (path == null) {
		return false;
	}
	while (path != null) {
		local par = path.GetParent();
		if (par != null) {
			local last_node = path.GetTile();
			if (!this.BuildRoadSegment(path.GetTile(),  par.GetTile(), 0)) {
				return false;
			}
		}
		path = par;
	}
	return true;
}

function RoadBuilder::BuildLoopAroundStation(tile_start, tile_end, tile_ignored) {
	local pathfinder = CustomPathfinder();
	pathfinder.LoopAroundStation();
	local t1=array(1);
	local t2=array(1);
	local i=array(1);
	t1[0]=tile_start;
	t2[0]=tile_end;
	i[0]=tile_ignored;
	pathfinder.InitializePath(t1, t2, i);

	local path = false;
	while (path == false) {
		path = pathfinder.FindPath(1000);
		if (path==null) {
			return false;
		}
		AIAI_instance.Maintenance();
		AIController.Sleep(1);
	}
	return this.BuildRoad(path);
}

function RoadBuilder::GetRandomVehicle(station_id){
	local vehicle_list = AIVehicleList_Station(station_id);
	vehicle_list.Valuate(RandomValuator);
	vehicle_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	return vehicle_list.Begin();
}

function RoadBuilder::GetLinkedStation(station_id) {
	local original = GetRandomVehicle(station_id);
	local load_station_id = GetLoadStationId(original);
	local another_station_id = GetUnloadStationId(original);
	if (load_station_id == null || another_station_id == null) {
		HandleInvalidOrders(station_id);
		return 0;
	}
	if (another_station_id == station_id) {
		another_station_id = load_station_id;
	}
	return another_station_id;
}

function RoadBuilder::AddNewNecessaryRVToThisPlace(station_id, cargo) {
	if (AIVehicleList_Station(station_id).Count()==0) {
		HandleDeadStation(station_id, cargo);
		return 0;
	}

	local another_station_id = GetLinkedStation(station_id);
	//station_id is currently processed station, another_station_id is the other side of the link

	local original = GetRandomVehicle(station_id);
	if (StationModificationStopped(station_id, another_station_id, cargo, original)) {
		return 0;
	}
	
	local processed = this.IsProcessedCargoVehicle(original);
	if (processed == null) {
		AddingStoppedInvalidStatus(station_id)
		return 0;
	}
	if (processed) {
		if (!IsItNeededToImproveThatNoRawStation(station_id, cargo)) {
			AddingStoppedHelpNotNeededForProcessingStation(station_id, cargo);
			return 0;
		}
	}
	if (GetSecondLoadStationId(original) != null) { //two way transport
	}
	local returned = HandledSpeciallyAsTwoWayRoute(station_id, another_station_id, cargo, original, processed);
	if (returned != null) {
		return returned;
	}
	if (this.copyVehicle(original, cargo )) {
		return 1;
	}
	return 0;
}

//return null to accept adding vehicle, return 0 otherwise
function RoadBuilder::HandledSpeciallyAsTwoWayRoute(station_id, another_station_id, cargo, original, processed) {
	local list = AIVehicleList_Station(station_id);
	for (local rv = list.Begin(); list.HasNext(); rv = list.Next()) {
		if(AIOrder.GetOrderDestination(rv, AIOrder.ORDER_CURRENT) == another_station_id){
			if(AIVehicle.GetCargoLoad(rv, cargo) < AIVehicle.GetCargoCapacity(rv, cargo)) {
				//if vehicle is traveling from that station with less than full fill, then adding more is a bad idea
				//at least on two-way routes
				return 0;
			}
		}
	}

	if (processed) {
		if(IsItNeededToImproveThatNoRawStation(another_station_id, cargo)) {
			//both ends need an improvement, lets launch new vehicles
			return null;
		}
	} else if (IsItNeededToImproveThatStation(another_station_id, cargo)) {
		//both ends need an improvement, lets launch new vehicles
		return null;
	}

	//another_station_id may be on full load, resulting in stale cargo on the current one
	if (RoadBuilder.DynamicFullLoadManagement(station_id, another_station_id, original)) { //reordering attempted to fix problem
		return 0; //cloning is not necessary
	}
	return null;
}

function RoadBuilder::StationModificationStopped(station_id, another_station_id, cargo, example_vehicle){
	if (AIVehicle.GetProfitLastYear(example_vehicle) < 0) {
		AddingStoppedUnprofitable(station_id, cargo);
		return true;
	}
	if (AgeOfTheYoungestVehicle(station_id) <= 20) {
		AddingStoppedNewVehiclesPresent(station_id);
		return true;
	}
	if (!IsItNeededToImproveThatStation(station_id, cargo)) {
		AddingStoppedHelpNotNeeded(station_id, cargo);
		return true;
	}
	if (AIVehicle.GetCapacity(example_vehicle, cargo) == 0) {
		return AddingStoppedUnexpectedCargo(station_id, cargo);
	}

	local veh_list = NotMovingVehiclesFromThisStation(station_id);
	veh_list.Valuate(IsVehicleNearStation, another_station_id);
	veh_list.RemoveValue(1);
	veh_list.Valuate(IsVehicleNearStation, station_id);
	veh_list.RemoveValue(1);
	if (veh_list.Count() != 0) {
		AddingStoppedTrafficJam(station_id, cargo);
		return true;
	}

	if (!AICargoList_StationAccepting(another_station_id).HasItem(cargo)) {
		AddingStoppedRouteDestroyed(station_id, cargo);
		return true;
	}

	return false;
}

function RoadBuilder::HandleInvalidOrders(station_id){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "invalid orders - " + GetReadableDate());
	}
}

function RoadBuilder::HandleDeadStation(station_id, cargo){
	//TODO - revive empty station (?)
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "dead - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedInvalidStatus(station_id){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "invalid processed status - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedNewVehiclesPresent(station_id){
	//to protect from bursts of new vehicles
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "young RV - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedHelpNotNeeded(station_id, cargo){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		if (AIStation.HasCargoRating(station_id, cargo)) { //TODO once it will hit stables remove note about debug_signs_about_adding_road_vehicles in info.nut
			Helper.BuildSign(AIStation.GetLocation(station_id), "OK status - " + GetReadableDate());
		}
	}
}

function RoadBuilder::AddingStoppedTrafficJam(station_id, cargo){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "not moving - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedUnprofitable(station_id, cargo){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "unprofitable - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedRouteDestroyed(station_id, cargo){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(another_station_id), AICargo.GetLabel(cargo) + " refused - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedHelpNotNeededForProcessingStation(station_id, cargo){
	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(AIStation.GetLocation(station_id), "OK for processed - " + GetReadableDate());
	}
}

function RoadBuilder::AddingStoppedUnexpectedCargo(station_id, cargo){
	Error(AIVehicle.GetName(original) + " have no capacity for " + AICargo.GetCargoLabel(cargo));
	if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
		abort("Wild cargo appeared. In case of RV there is no valid explanation.");
	}
}

function RoadBuilder::AddNewNecessaryRV() {
	local how_many = 0;
	local cargo_list = AICargoList();
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) {
		local station_list = AIStationList(AIStation.STATION_TRUCK_STOP);
		station_list.AddList(AIStationList(AIStation.STATION_BUS_STOP));
		for (local station_id = station_list.Begin(); station_list.HasNext(); station_id = station_list.Next()) {
			how_many += AddNewNecessaryRVToThisPlace(station_id, cargo)
		}
	}
	return how_many;
}

function RoadBuilder::DynamicFullLoadManagement(full_station, empty_station, RV) {
	if (AIBase.RandRange(3) != 0) {
		return true; //To wait for effects of action and avoid RV flood
	}

	local load_station_tile_id = GetLoadStationId(RV);
	if (load_station_tile_id == null) {
		return false;
	}
	local first_station_is_full = (load_station_tile_id == full_station);

	if (first_station_is_full) {
		if (AIOrder.GetOrderFlags(RV, 0) != (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE)) {
			Info(AIVehicle.GetName(RV) + " - change, situation 1");
			AIOrder.SetOrderFlags(RV, 0, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE);
			return true;
		} else {
			if (AIOrder.GetOrderFlags(RV, 1) == (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE)) {
				Info(AIVehicle.GetName(RV) + " - change, situation 2");
				AIOrder.SetOrderFlags(RV, 1, AIOrder.OF_NON_STOP_INTERMEDIATE);
				return true;
			}
		}
	} else {
		if (AIOrder.GetOrderFlags(RV, 1) != (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE)) {
			Info(AIVehicle.GetName(RV) + " - change, situation 3");
			AIOrder.SetOrderFlags(RV, 1, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE);
			return true;
		} else {
			if (AIOrder.GetOrderFlags(RV, 0) == (AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE)) {
				Info(AIVehicle.GetName(RV) + " - change, situation 4");
				AIOrder.SetOrderFlags(RV, 0, AIOrder.OF_NON_STOP_INTERMEDIATE);
				return true;
			}
		}
	}
	return false;
}

function RoadBuilder::copyVehicle(main_vehicle_id, cargo) {
	ProvideMoney();
	if (AIVehicle.IsValidVehicle(main_vehicle_id)==false) {
		return false;
	}
	local depot_tile = GetDepotLocation(main_vehicle_id);
	local speed = AIEngine.GetMaxSpeed(this.FindRV(cargo));
	local load_station_tile = GetLoadStationLocation(main_vehicle_id);
	local unload_station_tile = GetUnloadStationLocation(main_vehicle_id);
	if (unload_station_tile == null || load_station_tile == null) {
		return false;
	}
	local distance = AIMap.DistanceManhattan(load_station_tile, unload_station_tile);

	//RV station may process 24 RV in a month (24*)
	//in one month vehicle moves 52 tiles at 48 km/h - so it is OK to simply use (distance/speed)
	//go and return - two directions (*2)

	local max_count = 24*distance/speed*2;
	if (max_count < 3) {
		max_count = 3;
	}
	if (max_count > 100) {
		max_count = 100;
	}

	local load_station_id = GetLoadStationId(main_vehicle_id);
	if (load_station_id == null) {
		return false;
	}
	local list = AIVehicleList_Station(load_station_id)
	local how_many = list.Count();

	if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
		Helper.BuildSign(load_station_tile+AIMap.GetTileIndex(-1, 0), ""+how_many+" of " + max_count);
		Helper.BuildSign(load_station_tile+AIMap.GetTileIndex(-2, 0), "distance " + distance);
	}

	if (how_many>max_count) {
		if (AIAI.GetSetting("debug_signs_about_adding_road_vehicles")) {
			Helper.BuildSign(load_station_tile, "maxed!");
		}
		Warning("Too many vehicles on this route!");
		return false;
	}

	local vehicle_id = AIVehicle.CloneVehicle(depot_tile, main_vehicle_id, true)
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		Warning("RoadBuilder::copyVehicle failed due to " + AIError.GetLastErrorString());
		return false;
	}
	if (!AIVehicle.StartStopVehicle (vehicle_id)) {
		sellVehicleStoppedInDepotDueToFoo(vehicle_id, "starting (from copyVehicle)");
		return false;
	}

	local string;
	local raw = this.IsRawVehicle(main_vehicle_id);
	local processed = this.IsProcessedCargoVehicle(main_vehicle_id);
	local passengers = this.IstownCargoVehicle(main_vehicle_id);

	if (raw && raw != null) {
		string = "Raw cargo"; 
	} else if (processed && processed != null) {
		string = "Processed cargo"; 
	} else if (passengers && passengers != null) {
		string = "Bus line";
	} else {
		return false; //TODO - cancel sell order
	}
	AIVehicle.SetName(vehicle_id, string);
	return true;
}

function RoadBuilder::RemoveRedundantRV() {
	local station_list = AIStationList(AIStation.STATION_TRUCK_STOP);
	local how_many = RoadBuilder.RemoveRedundantRVFromStations(station_list);
	local station_list = AIStationList(AIStation.STATION_BUS_STOP);
	how_many += RoadBuilder.RemoveRedundantRVFromStations(station_list);
	return how_many;
}

function RoadBuilder::RemoveRedundantRVFromStations(station_list) {
	local full_delete_count = 0;
	local cargo_list = AICargoList();

	for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next()) {
		local cargo;
		local vehicle_list = AIVehicleList_Station(station);
		if (vehicle_list.Count()==0) {
			continue;
		}
		if (AgeOfTheYoungestVehicle(station) < 150) {
			continue;
		}
		for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) {
			if (AIVehicle.GetCapacity (vehicle_list.Begin(), cargo) > 0) {
				break;
			}
		}
		local front_vehicle = vehicle_list.Begin();
		local station_id = GetLoadStationId(front_vehicle);
		if (station_id == null) {
			continue;
		}
		if (station == station_id) {
			full_delete_count += this.RemoveRedundantRVFromStation(station, cargo, vehicle_list);
		}
	}
	return full_delete_count;
}

function RoadBuilder::IsVehicleNearStation(vehicle_id, station_id) {
	return AIStation.GetDistanceManhattanToTile(station_id, AIVehicle.GetLocation(vehicle_id)) < 4;
}

function RoadBuilder::RemoveRedundantRVFromStation(station_id, cargo, vehicle_list) {
	local waiting_counter = 0;	
	local waiting_balance = 0;
	local active_counter = 0;
	local vehicle_for_skipping = null;
	local max_load = -1;
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()) {
		if (IsForSell(vehicle_id) != false || AIVehicle.GetAge(vehicle_id) < 60) {
			return 0;
		}
		if (AIVehicle.GetCargoLoad(vehicle_id, cargo) == 0) {
			if (RoadBuilder.IsVehicleNearStation(vehicle_id, station_id)) {
				if (AIVehicle.GetState(vehicle_id) == AIVehicle.VS_AT_STATION) {
					waiting_balance += 2;
					waiting_counter += 1;
					if(max_load < AIVehicle.GetCargoLoad(vehicle_id, cargo)) {
						vehicle_for_skipping = vehicle_id;
						max_load = AIVehicle.GetCargoLoad(vehicle_id, cargo);
					}
					//Helper.BuildSign(AIVehicle.GetLocation(vehicle_id), "waiting - loading");
				} else if (AIVehicle.GetCurrentSpeed(vehicle_id)==0) {
					//Helper.BuildSign(AIVehicle.GetLocation(vehicle_id), "waiting - speed=0");
					waiting_balance++;
					waiting_counter++;
				} else {
					//Helper.BuildSign(AIVehicle.GetLocation(vehicle_id), "active - speed="+AIVehicle.GetCurrentSpeed(vehicle_id));
					waiting_balance--;
				}
			} else {
				//Helper.BuildSign(AIVehicle.GetLocation(vehicle_id), "active - not near station");
				active_counter++;
			}
		} else {
			//Helper.BuildSign(AIVehicle.GetLocation(vehicle_id), "active - 3");
			active_counter++;
		}
	}
	if(waiting_counter >= 2 && vehicle_for_skipping != null) {
		if(AIStation.GetCargoWaiting(station_id, cargo) < AIVehicle.GetCapacity(vehicle_for_skipping, cargo)){
			SkipVehicleIfLoadingAtThisStation(vehicle_for_skipping, station_id);
		}
	}
	local delete_goal = waiting_balance-5; //TODO OPTION
	local alternate_delete_goal = waiting_balance-active_counter-1;
	if (delete_goal < alternate_delete_goal) {
		delete_goal = alternate_delete_goal;
	}
	return this.deleteVehicles(vehicle_list, delete_goal, cargo);
	return 0;
}

function RoadBuilder::SkipVehicleIfLoadingAtThisStation(vehicle_for_skipping, station_id){
	if (!AIOrder.IsGotoStationOrder(vehicle_for_skipping, AIOrder.ORDER_CURRENT)) {
		return;
	}
	local tile_destination = AIOrder.GetOrderDestination(vehicle_for_skipping, AIOrder.ORDER_CURRENT);
	local target_station_id = AIStation.GetStationID(tile_destination);
	if(station_id != target_station_id) {
		return;
	}
	if (AIVehicle.GetState(vehicle_for_skipping) != AIVehicle.VS_AT_STATION) {
		return;
	}
	BoastAboutSkipping(SkipVehicleToTheNextOrder(vehicle_for_skipping), "RV");
}

function RoadBuilder::deleteVehicles(vehicle_list, delete_goal, cargo) {
	local delete_count=0;
	vehicle_list.Valuate(IsForSellUseTrueForInvalidVehicles);
	vehicle_list.KeepValue(0);
	vehicle_list.Valuate(AIVehicle.GetAge);
	vehicle_list.KeepAboveValue(60);
	vehicle_list.Valuate(AIVehicle.GetCargoLoad, cargo)
	vehicle_list.KeepValue(0);
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()) {
		if (delete_goal - delete_count < 0) {
			break;
		}
		if (AIAI_instance.sellVehicle(vehicle_id, "queuer")) {
			delete_count++;
		}
		Info(delete_count+" of " + delete_goal + " RV marked for deletion send to depot.")
	}
	return delete_count;
}

function RoadBuilder::BuildRoadSegment(path, par, depth) {
	if (depth>=6) {
		Warning("Construction terminated: "+AIError.GetLastErrorString()); 
		if (AIAI.GetSetting("other_debug_signs"))AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
		return false;
	}
	local result;
	if (AIMap.DistanceManhattan(path, par) == 1 ) {
		result = AIRoad.BuildRoad(path, par);
	} else {
		/* Build a bridge or tunnel. */
		if (!AIBridge.IsBridgeTile(path) && !AITunnel.IsTunnelTile(path)) {
			/* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
			if (AIRoad.IsRoadTile(path)) {
				AITile.DemolishTile(path);
			}
			if (AITunnel.GetOtherTunnelEnd(path) == par) {
				result = AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path);
			} else {
				result = AIAI_instance.BuildBridge(AIVehicle.VT_ROAD, path, par);
			}
		}
	}
	
	if (!result) {
		local error = AIError.GetLastError();
		if (error == AIError.ERR_ALREADY_BUILT) {
			return true;
		}
		if (error == AIError.ERR_VEHICLE_IN_THE_WAY) {
			AIController.Sleep(20);
			return this.BuildRoadSegment(path, par, depth+1);
		}
		Warning("Construction terminated: "+AIError.GetLastErrorString()); 
		if (AIAI.GetSetting("other_debug_signs")) {
			AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
		}
		return false;
	}
	return true;
}
