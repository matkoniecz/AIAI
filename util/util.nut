function AIAI::EnsureStatueForThisStation(station_id) {
	local location = AIStation.GetLocation(station_id);
	local town = AITile.GetClosestTown(location);
	if (AITown.HasStatue(town)){
		return true;
	}
	if (AITown.PerformTownAction(town, AITown.TOWN_ACTION_BUILD_STATUE)) {
		Info("Statue for " + AIStation.GetName(station_id));
		return true;
	}
	return false;
}

function AIAI::BuildStatues() {
	Info("Trying to build statues.")
	local veh_list = AIVehicleList();
	if (veh_list.Count() == 0) {
		return false;
	}

	//iterating over vehicles rather than AIStationList(AIStation.STATION_ANY);
	//as not everything is point to point
	//for example airports

	veh_list.Valuate(RandomValuator);
	veh_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	for (local veh = veh_list.Begin(); veh_list.HasNext(); veh = veh_list.Next()) {
		for(local i = 0; i < AIOrder.GetOrderCount(veh); i++) {
			local location = AIOrder.GetOrderDestination(veh, i);
			if (AITile.IsStationTile(location)) {
				if ((AIOrder.GetOrderFlags(veh, i) & AIOrder.OF_NO_LOAD) != AIOrder.OF_NO_LOAD) {
					local station_id = AIStation.GetStationID(location);
					if (AIVehicle.GetVehicleType(veh) == AIVehicle.VT_RAIL || AICompany.GetBankBalance(AICompany.COMPANY_SELF) > AICompany.GetMaxLoanAmount() || desperation>30) {
						if(!EnsureStatueForThisStation(station_id)) {
							if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
								return false;
							}	else {
								Warning("Statue construction failed due to " + AIError.GetLastErrorString());
							}
						}
					}
				}
			}
		}
	}
	Info("Statue construction failed despite available cash.");
	return false;
}

/////////////////////////////////////////////////
/// Age of the youngest vehicle (in days)
/// @pre AIStation.IsValidStation(station_id)
/////////////////////////////////////////////////
function AgeOfTheYoungestVehicle(station_id) {
	if (!AIStation.IsValidStation(station_id)) {
		abort("Invalid station_id");
	}
	local list = AIVehicleList_Station(station_id);
	local minimum = 10000;
	for (local q = list.Begin(); list.HasNext(); q = list.Next()) {
		local age=AIVehicle.GetAge(q);
		if (minimum > age) {
			minimum = age;
		}
	}
	return minimum;
}

function GetAverageCapacityOfVehiclesFromStation(station, cargo) {
	local list = AIVehicleList_Station(station);
	local total = 0;
	local count = 0;
	for (local q = list.Begin(); list.HasNext(); q = list.Next()) {
		local plus = AIVehicle.GetCapacity(q, cargo);
		if (plus>0) {
			total+=plus;
			count++;
		}
	}
	if (count == 0) {
		return 0;
	} else {
		return total/count;
	}
}

function SafeAddRectangle(list, tile, radius) { //from Rondje
	local x1 = max(1, AIMap.GetTileX(tile) - radius);
	local y1 = max(1, AIMap.GetTileY(tile) - radius);
	
	local x2 = min(AIMap.GetMapSizeX() - 2, AIMap.GetTileX(tile) + radius);
	local y2 = min(AIMap.GetMapSizeY() - 2, AIMap.GetTileY(tile) + radius);
	
	list.AddRectangle(AIMap.GetTileIndex(x1, y1), AIMap.GetTileIndex(x2, y2)); 
}

function SafeRemoveRectangle(list, tile, radius) { //based on code from Rondje
	local x1 = max(1, AIMap.GetTileX(tile) - radius);
	local y1 = max(1, AIMap.GetTileY(tile) - radius);
	
	local x2 = min(AIMap.GetMapSizeX() - 2, AIMap.GetTileX(tile) + radius);
	local y2 = min(AIMap.GetMapSizeY() - 2, AIMap.GetTileY(tile) + radius);
	
	list.RemoveRectangle(AIMap.GetTileIndex(x1, y1), AIMap.GetTileIndex(x2, y2)); 
}

function IsTileFlatAndBuildable(tile) {
	return (AITile.IsBuildable(tile) && AITile.SLOPE_FLAT == AITile.GetSlope(tile));
}

function IsTileWithAuthorityRefuse(tile) {
	local town_id=AITile.GetClosestTown (tile);
	if (!Town.TownRatingAllowStationBuilding(town_id)) {
		return true;
	} else {
		return false;
	}
}

