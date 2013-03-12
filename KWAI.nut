//this.anie nowych po³¹czeñ
//lepsze wybieranie przy a8
//industry - valuate before building
//nie pierwsze lepsze tylko najlepsze, nie masowac budowy (wiek reszty)
//kasowanie nadmiaru
//sprzedawaæ samoloty z minusem w obu latach (jeœli starsze ni¿ 2 lata)

class KWAI
{
desperacja=0;
rodzic=null;
_koszt=0;
}

function KWAI::GetMaximalDistance()
{
return 500+desperacja*50;
}

function KWAI::GetMinimalDistance()
{
if(200-this.desperacja*10<70)return 70;
return 200-this.desperacja*10;
}

function KWAI::GetOptimalDistance()
{
return 400;
}

function KWAI::ValuatorDlaCzyJuzZlinkowane(station_id, i)
{
return AITile.GetDistanceManhattanToTile( AIStation.GetLocation(station_id), AIIndustry.GetLocation(i) );
}

function KWAI::CzyJuzZlinkowane(i, cargo) //DUPNA HEUREZA TODO - replace it by feeder system
{
local list = AIStationList(AIStation.STATION_AIRPORT);
//dystans od i wiêkszy od 20
list.Valuate(this.ValuatorDlaCzyJuzZlinkowane, i);
list.KeepBelowValue(20);

for (local stacja = list.Begin(); list.HasNext(); cargo = list.Next())
    {
    local pojazdy = AIVehicleList_Station(stacja);
	for (local plane = pojazdy.Begin(); pojazdy.HasNext(); plane = pojazdy.Next())
	  {
	  if(AIVehicle.GetCapacity(plane, cargo)!=0)return true;
	  }
	}
return false;
}

function KWAI::BuildAirportRouteBetweenCities()
{
	AILog.Info("Trying to build an airport route (city version)");

	local airport_type = (AIAirport.IsValidAirportType(AIAirport.AT_LARGE) ? AIAirport.AT_LARGE : AIAirport.AT_SMALL);
	local engine=this.FindAircraft(airport_type, this.GetPassengerCargoId(), 3, AICompany.GetBankBalance(AICompany.COMPANY_SELF));
	
	for(local i=1; i<400; i++)
	   {
	   if(AIEngine.IsValidEngine(this.FindAircraft(airport_type, this.GetPassengerCargoId(), 3, 30000*i)))
	       {
		   _koszt=i*30000;
		   break;
		   }
	   }

	   if(AIEngine.IsValidEngine(engine) == false) 
	    {
		AILog.Info("Unfortunatelly no suitable aircraft found");
		return false;
		}
	
	AILog.Info("Engine found");

	local tile_1 = this.FindSuitableAirportSpotInTown(airport_type, 0);
	if (tile_1 < 0) 
	   {
	   _koszt=0;
	   return false;
	   }
	local tile_2 = this.FindSuitableAirportSpotInTown(airport_type, tile_1);
	if (tile_2 < 0) {
	   {
	   _koszt=0;
	   return false;
	   }
	}
	
	/* Build the airports for real */
	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		AILog.Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
	   _koszt=0;
	   return false;
	}
	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		AILog.Error("Although the testing told us we could build 2 airports, it still failed on the second airport at tile " + tile_2 + ".");
		if(AIAI.GetSetting("other_debug_signs"))AISign.BuildSign(tile_2, "HERE"+AIError.GetLastErrorString());
		AIAirport.RemoveAirport(tile_1);
	   _koszt=0;
		return false;
	}
	
	Info("Airports constructed on distance " + AIMap.DistanceManhattan(tile_1, tile_2));
	local dystans = AITile.GetDistanceManhattanToTile(tile_1, tile_2);
	local speed = AIEngine.GetMaxSpeed(engine);
	local licznik = this.IleSamolotow(dystans, speed);
	for(local i=0; i<licznik; i++) 
	   {
	   for(local i=0; !this.BuildPassengerAircraftWithRand(tile_1, tile_2, engine, this.GetPassengerCargoId()); i++)
          {
		  AILog.Error(AIError.GetLastErrorString()+"++++++++++++")
		  if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
		     {
			 return true;
			 }
		  rodzic.Konserwuj();
		  AIController.Sleep(100);
		  }
  	   }

	AILog.Info("Done building a route");
	return true;
}

