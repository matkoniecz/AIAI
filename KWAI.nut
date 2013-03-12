//lepsze wybieranie przy a8
//industry - valuate before building
//nie pierwsze lepsze tylko najlepsze, nie masowac budowy (wiek reszty) DONE?
//kasowanie nadmiaru
//sprzedawaæ samoloty z minusem w obu latach (jeœli starsze ni¿ 2 lata) DONE?

class KWAI
{
desperacja=0;
rodzic=null;
_koszt=0;
trasa = Route();
}

require("KWAI_station_allocators.nut");

function KWAI::GetMaxDistance()
{
return 750+desperacja*50;
}

function KWAI::GetMinDistance()
{
return maxi(200-this.desperacja*10, 70);
}

function KWAI::GetOptimalDistance()
{
return 400;
}

function KWAI::ValuatorDlaCzyJuzZlinkowane(station_id, i)
{
return AITile.GetDistanceManhattanToTile( AIStation.GetLocation(station_id), AIIndustry.GetLocation(i) );
}

function KWAI::IsConnectedIndustry(industry, cargo)
{
if(CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_LARGE))return true;
else if(CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_METROPOLITAN))return true;
else if(CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_COMMUTER))return true;
else return CheckerIsReallyConnectedIndustry(industry, cargo, AIAirport.AT_SMALL);
}

function KWAI::CheckerIsReallyConnectedIndustry(industry, cargo, airport_type)
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

function KWAI::BuildAirportRouteBetweenCities()
{
if(AIAI.GetSetting("deep_debugged_function_calling"))Info("BuildAirportRouteBetweenCities<");
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
   }
return BuildAirportRouteBetweenCitiesWithAirportTypeSet(AIAirport.AT_SMALL);
if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCities");
}

function KWAI::CostEstimation()
{
	for(local i=1; i<400; i++)
	   {
	   local enginiatko = KWAI.FindAircraft(AIAirport.AT_LARGE, AIAI.GetPassengerCargoId(), 3, 30000*i);
	   if(enginiatko!=null)
	   if(AIEngine.IsValidEngine(enginiatko))
	       {
		   return i*30000;
		   }
	   }
}

function KWAI::BuildAirportRouteBetweenCitiesWithAirportTypeSet(airport_type)
{	
if(AIAI.GetSetting("deep_debugged_function_calling"))Info("BuildAirportRouteBetweenCitiesWithAirportTypeSet<");
if(AIAirport.IsValidAirportType(airport_type)==false)
   {
   if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
   return false;
   }
Info("Trying to build an airport route (city version)");

	local engine=this.FindAircraft(airport_type, rodzic.GetPassengerCargoId(), 3, AICompany.GetBankBalance(AICompany.COMPANY_SELF));
	
	_koszt = KWAI.CostEstimation();
	
	   if(engine==null)
	    {
		Info("Unfortunatelly no suitable aircraft found");
  	    if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
		return false;
		}
	
	Info("Engine found");

	local tile_1 = this.FindSuitableAirportSpotInTown(airport_type, 0);
	if (tile_1 < 0) 
	   {
	   _koszt=0;
       if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
	   return false;
	   }
	local tile_2 = this.FindSuitableAirportSpotInTown(airport_type, tile_1);
	if (tile_2 < 0) {
	   {
	   _koszt=0;
       if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
	   return false;
	   }
	}
	
	/* Build the airports for real */
	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
	   _koszt=0;
      if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
	   return false;
	}
	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		Error("Although the testing told us we could build 2 airports, it still failed on the second airport at tile " + tile_2 + ".");
		if(AIAI.GetSetting("other_debug_signs"))AISign.BuildSign(tile_2, "HERE"+AIError.GetLastErrorString());
		AIAirport.RemoveAirport(tile_1);
	   _koszt=0;
   if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
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
   if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
			 return true;
			 }
		  rodzic.Konserwuj();
		  AIController.Sleep(100);
		  }
  	   }

	Info("Done building a route");
   if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">BuildAirportRouteBetweenCitiesWithAirportTypeSet");
	return true;
}

function KWAI::FindEngine(route)
{
route.engine_count = 3;
route.engine = KWAI.FindAircraft(route.station_size, route.cargo, route.engine_count = 3, route.budget);
route.demand = KWAI.CostEstimation();
return route;
}

function KWAI::FindAircraft(airport_type, cargo, ile, balance)
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

function KWAI::BuildCargoAircraft(tile_1, tile_2, engine, cargo, nazwa)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);
if(vehicle==-1)return false;

AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_FULL_LOAD_ANY);
AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NO_LOAD);
AIVehicle.StartStopVehicle(vehicle);
/*
for(local i=1; AIVehicle.SetName(vehicle, nazwa)==false; i++)
   {
   //maksimum 30 znaków
   //potrzeba obcinacza stringa
   AIVehicle.SetName(vehicle, nazwa+" # "+i);
   }
*/	
return true;
}

function KWAI::BuildPassengerAircraftWithRand(tile_1, tile_2, engine, cargo)
{
if(AIBase.RandRange(2)==1)
   {
   local swap=tile_2;
   tile_2=tile_1;
   tile_1=swap;
   }
return this.BuildPassengerAircraft(tile_1, tile_2, engine, cargo);
}

function KWAI::BuildExpressAircraft(tile_1, tile_2, engine, cargo)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);

if(vehicle==-1)return false;

AIOrder.AppendOrder(vehicle, tile_1, 0);
AIOrder.AppendOrder(vehicle, tile_2, 0);
AIVehicle.StartStopVehicle(vehicle);
	
return true;
}

