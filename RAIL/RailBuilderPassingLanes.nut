function RailBuilder::translate(data)
{
for(local x=-10; x<=10; x++)
	for(local y=-10; y<=10; y++)
		{
		if(data==AIMap.GetTileIndex(x, y)) return "["+x+", "+y+"]"
		}
return "?"
}

function RailBuilder::GetTileOnTheSideOftrack(tile, prevtile, on_the_left)
{
if(prevtile == null) return AIMap.TILE_INVALID;
if(tile == null) return AIMap.TILE_INVALID;

local change = tile - prevtile;

local track = AIRail.GetRailTracks(tile);
if( track == AIRail.RAILTRACK_NE_SW ){
	local side = (change == AIMap.GetTileIndex(-1, 0))
	if(on_the_left) side = !side;
	if(side){
		return tile + AIMap.GetTileIndex(0, -1);
		}
	else{
		return tile + AIMap.GetTileIndex(0, 1);
		}
	}
if( track == AIRail.RAILTRACK_NW_SE ){
	local side = (change == AIMap.GetTileIndex(0, 1))
	if(on_the_left) side = !side;
	if(side){
		return tile + AIMap.GetTileIndex(-1, 0);
		}
	else{
		return tile + AIMap.GetTileIndex(1, 0);
		}
	}
if( track == AIRail.RAILTRACK_NW_NE ) {
	local side = (change == AIMap.GetTileIndex(0, 1))
	if(on_the_left) side = !side;
	if(side){
		return tile + AIMap.GetTileIndex(-1, -1);
		}
	else{
		return tile + AIMap.GetTileIndex(0, 0);
		}
	}
if( track == AIRail.RAILTRACK_SW_SE ) {
	local side = (change == AIMap.GetTileIndex(-1, 0))
	if(on_the_left) side = !side;
	if(side){
		return tile + AIMap.GetTileIndex(0, 0);
		}
	else{
		return tile + AIMap.GetTileIndex(1, 1);
		}
	}
if( track == AIRail.RAILTRACK_NW_SW ) {
	local side = (change == AIMap.GetTileIndex(0, 1))
	if(on_the_left) side = !side;
	if(side){
		return tile + AIMap.GetTileIndex(0, 0);
		}
	else{
		return tile + AIMap.GetTileIndex(1, -1);
		}
	}
if( track == AIRail.RAILTRACK_NE_SE ) {
	local side = (change == AIMap.GetTileIndex(0, -1))
	if(on_the_left) side = !side;
	if(side){
		return tile + AIMap.GetTileIndex(0, 0);
		}
	else{
		return tile + AIMap.GetTileIndex(-1, 1);
		}
	}
return AIMap.TILE_INVALID;
}

function RailBuilder::DoubleConnected(tile, tile2, tile3)
{
return Connected(tile, tile2) && Connected(tile3, tile2);
}

function RailBuilder::Connected(tile, tile2)
{
for(local x=-1; x<=1; x++)
	for(local y=-1; y<=1; y++)
		if(x==0 || y==0)
			if(tile+AIMap.GetTileIndex(x, y) == tile2) return true;

return false;
}

function RailBuilder::IsLongJump(tile1, tile2)
{
if(Helper.Abs(AIMap.GetTileX(tile1) - AIMap.GetTileX(tile2)) > 1) {
	if(AIMap.GetTileY(tile1) == AIMap.GetTileY(tile2)) {
		return true;
		}
	}
if(AIMap.GetTileX(tile1) == AIMap.GetTileX(tile2)) {
	if(Helper.Abs(AIMap.GetTileY(tile1) - AIMap.GetTileY(tile2)) > 1) {
		return true;
		}
	}
return false;
}

