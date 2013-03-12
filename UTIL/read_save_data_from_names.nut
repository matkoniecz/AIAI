function StringToInteger(string)
{
Info(string+"<-len")
local result = 0;
local i=0;
while(i<string.len()){
	result=result*10+string[i]-48;
	i++;
	}
return result;
}

function IntToStrFill(int_val, num_digits)
{
   local str = int_val.tostring();
   while(str.len() < num_digits)
      {
      str = "0" + str;
      }
   return str;
}

function IsForSell(vehicle_id)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle " + vehicle_id);
local name=AIVehicle.GetName(vehicle_id)+"            ";
local forsell="for sell";

for(local i=0; i<forsell.len(); i++)
if(name[i]!=forsell[i]) return false;
return true;
}

function GetDepotLocation(vehicle_id)
{
assert(AIVehicle.IsValidVehicle(vehicle_id))
local depot_location = LoadDataFromStationNameFoundByStationId(AIStation.GetStationID(GetLoadStationLocation(vehicle_id)), "[]");
if(AIMap.IsValidTile(depot_location)) return depot_location;
//for(local i=0; i<AIOrder.GetOrderCount(vehicle_id); i++) if(AIOrder.IsGotoDepotOrder(vehicle_id, i)) return AIOrder.GetOrderDestination(vehicle_id, i);
abort("Explosion caused by vehicle " + AIVehicle.GetName(vehicle_id)+ " depot_location from station name is "+depot_location);
}

function GetLoadStationLocation(vehicle_id)
{
assert(AIVehicle.IsValidVehicle(vehicle_id))
for(local i=0; i<AIOrder.GetOrderCount(vehicle_id); i++) if(AIOrder.IsGotoStationOrder(vehicle_id, i)) return AIOrder.GetOrderDestination(vehicle_id, i);
abort("Explosion caused by vehicle " + AIVehicle.GetName(vehicle_id));
}

function GetUnloadStationLocation(vehicle_id)
{
assert(AIVehicle.IsValidVehicle(vehicle_id))
local onoff = false;
for(local i=0; i<AIOrder.GetOrderCount(vehicle_id); i++) {
   if(AIOrder.IsGotoStationOrder(vehicle_id, i)) {
	  if(onoff==true) return AIOrder.GetOrderDestination(vehicle_id, i);
	  onoff=true
	  }
   }
abort("Explosion caused by vehicle " + AIVehicle.GetName(vehicle_id));
}

function LoadDataFromStationNameFoundByStationId(station_id, delimiters)
{	
	assert(AIStation.IsValidStation(station_id))
	local start_code = delimiters[0]
	local end_code = delimiters[1]
	local str = AIBaseStation.GetName(station_id)
	local result = null;
		
	for(local i = 0; i < str.len(); ++i)
		{
		//Warning(result+" from "+str+" ["+i+"]="+str[i]);
		if(str[i]==start_code && result == null)
			{
			result=0
			}
		else if(str[i]==end_code)
			{
			//Warning(result+" from "+str);
			return result;
			}
		else if(result != null)
			{
			result=result*10+str[i]-48;
			}
		}
	return null;
}

function AIAI::TrySetStationName(station_id, data, leading_number)
{
	local string;
	string = IntToStrFill(leading_number, 4)+data;
	if(AIBaseStation.GetName(station_id) == string) return true;
	return AIBaseStation.SetName(station_id, string)
}

function AIAI::SetStationName(location, data)
{
	local station_id = AIStation.GetStationID(location);
	local current_number = LoadDataFromStationNameFoundByStationId(station_id, "0{");
	if(current_number != null)
		if(TrySetStationName(station_id, data, current_number))
			return;
	
	if(!AIBaseStation.IsValidBaseStation(station_id))
		abort("no station found");

	while(!TrySetStationName(station_id, data, station_number))station_number++;
	station_number++;
}

function AIAI::SetWaypointName(network, location)
{
	local waypoint = AIWaypoint.GetWaypointID(location);
	if(!AIBaseStation.IsValidBaseStation(waypoint))
		return;
	local string;
	local i=1;
	do
		{
		string = "{"+network+"}  #"+IntToStrFill(i, 5);
		i++;
		Error(AIError.GetLastErrorString());
		}
	while(!AIBaseStation.SetName(waypoint, string))
}

