function Info(string)
{
local date=AIDate.GetCurrentDate ();
AILog.Info(AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date)  + " " + string);
}

function Warning(string)
{
local date=AIDate.GetCurrentDate ();
AILog.Warning(AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date)  + " " + string);
}

function Error(string)
{
local date=AIDate.GetCurrentDate ();
AILog.Error(AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date)  + " " + string);
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

function GetDepot(vehicle)
{
for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) if(AIOrder.IsGotoDepotOrder(vehicle, i))return AIOrder.GetOrderDestination(vehicle, i);
Warning("Explosion caused by vehicle " + AIVehicle.GetName(vehicle));
Warning("Please, post savegame");
local zero=0/0;
}
function GetLoadStation(vehicle)
{
for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) if(AIOrder.IsGotoStationOrder(vehicle, i))return AIOrder.GetOrderDestination(vehicle, i);
Warning("Explosion caused by vehicle " + AIVehicle.GetName(vehicle));
Warning("Please, post savegame");
local zero=0/0;
}

function GetUnLoadStation(vehicle)
{
local onoff = false;

for(local i=0; i<AIOrder.GetOrderCount(vehicle); i++) 
   {
   if(AIOrder.IsGotoStationOrder(vehicle, i))
      {
	  if(onoff==true)return AIOrder.GetOrderDestination(vehicle, i);
	  onoff=true
	  }
   }
Warning("Explosion caused by vehicle " + AIVehicle.GetName(vehicle));
Warning("Please, post savegame");
local zero=0/0;
}

function GetVehicleType(vehicle_id)
{
return AIEngine.GetVehicleType(AIVehicle.GetEngineType(vehicle_id));
}

function IsAllowedPlane()
{
if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR))return false;
if(0 == AIAI.GetSetting("use_planes"))return false;

if(AIGameSettings.IsValid("vehicle.max_aircraft")==false) 
   {
   AILog.Error("ARGHH");
   AILog.Error("NAME OF SETTING CHANGED, PLEASE REPORT IT, AIAI MAY BEHAVE STRANGE");
   return true;
   }

local ile;
local veh_list = AIVehicleList();
veh_list.Valuate(GetVehicleType);
veh_list.KeepValue(AIVehicle.VT_AIR);
ile = veh_list.Count();
local allowed = AIGameSettings.GetValue("vehicle.max_aircraft");

if(allowed==0)return false;
if(ile==0)return true;

if((allowed - ile)<4) return false;
if(((ile*100)/(allowed))>90) return false;
return true;
}

function IsAllowedTruck()
{
if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD))return false;
if(0 == AIAI.GetSetting("use_trucks"))
   {
   return false;
   }
if(AIGameSettings.IsValid("vehicle.max_roadveh")==false) 
   {
   AILog.Error("ARGHH");
   AILog.Error("NAME OF SETTING CHANGED, PLEASE REPORT IT, AIAI MAY BEHAVE STRANGE");
   return true;
   }

local ile;
local veh_list = AIVehicleList();
veh_list.Valuate(GetVehicleType);
veh_list.KeepValue(AIVehicle.VT_ROAD);
ile = veh_list.Count();
local allowed = AIGameSettings.GetValue("vehicle.max_roadveh");

if(allowed==0)return false;
if(ile==0)return true;

if(((ile*100)/(allowed))>90) return false;
if((allowed - ile)<5) return false;
return true;
/*
max_trains = 500
max_roadveh = 500
max_aircraft = 200
max_ships = 300
*/
}

function Name()
{
if (!AICompany.SetName("AIAI")) 
    if(AIError.GetLastError==AIError.ERR_NAME_IS_NOT_UNIQUE)
	{
	if (!AICompany.SetName("Suicide AIAI")) {
    local i = 2;
    while (!AICompany.SetName("Suicide AIAI #" + i)) {
      i = i + 1;
    }
	}
	while(true) Sleep(1000);
    }
}

function Sqrt(i) { //from Rondje
	if (i == 0)
		return 0;   // Avoid divide by zero
	local n = (i / 2) + 1;       // Initial estimate, never low
	local n1 = (n + (i / n)) / 2;
	while (n1 < n) {
		n = n1;
		n1 = (n + (i / n)) / 2;
	}
	return n;
}

function SafeAddRectangle(list, tile, radius) { //from Rondje
	local x1 = max(0, AIMap.GetTileX(tile) - radius);
	local y1 = max(0, AIMap.GetTileY(tile) - radius);
	
	local x2 = min(AIMap.GetMapSizeX() - 2, AIMap.GetTileX(tile) + radius);
	local y2 = min(AIMap.GetMapSizeY() - 2, AIMap.GetTileY(tile) + radius);
	
	list.AddRectangle(AIMap.GetTileIndex(x1, y1),AIMap.GetTileIndex(x2, y2)); 
}

function mini(a, b)
{
if(a<b)return a;
return b;
}

function maxi(a, b)
{
if(a>b)return a;
return b;
}

function abs(a)
{
if(a<0)return -a;
return a;
}

function RandomTile() { //from ChooChoo
	return abs(AIBase.Rand()) % AIMap.GetMapSize();
}
