class AIAI extends AIController 
{
desperation = null;
GeneralInspection = null;
root_tile = null;
station_number = null;
detected_rail_crossings = null;
loaded_game = false;
bridge_list = [];
}

require("headers.nut");

function AIAI::Starter()
{
	Info("AIAI loaded!");
	NewLine();
	Info("Hi!");
	
	//PaintMapWithHillData();
	Name();
	HQ();
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")!= 0) AICompany.SetAutoRenewStatus(true);
	else AICompany.SetAutoRenewStatus(false);
	AICompany.SetAutoRenewMonths(0);
	AICompany.SetAutoRenewMoney(100000);
	detected_rail_crossings=AIList()

	if(!loaded_game){
		desperation = 0;
		GeneralInspection = GetDate()-12;
		station_number = 1
		}
	else{
		}
}

function AIAI::Start()
{
	this.Starter();
	local builders = strategyGenerator();
	while(true){
		Warning("Desperation: " + desperation);
		root_tile = RandomTile();
		if(AIVehicleList().Count()!=0){
			local need = Money.Inflate(100000);
			if(GetAvailableMoney()<need){
				Info("Waiting for more money: " + GetAvailableMoney()/1000 + "k / " + need/1000 + "k");
				while(AICompany.SetLoanAmount(AICompany.GetLoanAmount() - AICompany.GetLoanInterval()));
				this.Maintenance();
				BankruptProtector();
				Sleep(500);
				}
			}
		this.Maintenance();
		while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>Money.Inflate(500000) && this.Statue()) Info("I Am Rich! Statues!");
		this.InformationCenter(builders);
		if(this.TryEverything(builders)){
			desperation = 0;
			}
		else{
			Info("Nothing to do!");
			Sleep(100);
			desperation++;
			continue;
			}
		Info(GetDate()-GeneralInspection+" month from general check")
		if((GetDate()-GeneralInspection)>=6){ //6 months
			this.RunGeneralInspection();
			this.GeneralInspection = GetDate();
			}
		Info("===================================");
		}
}

function AIAI::RunGeneralInspection()
{
			this.DeleteUnprofitable();
			DeleteEmptyStations();
			Autoreplace();
			this.UpgradeBridges();
}

function AIAI::UpgradeBridges()
{
		if(bridge_list==null)return;
		for(local i = 0; i<bridge_list.len() && AICompany.GetBankBalance(AICompany.COMPANY_SELF)>Money.Inflate(500000); i++)
			{
			local tile = bridge_list[i];
			if(!AIBridge.IsBridgeTile(tile))continue;
			//AISign.BuildSign(tile, i);
			local old_bridge_type = AIBridge.GetBridgeID (tile);
			local new_bridge_type = AIAI.GetMaxSpeedBridge(tile, AIBridge.GetOtherBridgeEnd(tile));
			if( AIBridge.GetMaxSpeed(new_bridge_type) > AIBridge.GetMaxSpeed(old_bridge_type) )
				{
				local vehicle_type = AIVehicle.VT_ROAD;
				if( AITile.HasTransportType( tile, AITile.TRANSPORT_RAIL )) 
					{
					vehicle_type = AIVehicle.VT_RAIL;
					AIRail.SetCurrentRailType(AIRail.GetRailType( tile ));
					}
				if(!AIBridge.BuildBridge ( vehicle_type, new_bridge_type, tile, AIBridge.GetOtherBridgeEnd(tile)))
					Error(AIError.GetLastErrorString() + " - unable to upgrade bridge")
				}
			}
}
function AIAI::InformationCenter(builders)
{
	for(local i = 0; i<builders.len(); i++)
		{
		if(builders[i] != null)
		builders[i].SetDesperation(desperation);
		}
}

function AIAI::TryEverything(builders)
{
for(local i = 0; i<builders.len(); i++)
	{
	if(builders[i] != null){
		if(builders[i].Possible()){
			if(builders[i].Go()){
				RepayLoan();
				return true;
				}
			RepayLoan();
			}
		}
	}
return false;
}

