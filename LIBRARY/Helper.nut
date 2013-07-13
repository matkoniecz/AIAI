AILog.Info("adding new functions to SuperLib (Helper)");

//from Rondje, computes square root of i using Babylonian method
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