function ImproveTownRating(town_id, desperation) {
	local mode = AIExecMode();
	if (GetAvailableMoney() < Money.Inflate(200000) && desperation == 0) {
		return false;
	}
	ProvideMoney();
	local min_rating = AITown.TOWN_RATING_POOR;
	/* Check whether the current rating is good enough. */
	local rating = AITown.GetRating(town_id, AICompany.COMPANY_SELF);
	if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) {
		return true;
	}

	if (GetAvailableMoney() > GetSafeBankBalance()) {
		local costs = AIAccounting();
		Town.PlantTreesToImproveRating(town_id, min_rating, GetSafeBankBalance());
		Info("Tree planting at cost of " + costs.GetCosts() + " near " + AITown.GetName(town_id));
	}

	if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) {
		return true;
	}
	while(GetAvailableMoney()> Money.Inflate(3000000 || desperation > 5)) {
		if (AITown.PerformTownAction(town_id, AITown.TOWN_ACTION_BRIBE)) {
			Info("Bribed "+AITown.GetName(town_id)+".");
		} else {
			Info("Bribe in "+AITown.GetName(town_id)+" failed! " + AIError.GetLastErrorString());
			return false;
		}
		if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) {
			return true;
		}
	}
	if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) {
		return true;
	}
	return false;
}

function HandleFailedStationConstruction(location, error) {
	if (error == AIError.ERR_LOCAL_AUTHORITY_REFUSES) {
		ImproveTownRating(AITile.GetClosestTown(location), this.desperation);
	}
}

function GetRatherBigRandomTownValuator(town_id) {
	return AITown.GetPopulation(town_id)*AIBase.RandRange(5);
}

function GetRatherBigRandomTown() {
	local town_list = AITownList();
	town_list.Valuate(GetRatherBigRandomTownValuator);
	town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	return town_list.Begin();
}

function RandomValuator(dummy){
	return AIBase.RandRange(1000);
}

function IsCityTileUsed(town_tile, cargo_id) {
	if(IsCityTileUsedByAirport(town_tile, cargo_id)){
		return true;
	}
	return IsCityTileUsedByRoadVehicle(town_tile, cargo_id);
}

function IsCityTileUsedByRoadVehicle(town_tile, cargo_id) {
	local station_type = AIRoad.GetRoadVehicleTypeForCargo(cargo_id);
	local station_range = AIStation.GetCoverageRadius(station_type);

	local tiles_to_check = AITileList();
	SafeAddRectangle(tiles_to_check, town_tile, station_range);

	for(local tile = tiles_to_check.Begin(); tiles_to_check.HasNext(); tile = tiles_to_check.Next()) {
		local station_id = AIStation.GetStationID(tile);
		if(!AIStation.IsValidStation(station_id)){
			continue;
		}
		if(IsCargoLoadedOnThisStation(station_id, cargo_id)){
			return true;
		}
	}
	return false;
}

function IsCityTileUsedByAirport(town_tile, cargo_id) {
	//TODO - it is a hack rather than function
	local list = AIStationList(AIStation.STATION_AIRPORT);
	if (list.Count()!=0) {
		list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
		list.KeepBelowValue(18);
		list.Valuate(IsCargoLoadedOnThisStation, cargo_id);
		list.KeepValue(1);
		if (!list.IsEmpty()) return true;
	}
	return false;
}

function IsCargoLoadedOnThisStation(station_id, cargo_id) {
	local vehicle = ExampleOfVehicleFromStation(station_id);
	if(vehicle == null){
		return false;
	}
	if (AIVehicle.GetCapacity(vehicle, cargo_id) == 0) {
		return false;
	}

	for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) {
		if (!AIOrder.IsGotoStationOrder(vehicle, i)) {
			continue;
		}
		if ((AIOrder.GetOrderFlags(vehicle, i) & AIOrder.OF_NO_LOAD) == AIOrder.OF_NO_LOAD) {
			continue;
		}
		local tile_destination = AIOrder.GetOrderDestination(vehicle, i);
		local target_station_id = AIStation.GetStationID(tile_destination);
		if(target_station_id == station_id) {
			return true;
		}
	}
	return false;
}

function ExampleOfVehicleFromStation(station_id){
	local vehicle = null;
	local vehicle_list=AIVehicleList_Station(station_id);
	if (vehicle_list.Count() != 0) {
		vehicle = vehicle_list.Begin();
	}
	return vehicle;
}

function VehicleCounter(station) {
	return AIVehicleList_Station(station).Count();
}

