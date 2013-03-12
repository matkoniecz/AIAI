/*
 * This file is part of AdmiralAI.
 *
 * AdmiralAI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * AdmiralAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with AdmiralAI.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2008-2009 Thijs Marinussen
 */

 /** @file utils/tile.nut AITile-related utility functions. */

/**
 * A utility class containing tile related functions.
 */
class Utils_Tile
{
/* public: */

	/**
	 * Get the real tile height of a tile. The real tile hight is the base tile hight plus 1 if
	 *   the tile is a non-flat tile.
	 * @param tile The tile to get the height for.
	 * @return The height of the tile.
	 * @note The base tile hight is not the same as AITile.GetHeight. The value returned by
	 *   AITile.GetHeight is one too high in case the north corner is raised.
	 */
	static function GetRealHeight(tile);

	/**
	 * Check if we can handle a tile as a flat tile.
	 * @param tile The tile to check.
	 * @return Whether or not at least three corners of the tile are at the same
	 *  height and the other corner is not higher.
	 */
	static function IsNearlyFlatTile(tile);

	/**
	 * Add a square around a tile to an AITileList.
	 * @param tile_list The AITileList to add the tiles to.
	 * @param center_tile The center where the square should be created around.
	 * @param radius Half of the diameter of the square.
	 * @note The square ranges from (centertile - (radius, radius)) to (centertile + (radius, radius)).
	 */
	static function AddSquare(tile_list, center_tile, radius);

	/**
	 * A safe implementation of AITileList.AddRectangle. Only valid tiles are
	 *  added to the tile list.
	 * @param tile_list The AITileList to add the tiles to.
	 * @param center_tile The center of the rectangle.
	 * @param x_min The amount of tiles to the north-east, relative to center_tile.
	 * @param y_min The amount of tiles to the north-west, relative to center_tile.
	 * @param x_plus The amount of tiles to the south-west, relative to center_tile.
	 * @param y_plus The amount of tiles to the south-east, relative to center_tile.
	 */
	static function AddRectangleSafe(tile_list, center_tile, x_min, y_min, x_plus, y_plus);

	/**
	 * A safe implementation of AITileList.RemoveRectangle. Only valid tiles are
	 *  removed to the tile list.
	 * @param tile_list The AITileList to remove the tiles from.
	 * @param center_tile The center of the rectangle.
	 * @param x_min The amount of tiles to the north-east, relative to center_tile.
	 * @param y_min The amount of tiles to the north-west, relative to center_tile.
	 * @param x_plus The amount of tiles to the south-west, relative to center_tile.
	 * @param y_plus The amount of tiles to the south-east, relative to center_tile.
	 */
	static function RemoveRectangleSafe(tile_list, center_tile, x_min, y_min, x_plus, y_plus);

	/**
	 * Get the manhattan distance between a vehicle and a tile.
	 * @param vehicle The location of this vehicle is one end.
	 * @param tile The tile that is the other end.
	 * @return The manhattan distance between the vehicle and the tile.
	 */
	static function VehicleManhattanDistanceToTile(vehicle, tile);

	/**
	 * Check if a station can be build at a tile.
	 * @param tile The tile to check.
	 * @param width The width of the new station.
	 * @param height The height of the new station.
	 * @return The height the station can be build on or -1 if the station cannot be buid.
	 */
	static function CanBuildStation(tile, width, height);

	/**
	 * Try to flatten the land for a station.
	 * @param tile The topmost tile of the new station.
	 * @param width The width of the new station.
	 * @param height The height of the new station.
	 * @param tile_height The height all the tiles should be terraformed to.
	 * @return Whether the terraforming succeeded.
	 */
	static function FlattenLandForStation(tile, width, height, tile_height, force_flatten_x = false, force_flatten_y = false);
};

