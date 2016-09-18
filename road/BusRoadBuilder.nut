class BusRoadBuilder extends RoadBuilder
{
}

function BusRoadBuilder::IsAllowed() {
	if (0 == AIAI.GetSetting("use_buses")) {
		Info("Buses are disabled in AIAI settings.")
		return false;
	}
	return RoadBuilder.IsAllowed();
}

function BusRoadBuilder::Possible() {
	if (!this.IsAllowed()) {
		return false;
	}
	if (this.cost <= 1) {
		Info("no cost estimation for a bus route connection is available.");
	} else {
		Info("estimated cost of a bus connection: " + this.cost + " /  available funds: " + GetAvailableMoney() + " (" + (GetAvailableMoney()*100/this.cost) + "%)");
	}
	return this.cost<GetAvailableMoney();
}

function BusRoadBuilder::GetNiceRandomTown(location) {
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

function BusRoadBuilder::FindBusPair() {
	trasa.start = GetRatherBigRandomTown();
	trasa.end = GetNiceRandomTown(AITown.GetLocation(trasa.start))
	trasa.cargo = Helper.GetPAXCargo();
	//supporting trams require improvements to BuildDepotNextToRoad in SuperLib
	//if(AIRoad.IsRoadTypeAvailable(AIRoad.ROADTYPE_TRAM)){
	//	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
	//}

	if (trasa.end == null) {
		return false;
	}
	Info("From " + AITown.GetName(trasa.start) + "  to " +  AITown.GetName(trasa.end));
	trasa.cargo = Helper.GetPAXCargo();

	trasa = TownCargoStationAllocator(trasa);

	if (!((trasa.first_station.location==null)||(trasa.second_station.location==null))) {
		trasa.start_tile = AITown.GetLocation(trasa.start);
		trasa.end_tile = AITown.GetLocation(trasa.end);
		local cargo_production_at_first_location = AITile.GetCargoAcceptance(trasa.first_station.location, trasa.cargo, 1, 1, 3);
		local cargo_production_at_second_location = AITile.GetCargoAcceptance(trasa.second_station.location, trasa.cargo, 1, 1, 3);
		trasa.production = min(cargo_production_at_first_location, cargo_production_at_second_location);
		trasa.type = RouteType.townCargo;
		
		trasa = FindEngineForRoute(trasa);
		if (trasa.engine == null) {
			return false;
		} else {
			return true;
		}
	}
	return false;
}

function BusRoadBuilder::Go() {
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	trasa = Route();

	for(local i=0; i<retry_limit; i++) {
		Info("Scanning for bus route");
		if (!this.FindBusPair()) {
			Info("Nothing found!");
			cost = 0;
			return false;
		}
		Info("Scanning for bus route completed [ " + desperation + " ] ");
		if (this.PrepareRoute()) {
			Info("   Contruction started on correct route.");
			if (this.ConstructionOfRVRoute()) {
				return true;
			} else {
				//TODO - industries?
				trasa.forbidden_industries.AddItem(trasa.start, 0);
			}
		} else {
			if (trasa.start == null) {
				return false;
			} else {
				trasa.forbidden_industries.AddItem(trasa.start, 0);
			}
		}
	}
	return false;
}