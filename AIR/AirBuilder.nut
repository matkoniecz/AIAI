class AirBuilder extends Builder
{
}

function AirBuilder::FindPairIndustryToTownAllocator(route)
{
route.first_station.location = null;
route.second_station.location = null;
return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_METROPOLITAN, route.start);
route.second_station.location = FindSuitableAirportSpotInTheTown(AIAirport.AT_METROPOLITAN, route.end, route.cargo);
route.station_size = AIAirport.AT_METROPOLITAN;
if(route.first_station.location != null && route.second_station.location != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_LARGE, route.start);
route.second_station.location = FindSuitableAirportSpotInTheTown(AIAirport.AT_LARGE, route.end, route.cargo);
route.station_size = AIAirport.AT_LARGE;
if(route.first_station.location != null && route.second_station.location != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_COMMUTER, route.start);
route.second_station.location = FindSuitableAirportSpotInTheTown(AIAirport.AT_COMMUTER, route.end, route.cargo);
route.station_size = AIAirport.AT_COMMUTER;
if(route.first_station.location != null && route.second_station.location != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_SMALL, route.start);
route.second_station.location = FindSuitableAirportSpotInTheTown(AIAirport.AT_SMALL, route.end, route.cargo);
route.station_size = AIAirport.AT_SMALL;
return route;
}

function AirBuilder::FindPairDualIndustryAllocator(route)
{
route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_METROPOLITAN, route.start);
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_METROPOLITAN, route.end, route.cargo);
route.station_size = AIAirport.AT_METROPOLITAN;
if(route.first_station.location != null && route.second_station.location != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_LARGE, route.start);
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_LARGE, route.end, route.cargo);
route.station_size = AIAirport.AT_LARGE;
if(route.first_station.location != null && route.second_station.location != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_COMMUTER, route.start);
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_COMMUTER, route.end, route.cargo);
route.station_size = AIAirport.AT_COMMUTER;
if(route.first_station.location != null && route.second_station.location != null ) return route;

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_SMALL, route.start);
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_SMALL, route.end, route.cargo);
route.station_size = AIAirport.AT_SMALL;
return route;
}


function AirBuilder::FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(airport_type, industry_id)
{
local airport_x, airport_y, airport_rad;
local good_tile = 0;
airport_x = AIAirport.GetAirportWidth(airport_type);
airport_y = AIAirport.GetAirportHeight(airport_type);
airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

local tile_list=AITileList_IndustryProducing (industry_id, airport_rad)

tile_list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
tile_list.KeepValue(1);
return FindSuitableAirportSpotNearIndustryWithAirportType(tile_list, airport_type);
}

function AirBuilder::FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(airport_type, consumer, cargo)
{
local airport_x, airport_y, airport_rad;
local good_tile = 0;
airport_x = AIAirport.GetAirportWidth(airport_type);
airport_y = AIAirport.GetAirportHeight(airport_type);
airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

local list=AITileList_IndustryAccepting(consumer, 3);

list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
list.KeepValue(1);

list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
return FindSuitableAirportSpotNearIndustryWithAirportType(list, airport_type);
}

function AirBuilder::FindSuitableAirportSpotNearIndustryWithAirportType(tile_list, airport_type)
{
	local test = AITestMode();
    for (local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next()) 
		{
		if (AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) return tile;
		}
/* Did we found a place to build the airport on? */
return null;
}

