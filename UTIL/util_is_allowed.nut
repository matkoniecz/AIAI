function IsAllowedPAXPlane()
{
	if(0 == AIAI.GetSetting("PAX_plane")) return false;
	return IsAllowedPlane();
}

function IsAllowedCargoPlane()
{
	if(0 == AIAI.GetSetting("cargo_plane")) return false;
	return IsAllowedPlane();
}

function IsAllowedPlane()
{
	if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR)) return false;

	local ile;
	local veh_list = AIVehicleList();
	veh_list.Valuate(GetVehicleType);
	veh_list.KeepValue(AIVehicle.VT_AIR);
	ile = veh_list.Count();
	local allowed = AIGameSettings.GetValue("vehicle.max_aircraft");
	if(allowed==0) return false;
	if(ile==0) return true;
	if((allowed - ile)<4) return false;
	if(((ile*100)/(allowed))>90) return false;
	return true;
}

function IsAllowedTruck()
{
	if(0 == AIAI.GetSetting("use_trucks")) return false;
	return IsAllowedRV();
}

function IsAllowedCargoTrain()
{
	if(0 == AIAI.GetSetting("use_freight_trains")) return false;
	return IsAllowedTrain();
}

function IsAllowedBus()
{
	if(0 == AIAI.GetSetting("use_busses")) return false;
	return IsAllowedRV();
}

function IsAllowedRV()
{
	if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD)) return false;

	local ile;
	local veh_list = AIVehicleList();
	veh_list.Valuate(GetVehicleType);
	veh_list.KeepValue(AIVehicle.VT_ROAD);
	ile = veh_list.Count();
	local allowed = AIGameSettings.GetValue("vehicle.max_roadveh");
	if(allowed==0) return false;
	if(ile==0) return true;
	if(((ile*100)/(allowed))>90) return false;
	if((allowed - ile)<5) return false;
	return true;
}

function IsAllowedTrain()
{
	if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL)) return false;

	local ile;
	local veh_list = AIVehicleList();
	veh_list.Valuate(GetVehicleType);
	veh_list.KeepValue(AIVehicle.VT_RAIL);
	ile = veh_list.Count();
	local allowed = AIGameSettings.GetValue("vehicle.max_trains");
	if(allowed==0) return false;
	if(ile==0) return true;
	if(((ile*100)/(allowed))>90) return false;
	if((allowed - ile)<5) return false;
	return true;
}
