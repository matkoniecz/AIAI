class Builder
{
cost = null;
rodzic = null;
desperation = 0;
retry_limit = 2;
pathfinding_time_limit = 10;
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

function Builder::CountVehicles(station)
{
local vehicle_list=AIVehicleList_Station(station);
vehicle_list.Valuate(rodzic.CzyNaSprzedaz)
vehicle_list.KeepValue(0);
return vehicle_list.Count();
}

function Builder::GetPathfindingLimit()
{
return pathfinding_time_limit;
}
