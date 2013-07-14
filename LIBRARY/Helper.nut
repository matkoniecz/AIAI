AILog.Info("adding new functions to SuperLib (Helper)");

//from Rondje - attempt to contruct HQ in the biggest city, returns true if HQ contruction succeded, false otherwise
_SuperLib_Helper.BuildCompanyHQ <- function()
{
	if(AIMap.IsValidTile(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF))) {
		return;
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
//from Rondje, computes and returns square root of parameter using Babylonian method 
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
