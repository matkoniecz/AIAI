class SmartRailBuilder extends RailBuilder
{
};

function SmartRailBuilder::Possible()
{
	if(!IsAllowedSmartCargoTrain())return false;
	Info("$: " + this.cost + " / " + GetAvailableMoney());
	return this.cost<GetAvailableMoney();
}

function SmartRailBuilder::Go()
{
local types = AIRailTypeList();
AIRail.SetCurrentRailType(types.Begin()); //TODO FIXME - needed in IsGreatPlaceForRailStationSmartRail etc
for(local i=0; i<retry_limit; i++)
	{
	if(!Possible())return false;
	Important("Scanning for smart rail route");
	trasa = this.FindPairForSmartRailRoute(trasa);  
	if(!trasa.OK) 
		{
		Info("Nothing found!");
		cost = 0;
		return false;
		}
	Error(trasa.track_type);
	AIRail.SetCurrentRailType(trasa.track_type);
	Important("Scanning for smart rail route completed [ " + desperation + " ] cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
	if(this.SmartRailRoute())return true;
	else trasa.forbidden.AddItem(trasa.start, 0);
	}
return false;
}

function GetDirection(X, Y)
{
if(AIBase.RandRange(abs(X)+abs(Y))+1<=abs(X)) return "X";
return "Y";
}

function SmartRailBuilder::SubPathFinder(start, end, kill, in_ignore) 
{
local limit=100000;
/*
trasa
ignore is used
*/
local pathfinder = Rail();
pathfinder.estimate_multiplier = 3;
pathfinder.cost.bridge_per_tile = 500;
pathfinder.cost.tunnel_per_tile = 35;
pathfinder.cost.diagonal_tile = 35;
pathfinder.cost.coast = 0;
if(kill)pathfinder.cost.turn = pathfinder.cost.max_cost;
pathfinder.cost.max_bridge_length = 40;   // The maximum length of a bridge that will be build.
pathfinder.cost.max_tunnel_length = 40;   // The maximum length of a tunnel that will be build.

if(start == null) abort("?");
if(end == null) abort("?");
if(in_ignore == null)in_ignore=ignore //FIXME TODO!
pathfinder.InitializePath(end, start, in_ignore);

local path = false;
local guardian=0;
while (path == false) {
  path = pathfinder.FindPath(2000);
  Info("tick")
  rodzic.Maintenance();
  AIController.Sleep(1);
}

return path;
}

function SmartRailBuilder::IsOKJunctionTile(tile)
{
if(AITile.GetSlope(tile)!=AITile.SLOPE_FLAT)return false;
if(!AITile.IsBuildable(tile))return false;
return true;
}

function SmartRailBuilder::IsOKJunctionSeedTile(tile)
{
if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(-1, -1)))return false;
if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(-1, 0)))return false;
if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(0, -1)))return false;
if(!IsOKJunctionTile(tile))return false;


if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(-2, 0)))return false;
if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(0, -2)))return false;
if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(2, 0)))return false;
if(!IsOKJunctionTile(tile+AIMap.GetTileIndex(0, 2)))return false;

return true;
}

function SmartRailBuilder::MigrateNetworkPlug(tile, endX, loc_startX, endY, loc_startY)
{
while(!IsOKJunctionSeedTile(tile))
	{
	local X=endX-loc_startX;
	local Y=endY-loc_startY;
	local dir = GetDirection(X, Y);
	if (dir=="X")
		{
		loc_startX+=X/abs(X);
		}
	else
		{
		loc_startY+=Y/abs(Y);
		}
	tile=AIMap.GetTileIndex(loc_startX, loc_startY);
	AISign.BuildSign(tile, ".");
	}
return tile;
}