function AIAI::Statue()
{
	local veh_list = AIVehicleList();
	if(veh_list.Count()==0) return false;

	veh_list.Valuate(AIBase.RandItem);
	veh_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	for (local veh = veh_list.Begin(); veh_list.HasNext(); veh = veh_list.Next()){
		for(local i=0; i<AIOrder.GetOrderCount(veh); i++){
			local location = AIOrder.GetOrderDestination(veh, i);
			if(AITile.IsStationTile(location)){
				if((AIOrder.GetOrderFlags(veh, i) & AIOrder.OF_NO_LOAD) !=AIOrder.OF_NO_LOAD){
					local station = AIStation.GetStationID(location);
					local suma = 0;
					if(AIVehicle.GetVehicleType(veh)==AIVehicle.VT_RAIL || AICompany.GetBankBalance(AICompany.COMPANY_SELF)>AICompany.GetMaxLoanAmount() || desperation>30){
						if(AITown.PerformTownAction(AITile.GetClosestTown(location), AITown.TOWN_ACTION_BUILD_STATUE)){
							Info("Statue for " + AIVehicle.GetName(veh));
							return true;
							}
						else{
							if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) return false;
							}
						}
					}
				}
			}
		}
	Info("Statue construction failed");
	return false;
}

function AIAI::ClearSigns()
{
	local sign_list = AISignList();
	for (local x = sign_list.Begin(); sign_list.HasNext(); x = sign_list.Next()) AISign.RemoveSign(x);
	AIAI.ContactInfo();
}

function AIAI::SignMenagement()
	{
	//Info("SignMenagement")
	if(AIAI.GetSetting("clear_signs"))
		{
		AIAI.ClearSigns();
		}
	
	if(AIAI.GetSetting("debug_signs_for_airports_load"))
		{
		local list = AIStationList(AIStation.STATION_AIRPORT);
		for (local x = list.Begin(); list.HasNext(); x = list.Next()) 
			{	
			AirBuilder(0, this).IsItPossibleToAddBurden(x);
			}
		}
	}

function BankruptProtector()
{
if(AIVehicleList().Count()==0) return;
if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<AICompany.GetLoanInterval()*2)
{
AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
	{
	if(AIBase.RandRange(10)==1)Error("We need bailout!");
	else Error("We need money!");
	while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0)
		{
		if(AICompany.GetLoanAmount()==AICompany.GetMaxLoanAmount())
			{
			Error("We are too big to fail! Remember, we employ " + (AIVehicleList().Count()*7+AIStationList(AIStation.STATION_ANY).Count()*3+23) + " people!");
			DoomsdayMachine();
			Sleep(1000);
			}
		AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
		}
	Info("End of financial problems!");
	}
}	   
}


function IsCargoLoadedOnThisStation(station_id, cargo_id)
	{
	local vehicle_list=AIVehicleList_Station(station_id);
	if(vehicle_list.Count()!=0)
		if(AIStation.GetStationID(GetLoadStationLocation(vehicle_list.Begin()))==station_id)
			if(AIVehicle.GetCapacity(vehicle_list.Begin(), cargo_id)!=0)
				return true;
	return false;
	}

function AIAI::GetDate()
{
local date=AIDate.GetCurrentDate ();
return AIDate.GetYear(date)*12 + AIDate.GetMonth(date);
}

function AIAI::Save()
{
  local table = {
	desperation = this.desperation
	GeneralInspection = this.GeneralInspection
	BridgeList = this.bridge_list
	station_number = this.station_number
				};
  return table;
}

function AIAI::Load(version, data)
{
  if (data.rawin("desperation")) 
  if (data.rawin("GeneralInspection")) 
  if (data.rawin("BridgeList")) 
  if (data.rawin("station_number")) 
  {
    this.desperation = data.rawget("desperation")
    this.GeneralInspection = data.rawget("GeneralInspection")
	this.bridge_list =  data.rawget("BridgeList")
	this.loaded_game = true
	this.station_number = data.rawget("station_number")
	//fix broken savegames
	if(this.desperation == null){
		this.desperation = 0
		Error("Broken savegame, used default data for desperation")
		}
	if(this.GeneralInspection == null){
		this.GeneralInspection = GetDate()-12
		Error("Broken savegame, used default data for GeneralInspection")
		}
	if(this.station_number == null){
		this.station_number = 1
		Error("Broken savegame, used default data for station_number")
		}

	return;
  }
  abort("unable to load");
 }

