import("pathfinder.rail", "RailPathFinder", 1);

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
cost.tunnel_per_tile = 50;
cost.coast = 0;
cost.max_bridge_length = 20;   // The maximum length of a bridge that will be build.
cost.max_tunnel_length = 20;   // The maximum length of a tunnel that will be build.
}
class tiles
{
a = null;
b = null;
}

class RAIL
{
trasa = Route();
_koszt = null;
rodzic = null;
desperacja = 0; //TODO activate it
path = null; //TODO move it to RailStupid
}

require("RAILstupid.nut");
require("RAILtrain_getter.nut");

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

function RAIL::IsItPossibleToConnectThatTilesWithRail(tile_b, start_tile)
{

local pathfinder = RailPathFinder();

pathfinder.cost.max_tunnel_length = 100;
pathfinder.cost.max_bridge_length = 100;
pathfinder.cost.turn = pathfinder.cost.max_cost;

//[start_tile, tile_before_start] [last_tile, tile_after_end]
if(AIMap.GetTileY(tile_b)==AIMap.GetTileY(start_tile))
   {
   pathfinder.InitializePath([[start_tile, start_tile + AIMap.GetTileIndex(1, 0)]], [[tile_b, tile_b + AIMap.GetTileIndex(-1, 0)]]);
   AISign.BuildSign(start_tile, "start_tile");
   AISign.BuildSign(tile_b, "tile_b");
   AISign.BuildSign(start_tile + AIMap.GetTileIndex(1, 0), "pre start_tile");
   AISign.BuildSign(tile_b + AIMap.GetTileIndex(-1, 0), "pre tile_b");
   }
else if(AIMap.GetTileX(tile_b)==AIMap.GetTileX(start_tile))
   {
   pathfinder.InitializePath([[start_tile, start_tile + AIMap.GetTileIndex(0, 1)]], [[tile_b, tile_b + AIMap.GetTileIndex(0, -1)]]);
   AISign.BuildSign(start_tile, "start_tile");
   AISign.BuildSign(tile_b, "tile_b");
   AISign.BuildSign(start_tile + AIMap.GetTileIndex(0, 1), "pre start_tile");
   AISign.BuildSign(tile_b + AIMap.GetTileIndex(0, -1), "pre tile_b");
   }
else
   {
   Error("IsItPossibleToConnectThatTilesWithRail with "
   + "( "+ AIMap.GetTileX(start_tile) + ", " + AIMap.GetTileY(start_tile) + ")" 
   + " ( "+ AIMap.GetTileX(tile_b) + ", " + AIMap.GetTileY(tile_b) + ")" );
   Error("Booom");
   local zero=0/0;
   }
local path = pathfinder.FindPath(-1);
return path;
}

function RAIL::RailwayLinkConstruction(path)
{
return DumbBuilder(path);
}

function RAIL::DumbRemover(path, goal)
{
local prev = null;
local prevprev = null;
while (path != null) {
  if (prevprev != null) {
  //AISign.BuildSign(prev, "prev");
  if(prev==goal)return true;
  
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        AITile.DemolishTile(prev);
      } else {
        AITile.DemolishTile(prev);
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      AIRail.RemoveRail(prevprev, prev, path.GetTile());
    }
  }
  if (path != null) {
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}
return true;
}

function RAIL::DumbBuilder(path)
{
local copy = path;
local prev = null;
local prevprev = null;
while (path != null) {
  if (prevprev != null) {
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        if(!AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev))
			     {
		 DumbRemover(copy, prev);
		 return false;
		 }

      } else {
        local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
        bridge_list.Valuate(AIBridge.GetMaxSpeed);
        bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
        if(!AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile()))
	     {
		 DumbRemover(copy, prev);
		 return false;
		 }
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      if(!AIRail.BuildRail(prevprev, prev, path.GetTile())) 
	     {
		 DumbRemover(copy, prev);
		 return false;
		 }
    }
  }
  if (path != null) {
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}
return true;
}