function PathFinderNetworkingJumping(skip)
{
local startY=(AIMap.GetTileY(start[0][0])+AIMap.GetTileY(start[1][0]))/2;
local startX=(AIMap.GetTileX(start[0][0])+AIMap.GetTileX(start[1][0]))/2;

local endY=(AIMap.GetTileY(end[0][0])+AIMap.GetTileY(end[1][0]))/2;
local endX=(AIMap.GetTileX(end[0][0])+AIMap.GetTileX(end[1][0]))/2;

local deltaY = endY-startY;
local deltaX = endX-startX;

local skipX=skip*deltaX/(abs(deltaX)+abs(deltaY)); //TODO deltaX == 0
local skipY=skip*deltaY/(abs(deltaX)+abs(deltaY));
if(skipX==0) skipX=deltaX/abs(deltaX);
if(skipY==0) skipY=deltaY/abs(deltaY);
local junction_startX = startX+skipX;
local junction_startY = startY+skipY;
local junction_endX = endX-skipX;
local junction_endY = endY-skipY;

local start_junction=AIMap.GetTileIndex(junction_startX, junction_startY);
local end_junction=AIMap.GetTileIndex(junction_endX, junction_endY);
start_junction = this.MigrateNetworkPlug(start_junction, endX, junction_startX, endY, junction_startY)
end_junction = this.MigrateNetworkPlug(end_junction, startX, junction_endX, startY, junction_endY)

local segment_start, segment_start_in, segment_end, segment_end_in;
local segment_start2, segment_start_in2, segment_end2, segment_end_in2;
segment_start = start_junction;

	local X=endX-junction_startX;
	local Y=endY-junction_startY;
	local dir = GetDirection(X, Y);

	local i
	if (dir=="X")
		{
		for(i=10; i<100; i++)
			if(IsOKJunctionSeedTile(segment_start+AIMap.GetTileIndex(skipX/abs(skipX)*i, 0)))
				break;

		segment_start=start_junction
		segment_start_in=segment_start+AIMap.GetTileIndex(-skipX/abs(skipX), 0);
		segment_end=segment_start+AIMap.GetTileIndex(skipX/abs(skipX)*(i-1), 0);
		segment_end_in=segment_start+AIMap.GetTileIndex(skipX/abs(skipX)*(i), 0);
		
		segment_start2=segment_start+AIMap.GetTileIndex(0, -1);
		segment_start_in2=segment_start+AIMap.GetTileIndex(-skipX/abs(skipX), -1);
		segment_end2=segment_start+AIMap.GetTileIndex(skipX/abs(skipX)*(i-1), -1);
		segment_end_in2=segment_start+AIMap.GetTileIndex(skipX/abs(skipX)*(i), -1);
		}
	else
		{
		for(i=10; i<100; i++)
			if(IsOKJunctionSeedTile(segment_start+AIMap.GetTileIndex(0, skipY/abs(skipY)*i)))
				break;

		segment_start
		segment_start_in=segment_start+AIMap.GetTileIndex(0, -skipY/abs(skipY));
		segment_end=segment_start+AIMap.GetTileIndex(0, skipY/abs(skipY)*(i-1));
		segment_end_in=segment_start+AIMap.GetTileIndex(0, skipY/abs(skipY)*(i));
		
		segment_start2=segment_start+AIMap.GetTileIndex(-1, 0);
		segment_start_in2=segment_start+AIMap.GetTileIndex(-1, -skipY/abs(skipY));
		segment_end2=segment_start+AIMap.GetTileIndex(-1, skipY/abs(skipY)*(i-1));
		segment_end_in2=segment_start+AIMap.GetTileIndex(-1, skipY/abs(skipY)*(i));
		}

AISign.BuildSign(segment_start_in, "A");
AISign.BuildSign(segment_start, "B");
AISign.BuildSign(segment_end, "C");
AISign.BuildSign(segment_end_in, "D");
AISign.BuildSign(segment_start_in2, "A2");
AISign.BuildSign(segment_start2, "B2");
AISign.BuildSign(segment_end2, "C2");
AISign.BuildSign(segment_end_in2, "D2");

local test_start = [[segment_start, segment_start_in]]
local test_end = [[segment_end, segment_end_in]]
local test_start2 = [[segment_start2, segment_start_in2]]
local test_end2 = [[segment_end2, segment_end_in2]]

local path=this.SubPathFinder(test_end,test_start, true, null);
local path2=this.SubPathFinder(test_start2, test_end2, true, null);

if(path != null && path2 != null)
	{
	DumbBuilder(path);
	DumbBuilder(path2);
	this.SignalPathAdvanced(path, true, 8, 9999); //@pre - max train size == 7
	this.SignalPathAdvanced(path2, true, 8, 9999); //@pre - max train size == 7
	if (start_junction == null) abort("?");
	if (end_junction == null) abort("?");
	if (path == null) abort("?");
	return [start_junction, end_junction, path];
	}
else
	return null;
}

