AILog.Info("fix HasNext -> !IsEnd change");

AIBridgeList.HasNext <-
AIBridgeList_Length.HasNext <-
AICargoList.HasNext <-
AICargoList_IndustryAccepting.HasNext <-
AICargoList_IndustryProducing.HasNext <-
AIDepotList.HasNext <-
AIEngineList.HasNext <-
AIGroupList.HasNext <-
AIIndustryList.HasNext <-
AIIndustryList_CargoAccepting.HasNext <-
AIIndustryList_CargoProducing.HasNext <-
AIIndustryTypeList.HasNext <-
AIList.HasNext <-
AIRailTypeList.HasNext <-
AISignList.HasNext <-
AIStationList.HasNext <-
AIStationList_Vehicle.HasNext <-
AISubsidyList.HasNext <-
AITileList.HasNext <-
AITileList_IndustryAccepting.HasNext <-
AITileList_IndustryProducing.HasNext <-
AITileList_StationType.HasNext <-
AITownList.HasNext <-
AIVehicleList.HasNext <-
AIVehicleList_DefaultGroup.HasNext <-
AIVehicleList_Depot.HasNext <-
AIVehicleList_Group.HasNext <-
AIVehicleList_SharedOrders.HasNext <-
AIVehicleList_Station.HasNext <-
AIWaypointList.HasNext <-
AIWaypointList_Vehicle.HasNext <-
function()
{
	return !this.IsEnd(); 
	//I have better things to do than changing HasNext to IsEnd all over my code because OpenTTD devs 
	//suddenly decided that former one is somehow better (IMHO it is worse due to more complex contruction - it requires !)
}


AILog.Info("changing API");

AIMap._IsValidTile <- AIMap.IsValidTile;
AIMap.IsValidTile <- function(tile)
{
	if (tile == null) return false; //AIMap.IsValidTile(null) will return false instead of crashing
	return AIMap._IsValidTile(tile);
}

AISign._BuildSign <- AISign.BuildSign;
AISign.BuildSign <- function(tile, text)
{
	local test = AIExecMode(); //allow sign construction in test mode
	text+=""; //allow AISign.BuildSign(tile, 42)
	local returned = AISign._BuildSign(tile, text);
	if (AIError.GetLastError() != AIError.ERR_NONE) {
		Error(AIError.GetLastErrorString() + " - SIGN FAILED.");
		Error("Requested text: <" + text + "> on tile " + tile + ".");
		if (AIError.GetLastError() == AIError.ERR_PRECONDITION_STRING_TOO_LONG) {
			Error("Text " + text.len() + " characters long, maximum is 31");
		}
		if (!AIMap.IsValidTile(tile)) {
			Error("Tile invalid");
		}
	}
	return returned;
} 

AISign._RemoveSign <- AISign.RemoveSign;
AISign.RemoveSign <- function(id)
{
	local test = AIExecMode(); //allow sign destruction in test mode
	local returned = AISign._RemoveSign(id);
}

AIEngine._GetMaximumOrderDistance <- AIEngine.GetMaximumOrderDistance;
AIEngine.GetMaximumOrderDistance <- function(engine_id)
{
	local value = AIEngine._GetMaximumOrderDistance(engine_id);
	if (value == 0) value = INFINITE_DISTANCE; //it is better to get rid of 0 here, to allow KeepBelow etc in valuators
	return value;
}


AIOrder._AppendOrder <- AIOrder.AppendOrder;
AIOrder.AppendOrder <- function(vehicle_id, destination, order_flags)
{
	if (AIOrder._AppendOrder(vehicle_id, destination, order_flags)) return true;
	abort(AIError.GetLastErrorString() + " in AppendOrder");
}

AIVehicle.SetName_ <- AIVehicle.SetName
AIVehicle.SetName <- function (vehicle_id, string)
{
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		abort("Invalid vehicle " + vehicle_id);
	}
	if (AIEngine.IsWagon(AIVehicle.GetEngineType(vehicle_id))) {
		abort("naming wagon is impossible " + vehicle_id);
	}
	local i = 1;
	if (AIVehicle.SetName_(vehicle_id, string + " [" + vehicle_id + "]")) {
		return
	}
	for(;!AIVehicle.SetName_(vehicle_id, string + " #" + i + " [" + vehicle_id + "]"); i++) {
		if (AIError.GetLastError() == AIError.ERR_PRECONDITION_STRING_TOO_LONG) {
			if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
				abort("ops?")
			} else {
				AIVehicle.SetName_(vehicle_id, "PRECONDITION_FAILED");
			}
		}
	}
}

