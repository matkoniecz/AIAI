class AirBuilder extends Builder
{
}

function AirBuilder::IsAllowed()
{
	if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR)) return false;
	if(AIGameSettings.GetValue("economy.infrastructure_maintenance")) return false; //TODO - replace by estimating profits

	local ile;
	local veh_list = AIVehicleList();
	veh_list.Valuate(AIVehicle.GetVehicleType);
	veh_list.KeepValue(AIVehicle.VT_AIR);
	ile = veh_list.Count();
	local allowed = AIGameSettings.GetValue("vehicle.max_aircraft");
	if(allowed==0) return false;
	if(ile==0) return true;
	if((allowed - ile)<4) return false;
	if(((ile*100)/(allowed))>90) return false;
	return true;
}

function AirBuilder::FindPairIndustryToTownAllocator(route)
{
route.first_station.location = null
route.second_station.location = null
return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_METROPOLITAN, route.start)
route.second_station.location = FindSuitableAirportSpotInTownThatAcceptsThisWeirdCargo(AIAirport.AT_METROPOLITAN, route.end, route.cargo)
route.station_size = AIAirport.AT_METROPOLITAN
if(route.first_station.location != null && route.second_station.location != null ) return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_LARGE, route.start)
route.second_station.location = FindSuitableAirportSpotInTownThatAcceptsThisWeirdCargo(AIAirport.AT_LARGE, route.end, route.cargo)
route.station_size = AIAirport.AT_LARGE
if(route.first_station.location != null && route.second_station.location != null ) return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_COMMUTER, route.start)
route.second_station.location = FindSuitableAirportSpotInTownThatAcceptsThisWeirdCargo(AIAirport.AT_COMMUTER, route.end, route.cargo)
route.station_size = AIAirport.AT_COMMUTER
if(route.first_station.location != null && route.second_station.location != null ) return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_SMALL, route.start)
route.second_station.location = FindSuitableAirportSpotInTownThatAcceptsThisWeirdCargo(AIAirport.AT_SMALL, route.end, route.cargo)
route.station_size = AIAirport.AT_SMALL
return route
}

function AirBuilder::FindPairDualIndustryAllocator(route)
{

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_METROPOLITAN, route.start)
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_METROPOLITAN, route.end, route.cargo)
route.station_size = AIAirport.AT_METROPOLITAN
if(route.first_station.location != null && route.second_station.location != null ) return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_LARGE, route.start)
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_LARGE, route.end, route.cargo)
route.station_size = AIAirport.AT_LARGE
if(route.first_station.location != null && route.second_station.location != null ) return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_COMMUTER, route.start)
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_COMMUTER, route.end, route.cargo)
route.station_size = AIAirport.AT_COMMUTER
if(route.first_station.location != null && route.second_station.location != null ) return route

route.first_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeProducer(AIAirport.AT_SMALL, route.start)
route.second_station.location = FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(AIAirport.AT_SMALL, route.end, route.cargo)
route.station_size = AIAirport.AT_SMALL
return route
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

function AirBuilder::FindSuitableAirportSpotNearIndustryWithAirportTypeConsumer(airport_type, consumer, cargo, center_tile=null, max_distance=INFINITE_DISTANCE)
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

list.Valuate(AirBuilder.GetOrderDistance, center_tile);
list.KeepBelowValue(max_distance);    

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


function AirBuilder::GetOrderDistance(tile_1, tile_2)
{
return AIOrder.GetOrderDistance(AIVehicle.VT_AIR, tile_1, tile_2);
}

