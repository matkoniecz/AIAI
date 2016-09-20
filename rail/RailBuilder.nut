class RailPathProject
{
	start = null;
	end = null;
	ignore = null;
}

class RailBuilder extends Builder{
	trasa = Route();
	path = null;
	ignore = null;

	//[start_tile, tile_before_start]
	start = array(2);
	end = array(2);
};

require("RAILchoochoopathfinder.nut");
require("RailBuilderPassingLanes.nut")

class tiles
{
	a = null;
	b = null;
}

class RailwayStation extends Station
{
	platform_count = null;
	railway_tracks = null; 

	function BuildRailwayTracks(first, last)
	{
		if (railway_tracks == null) {
			return true;
		}
		for(local x = 0; x < railway_tracks.len(); x++) {
			if (first == railway_tracks[x][0] || last == railway_tracks[x][0]) {
				for(local i = 0; i < railway_tracks[x][1].len(); i++) {
					if (!AIRail.BuildRail(railway_tracks[x][1][i][0], railway_tracks[x][1][i][1], railway_tracks[x][1][i][2])) {
						Error(AIError.GetLastErrorString() + " - RailwayStation::BuildRailwayTracks");
						if (AIAI.GetSetting("debug_signs_about_failed_railway_contruction")) {
							AISign.BuildSign(railway_tracks[x][1][i][0], "a+");
							AISign.BuildSign(railway_tracks[x][1][i][1], "b+");
							AISign.BuildSign(railway_tracks[x][1][i][2], "c+");
							AIController.Break("failed railway construction"); 
						}
						Error(i + "BuildRailwayTracks failure");
						return false;
					}
				}
			}
		}
		return true;
	}

	function RemoveRailwayTracks(first, last)
	{
		if (railway_tracks == null) {
			return true;
		}
		for(local x = 0; x < railway_tracks.len(); x++) {
			if (first == railway_tracks[x][0] || last == railway_tracks[x][0]) {
				for(local i = 0; i < railway_tracks[x][1].len(); i++) {
					if (!AIRail.RemoveRail(railway_tracks[x][1][i][0], railway_tracks[x][1][i][1], railway_tracks[x][1][i][2])) {
						Error(AIError.GetLastErrorString() + " - RailwayStation::RemoveRailwayTracks");
						if (AIAI.GetSetting("debug_signs_about_failed_railway_contruction")) {
							AISign.BuildSign(railway_tracks[x][1][i][0], "a-");
							AISign.BuildSign(railway_tracks[x][1][i][1], "b-");
							AISign.BuildSign(railway_tracks[x][1][i][2], "c-");
							AIController.Break("failed railway destruction"); 
						}
						Error(i + "RemoveRailwayTracks failure");
						return false;
					}
				}
			}
		}
		return true;
	}
}

function RailBuilder::Maintenance() 
{
	if (AIStationList(AIStation.STATION_TRAIN).Count() == 0) {
		return;
	}
	local new_trains = this.AddTrains();
	if (new_trains != 0) {
		Info(new_trains + " new train(s)");
	}
	this.TrainReplace();
}

function RailBuilder::AddTrainsToThisStation(station, cargo) {
	if (!IsItNeededToImproveThatNoRawStation(station, cargo)) {
		return 0;
	}
	if (AgeOfTheYoungestVehicle(station) <= 110) {
		return 0;
	}
	Info("Train station " +AIBaseStation.GetName(station) + " have underservised " + AICargo.GetCargoLabel(cargo));
	local vehicle_list=AIVehicleList_Station(station);
	local how_many = vehicle_list.Count();
	vehicle_list.Valuate(IsForSellUseTrueForInvalidVehicles);
	vehicle_list.KeepValue(0);
	if (how_many != vehicle_list.Count()) {
		Info("wait for sell");
		return 0;
	}
	if (vehicle_list.Count()==0) {
		Warning("Dead station");
		return 0;
	}
	local max_train_count=LoadDataFromStationNameFoundByStationId(station, "{}");
	if (how_many >= max_train_count) {
		Warning("max_train_count = " + max_train_count + " <= how_many = " + how_many);
		return 0;
	}
	vehicle_list.Valuate(AIBase.RandItem);
	vehicle_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	local original = vehicle_list.Begin();
	if (AIVehicle.GetCapacity(original, cargo) == 0) {
		Error(AIVehicle.GetName(original) + " have no capacity for waiting cargo on station.");
		Error("It was probably a refit accident.");
		Error("Train engine was refittable but company in the past was unable to afford it attracting unwanted cargo.");
		Error("Now it changed and cargo is surprised.");
		Info("Aborting purchase of new trains to carry delusional cargo.");
		return 0;
	}
	local location_of_processed_station = AIStation.GetLocation(station);
	local location_of_load_station = GetLoadStationLocation(original)
	assert(location_of_processed_station == location_of_load_station);
	if (AIVehicle.GetProfitLastYear(original) + AIVehicle.GetProfitThisYear(original) <0) {
		Warning("Unprofitable leader");
		return 0;
	}
	if (HowManyVehiclesFromThisStationAreNotMoving(station) != 0) {
		Info("Traffic jam");
		return 0;
	}
	if (!AICargoList_StationAccepting(GetUnloadStationId(original)).HasItem(cargo)) {
		if (AIAI.GetSetting("other_debug_signs")) {
			AISign.BuildSign(GetUnloadStationLocation(original), "ACCEPTATION STOPPED");
		}
		return 0;
	}
	if (this.copyVehicle(original, cargo )) {
		return 1;
	}
	return 0;
}
function RailBuilder::AddTrains() {
	local how_many = 0;
	local cargo_list=AICargoList();
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) {
		local station_list=AIStationList(AIStation.STATION_TRAIN);
		for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next()) {
			how_many += this.AddTrainsToThisStation(station, cargo);
		}
	}
	return how_many;
}


function RailBuilder::copyVehicle(main_vehicle_id, cargo) {
	Info("Copying " + AIVehicle.GetName(main_vehicle_id))
	if (!AIVehicle.IsValidVehicle(main_vehicle_id)) {
		return false;
	}

	local depot_tile = GetDepotLocation(main_vehicle_id);
	if (depot_tile == null) {
		return false;
	}
	local loadStationId = GetLoadStationId(main_vehicle_id);
	local limit = LoadDataFromStationNameFoundByStationId(loadStationId, "{}");
	if (AIVehicleList_SharedOrders(main_vehicle_id).Count() < limit) {
		local vehicle_id = AIVehicle.CloneVehicle(depot_tile, main_vehicle_id, true);
		if (AIVehicle.IsValidVehicle(vehicle_id)) {
			if (AIVehicle.StartStopVehicle (vehicle_id)) {
				return true;
			}
		}
	}   
	return false;
}

function RailBuilder::TrainReplaceOnThisStation(station_id) {
	local vehicle_list=AIVehicleList_Station(station_id);
	local max_train_count=LoadDataFromStationNameFoundByStationId(station_id, "{}")
	if (vehicle_list.Count() > max_train_count) {
		return; //replacing all trains at the same time may double train count on route, what may result in deadlock
	}
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()) {
		if (IsForSell(vehicle_id) != false) {
			continue;
		}
		local cargo_list = AICargoList();
		local max = 0;
		local max_cargo;
		for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) {
			if (AIVehicle.GetCapacity(vehicle_id, cargo)>max) {
				max = AIVehicle.GetCapacity(vehicle_id, cargo);
				max_cargo = cargo;
			}
		}
		local route_data = Route();
		route_data.cargo = max_cargo;
		route_data.station_size = this.GetStationSize(GetLoadStationLocation(vehicle_id));
		route_data.depot_tile = GetDepotLocation(vehicle_id);
		route_data.track_type = AIRail.GetRailType(GetLoadStationLocation(vehicle_id));
		route_data = RailBuilder.FindTrain(route_data);
		local engine = route_data.engine[0];
		local wagon = route_data.engine[1];
		
		if (engine != null && wagon != null ) {
			local new_speed = this.GetMaxSpeedOfTrain(engine, wagon);
			local old_engine = AIVehicle.GetEngineType(vehicle_id);
			local old_wagon = AIVehicle.GetWagonEngineType(vehicle_id, 0);
			local old_speed = this.GetMaxSpeedOfTrain(old_engine, old_wagon);
			local cost = AIEngine.GetPrice(engine)+10*AIEngine.GetPrice(wagon);
			//TODO build engine, compare also running cost and capacity
			
			if (new_speed > old_speed && cost*2 < GetAvailableMoney()) {
				Info(new_speed + " > " + old_speed)
				local train = null;
				train = this.BuildTrain(route_data, "replacing", false);
				if (train != null) {
					if (AIOrder.ShareOrders(train, vehicle_id)) {
						gentleSellVehicle(vehicle_id, "replaced");
					}
				}
			}
		}
	}
}

