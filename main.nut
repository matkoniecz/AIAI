class AIAI extends AIController 
{
desperacja = null;
generalna_konserwacja = null;
root_tile = null;
station_number = null;
detected_rail_crossings = null;
}

require("findpair.nut");
require("util.nut");
require("UTILtile.nut");
require("AIAI.nut");

require("Builder.nut");
require("RAIL/RailBuilder.nut");
require("RAIL/SmartRailBuilder.nut");
require("RAIL/StupidRailBuilder.nut");
require("ROAD/RoadBuilder.nut");
require("ROAD/BusRoadBuilder.nut");
require("ROAD/TruckRoadBuilder.nut");
require("AIR/AirBuilder.nut");
require("AIR/PAXAirBuilder.nut");
require("AIR/CargoAirBuilder.nut");

import("util.superlib", "SuperLib", 5);

Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction

function AIAI::Starter()
{
Name();
HQ();
station_number = 1; //TODO load it
if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")!= 0) AICompany.SetAutoRenewStatus(true);
AICompany.SetAutoRenewMonths(0);
AICompany.SetAutoRenewMoney(100000); //from ChooChoo

AILog.Info("");
Info("Hi!!!");

detected_rail_crossings=AIList()

//TODO - LOAD IT
desperacja = 0;
generalna_konserwacja = GetDate();
//Autoreplace(); TODO: when?
}

function AIAI::Menagement()
{
root_tile = RandomTile();
this.SignMenagement();
this.MoneyMenagement();
this.Statua();
}

function AIAI::Start()
{
this.Starter();

local builders = array(6);
builders[0] = PAXAirBuilder(this, 0);
builders[1] = SmartRailBuilder(this, 0);
builders[2] = StupidRailBuilder(this, 0);
builders[3] = TruckRoadBuilder(this, 0);
builders[4] = BusRoadBuilder(this, 0);
builders[5] = CargoAirBuilder(this, 0);


while(true)
	{
	IdleMoneyMenagement();

	Error("Desperacja: " + desperacja);

	this.Menagement();
	
	this.Konserwuj();
   
	if(this.EverythingFailed(builders))
		{
		Info("Nothing to do!");
		Sleep(1000);
		continue;
		}
	
	this.InformationCenter(builders);
		
	if(!this.UberBuilder(builders)) desperacja++;
	else desperacja = 0;
	}
}

function AIAI::InformationCenter(builders)
{
for(local i = 0; i<builders.len(); i++)
	{
	builders[i].SetDesperacja(desperacja);
	}
}

function AIAI::EverythingFailed(builders)
{
for(local i = 0; i<builders.len(); i++)
	{
	if(builders[i].Possible())
		{
		return false;
		}
	}
return true;
}

function AIAI::UberBuilder(builders)
{
for(local i = 0; i<builders.len(); i++)
	{
	if(builders[i].Possible())
		{
		if(builders[i].Go()) 
			{
			RepayLoan();
			return true;
			}
		RepayLoan();
		}
	}
return false;
}

function AIAI::Statua()
{
local veh_list = AIVehicleList();
veh_list.Valuate(AIBase.RandItem);
veh_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
for (local veh = veh_list.Begin(); !veh_list.IsEnd(); veh = veh_list.Next()) 
   {
   for(local i=0; i<AIOrder.GetOrderCount(veh); i++)
      {
	  local location = AIOrder.GetOrderDestination(veh, i);
	  if(AITile.IsStationTile(location))
		{
	    if(AIOrder.GetOrderFlags(veh, i)!=AIOrder.AIOF_NO_LOAD)
		{
		local station = AIStation.GetStationID(location);
		local suma = 0;
		local cargo_list = AICargoList();
		for (local cargo = cargo_list.Begin(); !cargo_list.IsEnd(); cargo = cargo_list.Next()) suma+=AIStation.GetCargoWaiting(station, cargo);
		if(suma<200) //HARDCODED
		if(AIVehicle.GetVehicleType(veh)==AIVehicle.VT_RAIL || AICompany.GetBankBalance(AICompany.COMPANY_SELF)>AICompany.GetMaxLoanAmount() || desperacja>30)
		   {
		   if(AITown.PerformTownAction(AITile.GetClosestTown(location), AITown.TOWN_ACTION_BUILD_STATUE)) 
		      {
			  Warning("Statue for " + AIVehicle.GetName(veh));
			  return true;
			  }
		   else
		      {
		      if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) return false;
			  }
		   }
		  }
		}
	  }
   }

Error("Statua construction failed");
return false;
}

function AIAI::SignMenagement()
{
if(AIAI.GetSetting("clear_signs"))
{
local sign_list = AISignList();
for (local x = sign_list.Begin(); !sign_list.IsEnd(); x = sign_list.Next()) //from Chopper
  {
  AISign.RemoveSign(x);
  }
}

if(AIAI.GetSetting("debug_signs_for_airports_load"))
{
local list = AIStationList(AIStation.STATION_AIRPORT);
for (local x = list.Begin(); !list.IsEnd(); x = list.Next()) 
   {
   air.GetBurden(x);
   }
}
}

