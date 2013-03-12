
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

