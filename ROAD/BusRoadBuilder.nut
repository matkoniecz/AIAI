class BusRoadBuilder extends RoadBuilder
{
}

function BusRoadBuilder::Possible()
{
	if(!IsAllowedBus()) return false;
	Info("estimated cost of a bus connection: " + this.cost + " /  available funds: " + GetAvailableMoney());
	return this.cost<GetAvailableMoney();
}

function BusRoadBuilder::FindBusPair()
{
	trasa.start = GetRatherBigRandomTown();
	trasa.end = GetNiceRandomTown(AITown.GetLocation(trasa.start))
	trasa.cargo = Helper.GetPAXCargo();

	if(trasa.end == null) return false;
	Info("From " + AITown.GetName(trasa.start) + "  to " +  AITown.GetName(trasa.end) );
	trasa.cargo = Helper.GetPAXCargo();

	trasa = BusStationAllocator(trasa);

	if(!((trasa.first_station.location==null)||(trasa.second_station.location==null))){
		trasa.start_tile = AITown.GetLocation(trasa.start);
		trasa.end_tile = AITown.GetLocation(trasa.end);
		trasa.production = min(AITile.GetCargoAcceptance(trasa.first_station.location, trasa.cargo, 1, 1, 3), AITile.GetCargoAcceptance(trasa.second_station.location, 	trasa.cargo, 1, 1, 3));
		trasa.type = 2;	
	
		trasa = FindRVForFindPair(trasa);
		if(trasa.engine == null) return false;
		return true;
	}
	return false;
}

function BusRoadBuilder::Go()
{
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	trasa = Route();

	for(local i=0; i<retry_limit; i++){
		Info("Scanning for bus route");
		if(!this.FindBusPair()){
			Info("Nothing found!");
			cost = 0;
			return false;
		}
	Info("Scanning for bus route completed [ " + desperation + " ] ");
	if(this.PrepareRoute())
      {
	  Info("   Contruction started on correct route.");
	  if(this.ConstructionOfRVRoute(AIRoad.ROADVEHTYPE_BUS))
	  return true;
	  else trasa.forbidden.AddItem(trasa.start, 0);
	  }
   else
      {
	  if(trasa.start==null) return false;
	  else trasa.forbidden.AddItem(trasa.start, 0);
	  }
   }
return false;
}