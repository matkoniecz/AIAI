/*
vehicles shouldn't be built if accceptation of cargo is stopped
//stockpile handling - impossible


zastêpowanie pojazdów - done?

Todo in truck module
checking for stations without vehicles
checking for vehicles without stations
event handling
reuse existing roads constructed by another players
industry to city routes
For all newly build routes, check both ways. This way, if one-way roads are build, another road is build next to it so vehicles can go back. //from admiralai

Todo in air module
helicopters
industry to industry routes
dodawanie samolotów zale¿ne od pojemnoœci
*/

class AIAI extends AIController 
{
desperacja = null;
air=null;
truck=null;
}

require("KRAI.nut");
require("AIAI.nut");
require("util.nut");
require("KWAI.nut");

function AIAI::Start()
{
Name();
HQ();

AICompany.SetAutoRenewStatus(true);
AICompany.SetAutoRenewMonths(0);
AICompany.SetAutoRenewMoney(10000); //from ChooChoo

AILog.Info("");
Info("Hi!!!");

air = KWAI();
air.rodzic=this;

truck = KRAI();
truck.rodzic=this;

desperacja = 0;

for(local i=0; true; i++)
   {
   if(AIAI.GetSetting("clear_signs"))
   {
   local sign_list = AISignList();
   for (local x = sign_list.Begin(); sign_list.HasNext(); x = sign_list.Next()) //from Chopper
    {
	AISign.RemoveSign(x);
	}
   }
   
   local list = AIStationList(AIStation.STATION_AIRPORT);
   for (local x = list.Begin(); list.HasNext(); x = list.Next()) 
      {
	  air.GetBurden(x);
	  }
	
   air.desperacja = desperacja;
   truck.desperacja = desperacja;

   this.MoneyMenagement();

   AILog.Warning("desperation: " + desperacja);
   AILog.Warning("air: " + air._koszt);
   AILog.Warning("truck: " + truck._koszt);
   
   if(desperacja>1000)
      {
	  Info("We wait for better times.");
	  Sleep(200);
	  }
	  
   if(
     (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > truck._koszt && IsAllowedTruck() && truck._koszt!=0)||
     (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > air._koszt && IsAllowedPlane() && air._koszt!=0)
	 )
      {
	  local air_city = false; 
	  local air_cargo = false; 
	  local truck_cargo = false;
	  if(IsAllowedPlane())air_city = air.BuildAirportRouteBetweenCities();
	  if(IsAllowedTruck())truck_cargo = truck.skonstruj_trase();
	  if(IsAllowedPlane())air_cargo = air.CargoConnectionBuilder();
	  if((air_cargo||air_city||truck_cargo)==false)
	     {
		 desperacja++;
		 }
	  else 
	     {
		 desperacja=0;
		 }
	  }
	else 
	   {
	   Sleep(100);
       desperacja=1;
	   if(IsAllowedPlane()) air.BuildAirportRouteBetweenCities();
	   if(IsAllowedTruck()) truck.skonstruj_trase();
	   if(IsAllowedPlane()) air.CargoConnectionBuilder();
	   }

   this.Konserwuj();
   if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>AICompany.GetMaxLoanAmount()*2)
        {
		ZbudujStatue();
		}
    else
	  {
	  if(AIBase.RandRange(10)==1)
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
if(money<truck._koszt)
   if(available_loan+money>truck._koszt)
       AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
	   
}

function AIAI::IsConnectedIndustry(industry_id)
{
}

function AIAI::IsConnectedDistrict(town_tile)
{

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

function AIAI::Konserwuj()
{
truck.Konserwuj();
air.Konserwuj();
if(desperacja)if(AIBase.RandRange(50)==1)Autoreplace(); //TODO - wywo³aæ gdy pojawia siê nowy pojazd/przeglad pojazdu (ale do tego trzeba obs³ugi wydarzeñ)
}

function NajmlodszyPojazd(station)
{
local list = AIVehicleList_Station(station);
local minimum = 10000;
for (local q = list.Begin(); list.HasNext(); q = list.Next()) //from Chopper 
   {
   local age=AIVehicle.GetAge(q);
   if(minimum>age)minimum=age;
   }

return minimum;
}

function GetAverageCapacity(station, cargo)
{
local list = AIVehicleList_Station(station);
local total = 0;
local ile = 0;
for (local q = list.Begin(); list.HasNext(); q = list.Next()) //from Chopper 
   {
   local plus=AIVehicle.GetCapacity (q, cargo);
   if(plus>0)
      {
	  total+=plus;
	  ile++;
	  }
   }
if(ile==0)return 0;
else return total/ile;
}