g_no_car_goal <- null;

class AIAI extends AIController 
{
	desperation = null;
	GeneralInspection = null;
	root_tile = null;
	station_number = null;
	detected_rail_crossings = null;
	loaded_game = false;
	bridge_list = [];
	library = null;
}

require("headers.nut");

function AIAI::Starter()
{
	Info("AIAI loaded!");
	Info("");
	Info("Hi!");
	
	NameCompany();
	if(!AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) {
		Info("Building company HQ...")
		if(!Helper.BuildCompanyHQ()) {
			Info("No possible HQ location found");
		}
	}
	this.ShowContactInfoOnTheMap();
	if(AIGameSettings.GetValue("difficulty.vehicle_breakdowns")!= 0) {
		AICompany.SetAutoRenewStatus(true);
	} else {
		AICompany.SetAutoRenewStatus(false);
	}
	AICompany.SetAutoRenewMonths(0);
	AICompany.SetAutoRenewMoney(100000);
	detected_rail_crossings = AIList()

	if(!loaded_game) {
		desperation = 0;
		GeneralInspection = GetDate() - 12;
		station_number = 1
	} else {
	}
	if(Helper.GetMailCargo==-1) {
		abort("mail cargo does not exist");
	}
	if(Helper.GetPAXCargo==-1) {
		abort("PAX cargo does not exist");
	}
}

function AIAI::CommunicateWithGS()
{
	if(AIController.GetSetting("scp_enabled")) {
		if (this.library == null) {
			this.library = SCPLib("fake_data", "fake_data");
			this.library.SCPLogging_Info(true);
			this.library.SCPLogging_Error(true);
			g_no_car_goal = SCPClient_NoCarGoal(this.library);
		}
	}
	if(g_no_car_goal == null) {
		g_no_car_goal = SCPClient_NoCarGoal(this.library);
	}
	if(this.library != null) {
		this.library.SCPLogging_Info(Info);
		for(local j = 0; j < 5 && this.library.Check(); j++){}
	}
	if(AIController.GetSetting("scp_enabled")) {
		if(g_no_car_goal.IsNoCarGoalGame()){
			Info("It is a NoCarGoal game.");
		} else {
			Info("No Game Script detected.");
		}
	}
}

function AIAI::Start()
{
	this.Starter();
	local builders = strategyGenerator();
	for(local i = 1; true; i++) {
		local waiting_for_money = false;
		Warning("Desperation: " + desperation);
		this.CommunicateWithGS();
		root_tile = Tile.GetRandomTile();
		if(AIVehicleList().Count() != 0) {
			local need = this.GetMinimalCost(builders);
			if(GetAvailableMoney() < need) {
				Info("Waiting for more money: " + GetAvailableMoney()/1000 + "k / " + need/1000 + "k");
				this.Maintenance();
				BankruptProtector();
				Sleep(500);
				waiting_for_money = true;
			}
		}
		this.Maintenance();
		while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)>Money.Inflate(500000) && this.BuildStatues()) {
			Info("I Am Rich! Statues!");
		}
		this.InformationCenter(builders);
		if(this.TryEverything(builders)) {
			desperation /= 10;
		} else if (!waiting_for_money) {
			Info("Nothing to do!");
			Sleep(100);
			desperation++;
			continue;
		}
		local time = GetDate()-GeneralInspection;
		if(time == 1) {
			Info("1 month from general check");
		} else {
			Info(time + " months from general check");
		}
		if(time >= 6){ //6 months
			this.RunGeneralInspection();
			this.GeneralInspection = GetDate();
		}
		Info("==================iteration number " + i + " of the main loop is now finished=================");
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
	for(local i = 0; i<builders.len(); i++) {
		if(builders[i] != null) {
			builders[i].SetDesperation(desperation);
		}
	}
}

function AIAI::TryEverything(builders)
{
	for(local i = 0; i<builders.len(); i++) {
		if(builders[i] != null) {
			if(builders[i].Possible()) {
				if(builders[i].Go()) {
					return true;
				}
			}
		}
	}
	return false;
}

