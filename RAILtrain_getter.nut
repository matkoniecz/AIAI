class DenverAndRioGrande
{
}

function DenverAndRioGrande::SetRailType(skip) //modified
{
  local types = AIList();
  types.AddList(AIRailTypeList());
  if(types.Count() == 0)
  {
  Error("No rail types!");
    return false;
  }
	
  types.Valuate(AIRail.IsRailTypeAvailable);
  types.KeepValue(1);
  if(types.Count() == 0)
  {
  Error("No available rail types!");
  return false;
  }
  
//  types.Valuate(AIRail.GetMaxSpeed);  //TODO what with nutracks
//  types.RemoveValue(0);
//  if(types.Count() == 0)
//  {
//  Error("No usable rail types!");
//  return false;
//  }

  
for (local rail_type = types.Begin(); types.HasNext(); rail_type = types.Next())
   {
   if(skip==0)
      {
		AIRail.SetCurrentRailType(rail_type);
		//Info("Rail type selected.");
		return true;
	  }
   skip--;
   }
Error("Too many RailTypes failed");
return false;
}

function DenverAndRioGrande::FindTrain(trasa)
{
local wagon = DenverAndRioGrande.FindBestWagon(trasa.cargo)
local engine = DenverAndRioGrande.FindBestEngine(wagon, trasa.station_size, trasa.cargo);
trasa.engine = array(2);
trasa.engine[0] = engine;
trasa.engine[1] = wagon;
return trasa;
}

function DenverAndRioGrande::GetTrain(trasa)
{

for(local i = 0; DenverAndRioGrande.SetRailType(i); i++)
{
trasa = DenverAndRioGrande.FindTrain(trasa);
if(AIEngine.IsValidEngine(trasa.engine[0]) && AIEngine.IsValidEngine(trasa.engine[1])) 
   {
   //Warning("Return OK: " + trasa.engine);
   //Info("engine:" + trasa.engine[0] + "wagon:" + trasa.engine[1] )
   //Info("engine:" + AIEngine.GetName(trasa.engine[0]) + "wagon:" + AIEngine.GetName(trasa.engine[1]) )
   return trasa;
   }
}

trasa.engine = null;
//Warning("Return bad: " + trasa.engine);
//   Info("engine:" + engine + "wagon:" + wagon )
//   Info("engine:" + AIEngine.GetName(engine) + "wagon:" + AIEngine.GetName(wagon) )
return trasa;
}

function DenverAndRioGrande::FindWagons(cargoIndex)
{
    //AILog.Info("Looking for " + AICargo.GetCargoLabel(cargoIndex) + " wagons.");
    local wagons = AIEngineList(AIVehicle.VT_RAIL);
    wagons.Valuate(AIEngine.IsWagon);
    wagons.RemoveValue(0);
    //print(wagons.Count() + " wagons." );
    wagons.Valuate(AIEngine.IsValidEngine);
    wagons.RemoveValue(0);
    //print(wagons.Count() + " Valid and buildable." );
    wagons.Valuate(AIEngine.CanRefitCargo, cargoIndex);
    wagons.RemoveValue(0);
    //print(wagons.Count() + " Can refit to cargo." );    
    wagons.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
    wagons.RemoveValue(0);
    //print(wagons.Count() + " Can run on rail." ); 
    //wagons.AddList(nonRefitWagons);
    if(wagons.Count() == 0)
    {
      AILog.Warning("Warning, no wagons can pull or be refitted to this cargo on the current track.");
    }
    return wagons;
}

function DenverAndRioGrande::WagonValuator(engineId)
{
  return  AIEngine.GetCapacity(engineId) * AIEngine.GetMaxSpeed(engineId);
}

function DenverAndRioGrande::FindBestWagon(cargoIndex)
{   
    local wagons = DenverAndRioGrande.FindWagons(cargoIndex);
    wagons.Valuate(DenverAndRioGrande.WagonValuator);
    return wagons.Begin();
}

function DenverAndRioGrande::FindBestEngine(wagonId, trainsize, cargoId)
{
    
  local minHP = 175 * trainsize;
  
  local speed = AIEngine.GetMaxSpeed(wagonId);
  if(speed == 0) {speed = 2500;}
  local engines = AIEngineList(AIVehicle.VT_RAIL);
  engines.Valuate(AIEngine.IsWagon);
  engines.RemoveValue(1);
  
  engines.Valuate(AIEngine.IsValidEngine);
  engines.RemoveValue(0);
  engines.Valuate(AIEngine.CanPullCargo, cargoId);
  engines.RemoveValue(0);
  engines.Valuate(AIEngine.HasPowerOnRail, AIRail.GetCurrentRailType());
  engines.RemoveValue(0);
  //engines.Valuate(AIEngine.TrainCanRunOnRail, AIRail.GetCurrentRailType()); TODO activate it
  //engines.RemoveValue(0);
  
  engines.Valuate(AIEngine.GetPower);
  
  engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
  if(engines.GetValue(engines.Begin()) < minHP ) //no engine can pull the wagon at it's top speed.
  {
   //print("No engine has enough horsepower to pull all the wagons well.");
  }
  else
  {
    engines.RemoveBelowValue(minHP);
  }
  
  
  engines.Valuate(AIEngine.GetMaxSpeed);
  engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
  
  if(engines.GetValue(engines.Begin()) < speed ) //no engine can pull the wagon at it's top speed.
  {
   //AILog.Info("No engine has top speed of wagon. Checking Fastest.");
   //AILog.Info("The fastest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
   //Util.GetMaxLoan(); TODO DO STH WITH IT
   local cash = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
   if(cash > AIEngine.GetPrice(engines.Begin()) * 2 || AIVehicleList().Count() > 10)//if there are 10 trains, just return the best one and let it fail.
   {
    return engines.Begin();
   }
   else
   {
    //AILog.Info("The company is poor. Picking a slower, cheaper engine.");
    engines.Valuate(AIEngine.GetPrice);
    engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
    //AILog.Info("The Cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'  is '" + AIEngine.GetName(engines.Begin()) +"'" );
    return engines.Begin();
   }
  }
  
  engines.RemoveBelowValue(speed);
  engines.Valuate(AIEngine.GetPrice);
  engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
  
  //AILog.Info("The cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
  return engines.Begin();
  
}
