function Info(string) {
	local date=AIDate.GetCurrentDate ();
	AILog.Info(GetReadableDate()  + " " + string);
}

function Warning(string) {
	local date=AIDate.GetCurrentDate ();
	AILog.Warning(GetReadableDate()  + " " + string);
}

function Error(string) {
	AILog.Error(GetReadableDate() + " " + string);
}

function GetReadableDate() {
	local date=AIDate.GetCurrentDate ();
	return AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date);
}

counter <- 1;
counter_for_year <- 0;

function MajorInfo(string) {
	local test = AIExecMode(); //allow MajorInfo in test mode
	Warning(string + "<- important!");
	local date = AIDate.GetCurrentDate ();
	local year = AIDate.GetYear(date);
	if(counter_for_year < year) {
		counter = 1;
		counter_for_year = year;
	}
	string = year  + "." + counter + " " + string;
	CreateVehicleGroup(string)
	counter += 1;
	//CreateVehicleGroup(AIDate.GetYear(date)  + "." + counter + " " + string.len());
	//counter += 1;
}

function CreateVehicleGroup(name){
	local group = AIGroup.CreateGroup(AIVehicle.VT_RAIL);
	if(!AIGroup.IsValidGroup(group)) {
		Error("AIGroup.CreateGroup: " + AIError.GetLastErrorString())
		Error("IsTestModeEnabled(): " + IsTestModeEnabled());
		if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1){
			assert(false);
		}
	}
	if(!AIGroup.SetName(group, name)) {
		Error("AIGroup.SetName: " + AIError.GetLastErrorString());
		Error("IsTestModeEnabled(): " + IsTestModeEnabled());
		Error("name: "+name);
		Error("name.len(): " + name.len());
		if (AIAI.GetSetting("crash_AI_in_strange_situations") == 1){
			assert(false);
		}
	}
}

function ShortenErrorString(string){
	if(string == "ERR_NONE") {
		return "ERR_NONE"
	} else if(string == "ERR_UNKNOWN") {
		return "ERR_UNKNOWN"
	} else if(string == "ERR_PRECONDITION_FAILED") {
		return "E_PRECOND."
	} else if(string == "ERR_PRECONDITION_STRING_TOO_LONG") {
		return "TEXT_TOO_LONG"
	} else if(string == "ERR_PRECONDITION_TOO_MANY_PARAMETERS") {
		return "TOO_MANY_PAR."
	} else if(string == "ERR_PRECONDITION_INVALID_COMPANY") {
		return "BAD_COMPANY"
	} else if(string == "ERR_NEWGRF_SUPPLIED_ERROR") {
		return "NEWGRF"
	} else if(string == "ERR_GENERAL_BASE") {
		return "GENERAL"
	} else if(string == "ERR_NOT_ENOUGH_CASH") {
		return "need $"
	} else if(string == "ERR_LOCAL_AUTHORITY_REFUSES") {
		return "TOWN REF."
	} else if(string == "ERR_ALREADY_BUILT") {
		return "ALREADY_BUILT"
	} else if(string == "ERR_AREA_NOT_CLEAR") {
		return "AREA~CLR"
	} else if(string == "ERR_OWNED_BY_ANOTHER_COMPANY") {
		return "OWNED"
	} else if(string == "ERR_NAME_IS_NOT_UNIQUE") {
		return "DUP."
	} else if(string == "ERR_FLAT_LAND_REQUIRED") {
		return "FLAT_REQ."
	} else if(string == "ERR_LAND_SLOPED_WRONG") {
		return "SLOPED_WRONG"
	} else if(string == "ERR_VEHICLE_IN_THE_WAY") {
		return "VEH_IN_WAY"
	} else if(string == "ERR_SITE_UNSUITABLE") {
		return "SITE_UNSU."
	} else if(string == "ERR_TOO_CLOSE_TO_EDGE") {
		return "CLOSE_EDGE"
	} else if(string == "ERR_STATION_TOO_SPREAD_OUT") {
		return "SPREAD_OUT"
	}
	Error("unexpected error: " + string);
	assert(false)
}

function IsTestModeEnabled() {
	local gender = AICompany.GetPresidentGender(AICompany.COMPANY_SELF);
	local other_gender = AICompany.GENDER_MALE 
	if (gender == other_gender) {
		other_gender = AICompany.GENDER_FEMALE 
	}
	AICompany.SetPresidentGender(other_gender)
	if (gender == AICompany.GetPresidentGender(AICompany.COMPANY_SELF)) {
		return true;
	}
	return false;
}

function abort(message) {
	Error(message + ", last error is " + AIError.GetLastErrorString());
	Warning("Please, post savegame");
	if (IsTestModeEnabled()) {
		Error("Note: TestMode was enabled");
	}
	if (AIAI.GetSetting("pause_game_on_calling_abort_funtion_and_activated_ai_developer_tools") == 1 ) {
		AIController.Break("STOP!")
	}
	assert(false)
}