function RAIL::GetCostOfRoute(path)
{
local costs = AIAccounting();
costs.ResetCosts ();

/* Exec Mode */
local test = AITestMode();
/* Test Mode */

if(RAIL.DumbBuilder(path))
   {
   return costs.GetCosts();
   }
else return null;
}

function IsCrossingPossible(tile)
{
if(AITile.GetSlope(tile) != AITile.SLOPE_FLAT)return false;
if(AITile.GetSlope(tile + AIMap.GetTileIndex(0, 1)) !=AITile.SLOPE_FLAT)return false;
if(AITile.GetSlope(tile + AIMap.GetTileIndex(1, 1)) !=AITile.SLOPE_FLAT)return false;
if(AITile.GetSlope(tile + AIMap.GetTileIndex(1, 0)) !=AITile.SLOPE_FLAT)return false;
return AITile.IsBuildableRectangle(tile, 2, 2);
}

/*
precondition
tile_a.x == tile_b.x && tile_a.y < tile_b.y //tile_a powy¿ej od tile_b
||
tile_a.x && tile_b.x && tile_a.y == tile_b.y //tile_a na lewo od tile_b
*/
/*
null - niemo¿liwe
œcie¿ki - w przeciwnym razie
*/
function IsEasyConnectionPossible(tile_a, tile_b)
{
AISign.BuildSign(tile_a, "a");
AISign.BuildSign(tile_b, "b");
local line_a;
local line_b;

if((AIMap.GetTileX(tile_a)==AIMap.GetTileX(tile_b))&&(AIMap.GetTileY(tile_a)<AIMap.GetTileY(tile_b)))
   {
/*
   xv++++++xv
   vv++++++vv
*/   
   line_a = RAIL.IsItPossibleToConnectThatTilesWithRail( tile_a + AIMap.GetTileIndex(0, 2), tile_b + AIMap.GetTileIndex(0, -1));
   line_b = RAIL.IsItPossibleToConnectThatTilesWithRail( tile_a + AIMap.GetTileIndex(1, 2), tile_b + AIMap.GetTileIndex(1, -1));
   }
   else if((AIMap.GetTileX(tile_a) < AIMap.GetTileX(tile_b))&&(AIMap.GetTileY(tile_a)==AIMap.GetTileY(tile_b)))
   {
/*
   xv
   vv
   ++
   ++
   ++
   xv
   vv
*/
   line_a = RAIL.IsItPossibleToConnectThatTilesWithRail( tile_a + AIMap.GetTileIndex(2, 0), tile_b + AIMap.GetTileIndex(-1, 0));
   line_b = RAIL.IsItPossibleToConnectThatTilesWithRail( tile_a + AIMap.GetTileIndex(2, 1), tile_b + AIMap.GetTileIndex(-1, 1));
   }
   else
   {
   local zero = 0/0;
   }
RAIL.DumbBuilder(line_a);
RAIL.DumbBuilder(line_b);
}

function RAIL::WrongStarter(result)
{
if(IsCrossingPossible(result.a)==false)return true;
if(IsCrossingPossible(result.b)==false)return true;
return !((AIMap.GetTileX(result.a) <= AIMap.GetTileX(result.b))&&(AIMap.GetTileY(result.a)<=AIMap.GetTileY(result.b)));
}

function RAIL::GetStarter()
{
local result = tiles();
do
   {
   result.a = RandomTile();
   result.b = RandomTile();
   }
while(RAIL.WrongStarter(result))  
return result;
}

function RAIL::FlatPathfinder(tile_a, tile_b)
{
AISign.BuildSign(tile_a, "tile_a");
AISign.BuildSign(tile_b, "tile_b");

//odcinek w jednym z kierunków, szukamy miejsca na skrzy¿owanie 
          //od minimum w górê, nale¿y zostawiæ wiêcej ni¿ minimum
//w drugim kierunku

//zapisujemy zaklepany kawa³ek
//przesuwamy sie
}

function RAIL::Go()
{
//RAIL.StupidRailConnection();
return;
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin());

