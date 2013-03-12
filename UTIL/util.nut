function RepayLoan()
{
while(AICompany.SetLoanAmount(AICompany.GetLoanAmount()-AICompany.GetLoanInterval()));
}

function GetMailCargoId()
{
local result = Helper.GetMailCargo();
if(result==-1)abort("mail cargo does not exist");
return result;
}

function GetPAXCargoId()
{
local result = Helper.GetPAXCargo();
if(result==-1)abort("PAX cargo does not exist");
return result;
}

function GetAvailableMoney()
{
local me = AICompany.ResolveCompanyID(AICompany.COMPANY_SELF);
return AICompany.GetBankBalance(me) + AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount() - Money.Inflate(10000);
}

function TotalLastYearProfit()
	{
	local list = AIVehicleList();
	local suma =0;
	for (local q = list.Begin(); list.HasNext(); q = list.Next()) //from Chopper 
		{
		suma += AIVehicle.GetProfitLastYear(q);
		}
	return suma;
	}

function NewLine()
	{
	AILog.Info(" ");
	} 

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
/////////////////////////////////////////////////
/// Age of the youngest vehicle (in days)
/// @pre AIStation.IsValidStation(station_id)
/////////////////////////////////////////////////
function AgeOfTheYoungestVehicle(station_id)
{
if(!AIStation.IsValidStation(station_id)) abort("Invalid station_id");
local list = AIVehicleList_Station(station_id);
local minimum = 10000;
for (local q = list.Begin(); list.HasNext(); q = list.Next()) //from Chopper 
   {
   local age=AIVehicle.GetAge(q);
   if(minimum>age)minimum=age;
   }

return minimum;
}

function GetAverageCapacity(station, cargo)
{
local list = AIVehicleList_Station(station);
local total = 0;
local ile = 0;
for (local q = list.Begin(); list.HasNext(); q = list.Next()) //from Chopper 
   {
   local plus=AIVehicle.GetCapacity (q, cargo);
   if(plus>0)
      {
	  total+=plus;
	  ile++;
	  }
   }
if(ile==0) return 0;
else return total/ile;
}

function abort(message)
{
Error(message + ", last error is " + AIError.GetLastErrorString());
Warning("Please, post savegame");
if(AIAI.GetSetting("pause_game_on_calling_abort_funtion_and_activated_ai_developer_tools") == 1 ) AIController.Break("STOP!")
local zero=0/0;
}

function GetVehicleType(vehicle_id)
{
	return AIEngine.GetVehicleType(AIVehicle.GetEngineType(vehicle_id));
}

function Sqrt(i) { //from Rondje
	if(i<0)abort("sqrt supplied with "+i)
	if (i == 0)
		return 0;   // Avoid divide by zero
	local n = (i / 2) + 1;       // Initial estimate, never low
	local n1 = (n + (i / n)) / 2;
	while (n1 < n) {
		n = n1;
		n1 = (n + (i / n)) / 2;
	}
	return n;
}

function SafeAddRectangle(list, tile, radius) { //from Rondje
	local x1 = max(1, AIMap.GetTileX(tile) - radius);
	local y1 = max(1, AIMap.GetTileY(tile) - radius);
	
	local x2 = min(AIMap.GetMapSizeX() - 2, AIMap.GetTileX(tile) + radius);
	local y2 = min(AIMap.GetMapSizeY() - 2, AIMap.GetTileY(tile) + radius);
	
	//Error("(" + x1 + ", " + y1 + ")" + "(" + x2 + ", " + y2 + ")")
	
	list.AddRectangle(AIMap.GetTileIndex(x1, y1),AIMap.GetTileIndex(x2, y2)); 
}

function RandomTile() { //from ChooChoo
	return Helper.Abs(AIBase.Rand()) % AIMap.GetMapSize();
}

function StringToInteger(string)
{
Info(string+"<-len")
local result = 0;
local i=0;
while(i<string.len()){
	result=result*10+string[i]-48;
	i++;
	}
return result;
}

