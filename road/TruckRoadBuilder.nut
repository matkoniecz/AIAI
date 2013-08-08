class TruckRoadBuilder extends RoadBuilder
{
}

function TruckRoadBuilder::IsAllowed()
{
	if(0 == AIAI.GetSetting("use_trucks")) {
		return false;
	}
	return RoadBuilder.IsAllowed();
}

function TruckRoadBuilder::Possible()
{
	if(!this.IsAllowed()) {
		return false;
	}
	if(this.cost <= 1) {
		Info("no cost estimation for a truck connection is available.");
	} else {
		Info("estimated cost of a truck connection: " + this.cost + " /  available funds: " + GetAvailableMoney() + " (" + (GetAvailableMoney()*100/this.cost) + "%)");
	}
	return this.cost < GetAvailableMoney();
}

function TruckRoadBuilder::GetNiceRandomTown(location)
{
	local town_list = AITownList();
	town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
	town_list.KeepBelowValue(GetMaxDistance());
	town_list.KeepAboveValue(GetMinDistance());
	town_list.Valuate(AIBase.RandItem);
	town_list.KeepTop(1);
	if(town_list.Count()==0) {
		return null;
	}
	return town_list.Begin();
}

function TruckRoadBuilder::ValuateProducer(ID, cargo)
{
	if(AIRoad.GetRoadVehicleTypeForCargo(cargo) != AIRoad.ROADVEHTYPE_TRUCK) {
		return 0;
	}
	return RoadBuilder.ValuateProducer(ID, cargo);
}

function TruckRoadBuilder::FindPair(route)
{
	return FindPairWrapped(route, this);
}

function TruckRoadBuilder::IndustryToIndustryStationAllocator(project)
{
	local producer = project.start;
	local consumer = project.end;
	local cargo = project.cargo;
	local maybe_start_station = this.FindProducentStation(producer, cargo);
	local maybe_second_station = this.FindConsumerStation(consumer, cargo);

	project.first_station = maybe_start_station;
	project.second_station = maybe_second_station;

	project.second_station.location = project.second_station.location;

	return RoadBuilder.UniversalStationAllocator(project);
}

function TruckRoadBuilder::IndustryToCityStationAllocator(project)
{
	local start = project.start;
	local town = project.end;
	local cargo = project.cargo;

	local maybe_start_station = this.FindProducentStation(start, cargo);
	local maybe_second_station = this.FindCityStation(town, cargo);

	project.first_station = maybe_start_station;
	project.second_station = maybe_second_station;

	project.second_station.location = project.second_station.location;

	return RoadBuilder.UniversalStationAllocator(project);
}

function TruckRoadBuilder::Go()
{
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	trasa = Route();

	for(local i=0; i<retry_limit; i++) {
		Info("Scanning for truck route");
		trasa = this.FindPair(trasa); 
		if(!trasa.OK) {
			Info("Nothing found!");
			cost = 0;
			return false;
		}

		Info("Scanning for truck route completed [ " + desperation + " ] cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
		if(this.PrepareRoute()) {
			Info("   Contruction started on correct route.");
			if(this.ConstructionOfRVRoute(AIRoad.ROADVEHTYPE_TRUCK)) {
				return true;
			} else {
				trasa.forbidden_industries.AddItem(trasa.start, 0);
			}
		} else {
			Info("   Route preaparings failed.");
			if(trasa.start==null) {
				return false;
			} else {
				trasa.forbidden_industries.AddItem(trasa.start, 0);
			}
		}
	}
	return false;
}