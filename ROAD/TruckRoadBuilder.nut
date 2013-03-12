class TruckRoadBuilder extends RoadBuilder
{
}

function TruckRoadBuilder::Possible()
{
if(!IsAllowedTruck()) return false;
Warning("estimated cost of a truck connection: " + this.cost + " /  available funds: " + GetAvailableMoney());
return this.cost<GetAvailableMoney();
}

function TruckRoadBuilder::ValuateProducer(ID, cargo)
{
if(AIRoad.GetRoadVehicleTypeForCargo(cargo) != AIRoad.ROADVEHTYPE_TRUCK) return 0;
return RoadBuilder.ValuateProducer(ID, cargo);
}

function TruckRoadBuilder::FindPair(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = IsConnectedIndustry.bindenv(this);
local ValuateProducer = this.ValuateProducer.bindenv(this);
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, IndustryToIndustryTruckStationAllocator, GetNiceRandomTown, IndustryToCityTruckStationAllocator, WybierzRVForFindPair);
}

function TruckRoadBuilder::Go()
{
AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
trasa = Route();

for(local i=0; i<retry_limit; i++)
   {
   Info("Scanning for truck route");
   trasa = this.FindPair(trasa); 
   if(!trasa.OK) 
      {
      Info("Nothing found!");
      cost = 0;
      return false;
      }

   Info("Scanning for truck route completed [ " + desperation + " ] cargo: " + AICargo.GetCargoLabel(trasa.cargo) + " Source: " + AIIndustry.GetName(trasa.start));
   if(this.PrepareRoute())
      {
	  Info("   Contruction started on correct route.");
	  if(this.ConstructionOfTruckRoute())
	  return true;
	  else trasa.forbidden.AddItem(trasa.start, 0);
	  }
   else
      {
	  Info("   Route preaparings failed.");	  
	  if(trasa.start==null) return false;
	  else trasa.forbidden.AddItem(trasa.start, 0);
	  }
   }
return false;
}

function TruckRoadBuilder::ConstructionOfTruckRoute()
{
if(!this.BuildRVStation(AIRoad.ROADVEHTYPE_TRUCK))
   {
   trasa.forbidden.AddItem(trasa.start, 0);
   return false;	  
   }
return this.ConstructionOfRVRoute();
}