function RailBuilder::TrainReplace() {
	local station_list = AIStationList(AIStation.STATION_TRAIN);
	if (station_list.Count() == 0) {
		return;
	}
	local i = 0;
	for (local station_id = station_list.Begin(); station_list.HasNext(); station_id = station_list.Next()) {
		local vehicle_list=AIVehicleList_Station(station_id);
		if (vehicle_list.Count()==0) {
			continue;
		}
		local front_vehicle = vehicle_list.Begin();
		if ( station_id != GetLoadStationId(front_vehicle)) {
			continue;
		}
		i++;
		RailBuilder.TrainReplaceOnThisStation(station_id);
	}
}

function RailBuilder::GetStationSize(station_tile) {
	if (AIRail.GetRailStationDirection(station_tile) == AIRail.RAILTRACK_NE_SW) { //x_is_constant__horizontal
		local direction = AIRail.RAILTRACK_NE_SW;
		for(local i = 0; true; i++) {
			local checked_tile = station_tile + AIMap.GetTileIndex(i, 0);
			if (AIStation.GetStationID(checked_tile) != AIStation.GetStationID(station_tile)) {
				return i;
			}
			if (AIRail.GetRailStationDirection(checked_tile) != direction) {
				return i;
			}
		}
	} else {
		local direction = AIRail.RAILTRACK_NW_SE;
		for(local i = 0; true; i++) {
			local checked_tile = station_tile + AIMap.GetTileIndex(0, i);
			if (AIStation.GetStationID(checked_tile) != AIStation.GetStationID(station_tile)) {
				return i;
			}
			if (AIRail.GetRailStationDirection(checked_tile) != direction) {
				return i;
			}
		}
	}
}

function RailBuilder::GetMaxSpeedOfTrain(engine, wagon) {
	if (engine == null || wagon == null) {
		return 0;
	}
	local speed_wagon = AIEngine.GetMaxSpeed(wagon);
	local speed_engine = AIEngine.GetMaxSpeed(engine);
	if (speed_wagon == 0) {
		return speed_engine;
	}
	return min(speed_wagon, speed_engine);
}

function RailBuilder::RailwayLinkConstruction(path) {
	AIRail.SetCurrentRailType(trasa.track_type); 
	return DumbBuilder(path);
}

