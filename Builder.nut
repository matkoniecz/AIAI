class Builder
{
cost = null;
rodzic = null;
desperacja = 0;
};

function Builder::SetDesperacja(new_desperacja)
{
desperacja = new_desperacja;
}

function Builder::constructor(parent_init, desperacja_init)
{
rodzic = parent_init;
desperacja = desperacja_init;
cost = 1;
}

function Builder::CountVehicles(station)
{
local vehicle_list=AIVehicleList_Station(station);
vehicle_list.Valuate(rodzic.CzyNaSprzedaz)
vehicle_list.KeepValue(1);
return vehicle_list.Count();
}