function AirBuilder::FindSuitableAirportSpotInTown(airport_type, center_tile=null, max_distance=INFINITE_DISTANCE)
	{
	local airport_x, airport_y, airport_rad;

	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);
	local town_list = AITownList();

	town_list.Valuate(this.PopulationWithRandValuator);
	town_list.KeepAboveValue(500-desperation);

	if (center_tile != null) {
		town_list.Valuate(AITown.GetDistanceManhattanToTile, center_tile);
		town_list.KeepAboveValue(this.GetMinDistance());    
		town_list.KeepBelowValue(this.GetMaxDistance());    

		town_list.Valuate(AirBuilder.GetOrderDistance, center_tile); //TODO - is this correct - GetOrderDistance requires tile, not city id 
		town_list.KeepBelowValue(max_distance);    

		town_list.Valuate(this.DistanceWithRandValuator, center_tile);
		//TODO - wed³ug dystansu optimum to 500
		town_list.KeepBottom(50);
	}
	

	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next()) {
    	local tile = AITown.GetLocation(town);
		local list = AITileList();
		local range = Helper.Sqrt(AITown.GetPopulation(town)/100) + 15;
		SafeAddRectangle(list, tile, range);
		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
		list.KeepValue(1);
		list.Valuate(IsConnectedDistrict);
		list.KeepValue(0);
		// Sort on acceptance, remove places that don't have acceptance 
		list.Valuate(AITile.GetCargoAcceptance, Helper.GetPAXCargo(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(50);
		list.Valuate(AITile.GetCargoAcceptance, Helper.GetMailCargo(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(10);
		
		// Handle order distance
		if(center_tile != null){
			town_list.Valuate(AirBuilder.GetOrderDistance, center_tile);
			town_list.KeepBelowValue(max_distance);
		}
		// Couldn't find a suitable place for this town, skip to the next 
		if (list.Count() == 0) continue;
		// Walk all the tiles and see if we can build the airport at all
		{
			local good_tile = 0;
			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
				if(!IsItPossibleToHaveAirport(tile, airport_type, AIStation.STATION_NEW))
				   {
				   continue;
				   }
				good_tile = tile;
				break;
			}

			// Did we found a place to build the airport on?
			if (good_tile == 0) continue;
		}

		Info("Found a good spot for an airport in town " + town + " at tile " + tile);
		return tile;
	}

	Info("Couldn't find a suitable town to build an airport in");
	return -1;
}

function AirBuilder::FindSuitableAirportSpotInTownThatAcceptsThisWeirdCargo(town, cargo, center_tile=null, max_distance=INFINITE_DISTANCE)
{
 	local tile = AITown.GetLocation(town);
	local list = AITileList();
	local range = Helper.Sqrt(AITown.GetPopulation(town)/100) + 15;
	SafeAddRectangle(list, tile, range);

	list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
	list.KeepValue(1);

	/* Sort on acceptance, remove places that don't have acceptance */
	list.Valuate(AITile.GetCargoAcceptance, Helper.GetPAXCargo(), airport_x, airport_y, airport_rad);
	list.RemoveBelowValue(50);

	list.Valuate(AirBuilder.GetOrderDistance, center_tile);
	list.KeepBelowValue(max_distance);    

	list.Valuate(AITile.GetCargoAcceptance, Helper.GetMailCargo(), airport_x, airport_y, airport_rad);
	list.RemoveBelowValue(10);
	
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
return 750+desperation*50;
}

function AirBuilder::GetMinDistance()
{
return Helper.Max(200-this.desperation*10, 70);
}

function AirBuilder::GetOptimalDistance()
{
return 400;
}

function AirBuilder::ValuatorDlaCzyJuzZlinkowane(station_id, i)
{
return AITile.GetDistanceManhattanToTile( AIStation.GetLocation(station_id), AIIndustry.GetLocation(i) );
}

function AirBuilder::CostEstimation()
	{
	for(local i=1; i<100; i++)
		{
		local engine = AirBuilder.FindAircraft(AIAirport.AT_LARGE, Helper.GetPAXCargo(), 3, Money.Inflate(30000)*i, 120-4*desperation);
		if(engine!=null){
			if(AIEngine.IsBuildable(engine)){
				return i*Money.Inflate(30000);
				}
			}
		}
	}

function AirBuilder::FindEngine(route)
{
route.engine_count = 3;
route.engine = AirBuilder.FindAircraft(route.station_size, route.cargo, route.engine_count = 3, route.budget, Helper.Sqrt(AIOrder.GetOrderDistance(AIVehicle.VT_AIR, route.start_tile, route.end_tile)));
route.demand = AirBuilder.CostEstimation();
return route;
}

function FindAircraftValuatorRunningOnVehicleIDs(vehicle_id)
{
return FindAircraftValuator(AIVehicle.GetEngineType(vehicle_id));
}
function FindAircraftValuator(engine_id)
{
return AIEngine.GetCapacity(engine_id) * AIEngine.GetMaxSpeed(engine_id);
}

function AirBuilder::FindAircraft(airport_type, cargo, how_many, balance, distance)
{
distance = AIOrder.GetOrderDistance(AIVehicle.VT_AIR, AIMap.GetTileIndex(1, 1), AIMap.GetTileIndex(Helper.Clamp(distance, 1, AIMap.GetMapSizeX() - 2), 1))

local typical_minimal_capacity = 40
local engine_list = AIEngineList(AIVehicle.VT_AIR);

if(airport_type==AIAirport.AT_SMALL || airport_type==AIAirport.AT_COMMUTER )
	{
	engine_list.Valuate(AIEngine.GetPlaneType);
	engine_list.RemoveValue(AIAirport.PT_BIG_PLANE);
	}

if(how_many!=0)balance-=2*AIAirport.GetPrice(airport_type);
if(balance<0) return null;
engine_list.Valuate(AIEngine.GetPrice);

if(how_many==0) engine_list.KeepBelowValue(balance);
else engine_list.KeepBelowValue(balance/how_many);

engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
engine_list.KeepValue(1);

engine_list.Valuate(AIEngine.GetMaximumOrderDistance); //note, function is modified and return INFINITE_DISTANCE instead of 0
engine_list.RemoveBelowValue(INFINITE_DISTANCE); //TODO: Allow planes with suitable range

engine_list.Valuate(FindAircraftValuator);
engine_list.KeepTop(1);
if(engine_list.Count()==0) return null;
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

if(vehicle==-1) return false;

AIOrder.AppendOrder(vehicle, tile_1, 0);
AIOrder.AppendOrder(vehicle, tile_2, 0);
AIVehicle.StartStopVehicle(vehicle);
	
return true;
}

function AirBuilder::BuildPassengerAircraft(tile_1, tile_2, engine, cargo)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);
if(vehicle==-1) return false;
if(!AIOrder.AppendOrder(vehicle, tile_1, AIOrder.OF_FULL_LOAD_ANY))abort(AIVehicle.GetName(vehicle) + " - order fail")
if(!AIOrder.AppendOrder(vehicle, tile_2, AIOrder.OF_FULL_LOAD_ANY))abort(AIVehicle.GetName(vehicle) + " - order fail")
if(!AIVehicle.StartStopVehicle(vehicle)) abort(AIVehicle.GetName(vehicle) + " - startstop fail")
return true;
}