function KWAI::FindAircraft(airport_type, cargo, ile, balance)
{
//AILog.Error(balance+"");
local engine_list = AIEngineList(AIVehicle.VT_AIR);

//AILog.Error("engine_list.Count() I " + engine_list.Count());

if(airport_type==AIAirport.AT_SMALL)
	{
	engine_list.Valuate(AIEngine.GetPlaneType);
	engine_list.RemoveValue(AIAirport.PT_BIG_PLANE);
	}

//AILog.Error("engine_list.Count() II " + engine_list.Count());
	
balance-=2000;
if(ile!=0)balance-=2*AIAirport.GetPrice(airport_type);
if(balance<0)return -1;
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
engine_list.KeepAboveValue(40); //HARDCODED OPTION
engine_list.KeepTop(1);

//AILog.Error("engine_list.Count() VI " + engine_list.Count());

if(engine_list.Count()==0)return -1;
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

class AirCargoRoute
{
id_lotniska_startowego = null;
typ_nowego_lotniska = null;
tile_nowego_lotniska = null;
engine = null;
cargo = null;
nazwa=null;
}

function KWAI::FindRouteBetweenCityAndIndustry()
{
local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()==0)return;

for(local i=1; i<400; i++)
   {
   if(AIEngine.IsValidEngine(this.FindAircraft(AIAirport.GetAirportType(list.Begin()), this.GetPassengerCargoId(), 3, 30000*i)))
       {
	   _koszt=i*30000;
	   break;
	   }
   }
   
for (local aktualna = list.Begin(); list.HasNext(); aktualna = list.Next())
   {
   local pozycja=AIStation.GetLocation(aktualna);
   local airport_type = AIAirport.GetAirportType(pozycja);

   local airport_x, airport_y, airport_rad;
   airport_x = AIAirport.GetAirportWidth(airport_type);
   airport_y = AIAirport.GetAirportHeight(airport_type);
   airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

   local cargo_list = AICargoList();
   for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
      {
	  if(AITile.GetCargoAcceptance(pozycja, cargo, airport_x, airport_y, airport_rad)>10)
	     {
	     //AILog.Info(AICargo.GetCargoLabel(cargo) +" "+AITile.GetCargoAcceptance(pozycja, cargo, airport_x, airport_y, airport_rad));

		 //to szukamy czegos to transportu tego
		 local engine = this.FindAircraft(airport_type, cargo, 3, AICompany.GetBankBalance(AICompany.COMPANY_SELF));

	     if(engine==-1) 
		    {
			//Warning("Engine failed");
			continue;
			}
		 
		 //to szukamy producenta tego syfu
		 local industry_list = rodzic.GetIndustryList_CargoProducing(cargo);
		 if(industry_list.Count()==0)
		    {
			//Warning("Producer failed");
			continue;
			}

		 //dobrych producentów
		 industry_list.Valuate(AIIndustry.GetLastMonthProduction, cargo);
		 industry_list.KeepAboveValue(110-2*desperacja); //HARDCODED OPTION
		 if(industry_list.Count()==0)
		    {
			//Warning(AICargo.GetCargoLabel(cargo) +" "+AITile.GetCargoAcceptance(pozycja, cargo, airport_x, airport_y, airport_rad) + " producer failed: "+ (110-2*desperacja) );
			continue;
			}
		 //Error("@#@")

		 //dalekich producentów
		 industry_list.Valuate(AIIndustry.GetDistanceManhattanToTile, pozycja);
		 industry_list.KeepAboveValue(this.GetMinimalDistance());
		 if(industry_list.Count()==0)
		    {
			Warning("Good producer in distance failed");
			continue;
			}
		 
		 //szukamy miejsca na lotnisko
		 for (local producent = industry_list.Begin(); industry_list.HasNext(); producent = industry_list.Next())
		     {
			local dystans = AIIndustry.GetDistanceManhattanToTile(producent, pozycja);
			local speed = AIEngine.GetMaxSpeed(engine);
			local ile = this.IleSamolotow(dystans, speed);
			if(this.IsItPossibleToAddBurden(aktualna, AIIndustry.GetLocation(producent), engine, ile)==false)continue;
			
			 if(this.CzyJuzZlinkowane(producent, cargo))continue;
			 local zwrot = FindSuitableAirportSpotNearIndustry(airport_type, producent);
			//AILog.Info(AICargo.GetCargoLabel(cargo) + zwrot);
			if(zwrot!=null)
			    {
 				zwrot.id_lotniska_startowego = aktualna;
 				zwrot.typ_nowego_lotniska = airport_type;
 				zwrot.engine = engine;
 				zwrot.cargo = cargo;
 				zwrot.nazwa = AIIndustry.GetName(producent)+" to "+AIStation.GetName(aktualna);
				return zwrot;
				}
			 }
		 }
	  }   
   }
return null;
}