function AIAI::gentleSellVehicle(vehicle_id, why)
{
local tile_1 = GetLoadStationLocation(vehicle_id);
local tile_2 = GetUnloadStationLocation(vehicle_id);
if(IsForSell(vehicle_id)) return false;
Info("ORAR");
SetNameOfVehicle(vehicle_id, "for sell!" + why);
local depot_location = GetDepotLocation(vehicle_id);
if(!AIOrder.UnshareOrders(vehicle_id))
	{
	abort("WTF? Unshare impossible? "+AIVehicle.GetName(vehicle_id));
	}

if(!AIOrder.AppendOrder(vehicle_id, tile_1, AIOrder.OF_FULL_LOAD_ANY))
	{
	abort("WTF? AppendOrder impossible? "+AIVehicle.GetName(vehicle_id));
	}
if(!AIOrder.AppendOrder(vehicle_id, tile_2, AIOrder.OF_NO_LOAD))
	{
	abort("WTF? AppendOrder impossible? "+AIVehicle.GetName(vehicle_id))
	}
if(!AIOrder.AppendOrder (vehicle_id, depot_location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_STOP_IN_DEPOT)) //trains are not replaced by autoreplace! TODO
	{
	abort("WTF? AppendOrder impossible? "+AIVehicle.GetName(vehicle_id));
	}
AIOrder.SkipToOrder(vehicle_id, 1);
}

function AIAI::sellVehicle(vehicle_id, why)
{
if(!AIVehicle.IsValidVehicle(vehicle_id)) 
	{
	Error("Invalid vehicle " + vehicle_id);
	return true;
	}
local location = AIVehicle.GetLocation(vehicle_id)
if(AIVehicle.GetState(vehicle_id) == AIVehicle.VS_CRASHED) return true;
local state = AIVehicle.GetState(vehicle_id)
local state_maybe_crashed = AIVehicle.GetState(vehicle_id) & AIVehicle.VS_CRASHED
local state_crashed = AIVehicle.VS_CRASHED
local state_crashed_and_broken = AIVehicle.VS_CRASHED | AIVehicle.VS_BROKEN 

if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck1 " + vehicle_id);
if(IsForSell(vehicle_id)==true) return false;
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck2 " + vehicle_id);
SetNameOfVehicle(vehicle_id, "sell!" + why);
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck3 " + vehicle_id);
if(!AIVehicle.SendVehicleToDepot(vehicle_id)) 
	{
	Info("failed to sell vehicle! "+AIError.GetLastErrorString());
	return false;
	}
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck4 " + vehicle_id);
SetNameOfVehicle(vehicle_id, "for sell " + why);
return true;
}

function VehicleCounter(station)
{
return AIVehicleList_Station(station).Count();
}

function AIAI::DeleteEmptyStations()
{
local list;
list = AIStationList(AIStation.STATION_TRUCK_STOP);
list.Valuate(VehicleCounter);
list.KeepValue(0);
for (local spam = list.Begin(); list.HasNext(); spam = list.Next()) AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));

list = AIStationList(AIStation.STATION_BUS_STOP);
list.Valuate(VehicleCounter);
list.KeepValue(0);
for (local spam = list.Begin(); list.HasNext(); spam = list.Next()) AIRoad.RemoveRoadStation(AIBaseStation.GetLocation(spam));

list = AIStationList(AIStation.STATION_TRAIN); //TODO: remove also tracks
list.Valuate(VehicleCounter);
list.KeepValue(0);
for (local spam = list.Begin(); list.HasNext(); spam = list.Next()) AITile.DemolishTile(AIBaseStation.GetLocation(spam));
}

