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
if (!AICompany.SetName("AIAI")) {
	if (!AICompany.SetName("Suicide AIAI")) {
    local i = 2;
    while (!AICompany.SetName("Suicide AIAI #" + i)) {
      i = i + 1;
    }
	}
	while(true) Sleep(1000);
    }
}

function Autoreplace()
{
AutoreplaceRV();
AutoreplaceSmallPlane();
AutoreplaceBigPlane();
AILog.Warning("Autoreplace list updated by Autoreplace() from util.nut");
}

function AutoreplaceBigPlane()
{
local engine_list=AIEngineList(AIVehicle.VT_AIR);
engine_list.Valuate(AIEngine.GetPlaneType);
engine_list.KeepValue(AIAirport.PT_BIG_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsValidEngine(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = KWAI.FindAircraft(AIAirport.AT_LARGE, cargo, 1)
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         AILog.Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function AutoreplaceSmallPlane()
{
local engine_list=AIEngineList(AIVehicle.VT_AIR);
engine_list.Valuate(AIEngine.GetPlaneType);
engine_list.RemoveValue(AIAirport.PT_BIG_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsValidEngine(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = KWAI.FindAircraft(AIAirport.AT_SMALL, cargo, 1)
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         AILog.Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function AutoreplaceRV()
{
local engine_list=AIEngineList(AIVehicle.VT_ROAD);
engine_list.Valuate(AIEngine.GetRoadType);
engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsValidEngine(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = KRAI.GetReplace(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing), cargo);
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         AILog.Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function Sqrt(i) {
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
