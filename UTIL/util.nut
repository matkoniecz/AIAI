function AIAI::BuildStatues()
{
	local veh_list = AIVehicleList();
	if(veh_list.Count()==0) return false;

	veh_list.Valuate(AIBase.RandItem);
	veh_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	for (local veh = veh_list.Begin(); veh_list.HasNext(); veh = veh_list.Next()) {
		for(local i = 0; i < AIOrder.GetOrderCount(veh); i++) {
			local location = AIOrder.GetOrderDestination(veh, i);
			if(AITile.IsStationTile(location)) {
				if((AIOrder.GetOrderFlags(veh, i) & AIOrder.OF_NO_LOAD) != AIOrder.OF_NO_LOAD) {
					local station = AIStation.GetStationID(location);
					local suma = 0;
					if(AIVehicle.GetVehicleType(veh) == AIVehicle.VT_RAIL || AICompany.GetBankBalance(AICompany.COMPANY_SELF) > AICompany.GetMaxLoanAmount() || desperation>30) {
						if(AITown.PerformTownAction(AITile.GetClosestTown(location), AITown.TOWN_ACTION_BUILD_STATUE)) {
							Info("Statue for " + AIVehicle.GetName(veh));
							return true;
						} else {
							if(AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
								return false;
							}
						}
					}
				}
			}
		}
	}
	Info("Statue construction failed");
	return false;
}

function GetWeightOfCargo(cargo_id) {
	if(AICargo.IsFreight(cargo_id)) {
		return AIGameSettings.GetValue("vehicle.freight_trains");
	}
	if(AICargo.HasCargoClass(cargo_id, AICargo.CC_MAIL) || AICargo.HasCargoClass(cargo_id, AICargo.CC_PASSENGERS))  {
		return 0;
	}
	return 1;
}

/////////////////////////////////////////////////
/// Age of the youngest vehicle (in days)
/// @pre AIStation.IsValidStation(station_id)
/////////////////////////////////////////////////
function AgeOfTheYoungestVehicle(station_id)
{
	if(!AIStation.IsValidStation(station_id)) {
		abort("Invalid station_id");
	}
	local list = AIVehicleList_Station(station_id);
	local minimum = 10000;
	for (local q = list.Begin(); list.HasNext(); q = list.Next()) {
		local age=AIVehicle.GetAge(q);
		if(minimum > age) {
			minimum = age;
		}
	}
	return minimum;
}

