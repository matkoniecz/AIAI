class Builder
{
	cost = null;
	rodzic = null;
	desperation = 0;
	retry_limit = 2;
	pathfinding_time_limit = 10;
	blacklisted_vehicles = AIList();
	blacklisted_engine_wagon_combination = [];
};


function Builder::ValuateProducer(ID, cargo)
{
	if(!AIIndustry.IsValidIndustry(ID)) {
		return -1;
	}
	local base = AIIndustry.GetLastMonthProduction(ID, cargo);
	base *= (100-AIIndustry.GetLastMonthTransportedPercentage (ID, cargo));
	if(AIIndustry.GetLastMonthTransportedPercentage (ID, cargo)==0) {
		base*=3;
	}
	base *= AICargo.GetCargoIncome(cargo, 10, 50);
	if(!AIIndustryType.ProductionCanIncrease(AIIndustry.GetIndustryType(ID))) {
		base/=2;
	}
	if(base!=0) {
		if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(ID))) {
			base += 10000;
		}
	}
	return base;
}
 
function Builder::ValuateConsumer(industry_id, cargo, score)
{
	if(!AIIndustry.IsValidIndustry(industry_id)) {
		return -1;
	}
	local industry_name = AIIndustry.GetName(industry_id);
	if(AIIndustry.GetStockpiledCargo(industry_id, cargo)==0) {
		score *= 2;
	}
	if(IsConnectedIndustry(industry_id, cargo)) {
		score *= 7;
	}
	local industry_type_id = AIIndustry.GetIndustryType(industry_id);
	local industry_type_name = AIIndustryType.GetName(industry_type_id);
	local list = AIIndustryType.GetProducedCargo(industry_type_id);
	if(list.Count() == 0) {
		score /= 2;
	}
	return score;
}

function Builder::ValuateConsumerTown(ID, cargo, score)
{
	return score;
}

function Builder::SetDesperation(new_desperation)
{
	desperation = new_desperation;
}

function Builder::constructor(parent_init, desperation_init)
{
	rodzic = parent_init;
	desperation = desperation_init;
	cost = 1;
}

function Builder::GetCost()
{
	return cost;
}

function Builder::HowManyVehiclesFromThisStationAreNotMoving(station)
{
	local count = 0;
	local vehicle_list=AIVehicleList_Station(station);
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()) {
		if(AIVehicle.GetCurrentSpeed(vehicle_id) == 0) {
			if(AIVehicle.GetState(vehicle_id)!=AIVehicle.VS_AT_STATION) {
				//Warning(AIVehicle.GetName(vehicle_id) + " is waiting");
				count++;
			}
		}
	}
	return count;
}

function Builder::GetPathfindingLimit()
{
	return pathfinding_time_limit + desperation * 2;
}
