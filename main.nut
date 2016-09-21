g_no_car_goal <- null;

class AIAI extends AIController 
{
	desperation = null;
	general_inspection = null;
	root_tile = null;
	station_number = null;
	list_of_detected_rail_crossings = null;
	is_this_a_loaded_game = false;
	is_this_a_correctly_loaded_game = false;
	potential_load_status_logged = false;
	bridge_list = [];
	library_to_communicate_with_GS = null;
}

require("headers.nut");

function AIAI::Starter() {
	if(AIVehicleList().Count()+AIStationList(AIStation.STATION_ANY).Count() > 0){
		Warning("Loading from crashed/? game.");
		is_this_a_loaded_game = true;
		MajorInfo("stealth loaded game");
	}
	Info("AIAI loaded!");
	Info("");
	Info("Hi!");
	
	NameCompany();
	if (!AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) {
		Info("Building company HQ...")
		if (!Helper.BuildCompanyHQ()) {
			Info("No possible HQ location found");
		}
	}
	if(!is_this_a_loaded_game) {
		this.ShowContactInfoOnTheMap();
	}
	if (AIGameSettings.GetValue("difficulty.vehicle_breakdowns")!= 0) {
		AICompany.SetAutoRenewStatus(true);
	} else {
		AICompany.SetAutoRenewStatus(false);
	}
	AICompany.SetAutoRenewMonths(0);
	AICompany.SetAutoRenewMoney(100000);
	list_of_detected_rail_crossings = AIList()

	if (is_this_a_loaded_game) {
		if(!potential_load_status_logged) {
			potential_load_status_logged = true;
			MajorInfo("loaded game");
		}
		//should be loaded from savegame
	}
	if(!is_this_a_correctly_loaded_game) {
		desperation = 0;
		general_inspection = GetDate() - 12;
		station_number = 1
	}
	if (Helper.GetMailCargo==-1) {
		abort("mail cargo does not exist");
	}
	if (Helper.GetPAXCargo==-1) {
		abort("PAX cargo does not exist");
	}
}

function AIAI::CommunicateWithGS() {
	if (AIController.GetSetting("scp_enabled")) {
		if (this.library_to_communicate_with_GS == null) {
			this.library_to_communicate_with_GS = SCPLib("fake_data", "fake_data");
			this.library_to_communicate_with_GS.SCPLogging_Info(true);
			this.library_to_communicate_with_GS.SCPLogging_Error(true);
			g_no_car_goal = SCPClient_NoCarGoal(this.library_to_communicate_with_GS);
		}
	}
	if (g_no_car_goal == null) {
		g_no_car_goal = SCPClient_NoCarGoal(this.library_to_communicate_with_GS);
	}
	if (this.library_to_communicate_with_GS != null) {
		this.library_to_communicate_with_GS.SCPLogging_Info(Info);
		for(local j = 0; j < 5 && this.library_to_communicate_with_GS.Check(); j++) {}
	}
	if (AIController.GetSetting("scp_enabled")) {
		if (g_no_car_goal.IsNoCarGoalGame()) {
			Info("It is a NoCarGoal game.");
		} else {
			Info("No Game Script detected.");
		}
	}
}