function RailBuilder::Convert3TileLocatorToTrackID(prepre, pre, tile)
{
local data = tile-pre;
local dataprev = pre-prepre;

if((data==dataprev && dataprev==AIMap.GetTileIndex(0, -1)) || (data==dataprev && dataprev==AIMap.GetTileIndex(0, 1))) {
	//RAILTRACK_NE_SW
	return 1;
	}
if((data==dataprev && dataprev==AIMap.GetTileIndex(-1, 0)) || (data==dataprev && dataprev==AIMap.GetTileIndex(1, 0))) {
	//RAILTRACK_NW_SE
	return 2;
	}
if((dataprev==AIMap.GetTileIndex(0, -1) && data==AIMap.GetTileIndex(-1, 0)) || (dataprev==AIMap.GetTileIndex(1, 0) && data==AIMap.GetTileIndex(0, 1))) 
	{
	//RAILTRACK_NE_SE
	return 6;
	}
if(((dataprev==AIMap.GetTileIndex(-1, 0) && data==AIMap.GetTileIndex(0, -1))) || (dataprev==AIMap.GetTileIndex(0, 1) && data==AIMap.GetTileIndex(1, 0)))
	{
	//RAILTRACK_NW_SW
	return 5;
	}
if((dataprev==AIMap.GetTileIndex(0, 1) && data==AIMap.GetTileIndex(-1, 0)) || (dataprev==AIMap.GetTileIndex(1, 0) && data==AIMap.GetTileIndex(0, -1)))
	{
	//RAILTRACK_NW_NE
	return 3;
	}
if((dataprev==AIMap.GetTileIndex(0, -1) && data==AIMap.GetTileIndex(1, 0)) || (dataprev==AIMap.GetTileIndex(-1, 0) && data==AIMap.GetTileIndex(0, 1)))
	{
	//RAILTRACK_SW_SE
	return 4;
	}
AIAI.ClearSigns();
AISign.BuildSign(tile, "tile");
AISign.BuildSign(pre, "pre");
AISign.BuildSign(prepre, "prepre");
abort("invalid track");
}

function RailBuilder::CheckTileForEvilTracks(tile, path)
{
local tracks = AIRail.GetRailTracks(tile);
local table = array(7);
if(tracks == AIRail.RAILTRACK_INVALID)return true;
//Error("("+tracks+")***")
table[1]=AIRail.RAILTRACK_NE_SW & tracks;
table[2]=AIRail.RAILTRACK_NW_SE & tracks;
table[3]=AIRail.RAILTRACK_NW_NE & tracks;
table[4]=AIRail.RAILTRACK_SW_SE & tracks;
table[5]=AIRail.RAILTRACK_NW_SW & tracks;
table[6]=AIRail.RAILTRACK_NE_SE & tracks;

table[0]=0;
for(local i=1; i<=6; i++)
	if(table[i]){
		//AISign.BuildSign(tile, ".");
		//Info(i+"is here! *");
		table[0]++;
		}
local i=0;
local prevtile = null;
local prevprevtile = null;

while (path != null) {
	local current_tile = path.GetTile();
	i++;
	if(i>20) break;
	//
	if(prevtile==tile && prevprevtile != null)
		{
		table[Convert3TileLocatorToTrackID(prevprevtile, prevtile, current_tile)]=0;
		//Info(Convert3TileLocatorToTrackID(prevprevtile, prevtile, current_tile)+" detected*")
		table[0]--;
		if(table[0]==0)return true;
		}
	//
	path = path.GetParent();
	prevprevtile = prevtile
	prevtile = current_tile;
	}
if(table[0]==0)return true;
else return false;
}

function RailBuilder::testPath(path, stay_behind_path)
{
if(!CheckTileForEvilTracks(path.GetTile(), stay_behind_path))
	{
	return false;
	}
local test = AITestMode();
if(path != null && path.GetParent() != null && path.GetParent().GetParent() != null){
	local returned =  AIRail.BuildRail(path.GetTile(), path.GetParent().GetTile(), path.GetParent().GetParent().GetTile());
	if(AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) returned = true;
	if(AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY) returned = true;
	if(path.GetParent().GetParent().GetParent() != null) {
		local curve = path.GetTile() - path.GetParent().GetTile() != - (path.GetParent().GetParent().GetTile() - path.GetParent().GetParent().GetParent().GetTile())
		return curve && returned;
		}
	return returned;
	}
return true;
}

