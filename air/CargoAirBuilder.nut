class CargoAirBuilder extends AirBuilder
{
	trasa = null;
}

function CargoAirBuilder::IsAllowed() {
	if (0 == AIAI.GetSetting("cargo_plane")) {
		Info("Cargo planes are disabled in AIAI settings.")
		return false;
	}
	return AirBuilder.IsAllowed();
}

function CargoAirBuilder::Possible() {
	if (!this.IsAllowed()) return false;
	return this.cost<GetAvailableMoney();
}

function CargoAirBuilder::Go() {
	ProvideMoney();
	Info("Trying to build an airport route from industry");
	trasa = Route();
	trasa.budget = GetAvailableMoney();
	trasa = this.FindPair(trasa);
	cost = trasa.demand;

	Info("Trying to build an airport route from industry - scanning completed");

	if (!trasa.OK) {
		Info("Airport cargo route failed");
		return false;
		}
	else{
		Info("Airport cargo route found");
		}

	if (!AIAirport.BuildAirport(trasa.first_station.location, trasa.station_size, AIStation.STATION_NEW)) return false;
	if (!AIAirport.BuildAirport(trasa.second_station.location, trasa.station_size, AIStation.STATION_NEW)) {
		AIAirport.RemoveAirport(trasa.first_station.location);
		return false;
		}
	AIAI_instance.SetStationName(trasa.first_station.location, "");
	AIAI_instance.SetStationName(trasa.second_station.location, "");
	for(local i=0; i<trasa.engine_count; i++) {
		while(!this.BuildCargoAircraft(trasa.first_station.location, trasa.second_station.location, trasa.engine, trasa.cargo, "null")) {
			Error("Cargo aircraft construction failed due to " + AIError.GetLastErrorString()+".")
			if (AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) {
				return true;
				}
			AIAI_instance.Maintenance();
			AIController.Sleep(500);
			}
		Info("We have " + i + " from " + trasa.engine_count + " aircrafts.");
		}
	return true;
}
function CargoAirBuilder::FindPair(route) {
	return FindPairWrapped(route, this);
}

function CargoAirBuilder::GetNiceRandomTown(location) {
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