function AirBuilder::FindSuitableAirportSpotInTown(airport_type, center_tile)
{
if(AIAI.GetSetting("deep_debugged_function_calling"))Info("FindSuitableAirportSpotInTown<");
	local airport_x, airport_y, airport_rad;

	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);
	local town_list = AITownList();

	//Info(town_list.Count());
	
	town_list.Valuate(AITown.GetLocation);
	
	town_list.Valuate(this.PopulationWithRandValuator);
	town_list.KeepAboveValue(500-desperacja);

	if (center_tile != 0) {
    town_list.Valuate(AITown.GetDistanceManhattanToTile, center_tile);
	town_list.KeepAboveValue(this.GetMinDistance());    
	town_list.KeepBelowValue(this.GetMaxDistance());    
	}
	
	town_list.Valuate(this.DistanceWithRandValuator, center_tile);
	//TODO - wed³ug dystansu optimum to 500
	   
	town_list.KeepBottom(50);

	//Info(town_list.Count());
	
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next()) {

    	local tile = AITown.GetLocation(town);

		local list = AITileList();
		local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
		SafeAddRectangle(list, tile, range);

		//Info("tiles " + list.Count());
	
		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
		list.KeepValue(1);

		//Info(list.Count());
	
		list.Valuate(rodzic.IsConnectedDistrict);
		list.KeepValue(0);

		//Info(list.Count());
	
		/* Sort on acceptance, remove places that don't have acceptance */
		list.Valuate(AITile.GetCargoAcceptance, rodzic.GetPassengerCargoId(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(50);

		//Info(list.Count());
	
		list.Valuate(AITile.GetCargoAcceptance, rodzic.GetMailCargoId(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(10);

		//Info(list.Count());
	
		/* Couldn't find a suitable place for this town, skip to the next */
		if (list.Count() == 0) continue;
		/* Walk all the tiles and see if we can build the airport at all */
		{
			local good_tile = 0;
			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
				if(!IsItPossibleToHaveAirport(tile, airport_type, AIStation.STATION_NEW))
				   {
				   //Error("BAD " + tile);
				   //AISign.BuildSign(tile, "X");
				   continue;
				   }
			   Error("OK");
				good_tile = tile;
				break;
			}

			/* Did we found a place to build the airport on? */
			if (good_tile == 0) continue;
		}

		AILog.Info("Found a good spot for an airport in town " + town + " at tile " + tile);
if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">FindSuitableAirportSpotInTown");

		return tile;
	}

	AILog.Info("Couldn't find a suitable town to build an airport in");
if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">FindSuitableAirportSpotInTown");
	return -1;
}

function AirBuilder::FindSuitableAirportSpotInTheTown(town, cargo)
{
 	local tile = AITown.GetLocation(town);
	local list = AITileList();
	local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
	SafeAddRectangle(list, tile, range);

	list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
	list.KeepValue(1);

	/* Sort on acceptance, remove places that don't have acceptance */
	list.Valuate(AITile.GetCargoAcceptance, rodzic.GetPassengerCargoId(), airport_x, airport_y, airport_rad);
	list.RemoveBelowValue(50);

	//Info(list.Count());

	list.Valuate(AITile.GetCargoAcceptance, rodzic.GetMailCargoId(), airport_x, airport_y, airport_rad);
	list.RemoveBelowValue(10);

	//Info(list.Count());
	
	/* Couldn't find a suitable place for this town, skip to the next */
	if (list.Count() == 0) return null;
	/* Walk all the tiles and see if we can build the airport at all */
		local good_tile = 0;
		for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
			if(!IsItPossibleToHaveAirport(tile, airport_type, AIStation.STATION_NEW))continue;
		    else
			  {
			  return tile;
			  }
		}

return null;
}

function AirBuilder::GetMaxDistance()
{
return 750+desperacja*50;
}

function AirBuilder::GetMinDistance()
{
return maxi(200-this.desperacja*10, 70);
}

function AirBuilder::GetOptimalDistance()
{
return 400;
}

function AirBuilder::ValuatorDlaCzyJuzZlinkowane(station_id, i)
{
return AITile.GetDistanceManhattanToTile( AIStation.GetLocation(station_id), AIIndustry.GetLocation(i) );
}

function AirBuilder::IsConnectedIndustry(industry, cargo)
{
if(CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_LARGE))return true;
else if(CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_METROPOLITAN))return true;
else if(CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_COMMUTER))return true;
else return CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_SMALL);
}