function KWAI::BuildPassengerAircraft(tile_1, tile_2, engine, cargo)
{
local vehicle = this.BuildAircraft(tile_1, tile_2, engine, cargo);

if(vehicle==-1)return false;

AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_FULL_LOAD_ANY);
AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_FULL_LOAD_ANY);
AIVehicle.StartStopVehicle(vehicle);
	
return true;
}

function KWAI::BuildAircraft(tile_1, tile_2, engine, cargo)
{
	/* Build an aircraft */
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	if (!AIEngine.IsValidEngine(engine)) {
		return -1;
	}
	
local vehicle = AIVehicle.BuildVehicle(hangar, engine);

	if (!AIVehicle.IsValidVehicle(vehicle)) {
		AILog.Error("Couldn't build the aircraft " + AIError.GetLastErrorString());
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

function KWAI::IleSamolotow(dystans, speed)
{
if(((3*dystans)/(2*speed))<3)return 3;
return (3*dystans)/(2*speed);
}

function KWAI::ValuateProducer(ID, cargo)
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

function KWAI::ValuateConsumer(ID, cargo, score)
{
if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
return score;
}

function KWAI::distanceBetweenIndustriesValuator(distance)
{
if(distance>GetMaxDistance())return 0;
if(distance<GetMinDistance()) return 0;
return max(1, abs(400-distance)/20);
}

function KWAI::FindPair(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this);
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, FindPairDualIndustryAllocator, GetNiceRandomTown, FindPairIndustryToTownAllocator, FindEngine);
}

function KWAI::GetNiceRandomTown(location)
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

function KWAI::CargoConnectionBuilder()
{
Info("Trying to build an airport route from industry");

trasa = Route();
trasa.budget = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
trasa = this.FindPair(trasa);
_koszt = trasa.demand;

Info("Trying to build an airport route from industry - scanning completed");

if(!trasa.OK) 
   {
   Info("Airport cargo route failed");
   return false;
   }
else
   {
   Info("Airport cargo route found");
   }

if (!AIAirport.BuildAirport(trasa.first_station.location, trasa.station_size, AIStation.STATION_NEW)) 
	{
	return false;
	}
else
   {
   AIAI.Info("Airport constructed");
   }

if (!AIAirport.BuildAirport(trasa.end_station, trasa.station_size, AIStation.STATION_NEW)) 
	{
	return false;
	}
else
   {
   AIAI.Info("Airport constructed");
   //TODO - usun pierwsze
   }
	
	for(local i=0; i<trasa.engine_count; i++) 
	   {
	   while(!this.BuildCargoAircraft(trasa.first_station.location, trasa.end_station, trasa.engine, trasa.cargo, "null"))
          {
		  AIAI.Info("Next try");
		  Error("Aircraft construction failed due to " + AIError.GetLastErrorString()+".")
		  if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
		     {
			 return true;
			 }
 		  rodzic.Konserwuj();
		  AIController.Sleep(1000);
		  }
       //AIAI.Info("We have " + i + " from " + licznik + " aircrafts.");
  	   }
return true;
}

function KWAI::Konserwuj()
{
//Info("<");
this.Skipper();
//Info(">");

//Info("<");
this.Uzupelnij();
this.UzupelnijCargo();
//Info(">");
}

function KWAI::GetEffectiveDistance(tile_1, tile_2)
{
return AITile.GetDistanceManhattanToTile(tile_1, tile_2);
}

function KWAI::Burden(tile_1, tile_2, engine)
{
return AIEngine.GetMaxSpeed(engine)*200/(this.GetEffectiveDistance(tile_1, tile_2)+50);
}

function KWAI::GetBurden(stacja)
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

function KWAI::IsItPossibleToAddBurden(stacja, tile, engine, ile=1)
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


function KWAI::Uzupelnij()
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
			
			 local engine=this.FindAircraft(airport_type, cargo, 1, AICompany.GetBankBalance(AICompany.COMPANY_SELF));
		     if(engine==null) 
			    {
				continue;
				}
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

function KWAI::UzupelnijCargo()
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

		local save = AICompany.GetLoanAmount();
 		AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
		  local engine=this.FindAircraft(airport_type, cargo, 1, AICompany.GetBankBalance(AICompany.COMPANY_SELF));
		  if(engine != null)
		  if(IsItPossibleToAddBurden(aktualna, another_station, engine)) this.BuildCargoAircraft(AIStation.GetLocation(aktualna), another_station, engine, cargo, "uzupelniacz");
		  else Error("Aajjajaja");
 		  AICompany.SetLoanAmount(save);
		  }
	   }   
   }
}

function CzyToPassengerCargoValuator(veh)
{
   if(AIVehicle.GetCapacity(veh, AIAI.GetPassengerCargoId())>0)return 1;
   return 0;
   }

function KWAI::Skip(plane, stacja)
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

function KWAI::Skipper()
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
   
for (local skipping = lista .Begin(); lista .HasNext(); skipping = lista.Next())
   {
   this.Skip(skipping, list.GetValue(skipping));
   }

}

function KWAI::PopulationWithRandValuator(town_id)
{
return AITown.GetPopulation(town_id)-AIBase.RandRange(500);
}
	
function KWAI::DistanceWithRandValuator(town_id, center_tile)
{
local rand = AIBase.RandRange(150);
local distance = AITown.GetDistanceManhattanToTile(town_id, center_tile)-KWAI.GetOptimalDistance();
if(distance<0)distance*=-1;
return distance + rand;
}

function KWAI::IsItPossibleToHaveAirport(a, b, c)
{
local test = AITestMode();
return AIAirport.BuildAirport(a, b, c);
}
