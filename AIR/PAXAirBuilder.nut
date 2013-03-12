class PAXAirBuilder extends AirBuilder
{
}

function PAXAirBuilder::Possible()
{
if(!IsAllowedPAXPlane())return false;
Warning("$: " + this.cost + " / " + GetAvailableMoney());
return this.cost<GetAvailableMoney();
}

function PAXAirBuilder::Go()
{
cost = this.CostEstimation();
Info("Trying to build an airport route (city version)");
local airport_type = (AIAirport.IsValidAirportType(AIAirport.AT_LARGE) ? AIAirport.AT_LARGE : AIAirport.AT_SMALL);
if(airport_type==AIAirport.AT_LARGE)
   {
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
   }
cost=0;
return false;
}

function PAXAirBuilder::BuildAirportRouteBetweenCitiesWithAirportTypeSet(airport_type)
{	
if(!AIAirport.IsValidAirportType(airport_type))return false;
local engine=this.FindAircraft(airport_type, rodzic.GetPassengerCargoId(), 3, GetAvailableMoney());
	
if(engine==null)
    {
	Info("Unfortunatelly no suitable aircraft found");
	return false;
	}
	
ProvideMoney();

local tile_1 = this.FindSuitableAirportSpotInTown(airport_type, 0);
if (tile_1 < 0) 
   {
   return false;
   }
	local tile_2 = this.FindSuitableAirportSpotInTown(airport_type, tile_1);
	if (tile_2 < 0) {
	   {
       if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
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
		return false;
	}
	
	Info("Airports constructed on distance " + AIMap.DistanceManhattan(tile_1, tile_2));
	local dystans = AITile.GetDistanceManhattanToTile(tile_1, tile_2);
	local speed = AIEngine.GetMaxSpeed(engine);
	local licznik = this.IleSamolotow(dystans, speed);
	for(local i=0; i<licznik; i++) 
	   {
	   for(local i=0; !this.BuildPassengerAircraftWithRand(tile_1, tile_2, engine, rodzic.GetPassengerCargoId()); i++)
          {
	  Error("Aircraft construction failed due to " + AIError.GetLastErrorString()+".")
		  if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
		     {
			 return true;
			 }
		  rodzic.Konserwuj();
		  AIController.Sleep(100);
		  }
  	   }

	Info("Done building a route");
	return true;
}