function AirBuilder::CheckerIsReallyConnectedIndustry(industry, cargo, airport_type)
{
local radius = AIAirport.GetAirportCoverageRadius(airport_type);

local tile_list=AITileList_IndustryProducing(industry, radius);
for (local q = tile_list.Begin(); tile_list.HasNext(); q = tile_list.Next()) //from Chopper 
   {
   local station_id = AIStation.GetStationID(q);
   if(AIAirport.IsAirportTile(q))
   if(AIAirport.GetAirportType(q)==airport_type)
      {
	  local vehicle_list=AIVehicleList_Station(station_id);
	  if(vehicle_list.Count()!=0)
	  if(AIStation.GetStationID(GetLoadStation(vehicle_list.Begin()))==station_id) //czy load jest na wykrytej stacji
	  {
	  if(AIVehicle.GetCapacity(vehicle_list.Begin(), cargo)!=0)//i laduje z tej stacji
	     {
		 return true;
		 }
	  }
	  }
   }
return false;
}

function AirBuilder::CostEstimation()
{
	for(local i=1; i<400; i++)
	   {
	   local enginiatko = AirBuilder.FindAircraft(AIAirport.AT_LARGE, AIAI.GetPassengerCargoId(), 3, 30000*i);
	   if(enginiatko!=null)
	   if(AIEngine.IsBuildable(enginiatko))
	       {
		   return i*30000;
		   }
	   }
}

function AirBuilder::FindEngine(route)
{
route.engine_count = 3;
route.engine = AirBuilder.FindAircraft(route.station_size, route.cargo, route.engine_count = 3, route.budget);
route.demand = AirBuilder.CostEstimation();
return route;
}

function AirBuilder::FindAircraft(airport_type, cargo, ile, balance)
{
//Error(balance+"");
local engine_list = AIEngineList(AIVehicle.VT_AIR);

//Error("engine_list.Count() I " + engine_list.Count());

if(airport_type==AIAirport.AT_SMALL || airport_type==AIAirport.AT_COMMUTER )
	{
	engine_list.Valuate(AIEngine.GetPlaneType);
	engine_list.RemoveValue(AIAirport.PT_BIG_PLANE);
	}

//AILog.Error("engine_list.Count() II " + engine_list.Count());
	
balance-=2000;
if(ile!=0)balance-=2*AIAirport.GetPrice(airport_type);
if(balance<0)return null;
engine_list.Valuate(AIEngine.GetPrice);

if(ile==0) engine_list.KeepBelowValue(balance);
else engine_list.KeepBelowValue(balance/ile);

//AILog.Error("engine_list.Count() III " + engine_list.Count());

engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
engine_list.KeepValue(1);

//AILog.Error("engine_list.Count() IV " + engine_list.Count());

engine_list.Valuate(AIEngine.GetMaxSpeed);
engine_list.KeepAboveValue(100);

//AILog.Error("engine_list.Count() V " + engine_list.Count());

engine_list.Valuate(AIEngine.GetCapacity);
//Error("Desperacja: " + this.desperacja);
engine_list.KeepAboveValue(40 - this.desperacja); //HARDCODED OPTION
engine_list.KeepTop(1);

//AILog.Error("engine_list.Count() VI " + engine_list.Count());

if(engine_list.Count()==0)return null;
return engine_list.Begin();
}

function AirBuilder::BuildPassengerAircraftWithRand(tile_1, tile_2, engine, cargo)
{
if(AIBase.RandRange(2)==1)
   {
   local swap=tile_2;
   tile_2=tile_1;
   tile_1=swap;
   }
return this.BuildPassengerAircraft(tile_1, tile_2, engine, cargo);
}

function AirBuilder::BuildExpressAircraft(tile_1, tile_2, engine, cargo)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);

if(vehicle==-1)return false;

AIOrder.AppendOrder(vehicle, tile_1, 0);
AIOrder.AppendOrder(vehicle, tile_2, 0);
AIVehicle.StartStopVehicle(vehicle);
	
return true;
}

function AirBuilder::BuildPassengerAircraft(tile_1, tile_2, engine, cargo)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);

if(vehicle==-1)return false;

AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_FULL_LOAD_ANY);
AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_FULL_LOAD_ANY);
AIVehicle.StartStopVehicle(vehicle);
	
return true;
}