function AIAI::Start() {
	this.Starter();
	ConsiderGeneralInspection();
	local builders = strategyGenerator();
	for(local i = 1; true; i++) {
		local waiting_for_money = false;
		Warning("Desperation: " + desperation);
		this.CommunicateWithGS();
		root_tile = Tile.GetRandomTile();
		if (AIVehicleList().Count() != 0) {
			local need = this.GetMinimalCost(builders);
			if (GetAvailableMoney() < need) {
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
		if (this.TryEverything(builders)) {
			desperation /= 10;
		} else if (!waiting_for_money) {
			Info("Nothing to do!");
			Sleep(100);
			desperation++;
			continue;
		}
		Info("==================iteration number " + i + " of the main loop is now finished=================");
		}
	abort("Escaped Start function, it was not supposed to happen");
}

function AIAI::ConsiderGeneralInspection(){
	local time = GetDate()-general_inspection;
	if (time == 1) {
		Info("1 month from general check");
	} else {
		Info(time + " months from general check");
	}
	if (time >= 6) { //6 months
		this.Rungeneral_inspection();
		this.general_inspection = GetDate();
	}	
}

function AIAI::Rungeneral_inspection() {
	DeleteUnprofitable();
	DeleteEmptyStations();
	Autoreplace();
	this.UpgradeBridges();
}

function AIAI::UpgradeBridges() {
	if (bridge_list==null) {
		return
	}
	for(local i = 0; i<bridge_list.len() && AICompany.GetBankBalance(AICompany.COMPANY_SELF)>Money.Inflate(500000); i++) {
		local tile = bridge_list[i]
		if (!AIBridge.IsBridgeTile(tile)) {
			continue
		}
		local old_bridge_type = AIBridge.GetBridgeID (tile)
		local new_bridge_type = GetMaxSpeedBridge(tile, AIBridge.GetOtherBridgeEnd(tile))
		if (AIBridge.GetMaxSpeed(new_bridge_type) > AIBridge.GetMaxSpeed(old_bridge_type)) {
			local vehicle_type = AIVehicle.VT_ROAD;
			if (AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL)) {
				vehicle_type = AIVehicle.VT_RAIL;
				AIRail.SetCurrentRailType(AIRail.GetRailType(tile))
			}
			if (!AIBridge.BuildBridge ( vehicle_type, new_bridge_type, tile, AIBridge.GetOtherBridgeEnd(tile))) {
				Error(AIError.GetLastErrorString() + " - unable to upgrade bridge")
			}
		}
	}
}

function AIAI::InformationCenter(builders) {
	for(local i = 0; i<builders.len(); i++) {
		if (builders[i] != null) {
			builders[i].SetDesperation(desperation);
		}
	}
}

function AIAI::TryEverything(builders) {
	for(local i = 0; i<builders.len(); i++) {
		if (builders[i] != null) {
			if (builders[i].Possible()) {
				if (builders[i].Go()) {
					return true;
				}
			}
		}
	}
	return false;
}

function AIAI::GetMinimalCost(builders) {
	local cost = 1000000000; //TODO INFINITE fails
	for(local i = 0; i<builders.len(); i++) {
		if (builders[i] != null) {
			if (builders[i].IsAllowed()) {
				if (builders[i].GetCost() < cost) {
					cost = builders[i].GetCost();
				}
			}
		}
	}
	if (cost < Money.Inflate(100000)) {
		cost = Money.Inflate(100000);
	}
	return cost;
}

function AIAI::SignMenagement() {
	if (AIAI.GetSetting("clear_signs")) {
		Helper.ClearAllSigns();
	}
	if (AIAI.GetSetting("debug_signs_for_airports_load")) {
		local list = AIStationList(AIStation.STATION_AIRPORT);
		for (local x = list.Begin(); list.HasNext(); x = list.Next()) {
			AirBuilder(0, this).IsItPossibleToAddBurden(x);
		}
	}
}


function AIAI::GetDate() {
	local date=AIDate.GetCurrentDate();
	return AIDate.GetYear(date)*12 + AIDate.GetMonth(date);
}

function AIAI::Save() {
	local table = {
		desperation = this.desperation
		general_inspection = this.general_inspection
		BridgeList = this.bridge_list
		station_number = this.station_number
	};
	return table;
}

function AIAI::Load(version, data) {
	Info("Loading from save.");
	this.is_this_a_loaded_game = true;
	if (data.rawin("desperation") && data.rawin("general_inspection") && data.rawin("BridgeList") && data.rawin("station_number")) {
		this.is_this_a_correctly_loaded_game = true;
		this.desperation = data.rawget("desperation");
		this.general_inspection = data.rawget("general_inspection");
		this.bridge_list =  data.rawget("BridgeList");
		this.station_number = data.rawget("station_number");
		//fix broken savegames
		if (this.desperation == null) {
			this.desperation = 0;
			Error("Broken savegame, used default data for desperation");
		}
		if (this.general_inspection == null) {
			this.general_inspection = GetDate()-12;
			Error("Broken savegame, used default data for general_inspection");
		}
		if (this.station_number == null) {
			this.station_number = 1;
			Error("Broken savegame, used default data for station_number");
		}
		return;
	}
	if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
		abort("unable to load");
	} else {
		Error("unable to load properly, discrding all provided data");
	}
}