function AirBuilder::BuildAircraft(tile_1, tile_2, engine, cargo)
{
	/* Build an aircraft */
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	local vehicle = AIVehicle.BuildVehicle(hangar, engine);

	if (!AIVehicle.IsValidVehicle(vehicle)) {
		return -1;
		}

if(!AIVehicle.RefitVehicle(vehicle, cargo)) 
   {
   Error("Couldn't refit the aircraft " + AIError.GetLastErrorString());
   AIVehicle.SellVehicle(vehicle);
   return -1;
   }
return vehicle;
}

function AirBuilder::HowManyAirplanes(distance, speed, production, engine)
{
local ile = (3*distance)/(2*speed);
Info(ile + " aircrafts needed; based on distance");

ile *= 10 * production;
//Info(ile + "&^%***********");

ile /= AIEngine.GetCapacity(engine);
Info(ile + " aircrafts needed after production (" + production + ") and capacity (" +  AIEngine.GetCapacity(engine) +") adjustment");
ile = max(ile, 3);
return ile;
}

function AirBuilder::ValuateProducer(ID, cargo)
	{
	if(AIIndustry.GetLastMonthProduction(ID, cargo)<50-4*desperation) return 0; //protection from tiny industries servised by giant trains
	return Builder.ValuateProducer(ID, cargo);
	}