function SmartRailBuilder::PathFinderNetworking(reverse, limit) 
{
if (end == null) abort("?");
if (start == null) abort("?");
local pathfinder = Rail();
pathfinder.estimate_multiplier = 3;
pathfinder.cost.bridge_per_tile = 500;
pathfinder.cost.tunnel_per_tile = 35;
pathfinder.cost.diagonal_tile = 35;
pathfinder.cost.coast = 0;
pathfinder.cost.turn = 50;
pathfinder.cost.max_bridge_length = 40;   // The maximum length of a bridge that will be build.
pathfinder.cost.max_tunnel_length = 40;   // The maximum length of a tunnel that will be build.

local skip=10;
local pack = PathFinderNetworkingJumping(skip);

if (pack == null) return null;
	
local segment_start = pack[0];
local segment_end = pack[1];
local path = pack[2];

if (segment_start == null) abort("?");
if (segment_end == null) abort("?");
if (path == null) abort("?");
JunctionBuilder(segment_start);
JunctionBuilder(segment_end);
local out=true;
local pf_data_of_first_junction = TranformJunctionToPFArray(segment_start);
local pf_data_of_last_junction = TranformJunctionToPFArray(segment_end);

local path0 = SubPathFinder(pf_data_of_first_junction.start, start, false, ignore);
DumbBuilder(path0);
local path3 = SubPathFinder(start, pf_data_of_first_junction.end, false, ignore);
DumbBuilder(path3);

local path4 = SubPathFinder(end, pf_data_of_last_junction.end, false, ignore);
DumbBuilder(path4);
local path5 = SubPathFinder(pf_data_of_last_junction.start, end, false, ignore);
DumbBuilder(path5);
	
this.SignalPathAdvanced(path0, true, 7, 9999);
this.SignalPath(path3, true);
this.SignalPath(path4, true);
this.SignalPathAdvanced(path5, true, 7, 9999);
return path;
}

function SmartRailBuilder::CoverTileWithTracks(tile)
{
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NE_SW); //prawo-lewo
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_SE); //góra-dó³
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_NE);
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_SW_SE);
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_SW);
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NE_SE);
	return true;
	//TODO - error handling
}

function MakeWaypoints(tile_a, tile_b, railtrack)
	{
	if(!(AIRail.GetRailTracks(tile_a)==railtrack && AIRail.GetRailTracks(tile_b)==railtrack))
		{
		if(AIRail.BuildRailTrack(tile_a, railtrack) && AIRail.BuildRailTrack(tile_b, railtrack))
			{
			local waypoints_constructed;
			if(1 == AIAI.GetSetting("use_patch_code")) 
				{
				waypoints_constructed = true;
				//waypoints_constructed = AIRail.BuildRailWaypointTileRectangle(tile_a, 1, AIStation.STATION_NEW) && AIRail.BuildRailWaypointTileRectangle(tile_b, 1, AIStation.STATION_NEW);
				//waypoints_constructed = AIRail.BuildRailWaypointTileRectangle(tile_a, 2, AIStation.STATION_NEW);
				}
			else
				{
				waypoints_constructed = AIRail.BuildRailWaypoint(tile_a, AIStation.STATION_NEW) && AIRail.BuildRailWaypoint(tile_b, AIStation.STATION_NEW);
				}
			if(waypoints_constructed)
				{
				rodzic.SetWaypointName("TODO", tile_a);
				rodzic.SetWaypointName("TODO", tile_b);
				}
			else
				{
				Error(AIError.GetLastErrorString());
				AIRail.RemoveRailWaypointTileRectangle(tile_a, tile_b, true);
				}
			}
		else
			{
			AIRail.RemoveRailTrack(tile_a, railtrack);
			AIRail.RemoveRailTrack(tile_b, railtrack);
			}
		}
	}

function SmartRailBuilder::JunctionBuilder(tile)
{
if(!CoverTileWithTracks(tile+AIMap.GetTileIndex(-1, -1)))return false;
if(!CoverTileWithTracks(tile+AIMap.GetTileIndex(-1, 0)))return false;
if(!CoverTileWithTracks(tile+AIMap.GetTileIndex(0, -1)))return false;
if(!CoverTileWithTracks(tile+AIMap.GetTileIndex(0, 0)))return false;

	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NE_SW);

