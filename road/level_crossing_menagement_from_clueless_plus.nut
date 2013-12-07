//idea and code stolen from CluelessPlus
//I claim authorship of all bugs

function AIAI::HandleNewLevelCrossing(event)
{
	local crash_event = AIEventVehicleCrashed.Convert(event);
	local crash_reason = crash_event.GetCrashReason();
	local vehicle_id = crash_event.GetVehicleID();
	local crash_tile = crash_event.GetCrashSite();
	Info("Vehicle " + AIVehicle.GetName(vehicle_id) + " crashed at level crossing");

	local neighbours = Tile.GetNeighbours4MainDir(crash_tile);
	neighbours.Valuate(AIRoad.AreRoadTilesConnected, crash_tile);
	neighbours.KeepValue(1);
	
	local road_tile_next_to_crossing = neighbours.Begin();
	
	if (!neighbours.IsEmpty() && Road.ConvertRailCrossingToBridge(crash_tile, road_tile_next_to_crossing) == null) {
		// couldn't fix it right now, so put in in a wait list
		this.list_of_detected_rail_crossings.AddItem(crash_tile, 0);
	}
}

function AIAI::HandleOldLevelCrossings()
{
	// Check for rail crossings that couldn't be fixed just after a crash event
	this.list_of_detected_rail_crossings.Valuate(Helper.ItemValuator);
	foreach(crash_tile, _ in this.list_of_detected_rail_crossings) {
		Info("Trying to fix a railway crossing that had an accident before");
		//Helper.BuildSign(crash_tile, "crash_tile");
		local neighbours = Tile.GetNeighbours4MainDir(crash_tile);
		neighbours.Valuate(AIRoad.AreRoadTilesConnected, crash_tile);
		neighbours.KeepValue(1);
		
		local road_tile_next_to_crossing = neighbours.Begin();

		if (neighbours.IsEmpty() ||
				!AIMap.IsValidTile(road_tile_next_to_crossing) ||
				!AITile.HasTransportType(crash_tile, AITile.TRANSPORT_ROAD) ||
				!AITile.HasTransportType(road_tile_next_to_crossing, AITile.TRANSPORT_ROAD)) {
			this.list_of_detected_rail_crossings.RemoveValue(crash_tile);
		}

		local bridge_result = Road.ConvertRailCrossingToBridge(crash_tile, road_tile_next_to_crossing); 
		if (bridge_result.succeeded == true || bridge_result.permanently == true) {
			// Succeded to build rail crossing or failed permanently -> don't try again
			this.list_of_detected_rail_crossings.RemoveValue(crash_tile);
		}
	}
}