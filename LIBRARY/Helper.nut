AILog.Info("adding new functions to SuperLib (Helper)");

	//from AIAI by Kogut
	//estimates how weight of vehicle will change after loading one piece of cargo_id cargo
	//it is a guess, but there is no better method for predicting this value
	//returns expected weight of single piece of cargo_id
	//GetWeightOfOneCargoPiece(cargo_id)

	//from AIAI by Kogut
	//iterates over vehicles, all stopped in depots are sold
	//SellAllVehiclesStoppedInDepots()

	//from Rondje om de kerk
	//computes square root of i using Babylonian method
	//returns n that is the highest integer that is lower or equal to the square root of integer i
	//Sqrt(i)

	//from Rondje om the kerk
	//attempt to contruct HQ in the biggest city, returns true if HQ exists on exiting function, false otherwise
	//if HQ exists on calling function it will not be moved and function will return true
	//BuildCompanyHQ()

_SuperLib_Helper.GetWeightOfOneCargoPiece <- function(cargo_id)
{
	if(AICargo.IsFreight(cargo_id)) {
		return AIGameSettings.GetValue("vehicle.freight_trains");
	}
	if(AICargo.HasCargoClass(cargo_id, AICargo.CC_MAIL) || AICargo.HasCargoClass(cargo_id, AICargo.CC_PASSENGERS))  {
		return 0;
	}
	return 1;
}

_SuperLib_Helper.SellAllVehiclesStoppedInDepots <- function()
{
	local counter = 0;
	local list = AIVehicleList();
	for (local vehicle = list.Begin(); list.HasNext(); vehicle = list.Next()) {
		if(AIVehicle.IsStoppedInDepot(vehicle)){
			AIVehicle.SellVehicle(vehicle);
			counter++;
		}
	}
	return counter;
}

_SuperLib_Helper.BuildCompanyHQ <- function()
{
	if(AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) {
		return true;
	}

	// Find biggest town for HQ
	local towns = AITownList();
	towns.Valuate(AITown.GetPopulation);
	towns.Sort(AIList.SORT_BY_VALUE, false);
	local town = towns.Begin();
	
	// Find empty 2x2 square as close to town centre as possible
	local maxRange = Helper.Sqrt(AITown.GetPopulation(town)/100) + 5;
	local HQArea = AITileList();
	HQArea.AddRectangle(AITown.GetLocation(town) - AIMap.GetTileIndex(maxRange, maxRange), AITown.GetLocation(town) + AIMap.GetTileIndex(maxRange, maxRange));
	HQArea.Valuate(AITile.IsBuildableRectangle, 2, 2);
	HQArea.KeepValue(1);
	HQArea.Valuate(AIMap.DistanceManhattan, AITown.GetLocation(town));
	HQArea.Sort(AIList.SORT_BY_VALUE, true);
	
	for (local tile = HQArea.Begin(); HQArea.HasNext(); tile = HQArea.Next()) {
		if(AICompany.BuildCompanyHQ(tile)) {
			return true;
		} 
	}
	return false;
}

_SuperLib_Helper.Sqrt <- function(i)
{ 
	assert(i>=0);
	if (i == 0) {
		return 0; // Avoid divide by zero
	}
	local n = (i / 2) + 1; // Initial estimate, never low
	local n1 = (n + (i / n)) / 2;
	while (n1 < n) {
		n = n1;
		n1 = (n + (i / n)) / 2;
	}
	return n;
}

_SuperLib_Helper.ReversePath <- function(i)
{
class RPathItem
{
	_tile = null;
	_parent = null;

	constructor(tile)
	{
		this._tile = tile;
	}

	function GetTile()
	{
		return this._tile;
	}

	function GetParent()
	{
		return this._parent;
	}
};

	local rpath = RPathItem(path.GetTile());
	while (path.GetParent() != null) {
		path = path.GetParent();
		local npath = RPathItem(path.GetTile());
		npath._parent = rpath;
		rpath = npath;
	}
	path = rpath;
}

AILog.Info("changing SuperLib (Helper) finished");
