class CargoAirBuilder extends AirBuilder
{
trasa = null;
}

function CargoAirBuilder::Possible()
{
if(!IsAllowedCargoPlane())return false;
return this.cost<GetAvailableMoney();
}

function CargoAirBuilder::Go()
{
ProvideMoney();

Info("Trying to build an airport route from industry");

trasa = Route();
trasa.budget = GetAvailableMoney();
trasa = this.FindPair(trasa);
cost = trasa.demand;

Info("Trying to build an airport route from industry - scanning completed");

if(!trasa.OK) 
   {
   Info("Airport cargo route failed");
   return false;
   }
else
   {
   Info("Airport cargo route found");
   }

if (!AIAirport.BuildAirport(trasa.first_station.location, trasa.station_size, AIStation.STATION_NEW)) 
	{
	return false;
	}
else
   {
   AIAI.Info("Airport constructed");
   }

if (!AIAirport.BuildAirport(trasa.end_station, trasa.station_size, AIStation.STATION_NEW)) 
	{
	return false;
	}
else
   {
   AIAI.Info("Airport constructed");
   //TODO - usun pierwsze
   }
	
	for(local i=0; i<trasa.engine_count; i++) 
	   {
	   while(!this.BuildCargoAircraft(trasa.first_station.location, trasa.end_station, trasa.engine, trasa.cargo, "null"))
          {
		  AIAI.Info("Next try");
		  Error("Aircraft construction failed due to " + AIError.GetLastErrorString()+".")
		  if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH) 
		     {
			 return true;
			 }
 		  rodzic.Konserwuj();
		  AIController.Sleep(1000);
		  }
       //AIAI.Info("We have " + i + " from " + licznik + " aircrafts.");
  	   }
return true;
}
function CargoAirBuilder::FindPair(route)
{
local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
local IsProducerOK = null;
local IsConsumerOK = null;
local IsConnectedIndustry = rodzic.IsConnectedIndustry.bindenv(rodzic);
local ValuateProducer = this.ValuateProducer.bindenv(this);
local ValuateConsumer = this.ValuateConsumer.bindenv(this);
local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, FindPairDualIndustryAllocator, GetNiceRandomTown, FindPairIndustryToTownAllocator, FindEngine);
}