function RailBuilder::DumbRemover(path, goal) {
	Warning("DumbRemover after " + AIError.GetLastErrorString());
	local prev = null;
	local prevprev = null;
	while (path != null) {
		if (AIAI.GetSetting("debug_signs_about_failed_railway_contruction")) {
			AISign.BuildSign(path.GetTile(), "*");
		}
		if (prevprev != null) {
			if (prev==goal) {
				return true;
			}
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

class allowedConnections
{
	track = null;
	legal_prev = null;
	legal_next = null;
	constructions = null;
}

function RailBuilder::RetryCheck(non_critical_errors) {
	if (non_critical_errors != null) {
		for(local i = 0; i<non_critical_errors.len(); i++) {
			if (non_critical_errors[i].error == AIError.GetLastError() && non_critical_errors[i].retry_count>0) {
				non_critical_errors[i].retry_count--;
				Info("Waiting " + non_critical_errors[i].retry_time_wait + " due to " + AIError.GetLastErrorString() + "(" + non_critical_errors[i].retry_count + ")");
				AIController.Sleep(non_critical_errors[i].retry_time_wait);
				//AIAI_instance.Maintenance();
				//this caused problems:
				// - with measuring cost of contructed route
				// - builder may run in TestMode
				return true;
			}
		}
	}
	return false;
}
function RailBuilder::DumbBuilder(path, non_critical_errors = [{error = AIError.ERR_VEHICLE_IN_THE_WAY, retry_count = 4, retry_time_wait = 50}]) {
	Info("DumbBuilder");
	local copy = path;
	local prev = null;
	local prevprev = null;
	while (path != null) {
		if (prevprev != null) {
			if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
				if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
					local status = false;
					while(!status) {
						if (AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev)) {
							status = true;
						} else {
							Info("Failed tunnel")
							if (!this.RetryCheck(non_critical_errors)) {
								RunDumbRemoverIfNotInTestMode(copy, prev);
								return false;
							}
						}
					}
				} else {
					local status = false;
					while(!status) {
						if (AIAI_instance.BuildBridge(AIVehicle.VT_RAIL, prev, path.GetTile())) {
							status = true;
						} else {
							Info("Failed bridge")
							if (!this.RetryCheck(non_critical_errors)) {
								RunDumbRemoverIfNotInTestMode(copy, prev);
								return false;
							}
						}
					} 
				}
				prevprev = prev;
				prev = path.GetTile();
				path = path.GetParent();
			} else { //AIMap.DistanceManhattan(prev, path.GetTile()) <= 1
				local status = false;
				while(!status) {
					if (AIRail.BuildRail(prevprev, prev, path.GetTile())) {
						status = true;
					} else {
						Info("Failed rail");
						if (!this.RetryCheck(non_critical_errors)) {
							RunDumbRemoverIfNotInTestMode(copy, prev);
							return false;
						}
					}
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

function RunDumbRemoverIfNotInTestMode(path, prev){
	if(IsTestModeEnabled()){
		return;
	}
	RunDumbRemoverIfNotInTestMode(copy, prev);
}

function RailBuilder::GetCostOfRoute(path) {
	local costs = AIAccounting();
	costs.ResetCosts ();

	/* Exec Mode */
	local test = AITestMode();
	/* Test Mode */

	if (this.DumbBuilder(path)) {
		return costs.GetCosts();
	} else {
		return null;
	}
}

function RailBuilder::GetWeightOfEngine(engine, cargo) {
	local weight = AIEngine.GetWeight(engine);
	local capacity = max(AIEngine.GetCapacity(engine), 0);
	if (AICargo.IsFreight(cargo)) {
		weight += capacity * AIGameSettings.GetValue("vehicle.freight_trains");
	}
	return weight;
}

function RailBuilder::BuildTrainButNotWithThisEngineWagonCombination(route, name_of_train, engine, wagon, recover_from_failed_engine) {
	Info("Failed to combine '" + AIEngine.GetName(engine) +"' and '" + AIEngine.GetName(wagon) + "':" + AIError.GetLastErrorString() +" *^@@*")
	blacklisted_engine_wagon_combination.append([engine, wagon])
	Warning("blacklisted '" + AIEngine.GetName(engine) +"' and '" + AIEngine.GetName(wagon) + "' combination'")
	return this.BuildTrainRecoverAfterBlacklisting(route, name_of_train, recover_from_failed_engine)
}

function RailBuilder::BuildTrainButNotWithThisVehicle(route, name_of_train, bad_vehicle, recover_from_failed_engine) {
	Info("Failed to build '" + AIEngine.GetName(bad_vehicle) +"':" + AIError.GetLastErrorString() +" **@@*")
	blacklisted_vehicles.AddItem(bad_vehicle, 0)
	Warning("blacklisted "+AIEngine.GetName(bad_vehicle))
	return this.BuildTrainRecoverAfterBlacklisting(route, name_of_train, recover_from_failed_engine)
}

function RailBuilder::BuildTrainRecoverAfterBlacklisting(route, name_of_train, recover_from_failed_engine) {
	Helper.SellAllVehiclesStoppedInDepots()
	if (!recover_from_failed_engine) {
		return null;
	}
	Warning("trying to find a new train")
	route = RailBuilder.FindTrain(route);
	if (route.engine[0] != null && route.engine[1] != null ) {
		return this.BuildTrain(route, name_of_train, true);
	}
	return null;
}

function RailBuilder::AttachWagonToTheTrain(newWagon, engineId) {
	assert(AIVehicle.IsValidVehicle(newWagon));
	assert(AIVehicle.GetNumWagons(newWagon) > 0);
	assert(AIVehicle.IsValidVehicle(engineId));
	assert(AIVehicle.GetNumWagons(engineId) > 0);
	if (!(AIVehicle.GetVehicleType(engineId) == AIVehicle.VT_RAIL)) {
		abort("AIVehicle.GetVehicleType(engineId) != AIVehicle.VT_RAIL (" + AIVehicle.GetVehicleType(engineId) +")");
	}
	if (!AIVehicle.MoveWagon(newWagon, 0, engineId, 0)) {
		Info("Couldn't join wagon to train: " + AIError.GetLastErrorString());
		if (AIError.GetLastError() == AIError.ERR_PRECONDITION_FAILED) {
			abort("ERR_PRECONDITION_FAILED in MoveWagon");
		}
		AIVehicle.SellVehicle(newWagon);
		return false
	}
	return true
}

function RailBuilder::BuildTrain(route, name_of_train, recover_from_failed_engine) {
	local costs = AIAccounting();
	costs.ResetCosts ();
	local bestEngine = route.engine[0];
	local bestWagon = route.engine[1];
	local depotTile = route.depot_tile;
	local stationSize = route.station_size;
	local cargoIndex = route.cargo;

	Info("BuildTrain (" + AIEngine.GetName(bestEngine) + " + " + AIEngine.GetName(bestWagon) + ")")

	if (!AIEngine.IsBuildable(bestEngine)) {
		return this.BuildTrainButNotWithThisVehicle(route, name_of_train, bestEngine, recover_from_failed_engine)
	}
	if (!AIEngine.IsBuildable(bestWagon)) {
		return this.BuildTrainButNotWithThisVehicle(route, name_of_train, bestWagon, recover_from_failed_engine)
	}
	if (AIEngine.GetPrice(bestEngine) + AIEngine.GetPrice(bestWagon) > AICompany.GetBankBalance(AICompany.COMPANY_SELF)) {
		Warning("Not enough money to buy train.");
		return null;
	}

	local engineId = AIVehicle.BuildVehicle(depotTile, bestEngine)
	if (!AIVehicle.IsValidVehicle(engineId)) {
		return this.BuildTrainButNotWithThisVehicle(route, name_of_train, bestEngine, recover_from_failed_engine)
	}

	AIVehicle.SetName(engineId, "in construction");
	AIVehicle.RefitVehicle(engineId, cargoIndex);

	local max_number_of_wagons = 1000;
	local maximal_weight = AIEngine.GetMaxTractiveEffort(bestEngine) * 3;
	local capacity_of_engine = AIVehicle.GetCapacity(engineId, cargoIndex);
	local weight_of_engine = AIEngine.GetWeight(bestEngine) + (capacity_of_engine * Helper.GetWeightOfOneCargoPiece(cargoIndex));
	local length_of_engine = AIVehicle.GetLength(engineId);
	local weight_of_wagon;
	local length_of_wagon = null;

	for(local i = 0; i<max_number_of_wagons; i++) {
		if (i==1) {
			weight_of_wagon = AIEngine.GetWeight(bestWagon);
			weight_of_wagon += (AIVehicle.GetCapacity(engineId, cargoIndex) - capacity_of_engine) * Helper.GetWeightOfOneCargoPiece(cargoIndex);
			if (AIGameSettings.GetValue("vehicle.train_acceleration_model")==1) {
				max_number_of_wagons = (maximal_weight-weight_of_engine)/weight_of_wagon;
			}
			length_of_wagon = AIVehicle.GetLength(engineId) - length_of_engine;
			Info("length_of_wagon "+length_of_wagon+"; length_of_engine "+length_of_engine+";");
			local length_limit = stationSize
			if (length_limit > AIGameSettings.GetValue("max_train_length")) {
				length_limit = AIGameSettings.GetValue("max_train_length");
			}
			length_limit = (length_limit*16-length_of_engine)/length_of_wagon;
			if (max_number_of_wagons > length_limit) {
				max_number_of_wagons = length_limit;
			}
			Info("Limit:"+max_number_of_wagons);
			if (max_number_of_wagons == 0) {
				max_number_of_wagons = 1;
				Error("WTF, it was supposed to be wagonless train!");
			}
		}
		local newWagon = AIVehicle.BuildVehicle(depotTile, bestWagon);
		if (!AIVehicle.IsValidVehicle(newWagon)) {
			Info("Failed to build wagon '" + AIEngine.GetName(bestWagon) +"':" + AIError.GetLastErrorString());
		}
		AIVehicle.RefitVehicle(newWagon, cargoIndex);

		if (!RailBuilder.AttachWagonToTheTrain(newWagon, engineId)) {
			if (i==0) {
				Warning("And it was the first one!");
				return this.BuildTrainButNotWithThisEngineWagonCombination(route, name_of_train, bestEngine, bestWagon, recover_from_failed_engine);
			}
		}
	}

	if (AIVehicle.GetNumWagons(engineId) == 0) {
		abort("it was not supposed to happen - wagonless train");
	}

	//multiplier: for weak locos it may be necessary to merge multiple trains ito one (2*loco + 10*wagon, instead of loco+5 wagons)
	//without that travelling uphill would be ridiculously slow
	//multiplier = how many trains are merged into one
	local multiplier = min(GetAvailableMoney()/costs.GetCosts(), route.station_size*16/AIVehicle.GetLength(engineId))
	multiplier--; //one part of train is already constructed
	for (local x=0; x<multiplier; x++) {
		local newengineId = AIVehicle.BuildVehicle(route.depot_tile, bestEngine);
		AIVehicle.RefitVehicle(newengineId, route.cargo);
		AIVehicle.MoveWagon(newengineId, 0, engineId, 0);
		for(local i = 0; i<max_number_of_wagons; i++) {
			if (AIVehicle.GetLength(engineId)>route.station_size*16) {
				AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1);
				break;
			}
			local newWagon = AIVehicle.BuildVehicle(route.depot_tile, bestWagon);        
			AIVehicle.RefitVehicle(newWagon, cargoIndex);
			if (!AIVehicle.MoveWagon(newWagon, 0, engineId, AIVehicle.GetNumWagons(engineId)-1)) {
				Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
			}
		}
	}
	if (AIVehicle.GetCapacity(engineId, route.cargo) == 0) {
		return null;
	}
	if (AIVehicle.StartStopVehicle(engineId)) {
		AIVehicle.SetName(engineId, name_of_train);
		return engineId;
	}
	Warning("StartStopVehicle failed! Evil newgrf?");
	if (!AIVehicle.IsValidVehicle(engineId)) {
		Error(depotTile, "Please, post savegame on ttforums - http://tinyurl.com/ottdaiai (or send mail on matkoniecz@gmail.com)");
		abort("Sth happened with train (invalid id)!");
	}
	if (error==AIVehicle.ERR_VEHICLE_NO_POWER) {
		Error(depotTile, "Please, post savegame on ttforums - http://tinyurl.com/ottdaiai (or send mail on matkoniecz@gmail.com)");
		abort("Sth happened with train (no power)!");
	}
	Info("Brake van?")
	AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1)
	Info("Last wagon sold")
	
	local brake_van_id = Rail.GetBrakeVan(AIRail.GetCurrentRailType());
	if (brake_van_id != null) {
		Info("found a brake van!");
		local newWagon = AIVehicle.BuildVehicle(route.depot_tile, brake_van_id);
		if (!AIVehicle.MoveWagon(newWagon, 0, engineId, AIVehicle.GetNumWagons(engineId)-1)) {
			Error("Couldn't join brake van to train: " + AIError.GetLastErrorString());
		}
	} else {
		Error("No brake van on the current track (" + AIRail.GetCurrentRailType() + ").");
	}

	if (AIVehicle.StartStopVehicle(engineId)) {
		AIVehicle.SetName(engineId, name_of_train);
		return engineId;
	}
	Error("Train refuses to start, please report this problem.");
	return this.BuildTrainButNotWithThisVehicle(route, name_of_train, bestEngine, recover_from_failed_engine);
}

function RailBuilder::SignalPath(path) {
	SignalPathAdvanced(path, 0, null, 999999)
}

function RailBuilder::SignalPathAdvanced(path, skip, end, signal_count_limit) //from AdmiralAI
{
	local i = 0;
	local prev = null;
	local prevprev = null;
	local prevprevprev = null;
	local prevprevprevprev = null;
	local tiles_skipped = 50-(skip)*10;
	local lastbuild_tile = null;
	local lastbuild_front_tile = null;
	while (path != null && path != end ) {
		if (prevprev != null) {
			if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
				tiles_skipped += 10 * AIMap.DistanceManhattan(prev, path.GetTile());
			} else {
				if (path.GetTile() - prev != prev - prevprev) {
					tiles_skipped += 5;
				} else {
					tiles_skipped += 10;
				}
				//AISign.BuildSign(path.GetTile(), "tiles skipped: "+tiles_skipped)
				if (AIRail.GetSignalType(prev, path.GetTile()) != AIRail.SIGNALTYPE_NONE) tiles_skipped = 0;
				//AISign.BuildSign(path.GetTile(), tiles_skipped)
				if (tiles_skipped > 55 && path.GetParent() != null && signal_count_limit>0) {
					if (AIRail.BuildSignal(path.GetTile(), prev, AIRail.SIGNALTYPE_PBS_ONEWAY)) {
						i++;
						tiles_skipped = 0;
						lastbuild_tile = prev;
						lastbuild_front_tile = path.GetTile();
						signal_count_limit--;
					}
				}
			}
		}
		prevprevprevprev = prevprevprev;
		prevprevprev = prevprev;
		prevprev = prev;
		prev = path.GetTile();
		path = path.GetParent();
	}
	/* Although this provides better signalling (trains cannot get stuck half in the station),
	* it is also the cause of using the same track of rails both ways, possible causing deadlocks.
	if (tiles_skipped < 50 && lastbuild_tile != null) {
		AIRail.RemoveSignal(lastbuild_tile, lastbuild_front_tile);
	}*/

	if (AIRail.GetSignalType(prevprev, prevprevprev) == AIRail.SIGNALTYPE_NONE) {
		AIRail.BuildSignal(prevprev, prevprevprev, AIRail.SIGNALTYPE_PBS_ONEWAY );
	}
	if (AIRail.GetSignalType(prevprevprev, prevprevprevprev) == AIRail.SIGNALTYPE_NONE && AIRail.GetSignalType(prevprev, prevprevprev) == AIRail.SIGNALTYPE_NONE) {
		AIRail.BuildSignal(prevprevprev, prevprevprevprev, AIRail.SIGNALTYPE_PBS_ONEWAY);
	}
	//AISign.BuildSign(prevprev, "prevprev "+AIRail.GetSignalType(prevprev, prevprevprev))
	//AISign.BuildSign(prevprevprev, "prevprevprev")
	//AISign.BuildSign(prevprevprevprev, "prevprevprevprev")
	return i;
}

function RailBuilder::TrainOrders(engineId) {
	if (trasa.type == RouteType.rawCargo) {
		AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE );
		AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD );
	} else if (trasa.type == RouteType.processedCargo) {
		AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE );
		AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD );
	} else if (trasa.type == RouteType.townCargo) {
		AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE );
		AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.OF_FULL_LOAD_ANY | AIOrder.OF_NON_STOP_INTERMEDIATE );
	} else {
		abort("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
	}
}

