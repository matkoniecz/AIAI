function LogInFindPair(string)
{
	if (AIAI.GetSetting("log_in_find_pair") == 1) {
		Info(string);
	}
}

function FindPairWrapped (route, builder)
{
	local industry_list = builder.GetLimitedIndustryList();
	local choice = Route();
	local count = industry_list.Count();
	Info("Finding the best route started! Industry list count: " + count);
	local best = 0;
	local new;
	local counter = 1;
	for (route.start = industry_list.Begin(); industry_list.HasNext(); route.start = industry_list.Next()) {
		LogInFindPair(counter++ + " of " + industry_list.Count());
		if (builder.IsProducerOK(route.start) == false) {
			LogInFindPair("bad producer " + AIIndustry.GetName(route.start));
			continue;
		}
		if (route.forbidden_industries.HasItem(route.start)) {
			LogInFindPair("banned producer");
			continue;
		}
		local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(route.start));
		for (route.cargo = cargo_list.Begin(); cargo_list.HasNext(); route.cargo = cargo_list.Next()) {
			route.production = AIIndustry.GetLastMonthProduction(route.start, route.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (route.start, route.cargo))/100;
			if (IsConnectedIndustry(route.start, route.cargo)) {
				LogInFindPair("connected producer");
				continue;
			}
			local industry_list_accepting_current_cargo = builder.GetLimitedIndustryList_CargoAccepting(route.cargo);
			local base = builder.ValuateProducer(route.start, route.cargo);
			if (industry_list_accepting_current_cargo.Count()>0) {
				for(route.end = industry_list_accepting_current_cargo.Begin(); industry_list_accepting_current_cargo.HasNext(); route.end = industry_list_accepting_current_cargo.Next()) {
					if (route.forbidden_industries.HasItem(route.end)) {
						LogInFindPair("banned consumer");
						continue;
					}
					if (!builder.IsConsumerOK(route.end)) {
						LogInFindPair("bad consumer");
						continue; 
					}
					new = builder.ValuateConsumer(route.end, route.cargo, base);
					local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(route.end), AIIndustry.GetLocation(route.start)); 
					new *= builder.distanceBetweenIndustriesValuator(distance); 
					if (AITile.GetCargoAcceptance (AIIndustry.GetLocation(route.end), route.cargo, 1, 1, 4) == 0) {
						LogInFindPair("cargo is not accepted");
						continue;
					}
					if (new>best) {
						route.start_tile = AIIndustry.GetLocation(route.start);
						route.end_tile = AIIndustry.GetLocation(route.end);
						route = builder.IndustryToIndustryStationAllocator(route);
						if (route.StationsAllocated()) {
							route = builder.FindEngineForRoute(route);
							if (route.engine != null) {
								best = new;
								choice.start_tile = route.start_tile;
								choice.end_tile = route.end_tile;
								choice = clone route;
								choice.first_station = clone route.first_station;
								choice.second_station = clone route.second_station;
								choice.first_station.is_city = false;
								choice.second_station.is_city = false;
								choice.track_type = route.track_type;
							} else {
								LogInFindPair("no viable engine");
							}
						} else {
							LogInFindPair("unallocated stations");
						}
					}
				}
			} else {
				route.end = builder.GetNiceRandomTown(AIIndustry.GetLocation(route.start));
				if (route.end == null) {
					continue;
					LogInFindPair("no available town");
				}
				local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(route.end), AIIndustry.GetLocation(route.start));
				new = ValuateConsumerTown(route.end, route.cargo, base);
				new *= builder.distanceBetweenIndustriesValuator(distance);
				new*=2; /*if (AIIndustry.GetStockpiledCargo(x, route.cargo)==0)*/
				if (new>best) {
					route.start_tile = AIIndustry.GetLocation(route.start);
					route.end_tile = AITown.GetLocation(route.end);
					route = builder.IndustryToCityStationAllocator(route)
					if (route.StationsAllocated()) {
						route = builder.FindEngineForRoute(route);
						if (route.engine != null) {
							best = new;
							choice.start_tile = route.start_tile;
							choice.end_tile = route.end_tile;
							choice = clone route;
							choice.first_station = clone route.first_station;
							choice.second_station = clone route.second_station;
							choice.start_tile = AIIndustry.GetLocation(route.start);
							choice.end_tile = AITown.GetLocation(route.end);
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
		route.OK = false;
		return route;
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