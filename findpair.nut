function LogInFindPair(string) {
	if (AIAI.GetSetting("log_in_find_pair") == 1) {
		Info(string);
	}
}

function DiscardProducer(idea, builder){
	if (builder.IsProducerOK(idea.start) == false) {
		LogInFindPair("bad producer " + AIIndustry.GetName(idea.start));
		return true;
	}
	if (idea.forbidden_industries.HasItem(idea.start)) {
		LogInFindPair("banned producer");
		return true;
	}
	return false;
}

function DiscardConsumer(idea, builder){
	if (idea.forbidden_industries.HasItem(idea.end)) {
		LogInFindPair("banned consumer");
		return true;
	}
	if (!builder.IsConsumerOK(idea.end)) {
		LogInFindPair("bad consumer");
		return true;
	}
	if (AITile.GetCargoAcceptance(AIIndustry.GetLocation(idea.end), idea.cargo, 1, 1, 4) == 0) { //hardcoded 4 is hack. most likely.
		LogInFindPair("cargo is not accepted");
		return true;
	}
	return false;
}

function SendCargoToIndustry(cargo, builder){
	//TODO - some industries may accept passengers, that is not a good reason to send all passengers to them...
	local industry_list_accepting_current_cargo = builder.GetLimitedIndustryList_CargoAccepting(cargo);
	return industry_list_accepting_current_cargo.Count() > 0;
}

function FindPairWrapped(idea, builder) {
	local industry_list = builder.GetLimitedIndustryList();
	local choice = Route(); //data about the best found route
	Info("Finding the best route started! Count of considered industries: " + industry_list.Count());
	local best = 0; //score for best already found route
	local new; //score for currently tested route
	local counter = 1;
	for (idea.start = industry_list.Begin(); industry_list.HasNext(); idea.start = industry_list.Next()) {
		LogInFindPair(counter + " of " + industry_list.Count());
		counter++;
		if(DiscardProducer(idea, builder)){
			continue;
		}
		local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(idea.start));
		for (idea.cargo = cargo_list.Begin(); cargo_list.HasNext(); idea.cargo = cargo_list.Next()) {
			if (IsConnectedIndustry(idea.start, idea.cargo)) {
				LogInFindPair("connected producer");
				continue;
			}
			idea.production = AIIndustry.GetLastMonthProduction(idea.start, idea.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (idea.start, idea.cargo))/100;
			local base = builder.ValuateProducer(idea.start, idea.cargo);
			if(SendCargoToIndustry(idea.cargo, builder)) {
				local industry_list_accepting_current_cargo = builder.GetLimitedIndustryList_CargoAccepting(idea.cargo);
				for(idea.end = industry_list_accepting_current_cargo.Begin(); industry_list_accepting_current_cargo.HasNext(); idea.end = industry_list_accepting_current_cargo.Next()) {
					if(DiscardConsumer(idea, builder)){
						continue;
					}
					new = builder.ValuateConsumer(idea.end, idea.cargo, base);
					local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(idea.end), AIIndustry.GetLocation(idea.start)); 
					new *= builder.distanceBetweenIndustriesValuator(distance); 
					if (new>best) {
						idea.start_tile = AIIndustry.GetLocation(idea.start);
						idea.end_tile = AIIndustry.GetLocation(idea.end);
						idea = builder.IndustryToIndustryStationAllocator(idea);
						if (idea.StationsAllocated()) {
							idea = builder.FindEngineForRoute(idea);
							if (idea.engine != null) {
								best = new;
								choice = idea.proper_clone();
								choice.first_station.is_city = false;
								choice.second_station.is_city = false;
							} else {
								LogInFindPair("no viable engine");
							}
						} else {
							LogInFindPair("unallocated stations");
						}
					}
				}
			} else {
				idea.end = builder.GetNiceRandomTown(AIIndustry.GetLocation(idea.start));
				if (idea.end == null) {
					LogInFindPair("no available town");
					continue;
				}
				local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(idea.end), AIIndustry.GetLocation(idea.start));
				new = ValuateConsumerTown(idea.end, idea.cargo, base);
				new *= builder.distanceBetweenIndustriesValuator(distance);
				new*=2; /*if (AIIndustry.GetStockpiledCargo(x, idea.cargo)==0)*/
				if (new>best) {
					idea.start_tile = AIIndustry.GetLocation(idea.start);
					idea.end_tile = AITown.GetLocation(idea.end);
					idea = builder.IndustryToCityStationAllocator(idea)
					if (idea.StationsAllocated()) {
						idea = builder.FindEngineForRoute(idea);
						if (idea.engine != null) {
							best = new;
							choice = idea.proper_clone();
							choice.first_station.is_city = false;
							choice.second_station.is_city = true;
						} else {
							LogInFindPair("no viable engine");
						}
					} else {
						LogInFindPair("unallocated stations");
					}
				}
			}
		}
	}
	if (best == 0) {
		Warning("Findpair found nothing usable.");
		idea.OK = false;
		return idea;
	} else {
		Info(best/1000 + "k points");
	}
	choice.OK = true;
	if (AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(choice.start))) {
		choice.type = RouteType.rawCargo;
	} else {
		choice.type = RouteType.processedCargo;
	}
	return choice;
}