function RailBuilder::ValuatorRailType(rail_type_id) {
	local engines = AIEngineList(AIVehicle.VT_RAIL);
	engines.Valuate(AIEngine.IsWagon);
	engines.RemoveValue(1);  
	engines.Valuate(AIEngine.IsBuildable);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.HasPowerOnRail, rail_type_id);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.CanRunOnRail, rail_type_id);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.GetMaxSpeed);
	engines.Sort(AIList.SORT_BY_VALUE, false); //descending

	local max_speed=engines.GetValue(engines.Begin());
	local rail_max_speed = AIRail.GetMaxSpeed(rail_type_id);

	if (rail_max_speed != 0 && max_speed > rail_max_speed) {
		max_speed = rail_max_speed;
	}
	return max_speed*5-AIRail.GetBuildCost(rail_type_id, AIRail.BT_TRACK);
}

function RailBuilder::GetRailTypeList() //modified //from DenverAndRioGrande
{
	local railTypes = AIRailTypeList();
	if (railTypes.Count() == 0) {
		Warning("No rail types!");
		return null;
	}
	railTypes.Valuate(AIRail.IsRailTypeAvailable);
	railTypes.KeepValue(1);
	if (railTypes.Count() == 0) {
		Warning("No available rail types!");
		return null;
	}

	railTypes.Valuate(this.ValuatorRailType);
	railTypes.Sort(AIList.SORT_BY_VALUE, false); //descending

	return railTypes;
}

function RailBuilder::FindTrain(trasa)//from DenverAndRioGrande
{
	local wagon = RailBuilder.FindBestWagon(trasa.cargo, trasa.track_type);
	local engine = null;
	if (wagon != null) {
		engine = RailBuilder.FindBestEngine(wagon, trasa.station_size, trasa.cargo, trasa.track_type);
	}
	trasa.engine = array(2);
	trasa.engine[0] = engine;
	trasa.engine[1] = wagon;
	return trasa;
}

function RailBuilder::FindEngineForRoute(trasa)//from DenverAndRioGrande
{
	local railTypes = GetRailTypeList();
	if (railTypes != null) {
		/*
		for(local rail_type = railTypes.Begin(); railTypes.HasNext(); rail_type = railTypes.Next()) {
			local max_speed = AIRail.GetMaxSpeed(rail_type);
			local cost = AIRail.GetBuildCost(rail_type, AIRail.BT_TRACK);
			Info("Railtype " + AIRail.GetName(rail_type) + "("+rail_type+") with " + max_speed + " max speed and cost of " + cost + " has " + (max_speed*5-cost) + " points.");
			}
		*/

		for(local rail_type = railTypes.Begin(); railTypes.HasNext(); rail_type = railTypes.Next()) {
			local max_speed = AIRail.GetMaxSpeed(rail_type);
			local cost = AIRail.GetBuildCost(rail_type, AIRail.BT_TRACK);
			Info("Railtype "+ AIRail.GetName(rail_type) + " ( " +rail_type+" ) with " + max_speed + " max speed and cost of " + cost)// + " has " + (max_speed*5-cost) + " points.");

			trasa.track_type = rail_type;
			trasa = RailBuilder.FindTrain(trasa);
			if (trasa.engine[0] != null && trasa.engine[1] != null ) {
				return trasa;
			}
		}
	} else {
		Error("No tracks!")
	}
	Error("No engine!")
	trasa.engine = null;
	return trasa;
}

function RailBuilder::FindWagons(cargoIndex, track_type)//from DenverAndRioGrande
{
	local wagons = AIEngineList(AIVehicle.VT_RAIL);
	wagons.Valuate(AIEngine.IsWagon);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.IsBuildable);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.CanRefitCargo, cargoIndex);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.CanRunOnRail, track_type);
	wagons.RemoveValue(0);
	if (wagons.Count() == 0) {
		Error("No wagons can pull or be refitted to this cargo (" + AICargo.GetCargoLabel(cargoIndex) + ") on the current track (" + AIRail.GetCurrentRailType() + ").");
	}
	return wagons;
}