/*
AILog.Info("@@@@@@@@@@@@@@@@@@");
local tile_b;
local tile_a;

tile_b=AIMap.GetTileIndex(10, 10);
tile_a=AIMap.GetTileIndex(20, 10);
IsEasyConnectionPossible(tile_b, tile_a);

tile_b=AIMap.GetTileIndex(20, 20);
tile_a=AIMap.GetTileIndex(20, 10);
IsEasyConnectionPossible(tile_a, tile_b);
local list=AITileList();
*/

local wrzut = RAIL.GetStarter();
RAIL.FlatPathfinder(wrzut.a, wrzut.b);
}

function RAIL::BuildDepot(path, reverse) //from adimral
{
reverse = false; //TODO do sth with it!!!!!!!!
	if (reverse) {
		local rpath = RPathItem(path.GetTile());
		while (path.GetParent() != null) {
			path = path.GetParent();
			local npath = RPathItem(path.GetTile());
			npath._parent = rpath;
			rpath = npath;
		}
		path = rpath;
	}
	local prev = null;
	local pp = null;
	local ppp = null;
	local pppp = null;
	local ppppp = null;
	while (path != null) {
		if (ppppp != null) {
			if (ppppp - pppp == pppp - ppp && pppp - ppp == ppp - pp && ppp - pp == pp - prev) {
				local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
				                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
				foreach (offset in offsets) {
					if (Utils_Tile.GetRealHeight(ppp + offset) != Utils_Tile.GetRealHeight(ppp)) continue;
					local depot_build = false;
					if (AIRail.IsRailDepotTile(ppp + offset)) {
						if (AIRail.GetRailDepotFrontTile(ppp + offset) != ppp) continue;
						if (!AIRail.TrainHasPowerOnRail(AIRail.GetRailType(ppp + offset), AIRail.GetCurrentRailType())) continue;
						/* If we can't build trains for the current rail type in the depot, see if we can
						 * convert it without problems. */
						if (!AIRail.TrainHasPowerOnRail(AIRail.GetCurrentRailType(), AIRail.GetRailType(ppp + offset))) {
							if (!AIRail.ConvertRailType(ppp + offset, ppp + offset, AIRail.GetCurrentRailType())) continue;
						}
						depot_build = true;
					} else {
						local test = AITestMode();
						if (!AIRail.BuildRailDepot(ppp + offset, ppp)) continue;
					}
					if (!AIRail.AreTilesConnected(pp, ppp, ppp + offset) && !AIRail.BuildRail(pp, ppp, ppp + offset)) continue;
					if (!AIRail.AreTilesConnected(pppp, ppp, ppp + offset) && !AIRail.BuildRail(pppp, ppp, ppp + offset)) continue;
					if (depot_build || AIRail.BuildRailDepot(ppp + offset, ppp)) return ppp + offset;
				}
			} else if (ppppp - ppp == ppp - prev && ppppp - pppp != pp - prev) {
				local offsets = null;
				if (abs(ppppp - ppp) == AIMap.GetTileIndex(1, 1)) {
					if (ppppp - pppp == AIMap.GetTileIndex(1, 0) || prev - pp == AIMap.GetTileIndex(1, 0)) {
						local d = ConnectDepotDiagonal(prev, ppppp, max(prev, ppppp) + AIMap.GetTileIndex(-2, 0));
						if (d != null) return d;
					} else {
						local d = ConnectDepotDiagonal(prev, ppppp, max(prev, ppppp) + AIMap.GetTileIndex(0, -2));
						if (d != null) return d;
					}
				} else {
					if (ppppp - pppp == AIMap.GetTileIndex(0, -1) || prev - pp == AIMap.GetTileIndex(0, -1)) {
						local d = ConnectDepotDiagonal(prev, ppppp, max(prev, ppppp) + AIMap.GetTileIndex(2, 0));
						if (d != null) return d;
					} else {
						local d = ConnectDepotDiagonal(prev, ppppp, max(prev, ppppp) + AIMap.GetTileIndex(0, -2));
						if (d != null) return d;
					}
				}
			}
		}
		ppppp = pppp;
		pppp = ppp;
		ppp = pp;
		pp = prev;
		prev = path.GetTile();
		path = path.GetParent();
	}
	return null;
}