function IsTileFlatAndBuildable(tile)
	{
	return (AITile.IsBuildable(tile) && AITile.SLOPE_FLAT == AITile.GetSlope(tile));
	}

function IsTileWithAuthorityRefuse(tile)
	{
	local town_id=AITile.GetClosestTown (tile);
	if(AITown.GetRating (town_id, AICompany.COMPANY_SELF) == AITown.TOWN_RATING_APPALLING) return true;
	if(AITown.GetRating (town_id, AICompany.COMPANY_SELF) == AITown.TOWN_RATING_VERY_POOR) return true;
	return false;
	}

	function DeleteVehiclesInDepots()
	{
	//Info("DeleteVehiclesInDepots");
	local counter=0;
	local list=AIVehicleList();
	for (local q = list.Begin(); list.HasNext(); q = list.Next()){ //from Chopper 
		if(AIVehicle.IsStoppedInDepot(q)){
			AIVehicle.SellVehicle(q);
			counter++;
		}
	}
	return counter;
	}

function ImproveTownRating(town_id, desperation) //from AdmiralAI
{	
	local mode = AIExecMode();
	if(GetAvailableMoney()<Money.Inflate(200000) && desperation == 0) return false;
	ProvideMoney();
	local min_rating=AITown.TOWN_RATING_POOR
	/* Check whether the current rating is good enough. */
	local rating = AITown.GetRating(town_id, AICompany.COMPANY_SELF);
	if (rating == AITown.TOWN_RATING_NONE || rating >= min_rating) return true;

	/* Build trees to improve the rating. We build this tree in an expanding
	 * circle starting around the town center. */
	local location = AITown.GetLocation(town_id);
	for (local size = 3; size <= 1000; size++) {
		local list = AITileList();
		SafeAddRectangle(list, location, size);
		list.Valuate(AITile.IsBuildable);
		list.KeepValue(1);
		/* Don't build trees on tiles that already have trees, as this doesn't
		 * give any town rating improvement. */
		list.Valuate(AITile.HasTreeOnTile);
		list.KeepValue(0);
		foreach (tile, dummy in list) {
			if(!AITown.IsWithinTownInfluence(town_id, tile))
				{
				if(GetAvailableMoney()> Money.Inflate(3000000 || desperation > 5)) {
					if(AITown.PerformTownAction(town_id, AITown.TOWN_ACTION_BRIBE))
						{
						Info("Bribed "+AITown.GetName(town_id)+"!" + AIError.GetLastErrorString());
						}
					else{
						Info("Bribe in "+AITown.GetName(town_id)+" failed!" + AIError.GetLastErrorString());
						return false;
						}
					}
				else{
					return false;
					}
				}
			else
				{
				if(AITile.PlantTree(tile))
					{
					Info("Tree planted!");
					}
				}
			/* Check whether the current rating is good enough. */
			if (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating) return true;
			if(GetAvailableMoney()<Money.Inflate(200000)) return false;
		}
	}
}

function HandleFailedStationConstruction(location, error)
{	
	if(error==AIError.ERR_LOCAL_AUTHORITY_REFUSES) 
		{
		ImproveTownRating(AITile.GetClosestTown(location), this.desperation);
		}
}

function GetRatherBigRandomTownValuator(town_id)
{
return AITown.GetPopulation(town_id)*AIBase.RandRange(5);
}

function GetRatherBigRandomTown()
{
local town_list = AITownList();
town_list.Valuate(GetRatherBigRandomTownValuator);
town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
return town_list.Begin();
}

function IsConnectedDistrict(town_tile)
{
	//TODO - it is a hack rather than function
	local list = AIStationList(AIStation.STATION_AIRPORT);
	if(list.Count()!=0){
		list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
		list.KeepBelowValue(18);
		if(!list.IsEmpty()) return true;
	}

	list = AIStationList(AIStation.STATION_BUS_STOP);
	if(list.Count()!=0){
		list.Valuate(AIStation.GetDistanceManhattanToTile, town_tile);
		list.KeepBelowValue(8);
		if(!list.IsEmpty()) return true;
	}
	return false;
}
