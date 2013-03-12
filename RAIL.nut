/*

 local types = AIRailTypeList();
 AIRail.SetCurrentRailType(types.Begin());

 
*/

import("pathfinder.rail", "RailPathFinder", 1);

class RAIL
{
}

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

function RAIL::IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b)
{

local pathfinder = RailPathFinder();

pathfinder.cost.max_tunnel_length = 100;
pathfinder.cost.max_bridge_length = 100;
pathfinder.cost.turn = pathfinder.cost.max_cost;

//[start_tile, tile_before_start] [last_tile, tile_after_end]
if(AIMap.GetTileY(tile_b)==AIMap.GetTileY(tile_a))
   {
   pathfinder.InitializePath([[tile_a, tile_a + AIMap.GetTileIndex(1, 0)]], [[tile_b, tile_b + AIMap.GetTileIndex(-1, 0)]]);
   AISign.BuildSign(tile_a, "tile_a");
   AISign.BuildSign(tile_b, "tile_b");
   AISign.BuildSign(tile_a + AIMap.GetTileIndex(1, 0), "pre tile_a");
   AISign.BuildSign(tile_b + AIMap.GetTileIndex(-1, 0), "pre tile_b");
   }
else if(AIMap.GetTileX(tile_b)==AIMap.GetTileX(tile_a))
   {
   pathfinder.InitializePath([[tile_a, tile_a + AIMap.GetTileIndex(0, 1)]], [[tile_b, tile_b + AIMap.GetTileIndex(0, -1)]]);
   AISign.BuildSign(tile_a, "tile_a");
   AISign.BuildSign(tile_b, "tile_b");
   AISign.BuildSign(tile_a + AIMap.GetTileIndex(0, 1), "pre tile_a");
   AISign.BuildSign(tile_b + AIMap.GetTileIndex(0, -1), "pre tile_b");
   }
else
   {
   Error("IsItPossibleToConnectThatTilesWithRail with "
   + "( "+ AIMap.GetTileX(tile_a) + ", " + AIMap.GetTileY(tile_a) + ")" 
   + " ( "+ AIMap.GetTileX(tile_b) + ", " + AIMap.GetTileY(tile_b) + ")" );
   Error("Booom");
   local zero=0/0;
   }
local path = pathfinder.FindPath(-1);
return path;
}

function RAIL::DumbBuilder(path)
{
local prev = null;
local prevprev = null;
while (path != null) {
  if (prevprev != null) {
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev);
      } else {
        local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
        bridge_list.Valuate(AIBridge.GetMaxSpeed);
        bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
        AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile());
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      AIRail.BuildRail(prevprev, prev, path.GetTile());
    }
  }
  if (path != null) {
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}
}

function IsCrossingPossible(tile)
{
if(AITile.GetSlope(tile) != AITile.SLOPE_FLAT)return false;
if(AITile.GetSlope(tile + AIMap.GetTileIndex(0, 1)) !=AITile.SLOPE_FLAT)return false;
if(AITile.GetSlope(tile + AIMap.GetTileIndex(1, 1)) !=AITile.SLOPE_FLAT)return false;
if(AITile.GetSlope(tile + AIMap.GetTileIndex(1, 0)) !=AITile.SLOPE_FLAT)return false;
return AITile.IsBuildableRectangle(tile, 2, 2);
}

function IsConnectionPossible(tile, tile)
{

}

function RAIL::Go()
{
return;

local list=AITileList();

//SafeAddRectangle(list, AITown.GetLocation(0), 100);
SafeAddRectangle(list, AIMap.GetTileIndex(20, 10), 100);

Error("XXXXXXXXXXX " + list.Count());

for(local q = list.Begin(); list.HasNext(); q = list.Next())
   {
   //Error("X");
   if(IsCrossingPossible(q)) AISign.BuildSign(q, "OK");
   }

local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin());

AILog.Info("@@@@@@@@@@@@@@@@@@");
local tile_b;
local tile_a;

tile_b=AIMap.GetTileIndex(10, 10);
tile_a=AIMap.GetTileIndex(20, 10);
RAIL.DumbBuilder(RAIL.IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b));

tile_b=AIMap.GetTileIndex(60, 10);
tile_a=AIMap.GetTileIndex(60, 20);
RAIL.DumbBuilder(RAIL.IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b));



tile_b=AIMap.GetTileIndex(100, 100);
tile_a=AIMap.GetTileIndex(200, 100);
RAIL.DumbBuilder(RAIL.IsItPossibleToConnectThatTilesWithRail(tile_a, tile_b));
}