function RailBuilder::addTileToPath(path, tile, stay_behind_path)
{
if(!AIMap.IsValidTile(tile))return {path=path, OK=false};
if(path == null){
	return {path=Path(path, tile, null), OK=true};
	}
if(path.GetTile() == tile){
	return {path=path, OK=true};
	}

local prev = path.GetTile();

if(this.IsLongJump(prev, tile)) return {path=path, OK=false};
if(!this.Connected(prev, tile)) {
	for(local x=-1; x<=1; x++) {
		for(local y=-1; y<=1; y++) {
			if(this.DoubleConnected(prev, prev+AIMap.GetTileIndex(x, y), tile)) {
				if(!AITile.HasTransportType(prev+AIMap.GetTileIndex(x, y), AITile.TRANSPORT_RAIL))
					{
					path = Path(path, prev+AIMap.GetTileIndex(x, y), null);
					if(!testPath(path, stay_behind_path)) return {path=path, OK=false};
					path = Path(path, tile, null);
					if(!testPath(path, stay_behind_path)) return {path=path, OK=false};
					return {path=path, OK=true};
					}
				}
			}
		}
	if(!testPath(path, stay_behind_path)) return {path=path, OK=false};
	return {path=path, OK=false}
	}
path=Path(path, tile, null);
if(!testPath(path, stay_behind_path)) return {path=path, OK=false};
else return {path=path, OK=true};
}

function RailBuilder::IsItPossibleToEndPathWIthIt(path, prevtile, tile, aftertile, side, stay_behind_path, after1tile, after2tile, after3tile)
{
local old_copy = path;

if (!AIMap.IsValidTile(prevtile)) return false;
if (!AIMap.IsValidTile(tile)) return false;
if (!AIMap.IsValidTile(aftertile)) return false;
local tileSide = GetTileOnTheSideOftrack(tile, prevtile, side)
if (!AIMap.IsValidTile(tileSide)) return false;
path=addTileToPath(path, tileSide, stay_behind_path);
if(path.OK)path=path.path;
else{
	return false;
	}
	
path=addTileToPath(path, tile, stay_behind_path);
if(path.OK)path=path.path;
else{
	return false;
	}

path=addTileToPath(path, aftertile, stay_behind_path);
if(path.OK)path=path.path;
else{
	return false;
	}
if(after1tile != null) if(after1tile - path.GetTile() == - ( path.GetParent().GetTile() - path.GetParent().GetParent().GetTile() )) return false;
if(after2tile != null) if(path.GetTile() - path.GetParent().GetTile() == - ( after2tile - after1tile )) return false;
if(after3tile != null) if(after1tile - path.GetTile() == - ( after3tile - after2tile )) return false;
/*
{
local mode = AIExecMode();
AIAI.ClearSigns();
if(after2tile != null)AISign.BuildSign(after2tile, "after2tile");
if(after1tile != null)AISign.BuildSign(after1tile, "after1tile");
if(after3tile != null)AISign.BuildSign(after3tile, "after3tile");
AISign.BuildSign(aftertile, "aftertile");
AISign.BuildSign(path.GetTile(), "path.GetTile()");
AISign.BuildSign(path.GetParent().GetTile(), "path.GetParent().GetTile()");
AISign.BuildSign(path.GetParent().GetParent().GetTile(), "path.Parent().Parent().Tile()");
Info("*");
}
/*
DumbBuilder(old_copy)
Info("pre*");
this.DumbRemover(old_copy, null)
Info("pre*");


local copy = path;
DumbBuilder(copy)
AISign.BuildSign(tile, "+ - end");
Info("* - end");
local copy = path;
this.DumbRemover(copy, null)
Info("post*");
*/
return path;
}

