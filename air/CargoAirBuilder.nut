class CargoAirBuilder extends AirBuilder
{
	trasa = null;
}

function CargoAirBuilder::IsAllowed()
{
	if(0 == AIAI.GetSetting("cargo_plane")) return false;
	return AirBuilder.IsAllowed();
}

function CargoAirBuilder::Possible()
{
	if(!this.IsAllowed()) return false;
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

	if(!trasa.OK){
		Info("Airport cargo route failed");
		return false;
		}
	else{
		Info("Airport cargo route found");
		}

	if (!AIAirport.BuildAirport(trasa.first_station.location, trasa.station_size, AIStation.STATION_NEW)) return false;
	if (!AIAirport.BuildAirport(trasa.second_station.location, trasa.station_size, AIStation.STATION_NEW)){
		AIAirport.RemoveAirport(trasa.first_station.location);
		return false;
		}
	rodzic.SetStationName(trasa.first_station.location, "");
	rodzic.SetStationName(trasa.second_station.location, "");
	for(local i=0; i<trasa.engine_count; i++){
		while(!this.BuildCargoAircraft(trasa.first_station.location, trasa.second_station.location, trasa.engine, trasa.cargo, "null")){
			Error("Cargo aircraft construction failed due to " + AIError.GetLastErrorString()+".")
			if(AIError.GetLastError()!=AIError.ERR_NOT_ENOUGH_CASH){
				return true;
				}
			rodzic.Maintenance();
			AIController.Sleep(500);
			}
		Info("We have " + i + " from " + trasa.engine_count + " aircrafts.");
		}
	return true;
}
function CargoAirBuilder::FindPair(route)
{
	local GetIndustryList = rodzic.GetIndustryList.bindenv(rodzic);
	local IsProducerOK = null;
	local IsConsumerOK = null;
	local IsConnectedIndustry = IsConnectedIndustry.bindenv(this);
	local ValuateProducer = this.ValuateProducer.bindenv(this);
	local ValuateConsumer = this.ValuateConsumer.bindenv(this);
	local distanceBetweenIndustriesValuator = this.distanceBetweenIndustriesValuator.bindenv(this);
	return FindPairWrapped(route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
	distanceBetweenIndustriesValuator, FindPairDualIndustryAllocator, GetNiceRandomTown, FindPairIndustryToTownAllocator, FindEngine);
}