function AIAI::GetMinimalCost(builders)
{
	local cost = 1000000000; //TODO INFINITE fails
	for(local i = 0; i<builders.len(); i++) {
		if(builders[i] != null) {
			if(builders[i].IsAllowed()) {
				if(builders[i].GetCost() < cost) {
					cost = builders[i].GetCost();
				}
			}
		}
	}
	if(cost < Money.Inflate(100000)) {
		cost = Money.Inflate(100000);
	}
	return cost;
}

function AIAI::SignMenagement()
{
	if(AIAI.GetSetting("clear_signs")) {
		Helper.ClearAllSigns();
	}
	if(AIAI.GetSetting("debug_signs_for_airports_load")) {
		local list = AIStationList(AIStation.STATION_AIRPORT);
		for (local x = list.Begin(); list.HasNext(); x = list.Next()) {
			AirBuilder(0, this).IsItPossibleToAddBurden(x);
		}
	}
}


function AIAI::GetDate()
{
	local date=AIDate.GetCurrentDate();
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
	if (data.rawin("desperation") && data.rawin("GeneralInspection") && data.rawin("BridgeList") && data.rawin("station_number")) {
		this.loaded_game = true;
		this.desperation = data.rawget("desperation");
		this.GeneralInspection = data.rawget("GeneralInspection");
		this.bridge_list =  data.rawget("BridgeList");
		this.station_number = data.rawget("station_number");
		//fix broken savegames
		if(this.desperation == null) {
			this.desperation = 0;
			Error("Broken savegame, used default data for desperation");
		}
		if(this.GeneralInspection == null) {
			this.GeneralInspection = GetDate()-12;
			Error("Broken savegame, used default data for GeneralInspection");
		}
		if(this.station_number == null) {
			this.station_number = 1;
			Error("Broken savegame, used default data for station_number");
		}
		return;
	}
	if(AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
		abort("unable to load");
	} else {
		Error("unable to load properly, discrding all provided data");
	}
}

function AIAI::gentleSellVehicle(vehicle_id, why)
{
	if(IsForSell(vehicle_id) != false) {
		return false;
	}
	local tile_1 = GetLoadStationLocation(vehicle_id);
	local tile_2 = GetUnloadStationLocation(vehicle_id);
	local depot_location = GetDepotLocation(vehicle_id);
	if (tile_1 == null || tile_2 == null || depot_location == null) {
		return false
	}

	if(!AIOrder.UnshareOrders(vehicle_id)) {
		abort("WTF? Unshare impossible? "+AIVehicle.GetName(vehicle_id));
	}

	//note: AIAI is using modified AIOrder.AppendOrder that will trigger assertion on failure
	AIOrder.AppendOrder(vehicle_id, tile_1, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY);
	AIOrder.AppendOrder(vehicle_id, tile_2, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_NO_LOAD);
	AIOrder.AppendOrder(vehicle_id, depot_location, AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_STOP_IN_DEPOT);
	if(AIOrder.ResolveOrderPosition (vehicle_id, AIOrder.ORDER_CURRENT) != 1) {
		if(!AIOrder.SkipToOrder(vehicle_id, 1)) {
			abort("SkipToOrder failed");
		}
	}
	AIVehicle.SetName(vehicle_id, "for sell!" + why);
}

function AIAI::sellVehicle(vehicle_id, why)
{
	if(!AIVehicle.IsOKVehicle(vehicle_id)) {
		Error("Invalid or crashed vehicle " + vehicle_id);
		return true;
	}
	if(IsForSell(vehicle_id) != false) {
		return false;
	}
	AIVehicle.SetName(vehicle_id, "sell!" + why);
	if(!AIVehicle.SendVehicleToDepot(vehicle_id)) {
		Info("failed to sell vehicle! "+AIError.GetLastErrorString());
		return false;
	}
	AIVehicle.SetName(vehicle_id, "for sell " + why);
	return true;
}