function RailBuilder::WagonValuator(engineId)//from DenverAndRioGrande
{
	return  AIEngine.GetCapacity(engineId) * AIEngine.GetMaxSpeed(engineId);
}

function RailBuilder::IsThisThingBanned(engine, cargo_id, blacklisted_vehicles) {
	return blacklisted_vehicles.HasItem(engine);
}

function RailBuilder::FindBestWagon(cargoId, track_type)//from DenverAndRioGrande
{   
	local wagons = RailBuilder.FindWagons(cargoId, track_type);
	if (wagons.Count()==0) {
		return null;
	}
	wagons.Valuate(this.IsThisThingBanned, cargoId, blacklisted_vehicles);
	wagons.RemoveValue(1);

	wagons.Valuate(RailBuilder.WagonValuator);
	return wagons.Begin();
}

function RailBuilder::RemoveBlacklistedEnginesFromList(list_of_engines, wagonId, cargoId, track_type){
	local blacklisted_engines = AIList();
	//Info("===================================")
	foreach(i, val in blacklisted_engine_wagon_combination) {
		if (val[1] == wagonId) {
			blacklisted_engines.AddItem(val[0], 0)
		}
		//Info(AIEngine.GetName(val[0]) + " " + AIEngine.GetName(val[1]))
	}
	list_of_engines.Valuate(this.IsThisThingBanned, cargoId, blacklisted_engines);
	list_of_engines.RemoveValue(1);

	list_of_engines.Valuate(this.IsThisThingBanned, cargoId, blacklisted_vehicles);
	list_of_engines.RemoveValue(1);
	return list_of_engines;
}

function RailBuilder::GetEngineListExceptClearlyBad(wagonId, cargoId, track_type){
	local engines = AIEngineList(AIVehicle.VT_RAIL);
	engines.Valuate(AIEngine.IsWagon);
	engines.RemoveValue(1);

	engines.Valuate(AIEngine.IsBuildable);
	engines.RemoveValue(0);

	engines = RemoveBlacklistedEnginesFromList(engines, wagonId, cargoId, track_type)

	engines.Valuate(AIEngine.CanPullCargo, cargoId);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.HasPowerOnRail, track_type);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.CanRunOnRail, track_type);
	engines.RemoveValue(0);

	return engines;
}

function RailBuilder::EngineCostValuator(engineId){
	local multiplier = 10;
	if(AIEngine.GetMaxTractiveEffort(engineId) < 100) {
		multiplier = 10*100/AIEngine.GetMaxTractiveEffort(engineId);
	}
	//AIEngine.GetRunningCost gives the running cost of a vehicle per year.
	return (AIEngine.GetPrice(engineId) + AIEngine.GetRunningCost(engineId)) * multiplier;
}


function RailBuilder::FindBestEngine(wagonId, trainsize, cargoId, track_type)//from DenverAndRioGrande	
{
	local minHP = 175 * trainsize;

	local speed = AIEngine.GetMaxSpeed(wagonId);
	if (speed == 0) {
		speed = INFINITE_SPEED;
	}

	local engines = GetEngineListExceptClearlyBad(wagonId, cargoId, track_type);

	engines.Valuate(AIEngine.GetPower);	
	engines.Sort(AIList.SORT_BY_VALUE, false);
	
	/*	if (engines.GetValue(engines.Begin()) < minHP ) //no engine can pull the wagon at it's top speed.
		{
		Error("No engine has enough horsepower to pull all the wagons well.");
		}
	else{
		engines.RemoveBelowValue(minHP);
		} TODO: rework engine choosing*/
	

	engines.Valuate(AIEngine.GetMaxSpeed);
	engines.Sort(AIList.SORT_BY_VALUE, false);
	if (engines.Count()==0) {
		return null;
	}
	if (engines.GetValue(engines.Begin()) < speed ) { //no engine can pull the wagon at it's top speed.
		//Info("No engine has top speed of wagon. Checking Fastest.");
		//Info("The fastest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
		local cash = GetAvailableMoney();
		if (cash > AIEngine.GetPrice(engines.Begin()) * 2 || AIVehicleList().Count() > 10) { //if there are 10 trains, just return the best one and let it fail.
			return engines.Begin();
		} else {
			Warning("The company is poor. Picking a slower, cheaper engine.");
			engines.Valuate(EngineCostValuator);
			engines.Sort(AIList.SORT_BY_VALUE, true);
			Info("The Cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'  is '" + AIEngine.GetName(engines.Begin()) +"'" );
			return engines.Begin();
		}
	}

	engines.RemoveBelowValue(speed);
	engines.Valuate(EngineCostValuator);
	engines.Sort(AIList.SORT_BY_VALUE, true);
	
	Info("The cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
	return engines.Begin();
}

function RailBuilder::ValuateProducer(ID, cargo) {
	if (AIIndustry.GetLastMonthProduction(ID, cargo)<50-4*desperation) {
		return 0; //protection from tiny industries servised by giant trains
	}
	return Builder.ValuateProducer(ID, cargo);
}

function RailBuilder::GetMinimalStationSize() {
	return max(1, min(4 - (desperation/2), AIGameSettings.GetValue("station.station_spread")));
}

function RailBuilder::StationPreparation() 
{
	start = trasa.first_station.connection;
	end = trasa.second_station.connection;
	ignore = [];
	for(local i = 0; i<trasa.first_station.area_blocked_by_station.len(); i++) {
		ignore.append(trasa.first_station.area_blocked_by_station[i]);
		//AISign.BuildSign(trasa.first_station.area_blocked_by_station[i], "!")
	}
	for(local i = 0; i<trasa.second_station.area_blocked_by_station.len(); i++) {
		ignore.append(trasa.second_station.area_blocked_by_station[i]);
		//AISign.BuildSign(trasa.second_station.area_blocked_by_station[i], "!")
	}
}

function RailBuilder::UndoStationConstruction(path) 
{
	local first = path.GetTile();
	local last;
	while (path != null) {
		last = path.GetTile();
		path = path.GetParent();
	}
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	trasa.second_station.RemoveRailwayTracks(first, last);
	trasa.first_station.RemoveRailwayTracks(first, last);
}

function RailBuilder::StationConstruction(path) 
{
	local copy = path;
	local first = path.GetTile();
	local last;
	while (path != null) {
		last = path.GetTile();
		path = path.GetParent();
	}
	path = copy;
	//BuildNewGRFRailStation (TileIndex tile, RailTrack direction, uint num_platforms, uint platform_length, StationID station_id, 
	//						CargoID cargo_id, IndustryType source_industry, IndustryType goal_industry, int distance, bool source_station)
	AIRail.SetCurrentRailType(trasa.track_type);
	local source_industry = null;
	local goal_industry = null;
	if (trasa.first_station.is_city) {
		source_industry = AIIndustryType.INDUSTRYTYPE_TOWN;
	} else {
		source_industry = AIIndustry.GetIndustryType(trasa.start);
	}
	if (trasa.second_station.is_city) {
		goal_industry = AIIndustryType.INDUSTRYTYPE_TOWN;
	} else {
		goal_industry = AIIndustry.GetIndustryType(trasa.end);
	}

	local direction = null

	local distance = AIMap.DistanceManhattan(trasa.first_station.location, trasa.second_station.location);
	local location = trasa.first_station.location
	local platform_count = trasa.first_station.platform_count
	direction = StationDirectionToTrackDirection(trasa.first_station.direction);
	local source = true;
	if(!BuildStation(location, direction, platform_count, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, source)){
			return false;
	}
	
	local location = trasa.second_station.location;
	local platform_count = trasa.second_station.platform_count;
	direction = StationDirectionToTrackDirection(trasa.second_station.direction);
	local source = false;
	if(!BuildStation(location, direction, platform_count, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, source)){
			AITile.DemolishTile(trasa.first_station.location);
			return false;
	}

	if (!trasa.first_station.BuildRailwayTracks(first, last)) {
		this.UndoStationConstruction(path);
		return false;
	}
	if (!trasa.second_station.BuildRailwayTracks(first, last)) {
		this.UndoStationConstruction(path);
		return false;
	}
	return true;
}

function RailBuilder::StationDirectionToTrackDirection(station_direction){
	if (station_direction != StationDirection.x_is_constant__horizontal) {
		return AIRail.RAILTRACK_NE_SW;
	} else {
		return AIRail.RAILTRACK_NW_SE;
	}
	assert(false);
}

function RailBuilder::BuildStation(location, direction, platform_count, station_size, station_id, cargo, source_industry, goal_industry, distance, source) {
	if (!AIRail.BuildNewGRFRailStation(location, direction, platform_count, station_size, station_id, cargo, source_industry, goal_industry, distance, source)) {
		Info("BuildNewGRFRailStation failed - " + AIError.GetLastErrorString());
		if (!AIRail.BuildRailStation(location, direction, platform_count, station_size, station_id)) {
			Warning("BuildRailStation failed - " + AIError.GetLastErrorString());
			return false;
		}
	}
	return true;
}


function RailBuilder::PathFinder(limit) 
{
	local pathfinder = RailPathfinder();
	pathfinder.estimate_multiplier = 3;
	pathfinder.cost.bridge_per_tile = 500;
	pathfinder.cost.tunnel_per_tile = 35;
	pathfinder.cost.diagonal_tile = 35;
	pathfinder.cost.coast = 0;
	pathfinder.cost.level_crossing = 3 * pathfinder.cost.bridge_per_tile + 100;
	pathfinder.cost.turn = 50;
	pathfinder.cost.max_bridge_length = 40;
	pathfinder.cost.max_tunnel_length = 40;

	pathfinder.InitializePath(end, start, ignore);

	path = false;
	local guardian=0;
	local pathfinding_split = 5; //to make maintemance more often - for example plane skipping
	limit = limit*pathfinding_split;
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
		if (AIAI.GetSetting("log_rail_pathfinding_time"))
		AISign.BuildSign(AIMap.GetTileIndex(1, 1), "- "+GetReadableDate() + "[ " + AITile.GetDistanceManhattanToTile(start[0][0], end[0][0]) + "]")
		return false;
	}
	Info("   Rail pathfinder found sth.");
	if (AIAI.GetSetting("log_rail_pathfinding_time"))
	AISign.BuildSign(AIMap.GetTileIndex(1, 1), guardian+" "+GetReadableDate() + "[ " + AITile.GetDistanceManhattanToTile(start[0][0], end[0][0]) + "]")
	return true;
}

