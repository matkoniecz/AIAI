require("RAILchoochoopathfinder.nut");

class RailPathFinder extends Rail { //From ChooChooo
	_cost_level_crossing = 0;
}

function RailPathFinder::_Cost(path, new_tile, new_direction, self)
{
	local cost = ::RailPathFinder._Cost(path, new_tile, new_direction, self);
	if (AITile.HasTransportType(new_tile, AITile.TRANSPORT_ROAD)) cost += self._cost_level_crossing;
	return cost;
}