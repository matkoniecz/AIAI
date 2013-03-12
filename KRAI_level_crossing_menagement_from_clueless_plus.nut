function KRAI::HandleNewLevelCrossing(ev) //from CluelessPlus
{
			   local crash_event = AIEventVehicleCrashed.Convert(ev);
			   local crash_reason = crash_event.GetCrashReason();
			   local vehicle_id = crash_event.GetVehicleID();
			   local crash_tile = crash_event.GetCrashSite();
			   Warning("Vehicle " + AIVehicle.GetName(vehicle_id) + " crashed at level crossing");				

				local neighbours = Tile.GetNeighbours4MainDir(crash_tile);
				neighbours.Valuate(AIRoad.AreRoadTilesConnected, crash_tile);
				neighbours.KeepValue(1);
				
				local road_tile_next_to_crossing = neighbours.Begin();

				if(!neighbours.IsEmpty() && ConvertRailCrossingToBridge(crash_tile, road_tile_next_to_crossing) == null)
				{
					// couldn't fix it right now, so put in in a wait list
					this.detected_rail_crossings.AddItem(crash_tile, road_tile_next_to_crossing);
				}
}

function KRAI::HandleOldLevelCrossings() //from CluelessPlus
{
if(AIBase.RandRange(3)==0)
   {
   detected_rail_crossings = AIList();
   Info("detected_rail_crossings cleared");
   return;
   }
					this.detected_rail_crossings.Valuate(Helper.ItemValuator);
					foreach(crash_tile, _ in this.detected_rail_crossings)
					{
						AILog.Info("Trying to fix a railway crossing that had an accident before (one of" + this.detected_rail_crossings.Count() + ")" );
						local neighbours = Tile.GetNeighbours4MainDir(crash_tile);
						neighbours.Valuate(AIRoad.AreRoadTilesConnected, crash_tile);
						neighbours.KeepValue(1);
						
						local road_tile_next_to_crossing = neighbours.Begin();

						if(neighbours.IsEmpty() ||
								!AIMap.IsValidTile(road_tile_next_to_crossing) || 
								ConvertRailCrossingToBridge(crash_tile, road_tile_next_to_crossing) != null)
						{
							this.detected_rail_crossings.RemoveValue(crash_tile);
						}
					}

}