function AirBuilder::BuildAircraft(tile_1, tile_2, engine, cargo)
{
	/* Build an aircraft */
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	if (!AIEngine.IsBuildable(engine)) {
		return -1;
	}
	
local vehicle = AIVehicle.BuildVehicle(hangar, engine);

	if (!AIVehicle.IsValidVehicle(vehicle)) {
		return -1;
	}

if(!AIVehicle.RefitVehicle(vehicle, cargo)) 
   {
   AILog.Error("Couldn't refit the aircraft " + AIError.GetLastErrorString());
   AIVehicle.SellVehicle(vehicle);
   return -1;
   }
return vehicle;
}

function AirBuilder::HowManyAirplanes(dystans, speed, production, engine)
{
local ile = (3*dystans)/(2*speed);
Error(ile + "&^%");

ile *= 10 * production;
Error(ile + "&^%***********");

ile /= AIEngine.GetCapacity(engine);
Error(ile + "&^%************************");
ile = max(ile, 3);
return ile;
}

function AirBuilder::ValuateProducer(ID, cargo)
{
   local base = AIIndustry.GetLastMonthProduction(ID, cargo);
   base*=(100-AIIndustry.GetLastMonthTransportedPercentage (ID, cargo));
   if(AIIndustry.GetLastMonthTransportedPercentage (ID, cargo)==0)base*=3;
   base*=AICargo.GetCargoIncome(cargo, 10, 50);
   if(base!=0)
	  if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(ID)))
		{
		//base*=3;
	    //base/=2;
		base+=10000;
	    }
return base;
}

function AirBuilder::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
return score;
}

function AirBuilder::distanceBetweenIndustriesValuator(distance)
{
if(distance>GetMaxDistance())return 0;
if(distance<GetMinDistance()) return 0;
return max(1, abs(400-distance)/20);
}


function AirBuilder::BuildCargoAircraft(tile_1, tile_2, engine, cargo, nazwa)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);
if(vehicle==-1)return false;

AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_FULL_LOAD_ANY);
AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NO_LOAD);
AIVehicle.StartStopVehicle(vehicle);
SetNameOfVehicle(vehicle, nazwa);
return true;
}

function AirBuilder::GetNiceRandomTown(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistance());
town_list.KeepAboveValue(GetMinDistance());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0)return null;
return town_list.Begin();
}

function AirBuilder::Konserwuj()
{
this.Skipper();

if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR))return;
local ile;
local veh_list = AIVehicleList();
veh_list.Valuate(GetVehicleType);
veh_list.KeepValue(AIVehicle.VT_AIR);
ile = veh_list.Count();
local allowed = AIGameSettings.GetValue("vehicle.max_aircraft");
if(allowed==ile)return;

this.Uzupelnij();
this.UzupelnijCargo();
}

function AirBuilder::GetEffectiveDistanceBetweenAirports(tile_1, tile_2)
{
local x1 = AIMap.GetTileX(tile_1);
local y1 = AIMap.GetTileY(tile_1);

local x2 = AIMap.GetTileX(tile_2);
local y2 = AIMap.GetTileY(tile_2);

local x_delta = abs(x1 - x2);
local y_delta = abs(y1 - y2);

local longer = max(x_delta, y_delta);
local shorter = min(x_delta, y_delta);

return shorter*99/70 + longer - shorter;
}

function AirBuilder::Burden(tile_1, tile_2, engine)
{
return AIEngine.GetMaxSpeed(engine)*200/(this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2)+50);
}

function AirBuilder::GetBurden(stacja)
{
local total;
local total = 0;
local airlist=AIVehicleList_Station(stacja);
for (local plane = airlist.Begin(); airlist.HasNext(); plane = airlist.Next())
   {
   total += this.Burden(AIOrder.GetOrderDestination (plane, 0), AIOrder.GetOrderDestination (plane, 1), AIVehicle.GetEngineType(plane));
   }
   
return total;
}

