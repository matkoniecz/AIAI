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
	Info("");
	Info("Hi!");
	
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
	if(Helper.GetMailCargo==-1)	abort("mail cargo does not exist");
	if(Helper.GetPAXCargo==-1)	abort("PAX cargo does not exist");
}

function AIAI::Start()
{
	this.Starter();
	local builders = strategyGenerator();
	while(true){
		Warning("Desperation: " + desperation);
		root_tile = Tile.GetRandomTile();
		if(AIVehicleList().Count()!=0){
			local need = this.GetMinimalCost(builders);
			if(GetAvailableMoney()<need){
				Info("Waiting for more money: " + GetAvailableMoney()/1000 + "k / " + need/1000 + "k");
				this.Maintenance();
				BankruptProtector();
				Sleep(500);
				}
			}
		this.Maintenance();
		while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>Money.Inflate(500000) && this.BuildStatues()) Info("I Am Rich! Statues!");
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
	abort("Escaped Start function, it was not supposed to happen");
}

function AIAI::RunGeneralInspection()
{
			DeleteUnprofitable();
			DeleteEmptyStations();
			Autoreplace();
			this.UpgradeBridges();
}

function AIAI::UpgradeBridges()
{
	if(bridge_list==null) {
		return
	}
	for(local i = 0; i<bridge_list.len() && AICompany.GetBankBalance(AICompany.COMPANY_SELF)>Money.Inflate(500000); i++) {
		local tile = bridge_list[i]
		if(!AIBridge.IsBridgeTile(tile)) {
			continue
		}
		//AISign.BuildSign(tile, i)
		local old_bridge_type = AIBridge.GetBridgeID (tile)
		local new_bridge_type = GetMaxSpeedBridge(tile, AIBridge.GetOtherBridgeEnd(tile))
		if(AIBridge.GetMaxSpeed(new_bridge_type) > AIBridge.GetMaxSpeed(old_bridge_type)) {
			local vehicle_type = AIVehicle.VT_ROAD;
			if(AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL)) {
				vehicle_type = AIVehicle.VT_RAIL;
				AIRail.SetCurrentRailType(AIRail.GetRailType(tile))
			}
			if(!AIBridge.BuildBridge ( vehicle_type, new_bridge_type, tile, AIBridge.GetOtherBridgeEnd(tile))) {
				Error(AIError.GetLastErrorString() + " - unable to upgrade bridge")
			}
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
				return true;
				}
			}
		}
	}
return false;
}

function AIAI::GetMinimalCost(builders)
{
local cost = 10000000000;
			Info(cost);
for(local i = 0; i<builders.len(); i++)
	{
	if(builders[i] != null){
		if(builders[i].IsAllowed()){
			if(builders[i].GetCost() < cost){
				cost = builders[i].GetCost();
				Info(cost);
				}
			}
		}
	}
if(cost < Money.Inflate(100000)) cost = Money.Inflate(100000);
			Info(cost);
return cost;
}

