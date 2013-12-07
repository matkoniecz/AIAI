function Info(string)
{
	local date=AIDate.GetCurrentDate ();
	AILog.Info(GetReadableDate()  + " " + string);
}

function Warning(string)
{
	local date=AIDate.GetCurrentDate ();
	AILog.Warning(GetReadableDate()  + " " + string);
}

function Error(string)
{
	AILog.Error( GetReadableDate() + " " + string);
}

function GetReadableDate()
{
	local date=AIDate.GetCurrentDate ();
	return AIDate.GetYear(date)  + "." + AIDate.GetMonth(date)  + "." + AIDate.GetDayOfMonth(date);
}

function IsTestModeEnabled()
{
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

function abort(message)
{
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