function AirBuilder::IsItPossibleToAddBurden(stacja, tile, engine, ile=1)
{
local maksimum;
local total = this.GetBurden(stacja);
local airport_type = AIAirport.GetAirportType(AIStation.GetLocation(stacja));
if(airport_type==AIAirport.AT_LARGE) maksimum = 1500; //1 l¹dowanie miesiêcznie - 250 //6 na du¿ym
if(airport_type==AIAirport.AT_METROPOLITAN ) maksimum = 2000; //1 l¹dowanie miesiêcznie - 250 //6 na du¿ym
if(airport_type==AIAirport.AT_COMMUTER) maksimum = 500; //1 l¹dowanie miesiêcznie - 250 //4 na ma³ym
if(airport_type==AIAirport.AT_SMALL) maksimum = 600; //1 l¹dowanie miesiêcznie - 250 //4 na ma³ym
 
if(AIAI.GetSetting("debug_signs_for_airports_load")) AISign.BuildSign(AIStation.GetLocation(stacja), total + " (" + maksimum + ")");

total+=ile*this.Burden(AIStation.GetLocation(stacja), tile, engine);

return total <= maksimum;
}


function AirBuilder::Uzupelnij()
{
local airport_type;
local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()==0)return;

for (local aktualna = list.Begin(); list.HasNext(); aktualna = list.Next())
   {
   local cargo_list = AICargoList();
   for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
	   if(AIStation.GetCargoWaiting(aktualna, cargo)>100)
       {																						//protection from flood of mail planes
	   if((GetAverageCapacity(aktualna, cargo)*3 < AIStation.GetCargoWaiting(aktualna, cargo) &&  AIStation.GetCargoWaiting(aktualna, cargo)>200) 
	       || AIStation.GetCargoRating(aktualna, cargo)<30 ) //HARDCODED OPTION
		  {
		  //teraz trzeba znaleŸæ lotnisko docelowe
		  local odbiorca = AIStationList(AIStation.STATION_AIRPORT);
		  for (local goal = odbiorca.Begin(); odbiorca.HasNext(); goal = odbiorca.Next())
			 {
 			 local tile_1 = AIStation.GetLocation(aktualna);
			 local tile_2 = AIStation.GetLocation(goal);
			 local airport_type_1 = AIAirport.GetAirportType(tile_1);
			 local airport_type_2 = AIAirport.GetAirportType(tile_2);
			 if((airport_type_1==AIAirport.AT_SMALL || airport_type_2==AIAirport.AT_SMALL)||
			    (airport_type_1==AIAirport.AT_COMMUTER  || airport_type_2==AIAirport.AT_COMMUTER)) 
			    {
				airport_type=AIAirport.AT_SMALL;
				}
			 else
			    {
				airport_type=AIAirport.AT_LARGE;
				}
 			 local airport_x_to = AIAirport.GetAirportWidth(airport_type);
			 local airport_y_to = AIAirport.GetAirportHeight(airport_type);
			 local airport_rad_to = AIAirport.GetAirportCoverageRadius(airport_type);
			
			 local engine=this.FindAircraft(airport_type, cargo, 1, GetAvailableMoney());
		     if(engine==null) 
			    {
				continue;
				}
			ProvideMoney();
			 if(AITile.GetDistanceManhattanToTile(tile_1, tile_2)>100)
			 if(NajmlodszyPojazd(goal)>40)
			 {
				 if(this.IsItPossibleToAddBurden(aktualna, tile_2, engine))
				 if(this.IsItPossibleToAddBurden(goal, tile_1, engine))
				     {
					 if(AITile.GetCargoAcceptance(tile_2, cargo, airport_x_to, airport_y_to, airport_rad_to)>10)
					    {
						if( rodzic.GetPassengerCargoId()==cargo )
						   {
						   if(AITile.GetCargoProduction(tile_2, cargo, airport_x_to, airport_y_to, airport_rad_to)>10)
						   this.BuildPassengerAircraft(tile_1, tile_2, engine, cargo);
						   }
						else if(rodzic.GetMailCargoId()==cargo)
						   {
						   this.BuildExpressAircraft(tile_1, tile_2, engine, cargo);
						   }
						}
				     }
				}
			 }
		   }
	   }   
   }
}

function AirBuilder::UzupelnijCargo()
{
local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()==0)return;

