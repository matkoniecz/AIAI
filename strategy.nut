function strategyGenerator()
{
return alfa();
}

function beta()
{
local builders = array(9);
local new;

new = PAXAirBuilder(this, 0);
builders[0] = new;

builders[1] = null;

builders[2] = null; 

new = TruckRoadBuilder(this, 0);
new.pathfinding_time_limit=10;
new.retry_limit=2;
builders[3] = new; 

new = StupidRailBuilder(this, 0);
new.pathfinding_time_limit=3;
new.retry_limit=3;
builders[4] = new; 

new = BusRoadBuilder(this, 0);
new.pathfinding_time_limit=10;
new.retry_limit=1;
builders[5] = new; 

new = CargoAirBuilder(this, 0);
builders[6] = new;

builders[7] = null; 

new = StupidRailBuilder(this, 0);
new.pathfinding_time_limit=10;
new.retry_limit=3;
builders[8] = new; 

return builders;
}

function alfa()
{
local builders = array(6);
local new;

new = PAXAirBuilder(this, 0);
builders[0] = new;

new = StupidRailBuilder(this, 0);
new.pathfinding_time_limit=20;
new.retry_limit=1;
builders[1] = new; 

builders[2] = null; 

new = TruckRoadBuilder(this, 0);
new.pathfinding_time_limit=10;
new.retry_limit=2;
builders[3] = new; 

new = BusRoadBuilder(this, 0);
new.pathfinding_time_limit=10;
new.retry_limit=1;
builders[4] = new; 

new = CargoAirBuilder(this, 0);
builders[5] = new;

return builders;
}