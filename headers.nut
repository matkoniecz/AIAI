require("strategy.nut");
require("findpair.nut");
require("util.nut");
require("UTILtile.nut");
require("AIAI.nut");

require("Builder.nut");
require("RAIL/RailBuilder.nut");
require("RAIL/SmartRailBuilder.nut");
require("RAIL/StupidRailBuilder.nut");
require("ROAD/RoadBuilder.nut");
require("ROAD/BusRoadBuilder.nut");
require("ROAD/TruckRoadBuilder.nut");
require("AIR/AirBuilder.nut");
require("AIR/PAXAirBuilder.nut");
require("AIR/CargoAirBuilder.nut");

import("util.superlib", "SuperLib", 7); //http://www.tt-forums.net/viewtopic.php?p=960013#p960013 - przed up do 10

Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction

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

	constructor(old_path, new_tile, new_direction)
	{
		this._prev = old_path;
		this._tile = new_tile;
		this._direction = new_direction;
		if (old_path == null) {
			this._length = 0;
		} else {
			this._length = old_path.GetLength() + AIMap.DistanceManhattan(old_path.GetTile(), new_tile);
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
};
