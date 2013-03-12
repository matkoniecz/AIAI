class Builder
{
cost = null;
rodzic = null;
desperation = 0;
retry_limit = 2;
pathfinding_time_limit = 10;
blacklisted_engines = AIList();
};

function Builder::SetDesperation(new_desperation)
{
desperation = new_desperation;
}

function Builder::constructor(parent_init, desperation_init)
{
rodzic = parent_init;
desperation = desperation_init;
cost = 1;
}

function Builder::HowManyVehiclesFromThisStationAreStopped(station)
{
local count = 0;
			local vehicle_list=AIVehicleList_Station(station);
			for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next())
				{
				if(AIVehicle.GetCurrentSpeed(vehicle_id) == 0){
					if(AIVehicle.GetState(vehicle_id)!=AIVehicle.VS_AT_STATION){
						Warning(AIVehicle.GetName(vehicle_id) + " is waiting");
						count++;
						}						
					}
				}
return count;
}

function Builder::GetPathfindingLimit()
{
return pathfinding_time_limit + desperation * 2;
}
