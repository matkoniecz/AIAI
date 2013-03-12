function DefaultIsConsumerOK(industry_id)
{
if(AIIndustry.IsValidIndustry(industry_id)==false) //industry closed during preprocessing
   {
   return false;
   }
return true;
}

function DefaultIsProducerOK(industry_id)
{
local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(industry_id));
if(cargo_list==null) return false;
if(cargo_list.Count()==0) return false;
if(AIIndustry.IsValidIndustry(industry_id)==false) //industry closed during preprocessing
   {
   return false;
   }
return true;
}

function FindPairWrapped
(traska,
GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, CityStationAllocator, FindEngine)
{
if(IsProducerOK == null) IsProducerOK = DefaultIsProducerOK;
if(IsConsumerOK == null) IsConsumerOK = DefaultIsConsumerOK;
return FindPairDeepWrapped
(traska,
GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, CityStationAllocator, FindEngine);
}

function FindPairDeepWrapped
(traska,
GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, ToCityStationAllocator, FindEngine)
{
local industry_list = GetIndustryList();
local choise = Route();
Info("Industry list count: " + industry_list.Count());
local best=0;
local new;

for (traska.start = industry_list.Begin(); industry_list.HasNext(); traska.start = industry_list.Next()) //from Chopper
	{
	if(IsProducerOK(traska.start)==false)continue;
	if(traska.forbidden.HasItem(traska.start))continue;
	local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(traska.start));
	for (traska.cargo = cargo_list.Begin(); cargo_list.HasNext(); traska.cargo = cargo_list.Next())
	{
	traska.production = AIIndustry.GetLastMonthProduction(traska.start, traska.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (traska.start, traska.cargo))/100;

	if(IsConnectedIndustry(traska.start, traska.cargo))continue;
   
	local industry_list_accepting_current_cargo = rodzic.GetIndustryList_CargoAccepting(traska.cargo);
	local base = ValuateProducer(traska.start, traska.cargo);
	if(industry_list_accepting_current_cargo.Count()>0){
	for(traska.end = industry_list_accepting_current_cargo.Begin(); industry_list_accepting_current_cargo.HasNext(); traska.end = industry_list_accepting_current_cargo.Next())
		{
		if(traska.forbidden.HasItem(traska.end))continue;
		if(!IsConsumerOK(traska.end))continue; 
		
	    new = ValuateConsumer(traska.end, traska.cargo, base)	
		local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(traska.end), AIIndustry.GetLocation(traska.start)); 
		new*= distanceBetweenIndustriesValuator(distance); 
		if(AITile.GetCargoAcceptance (AIIndustry.GetLocation(traska.end), traska.cargo, 1, 1, 4)==0){
			  if(AIAI.GetSetting("other_debug_signs"))Helper.SetSign(AIIndustry.GetLocation(traska.end), AICargo.GetCargoLabel(traska.cargo) + "refused here");
			  new=0;
			  }
		if(new>best){
			traska.start_tile = AIIndustry.GetLocation(traska.start);
			traska.end_tile = AIIndustry.GetLocation(traska.end);
			traska = DualIndustryStationAllocator(traska);
			if(traska.StationsAllocated()){
				traska = FindEngine(traska);
				if(traska.engine != null){
					best = new;
					choise.start_tile = traska.start_tile;
					choise.end_tile = traska.end_tile;
					choise = clone traska;
					choise.first_station = clone traska.first_station;
					choise.second_station = clone traska.second_station;
					choise.first_station.is_city = false;
					choise.second_station.is_city = false;
					choise.track_type = traska.track_type;
					//Info(choise.track_type)
					}
				}
			}
		}
	}
	else {
	   traska.end = GetNiceTownForMe(AIIndustry.GetLocation(traska.start)); 
	   if(traska.end == null)continue;
	   local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(traska.end), AIIndustry.GetLocation(traska.start));
	   new=base;
	   new*= distanceBetweenIndustriesValuator(distance);
	   /*if(AIIndustry.GetStockpiledCargo(x, traska.cargo)==0)*/ new*=2;
		if(new>best){
	        //Info("There is no industrial acceptor for " + AIIndustry.GetName(traska.start) + " . We will try send to " + AITown.GetName(traska.end));
			traska.start_tile = AIIndustry.GetLocation(traska.start);
			traska.end_tile = AITown.GetLocation(traska.end);
			traska = ToCityStationAllocator(traska)
			if(traska.StationsAllocated()){
				traska = FindEngine(traska);
				if(traska.engine != null){
					best = new;
					choise.start_tile = traska.start_tile;
					choise.end_tile = traska.end_tile;
					choise = clone traska;
					choise.first_station = clone traska.first_station;
					choise.second_station = clone traska.second_station;
					choise.start_tile = AIIndustry.GetLocation(traska.start);
					choise.end_tile = AITown.GetLocation(traska.end);
					choise.first_station.is_city = false;
					choise.second_station.is_city = true;
					}
				}
			}
		}
	}
	}
NewLine();
//Info("(" + best + " points)");

if(best==0){
   traska.OK=false;
   return traska;
   }
choise.OK=true;
if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(choise.start))) choise.type=1;
else choise.type=0;
choise.Print();
return choise;
}