function AIAI::BuilderMaintenance()
{
	local maintenance = array(3);
	maintenance[0] = RailBuilder(this, 0);
	maintenance[1] = RoadBuilder(this, 0);
	maintenance[2] = AirBuilder(this, 0);

	for(local i = 0; i<maintenance.len(); i++) {
		maintenance[i].Maintenance();
	}
}

function DoomsdayMachine()
{
	Info("DoomsdayMachine!");
	Info("Scrap useless vehicles!");
	Helper.SellAllVehiclesStoppedInDepots();
	Info("BuilderMaintenance!");
	this.BuilderMaintenance();
	Info("Scrap useless vehicles!");
	Helper.SellAllVehiclesStoppedInDepots();
	Sleep(500);
	Info("Scrap useless vehicles!");
	Helper.SellAllVehiclesStoppedInDepots();
	Sleep(500);
	Info("Scrap useless vehicles!");
	Helper.SellAllVehiclesStoppedInDepots();
}


function AIAI::Maintenance()
{
	this.SafeMaintenance();
	this.HandleEvents();
	this.BankruptProtector();
	Helper.SellAllVehiclesStoppedInDepots(); //must not be run during creating vehicles
}

function AIAI::SafeMaintenance()
{
	this.SignMenagement();
	this.HandleOldLevelCrossings();
	this.BuilderMaintenance();
}

