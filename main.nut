/*
TODO: remove empty stations
TODO: protect trains from selling and cloning WTF

TODO: Autoreplace for trains
TODO: terminus RV station=
TODO: rework buspair
TODO: better RV depot placing (replace double flat by test mode)
TODO: more working depots
TODO: check jams before RV building
TODO: reuse existing roads constructed by another players
TODO: For all newly build routes, check both ways. This way, if one-way roads are build, another road is build next to it so vehicles can go back. //from admiralai
TODO: long bridges sometimes are unavailable!
TODO: helicopters
TODO: dodawanie samolotów zale¿ne od pojemnoœci
TODO: - RV stations use both directions - make it also in second function!

TODO: bus scanner
	- construction of 2 bus stops
	- 1 bus
	- go on route WITHOUT pathfinding
	- vehicle is lost
		- route construction is needed
	- vehicle is profitable - we parasited succesfully
	limitation: real players rarely construct intercity routes

Changelog
- Cargo trains! [really stupid cargo trains]
- Support for 2cc, NARS, default trains. Probably also other newgrf.
- Removes useless railways
- RV stations use both directions
- industry to industry plane routes (av8 or other cargo planes needed)
- Airport capacity bug fixed
- Bus buying bug fixed
- Passengers are no longer "processed cargo"
- capping truck stations with depots, if circle around station failed
- Fixed ignored "Trucks allowed" setting

*/

class AIAI extends AIController 
{
desperacja = null;
generalna_konserwacja = null;
root_tile = null;
air=null;
RV=null;
OMGtrain = null;
}

require("findpair.nut");
require("util.nut");
require("UTILtile.nut");
require("KRAI.nut");
require("AIAI.nut");
require("KWAI.nut");
require("RAIL.nut");

import("util.superlib", "SuperLib", 2);

Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction

function AIAI::Starter()
{
Name();
HQ();

AICompany.SetAutoRenewStatus(true);
AICompany.SetAutoRenewMonths(0);
AICompany.SetAutoRenewMoney(100000); //from ChooChoo

AILog.Info("");
Info("Hi!!!");

//TODO - do it in their constructors
air = KWAI();
air.rodzic=this;
RV = KRAI();
RV.rodzic=this;
RV.detected_rail_crossings=AIList()
OMGtrain = RAIL();
OMGtrain.rodzic = this;

//TODO - LOAD IT
desperacja = 0;
RV._koszt = 1;
air._koszt = 1;
generalna_konserwacja = GetDate();
Autoreplace();
}

function AIAI::Menagement()
{
root_tile = RandomTile();
this.SignMenagement();
this.MoneyMenagement();
this.Statua();
this.Konserwuj();
}

function AIAI::Start()
{
this.Starter();

while(true)
   {
   this.Menagement();

	local StupidCargoRailConnection = AICompany.GetBankBalance(AICompany.COMPANY_SELF) > OMGtrain._koszt && IsAllowedStupidCargoTrain();
	local truck = AICompany.GetBankBalance(AICompany.COMPANY_SELF) > RV._koszt && IsAllowedTruck();
	local PAX_plane = AICompany.GetBankBalance(AICompany.COMPANY_SELF) > air._koszt && IsAllowedPAXPlane();
	local bus = AICompany.GetBankBalance(AICompany.COMPANY_SELF) > RV._koszt && IsAllowedBus();
	local cargo_plane = AICompany.GetBankBalance(AICompany.COMPANY_SELF) > air._koszt && IsAllowedCargoPlane();
	local wszystkoszszlagtrafil = !(StupidCargoRailConnection || truck || PAX_plane || bus || cargo_plane);
   if(wszystkoszszlagtrafil)continue;

	air.desperacja = desperacja;
	RV.desperacja = desperacja;
	OMGtrain.desperacja = desperacja;

	AILog.Warning("desperation: " + desperacja);
	AILog.Warning("air: " + air._koszt);
	AILog.Warning("RV: " + RV._koszt);
	AILog.Warning("RAIL: " + OMGtrain._koszt);

if(StupidCargoRailConnection) if(OMGtrain.StupidRailConnection()) 
    {
	desperacja = 0;
	continue;
	}
if(truck) if(RV.TruckRoute()) 
    {
	desperacja = 0;
	continue;
	}
if(PAX_plane) if(air.BuildAirportRouteBetweenCities()) 
    {
	desperacja = 0;
	continue;
	}
if(bus) if(RV.BusRoute()) 
    {
	desperacja = 0;
	continue;
	}
if(cargo_plane) if(air.CargoConnectionBuilder()) 
    {
	desperacja = 0;
	continue;
	}
	Error("desperacja++;");
   desperacja++;
   }
}

function AIAI::Statua()
{
   if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>AICompany.GetMaxLoanAmount())
        {
		if(ZbudujStatue())
		   {
		   Info("Zbudowane statue!");
		   }
		}
    else
	  {
      if(desperacja>30)
        {
		local save = AICompany.GetLoanAmount();
		AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
		if(ZbudujStatue())
		   {
		   Info("Zbudowane statue!");
   		   desperacja=0;
		   }
		AICompany.SetLoanAmount(save);
		}
	   }
}

