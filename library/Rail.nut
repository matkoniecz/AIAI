AILog.Info("adding new functions to SuperLib (Rail)");

class Rail{}

	//from AIAI by Kogut
	//attempts to locate brake van - wagon appearing in some newgrfs (for example - Japanese Train Set v2.1a), required to start freight train
	//search is limited to ones usable on specified railtype
	//returns engine_id of the fastest one or null if none was found
	//GetBrakeVan(railtype)

	//from AdmiralAI by Thijs Marinussen
	//constructs RailDepot and connects it to railway supplied in path parameter, may perform some landscaping to allow construction of the depot
	//Returns a depot tile if successful, null otherwise 
	//BuildDepot(path);

function Rail::GetBrakeVan(railtype)
{
	local wagons = AIEngineList(AIVehicle.VT_RAIL);
	wagons.Valuate(AIEngine.IsWagon);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.IsBuildable);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.CanRunOnRail, railtype);
	wagons.RemoveValue(0);
	local cargo_list=AICargoList();
	for (local cargoIndex = cargo_list.Begin(); !cargo_list.IsEnd(); cargoIndex = cargo_list.Next()){
		wagons.Valuate(AIEngine.CanRefitCargo, cargoIndex);
		wagons.RemoveValue(1);
	}
	if (wagons.Count() == 0){
		return null;
	} else {
		wagons.Valuate(AIEngine.GetMaxSpeed);
		return wagons.Begin();
	}
}

function Rail::BuildDepot(path)
{
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
					if (AITile.GetMaxHeight(ppp + offset) != AITile.GetMaxHeight(ppp)) continue;
					local depot_build = false;
					if (AIRail.IsRailDepotTile(ppp + offset)) {
						if (AIRail.GetRailDepotFrontTile(ppp + offset) != ppp) continue;
						if (!AIRail.TrainHasPowerOnRail(AIRail.GetRailType(ppp + offset), AIRail.GetCurrentRailType())) continue;
						/* If we can't build trains for the current this type in the depot, see if we can
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
				if (Helper.Abs(ppppp - ppp) == AIMap.GetTileIndex(1, 1)) {
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
		/* If we can't build trains for the current this type in the depot, see if we can
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
		/* If we can't build trains for the current this type in the depot, see if we can
		 * convert it without problems. */
		if (!AIRail.TrainHasPowerOnRail(AIRail.GetCurrentRailType(), AIRail.GetRailType(tile_c + offset2))) {
			if (!AIRail.ConvertRailType(tile_c + offset2, tile_c + offset2, AIRail.GetCurrentRailType())) return null;
		}
		depot_tile = tile_c + offset2;
		depot_build = true;
		tiles.append([tile_a + offset1, tile_c, tile_c + offset2]);
		tiles.append([tile_b + offset2, tile_c, tile_c + offset2]);
	} else if (AITile.IsBuildable(tile_c + offset1)) {
		if (AITile.GetMaxHeight(tile_c) != AITile.GetMaxHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		if (AITile.GetMaxHeight(tile_c) != AITile.GetMaxHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		depot_tile = tile_c + offset1;
		tiles.append([tile_a + offset1, tile_c, tile_c + offset1]);
		tiles.append([tile_b + offset2, tile_c, tile_c + offset1]);
	} else if (AITile.IsBuildable(tile_c + offset2)) {
		if (AITile.GetMaxHeight(tile_c) != AITile.GetMaxHeight(tile_a) &&
			!AITile.RaiseTile(tile_c, AITile.GetComplementSlope(AITile.GetSlope(tile_c)))) return null;
		if (AITile.GetMaxHeight(tile_c) != AITile.GetMaxHeight(tile_a) &&
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

AILog.Info("changing SuperLib (Rail) finished");