function RailBuilder::distanceBetweenIndustriesValuator(distance) {
	if (distance>GetMaxDistance()) return 0;
	if (distance<GetMinDistance()) return 0;

	if (desperation>5) {
		if (distance>100+desperation*60) return 1;
		return 4;
	}

	if (distance>200+desperation*50) return 1;
	if (distance>185) return 2;
	if (distance>170) return 3;
	if (distance>155) return 4;
	if (distance>120) return 3;
	if (distance>80) return 2;
	if (distance>40) return 1;
	return 0;
}

function RailBuilder::GetMinDistance() {
	return 10;
}

function RailBuilder::GetMaxDistance() {
	if (desperation>5) return 100+desperation*75;
	return 250+desperation*50;
}

function RailBuilder::IsAllowed() {
	if (0 == AIAI.GetSetting("use_freight_trains")) {
		Info("Freight trains are disabled in AIAI settings.")
		return false;
	}
	if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL)) {
		Warning("AIs are not allowed to build trains in this game (see advanced settings, section 'Competitors', subsection 'Computer players')!");
		return false;
	}

	local count;
	local veh_list = AIVehicleList();
	veh_list.Valuate(AIVehicle.GetVehicleType);
	veh_list.KeepValue(AIVehicle.VT_RAIL);
	count = veh_list.Count();
	local allowed = AIGameSettings.GetValue("vehicle.max_trains");
	if (allowed==0) {
		Warning("Max train count is set to 0 (see advanced settings, section 'vehicles'). ");
		return false;
	}
	if (count==0) {
		return true;
	}
	if (((count*100)/(allowed))>90) {
		Warning("Max train count is too low to consider more trains (see advanced settings, section 'vehicles'). ");
		return false;
	}
	if ((allowed - count)<5) {
		Warning("Max train count is too low to consider more trains (see advanced settings, section 'vehicles'). ");
		return false;
	}
	return true;
}

function RailBuilder::Possible() {
	if (!this.IsAllowed()) return false;
	if (this.cost <= 1) {
		Info("no cost estimation for a railway connection is available.");
	} else {
		Info("estimated cost of a railway connection: " + this.cost + " /  available funds: " + GetAvailableMoney() + " (" + (GetAvailableMoney()*100/this.cost) + "%)");
	}
	return this.cost<GetAvailableMoney();
}

function RailBuilder::Go() {
	local list_of_rail_types = GetRailTypeList();
	if (list_of_rail_types == null) {
		Error("No suitable railtype!")
		return false;
	}
	//TODO FIXME railtype mess
	//IsGreatPlaceForRailStationRail etc should know which railtype will be used
	//engine selection depends on length of station and is deciding which railtype will be used
	//at least pathfinding happens after this and it is the only affected thing, for now there is now difference in station construction
	//so this bug (for now) is not noticeable in any way, form or shape
	//solution - select railtype and keep it would be worse (aborted constructions) for no gain
	//maybe futureproofing may be done with looking for a new station location if their construction failed?
	AIRail.SetCurrentRailType(list_of_rail_types.Begin());
	for(local i=0; i<2; i++) {
		if (!Possible()) {
			return false;
		}
		Info("Scanning for rail route");
		trasa = this.FindPairForRoute(trasa);  
		if (!trasa.OK) {
			Info("Nothing found!");
			cost = 0;
			return false;
		}
		AIRail.SetCurrentRailType(trasa.track_type);

		Info("Scanning for rail route completed.")
		local main_part_of_message = "Desperation: " + desperation + " cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start);
		if (!trasa.second_station.is_city) {
			Info(main_part_of_message + " End: " + AIIndustry.GetName(trasa.end));
		} else if (trasa.second_station.is_city) {
			Info(main_part_of_message + " End: " + AITown.GetName(trasa.end));
		} else {
			assert(false);
		}
		if (this.PrepareRoute()) {
			Info("   Contruction started on correct route.");
			if (this.ConstructionOfRoute()) {
				Info("   Construction finished.");
				return true;
			} else {
				Info("   Construction failed.");
				trasa.forbidden_industries.AddItem(trasa.start, 0);
			}
		} else {
			Info("   Route preparings failed.");
			if (trasa.start==null) {
				return false;
			} else {
				trasa.forbidden_industries.AddItem(trasa.start, 0);
			}
		}
	}
	return false;
}