function AirBuilder::distanceBetweenIndustriesValuator(distance)
{
if(distance>GetMaxDistance()) return 0;
if(distance<GetMinDistance()) return 0;
return max(1, abs(400-distance)/20);
}

function AirBuilder::BuildCargoAircraft(tile_1, tile_2, engine, cargo, nazwa)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);
if(vehicle==-1) return false;

AIOrder.AppendOrder(vehicle, tile_1, AIOrder.OF_FULL_LOAD_ANY);
AIOrder.AppendOrder(vehicle, tile_2, AIOrder.OF_NO_LOAD);
AIVehicle.StartStopVehicle(vehicle);
AIVehicle.SetName(vehicle, nazwa);
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
if(town_list.Count()==0) return null;
return town_list.Begin();
}

function AirBuilder::Maintenance()
{
this.Skipper();

if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR)) return;
local veh_list = AIVehicleList();
veh_list.Valuate(AIVehicle.GetVehicleType);
veh_list.KeepValue(AIVehicle.VT_AIR);
local allowed = AIGameSettings.GetValue("vehicle.max_aircraft");
if(allowed == veh_list.Count()) return;

this.addPAXAircrafts();
this.AddCargoAircrafts();
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

function AirBuilder::GetBurdenOfSingleAircraft(tile_1, tile_2, engine)
{
/*
Info("AIEngine.GetMaxSpeed(engine) = " + AIEngine.GetMaxSpeed(engine))
Info("this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2) = " + this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2))
Info(AIEngine.GetMaxSpeed(engine) + "*200/(" + this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2) + "+50)")
Info(AIEngine.GetMaxSpeed(engine)*200/(this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2)+50))
*/

//return AIEngine.GetMaxSpeed(engine)*200/(this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2)+50);
//was too restrictive for Colemena Count at 1/1 speed ratio, at distance 171 for small airport [only one allowed, used 428 of 750]

return AIEngine.GetMaxSpeed(engine)*125/(this.GetEffectiveDistanceBetweenAirports(tile_1, tile_2)+75);
}

function AirBuilder::GetCurrentBurdenOfAirport(airport)
{
local total;
local total = 0;
local airlist=AIVehicleList_Station(airport);
for (local plane = airlist.Begin(); airlist.HasNext(); plane = airlist.Next())
   {
   total += this.GetBurdenOfSingleAircraft(AIOrder.GetOrderDestination (plane, 0), AIOrder.GetOrderDestination (plane, 1), AIVehicle.GetEngineType(plane));
   }
return total;
}

function AirBuilder::IsItPossibleToAddBurden(airport_id, tile=null, engine=null, ile=1)
{
local maksimum;
local total = this.GetCurrentBurdenOfAirport(airport_id);
local airport_type = AIAirport.GetAirportType(AIStation.GetLocation(airport_id));
if(airport_type==AIAirport.AT_LARGE) maksimum = 1500; //1 l¹dowanie miesiêcznie - 250 //6 na du¿ym
if(airport_type==AIAirport.AT_METROPOLITAN ) maksimum = 2000; //1 l¹dowaie miesiêcznie - 250 //6 na du¿ym
if(airport_type==AIAirport.AT_COMMUTER) maksimum = 500; //1 l¹dowanie miesiêcznie - 250 //4 na ma³ym
if(airport_type==AIAirport.AT_SMALL) maksimum = 750; //1 l¹dowanie miesiêcznie - 250 //4 na ma³ym
 
if(AIAI.GetSetting("debug_signs_for_airports_load")) Helper.SetSign(AIStation.GetLocation(airport_id), total + " (" + maksimum + ")");

if(tile != null && engine != null) total+=ile*this.GetBurdenOfSingleAircraft(AIStation.GetLocation(airport_id), tile, engine);

return total <= maksimum;
}