function AIAI::SignMenagement()
{
if(AIAI.GetSetting("clear_signs"))
{
for(local i=0; true; i++)
   {
   local sign_list = AISignList();
   for (local x = sign_list.Begin(); sign_list.HasNext(); x = sign_list.Next()) //from Chopper
    {
	AISign.RemoveSign(x);
	}
   }
}

if(AIAI.GetSetting("debug_signs_for_airports_load"))
{
local list = AIStationList(AIStation.STATION_AIRPORT);
for (local x = list.Begin(); list.HasNext(); x = list.Next()) 
   {
   air.GetBurden(x);
   }
}
}

function AIAI::MoneyMenagement()
{
if(AIVehicleList().Count()==0)AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>AICompany.GetLoanInterval())
	{
    AICompany.SetLoanAmount(AICompany.GetLoanAmount()-AICompany.GetLoanInterval());
    }

if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
{
if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0) AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
	{
	if(AIBase.RandRange(10)==1)AILog.Error("We need bailout!");
	else AILog.Error("We need money!");
	while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
		{
		AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
		if(AICompany.GetLoanAmount()==AICompany.GetMaxLoanAmount())
			{
			AILog.Error("We are too big to fail! Remember, we employ " + (AIVehicleList().Count()*7+AIStationList(AIStation.STATION_ANY).Count()*3) + " people!!!");
			Sleep(1000);
			}
		}
	}
AILog.Warning("End of financial problems!");
}

local money;
local available_loan;

available_loan = AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount();
money = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
if(money<air._koszt)
   if(available_loan+money>air._koszt)
       AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());

available_loan = AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount();
money = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
if(money<RV._koszt)
   if(available_loan+money>RV._koszt)
       AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
	   
available_loan = AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount();
money = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
if(money<OMGtrain._koszt)
   if(available_loan+money>OMGtrain._koszt)
       AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
	   
}

function AIAI::IsConnectedIndustry(industry_id, cargo)
{
local returnik = realcodeofIsConnectedIndustry(industry_id, cargo);
//AISign.BuildSign(AIIndustry.GetLocation(industry_id), returnik+"");
return returnik;
}

function AIAI::realcodeofIsConnectedIndustry(industry_id, cargo)
{
if(RV.IsConnectedIndustry(industry_id, cargo)==true)return true;
return air.IsConnectedIndustry(industry_id, cargo);
}


function AIAI::IsConnectedDistrict(town_tile)
{
//if(AIAI.GetSetting("deep_debugged_function_calling"))Info("IsConnectedDistrict<");

local list = AIStationList(AIStation.STATION_AIRPORT);
if(list.Count()!=0)
  {
  list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
  list.KeepBelowValue(18);
  //if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">IsConnectedDistrict");
  if(!list.IsEmpty())return true;
  }

list = AIStationList(AIStation.STATION_BUS_STOP);
if(list.Count()!=0)
  {
  list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
  list.KeepBelowValue(8);
  //if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">IsConnectedDistrict");
  if(!list.IsEmpty())return true;
  }

//if(AIAI.GetSetting("deep_debugged_function_calling"))Info(">IsConnectedDistrict");
return false;
}

function AIAI::GetDate()
{
local date=AIDate.GetCurrentDate ();
return AIDate.GetYear(date)*12 + AIDate.GetMonth(date);
}

function AIAI::Info(string)
{
local date=AIDate.GetCurrentDate ();
AILog.Info(AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date)  + " " + string);
}

function AIAI::Debug(string)
{
local date=AIDate.GetCurrentDate ();
AILog.Info(AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date)  + "." + string);
}

function AIAI::Save()
{
  local table = {counter_value = null};
  return table;
}

function AIAI::Load(version, data)
{
}

function AIAI::CzyNaSprzedaz(car)
{
local name=AIVehicle.GetName(car)+"            ";
local forsell="for sell";
local n=6;

for(local i=0; i<n; i++)
if(name[i]!=forsell[i])return false;
return true;
}

function AIAI::sellVehicle(main_vehicle_id, why)
{
if(AIAI.CzyNaSprzedaz(main_vehicle_id)==true)return false;

if(AIVehicle.SendVehicleToDepot(main_vehicle_id))
   {
   if(!AIVehicle.SetName(main_vehicle_id, "for sell " + why))
      {
	  local o=1;
	  while(!AIVehicle.SetName(main_vehicle_id, "for sell # "+o + " " + why)){o++;}
	  }
   return true;
   }
return false;
}

function AIAI::DeleteEmptyRVStations()
{
list = AIStationList(AIStation.STATION_ANY);
list.Valuate(AIStation.HasStationType, AIStation.STATION_TRAIN);
list.RemoveValue(1);
list.Valuate(AIStation.HasStationType, AIStation.STATION_AIRPORT);
list.RemoveValue(1);
list.Valuate(AIStation.HasStationType, AIStation.STATION_DOCK);
list.RemoveValue(1);
//TODO HOW TO PREVENT FROM DELETING STATION DURING CONSTRUCTION???
}

