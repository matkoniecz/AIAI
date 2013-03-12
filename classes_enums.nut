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
}

class RailwayStation extends Station
{
}

function ProvideMoney()
{
if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>10*AICompany.GetMaxLoanAmount()) AICompany.SetLoanAmount(0);
else AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
}

class Route
{
start=null;
end=null;
forbidden=null;
start_otoczka=null;
koniec_otoczka=null;
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

//trasa.type
//0 proceed trasa.cargo
//1 raw
//2 passenger
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
forbidden = AIList();
start_otoczka=null; //obsolete TODO //move to Station()
koniec_otoczka=null; //obsolete TODO //move to Station()
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

function Print()
{
/*
Info(" start " + AIIndustry.GetName(start));
Info(" end " + AIIndustry.GetName(end));
Info(" depot_tile " + depot_tile);
Info(" second_station.location " + second_station.location);
Info(" first_station.location " + first_station.location);
Info(" first_station.direction " + first_station.direction);
Info(" second_station.location " + second_station.location);
Info(" second_station.direction " + second_station.direction);

Info(" start_tile " + start_tile);
Info(" end_tile " + end_tile);
Info(" cargo " + AICargo.GetCargoLabel(cargo));
Info(" production " + production);
Info(" type " + type);
Info(" station_size " + station_size);
Info(" engine " + engine);
//Info(" engine " + AIEngine.GetName(engine));
Info(" engine_count " + engine_count);
Info(" budget " + budget);
Info(" demand " + demand);
NewLine();
*/
}

}