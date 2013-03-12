/*

 local types = AIRailTypeList();
 AIRail.SetCurrentRailType(types.Begin());

 
*/

import("pathfinder.rail", "RailPathFinder", 1);

/*
ost.max_cost 	 2000000000 	 The maximum cost for a route.
cost.tile 	100 	The cost for a non-diagonal track.
cost.diagonal_tile 	70 	The cost for a diagonal track.
cost.turn 	50 	The cost that is added to _cost_tile / _cost_diagonal_tile if the direction changes.
cost.slope 	100 	The extra cost if a rail tile is sloped.
cost.bridge_per_tile 	150 	The cost per tile of a new bridge, this is added to _cost_tile.
cost.tunnel_per_tile 	120 	The cost per tile of a new tunnel, this is added to _cost_tile.
cost.coast 	20 	The extra cost for a coast tile.
cost.max_bridge_length 	6 	The maximum length of a bridge that will be build.
cost.max_tunnel_length 	6 	The maximum length of a tunnel that will be build.
*/

class RAIL
{
}

function RAIL::IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b)
{
local pathfinder = RailPathFinder();
pathfinder.cost.max_tunnel_length = 100;
pathfinder.cost.max_bridge_length = 100;
pathfinder.cost.turn = pathfinder.cost.max_cost;

AISign.BuildSign(tile_a, "tile_a");
AISign.BuildSign(tile_b, "tile_b");

if(AIMap.GetTileY(tile_b)==AIMap.GetTileY(tile_a))
   {
   pathfinder.InitializePath([[tile_a, tile_a + AIMap.GetTileIndex(0, -1)]], [[tile_b + AIMap.GetTileIndex(0, -1), tile_b]]);
   }
else if(AIMap.GetTileX(tile_b)==AIMap.GetTileX(tile_a))
   {
   pathfinder.InitializePath([[tile_a, tile_a + AIMap.GetTileIndex(-1, 0)]], [[tile_b + AIMap.GetTileIndex(-1, 0), tile_b]]);
   }
else
   {
   Error("IsItPossibleToConnectThatTilesWithRail with "
   + "( "+ AIMap.GetTileX(tile_a) + ", " + AIMap.GetTileY(tile_a) + ")" 
   + " ( "+ AIMap.GetTileX(tile_b) + ", " + AIMap.GetTileY(tile_b) + ")" );
   Error("Booom");
   local zero=0/0;
   }
}

function RAIL::Go()
{
local tile_b;
local tile_a;

tile_b=AIMap.GetTileIndex(10, 10);
tile_a=AIMap.GetTileIndex(10, 20);
RAIL.IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b);

tile_b=AIMap.GetTileIndex(10, 10);
tile_a=AIMap.GetTileIndex(20, 10);
RAIL.IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b);


tile_b=AIMap.GetTileIndex(100, 100);
tile_a=AIMap.GetTileIndex(200, 100);
RAIL.IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b);
}