function RailBuilder::ConstructionOfRoute() {
	AIRail.SetCurrentRailType(trasa.track_type);
	ProvideMoney();

	if (!this.StationConstruction(path)) {
		Info("   But station construction failed");
		return false;   
	}
	if (!this.RailwayLinkConstruction(path)) {
		Info("   But stopped by error");
		this.UndoStationConstruction(path);
		return false;
	}

	trasa.depot_tile = Rail.BuildDepot(path);

	if (trasa.depot_tile==null) {
		Info("   Depot placement error");
		this.UndoStationConstruction(path)
		this.DumbRemover(path, null)
		return false;
	}

	local new_engine = this.BuildTrain(trasa, "stupid", true);
	if (new_engine == null) {
		this.UndoStationConstruction(path)
		this.DumbRemover(path, null)
		return false;
	}
	this.TrainOrders(new_engine);

	AIAI_instance.SetStationName(trasa.first_station.location, "{1}["+trasa.depot_tile+"]");
	AIAI_instance.SetStationName(trasa.second_station.location, "{1}["+trasa.depot_tile+"]");
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.first_station.location), "[]") == trasa.depot_tile);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.second_station.location), "[]") == trasa.depot_tile);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.first_station.location), "{}") == 1);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.second_station.location), "{}") == 1);

	local max_train_count = this.ConstructionOfPassingLanes(this.GeneratePassingLanes(path));

	Info("   Route constructed!");

	if (max_train_count == 0) {
		max_train_count = 1;
	} else if (max_train_count>=2) {
		max_train_count = 2 + (max_train_count-2)/2;
	}

	AIAI_instance.SetStationName(trasa.first_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
	AIAI_instance.SetStationName(trasa.second_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.first_station.location), "[]") == trasa.depot_tile);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.second_station.location), "[]") == trasa.depot_tile);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.first_station.location), "{}") == max_train_count);
	assert(LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(trasa.second_station.location), "{}") == max_train_count);

	if (max_train_count > 1) {
		new_engine = this.BuildTrain(trasa, "muhahaha", true);
		if (new_engine != null) {
			this.TrainOrders(new_engine);
		}
	}
	return true;
}

function RailBuilder::PrepareRoute() {
	Info("   Rail route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));
	this.StationPreparation();   
	if (!this.PathFinder(this.GetPathfindingLimit())) {
		return false;
	}
	local estimated_cost = this.GetCostOfRoute(path); 
	if (estimated_cost==null) {
		Info("   Pathfinder failed to find correct route.");
		return false;
	}
	Info("Route is OK!")

	estimated_cost+=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);
	estimated_cost+=Money.Inflate(2000) //TODO zamiast 2000 koszt stacji to samo w RV
	cost=estimated_cost;
	if (GetAvailableMoney()<estimated_cost) {
		ProvideMoney();
		if (GetAvailableMoney()<estimated_cost) {
			Warning("too expensivee, we have only " + GetAvailableMoney() + ". And we need " + estimated_cost + " ( " + (GetAvailableMoney()*100/estimated_cost) + "% )");
			return false;
		}
	}
	Info("Route found!");
	return true;
}

function RailBuilder::FindPairForRoute(route) {
	return FindPairWrapped(route, this);
}

function RailBuilder::GetNiceRandomTown(location) {
	local town_list = AITownList();
	town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
	town_list.KeepBelowValue(GetMaxDistance());
	town_list.KeepAboveValue(GetMinDistance());
	town_list.Valuate(AIBase.RandItem);
	town_list.KeepTop(1);
	if (town_list.Count()==0) {
		return null;
	}
	return town_list.Begin();
}


function RailBuilder::IndustryToIndustryStationAllocator(project) {
	project.station_size = AIAI.GetSetting("max_train_station_length");

	local producer = project.start;
	local consumer = project.end;
	local cargo = project.cargo;

	project.first_station.location = null; 
	for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--) {
		project.first_station = this.FindStationProducer(producer, cargo, project.station_size);
		project.second_station = this.FindStationConsumer(consumer, cargo, project.station_size);
		if (project.StationsAllocated()) {
			break;
		}
	}
	project.second_station.location = project.second_station.location;
	return project;
}

function RailBuilder::IndustryToCityStationAllocator(project) {
	project.station_size = AIAI.GetSetting("max_train_station_length");

	project.first_station.location = null; 
	for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--) {
		project.first_station = this.FindStationProducer(project.start, project.cargo, project.station_size);
		project.second_station = this.FindCityConsumerStation(project.end, project.cargo, project.station_size);
		if (project.StationsAllocated()) {
			break;
		}
	}
	project.second_station.location = project.second_station.location;
	return project;
}

function RailBuilder::FindCityConsumerStation(town, cargo, length) {
	return FindCityProducerStation(town, cargo, length, AIAI.GetSetting("max_train_station_platform_count_city_end"))
}

function RailBuilder::FindCityProducerStation(town, cargo, length) {
	return FindCityProducerStation(town, cargo, length, AIAI.GetSetting("max_train_station_platform_count_city_start"))
}

function RailBuilder::FindCityProducerStation(town, cargo, length, platform_count) {
	local radius = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	local tile = AITown.GetLocation(town);
	local list = AITileList();
	local range = Helper.Sqrt(AITown.GetPopulation(town)/100) + 15;
	SafeAddRectangle(list, tile, range);
	list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, radius);
	list.KeepAboveValue(10);
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	return this.FindStationRail(list, length, platform_count); 
}

function RailBuilder::FindStationConsumer(consumer, cargo, length) {
	local radius = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	local list=AITileList_IndustryAccepting(consumer, radius);
	list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, radius);
	list.RemoveValue(0);
	list.Valuate(AIMap.DistanceSquare, trasa.end_tile); //pure eyecandy (station near industry) TODO sort by industry count
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	return this.FindStationRail(list, length, AIAI.GetSetting("max_train_station_platform_count_end_industry"));
}

function RailBuilder::FindStationProducer(producer, cargo, length) {
	local radius = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	local list=AITileList_IndustryProducing(producer, radius);
	list.Valuate(AIMap.DistanceSquare, trasa.start_tile); //pure eyecandy (station near industry) TODO sort by industry count
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	return this.FindStationRail(list, length, AIAI.GetSetting("max_train_station_platform_count_start_industry"));
}

function RailBuilder::FindStationRail(list, length, max_platform_count) {
	local returned = RailwayStation();
	returned.location = null;
	returned.platform_count = 0;
	local current_result;

	for(local station = list.Begin(); list.HasNext(); station = list.Next()) {
		current_result = this.TryToPlaceRailStationHere(station, StationDirection.y_is_constant__vertical, length, max_platform_count)
		if (current_result.platform_count > returned.platform_count) {
			returned = clone(current_result);
		}
		current_result = this.TryToPlaceRailStationHere(station, StationDirection.x_is_constant__horizontal, length, max_platform_count)
		if (current_result.platform_count > returned.platform_count)
		{
			returned = clone(current_result);
		}
	}
	return returned;
}

function RailBuilder::RequestTrackConstruction(platform_count, station_tile, mover, antimover, tile_a_neighbour, tile_b_neighbour, tile_a_real_neighbour, tile_b_real_neighbour) 
{
	/*
	AIController.Sleep(20);
	Helper.ClearAllSigns();
	AISign.BuildSign(station_tile, "station_tile, platform_count: "+platform_count)
	AISign.BuildSign(station_tile+mover, "station_tile+mover")
	AISign.BuildSign(station_tile+antimover, "station_tile+antimover")
	if (tile_a_neighbour != null) AISign.BuildSign(tile_a_neighbour, "tile_a_neighbour")
	if (tile_b_neighbour != null) AISign.BuildSign(tile_b_neighbour, "tile_b_neighbour")
	if (tile_a_real_neighbour != null) AISign.BuildSign(tile_a_real_neighbour, "tile_a_real_neighbour")
	if (tile_b_real_neighbour != null) AISign.BuildSign(tile_b_real_neighbour, "tile_b_real_neighbour")
	*/
	local tile_a = (tile_a_neighbour+tile_a_real_neighbour)/2;
	local tile_b = (tile_b_neighbour+tile_b_real_neighbour)/2;
	local contruction = [[tile_a, []], [tile_b, []]]
	if (tile_a_neighbour != null) {
		contruction[0][1].append([tile_a + antimover, tile_a, tile_a - antimover]);
		contruction[0][1].append([tile_a_neighbour + antimover, tile_a_neighbour, tile_a_neighbour - antimover]);
		contruction[0][1].append([tile_a_neighbour - antimover, tile_a_neighbour, tile_a_neighbour + mover]);
		for(local platform = 1; platform < platform_count; platform++) {
			local tile = tile_a_neighbour + mover * platform;
			//contruction[0][1].append([tile + mover, tile, tile - mover]);
			contruction[0][1].append([tile - mover, tile, tile + antimover]);
			if (platform + 1 < platform_count) {
				contruction[0][1].append([tile - mover, tile, tile + mover]);
			}
		}
	}
	if (tile_b_neighbour != null) {
		contruction[1][1].append([tile_b + antimover, tile_b, tile_b - antimover]);
		contruction[1][1].append([tile_b_neighbour + antimover, tile_b_neighbour, tile_b_neighbour - antimover]);
		contruction[1][1].append([tile_b_neighbour + antimover, tile_b_neighbour, tile_b_neighbour + mover]);
		for(local platform = 1; platform < platform_count; platform++) {
			local tile = tile_b_neighbour + mover * platform;
			contruction[1][1].append([tile - antimover, tile, tile - mover]);
			if (platform + 1 < platform_count) {
				contruction[1][1].append([tile - mover, tile, tile + mover]);
			}
		}
	}
	return contruction
}