function RailBuilder::IsItPossibleToStartPathWIthIt(prevprevtile, prevtile, tile, aftertile, side, stay_behind_path)
{
local afterSide = GetTileOnTheSideOftrack(aftertile, tile, side)
if (!AIMap.IsValidTile(prevtile)) return false;
if (!AIMap.IsValidTile(tile)) return false;
if (!AIMap.IsValidTile(aftertile)) return false;
if (!AIMap.IsValidTile(afterSide)) return false;
local path = null;

if(afterSide != aftertile) {
	path=addTileToPath(path, prevtile, stay_behind_path);
	if(path.OK)path=path.path;
	else return false;
	}
	
path=addTileToPath(path, tile, stay_behind_path);
if(path.OK)path=path.path;
else return false;

path=addTileToPath(path, afterSide, stay_behind_path);
if(path.OK)path=path.path;
else return false;

if(prevprevtile!= null) {
	local change = array(4);
	change[0] = prevtile - prevprevtile;
	change[1] = tile - prevtile;
	change[2] = afterSide - tile;
	change[3] = path.GetParent().GetTile() - tile;
	if(change[0]== -change[2])return false;
	if(change[0]== -change[3])return false;
}

/*
local copy = path;
DumbBuilder(copy)
AISign.BuildSign(tile, "+ - start");
Info("* - start");
local copy = path;
this.DumbRemover(copy, null)
Info("post*");
return path;
*/
return path;
}

enum PassingLaneFinderStatus
{
finished,
active,
failed,
}

class PassingLaneConstructor extends RailBuilder
{
status = null;
last_finished = null;
side = null;
active_construction = null;
start_tile = null;
end_tile = null;
number_of_start_tile = null;
debug_side = null;

constructor(side)
{
this.side = side;
this.status = PassingLaneFinderStatus.failed;
}

function GetPositionOfStart()
{
if(last_finished == null) return 1000000;
return number_of_start_tile;
}

function Finished()
{
return status == PassingLaneFinderStatus.finished;
}

function Active()
{
return status == PassingLaneFinderStatus.active;
}

function Failed()
{
return status == PassingLaneFinderStatus.failed;
}

function GetStatus()
{
return status;
}

function GetLane()
{
if(status != PassingLaneFinderStatus.finished)abort("GetLane - incorrect status Error <here insert random number :D>");
status = PassingLaneFinderStatus.failed
local copy_last_finished = last_finished;
this.last_finished = null;
return {path = copy_last_finished, start = start_tile, end = end_tile};
}

function process(path, stay_behind_path, tile, prevtile, prevprevtile, nextile, nextile_in_end, after1tile_in_end, after2tile_in_end, after3tile_in_end, number_of_tile)
	{
	if(status==PassingLaneFinderStatus.active) {
		active_construction=addTileToPath(active_construction, GetTileOnTheSideOftrack(tile, prevtile, side), stay_behind_path);
		if(active_construction.OK && path != null) {
			if(side == debug_side) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "active, longer");
			active_construction=active_construction.path;
			}
		else {
			if(last_finished!=null)	{
				if(side == debug_side) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "active, ended");
				status = PassingLaneFinderStatus.finished;
				}
			else {
				status = PassingLaneFinderStatus.failed;
				if(side == debug_side) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "active, failed");
				}
			active_construction=null;
			}
		}
	if(status==PassingLaneFinderStatus.active) {
		local test = null;
		test = IsItPossibleToEndPathWIthIt(active_construction, prevtile, tile, nextile_in_end, side, stay_behind_path, after1tile_in_end, after2tile_in_end, after3tile_in_end)
		if(test != false && test.GetRealLength()>9.0) //HACK, should be 7.0
			{
			if(side == debug_side) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "active, may end here "+test.GetRealLength());
			last_finished=test;
			end_tile = path;
			}
		else
			{
			if(side == debug_side) 
				{
				if(test != false) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "active, may NOT end here: "+test.GetRealLength());
				else AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "active, may NOT end here: false active_construction len:"+active_construction.GetRealLength());
				}
			}
		}
	if(status==PassingLaneFinderStatus.failed && prevtile != null) {
		local test = IsItPossibleToStartPathWIthIt(prevprevtile, prevtile, tile, nextile, side, stay_behind_path)
		if(test != false) {
			active_construction = test;
			status = PassingLaneFinderStatus.active;
			last_finished = null;
			if( path.GetChildren() != null ) 
				{
				start_tile = path.GetChildren();
				if( path.GetChildren().GetChildren() != null ) 
					start_tile = path.GetChildren().GetChildren();
				}
			else start_tile = path;
			number_of_start_tile = number_of_tile;
			if(side == debug_side) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "failed, started");
			}
		else
			{
			if(side == debug_side) AISign.BuildSign(tile + AIMap.GetTileIndex(0, 0), "failed");
			}
		}
}

}

