function KRAI::RawVehicle(vehicle)
{
return AIVehicle.GetName(vehicle)[0]=='R';
}

function KRAI::sprawdz_droge(path)
{
local costs = AIAccounting();
costs.ResetCosts ();

 /* Exec Mode */
{
local test = AITestMode();
/* Test Mode */

if(path==null)return false;
while (path != null) {
  local par = path.GetParent();
  if (par != null) {
    local last_node = path.GetTile();
	if(!this.ZbudujKawalateczekDrogi(path.GetTile(),  par.GetTile(), 0))
	    {
		AILog.Error(AIError.GetLastErrorString());
		return null;
		}
  }
  path = par;
}

}
/* Exec Mode */
//print("Costs for route is: " + costs.GetCosts());
return costs.GetCosts();
}

function KRAI::zbuduj_droge(path)
{
if(path==null)return false;
while (path != null) {
  local par = path.GetParent();
  if (par != null) {
    local last_node = path.GetTile();
	if(!this.ZbudujKawalateczekDrogi(path.GetTile(),  par.GetTile(), 0))
	    {
		return false;
		}
  }
  path = par;
}
return true;
}

function KRAI::CircleAroundStation(tile_s, tile_e, tile_i)
{
local pathfinder = CustomPathfinder();
pathfinder.CircleAroundStation();
local t1=array(1);
local t2=array(1);
local i=array(1);
t1[0]=tile_s;
t2[0]=tile_e;
i[0]=tile_i;
pathfinder.InitializePath(t1, t2, i);

local path = false;
while (path == false) 
  {
  path = pathfinder.FindPath(1000);

  if(path==null)return false;

  rodzic.Konserwuj();

  AIController.Sleep(1);
  }

return this.zbuduj_droge(path);
}

function KRAI::IsItNeededToAddRVToThatStation(aktualna, cargo)
{
return AIStation.GetCargoWaiting(aktualna, cargo)>50 || (AIStation.GetCargoRating(aktualna, cargo)<40&&AIStation.GetCargoWaiting(aktualna, cargo)>0) ;
}
function KRAI::Uzupelnij()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
   {
   local station_list=AIStationList(AIStation.STATION_TRUCK_STOP);
   for (local aktualna = station_list.Begin(); station_list.HasNext(); aktualna = station_list.Next()) //from Chopper
	  {
	  if(NajmlodszyPojazd(aktualna)>20) //nie dodawaæ masowo
	  if(IsItNeededToAddRVToThatStation(aktualna, cargo))
	  {
	     local vehicle_list=AIVehicleList_Station(aktualna);
		 
		 vehicle_list.Valuate(AIBase.RandItem);
		 vehicle_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
		 local original=vehicle_list.Begin();
		 
		 if(AIVehicle.GetProfitLastYear(original)<0)continue;

		 local end = AIOrder.GetOrderDestination(original, AIOrder.GetOrderCount(original)-2);

	     if(AITile.GetCargoAcceptance (end, cargo, 1, 1, 4)==0)
		    {
			if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(end, "ACCEPTATION STOPPED");
			continue;
			}
		 if(this.RawVehicle(original)) 
		    {
			if(this.copyVehicle(original, cargo )) ile++;
			}
		 else 
		    {
			if(AIStation.GetCargoWaiting(aktualna, cargo)>150 || (AIStation.GetCargoRating(aktualna, cargo)<40&&AIStation.GetCargoWaiting(aktualna, cargo)>0)) 
			   {
			   if(this.copyVehicle(original, cargo)) ile++;
			   }
			}
		}
	  }
   }
return ile;
}

