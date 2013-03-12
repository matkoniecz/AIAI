function Autoreplace()
{
Info("Autoreplace started");
AutoreplaceRV();
AutoreplaceSmallPlane();
AutoreplaceBigPlane();
Info("Autoreplace list updated by Autoreplace()");
}

function AutoreplaceBigPlane()
{
local engine_list=AIEngineList(AIVehicle.VT_AIR);
engine_list.Valuate(AIEngine.GetPlaneType);
engine_list.KeepValue(AIAirport.PT_BIG_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = (AirBuilder(this, 0)).FindAircraft(AIAirport.AT_LARGE, cargo, 1, 100000000)
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function AutoreplaceSmallPlane()
{
local engine_list=AIEngineList(AIVehicle.VT_AIR);
engine_list.Valuate(AIEngine.GetPlaneType);
engine_list.KeepValue(AIAirport.PT_SMALL_PLANE);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = (AirBuilder(this, 0)).FindAircraft(AIAirport.AT_SMALL, cargo, 1, 100000000)
	  if(engine_best != null)
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}

function AutoreplaceRV()
{
local engine_list=AIEngineList(AIVehicle.VT_ROAD);
engine_list.Valuate(AIEngine.GetRoadType);
engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);

for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) //from Chopper 
   {
   local cargo_list=AICargoList();
   local cargo;
   for (cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()) //from Chopper
      {
	  if(AIEngine.CanRefitCargo(engine_existing, cargo))break;
	  }
	
   if(AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false)
      {
	  local engine_best = (RoadBuilder(this, 0)).GetReplace(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing), cargo);
	  if(engine_best != engine_existing)
	     {
		 AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
         Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
		 }
	  }
   
   }
}