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

	function proper_clone()
	{
		local returned = Route();
		returned.start = start;
		returned.end = end;
		returned.forbidden_industries = forbidden_industries; //note that this is NOT cloned and everything links to the same list
		returned.depot_tile = depot_tile;
		returned.start_tile = start_tile;
		returned.end_tile = end_tile;
		returned.cargo = cargo;
		returned.production = production;
		returned.type = type;
		returned.station_size = station_size;
		returned.station_direction = station_direction;
		returned.first_station = clone first_station;
		returned.second_station = clone second_station;
	
		returned.track_type = track_type;
		returned.engine = engine;
		returned.engine_count = engine_count;
		returned.budget = budget;
		returned.demand = demand;
		returned.OK = OK;	
		return returned;
	}
}