function Utils_Tile::GetRealHeight(tile)
{
	local height = AITile.GetCornerHeight(tile, AITile.CORNER_N); //API updated
	local slope = AITile.GetSlope(tile);
	if (AITile.IsSteepSlope(slope)) {
		switch (slope) {
			case AITile.SLOPE_STEEP_N: return height;
			case AITile.SLOPE_STEEP_E: return height + 1;
			case AITile.SLOPE_STEEP_W: return height + 1;
			case AITile.SLOPE_STEEP_S: return height + 2;
		}
	}
	if (slope & AITile.SLOPE_N) height--;
	if (slope != AITile.SLOPE_FLAT) height++;
	return height;
}

function Utils_Tile::IsNearlyFlatTile(tile)
{
	local slope = AITile.GetSlope(tile);
	return slope == AITile.SLOPE_FLAT || slope == AITile.SLOPE_NWS || slope == AITile.SLOPE_WSE ||
			slope == AITile.SLOPE_SEN || slope == AITile.SLOPE_ENW;
}

function Utils_Tile::AddSquare(tile_list, center_tile, radius)
{
	Utils_Tile.AddRectangleSafe(tile_list, center_tile, radius, radius, radius, radius);
}

function Utils_Tile::AddRectangleSafe(tile_list, center_tile, x_min, y_min, x_plus, y_plus)
{
	local tile_x = AIMap.GetTileX(center_tile);
	local tile_y = AIMap.GetTileY(center_tile);
	local tile_from = AIMap.GetTileIndex(max(1, tile_x - x_min), max(1, tile_y - y_min));
	local tile_to = AIMap.GetTileIndex(min(AIMap.GetMapSizeX() - 2, tile_x + x_plus), min(AIMap.GetMapSizeY() - 2, tile_y + y_plus));
	tile_list.AddRectangle(tile_from, tile_to);
}

function Utils_Tile::RemoveRectangleSafe(tile_list, center_tile, x_min, y_min, x_plus, y_plus)
{
	local tile_x = AIMap.GetTileX(center_tile);
	local tile_y = AIMap.GetTileY(center_tile);
	local tile_from = AIMap.GetTileIndex(max(1, tile_x - x_min), max(1, tile_y - y_min));
	local tile_to = AIMap.GetTileIndex(min(AIMap.GetMapSizeX() - 2, tile_x + x_plus), min(AIMap.GetMapSizeY() - 2, tile_y + y_plus));
	tile_list.RemoveRectangle(tile_from, tile_to);
}

function Utils_Tile::VehicleManhattanDistanceToTile(vehicle, tile)
{
	return AIMap.DistanceManhattan(AIVehicle.GetLocation(vehicle), tile);
}

function Utils_Tile::CanBuildStation(tile, width, height)
{
	local test = AITestMode();
	if (!AITile.IsBuildableRectangle(tile, width, height)) return -1;
	local min_height = Utils_Tile.GetRealHeight(tile);
	local max_height = min_height;
	for (local x = AIMap.GetTileX(tile); x < AIMap.GetTileX(tile) + width; x++) {
		for (local y = AIMap.GetTileY(tile); y < AIMap.GetTileY(tile) + height; y++) {
			local h = Utils_Tile.GetRealHeight(AIMap.GetTileIndex(x, y));
			min_height = min(min_height, h);
			max_height = max(max_height, h);
			if (max_height - min_height > 2) return -1;
		}
	}
	local target_heights = [(max_height + min_height) / 2];
	if (max_height - min_height == 1) target_heights.push(max_height);
	foreach (height in target_heights) {
		if (height == 0) continue;
		local tf_ok = true;
		for (local x = AIMap.GetTileX(tile); tf_ok && x < AIMap.GetTileX(tile) + width; x++) {
			for (local y = AIMap.GetTileY(tile); tf_ok && y < AIMap.GetTileY(tile) + height; y++) {
				local t = AIMap.GetTileIndex(x, y);
				local h = Utils_Tile.GetRealHeight(t);
				if (h < height && !AITile.RaiseTile(t, AITile.GetComplementSlope(AITile.GetSlope(t)))) {
					tf_ok = false;
					break;
				}
				h = Utils_Tile.GetRealHeight(t);
				/* We need to check this twice, because the first one flattens the tile, and the second time it's raised. */
				if (h < height && !AITile.RaiseTile(t, AITile.GetComplementSlope(AITile.GetSlope(t)))) {
					tf_ok = false;
					break;
				}
				if (h > height && !AITile.LowerTile(t, AITile.GetSlope(t) != AITile.SLOPE_FLAT ? AITile.GetSlope(t) : AITile.SLOPE_ELEVATED)) {
					tf_ok = false;
					break;
				}
			}
		}
		if (tf_ok) {
			return height;
		}
	}
	return -1;
}