function ConnectDepotDiagonal(tile_a, tile_b, tile_c)
{
	if (!AITile.IsBuildable(tile_c) && (!AIRail.IsRailTile(tile_c) || !AICompany.IsMine(AITile.GetOwner(tile_c)))) return null;
	local offset1 = (tile_c - tile_a) / 2;
	local offset2 = (tile_c - tile_b) / 2;
	local depot_tile = null;
	local depot_build = false;
	local tiles = [];
	tiles.append([tile_a, tile_a + offset1, tile_c]);
	tiles.append([tile_b, tile_b + offset2, tile_c]);
	if (AIRail.IsRailDepotTile(tile_c + offset1) && AIRail.GetRailDepotFrontTile(tile_c + offset1) == tile_c &&
			AIRail.TrainHasPowerOnRail(AIRail.GetRailType(tile_c + offset1), AIRail.GetCurrentRailType())) {
		/* If we can't build trains for the current rail type in the depot, see if we can
		 * convert it without problems. */
		if (!AIRail.TrainHasPowerOnRail(AIRail.GetCurrentRailType(), AIRail.GetRailType(tile_c + offset1))) {
			if (!AIRail.ConvertRailType(tile_c + offset1, tile_c + offset1, AIRail.GetCurrentRailType())) return null;
		}
		depot_tile = tile_c + offset1;
		depot_build = true;
		tiles.append([tile_a + offset1, tile_c, tile_c + offset1]);
		tiles.append([tile_b + offset2, tile_c, tile_c + offset1]);
	} else if (AIRail.IsRailDepotTile(tile_c + offset2) && AIRail.GetRailDepotFrontTile(tile_c + offset2) == tile_c &&
			AIRail.TrainHasPowerOnRail(AIRail.GetRailType(tile_c + offset2), AIRail.GetCurrentRailType())) {
		/* If we can't build trains for the current rail type in the depot, see if we can
		 * convert it without problems. */
		if (!AIRail.TrainHasPowerOnRail(AIRail.GetCurrentRailType(), AIRail.GetRailType(tile_c + offset2))) {
			if (!AIRail.ConvertRailType(tile_c + offset2, tile_c + offset2, AIRail.GetCurrentRailType())) return null;
		}
		depot_tile = tile_c + offset2;
		depot_build = true;
		tiles.append([tile_a + offset1, tile_c, tile_c + offset2]);
		tiles.append([tile_b + offset2, tile_c, tile_c + offset2]);
	} else if (AITile.IsBuildable(tile_c + offset1)) {
		if (Utils_Tile.GetRealHeight(tile_c) != Utils_Tile.GetRealHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		if (Utils_Tile.GetRealHeight(tile_c) != Utils_Tile.GetRealHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		depot_tile = tile_c + offset1;
		tiles.append([tile_a + offset1, tile_c, tile_c + offset1]);
		tiles.append([tile_b + offset2, tile_c, tile_c + offset1]);
	} else if (AITile.IsBuildable(tile_c + offset2)) {
		if (Utils_Tile.GetRealHeight(tile_c) != Utils_Tile.GetRealHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		if (Utils_Tile.GetRealHeight(tile_c) != Utils_Tile.GetRealHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		depot_tile = tile_c + offset2;
		tiles.append([tile_a + offset1, tile_c, tile_c + offset2]);
		tiles.append([tile_b + offset2, tile_c, tile_c + offset2]);
	} else {
		return null;
	}
	{
		local test = AITestMode();
		foreach (t in tiles) {
			if (!AIRail.AreTilesConnected(t[0], t[1], t[2]) && !AIRail.BuildRail(t[0], t[1], t[2])) return null;
		}
		if (!depot_build && !AIRail.BuildRailDepot(depot_tile, tile_c)) return null;
	}
	foreach (t in tiles) {
		if (!AIRail.AreTilesConnected(t[0], t[1], t[2]) && !AIRail.BuildRail(t[0], t[1], t[2])) return null;
	}
	if (!depot_build && !AIRail.BuildRailDepot(depot_tile, tile_c)) return null;
	return depot_tile;
}