for (local aktualna = list.Begin(); list.HasNext(); aktualna = list.Next())
   {
   local cargo_list = AICargoList();
   for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
	   if(AIStation.GetCargoWaiting(aktualna, cargo)>1)
       {
	   if(cargo != AIAI.GetPassengerCargoId())
	   if(cargo != AIAI.GetMailCargoId())
	   if(IsItNeededToImproveThatStation(aktualna, cargo))
		  {
		 local airport_type = AIAirport.GetAirportType(AIStation.GetLocation(aktualna));
		 if(airport_type==AIAirport.AT_SMALL || airport_type==AIAirport.AT_COMMUTER) 
		    {
			airport_type=AIAirport.AT_SMALL;
			}
		  local vehicle = AIVehicleList_Station(aktualna).Begin();
		  local another_station = AIOrder.GetOrderDestination(vehicle, 0);
		  if(AIStation.GetLocation(aktualna) == another_station) another_station = AIOrder.GetOrderDestination(vehicle, 1);

		  local engine=this.FindAircraft(airport_type, cargo, 1, GetAvailableMoney());
		  if(engine != null)
		  {
		  ProvideMoney();
		  if(IsItPossibleToAddBurden(aktualna, another_station, engine)) this.BuildCargoAircraft(AIStation.GetLocation(aktualna), another_station, engine, cargo, "uzupelniacz");
		  }
		  else 
		  {
		  Error("Aajjajaja");
		  }
		  }
	   }   
   }
}

function CzyToPassengerCargoValuator(veh)
{
   if(AIVehicle.GetCapacity(veh, AIAI.GetPassengerCargoId())>0)return 1;
   return 0;
   }

function AirBuilder::Skip(plane, stacja)
{
for(local i=0; i<AIOrder.GetOrderCount(plane); i++)
   {
   if(AIOrder.GetOrderFlags(plane, i)==AIOrder.AIOF_FULL_LOAD_ANY)
      {
	   AIOrder.SetOrderFlags(plane, i, AIOrder.AIOF_NO_LOAD);
	   AIController.Sleep(10);
	   AIOrder.SetOrderFlags(plane, i, AIOrder.AIOF_FULL_LOAD_ANY);	  	
	  }
   }
}

function AirBuilder::Skipper()
{
local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()==0)return;

local lista = AIList();

for (local aktualna = list.Begin(); list.HasNext(); aktualna = list.Next())
   {
   local pozycja=AIStation.GetLocation(aktualna)
   local airlist=AIVehicleList_Station(aktualna);
   if(airlist.Count()==0)continue;
   local counter=0;
   
   local minimum = 101;
   local pustak = null;
   for (local plane = airlist.Begin(); airlist.HasNext(); plane = airlist.Next())
      {
	  if(AIVehicle.GetState(plane)==AIVehicle.VS_AT_STATION)
	     if(AITile.GetDistanceManhattanToTile(AIVehicle.GetLocation(plane), pozycja)<30)
		    if(AIVehicle.GetCapacity(plane, rodzic.GetPassengerCargoId())>0)
			{
			local percent = ( 100 * AIVehicle.GetCargoLoad(plane, rodzic.GetPassengerCargoId()))/(AIVehicle.GetCapacity(plane, rodzic.GetPassengerCargoId()));
		    //Info(percent + " %");
			if(percent < minimum)
			   {
			   //Info(percent + " %%%")
			   minimum=percent;
			   pustak=plane;
			   }
  		    lista.AddItem(plane, aktualna);
			counter++;
			}
	  }
   if(pustak!=null)lista.RemoveItem(pustak); //airport may be empty
   }
   
for (local skipping = lista .Begin(); lista.HasNext(); skipping = lista.Next())
   {
   this.Skip(skipping, list.GetValue(skipping));
   }

}

function AirBuilder::PopulationWithRandValuator(town_id)
{
return AITown.GetPopulation(town_id)-AIBase.RandRange(500);
}
	
function AirBuilder::DistanceWithRandValuator(town_id, center_tile)
{
local rand = AIBase.RandRange(150);
local distance = AITown.GetDistanceManhattanToTile(town_id, center_tile)-AirBuilder.GetOptimalDistance();
if(distance<0)distance*=-1;
return distance + rand;
}

function AirBuilder::IsItPossibleToHaveAirport(a, b, c)
{
local test = AITestMode();
if(AIAirport.BuildAirport(a, b, c)) return true;
return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
}