function KWAI::IleSamolotow(dystans, speed)
{
if(((3*dystans)/(2*speed))<3)return 3;
return (3*dystans)/(2*speed);
}

function KWAI::FindSuitableAirportSpotNearIndustry(airport_type, industry_id)
{
local airport_x, airport_y, airport_rad;
local good_tile = 0;
airport_x = AIAirport.GetAirportWidth(airport_type);
airport_y = AIAirport.GetAirportHeight(airport_type);
airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

local tile_list=AITileList_IndustryProducing (industry_id, airport_rad)
tile_list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
tile_list.KeepValue(1);
/* Walk all the tiles and see if we can build the airport at all */
	{
	local test = AITestMode();
    for (local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next()) 
		{
		if (!AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) continue;
		good_tile = tile;
		break;
		}
	}

/* Did we found a place to build the airport on? */
if (good_tile != 0) 
   {
   local zwrot = AirCargoRoute();
   zwrot.tile_nowego_lotniska = good_tile;
   return zwrot;
   }
else 
   {
   return null;
   }
}

function KWAI::CargoConnectionBuilder()
{
AIAI.Info("Trying to build an airport route from industry");

local propozycja = this.FindRouteBetweenCityAndIndustry();

//Info("Trying to build an airport route from industry - scanning completed");

if(propozycja == null) 
   {
   AIAI.Info("Airport cargo route failed");
   return false;
   }
else
   {
   AIAI.Info("Airport cargo route found");
   }

if (!AIAirport.BuildAirport(propozycja.tile_nowego_lotniska, propozycja.typ_nowego_lotniska, AIStation.STATION_NEW)) 
	{
	AILog.Error("Although the testing told us we could build airport we failed at tile " + propozycja.tile_nowego_lotniska + ".");
	return false;
	}
else
   {
   AIAI.Info("Airport constructed");
   }
	
	local tile_2=AIStation.GetLocation(propozycja.id_lotniska_startowego);
	local dystans = AITile.GetDistanceManhattanToTile(propozycja.tile_nowego_lotniska, tile_2);
	local speed = AIEngine.GetMaxSpeed(propozycja.engine);
	local licznik = this.IleSamolotow(dystans, speed);

   AIAI.Info("We want " + licznik + " aircrafts.");

	for(local i=0; i<licznik; i++) 
	   {
	   while(!this.BuildCargoAircraft(propozycja.tile_nowego_lotniska, tile_2, propozycja.engine, propozycja.cargo, propozycja.nazwa))
          {
		  AIAI.Info("Next try");
		  AILog.Error(AIError.GetLastErrorString()+"++++++++++++")
		  if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
		     {
			 return true;
			 }
 		  rodzic.Konserwuj();
		  AIController.Sleep(100);
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
//Info(">");

//Info("<");
if(AIBase.RandRange(20)==1) this.DeadlockPrevention();
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
   
if(AIAI.GetSetting("debug_signs_for_airports_load")) AISign.BuildSign(AIStation.GetLocation(stacja), total+"");
return total;
}

function KWAI::IsItPossibleToAddBurden(stacja, tile, engine, ile=1)
{
local maksimum;
local total = this.GetBurden(stacja);
local airport_type = AIAirport.GetAirportType(AIStation.GetLocation(stacja));
if(airport_type==AIAirport.AT_LARGE) maksimum = 1500; //1 l¹dowanie miesiêcznie - 250 //6 na du¿ym
if(airport_type==AIAirport.AT_SMALL) maksimum = 500; //1 l¹dowanie miesiêcznie - 250 //4 na ma³ym

total+=ile*this.Burden(AIStation.GetLocation(stacja), tile, engine);

return total < maksimum;
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
	   if(AIStation.GetCargoWaiting(aktualna, cargo)>1)
       {
																								//protection from flood of mail planes
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
			 if(airport_type_1==AIAirport.AT_SMALL || airport_type_2==AIAirport.AT_SMALL) 
			    {
				airport_type=AIAirport.AT_SMALL;
				}
			 else
			    {
				airport_type=AIAirport.AT_LARGE;
				}
			
			 /*useless*/
 			 local airport_x_to = AIAirport.GetAirportWidth(airport_type_2);
			 /*useless*/
			 local airport_y_to = AIAirport.GetAirportHeight(airport_type_2);
			 /*useless*/
			 local airport_rad_to = AIAirport.GetAirportCoverageRadius(airport_type_2);

			 local engine=this.FindAircraft(airport_type, cargo, 1, AICompany.GetBankBalance(AICompany.COMPANY_SELF));
			 
		     if(engine==-1) 
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
						if( this.GetPassengerCargoId()==cargo )
						   {
						   if(AITile.GetCargoProduction(tile_2, cargo, airport_x_to, airport_y_to, airport_rad_to)>10)
						   this.BuildPassengerAircraft(tile_1, tile_2, engine, cargo);
						   }
						else if(this.GetMailCargoId()==cargo)
						   {
						   this.BuildExpressAircraft(tile_1, tile_2, engine, cargo);
						   }
						else
						   {
						   this.BuildCargoAircraft(tile_1, tile_2, engine, cargo, "uzupelniacz");
						   }
						}
				     }
				}
			 }
		   }
	   }   
   }
}

