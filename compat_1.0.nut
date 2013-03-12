/* $Id: compat_1.0.nut 21953 2011-02-04 14:11:14Z smatz $ */
/*
 * This file is part of OpenTTD.
 * OpenTTD is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * OpenTTD is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

AILog.Info("1.0 API compatability in effect.");

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
}