AIVehicle.CloneVehicle_ <- AIVehicle.CloneVehicle
AIVehicle.CloneVehicle <- function (depot_tile, vehicle_id, share_orders)
{
	local new_vehicle_id = AIVehicle.CloneVehicle_(depot_tile, vehicle_id, share_orders)
	if (AIVehicle.IsValidVehicle(new_vehicle_id)) {
		if (!AIEngine.IsWagon(AIVehicle.GetEngineType(vehicle_id))) {
			AIVehicle.SetName(new_vehicle_id, "copied")
		}
	}
	return new_vehicle_id
}

AIVehicle.BuildVehicle_ <- AIVehicle.BuildVehicle
AIVehicle.BuildVehicle <- function (depot_tile, engine_id)
{		
	if (!AIEngine.IsBuildable(engine_id)) {
		abort("not buildable!")
	}
	if (AITile.GetOwner(depot_tile) != AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) {
		Error(AITile.GetOwner(depot_tile) + " != " + AICompany.ResolveCompanyID(AICompany.COMPANY_SELF))
		AISign.BuildSign(depot_tile, "depot_tile")
		abort("depot tile not owned by company")
	}
	type = AIEngine.GetVehicleType(engine_id)
	if (type == AIVehicle.VT_RAIL) {
		if (!AIRail.IsRailDepotTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no rail depot")
		}
	} else if (type == AIVehicle.VT_ROAD) {
		if (!AIRoad.IsRoadDepotTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no RV depot")
		}
	} else if (type == AIVehicle.VT_WATER) {
		if (!AIMarine.IsWaterDepotTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no water depot")
		}
	} else if (type == AIVehicle.VT_AIR) {
		if (!AIAirport.IsHangarTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no hangar")
		}
	} else {
		AISign.BuildSign(depot_tile, "depot_tile")
		abort ("incorrect vehicle type (" + type + ")")
	}

	local vehicle_id = AIVehicle.BuildVehicle_(depot_tile, engine_id);
	if (AIError.GetLastError() != AIError.ERR_NONE) {
		Warning("Vehicle ("+AIEngine.GetName(engine_id)+") construction failed with "+AIError.GetLastErrorString() + "(message from modified AIVehicle::BuildVehicle)")
		if (AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) {
			do {
				AIAI_instance.SafeMaintenance();
				ProvideMoney();
				AIController.Sleep(400);
				Info("retry: BuildVehicle");
				vehicle_id = AIVehicle.BuildVehicle_(depot_tile, engine_id);
			} while(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH)
		}
		Warning(AIError.GetLastErrorString());
		if (AIError.GetLastError()==AIVehicle.ERR_VEHICLE_BUILD_DISABLED || AIError.GetLastError()==AIVehicle.ERR_VEHICLE_TOO_MANY ) {
			return AIVehicle.VEHICLE_INVALID;
		}
		if (AIError.GetLastError()==AIVehicle.ERR_VEHICLE_WRONG_DEPOT) {
			abort("depot nuked");
		}
		if (AIError.GetLastError()==AIError.ERR_PRECONDITION_FAILED) {
			AISign.BuildSign(depot_tile, "ERR_PRECONDITION_FAILED");
			abort("ERR_PRECONDITION_FAILED (before sign construction), engine: "+AIEngine.GetName(engine_id));
		}
		if (AIError.GetLastError()!=AIError.ERR_NONE) {
			abort("wtf");
		}
	}
	if (AIError.GetLastError() != AIError.ERR_NONE) {
		Info(AIError.GetLastErrorString());
	}
	Info(AIEngine.GetName(engine_id) + " constructed! ("+vehicle_id+")")
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		abort("Supposedly valid vehicle that was just constructed is invalid.");
	}
	if (!AIEngine.IsWagon(AIVehicle.GetEngineType(vehicle_id))) {
		AIVehicle.SetName(vehicle_id, "new")
	}
	return vehicle_id;
}

AIVehicle.IsOKVehicle <- function(vehicle_id)
{
	if (!AIVehicle.IsValidVehicle(vehicle_id)) {
		return false
	}
	if ((AIVehicle.GetState(vehicle_id) & AIVehicle.VS_CRASHED) ==  AIVehicle.VS_CRASHED) {
		return false
	}
	return true
}

Info("changing API finished");
