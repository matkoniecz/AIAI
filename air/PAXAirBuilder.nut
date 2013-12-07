class PAXAirBuilder extends AirBuilder
{
}

function PAXAirBuilder::IsAllowed()
{
	if (0 == AIAI.GetSetting("PAX_plane")) return false;
	return AirBuilder.IsAllowed();
}

function PAXAirBuilder::Possible()
{
	if (!this.IsAllowed()) return false;
	if (this.cost <= 1) {
		Info("no cost estimation for a PAX airplane connection is available.");
	} else {
		Info("estimated cost of a PAX airplane connection: " + this.cost + " / available funds: " + GetAvailableMoney() + " (" + (GetAvailableMoney()*100/this.cost) + "%)");
	}
	return this.cost<GetAvailableMoney();
}

function PAXAirBuilder::Go()
{
	cost = this.CostEstimation();
	Info("Trying to build an airport route (city version)");
	if (BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_METROPOLITAN)) {
		return true;
		}
	else if (BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_LARGE)) {
		return true;
		}
	else if (BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_COMMUTER)) {
		return true;
		}
	else if (BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_SMALL)) {
		return true;
		}
	cost=0;
	return false;
}

function PAXAirBuilder::BuildAirportRouteBetweenCitiesWithAirportTypeSet(airport_type)
{
	local min_distance = 250 - 4*desperation;
	if (!AIAirport.IsValidAirportType(airport_type)) return false;
	local engine=this.FindAircraft(airport_type, Helper.GetPAXCargo(), 3, GetAvailableMoney(), min_distance);
	if (engine==null) {
		Info("Unfortunately no suitable aircraft found");
		return false;
	}
	
	ProvideMoney();
	local tile_1 = this.FindSuitableAirportSpotInTown(airport_type);
	if (tile_1 < 0) {
		Info("Unfortunately no suitable airport location");
		return false;
	}
	local tile_2 = this.FindSuitableAirportSpotInTown(airport_type, tile_1, AIEngine.GetMaximumOrderDistance(engine));
	if (tile_2 < 0) {		{
		Info("Unfortunatell no suitable pair of airport locations");
		return false;
		}
	}
	
	/* Build the airports for real */
	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
	   return false;
	}
	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		Error("Although the testing told us we could build 2 airports, it still failed on the second airport at tile " + tile_2 + ".");
		//AIAirport.RemoveAirport(tile_1);
		AIAI_instance.SetStationName(tile_2, "");
		return false;
	}
	AIAI_instance.SetStationName(tile_1, "");
	AIAI_instance.SetStationName(tile_2, "");
	
local airport_x = AIAirport.GetAirportWidth(airport_type);
local airport_y = AIAirport.GetAirportHeight(airport_type);
local airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

	Info("Airports constructed on distance " + AIMap.DistanceManhattan(tile_1, tile_2) + " but effective distanse is: " + GetEffectiveDistanceBetweenAirports(tile_1, tile_2));
	local distance = this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2);
	local speed = AIEngine.GetMaxSpeed(engine);
	local production_at_first_airport = AITile.GetCargoAcceptance(tile_1, Helper.GetPAXCargo(), airport_x, airport_y, airport_rad);
	local production_at_second_airport = AITile.GetCargoAcceptance(tile_2, Helper.GetPAXCargo(), airport_x, airport_y, airport_rad);
	local production = min(production_at_first_airport, production_at_second_airport);
	local counter = this.HowManyAirplanes(distance, speed, production, engine);
	for(local i=1; i<=counter; i++) 
		{
		while(!this.BuildPassengerAircraftWithRand(tile_1, tile_2, engine, Helper.GetPAXCargo()))
			{
			Error("PAX aircraft construction failed due to " + AIError.GetLastErrorString()+".")
			if (AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
				{
				return true;
				}
			AIAI_instance.Maintenance();
			AIController.Sleep(500);
			}
		Info("We have " + i + " from " + counter + " aircrafts.");
		if (i < counter)
			{
			if (!this.IsItPossibleToAddBurden(AIStation.GetStationID(tile_1), tile_2, engine) || !this.IsItPossibleToAddBurden(AIStation.GetStationID(tile_2), tile_1, engine))
				{
				Info("Interrupted, too many airplanes");
				return true;
				}
			}
		}

	Info("Done building a route");
	return true;
}