function DeleteEmptyStations() {
	local station_id_list;
	station_id_list = AIStationList(AIStation.STATION_TRUCK_STOP);
	station_id_list.AddList(AIStationList(AIStation.STATION_BUS_STOP));
	station_id_list.Valuate(VehicleCounter);
	station_id_list.KeepValue(0);
	for (local spam = station_id_list.Begin(); station_id_list.HasNext(); spam = station_id_list.Next()) {
		local depot_tile = LoadDataFromStationNameFoundByStationId(spam, "[]");
		if (depot_tile != null && AIRoad.IsRoadDepotTile(depot_tile)) {
			if (AIRoad.RemoveRoadDepot(depot_tile)) {
				AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));
			} else {
				if (AIError.GetLastError() != AIError.ERR_VEHICLE_IN_THE_WAY && AIError.GetLastError() != AIError.AIError.ERR_NOT_ENOUGH_CASH) {
					Error("Abandoned road depot removal failed with " + AIError.GetLastErrorString());
					if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
						abort("unexpected error");
					}
				}
			}
		} else {
			AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));
		}
	}

	station_id_list = AIStationList(AIStation.STATION_TRAIN); //TODO: remove also tracks
	station_id_list.Valuate(VehicleCounter);
	station_id_list.KeepValue(0);
	for (local spam = station_id_list.Begin(); station_id_list.HasNext(); spam = station_id_list.Next()) {
		AITile.DemolishTile(AIBaseStation.GetLocation(spam));
	}
}

function DeleteUnprofitable() {
	local vehicle_list = AIVehicleList();

	vehicle_list.Valuate(IsForSellUseTrueForInvalidVehicles);
	vehicle_list.KeepValue(0);

	vehicle_list.Valuate(AIVehicle.GetAge);
	vehicle_list.KeepAboveValue(800);

	vehicle_list.Valuate(AIVehicle.GetProfitThisYear);
	vehicle_list.KeepBelowValue(0);
	vehicle_list.Valuate(AIVehicle.GetProfitLastYear);
	vehicle_list.KeepBelowValue(0);

	Info(vehicle_list.Count() + " vehicle(s) should be sold because are unprofitable");
	
	local counter = 0;
	
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()) {
		local load_station_id = GetLoadStationId(vehicle_id)
		if (load_station_id == null) {
			continue
		}
		local load_station_vehicle_list = AIVehicleList_Station(load_station_id)
		if (AIVehicle.GetVehicleType(vehicle_id)!=AIVehicle.VT_RAIL || load_station_vehicle_list.Count()>2) {
			if (AIVehicle.IsValidVehicle(vehicle_id)) if (SellVehicle(vehicle_id, "unprofitable")) counter++;
		}
	}
	Info(counter + " vehicle(s) sold.");
}

function NotMovingVehiclesFromThisStation(station) {
	local vehicle_list = AIVehicleList_Station(station);
	vehicle_list.Valuate(AIVehicle.GetCurrentSpeed);
	vehicle_list.KeepValue(0);
	vehicle_list.Valuate(AIVehicle.GetState);
	vehicle_list.RemoveValue(AIVehicle.VS_AT_STATION);
	return vehicle_list;
}
function HowManyVehiclesFromThisStationAreNotMoving(station) {
	return NotMovingVehiclesFromThisStation(station).Count();
}

function SellVehicle(vehicle_id, why) {
	if (!AIVehicle.IsOKVehicle(vehicle_id)) {
		Error("Invalid or crashed vehicle " + vehicle_id);
		return true;
	}
	if (IsForSell(vehicle_id) != false) {
		return false;
	}
	AIVehicle.SetName(vehicle_id, "sell!" + why);
	if (!AIVehicle.SendVehicleToDepot(vehicle_id)) {
		Info("failed to sell vehicle! "+AIError.GetLastErrorString());
		return false;
	}
	AIVehicle.SetName(vehicle_id, "for sell " + why);
	return true;
}

function gentleSellVehicle(vehicle_id, why) {
	if (IsForSell(vehicle_id) != false) {
		return false;
	}
	local tile_1 = GetLoadStationLocation(vehicle_id);
	local tile_2 = GetUnloadStationLocation(vehicle_id);
	local depot_location = GetDepotLocation(vehicle_id);
	if (tile_1 == null || tile_2 == null || depot_location == null) {
		return false
	}

	if (!AIOrder.UnshareOrders(vehicle_id)) {
		abort("WTF? Unshare impossible? "+AIVehicle.GetName(vehicle_id));
	}

	//note: AIAI is using modified AIOrder.AppendOrder that will trigger assertion on failure
	AIOrder.AppendOrder(vehicle_id, tile_1, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
	AIOrder.AppendOrder(vehicle_id, tile_2, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD);
	AIOrder.AppendOrder(vehicle_id, depot_location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_STOP_IN_DEPOT);
	if (AIOrder.ResolveOrderPosition (vehicle_id, AIOrder.ORDER_CURRENT) != 1) {
		if (!AIOrder.SkipToOrder(vehicle_id, 1)) {
			abort("SkipToOrder failed");
		}
	}
	AIVehicle.SetName(vehicle_id, "for sell!" + why);
}