function Utils_Tile::FlattenLandForStation(tile, width, height, tile_height, force_flatten_x = false, force_flatten_y = false)
{
	local flatten_all = AIGameSettings.GetValue("construction.build_on_slopes") == 0;
	local min_x = AIMap.GetTileX(tile);
	local max_x = min_x + width - 1;
	local min_y = AIMap.GetTileY(tile);
	local max_y = min_y + height - 1;
	/* Loop over all tiles the airport will cover. */
	for (local x = min_x; x <= max_x; x++) {
		for (local y = min_y; y <= max_y; y++) {
			local t = AIMap.GetTileIndex(x, y);
			local h = Utils_Tile.GetRealHeight(t);
			if (Helper.Abs(tile_height - h) >= 2) {
				Error("Utils_Tile::FlattenLandForStation(): Difference in tile height is too big");
				return false;
			}
			/* AITile.GetComplementSlope can't handle steep slopes, so raise
			 * the lowest corner of tiles with a steep slope. */
			if (AITile.IsSteepSlope(AITile.GetSlope(t))) {
				switch (AITile.GetSlope(t)) {
					case AITile.SLOPE_STEEP_W:
						if (!AITile.RaiseTile(t, AITile.SLOPE_E)) return false;
						break;
					case AITile.SLOPE_STEEP_S:
						if (!AITile.RaiseTile(t, AITile.SLOPE_N)) return false;
						break;
					case AITile.SLOPE_STEEP_E:
						if (!AITile.RaiseTile(t, AITile.SLOPE_W)) return false;
						break;
					case AITile.SLOPE_STEEP_N:
						if (!AITile.RaiseTile(t, AITile.SLOPE_S)) return false;
						break;
				}
			}
			if (h == tile_height && AITile.GetSlope(t) == AITile.SLOPE_FLAT) continue;
			if (h > tile_height) {
				if (!AITile.LowerTile(t, AITile.GetSlope(t) != AITile.SLOPE_FLAT ? AITile.GetSlope(t) : AITile.SLOPE_ELEVATED)) return false;
			} else {
				if (h < tile_height) {
					/* Tiles with there heighest corner lower than the desired height
					* that are not flat need to be terraformed twice. */
					if (AITile.GetSlope(t) != AITile.SLOPE_FLAT) {
						if (!AITile.RaiseTile(t, AITile.GetComplementSlope(AITile.GetSlope(t)))) return false;
					}
				}
				local slope = AITile.GetComplementSlope(AITile.GetSlope(t));
				if (!flatten_all) {
					/* With build-on-slopes on, don't terraform every tile. */
					if (x == min_x && !force_flatten_x) slope = slope & AITile.SLOPE_SW;
					if (x == max_x && !force_flatten_x) slope = slope & AITile.SLOPE_NE;
					if (y == min_y && !force_flatten_y) slope = slope & AITile.SLOPE_SE;
					if (y == max_y && !force_flatten_y) slope = slope & AITile.SLOPE_NW;
				}
				if (slope != AITile.SLOPE_FLAT && !AITile.RaiseTile(t, slope)) return false;
			}
		}
	}
	return true;
}
