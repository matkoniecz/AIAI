require("compat_1.0.nut");
import("util.superlib", "SuperLib", 19);
Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction
Road <- SuperLib.Road
Money <- SuperLib.Money

AIMap._IsValidTile <- AIMap.IsValidTile;
AIMap.IsValidTile <- function(tile)
{
	if(tile == null) return false;
	return AIMap._IsValidTile(tile);
}

AISign._BuildSign <- AISign.BuildSign;
AISign.BuildSign <- function(tile, text)
{
	local returned = AISign._BuildSign(tile, text);
	if(AIError.GetLastError()!=AIError.ERR_NONE)
		Error(AIError.GetLastErrorString() + " - SIGN FAILED" );
	Info("signSTOP!  ("+text+")")
	return returned;
}

require("UTIL/util.nut");
require("UTIL/util_is_allowed.nut");
require("UTIL/UTILtile.nut");
require("UTIL/util_AIAI.nut")
require("strategy.nut");
require("autoreplace.nut");
require("classes_enums.nut");
require("findpair.nut");
require("Builder.nut");
require("RAIL/RailBuilder.nut");
require("RAIL/StupidRailBuilder.nut");
require("ROAD/RoadBuilder.nut");
require("ROAD/BusRoadBuilder.nut");
require("ROAD/TruckRoadBuilder.nut");
require("AIR/AirBuilder.nut");
require("AIR/PAXAirBuilder.nut");
require("AIR/CargoAirBuilder.nut");


/**
 *  path from the AyStar algorithm, without internal pf data.
 *  It is reversed, that is, the first entry is more close to the goal-nodes
 *  than his GetParent(). You can walk this list to find the whole path.
 *  The last entry has a GetParent() of null.
 */
class Path
{
	_prev = null;
	_tile = null;
	_direction = null;
	_cost = null;
	_length = null;
	_real_length = null;

	constructor(old_path, new_tile, new_direction)
	{
		this._prev = old_path;
		this._tile = new_tile;
		this._direction = new_direction;
		if (old_path == null) {
			this._length = 0;
			this._real_length = 0.0;
		} else {
			this._length = old_path.GetLength() + AIMap.DistanceManhattan(old_path.GetTile(), new_tile);
			if(old_path.GetParent() != null)
				{
				local old_tile = old_path.GetTile();
				if(Helper.Abs(AIMap.GetTileX(old_tile)-AIMap.GetTileX(new_tile))<=1 && Helper.Abs(AIMap.GetTileY(old_tile)-AIMap.GetTileY(new_tile))<=1) {
					Info(this._real_length+">");
					this._real_length = old_path.GetRealLength() + 0.5;
					Info(this._real_length+"<");
					}
				else{
					Info(this._real_length+">");
					this._real_length = old_path.GetRealLength() + 1.0;
					Info(this._real_length+"<");
					}
				}
			else
				{
				Info(this._real_length+">");
				this._real_length = 0.0;
				Info(this._real_length+"<");
				}
		}
	};

	/**
	 * Return the tile where this (partial-)path ends.
	 */
	function GetTile() { return this._tile; }

	/**
	 * Return the direction from which we entered the tile in this (partial-)path.
	 */
	function GetDirection() { return this._direction; }

	/**
	 * Return an instance of this class leading to the previous node.
	 */
	function GetParent() { return this._prev; }

	/**
	 * Return the length (in tiles) of this path.
	 */
	function GetLength() { return this._length; }
	/**

	* Return the length (in tiles) of this path.
	 */
	function GetRealLength() 
	{ 
	if(this.GetParent() == null) return 0;
	return this.GetParent()._real_length; 
	}
};