function AIAI::DeleteUnprofitable()
{
	local vehicle_list = AIVehicleList();

   	vehicle_list.Valuate(AIAI.CzyNaSprzedaz);
	vehicle_list.KeepValue(0);

   	vehicle_list.Valuate(AIVehicle.GetAge);
	vehicle_list.KeepAboveValue(800);

   	vehicle_list.Valuate(AIVehicle.GetProfitThisYear);
	vehicle_list.KeepBelowValue(0);
   	vehicle_list.Valuate(AIVehicle.GetProfitLastYear);
	vehicle_list.KeepBelowValue(0);

	Info(vehicle_list.Count() + " vehicles should be sold because are unprofitable");
   	
	local counter = 0;
	
	for (local veh = vehicle_list.Begin(); vehicle_list.HasNext(); veh = vehicle_list.Next()) if(AIAI.sellVehicle(veh, "unprofitable")) counter++;
	
	Info(counter + " vehicles sold.");
	generalna_konserwacja = GetDate();
}

function AIAI::Konserwuj()
{
//Error("<");

//Warning("<");
RV.Konserwuj();
//Warning(">");

//Warning("<");
air.Konserwuj();
//Warning(">");

//Warning("<");
this.DeleteVehiclesInDepots();
//Warning(">");

//Warning("<");
this.HandleEvents();
//Warning(">");

//Warning("<");
if((GetDate()-generalna_konserwacja)>12) //powinno raz na 12 miesiêcy
    {
	this.DeleteUnprofitable();
	//DeleteEmptyRVStations();
	}
//Warning(">");

//Error(">");
}

function AIAI::HandleEvents() //from CluelessPlus and simpleai
{
	while(AIEventController.IsEventWaiting())
	{
		local event = AIEventController.GetNextEvent();

		if(event == null)
			return;

		local ev_type = event.GetEventType();

		if(ev_type == AIEvent.AI_ET_VEHICLE_LOST)//from CluelessPlus
		{
		
    		Error("Vehicle lost event detected!");
			local lost_event = AIEventVehicleLost.Convert(event);
			local lost_veh = lost_event.GetVehicleID();

			/*
			local connection = ReadConnectionFromVehicle(lost_veh);
			
			if(connection.station.len() >= 2 && connection.connection_failed != true)
			{
				AILog.Info("Try to connect the stations again");

				if(!connection.RepairRoadConnection())
					SellVehicle(lost_veh);
			}
			else
			{
				SellVehicle(lost_veh);
			}
			*/
			
		}
		else if(ev_type == AIEvent.AI_ET_VEHICLE_CRASHED)//from CluelessPlus
		{

			local crash_event = AIEventVehicleCrashed.Convert(event);
			local crash_reason = crash_event.GetCrashReason();
			//local vehicle_id = crash_event.GetVehicleID();
			//local crash_tile = crash_event.GetCrashSite();
			if(crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING)
			{
				RV.HandleNewLevelCrossing(event);
			}
		}
		else if(ev_type == AIEvent.AI_ET_ENGINE_PREVIEW) //from simpleai
		{
		event = AIEventEnginePreview.Convert(event);
		if (event.AcceptPreview()) 
		   {
		   Info("New engine available for preview: " + event.GetName());
		   Autoreplace();
		   }
		}
		else if(ev_type == AIEvent.AI_ET_ENGINE_AVAILABLE)//from simpleai
		{
		event = AIEventEngineAvailable.Convert(event);
		local engine = event.GetEngineID();
		Info("New engine available: " + AIEngine.GetName(engine));
		Autoreplace();
		}
		else if(ev_type == AIEvent.AI_ET_COMPANY_NEW)//from simpleai
		{
		event = AIEventCompanyNew.Convert(event);
		local company = event.GetCompanyID();
		Warning("Welcome " + AICompany.GetName(company));
		}
		else if(ev_type == AIEvent.AI_ET_COMPANY_IN_TROUBLE)//from simpleai
		{
				event = AIEventCompanyInTrouble.Convert(event);
				local company = event.GetCompanyID();
				if (AICompany.IsMine(company)) Error("I'm in trouble, I don't know what to do!");
		/* TODO: Handle it. */
		}
		else if(ev_type == AIEvent.AI_ET_INDUSTRY_OPEN)//from simpleai
		{
		event = AIEventIndustryOpen.Convert(event);
		local industry = event.GetIndustryID();
		Info("New industry: " + AIIndustry.GetName(industry));
		/* TODO: Handle it. */
		}
		else if(ev_type == AIEvent.AI_ET_INDUSTRY_CLOSE)//from simpleai
		{
		event = AIEventIndustryClose.Convert(event);
		local industry = event.GetIndustryID();
		if (AIIndustry.IsValidIndustry(industry))
		    {
			Info("Closing industry: " + AIIndustry.GetName(industry));
			/* TODO: Handle it. */
			}
		}
		else
		{
		;
		}
	}
}

