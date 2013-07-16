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

function TruckRoadBuilder::ValuateProducer(ID, cargo)
{
	if(AIRoad.GetRoadVehicleTypeForCargo(cargo) != AIRoad.ROADVEHTYPE_TRUCK) {
		return 0;
	}
	return RoadBuilder.ValuateProducer(ID, cargo);
}

function TruckRoadBuilder::FindPair(route)
{
	local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
	local IsProducerOK = null;
	local IsConsumerOK = null;
	local IsConnectedIndustry = IsConnectedIndustry.bindenv(this);
	local ValuateProducer = this.ValuateProducer.bindenv(this);
	local ValuateConsumer = this.ValuateConsumer.bindenv(this);
	local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
	return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
	distanceBetweenIndustriesValuator, IndustryToIndustryTruckStationAllocator, GetNiceRandomTown, IndustryToCityTruckStationAllocator, FindRVForFindPair);
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