function RailBuilder::AddPassingLanes(path)
{
local list = null;
local prevtile = null;
local prevprevtile = null;
local stay_behind_path = path;
local i = 0;
local right = PassingLaneConstructor(true);
local left = PassingLaneConstructor(false);
while (path != null) {
	i++;
	local tile = path.GetTile();
	local nextile = null;
	if(path != null && path.GetParent() != null) {
		nextile = path.GetParent().GetTile();
		}
	path = path.GetParent();
	if(i>10) stay_behind_path = stay_behind_path.GetParent();
	local nextile_in_end = nextile
	local after1tile_in_end = null;
	local after2tile_in_end = null;
	local after3tile_in_end = null;
	if(!(tile != nextile || path.GetParent() == null || path.GetParent().GetParent() == null))
		{
		nextile_in_end = path.GetParent().GetParent().GetTile();
		after1tile_in_end = path.GetParent().GetParent().GetTile();
		if(path.GetParent().GetParent().GetParent() != null) {
			after2tile_in_end = path.GetParent().GetParent().GetParent().GetTile();
			if(path.GetParent().GetParent().GetParent().GetParent() != null) after3tile_in_end = path.GetParent().GetParent().GetParent().GetParent().GetTile();
			}
		}
	else
		{
		if(path != null)if(path.GetParent() != null)
			{
			after1tile_in_end = path.GetParent().GetTile();
			if(path.GetParent().GetParent() != null) 
				{
				after2tile_in_end = path.GetParent().GetParent().GetTile();
				if(path.GetParent().GetParent().GetParent() != null) after3tile_in_end = path.GetParent().GetParent().GetParent().GetTile();
				}
			}
		}
	
	right.process(path, stay_behind_path, tile, prevtile, prevprevtile, nextile, nextile_in_end, after1tile_in_end, after2tile_in_end, after3tile_in_end, i)
	left.process(path, stay_behind_path, tile, prevtile, prevprevtile, nextile, nextile_in_end, after1tile_in_end, after2tile_in_end, after3tile_in_end, i)

	if(right.Finished() && (right.GetPositionOfStart() < left.GetPositionOfStart() || left.Failed())) {
		list = addToArray(list, right.GetLane());
		right = PassingLaneConstructor(true);
		left = PassingLaneConstructor(false);
		}
	else if(left.Finished() && (left.GetPositionOfStart() < right.GetPositionOfStart() || right.Failed())) {
		list = addToArray(list, left.GetLane());
		right = PassingLaneConstructor(true);
		left = PassingLaneConstructor(false);
		}
	if(left.Finished()) left.GetLane();
	if(right.Finished()) right.GetLane();
	prevprevtile = prevtile;
	prevtile = tile;
	}

local count = 0;
if(list!=null)
for(local i=0; i<list.len(); i++)
	{
	local copy = list[i].path;
	if(DumbBuilder(copy)) {
		copy = list[i].path;
		count+=SignalPathAdvanced(copy, 7, null, 9999);
		count+=SignalPathAdvanced(list[i].start, 7, list[i].end, 9999);
		}
	}
return count;
}