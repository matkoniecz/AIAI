function AIAI::HandleNewLevelCrossing(ev) //from CluelessPlus
{
	local crash_event = AIEventVehicleCrashed.Convert(ev);
	local crash_reason = crash_event.GetCrashReason();
	local vehicle_id = crash_event.GetVehicleID();
	local crash_tile = crash_event.GetCrashSite();
	Info("Vehicle " + AIVehicle.GetName(vehicle_id) + " crashed at level crossing");				

	local neighbours = Tile.GetNeighbours4MainDir(crash_tile);
	//neighbours.Valuate(AIRoad.AreRoadTilesConnected, crash_tile);
	//neighbours.KeepValue(1);
	//
	//local road_tile_next_to_crossing = neighbours.Begin();
	//
	//if(!neighbours.IsEmpty() && ConvertRailCrossingToBridge(crash_tile, road_tile_next_to_crossing) == null)
	//{
	//	// couldn't fix it right now, so put in in a wait list
		this.detected_rail_crossings.AddItem(crash_tile, 0);
	this.HandleOldLevelCrossings()
	//}
}

function AIAI::HandleOldLevelCrossings() //from CluelessPlus
{
	// Check for rail crossings that couldn't be fixed just after a crash event
	//TimerStart("rail_crossings"); TODO FIXME IMPORT
	this.detected_rail_crossings.Valuate(Helper.ItemValuator);
	foreach(crash_tile, _ in this.detected_rail_crossings)
	{
		Info("Trying to fix a railway crossing that had an accident before");
		Helper.SetSign(crash_tile, "crash_tile");
		local neighbours = Tile.GetNeighbours4MainDir(crash_tile);
		neighbours.Valuate(AIRoad.AreRoadTilesConnected, crash_tile);
		neighbours.KeepValue(1);
		
		local road_tile_next_to_crossing = neighbours.Begin();

		if(neighbours.IsEmpty() ||
				!AIMap.IsValidTile(road_tile_next_to_crossing) ||
				!AITile.HasTransportType(crash_tile, AITile.TRANSPORT_ROAD) ||
				!AITile.HasTransportType(road_tile_next_to_crossing, AITile.TRANSPORT_ROAD))
		{
			this.detected_rail_crossings.RemoveValue(crash_tile);
		}

		Info("AAAAAA2");
		local bridge_result = Road.ConvertRailCrossingToBridge(crash_tile, road_tile_next_to_crossing); 
		Info("AAAAAA3");
		if(bridge_result.succeeded == true || bridge_result.permanently == true)
		{
			// Succeded to build rail crossing or failed permanently -> don't try again
			this.detected_rail_crossings.RemoveValue(crash_tile);
		}
	}
	//TimerStop("rail_crossings");TODO FIXME IMPORT
	/*
	if(AIBase.RandRange(10)==0)
	{
		detected_rail_crossings = AIList();
		Info("detected_rail_crossings cleared");
		return;
	}
	*/
}