function KRAI::copyVehicle(main_vehicle_id, cargo)
{
if(AIVehicle.IsValidVehicle(main_vehicle_id)==false)return false;
local depot_tile = GetDepot(main_vehicle_id);

local speed = AIEngine.GetMaxSpeed(this.WybierzRV(cargo));
local distance = AIMap.DistanceManhattan(GetLoadStation(main_vehicle_id), GetUnLoadStation(main_vehicle_id));

//OPTION
//1 na tile przy 25 km/h

local maksymalnie=distance*50/(speed+10);
//
local station_tile = GetLoadStation(main_vehicle_id);
local station_id = AIStation.GetStationID(station_tile);
local list = AIVehicleList_Station(station_id);   	
local ile = list.Count();

//this.Info("Ile: "+ile+" na " + maksymalnie);

if(ile<maksymalnie)
   {
   local vehicle_id = AIVehicle.CloneVehicle(depot_tile, main_vehicle_id, true);
   if(AIVehicle.IsValidVehicle(vehicle_id))
      {
 	  AIVehicle.StartStopVehicle (vehicle_id);

	  local string;
	  //Warning(AIVehicle.GetName(main_vehicle_id) +" -X- " + AIVehicle.GetName(main_vehicle_id)[0]);
	  if(RawVehicle(main_vehicle_id)) string = "Raw cargo ";
	  else string = "Processed cargo"; 
	  local i = AIVehicleList().Count();
	  for(;!AIVehicle.SetName(vehicle_id, string + " #" + i); i++) ; //Error(AIError.GetLastErrorString());
      return true;
	  }
   }   
return false;
}

function KRAI::UsunNadmiarowePojazdy()
{
local ile=0;
local cargo_list = AICargoList();

local station_list = AIStationList(AIStation.STATION_TRUCK_STOP);
for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next()) //from Chopper 
   {
   if(NajmlodszyPojazd(station)<150)continue;
   local vehicle_list = AIVehicleList_Station(station);
   if(vehicle_list.Count()==0)continue;
   local counter=0;
   local cargo;
	
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper 
      {
	  if(AIVehicle.GetCapacity (vehicle_list.Begin(), cargo)>0)
	      {
		  break;
		  }
	  }
	
	local czy_load=vehicle_list.Begin();
	local station_id = AIStation.GetStationID(GetLoadStation(czy_load));

   //this.Info("Station with " + AIStation.GetCargoWaiting(station, cargo) + " of " + AICargo.GetCargoLabel(cargo));
	
   if(station==station_id)	
   if(!IsItNeededToAddRVToThatStation(station, cargo))
      {   
	  for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next()) //from Chopper 
       {
	   if(AIVehicle.GetCargoLoad (vehicle, cargo)==0)
	   if(AIVehicle.GetAge(vehicle)>60)
	   if(!rodzic.CzyNaSprzedaz(vehicle))
	   if(AIStation.GetDistanceManhattanToTile(station, AIVehicle.GetLocation(vehicle))<=2) //OPTION
	      {
    	  //this.Info(AIVehicle.GetName(vehicle)+" ***"+AIStation.GetDistanceManhattanToTile (station, AIVehicle.GetLocation(vehicle))+"*** <"+counter);
		  counter++;
		  
		  if(AIVehicle.GetCurrentSpeed(vehicle)<20)counter++;
		  if(AIVehicle.GetCurrentSpeed(vehicle)>40)counter--;
		  
		  if(counter>5) //OPTION
	         {
		     ile++;
		     rodzic.sellVehicle(vehicle, "kolejkowicze");
		     }
		  }
	   }
	  }
   }

return ile;
}

function KRAI::ZbudujKawalateczekDrogi(path, par, depth)
{
if(depth>=6)
    {
	this.Info("Construction terminated! "+AIError.GetLastErrorString()); 
	if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
 	return false;
    }
local rezultat;
if (AIMap.DistanceManhattan(path, par) == 1 ) 
   {
   rezultat = AIRoad.BuildRoad(path, par);
   }
else 
   {
   /* Build a bridge or tunnel. */
   if (!AIBridge.IsBridgeTile(path) && !AITunnel.IsTunnelTile(path)) 
      {
      /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
      if (AIRoad.IsRoadTile(path)) AITile.DemolishTile(path);
      
	  if (AITunnel.GetOtherTunnelEnd(path) == par) 
	     {
		 rezultat = AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path);
		 } 
      else 
	     {
         local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path, par) + 1);
         bridge_list.Valuate(AIBridge.GetMaxSpeed);
         bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
         rezultat = AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path, par);
        }
      }
    }
	
if(!rezultat)
   {
   local error=AIError.GetLastError();
   if(error==AIError.ERR_ALREADY_BUILT)return true;
   if(error==AIError.ERR_VEHICLE_IN_THE_WAY)
   {
   AIController.Sleep(20);
   return this.ZbudujKawalateczekDrogi(path, par, depth+1);
   }
   this.Info("Construction terminated! "+AIError.GetLastErrorString()); 
   if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(path, "stad" + depth+AIError.GetLastErrorString());
   return false;
   }
return true;
}


