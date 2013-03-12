class PAXAirBuilder extends AirBuilder
{
}

function PAXAirBuilder::Possible()
{
if(!IsAllowedPAXPlane())return false;
Info("estimated cost of a PAX airplane connection: " + this.cost + " / available funds: " + GetAvailableMoney());
return this.cost<GetAvailableMoney();
}

function PAXAirBuilder::Go()
{
	cost = this.CostEstimation();
	Info("Trying to build an airport route (city version)");
	if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_METROPOLITAN))
		{
		return true;
		}
	else if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_LARGE))
		{
		return true;
		}
	else if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_COMMUTER))
		{
		return true;
		}
	else if(BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_SMALL))
		{
		return true;
		}
	cost=0;
	return false;
}

function PAXAirBuilder::BuildAirportRouteBetweenCitiesWithAirportTypeSet(airport_type)
{	
if(!AIAirport.IsValidAirportType(airport_type))return false;
local engine=this.FindAircraft(airport_type, GetPassengerCargoId(), 3, GetAvailableMoney());
if(engine==null)
    {
	Info("Unfortunatelly no suitable aircraft found");
	return false;
	}
	
ProvideMoney();

local tile_1 = this.FindSuitableAirportSpotInTown(airport_type, 0);
if (tile_1 < 0) 
	{
	Info("Unfortunatelly no suitable airport location");
	return false;
	}
	local tile_2 = this.FindSuitableAirportSpotInTown(airport_type, tile_1);
	if (tile_2 < 0) {
		{
		Info("Unfortunatelly no suitable pair of airport locations");
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
		rodzic.SetStationName(tile_2, "");
		return false;
	}
	rodzic.SetStationName(tile_1, "");
	rodzic.SetStationName(tile_2, "");
	
local airport_x = AIAirport.GetAirportWidth(airport_type);
local airport_y = AIAirport.GetAirportHeight(airport_type);
local airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

	Info("Airports constructed on distance " + AIMap.DistanceManhattan(tile_1, tile_2) + " but effective distanse is: " + GetEffectiveDistanceBetweenAirports(tile_1, tile_2));
	local dystans = this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2);
	local speed = AIEngine.GetMaxSpeed(engine);
	local production_at_first_airport = AITile.GetCargoAcceptance(tile_1, GetPassengerCargoId(), airport_x, airport_y, airport_rad);
	local production_at_second_airport = AITile.GetCargoAcceptance(tile_2, GetPassengerCargoId(), airport_x, airport_y, airport_rad);
	local production = min(production_at_first_airport, production_at_second_airport);
	local licznik = this.HowManyAirplanes(dystans, speed, production, engine);
	for(local i=0; i<licznik; i++) 
		{
		while(!this.BuildPassengerAircraftWithRand(tile_1, tile_2, engine, GetPassengerCargoId()))
			{
			Error("PAX aircraft construction failed due to " + AIError.GetLastErrorString()+".")
			if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
				{
				return true;
				}
			rodzic.Maintenance();
			AIController.Sleep(500);
			}
		Info("We have " + i + " from " + licznik + " aircrafts.");
		if(!this.IsItPossibleToAddBurden(AIStation.GetStationID(tile_1), tile_2, engine) || 
		   !this.IsItPossibleToAddBurden(AIStation.GetStationID(tile_2), tile_1, engine))
			{
			Info("Interupted, too many airplanes");
			return true;
			}
		}

	Info("Done building a route");
	return true;
}