MakeWaypoints(tile+AIMap.GetTileIndex(0, 1), tile+AIMap.GetTileIndex(-1, 1), AIRail.RAILTRACK_NW_SE) //lower right
MakeWaypoints(tile+AIMap.GetTileIndex(0, -2), tile+AIMap.GetTileIndex(-1, -2), AIRail.RAILTRACK_NW_SE) //upper left

MakeWaypoints(tile+AIMap.GetTileIndex(1, 0), tile+AIMap.GetTileIndex(1, -1), AIRail.RAILTRACK_NE_SW) //lower left
MakeWaypoints(tile+AIMap.GetTileIndex(-2, 0), tile+AIMap.GetTileIndex(-2, -1), AIRail.RAILTRACK_NE_SW) //upper right
return true;
}

function SmartRailBuilder::ProcessTransformation(checktile, escapetile, railtrack, on_off, result)
	{
	//Warning(AIRail.GetRailTracks(checktile));
	//Error(railtrack);
	if(AIRail.GetRailTracks(checktile)==railtrack)
		{
		return [escapetile, checktile]
		}
	else
		{
		AISign.BuildSign(checktile, "NIE MA");
		return null;
		}
	}

function SmartRailBuilder::TranformJunctionToPFArray(tile)
	{
	//junction as start
	
	//AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_NE); //prawo-lewo
	//IRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_SE); //góra-dó³

	//AISign.BuildSign(tile, "^");
	local result = RailPathProject();
	local checktile, escapetile, railtrack, on_off, result_after;

	//lower right
	checktile = tile+AIMap.GetTileIndex(0, 1);
	escapetile = tile+AIMap.GetTileIndex(0, 2);
	railtrack = AIRail.RAILTRACK_NW_SE;
	result.addStart(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (start)");
	//AISign.BuildSign(escapetile, "do (start)");

	checktile = tile+AIMap.GetTileIndex(-1, 1);
	escapetile = tile+AIMap.GetTileIndex(-1, 2);
	railtrack = AIRail.RAILTRACK_NW_SE;
	result.addEnd(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (cel)");
	//AISign.BuildSign(escapetile, "do (cel)");

	//upper left
	checktile = tile+AIMap.GetTileIndex(0, -2);
	escapetile = tile+AIMap.GetTileIndex(0, -3);
	railtrack = AIRail.RAILTRACK_NW_SE;
	result.addEnd(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (cel)");
	//AISign.BuildSign(escapetile, "do (cel)");

	checktile = tile+AIMap.GetTileIndex(-1, -2);
	escapetile = tile+AIMap.GetTileIndex(-1, -3);
	railtrack = AIRail.RAILTRACK_NW_SE;
	result.addStart(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (start)");
	//AISign.BuildSign(escapetile, "do (start)");

	//upper right
	checktile = tile+AIMap.GetTileIndex(-2, 0);
	escapetile = tile+AIMap.GetTileIndex(-3, 0);
	railtrack = AIRail.RAILTRACK_NE_SW;
	result.addStart(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (start)");
	//AISign.BuildSign(escapetile, "do (start)");

	checktile = tile+AIMap.GetTileIndex(-2, -1);
	escapetile = tile+AIMap.GetTileIndex(-3, -1);
	railtrack = AIRail.RAILTRACK_NE_SW;
	result.addEnd(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (cel)");
	//AISign.BuildSign(escapetile, "do (cel)");

	//lower left
	checktile = tile+AIMap.GetTileIndex(1, 0);
	escapetile = tile+AIMap.GetTileIndex(2, 0);
	railtrack = AIRail.RAILTRACK_NE_SW;
	result.addStart(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (start)");
	//AISign.BuildSign(escapetile, "do (start)");

	checktile = tile+AIMap.GetTileIndex(1, -1);
	escapetile = tile+AIMap.GetTileIndex(2, -1);
	railtrack = AIRail.RAILTRACK_NE_SW;
	result.addEnd(ProcessTransformation(checktile, escapetile, railtrack, on_off, result))
	//AISign.BuildSign(checktile, "z (cel)");
	//AISign.BuildSign(escapetile, "do (cel)");

	return result;
	}
	
function SmartRailBuilder::SmartRailBuilderNetworking()
{
Info("try_networking");
this.StationPreparation();   	
path = this.PathFinderNetworking(false, this.GetPathfindingLimit());
if(path == null) 
	return false;

local estimated_cost=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);
cost=estimated_cost;

if(!this.StationConstruction()) return false;   

/*
if(!this.RailwayLinkConstruction(path)){
	Info("   But stopped by error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	return false;	  
	}
*/
trasa.depot_tile = this.BuildDepot(path, false);
local max_train_count = 9;
rodzic.SetStationName(trasa.first_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
rodzic.SetStationName(trasa.second_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");

if(trasa.depot_tile==null){
	Info("   Depot placement error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;	  
	}

local new_engine = this.BuildTrain(trasa, "smart uno");

if(new_engine == null){
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;
	}
this.TrainOrders(new_engine);

/*
	this.SignalPath(path, false);
	this.SignalPath(old_path, false);
*/
	
local second_engine = this.BuildTrain(trasa, "smart duo");
if(second_engine != null)
	{
	if(AIVehicle.IsValidVehicle(new_engine))
		{
		AIOrder.ShareOrders(second_engine, new_engine);
		AITown.PerformTownAction(trasa.first_station.location, AITown.TOWN_ACTION_BUILD_STATUE);
		}
   else
		{
		this.TrainOrders(second_engine);
		}
   }
return true;
}

function SmartRailBuilder::SmartRailRoute()
{
AIRail.SetCurrentRailType(trasa.track_type);
if(1 == AIAI.GetSetting("try_networking")) 
	{
	if(this.SmartRailBuilderNetworking()) return true;
	}


this.StationPreparation();   
Info("   Company started route on distance: " + AIMap.DistanceManhattan(trasa.start_tile, trasa.end_tile));
	
if(!this.PathFinder(false, this.GetPathfindingLimit()))return false;

local estimated_cost = this.GetCostOfRoute(path); 
if(estimated_cost==null){
  Info("   Pathfinder failed to find correct route.");
  return false;
  }

Info("Construction can start!")
estimated_cost+=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);
cost=estimated_cost;

if(GetAvailableMoney()<estimated_cost+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	Error("WE NEED MORE CASH TO BUILD OUR PRECIOUS ROUTE!")
	local total_last_year_profit = TotalLastYearProfit();
	if(total_last_year_profit>estimated_cost)
		{
		Error("But we can wait!");
		while(GetAvailableMoney()<estimated_cost+2000){ //TODO: real station cost
			Info("too expensivee, we have only " + GetAvailableMoney() + " And we need " + estimated_cost);
			rodzic.Maintenance();
			AIController.Sleep(1000);
			}
		}
		else{
			Error("And we can not wait!");
			this.cost = estimated_cost;
			return false;
		}
	}
else Info("We have enough money.")
ProvideMoney();
if(!this.StationConstruction()) return false;   
if(!this.RailwayLinkConstruction(path)){
	Info("   But stopped by error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	return false;	  
	}

trasa.depot_tile = this.BuildDepot(path, false);
local max_train_count = 1;
rodzic.SetStationName(trasa.first_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
rodzic.SetStationName(trasa.second_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
if(trasa.depot_tile==null){
	Info("   Depot placement error");
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;	  
	}

local new_engine = this.BuildTrain(trasa, "smart uno");

if(new_engine == null){
	AITile.DemolishTile(trasa.first_station.location);
	AITile.DemolishTile(trasa.second_station.location);
	this.DumbRemover(path, null)
	return false;
	}
this.TrainOrders(new_engine);
Info("   I stage completed");
RepayLoan();

local date=AIDate.GetCurrentDate ();
   
local old_path = path;

if(!this.PathFinder(true, this.GetPathfindingLimit()))return true; //TODO: passing lanes
ProvideMoney();
local date=AIDate.GetCurrentDate ();
cost = this.GetCostOfRoute(path); 
if(cost==null){
	Info("   Pathfinder failed to find correct route.");
	Info("Retry");
	if(!this.PathFinder(true, this.GetPathfindingLimit()*4))return true; //TODO: passing lanes
		ProvideMoney();
		local date=AIDate.GetCurrentDate ();
		cost = this.GetCostOfRoute(path); 
		if(cost==null){
		Info("   Pathfinder failed again to find correct route.");{
			//TODO passing lanes
			return true;
			}
		}
	}
if(GetAvailableMoney()<cost+2000)  //TODO replace 2000 with real station costs
	{
	ProvideMoney();
	while(GetAvailableMoney()<cost+2000) 
		{
		Info("too expensivee, we have only " + GetAvailableMoney() + " And we need " + cost);
		rodzic.Maintenance();
		AIController.Sleep(1000);
		ProvideMoney();
		}
	}

if(!this.RailwayLinkConstruction(path)){
   Info("   But stopped by error");
  //TODO passing lanes
   return true;	  
   }

local reversed_path=Path(null, 1, 1);

	this.SignalPath(path, true);
	this.SignalPath(old_path, true);
estimated_cost=AIEngine.GetPrice(trasa.engine[0])+trasa.station_size*2*AIEngine.GetPrice(trasa.engine[1]);

if(GetAvailableMoney() <estimated_cost+2000)  //TODO zamiast 2000 koszt stacji to samo w RV
    {
	ProvideMoney();
	while(GetAvailableMoney()<estimated_cost+2000) 
		{
		Info("too expensivee, we have only " +GetAvailableMoney() + " And we need " + estimated_cost);
		rodzic.Maintenance();
		AIController.Sleep(1000);
		ProvideMoney();
		}
	}
	
local second_engine = this.BuildTrain(trasa, "smart duo");
if(second_engine != null)
	{
	if(AIVehicle.IsValidVehicle(new_engine))
		{
		AIOrder.ShareOrders(second_engine, new_engine);
		AITown.PerformTownAction(trasa.first_station.location, AITown.TOWN_ACTION_BUILD_STATUE);
		}
   else
		{
		this.TrainOrders(second_engine);
		}
   }
local max_train_count = 9;
rodzic.SetStationName(trasa.first_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
rodzic.SetStationName(trasa.second_station.location, "{"+max_train_count+"}"+"["+trasa.depot_tile+"]");
return true;
}

function SmartRailBuilder::FindPairForSmartRailRoute(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this); 
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuatorSmartRail = this.distanceBetweenIndustriesValuatorSmartRail.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuatorSmartRail, IndustryToIndustryTrainSmartRailStationAllocator, GetNiceRandomTownSmartRail, IndustryToCityTrainSmartRailStationAllocator, RailBuilder.GetTrain);
}

function SmartRailBuilder::GetNiceRandomTownSmartRail(location)
{
local town_list = AITownList();
town_list.Valuate(AITown.GetDistanceManhattanToTile, location);
town_list.KeepBelowValue(GetMaxDistanceSmartRail());
town_list.KeepAboveValue(GetMinDistanceSmartRail());
town_list.Valuate(AIBase.RandItem);
town_list.KeepTop(1);
if(town_list.Count()==0)return null;
return town_list.Begin();
}

function SmartRailBuilder::IndustryToIndustryTrainSmartRailStationAllocator(project)
{
project.station_size = 7;

local producer = project.start;
local consumer = project.end;
local cargo = project.cargo;

project.first_station.location = null; 
for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaSmartRail(producer, cargo, project.station_size);
project.second_station = this.ZnajdzStacjeKonsumentaSmartRail(consumer, cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;

return project;
}

function SmartRailBuilder::IndustryToCityTrainSmartRailStationAllocator(project)
{
project.station_size = 7;

project.first_station.location = null; 
for(; project.station_size>=this.GetMinimalStationSize(); project.station_size--)
{
project.first_station = this.ZnajdzStacjeProducentaSmartRail(project.start, project.cargo, project.station_size);
project.second_station = this.ZnajdzStacjeMiejskaSmartRail(project.end, project.cargo, project.station_size);
if(project.StationsAllocated())break;
}

project.second_station.location = project.second_station.location;
return project;
}

function SmartRailBuilder::ZnajdzStacjeMiejskaSmartRail(town, cargo, size)
{
local tile = AITown.GetLocation(town);
local list = AITileList();
local range = Sqrt(AITown.GetPopulation(town)/100) + 15;
SafeAddRectangle(list, tile, range);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.KeepAboveValue(10);
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
return this.ZnajdzStacjeSmartRail(list, size);
}

function SmartRailBuilder::ZnajdzStacjeKonsumentaSmartRail(consumer, cargo, size)
{
local list=AITileList_IndustryAccepting(consumer, 3);
list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
list.RemoveValue(0);
list.Valuate(AIMap.DistanceSquare, trasa.end_tile); //pure eyecandy (station near industry)
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);
return this.ZnajdzStacjeSmartRail(list, size);
}

function SmartRailBuilder::ZnajdzStacjeProducentaSmartRail(producer, cargo, size)
{
local list=AITileList_IndustryProducing(producer, 3);
list.Valuate(AIMap.DistanceSquare, trasa.start_tile); //pure eyecandy (station near industry)
list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_ASCENDING);
return this.ZnajdzStacjeSmartRail(list, size);
}

function SmartRailBuilder::ZnajdzStacjeSmartRail(list, length)
{
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(this.IsGreatPlaceForRailStationSmartRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(this.IsGreatPlaceForRailStationSmartRail(station, StationDirection.x_is_constant__horizontal, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.x_is_constant__horizontal;
		return returnik;
		}
	}
for(local station = list.Begin(); list.HasNext(); station = list.Next())
	{
	if(this.IsOKPlaceForRailStationSmartRail(station, StationDirection.y_is_constant__vertical, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.y_is_constant__vertical;
		return returnik;
		}
	if(this.IsOKPlaceForRailStationSmartRail(station, StationDirection.x_is_constant__horizontal, length))
		{
		local returnik = Station();
		returnik.location = station;
		returnik.direction = StationDirection.x_is_constant__horizontal;
		return returnik;
		}
	}
local returnik = Station();
returnik.location = null;
return returnik;
}

function SmartRailBuilder::IsGreatPlaceForRailStationSmartRail(station_tile, direction, length)
{
local test = AITestMode();
/* Test Mode */
if(direction == StationDirection.y_is_constant__vertical)
   {
   local tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
   local tile_b = station_tile + AIMap.GetTileIndex(length, 0);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   if(!(Utils_Tile.IsNearlyFlatTile(tile_a) && Utils_Tile.IsNearlyFlatTile(tile_b)))return false;
   
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	if ( AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW) )return true;
	return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
	}
else
   {
   local tile_a = station_tile + AIMap.GetTileIndex(0, -1);
   local tile_b = station_tile + AIMap.GetTileIndex(0, length);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   if(!(Utils_Tile.IsNearlyFlatTile(tile_a) && Utils_Tile.IsNearlyFlatTile(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	if( AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW)) return true;
	return (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH);
   }
}

function SmartRailBuilder::IsOKPlaceForRailStationSmartRail(station_tile, direction, length)
{
local test = AITestMode();
/* Test Mode */
if(direction == StationDirection.y_is_constant__vertical)
   {
   local tile_a = station_tile + AIMap.GetTileIndex(-1, 0);
   local tile_b = station_tile + AIMap.GetTileIndex(length, 0);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NE_SW, 1, length, AIStation.STATION_NEW);
	}
else
   {
   local tile_a = station_tile + AIMap.GetTileIndex(0, -1);
   local tile_b = station_tile + AIMap.GetTileIndex(0, length);
   if(!(AITile.IsBuildable(tile_a) && AITile.IsBuildable(tile_b)))return false;
   //AISign.BuildSign(tile_a, "tile_a");
   //AISign.BuildSign(tile_b, "tile_b");
	return AIRail.BuildRailStation(station_tile, AIRail.RAILTRACK_NW_SE, 1, length, AIStation.STATION_NEW);
   }
}
   
 function SmartRailBuilder::distanceBetweenIndustriesValuatorSmartRail(distance)
{
if(distance>GetMaxDistanceSmartRail())return 0;
if(distance<GetMinDistanceSmartRail()) return 0;

if(desperation>5)
   {
   if(distance>100+desperation*60)return 1;
   return 4;
   }

if(distance>200+desperation*50)return 1;
if(distance>185) return 2;
if(distance>170) return 3;
if(distance>155) return 4;
if(distance>120) return 3;
if(distance>80) return 2;
if(distance>40) return 1;
return 0;
}

function SmartRailBuilder::GetMinDistanceSmartRail()
{
return 10;
}

function SmartRailBuilder::GetMaxDistanceSmartRail()
{
if(desperation>5) return 100+desperation*75;
return 250+desperation*50;
}