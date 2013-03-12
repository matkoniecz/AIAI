import("pathfinder.rail", "RailPathFinder", 1);
require("RAILchoochoopathfinder.nut"); //TODO MERGE!
class MyRailPF extends RailPathFinder { //From SimpleAI
	_cost_level_crossing = null;
}
function MyRailPF::_Cost(path, new_tile, new_direction, self)
{
	local cost = ::RailPathFinder._Cost(path, new_tile, new_direction, self);
	if (AITile.HasTransportType(new_tile, AITile.TRANSPORT_ROAD)) cost += self._cost_level_crossing;
	return cost;
}

function MyRailPF::Fast()
{
_cost_level_crossing = 400;
cost.bridge_per_tile = 50;
cost.tunnel_per_tile = 35;
cost.coast = 0;
cost.max_bridge_length = 20;   // The maximum length of a bridge that will be build.
cost.max_tunnel_length = 20;   // The maximum length of a tunnel that will be build.
}