// returns [bridge_start_tile, bridge_end_tile] or null
function ConvertRailCrossingToBridge(rail_tile, prev_tile) //from CluelessPlus
{
	local forward_dir = Direction.GetDirectionToAdjacentTile(prev_tile, rail_tile);
	local backward_dir = Direction.TurnDirClockwise45Deg(forward_dir, 4);

	local tile_after = Direction.GetAdjacentTileInDirection(rail_tile, forward_dir);
	local tile_before = Direction.GetAdjacentTileInDirection(rail_tile, backward_dir);

	// Check if the tile before rail is a rail-tile. If so, go to prev tile for a maximum of 10 times
	local i = 0;
	while (AITile.HasTransportType(tile_before, AITile.TRANSPORT_RAIL) && i < 10)
	{
		tile_before = Direction.GetAdjacentTileInDirection(tile_before, backward_dir);
		i++;
	}

	// Check if the tile after rail is a rail-tile. If so, go to next tile for a maximum of 10 times (in total with going backwards)
	while (AITile.HasTransportType(tile_after, AITile.TRANSPORT_RAIL) && i < 10)
	{
		tile_after = Direction.GetAdjacentTileInDirection(tile_after, forward_dir);
		i++;
	}

	Helper.SetSign(tile_after, "after");
	Helper.SetSign(tile_before, "before");
	
	// rail-before shouldn't be a rail tile as we came from it, but if it is then it is a multi-rail that
	// previously failed to be bridged
	if (AITile.HasTransportType(tile_before, AITile.TRANSPORT_RAIL) ||
			AIBridge.IsBridgeTile(tile_before) ||
			AITunnel.IsTunnelTile(tile_before))
	{
		AILog.Info("Fail 1");
		return null;
	}

	// If after moving 10 times, there is still a rail-tile, abort
	if (AITile.HasTransportType(tile_after, AITile.TRANSPORT_RAIL) ||
			AIBridge.IsBridgeTile(tile_after) ||
			AITunnel.IsTunnelTile(tile_after))
	{
		AILog.Info("Fail 2");
		return null;
	}


	/* Now tile_before and tile_after are the tiles where the bridge would begin/end */
	
	// Check that we own those tiles. NoAI 1.0 do not have any constants for checking if a owner is a company or
	// not. -1 seems to indicate that it is not a company. ( = town )
	local tile_after_owner = AITile.GetOwner(tile_after);
	local tile_before_owner = AITile.GetOwner(tile_before);
	if ( (tile_before_owner != -1 && !AICompany.IsMine(tile_before_owner)) || 
			(tile_after_owner != -1 && !AICompany.IsMine(tile_after_owner)) )
	{
		AILog.Info("Not my road - owned by " + tile_before_owner + ": " + AICompany.GetName(tile_before_owner) + " and " + tile_after_owner + ":" + AICompany.GetName(tile_after_owner));
		AILog.Info("Fail 3");
		return null;
	}

	// Check that those tiles do not have 90-deg turns, T-crossings or 4-way crossings
	local left_dir = Direction.TurnDirAntiClockwise45Deg(forward_dir, 2);
	local right_dir = Direction.TurnDirClockwise45Deg(forward_dir, 2);

	local bridge_ends = [tile_before, tile_after];
	foreach(end_tile in bridge_ends)
	{
		local left_tile = Direction.GetAdjacentTileInDirection(end_tile, left_dir);
		local right_tile = Direction.GetAdjacentTileInDirection(end_tile, right_dir);

		if (AIRoad.AreRoadTilesConnected(end_tile, left_tile) || AIRoad.AreRoadTilesConnected(end_tile, right_tile))
		{
			AILog.Info("Fail 4");
			return null;
		}
	}

	/* Now we know that we can demolish the road on tile_before and tile_after without destroying any road intersections */
	
	local tunnel = false;
	local bridge = false;

	//local after_dn_slope = Tile.IsDownSlope(tile_after, forward_dir);
	local after_dn_slope = Tile.IsUpSlope(tile_after, backward_dir);
	local before_dn_slope = Tile.IsDownSlope(tile_before, backward_dir);
	local same_height = AITile.GetMaxHeight(tile_after) == AITile.GetMaxHeight(tile_before);

	AILog.Info("after_dn_slope = " + after_dn_slope + " | before_dn_slope = " + before_dn_slope + " | same_height = " + same_height);

	if (Tile.IsDownSlope(tile_after, forward_dir) && Tile.IsDownSlope(tile_before, backward_dir) &&
		AITile.GetMaxHeight(tile_after) == AITile.GetMaxHeight(tile_before)) // Make sure the tunnel entrances are at the same height
	{
		// The rail is on a hill with down slopes at both sides -> can tunnel under the railway.
		tunnel = true;
	}
	else
	{
		if (AITile.GetMaxHeight(tile_before) == AITile.GetMaxHeight(tile_after)) // equal (max) height
		{
			// either 
			// _______      _______
			//        \____/
			//         rail
			//
			// or flat 
			// ____________________
			//         rail
			bridge = (Tile.IsBuildOnSlope_UpSlope(tile_before, backward_dir) && Tile.IsBuildOnSlope_UpSlope(tile_after, forward_dir)) ||
					(Tile.IsBuildOnSlope_FlatInDirection(tile_before, forward_dir) && Tile.IsBuildOnSlope_FlatInDirection(tile_after, forward_dir));
		}
		else if (AITile.GetMaxHeight(tile_before) == AITile.GetMaxHeight(tile_after) + 1) // tile before is one higher
		{
			// _______
			//        \____________
			//         rail

			bridge = Tile.IsBuildOnSlope_UpSlope(tile_before, backward_dir) && Tile.IsBuildOnSlope_FlatInDirection(tile_after, forward_dir);

		}
		else if (AITile.GetMaxHeight(tile_before) + 1 == AITile.GetMaxHeight(tile_after)) // tile after is one higher
		{
			//              _______
			// ____________/
			//         rail

			bridge = Tile.IsBuildOnSlope_FlatInDirection(tile_before, forward_dir) && Tile.IsBuildOnSlope_UpSlope(tile_after, forward_dir);
		}
		else // more than one level of height difference
		{
		}
	}

	if (!tunnel && !bridge)
	{
		// Can neither make tunnel or build bridge
		AILog.Info("Fail 5");
		return null;
	}

	local bridge_length = AIMap.DistanceManhattan(tile_before, tile_after) + 1;
	local bridge_list = AIBridgeList_Length(bridge_length);
	if (bridge)
	{
		if (bridge_list.IsEmpty())
		{
			AILog.Info("Fail 6");
			return null; // There is no bridge for this length
		}
	}

	/* Now we know it is possible to bridge/tunnel the rail from tile_before to tile_after */
	
	// Make sure we can afford the construction
	AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < 20000)
	{
		AILog.Info("Found railway crossing that can be replaced, but bail out because of low founds.");
		AILog.Info("Fail 7");
		return null;
	}

	/* Now lets get started removing the old road! */

	{
		// Since it is a railway crossing it is a good idea to remove the entire road in one go.
		local i = 0;
		while(i < 20 && !AIRoad.RemoveRoadFull(tile_before, tile_after))
		{
			local last_error = AIError.GetLastError();
			if(last_error == AIError.ERR_VEHICLE_IN_THE_WAY || last_error == AIError.ERR_NOT_ENOUGH_CASH)
			{
				AILog.Info("Couldn't remove road over rail because of vehicle in the way or low cash -> wait and try again");
				AIController.Sleep(5);
			}
			else
			{
				AILog.Info("Couldn't remove road because " + AIError.GetLastErrorString());
				break;
			}
			i++;
		}

		if (AIRoad.AreRoadTilesConnected(tile_before, tile_after))
		{
			AILog.Info("Tried to remove road over rail for a while, but failed");
			AILog.Info("Fail 8");
			return null;
		}
	}

	/* Now lets get started building bridge / tunnel! */

	local build_failed = false;	

	if (tunnel)
	{
		if(!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, tile_before))
			build_failed = true;
	}
	else if (bridge)
	{
		bridge_list.Valuate(AIBridge.GetMaxSpeed);
		if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), tile_before, tile_after))
			build_failed = true;
	}

	if (build_failed)
	{
		local what = tunnel == true? "tunnel" : "bridge";
		AILog.Warning("Failed to build " + what + " to cross rail because " + AIError.GetLastErrorString() + ". Now try to build road to repair the road.");
		if(AIRoad.BuildRoadFull(tile_before, tile_after))
		{
			AILog.Error("Failed to repair road crossing over rail by building road because " + AIError.GetLastErrorString());
		}

		AILog.Info("Fail 9");
		return null;
	}

	return [tile_before, tile_after];
}