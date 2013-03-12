/* $Id: compat_1.0.nut 21953 2011-02-04 14:11:14Z smatz $ */
/*
 * This file is part of OpenTTD.
 * OpenTTD is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * OpenTTD is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

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
	if(tile == null) return false; //AIMap.IsValidTile(null) will return false instead of crashing
	return AIMap._IsValidTile(tile);
}

AISign._BuildSign <- AISign.BuildSign;
AISign.BuildSign <- function(tile, text)
{
	local test = AIExecMode(); //allow sign construction in test mode
	text+=""; //allow AISign.BuildSign(tile, 42)
	local returned = AISign._BuildSign(tile, text);
	if(AIError.GetLastError()!=AIError.ERR_NONE)
		{
		Error(AIError.GetLastErrorString() + " - SIGN FAILED" );
		if(!AIMap.IsValidTile(tile))Error("Tile invalid");
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
	if(value == 0) value = INFINITE_DISTANCE; //it is better to get rid of 0 here, to allow KeepBelow etc in valuators
	return value;
}


AIOrder._AppendOrder <- AIOrder.AppendOrder;
AIOrder.AppendOrder <- function(vehicle_id, destination, order_flags)
{
	if(AIOrder._AppendOrder(vehicle_id, destination, order_flags)) return true;
	Error(AIError.GetLastErrorString() + "in AppendOrder") //assertion
	local boom  = 0/0;
}

AIVehicleList_Station_ <- AIVehicleList_Station
AIVehicleList_Station <- function(station_id)
{
	local vehicle_list = AIVehicleList_Station_(station_id)
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()){
		if(AIVehicle.GetState(vehicle_id) == AIVehicle.VS_CRASHED) Error("AIVehicleList_Station contains crashed vehicle: "+AIVehicle.GetName(vehicle_id))
		}
	if(vehicle_list.Count()==0) Error("Empty AIVehicleList_Station");
	return vehicle_list;
}

AILog.Info("changing API finished");