function AirBuilder::addPAXAircrafts()
{
local airport_type;
local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()==0) return;

for (local airport = list.Begin(); list.HasNext(); airport = list.Next())
	{
	local cargo_list = AICargoList();
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
		{
		if(AIStation.GetCargoWaiting(airport, cargo)>100)
			{																						//protection from flood of mail planes
			if((GetAverageCapacityOfVehiclesFromStation(airport, cargo)*2 < AIStation.GetCargoWaiting(airport, cargo) &&  AIStation.GetCargoWaiting(airport, cargo)>200) 
			|| AIStation.GetCargoRating(airport, cargo)<30 )
				{
				local airports_list = AIStationList(AIStation.STATION_AIRPORT);
				for (local goal_airport = airports_list.Begin(); airports_list.HasNext(); goal_airport = airports_list.Next())
					{
					local tile_1 = AIStation.GetLocation(airport);
					local tile_2 = AIStation.GetLocation(goal_airport);
					local airport_type_1 = AIAirport.GetAirportType(tile_1);
					local airport_type_2 = AIAirport.GetAirportType(tile_2);
					if((airport_type_1==AIAirport.AT_SMALL || airport_type_2==AIAirport.AT_SMALL)||
					   (airport_type_1==AIAirport.AT_COMMUTER  || airport_type_2==AIAirport.AT_COMMUTER)) 
						airport_type=AIAirport.AT_SMALL;
					else
						airport_type=AIAirport.AT_LARGE;

					local engine=this.FindAircraft(airport_type, cargo, 1, GetAvailableMoney(), AIOrder.GetOrderDistance(AIVehicle.VT_AIR, tile_1, tile_2));
					if(engine==null) continue;
					local vehicle_list=AIVehicleList_Station(airport);
					vehicle_list.Valuate(FindAircraftValuatorRunningOnVehicleIDs);
					vehicle_list.RemoveAboveValue(FindAircraftValuator(engine))
					if(vehicle_list.Count()==0) continue;
					ProvideMoney();
					if(AITile.GetDistanceManhattanToTile(tile_1, tile_2)>100
					&& AgeOfTheYoungestVehicle(goal_airport)>40)
						{
						if(this.IsItPossibleToAddBurden(airport, tile_2, engine, 1)
						&& this.IsItPossibleToAddBurden(goal_airport, tile_1, engine, 1))
							{
							if( Helper.GetPAXCargo()==cargo )
								this.BuildPassengerAircraft(tile_1, tile_2, engine, cargo);
							else if(Helper.GetMailCargo()==cargo)
								this.BuildExpressAircraft(tile_1, tile_2, engine, cargo);
							break;
							}
						}
					}
				}
			}   
		}
	}
}

function AirBuilder::AddCargoAircrafts()
{
local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()==0) return;