function AIAI::DeleteUnprofitable()
{
	local vehicle_list = AIVehicleList();

   	vehicle_list.Valuate(IsForSell);
	vehicle_list.KeepValue(0);

   	vehicle_list.Valuate(AIVehicle.GetAge);
	vehicle_list.KeepAboveValue(800);

   	vehicle_list.Valuate(AIVehicle.GetProfitThisYear);
	vehicle_list.KeepBelowValue(0);
   	vehicle_list.Valuate(AIVehicle.GetProfitLastYear);
	vehicle_list.KeepBelowValue(0);

	Info(vehicle_list.Count() + " vehicle(s) should be sold because are unprofitable");
   	
	local counter = 0;
	
	for (local vehicle_id = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle_id = vehicle_list.Next()) 
	   {
	   if(AIVehicle.GetVehicleType(vehicle_id)!=AIVehicle.VT_RAIL || (AIVehicleList_Station(AIStation.GetStationID(GetLoadStationLocation(vehicle_id)))).Count()>2)
	      {
		  if(AIVehicle.IsValidVehicle(vehicle_id)) if(AIAI.sellVehicle(vehicle_id, "unprofitable")) counter++;
		  }
	   }
	Info(counter + " vehicle(s) sold.");
}

function AIAI::BuilderMaintenance()
{
local maintenance = array(3);
maintenance[0] = RailBuilder(this, 0);
maintenance[1] = RoadBuilder(this, 0);
maintenance[2] = AirBuilder(this, 0);

for(local i = 0; i<maintenance.len(); i++)
	{
	maintenance[i].Maintenance();
	}
}

function DoomsdayMachine()
{
Info("DoomsdayMachine!");
Info("Scrap useless vehicles!");
DeleteVehiclesInDepots();
Info("BuilderMaintenance!");
this.BuilderMaintenance();
Info("Scrap useless vehicles!");
DeleteVehiclesInDepots();
Sleep(500);
Info("Scrap useless vehicles!");
DeleteVehiclesInDepots();
Sleep(500);
Info("Scrap useless vehicles!");
DeleteVehiclesInDepots();
}


function AIAI::Maintenance()
{
this.SafeMaintenance();
this.HandleEvents();
this.BankruptProtector();
DeleteVehiclesInDepots(); //must not be run during creating vehicles
}

function AIAI::SafeMaintenance()
{
this.SignMenagement();
this.HandleOldLevelCrossings();
this.BuilderMaintenance();
}

function AIAI::HandleEvents() //from CluelessPlus and simpleai
	{
	while(AIEventController.IsEventWaiting()){
		local event = AIEventController.GetNextEvent();
		if(event == null) return;
		local ev_type = event.GetEventType();
		if(ev_type == AIEvent.ET_VEHICLE_LOST){
    		Warning("Vehicle lost event detected!");
			local lost_event = AIEventVehicleLost.Convert(event);
			local lost_veh = lost_event.GetVehicleID();

			/*
			TODO - do sth with that code
			local connection = ReadConnectionFromVehicle(lost_veh);
			
			if(connection.station.len() >= 2 && connection.connection_failed != true)
			{
				Info("Try to connect the stations again");

				if(!connection.RepairRoadConnection())
					SellVehicle(lost_veh);
			}
			else
			{
				SellVehicle(lost_veh);
			}
			*/
			
		}
		else if(ev_type == AIEvent.ET_VEHICLE_CRASHED){
			Warning("Vehicle crash detected!");
			local crash_event = AIEventVehicleCrashed.Convert(event);
			local crash_reason = crash_event.GetCrashReason();
			if(crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING){
				this.HandleNewLevelCrossing(event);
				}
			}
		else if(ev_type == AIEvent.ET_AIRCRAFT_DEST_TOO_FAR){
			local order_event = AIEventAircraftDestTooFar.Convert(event);
			local airplane_id = order_event.GetVehicleID();
			abort("AIRCRAFT_DEST_TOO_FAR " + airplane_id + " " + airplane_id + " " + AIVehicle.GetName(airplane_id));
			}
		else if(ev_type == AIEvent.ET_ENGINE_PREVIEW){
			event = AIEventEnginePreview.Convert(event);
			if (event.AcceptPreview()){
				Info("New engine available from preview: " + event.GetName());
				Autoreplace();
				if(event.GetVehicleType() == AIVehicle.VT_RAIL) this.BuilderMaintenance();
				}
			}
		else if(ev_type == AIEvent.ET_ENGINE_AVAILABLE){
			event = AIEventEngineAvailable.Convert(event);
			local engine = event.GetEngineID();
			Info("New engine available: " + AIEngine.GetName(engine));
			Autoreplace();
			if(AIEngine.GetVehicleType(engine) == AIVehicle.VT_RAIL) this.BuilderMaintenance();
			}
		else if(ev_type == AIEvent.ET_COMPANY_NEW){
			event = AIEventCompanyNew.Convert(event);
			local company = event.GetCompanyID();
			Info("Welcome " + AICompany.GetName(company));
			}
		else if(ev_type == AIEvent.ET_COMPANY_IN_TROUBLE){
			event = AIEventCompanyInTrouble.Convert(event);
			local company = event.GetCompanyID();
			if (AICompany.IsMine(company)){
				Warning("Our company is in trouble!");
			   if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0) AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval());
			   this.BankruptProtector();
			   }
			else {
				Warning("Competitor is in trouble!");
				}
			}
		else if(ev_type == AIEvent.ET_INDUSTRY_OPEN){
			event = AIEventIndustryOpen.Convert(event);
			local industry = event.GetIndustryID();
			Info("New industry: " + AIIndustry.GetName(industry));
			/* TODO: Handle it. */
			}
		else if(ev_type == AIEvent.ET_INDUSTRY_CLOSE)//from simpleai
			{
			event = AIEventIndustryClose.Convert(event);
			local industry = event.GetIndustryID();
			if (AIIndustry.IsValidIndustry(industry)){
				Info("Closing industry: " + AIIndustry.GetName(industry));
				/* Handling is useless. TODO? */
				}
			}
		/*events left
		
		*/
	}
}