function RailBuilder::ForbiddenArea(platform_count, length, station_tile, mover, antimover, tile_first_neighbour, tile_second_neighbour, tile_first, tile_second) 
{	
	local forbidden = []
	if (tile_first != null) {
		forbidden.append(tile_first)
	}
	if (tile_second != null) {
		forbidden.append(tile_second)
	}
	for(local platform = 0; platform < platform_count; platform++) {
		local platform_tile = station_tile + mover * platform;
		for(local tile = platform_tile; tile!=platform_tile+antimover * length; tile+=antimover) {
			forbidden.append(tile);
		}
	}
	if (tile_first_neighbour != null) {
		for(local platform = 0; platform < platform_count; platform++) {
			forbidden.append(tile_first_neighbour + mover * platform);
		}
	}
	if (tile_second_neighbour != null) {
		for(local platform = 0; platform < platform_count; platform++) {
			forbidden.append(tile_second_neighbour + mover * platform);
		}
	}
	return forbidden;
}

function RailBuilder::IsTryToPlaceRailStationHereGoingToCompletelyFail(station_entrance_a, station_entrance_b, railtrack, length, station_tile) {
	//avoid joining with our other station
	if (AIRail.IsRailStationTile(station_entrance_a)) {
		if (AIRail.GetRailStationDirection(station_entrance_a) == railtrack) {
			return true;
		}
	}
	if (AIRail.IsRailStationTile(station_entrance_b)) {
		if (AIRail.GetRailStationDirection(station_entrance_b) == railtrack) {
			return true;
		}
	}

	//avoid pathfinding for a locked station
	if (!(AITile.IsBuildable(station_entrance_a) || AITile.IsBuildable(station_entrance_b))) {
		return true;
	}

	//check station location
	if (!AIRail.BuildRailStation(station_tile, railtrack, 1, length, AIStation.STATION_NEW) ) {
		local error = AIError.GetLastError();
		HandleFailedStationConstruction(station_tile, error);
		if (error != AIError.ERR_NOT_ENOUGH_CASH) {
			return true;
		}
	}
	return false;
}

function RailBuilder::TryToPlaceRailStationHere(station_tile, direction, length, max_platform_count) {
	local returned = RailwayStation();
	returned.location = station_tile;
	returned.direction = direction;
	returned.platform_count = 0;
	returned.railway_tracks = null;
	local test = AITestMode();
	local tile_a = null;
	local tile_b = null;
	local railtrack = null;
	local mover, antimover;

	if (direction == StationDirection.y_is_constant__vertical) {
		tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
		tile_b = station_tile + AIMap.GetTileIndex(length, 0);
		railtrack = AIRail.RAILTRACK_NE_SW;
		returned.connection = [[station_tile, tile_a], [tile_b, tile_b + AIMap.GetTileIndex(-1, 0)]]
		mover = AIMap.GetTileIndex(0, 1)
		antimover = AIMap.GetTileIndex(1, 0)
	} else {
		tile_a = station_tile + AIMap.GetTileIndex(0, -1);
		tile_b = station_tile + AIMap.GetTileIndex(0, length);
		railtrack = AIRail.RAILTRACK_NW_SE
		returned.connection = [[station_tile, tile_a], [tile_b, tile_b + AIMap.GetTileIndex(0, -1)]]
		mover = AIMap.GetTileIndex(1, 0)
		antimover = AIMap.GetTileIndex(0, 1)
	}

	if (IsTryToPlaceRailStationHereGoingToCompletelyFail(tile_a, tile_b, railtrack, length, station_tile)) {
		return returned;
	}
	returned.area_blocked_by_station = this.ForbiddenArea(1, length, station_tile, mover, antimover, null, null, null, null);
	returned.platform_count = 1;
	local achieved = clone(returned);

	local tile_a_neighbour, tile_b_neighbour;

	tile_a -= antimover
	tile_b += antimover
	tile_a_neighbour = tile_a + antimover
	tile_b_neighbour = tile_b - antimover
	local tile_a_real_neighbour = tile_a - antimover
	local tile_b_real_neighbour = tile_b + antimover
	//returned.connection is array of arrays in form [path, path_anchor]
	returned.connection = [[tile_a_real_neighbour, tile_a], [tile_b_real_neighbour, tile_b]]

	if (AIRail.IsRailStationTile(tile_a_neighbour)) {
		if (AIRail.GetRailStationDirection(tile_a_neighbour) == railtrack) {
			return achieved;
		}
	}

	if (AIRail.IsRailStationTile(tile_b_neighbour)) {
		if (AIRail.GetRailStationDirection(tile_b_neighbour) == railtrack) {
			return achieved;
		}
	}
	local i = 2; 
	while (true) {
		local station_status = AIRail.BuildRailStation(station_tile, railtrack, i, length, AIStation.STATION_NEW)
		local error = AIError.GetLastError();
		HandleFailedStationConstruction(station_tile, error);
		if (error == AIError.ERR_NOT_ENOUGH_CASH) station_status == true;
		
		local a_connection_status = true;
		local a_connection_real_status = true;
		local b_connection_status = true;
		local b_connection_real_status = true;
		for(local x=0; x<i; x++) {
			if (!IsTileFlatAndBuildable(tile_a_neighbour + mover * x)) {
				a_connection_status = false;
			}
			if (!IsTileFlatAndBuildable(tile_b_neighbour + mover * x)) {
				b_connection_status = false;
			}
		}
		if (!IsTileFlatAndBuildable(tile_a)) {
			a_connection_status = false;
		}
		if (!IsTileFlatAndBuildable(tile_b)) {
			b_connection_status = false;
		}
		if (!station_status || (!a_connection_status && !b_connection_status) || i > max_platform_count) {
			returned.platform_count = i-1;
			if (returned.platform_count == 1) {
				return achieved;
			} else {
				if (returned.connection.len() == 2) {
					returned.area_blocked_by_station = this.ForbiddenArea(returned.platform_count, length, station_tile, mover, antimover, tile_a_neighbour, tile_b_neighbour, tile_a, tile_b);
				} else {
					if (a_connection_status) {
						returned.area_blocked_by_station = this.ForbiddenArea(returned.platform_count, length, station_tile, mover, antimover, tile_a_neighbour, null, tile_a, null);
					} else {
						returned.area_blocked_by_station = this.ForbiddenArea(returned.platform_count, length, station_tile, mover, antimover, tile_b_neighbour, null, tile_b, null);
					}
				}
				returned.railway_tracks = this.RequestTrackConstruction(returned.platform_count, station_tile, mover, antimover, tile_a_neighbour, tile_b_neighbour, tile_a_real_neighbour, tile_b_real_neighbour)
				return returned;
			}
		}
		if (!a_connection_status && returned.connection.len() == 2) {
			returned.connection = [returned.connection[1]];
		}
		if (!b_connection_status && returned.connection.len() == 2) {
			returned.connection = [returned.connection[0]];
		}
		i++;
	}
	return achieved;
}