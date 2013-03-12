class CustomPathfinder extends RoadPathFinder //Made with Zutty's help - thanks for help http://www.tt-forums.net/viewtopic.php?f=65&t=47219
{
   _cost_level_crossing = null; //from SIMPLEAI
   function InitializePath(sources, goals, ignored) {
      local nsources = [];

      foreach (node in sources) {
         nsources.push([node, 0xFF]);
      }

      this._pathfinder.InitializePath(nsources, goals, ignored);
   }

function _Cost(self, path, new_tile, new_direction)//from SIMPLEAI
{
	local cost = ::RoadPathFinder._Cost(self, path, new_tile, new_direction);
	if (AITile.HasTransportType(new_tile, AITile.TRANSPORT_RAIL)) cost += self._cost_level_crossing;
	return cost;
}

function _GetTunnelsBridges(last_node, cur_node, bridge_dir)//from SIMPLEAI
{
	local slope = AITile.GetSlope(cur_node);
	if (slope == AITile.SLOPE_FLAT && AITile.IsBuildable(cur_node + (cur_node - last_node))) return [];
	local tiles = [];
	for (local i = 2; i < this._max_bridge_length; i++) {
		local bridge_list = AIBridgeList_Length(i + 1);
		local target = cur_node + i * (cur_node - last_node);
		if (!bridge_list.IsEmpty() && AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), cur_node, target)) {
			tiles.push([target, bridge_dir]);
		}
	}

	if (slope != AITile.SLOPE_SW && slope != AITile.SLOPE_NW && slope != AITile.SLOPE_SE && slope != AITile.SLOPE_NE) return tiles;
	local other_tunnel_end = AITunnel.GetOtherTunnelEnd(cur_node);
	if (!AIMap.IsValidTile(other_tunnel_end)) return tiles;

	local tunnel_length = AIMap.DistanceManhattan(cur_node, other_tunnel_end);
	local prev_tile = cur_node + (cur_node - other_tunnel_end) / tunnel_length;
	if (AITunnel.GetOtherTunnelEnd(other_tunnel_end) == cur_node && tunnel_length >= 2 &&
			prev_tile == last_node && tunnel_length < _max_tunnel_length && AITunnel.BuildTunnel(AIVehicle.VT_ROAD, cur_node)) {
		tiles.push([other_tunnel_end, bridge_dir]);
	}
	return tiles;
}
   
function Fast()
{
_cost_level_crossing = 30;
cost.tile = 10;
cost.max_cost = 4000;          // = equivalent of 400 tiles
cost.no_existing_road = AIAI.GetSetting("no_road_cost");     // changed//don't care about reusing existing roads
cost.turn = 1;                 // minor penalty for turns
cost.slope =   10;             //changed //  don't care about slopes
cost.bridge_per_tile = 4+AIAI.GetSetting("no_road_cost");      // bridges / tunnels are 50% more expensive per tile than normal tiles
cost.tunnel_per_tile = 4+AIAI.GetSetting("no_road_cost");
cost.coast =   0;              // don't care about coast tiles
cost.max_bridge_length = 15;   // The maximum length of a bridge that will be build.
cost.max_tunnel_length = 15;   // The maximum length of a tunnel that will be build.
}

function CircleAroundStation()
{
_cost_level_crossing = 30;
cost.tile = 10;
cost.max_cost = 800;          // = equivalent of 100 tiles
cost.no_existing_road = 10;   // no rebuilding
cost.turn = 1;                 // minor penalty for turns
cost.slope =   20;              //  don't care about slopes
cost.bridge_per_tile = 5;      // bridges / tunnels are 50% more expensive per tile than normal tiles
cost.tunnel_per_tile = 5;
cost.coast =   0;              // don't care about coast tiles
cost.max_bridge_length = 0;   // The maximum length of a bridge that will be build.
cost.max_tunnel_length = 0;   // The maximum length of a tunnel that will be build.
}

}