function GetAverageCapacityOfVehiclesFromStation(station, cargo)
{
	local list = AIVehicleList_Station(station);
	local total = 0;
	local count = 0;
	for (local q = list.Begin(); list.HasNext(); q = list.Next()) {
		local plus = AIVehicle.GetCapacity(q, cargo);
		if(plus>0) {
			total+=plus;
			count++;
		}
	}
	if(count == 0) {
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


function IsTileFlatAndBuildable(tile)
{
	return (AITile.IsBuildable(tile) && AITile.SLOPE_FLAT == AITile.GetSlope(tile));
}

function IsTileWithAuthorityRefuse(tile)
{
	local town_id=AITile.GetClosestTown (tile);
	if(!Town.TownRatingAllowStationBuilding(town_id)) {
		return true;
	} else {
		return false;
	}
}

//TODO - librarize
function SellVehiclesInDepots()
{
	local counter = 0;
	local list = AIVehicleList();
	for (local vehicle = list.Begin(); list.HasNext(); vehicle = list.Next()) {
		if(AIVehicle.IsStoppedInDepot(vehicle)){
			AIVehicle.SellVehicle(vehicle);
			counter++;
		}
	}
	return counter;
}

//TODO - librarize
function PlantTreesToImproveRating(town_id, min_rating) //from AdmiralAI
{
	/* Build trees to improve the rating. We build this tree in an expanding
	 * circle starting around the town center. */
	local location = AITown.GetLocation(town_id);
	local list = Tile.GetTownTiles(town_id)
	list.Valuate(AITile.IsBuildable);
	list.KeepValue(1);
	/* Don't build trees on tiles that already have trees, as this doesn't
	 * give any town rating improvement. */
	list.Valuate(AITile.HasTreeOnTile);
	list.KeepValue(0);
	foreach (tile, dummy in list) {
		if(AITown.IsWithinTownInfluence(town_id, tile)) {
			if(!AITile.PlantTree(tile)) {
				if(AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
					return (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating);
				}
			}
		}
		/* Check whether the current rating is good enough. */
		if (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating) {
			return true;
		}
		if(GetAvailableMoney() < 0) {
			return false;
		}
	}
	if (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating) {
		return true;
	} else {
		return false;
	}
}

function ImproveTownRating(town_id, desperation)
{
	local mode = AIExecMode();
	if(GetAvailableMoney() < Money.Inflate(200000) && desperation == 0) {
		return false;
	}
	ProvideMoney();
	local min_rating = AITown.TOWN_RATING_POOR;
	/* Check whether the current rating is good enough. */
	local rating = AITown.GetRating(town_id, AICompany.COMPANY_SELF);
	if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) {
		return true;
	}
	local costs = AIAccounting();
	PlantTreesToImproveRating(town_id, min_rating);
	Info("Tree planting at cost of " + costs.GetCosts());

	if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) {
		return true;
	}
	while(GetAvailableMoney()> Money.Inflate(3000000 || desperation > 5)) {
		if(AITown.PerformTownAction(town_id, AITown.TOWN_ACTION_BRIBE)){
			Info("Bribed "+AITown.GetName(town_id)+"!" + AIError.GetLastErrorString());
		} else {
			Info("Bribe in "+AITown.GetName(town_id)+" failed!" + AIError.GetLastErrorString());
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

function HandleFailedStationConstruction(location, error)
{
	if(error == AIError.ERR_LOCAL_AUTHORITY_REFUSES) {
		ImproveTownRating(AITile.GetClosestTown(location), this.desperation);
	}
}

function GetRatherBigRandomTownValuator(town_id)
{
	return AITown.GetPopulation(town_id)*AIBase.RandRange(5);
}

function GetRatherBigRandomTown()
{
	local town_list = AITownList();
	town_list.Valuate(GetRatherBigRandomTownValuator);
	town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	return town_list.Begin();
}

function IsConnectedDistrict(town_tile)
{
	//TODO - it is a hack rather than function
	local list = AIStationList(AIStation.STATION_AIRPORT);
	if(list.Count()!=0){
		list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
		list.KeepBelowValue(18);
		if(!list.IsEmpty()) return true;
	}

	list = AIStationList(AIStation.STATION_BUS_STOP);
	if(list.Count()!=0){
		list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
		list.KeepBelowValue(8);
		if(!list.IsEmpty()) return true;
	}
	return false;
}

function IsCargoLoadedOnThisStation(station_id, cargo_id)
{
	local vehicle_list=AIVehicleList_Station(station_id);
	if(vehicle_list.Count() != 0) {
		if(GetLoadStationId(vehicle_list.Begin()) == station_id) {
			if(AIVehicle.GetCapacity(vehicle_list.Begin(), cargo_id) != 0) {
				return true;
			}
		}
	}
	return false;
}

function VehicleCounter(station)
{
	return AIVehicleList_Station(station).Count();
}

function DeleteEmptyStations()
{
	local station_id_list;
	station_id_list = AIStationList(AIStation.STATION_TRUCK_STOP);
	station_id_list.AddList(AIStationList(AIStation.STATION_BUS_STOP));
	station_id_list.Valuate(VehicleCounter);
	station_id_list.KeepValue(0);
	for (local spam = station_id_list.Begin(); station_id_list.HasNext(); spam = station_id_list.Next()) {
		local depot_tile = LoadDataFromStationNameFoundByStationId(spam, "[]");
		if(AIRoad.IsRoadDepotTile(depot_tile)) {
			if(AIRoad.RemoveRoadDepot(depot_tile)) {
				AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));
			} else {
				if (AIError.GetLastError() != AIError.ERR_VEHICLE_IN_THE_WAY && AIError.GetLastError() != AIError.AIError.ERR_NOT_ENOUGH_CASH) {
					Error("Abandoned road depot removal failed with " + AIError.GetLastErrorString());
					if(AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
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

function DeleteUnprofitable()
{
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
		if(load_station_id == null) {
			continue
		}
		local load_station_vehicle_list = AIVehicleList_Station(load_station_id)
		if(AIVehicle.GetVehicleType(vehicle_id)!=AIVehicle.VT_RAIL || load_station_vehicle_list.Count()>2) {
			if(AIVehicle.IsValidVehicle(vehicle_id)) if(AIAI.sellVehicle(vehicle_id, "unprofitable")) counter++;
		}
	}
	Info(counter + " vehicle(s) sold.");
}