for (local airport = list.Begin(); list.HasNext(); airport = list.Next()){
	local cargo_list = AICargoList();
	for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
		if(AIStation.GetCargoWaiting(airport, cargo)>1){
		if(cargo != Helper.GetPAXCargo())
			if(cargo != Helper.GetMailCargo())
				if(IsItNeededToImproveThatStation(airport, cargo))
				{
				local airport_type = AIAirport.GetAirportType(AIStation.GetLocation(airport));
				if(airport_type==AIAirport.AT_SMALL || airport_type==AIAirport.AT_COMMUTER){
					airport_type=AIAirport.AT_SMALL;
					}
				local vehicle = AIVehicleList_Station(airport).Begin();
				local another_station = AIOrder.GetOrderDestination(vehicle, 0);
				if(AIStation.GetLocation(airport) == another_station) another_station = AIOrder.GetOrderDestination(vehicle, 1);
				local engine=this.FindAircraft(airport_type, cargo, 1, GetAvailableMoney(), AIOrder.GetOrderDistance(AIVehicle.VT_AIR, another_station, AIBaseStation.GetLocation(airport)));
				if(engine != null){
					ProvideMoney();
					if(IsItPossibleToAddBurden(airport, another_station, engine)) {
						if(IsItPossibleToAddBurden(AIStation.GetStationID(another_station), AIBaseStation.GetLocation(airport), engine)) {
							this.BuildCargoAircraft(AIStation.GetLocation(airport), another_station, engine, cargo, "uzupelniacz");
							}
						}
					}
				else {
					Error("Plane not found for " + AICargo.GetCargoLabel(cargo) + " cargo.");
					}
		  }
	   }   
   }
}

function AirBuilder::Skipper()
{
local airport_list = AIStationList(AIStation.STATION_AIRPORT);
if(airport_list.Count()==0) return;

local list = AIList();

for (local airport = airport_list.Begin(); airport_list.HasNext(); airport = airport_list.Next())
   {
   local pozycja=AIStation.GetLocation(airport)
   local airlist=AIVehicleList_Station(airport);
   if(airlist.Count()==0)continue;

   local counter=0;
   local minimum = 101;
   local plane_left_on_airport = null;
   for (local plane = airlist.Begin(); airlist.HasNext(); plane = airlist.Next()){
	  if(AIVehicle.GetState(plane)==AIVehicle.VS_AT_STATION)
	     if(AITile.GetDistanceManhattanToTile(AIVehicle.GetLocation(plane), pozycja)<30)
		    if(AIVehicle.GetCapacity(plane, Helper.GetPAXCargo())>0){
			local percent = ( 100 * AIVehicle.GetCargoLoad(plane, Helper.GetPAXCargo()))/(AIVehicle.GetCapacity(plane, Helper.GetPAXCargo()));
		    //Info(percent + " %");
			if(percent < minimum)
			   {
			   //Info(percent + " %%%")
			   minimum=percent;
			   plane_left_on_airport=plane;
			   }
  		    list.AddItem(plane, airport);
			counter++;
			}
	  }
   if(plane_left_on_airport!=null)list.RemoveItem(plane_left_on_airport); 
   }
local count=0;
for (local plane = list.Begin(); list.HasNext(); plane = list.Next())
	{
	for(local i=0; i<AIOrder.GetOrderCount(plane); i++)
		{
		if(AITile.GetDistanceManhattanToTile(AIVehicle.GetLocation(plane), AIOrder.GetOrderDestination(plane, i))<30)
			{
			if(AIOrder.SkipToOrder(plane, (i+1)%AIOrder.GetOrderCount(plane)))
				{
				count++;
				//Error("OK: "+AIError.GetLastErrorString() +" dump: "+AIOrder.GetOrderCount(plane) +" "+ AIOrder.ORDER_CURRENT);
				break;
				}
			else { 
				//Error("fail: "+AIError.GetLastErrorString() +" dump: "+AIOrder.GetOrderCount(plane) +" "+ AIOrder.ORDER_CURRENT);
				break;
				} 
			}
		}
	}
	local plural = "s"
	if(count == 1) {
		plural = ""
	}
	Info(count+" plane"+plural+" skipped to next destination!");
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

function AirBuilder::IsItPossibleToHaveAirport(tile, airport_type, c)
{
	{
		local test = AITestMode();
		if(AIAirport.BuildAirport(tile, airport_type, c)) return true;
	}
	local error = AIError.GetLastError()
	HandleFailedStationConstruction(tile, error);
	return (error == AIError.ERR_NOT_ENOUGH_CASH);
}