function AIAI::SignMenagement()
	{
	//Info("SignMenagement")
	if(AIAI.GetSetting("clear_signs"))
		{
		Helper.ClearAllSigns();
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
if(AIVehicle.GetName(vehicle_id) == "stupid #1"){Error("detected"); AIController.Sleep(50);}

if(IsForSell(vehicle_id)) return false;

local tile_1 = GetLoadStationLocation(vehicle_id);
local tile_2 = GetUnloadStationLocation(vehicle_id);
local depot_location = GetDepotLocation(vehicle_id);

if(!AIOrder.UnshareOrders(vehicle_id))
	{
	abort("WTF? Unshare impossible? "+AIVehicle.GetName(vehicle_id));
	}

if(!AIOrder.AppendOrder(vehicle_id, tile_1, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY))
	{
	abort("WTF? AppendOrder impossible? "+AIVehicle.GetName(vehicle_id));
	}
if(!AIOrder.AppendOrder(vehicle_id, tile_2, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD))
	{
	abort("WTF? AppendOrder impossible? "+AIVehicle.GetName(vehicle_id))
	}
if(!AIOrder.AppendOrder (vehicle_id, depot_location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_STOP_IN_DEPOT)) //trains are not replaced by autoreplace! TODO
	{
	abort("WTF? AppendOrder impossible? "+AIVehicle.GetName(vehicle_id));
	}
AIOrder.SkipToOrder(vehicle_id, 1);
AIVehicle.SetName(vehicle_id, "for sell!" + why);
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
if(IsForSell(vehicle_id) == true) return false;
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck2 " + vehicle_id);
AIVehicle.SetName(vehicle_id, "sell!" + why);
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck3 " + vehicle_id);
if(!AIVehicle.SendVehicleToDepot(vehicle_id)) 
	{
	Info("failed to sell vehicle! "+AIError.GetLastErrorString());
	return false;
	}
if(!AIVehicle.IsValidVehicle(vehicle_id)) abort("Invalid vehicle, aftercheck4 " + vehicle_id);
AIVehicle.SetName(vehicle_id, "for sell " + why);
return true;
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
			   if(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0) BorrowOnePieceOfLoan();
			   this.BankruptProtector();
			   }
			else {
				Warning("Competitor is in trouble!");
				}
			}
		else if(ev_type == AIEvent.ET_ROAD_RECONSTRUCTION ){
			event = AIEventRoadReconstruction.Convert(event);
			local town = event.GetTownID();
			local company = event.GetCompanyID();
			Info("Road reconstruction at " + AITown.GetName(town) + " caused by " + AICompany.GetName(company));
			/* TODO: Handle it. */
			}
		else if(ev_type == AIEvent.ET_EXCLUSIVE_TRANSPORT_RIGHTS ){
			event = AIEventExclusiveTransportRights.Convert(event);
			local town = event.GetTownID();
			local company = event.GetCompanyID();
			Info("Exclusive rights at " + AITown.GetName(town) + " bought by " + AICompany.GetName(company));
			/* TODO: Handle it. */
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

function AIAI::BuildVehicle(depot_tile, engine_id)
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
		if(!AIRail.IsRailDepotTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no rail depot")
		}
	} else if (type == AIVehicle.VT_ROAD) {
		if(!AIRoad.IsRoadDepotTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no RV depot")
		}
	} else if (type == AIVehicle.VT_WATER) {
		if(!AIMarine.IsWaterDepotTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no water depot")
		}
	} else if (type == AIVehicle.VT_AIR) {
		if(!AIAirport.IsHangarTile(depot_tile)) {
			AISign.BuildSign(depot_tile, "depot_tile")
			abort ("no hangar")
		}
	} else {
		AISign.BuildSign(depot_tile, "depot_tile")
		abort ("incorrect vehicle type (" + type + ")")
	}

	//Info("BuildVehicle ("+AIEngine.GetName(engine_id)+")");
	local newengineId = AIVehicle.BuildVehicle(depot_tile, engine_id);
	if(AIError.GetLastError() != AIError.ERR_NONE) {
		Warning("Vehicle ("+AIEngine.GetName(engine_id)+") construction failed with "+AIError.GetLastErrorString() + "(message from AIAI::BuildVehicle)")
		if(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH) {
			do {
				rodzic.SafeMaintenance();
				ProvideMoney();
				AIController.Sleep(400);
				Info("retry: BuildVehicle");
				newengineId = AIVehicle.BuildVehicle(depot_tile, engine_id);
			} while(AIError.GetLastError()==AIError.ERR_NOT_ENOUGH_CASH)
		}
		Warning(AIError.GetLastErrorString());
		if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_BUILD_DISABLED || AIError.GetLastError()==AIVehicle.ERR_VEHICLE_TOO_MANY ){
			return AIVehicle.VEHICLE_INVALID;
		}
		if(AIError.GetLastError()==AIVehicle.ERR_VEHICLE_WRONG_DEPOT) {
			abort("depot nuked");
		}
		if(AIError.GetLastError()==AIError.ERR_PRECONDITION_FAILED) {
			AISign.BuildSign(depot_tile, "ERR_PRECONDITION_FAILED");
			abort("ERR_PRECONDITION_FAILED (before sign construction), engine: "+AIEngine.GetName(engine_id));
		}
		if(AIError.GetLastError()!=AIError.ERR_NONE) {
			abort("wtf");
		}
	}
	if(AIError.GetLastError() != AIError.ERR_NONE) {
		Info(AIError.GetLastErrorString());
	}
	Info(AIEngine.GetName(engine_id) + " constructed! ("+newengineId+")")
	if(!AIVehicle.IsValidVehicle(newengineId)) {
		abort("!!!!!!!!!!!!!!!");
	}
	return newengineId;
}

function GetMaxSpeedBridge(start, end)
{
local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(start, end) + 1);
bridge_list.Valuate(AIBridge.GetMaxSpeed);
bridge_list.Sort(AIList.SORT_BY_VALUE, false);
return bridge_list.Begin()
}

function AIAI::BuildBridge(vehicle_type, start, end)
{
local bridge_type_id = GetMaxSpeedBridge(start, end);
local result = AIBridge.BuildBridge(vehicle_type, bridge_type_id, start, end);
if(result) bridge_list.append(start);
return result;
}