function AIAI::HandleEvents() //from CluelessPlus and SimpleAI
	{
	while(AIEventController.IsEventWaiting()) {
		local event = AIEventController.GetNextEvent();
		if(event == null) {
			return;
		}
		local ev_type = event.GetEventType();
		if(ev_type == AIEvent.ET_VEHICLE_LOST) {
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
			
		} else if(ev_type == AIEvent.ET_VEHICLE_CRASHED){
			Warning("Vehicle crash detected!");
			local crash_event = AIEventVehicleCrashed.Convert(event);
			local crash_reason = crash_event.GetCrashReason();
			if(crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING){
				this.HandleNewLevelCrossing(event);
			}
		} else if(ev_type == AIEvent.ET_AIRCRAFT_DEST_TOO_FAR) {
			local order_event = AIEventAircraftDestTooFar.Convert(event);
			local airplane_id = order_event.GetVehicleID();
			abort("AIRCRAFT_DEST_TOO_FAR " + airplane_id + " " + airplane_id + " " + AIVehicle.GetName(airplane_id));
		} else if(ev_type == AIEvent.ET_ENGINE_PREVIEW) {
			event = AIEventEnginePreview.Convert(event);
			if (event.AcceptPreview()){
				Info("New engine available from preview: " + event.GetName());
				Autoreplace();
				if(event.GetVehicleType() == AIVehicle.VT_RAIL) {
					this.BuilderMaintenance();
				}
			}
		} else if(ev_type == AIEvent.ET_ENGINE_AVAILABLE) {
			event = AIEventEngineAvailable.Convert(event);
			local engine = event.GetEngineID();
			Info("New engine available: " + AIEngine.GetName(engine));
			Autoreplace();
			if(AIEngine.GetVehicleType(engine) == AIVehicle.VT_RAIL) {
				this.BuilderMaintenance();
			}
		} else if(ev_type == AIEvent.ET_COMPANY_NEW) {
			event = AIEventCompanyNew.Convert(event);
			local company = event.GetCompanyID();
			Info("Welcome " + AICompany.GetName(company));
		} else if(ev_type == AIEvent.ET_COMPANY_IN_TROUBLE) {
			event = AIEventCompanyInTrouble.Convert(event);
			local company = event.GetCompanyID();
			if (AICompany.IsMine(company)) {
				Warning("Our company is in trouble!");
				this.BankruptProtector();
			} else {
				Info("Competitor is in trouble!");
			}
		} else if (ev_type == AIEvent.ET_COMPANY_BANKRUPT) {
			event = AIEventCompanyInTrouble.Convert(event);
			local company = event.GetCompanyID();
			if (AICompany.IsMine(company)) {
				Error("Our company failed! Ops.");
				this.BankruptProtector();
			} else {
				Info("Competitor failed!");
				Info("Muhahhahahahahaha");
			}
		} else if(ev_type == AIEvent.ET_ROAD_RECONSTRUCTION ) {
			event = AIEventRoadReconstruction.Convert(event);
			local town = event.GetTownID();
			local company = event.GetCompanyID();
			Info("Road reconstruction at " + AITown.GetName(town) + " caused by " + AICompany.GetName(company));
			/* TODO: Handle it. */
		} else if(ev_type == AIEvent.ET_EXCLUSIVE_TRANSPORT_RIGHTS ) {
			event = AIEventExclusiveTransportRights.Convert(event);
			local town = event.GetTownID();
			local company = event.GetCompanyID();
			Info("Exclusive rights at " + AITown.GetName(town) + " bought by " + AICompany.GetName(company));
			/* TODO: Handle it. */
		} else if(ev_type == AIEvent.ET_INDUSTRY_OPEN) {
			event = AIEventIndustryOpen.Convert(event);
			local industry = event.GetIndustryID();
			Info("New industry: " + AIIndustry.GetName(industry));
			// No need, this should be noticed in normal route finding.
		} else if(ev_type == AIEvent.ET_INDUSTRY_CLOSE) {
			event = AIEventIndustryClose.Convert(event);
			local industry = event.GetIndustryID();
			if (AIIndustry.IsValidIndustry(industry)) {
				Info("Closing industry " + AIIndustry.GetName(industry) + " at [" + AIMap.GetTileX(AIIndustry.GetLocation(industry)) + ", " + AIMap.GetTileY(AIIndustry.GetLocation(industry)) + "]");
				// Handling is useless, as it should be caught on checking existing connections. Also, it may be temporary (weird NewGrf) or fixed by another company.
			}
		} else if (ev_type == AIEvent.ET_VEHICLE_WAITING_IN_DEPOT) {
			Helper.SellAllVehiclesStoppedInDepots();
		} else if (ev_type == AIEvent.ET_DISASTER_ZEPPELINER_CRASHED) {
			//TODO
		} else if (ev_type == AIEvent.ET_DISASTER_ZEPPELINER_CLEARED) {
			//TODO
		} else if (ev_type == AIEvent.ET_TOWN_FOUNDED) {
			// No need, this should be noticed in normal route finding.
		} else if (ev_type == AIEvent.ET_ADMIN_PORT) {
			// Currently there is no support for anything related with admin port. Nor there is a any need or plan for this.
		} else if (ev_type == AIEvent.ET_WINDOW_WIDGET_CLICK) {
			// No idea what is this (undocumented in docs), but there is no planned support.
		} else if (ev_type == AIEvent.ET_GOAL_QUESTION_ANSWER) {
			// No idea what is this (undocumented in docs), but there is no planned support.
		} else if (ev_type == AIEvent.ET_ROAD_RECONSTRUCTION ) {
			//TODO
		} else if (ev_type == AIEvent.ET_SUBSIDY_OFFER) {
		} else if (ev_type == AIEvent.ET_SUBSIDY_OFFER_EXPIRED) {
		} else if (ev_type == AIEvent.ET_SUBSIDY_AWARDED) {
		} else if (ev_type == AIEvent.ET_SUBSIDY_EXPIRED) {
		} else if (ev_type == AIEvent.ET_COMPANY_ASK_MERGER) {
		} else if (ev_type == AIEvent.ET_COMPANY_MERGER) {
		} else if (ev_type == AIEvent.ET_VEHICLE_UNPROFITABLE) {
		} else if (ev_type == AIEvent.ET_STATION_FIRST_VEHICLE) {
		} else {
			Error("Unhandled event " + ev_type);
			if(AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
				abort("unhandled event");
			}
		}
	}
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
	if(result) {
		bridge_list.append(start);
	}
	return result;
}