function BankruptProtector()
{
if(AIVehicleList().Count()==0) return;
if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<AICompany.GetLoanInterval()*2)
{
AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
	{
	if(AIBase.RandRange(10)==1)Error("We need bailout!");
	else Error("We need money!");
	while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
		{
		AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
		if(AICompany.GetLoanAmount()==AICompany.GetMaxLoanAmount())
			{
			Error("We are too big to fail! Remember, we employ " + (AIVehicleList().Count()*7+AIStationList(AIStation.STATION_ANY).Count()*3+23) + " people!!!");
			Sleep(1000);
			}
		}
	}
Warning("End of financial problems!");
}	   
}

function AIAI::IdleMoneyMenagement()
{
if(AIVehicleList().Count()==0) return;
BankruptProtector();
while((AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount())<100000)
	{
	Info("Waiting for more money: " + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount())/1000 + "k / 100k"); //TODO: inflate (also in while)
	while(AICompany.SetLoanAmount(AICompany.GetLoanAmount() - AICompany.GetLoanInterval()));
	BankruptProtector();
	Sleep(500);
	this.Konserwuj();
	}
}

function AIAI::MoneyMenagement()
{
BankruptProtector();
}

function AIAI::IsConnectedIndustry(industry_id, cargo)
{
local returnik = realcodeofIsConnectedIndustry(industry_id, cargo);
//AISign.BuildSign(AIIndustry.GetLocation(industry_id), returnik+"");
return returnik;
}

function AIAI::realcodeofIsConnectedIndustry(industry_id, cargo)
{
if((RoadBuilder(this, 0)).IsConnectedIndustry(industry_id, cargo)==true)return true;
return (AirBuilder(this, 0)).IsConnectedIndustry(industry_id, cargo);
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
   SetNameOfVehicle(main_vehicle_id, "for sell " + why);
   return true;
   }
return false;
}

function VehicleCounter(station)
{
return AIVehicleList_Station(station).Count();
}

function AIAI::DeleteEmptyStations()
{
local list;
list = AIStationList(AIStation.STATION_TRUCK_STOP);
list.Valuate(VehicleCounter);
list.KeepValue(0);
for (local spam = list.Begin(); !list.IsEnd(); spam = list.Next()) AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));

list = AIStationList(AIStation.STATION_BUS_STOP);
list.Valuate(VehicleCounter);
list.KeepValue(0);
for (local spam = list.Begin(); !list.IsEnd(); spam = list.Next()) AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));

//TODO: station may be under construction: ADD it after hiding stations during construction, TODO: add ignore possibility to rail PF 
//list = AIStationList(AIStation.STATION_TRAIN);
//list.Valuate(VehicleCounter);
//list.KeepValue(0);
//for (local spam = list.Begin(); !list.IsEnd(); spam = list.Next()) AITile.DemolishTile(AIBaseStation.GetLocation(spam));
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

	Info(vehicle_list.Count() + " vehicle(s) should be sold because are unprofitable");
   	
	local counter = 0;
	
	for (local veh = vehicle_list.Begin(); !vehicle_list.IsEnd(); veh = vehicle_list.Next()) 
	   {
	   if(AIVehicle.GetVehicleType(veh)!=AIVehicle.VT_RAIL || (AIVehicleList_Station(AIStation.GetStationID(GetLoadStation(veh)))).Count()>2)
	      {
		  if(AIAI.sellVehicle(veh, "unprofitable")) counter++;
		  }
	   }
	Info(counter + " vehicle(s) sold.");
	generalna_konserwacja = GetDate();
}

function AIAI::Konserwuj()
{
this.MoneyMenagement();
this.HandleOldLevelCrossings();

local maintenance = array(3);
maintenance[0] = RailBuilder(this, 0);
maintenance[1] = RoadBuilder(this, 0);
maintenance[2] = AirBuilder(this, 0);

for(local i = 0; i<maintenance.len(); i++)
	{
	maintenance[i].Konserwuj();
	}

this.DeleteVehiclesInDepots();
this.HandleEvents();
if((GetDate()-generalna_konserwacja)>12) //powinno raz na 12 miesiêcy
    {
	this.DeleteUnprofitable();
	DeleteEmptyStations();
	}
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
				this.HandleNewLevelCrossing(event);
			}
		}
		else if(ev_type == AIEvent.AI_ET_ENGINE_PREVIEW) //from simpleai
		{
		event = AIEventEnginePreview.Convert(event);
		if (event.AcceptPreview()) 
		   {
		   Info("New engine available from preview: " + event.GetName());
		   Autoreplace();
			if(event.GetVehicleType() == AIVehicle.VT_RAIL)(RailBuilder(this, 0)).TrainReplace();
		   }
		}
		else if(ev_type == AIEvent.AI_ET_ENGINE_AVAILABLE)//from simpleai
		{
		event = AIEventEngineAvailable.Convert(event);
		local engine = event.GetEngineID();
		Info("New engine available: " + AIEngine.GetName(engine));
		Autoreplace();
		if(AIEngine.GetVehicleType(engine) == AIVehicle.VT_RAIL)(RailBuilder(this, 0)).TrainReplace();
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
				if (AICompany.IsMine(company))
				   {
				   if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0) AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
				   this.MoneyMenagement();
				   }
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

function IntToStrFill(int_val, num_digits) //from ClueHelper
{
	local str = int_val.tostring();

	while(str.len() < num_digits)
	{
		str = "0" + str;
	}

	return str;
}

function AIAI::SetStationName(location)
{
local station = AIStation.GetStationID(location);
local string;
do
	{
	string = IntToStrFill(station_number, 9);
	station_number++;
	}
while(!AIBaseStation.SetName(station, string))
}