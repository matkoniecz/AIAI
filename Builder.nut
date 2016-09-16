class Builder
{
	cost = null;
	AIAI_instance = null;
	desperation = 0;
	retry_limit = 2;
	pathfinding_time_limit = 10;
	blacklisted_vehicles = AIList();
	blacklisted_engine_wagon_combination = [];
};


function Builder::ValuateProducer(ID, cargo)
{
	if (!AIIndustry.IsValidIndustry(ID)) {
		return -1;
	}
	local base = AIIndustry.GetLastMonthProduction(ID, cargo);
	base *= (100-AIIndustry.GetLastMonthTransportedPercentage(ID, cargo));
	if (AIIndustry.GetLastMonthTransportedPercentage(ID, cargo) == 0) {
		base *= 3;
	}
	base *= AICargo.GetCargoIncome(cargo, 10, 50);
	base = AdjustForScenarios(ID, cargo, base);
	if (!AIIndustryType.ProductionCanIncrease(AIIndustry.GetIndustryType(ID))) {
		base/=2;
	}
	if (base!=0) {
		if (AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(ID))) {
			base += 10000;
		}
	}
	return base;
}

function Builder::AdjustForScenarios(ID, cargo, base){
	return AdjustForNoCarGoal(ID, cargo, base);
}

function Builder::AdjustForNoCarGoal(ID, cargo, base){
	if (g_no_car_goal.IsGoalCargo(cargo, true) == false) {
		Info(AICargo.GetCargoLabel(cargo) + " is not goal cargo");
		return base;
	}
	Info(AICargo.GetCargoLabel(cargo));
	local bonus_percent = 10;
	bonus_percent += PortionOfAvailableLoanInPercents() / 5;
	if (AICompany.GetLoanAmount() == 0) {
		bonus_percent += 200;
	}
	local my_company = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
	if (AICompany.CURRENT_QUARTER != AICompany.EARLIEST_QUARTER) {
		bonus_percent += AICompany.GetQuarterlyIncome(my_company, AICompany.CURRENT_QUARTER+1) / 4000;
	}
	//Info(part_of_available_loan_in_percents + " part_of_available_loan_in_percents");
	//Info(bonus_percent + " bonus_percent");
	base *= (100+bonus_percent)/100;
	return base;
}

function Builder::ValuateConsumer(industry_id, cargo, score)
{
	if (!AIIndustry.IsValidIndustry(industry_id)) {
		return -1;
	}
	local industry_name = AIIndustry.GetName(industry_id);
	if (AIIndustry.GetStockpiledCargo(industry_id, cargo)==0) {
		score *= 2;
	}
	if (IsConnectedIndustry(industry_id, cargo)) {
		score *= 7;
	}
	local industry_type_id = AIIndustry.GetIndustryType(industry_id);
	if (!AIIndustryType.IsValidIndustryType(industry_id)) {
		return -1; //industry closed after first check in this function
	}
	local industry_type_name = AIIndustryType.GetName(industry_type_id);
	local list = AIIndustryType.GetProducedCargo(industry_type_id);
	if (list.Count() == 0) {
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
	AIAI_instance = parent_init;
	desperation = desperation_init;
	cost = 1;
}

function Builder::GetCost()
{
	return cost;
}

function Builder::GetPathfindingLimit()
{
	return pathfinding_time_limit + desperation * 2;
}

const MAX_AMOUNT_OF_PROCESSABLE_INDUSTRIES = 80;
function Builder::GetLimitedIndustryList()
{
	local list = AIIndustryList()
	list.Valuate(AIIndustry.GetDistanceManhattanToTile, AIAI_instance.root_tile)
	list.KeepBottom(MAX_AMOUNT_OF_PROCESSABLE_INDUSTRIES);
	return list;
}

function Builder::GetLimitedIndustryList_CargoAccepting(cargo)
{
	local list = AIIndustryList_CargoAccepting(cargo)
	list.Valuate(AIIndustry.GetDistanceManhattanToTile, AIAI_instance.root_tile)
	list.KeepBottom(MAX_AMOUNT_OF_PROCESSABLE_INDUSTRIES/10);
	return list;
}

function Builder::GetLimitedIndustryList_CargoProducing(cargo)
{
	local list = AIIndustryList_CargoProducing(cargo)
	list.Valuate(AIIndustry.GetDistanceManhattanToTile, AIAI_instance.root_tile)
	list.KeepBottom(MAX_AMOUNT_OF_PROCESSABLE_INDUSTRIES/10);
	return list;
}

function Builder::IsConsumerOK(industry_id)
{
	if (AIIndustry.IsValidIndustry(industry_id)==false) {
		return false; //industry closed during preprocessing
	}
	return true;
}

function Builder::IsProducerOK(industry_id)
{
	local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(industry_id));
	if (cargo_list==null) {
		return false;
	}
	if (cargo_list.Count()==0) {
		return false;
	}
	if (AIIndustry.IsValidIndustry(industry_id)==false) {
		return false; //industry closed during preprocessing
	}
	return true;
}