function IntToStrFill(int_val, num_digits) //from ClueHelper
{
	local str = int_val.tostring();
	while(str.len() < num_digits)
		{
		str = "0" + str;
		}
	return str;
}

function LoadDataFromStationNameFoundByStationId(station, delimiters)
{	
	local start_code = delimiters[0]
	local end_code = delimiters[1]
	if(!AIStation.IsValidStation(station))
		{
		abort("");
		}
	local str = AIBaseStation.GetName(station)
	local result = null;
		
	for(local i = 0; i < str.len(); ++i)
		{
		//Warning(result+" from "+str+" ["+i+"]="+str[i]);
		if(str[i]==start_code && result == null)
			{
			result=0
			}
		else if(str[i]==end_code)
			{
			//Warning(result+" from "+str);
			return result;
			}
		else if(result != null)
			{
			result=result*10+str[i]-48;
			}
		}
	return null;
}

function LoadDataFromStationName(location)
{
	local station = AIStation.GetStationID(location);
	if(!AIBaseStation.IsValidBaseStation(station))
		return null;
	return LoadDataFromStationNameFoundByStationId(station, "{}");
}

function AIAI::TrySetStationName(station_id, data, leading_number)
{
	local string;
	string = IntToStrFill(leading_number, 4)+data;
	if(AIBaseStation.GetName(station_id) == string) return true;
	return AIBaseStation.SetName(station_id, string)
}

function AIAI::SetStationName(location, data)
{
	local station_id = AIStation.GetStationID(location);
	local current_number = LoadDataFromStationNameFoundByStationId(station_id, "0{");
	if(current_number != null)
		if(TrySetStationName(station_id, data, current_number))
			return;
	
	if(!AIBaseStation.IsValidBaseStation(station_id))
		abort("no station found");

	while(!TrySetStationName(station_id, data, station_number))station_number++;
	station_number++;
}

function AIAI::SetWaypointName(network, location)
{
	local waypoint = AIWaypoint.GetWaypointID(location);
	if(!AIBaseStation.IsValidBaseStation(waypoint))
		return;
	local string;
	local i=1;
	do
		{
		string = "{"+network+"}  #"+IntToStrFill(i, 5);
		i++;
		Error(AIError.GetLastErrorString());
		}
	while(!AIBaseStation.SetName(waypoint, string))
}

