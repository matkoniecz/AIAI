enum StationDirection
{
	x_is_constant__horizontal,
	y_is_constant__vertical
}

class Station
{
	location = null;
	direction = null;
	is_city = null;
	connection = null;
	area_blocked_by_station = null;
}

enum RouteType
{
rawCargo,
processedCargo,
townCargo,
}

class Route
{
start = null;
end = null;
forbidden_industries = null;
depot_tile = null;
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
station_size = null;
station_direction = null;
first_station = null;
second_station = null;

track_type = null;
engine = null;
engine_count = null;
budget = null;
demand = null;
OK = null;

constructor()
{
first_station = Station();
second_station = Station();
start=null;
end=null;
forbidden_industries = AIList();
depot_tile = null;
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
station_size = null;
engine = null;
engine_count = null;
budget = null;
}

function StationsAllocated()
{
return first_station.location != null && second_station.location != null
}

}