function AIAI::BuilderMaintenance() {
	local maintenance = array(3);
	maintenance[0] = RailBuilder(this, 0);
	maintenance[1] = RoadBuilder(this, 0);
	maintenance[2] = AirBuilder(this, 0);

	for(local i = 0; i<maintenance.len(); i++) {
		maintenance[i].Maintenance();
	}
}

function DoomsdayMachine() {
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


function AIAI::Maintenance() {
	this.SafeMaintenance();
	this.HandleEvents();
	this.BankruptProtector();
	Helper.SellAllVehiclesStoppedInDepots(); //must not be run during creating vehicles
}

function AIAI::SafeMaintenance() {
	this.SignMenagement();
	this.HandleOldLevelCrossings();
	this.BuilderMaintenance();
}

function AIAI::HandleEvents() //from CluelessPlus and SimpleAI
	{
	while(AIEventController.IsEventWaiting()) {
		local event = AIEventController.GetNextEvent();
		if (event == null) {
			return;
		}
		switch(event.GetEventType())
		{
		case AIEvent.ET_VEHICLE_LOST:
    		Warning("Vehicle lost event detected!");
			local lost_event = AIEventVehicleLost.Convert(event);
			local lost_veh = lost_event.GetVehicleID();

			/*
			TODO - do sth with that code
			local connection = ReadConnectionFromVehicle(lost_veh);
			
			if (connection.station.len() >= 2 && connection.connection_failed != true)
			{
				Info("Try to connect the stations again");

				if (!connection.RepairRoadConnection())
					SellVehicle(lost_veh);
			}
			else
			{
				SellVehicle(lost_veh);
			}
			*/
			break;
		case AIEvent.ET_VEHICLE_CRASHED:
			Warning("Vehicle crash detected!");
			local crash_event = AIEventVehicleCrashed.Convert(event);
			local crash_reason = crash_event.GetCrashReason();
			if (crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING) {
				this.HandleNewLevelCrossing(event);
			}
			break;
		case AIEvent.ET_AIRCRAFT_DEST_TOO_FAR:
			local order_event = AIEventAircraftDestTooFar.Convert(event);
			local airplane_id = order_event.GetVehicleID();
			abort("AIRCRAFT_DEST_TOO_FAR " + airplane_id + " " + airplane_id + " " + AIVehicle.GetName(airplane_id));
			break;
		case AIEvent.ET_ENGINE_PREVIEW:
			event = AIEventEnginePreview.Convert(event);
			if (event.AcceptPreview()) {
				Info("New engine available from preview: " + event.GetName());
				Autoreplace();
				if (event.GetVehicleType() == AIVehicle.VT_RAIL) {
					this.BuilderMaintenance();
				}
			}
			break;
		case AIEvent.ET_ENGINE_AVAILABLE:
			event = AIEventEngineAvailable.Convert(event);
			local engine = event.GetEngineID();
			Info("New engine available: " + AIEngine.GetName(engine));
			Autoreplace();
			if (AIEngine.GetVehicleType(engine) == AIVehicle.VT_RAIL) {
				this.BuilderMaintenance();
			}
			break;
		case AIEvent.ET_COMPANY_NEW:
			event = AIEventCompanyNew.Convert(event);
			local company = event.GetCompanyID();
			Info("Welcome " + AICompany.GetName(company));
			break;
		case AIEvent.ET_COMPANY_IN_TROUBLE:
			event = AIEventCompanyInTrouble.Convert(event);
			local company = event.GetCompanyID();
			if (AICompany.IsMine(company)) {
				Warning("Our company is in trouble!");
				this.BankruptProtector();
			} else {
				Info("Competitor is in trouble!");
			}
			break;
		case AIEvent.ET_COMPANY_BANKRUPT:
			event = AIEventCompanyInTrouble.Convert(event);
			local company = event.GetCompanyID();
			if (AICompany.IsMine(company)) {
				Error("Our company failed! Ops.");
				this.BankruptProtector();
			} else {
				Info("Competitor failed!");
				Info("Muhahhahahahahaha");
			}
			break;
		case AIEvent.ET_ROAD_RECONSTRUCTION :
			event = AIEventRoadReconstruction.Convert(event);
			local town = event.GetTownID();
			local company = event.GetCompanyID();
			Info("Road reconstruction at " + AITown.GetName(town) + " caused by " + AICompany.GetName(company));
			/* TODO: Handle it. */
			break;
		case AIEvent.ET_EXCLUSIVE_TRANSPORT_RIGHTS :
			event = AIEventExclusiveTransportRights.Convert(event);
			local town = event.GetTownID();
			local company = event.GetCompanyID();
			Info("Exclusive rights at " + AITown.GetName(town) + " bought by " + AICompany.GetName(company));
			/* TODO: Handle it. */
			break;
		case AIEvent.ET_INDUSTRY_OPEN:
			event = AIEventIndustryOpen.Convert(event);
			local industry = event.GetIndustryID();
			Info("New industry: " + AIIndustry.GetName(industry));
			// No need, this should be noticed in normal route finding.
			break;
		case AIEvent.ET_INDUSTRY_CLOSE:
			event = AIEventIndustryClose.Convert(event);
			local industry = event.GetIndustryID();
			if (AIIndustry.IsValidIndustry(industry)) {
				Info("Closing industry " + AIIndustry.GetName(industry) + " at [" + AIMap.GetTileX(AIIndustry.GetLocation(industry)) + ", " + AIMap.GetTileY(AIIndustry.GetLocation(industry)) + "]");
				// Handling is useless, as it should be caught on checking existing connections. Also, it may be temporary (weird NewGrf) or fixed by another company.
			}
			break;
		case AIEvent.ET_VEHICLE_WAITING_IN_DEPOT:
			Helper.SellAllVehiclesStoppedInDepots();
			break;
		case AIEvent.ET_DISASTER_ZEPPELINER_CRASHED:
			//TODO
			break;
		case AIEvent.ET_DISASTER_ZEPPELINER_CLEARED:
			//TODO
			break;
		case AIEvent.ET_TOWN_FOUNDED:
			// No need, this should be noticed in normal route finding.
			break;
		case AIEvent.ET_ADMIN_PORT:
			// Currently there is no support for anything related with admin port. Nor there is a any need or plan for this.
			break;
		case AIEvent.ET_WINDOW_WIDGET_CLICK:
			// No idea what is this (undocumented in docs), but there is no planned support.
			break;
		case AIEvent.ET_GOAL_QUESTION_ANSWER:
			// No idea what is this (undocumented in docs), but there is no planned support.
			break;
		case AIEvent.ET_ROAD_RECONSTRUCTION :
			//TODO
			break;
		case AIEvent.ET_SUBSIDY_OFFER:
		case AIEvent.ET_SUBSIDY_OFFER_EXPIRED:
		case AIEvent.ET_SUBSIDY_AWARDED:
		case AIEvent.ET_SUBSIDY_EXPIRED:
		case AIEvent.ET_COMPANY_ASK_MERGER:
		case AIEvent.ET_COMPANY_MERGER:
		case AIEvent.ET_VEHICLE_UNPROFITABLE:
		case AIEvent.ET_STATION_FIRST_VEHICLE:
			break;
		default:
			Error("Unhandled event " + event.GetEventType());
			if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1) {
				abort("unhandled event");
			}
			break;
		}
	}
}

function GetMaxSpeedBridge(start, end) {
	local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(start, end) + 1);
	bridge_list.Valuate(AIBridge.GetMaxSpeed);
	bridge_list.Sort(AIList.SORT_BY_VALUE, false);
	return bridge_list.Begin()
}

function AIAI::BuildBridge(vehicle_type, start, end) {
	local bridge_type_id = GetMaxSpeedBridge(start, end);
	local result = AIBridge.BuildBridge(vehicle_type, bridge_type_id, start, end);
	if (result) {
		bridge_list.append(start);
	}
	return result;
}