function CzyToPassengerCargoValuator(veh)
   {
   if(AIVehicle.GetCapacity(veh, KWAI.GetPassengerCargoId())>0)return 1;
   return 0;
   }

function KWAI::DeadlockPrevention()
{
Warning("DeadlockPrevention");
local list = AIVehicleList();

local list = AIStationList(AIStation.STATION_AIRPORT);

for (local station = list.Begin(); list.HasNext(); station = list.Next())
    {
    local hangar = AIAirport.GetHangarOfAirport(AIStation.GetLocation(station));
	local veh_list;
	
	veh_list = AIVehicleList_Station(station);
	veh_list.Valuate(CzyToPassengerCargoValuator);
	veh_list.KeepValue(0);
	if(veh_list.Count()==0)continue;

	veh_list.Valuate(AIVehicle.GetLocation);
	veh_list.KeepValue(hangar);
	if(veh_list.Count()==0)continue;
	
	veh_list = AIVehicleList_Station(station);
	veh_list.Valuate(CzyToPassengerCargoValuator);
	veh_list.KeepValue(0);
	if(veh_list.Count()==0)continue;
	
	local veh = veh_list.Begin();
    Skip(veh, station);
/*
	AIVehicle.SendVehicleToDepot(veh)
    AIController.Sleep(10);
    AIVehicle.SendVehicleToDepot(veh);

		 for ( veh_list.HasNext(); veh = veh_list.Next())
		{
         AIVehicle.SendVehicleToDepot(veh);
	     AIController.Sleep(10);
	     AIVehicle.SendVehicleToDepot(veh);
	     continue;
		 }
*/
   }
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
		    if(AIVehicle.GetCapacity(plane, this.GetPassengerCargoId())>0)
			{
			local percent = ( 100 * AIVehicle.GetCargoLoad(plane, this.GetPassengerCargoId()))/(AIVehicle.GetCapacity(plane, this.GetPassengerCargoId()));
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

function KWAI::FindSuitableAirportSpotInTown(airport_type, center_tile)
{
	local airport_x, airport_y, airport_rad;

	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);
	local town_list = AITownList();

	town_list.Valuate(AITown.GetLocation);
	
	/* Remove all the towns we already used */
	local station_list=AIStationList(AIStation.STATION_AIRPORT);
	for(local i=station_list.Begin(); station_list.HasNext(); i=station_list.Next())
	    {
		local location;
		local town;
	
		location = AIStation.GetLocation(i);
	    town = AITile.GetClosestTown(location);
		town_list.RemoveValue(AITown.GetLocation(town));
	
		location = AIStation.GetLocation(i)+AIMap.GetTileIndex(0, 8);
	    town = AITile.GetClosestTown(location);
		town_list.RemoveValue(AITown.GetLocation(town));
		
		location = AIStation.GetLocation(i)+AIMap.GetTileIndex(0, -8);
	    town = AITile.GetClosestTown(location);
		town_list.RemoveValue(AITown.GetLocation(town));

		location = AIStation.GetLocation(i)+AIMap.GetTileIndex(-8, 0);
	    town = AITile.GetClosestTown(location);
		town_list.RemoveValue(AITown.GetLocation(town));

		location = AIStation.GetLocation(i)+AIMap.GetTileIndex(8, 0);
	    town = AITile.GetClosestTown(location);
		town_list.RemoveValue(AITown.GetLocation(town));
		}

	town_list.Valuate(this.PopulationWithRandValuator);
	town_list.KeepAboveValue(500);

	if (center_tile != 0) {
    town_list.Valuate(AITown.GetDistanceManhattanToTile, center_tile);
	town_list.KeepAboveValue(this.GetMinimalDistance());    
	town_list.KeepBelowValue(this.GetMaximalDistance());    
	}
	
	town_list.Valuate(this.DistanceWithRandValuator, center_tile);
	//TODO - wed³ug dystansu optimum to 500
	   
	/* Keep the best 10, if we can't find 2 stations in there, just leave it anyway */
	town_list.KeepBottom(50);

	/* Now find 2 suitable towns */
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next()) {

    	local tile = AITown.GetLocation(town);

		local list = AITileList();
		local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
		SafeAddRectangle(list, tile, range);

		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
		list.KeepValue(1);
		/* Sort on acceptance, remove places that don't have acceptance */
		list.Valuate(AITile.GetCargoAcceptance, this.GetPassengerCargoId(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(50);

		list.Valuate(AITile.GetCargoAcceptance, this.GetMailCargoId(), airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(10);

		/* Couldn't find a suitable place for this town, skip to the next */
		if (list.Count() == 0) continue;
		/* Walk all the tiles and see if we can build the airport at all */
		{
			local test = AITestMode();
			local good_tile = 0;

			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
				if (!AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) continue;
				good_tile = tile;
				break;
			}

			/* Did we found a place to build the airport on? */
			if (good_tile == 0) continue;
		}

		AILog.Info("Found a good spot for an airport in town " + town + " at tile " + tile);

		return tile;
	}

	AILog.Info("Couldn't find a suitable town to build an airport in");
	return -1;
}

function KWAI::GetPassengerCargoId()
{
local cargo_list = AICargoList();
cargo_list.Valuate(AICargo.HasCargoClass, AICargo.CC_PASSENGERS);
cargo_list.KeepValue(1);
cargo_list.Valuate(AICargo.GetTownEffect);
cargo_list.KeepValue(AICargo.TE_PASSENGERS);
cargo_list.Valuate(AICargo.GetTownEffect);
cargo_list.KeepValue(AICargo.TE_PASSENGERS);

if(!AICargo.IsValidCargo(cargo_list.Begin()))
{
	AILog.Error("PAX Cargo do not exist");
}

cargo_list.Valuate(AICargo.GetCargoIncome, 1, 1); //Elimination ECS tourists
cargo_list.KeepBottom(1);

return cargo_list.Begin();
}

function KWAI::GetMailCargoId()
{
local list = AICargoList();
for (local i = list.Begin(); list.HasNext(); i = list.Next()) 
	{
	if(AICargo.GetTownEffect(i)==AICargo.TE_MAIL)
		{
		return i;
		}
	}
return null;
}