function PaintMapWithHillData()
{
local tile_source = AIMap.GetTileIndex(1, 1)
local rectangle_size = 5;
for(local x_cluster=0; x_cluster*rectangle_size+1<AIMap.GetMapSizeX(); x_cluster++)
	for(local y_cluster=0; y_cluster*rectangle_size+1<AIMap.GetMapSizeY(); y_cluster++)
		{
		local count=0;
		for(local x=0; x<rectangle_size; x++)
			for(local y=0; y<rectangle_size; y++)
				{
				local tile = AIMap.GetTileIndex(x_cluster*rectangle_size+x, y_cluster*rectangle_size+y);
				local slope = AITile.GetSlope(tile);
				count += AITile.IsSteepSlope(slope)? 2 : 0;
				count += AITile.IsHalftileSlope(slope)? 1 : 0;
				count += AITile.IsBuildable(tile)? 0 : 5;
				}
		for(local x=0; x<rectangle_size; x++)
			for(local y=0; y<rectangle_size; y++)
				{
				local tile = AIMap.GetTileIndex(x_cluster*rectangle_size+x+1, y_cluster*rectangle_size+y+1);
				//AISign.BuildSign(tile, "" + Sqrt(AIOrder.GetOrderDistance(AIVehicle.VT_AIR , tile_source, tile)) + " " + AIOrder.GetOrderDistance(AIVehicle.VT_ROAD , tile_source, tile) + " " + AIOrder.GetOrderDistance(AIVehicle.VT_RAIL , tile_source, tile) + " " + AIOrder.GetOrderDistance(AIVehicle.VT_WATER  , tile_source, tile))
				AISign.BuildSign(tile, count+"");
				}
		}
}

function AIAI::BuildVehicle(depot_tile, engine_id)
{		
	if(!AIEngine.IsBuildable(engine_id))
		abort("not buildable!");
		
	//Info("BuildVehicle ("+AIEngine.GetName(engine_id)+")");
	local newengineId = AIVehicle.BuildVehicle(depot_tile, engine_id);
	if(AIError.GetLastError()!=AIError.ERR_NONE)
		{
		Warning("Vehicle ("+AIEngine.GetName(engine_id)+") construction failed with "+AIError.GetLastErrorString() + "(message from AIAI::BuildVehicle)")
		if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH)
			{
			do {
				rodzic.SafeMaintenance();
				ProvideMoney();
				AIController.Sleep(400);
				Info("retry: BuildVehicle");
				newengineId = AIVehicle.BuildVehicle(depot_tile, engine_id);
			} while(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH)
			}
		Warning(AIError.GetLastErrorString());
		if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_BUILD_DISABLED || AIError.GetLastError()==AIVehicle.ERR_VEHICLE_TOO_MANY )
			{
			return AIVehicle.VEHICLE_INVALID;
			}
		if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_WRONG_DEPOT) abort("depot nuked");
		if(AIError.GetLastError()==AIError.ERR_PRECONDITION_FAILED) 
			{
			AISign.BuildSign(depot_tile, "ERR_PRECONDITION_FAILED");
			abort("ERR_PRECONDITION_FAILED (before sign construction), engine: "+AIEngine.GetName(engine_id));
			}
		if(AIError.GetLastError()!=AIError.ERR_NONE) abort("wtf");
		if(!AIVehicle.IsValidVehicle(newengineId)) abort("!!!");
		}
	Info(AIEngine.GetName(engine_id) + " constructed! ("+newengineId+")")
	if(!AIVehicle.IsValidVehicle(newengineId)) abort("!!!!!!!!!!!!!!!");
	return newengineId;
}

function AIAI::GetMaxSpeedBridge(start, end)
{
local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(start, end) + 1);
bridge_list.Valuate(AIBridge.GetMaxSpeed);
bridge_list.Sort(AIList.SORT_BY_VALUE, false);
return bridge_list.Begin()
}

function AIAI::BuildBridge(vehicle_type, start, end)
{
local bridge_type_id = this.GetMaxSpeedBridge(start, end);
local result = AIBridge.BuildBridge(vehicle_type, bridge_type_id, start, end);
if(result) bridge_list.append(start);
return result;
}