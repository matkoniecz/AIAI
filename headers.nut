const INFINITE = 1000000000;
const INFINITE_DISTANCE = 4000000;
const INFINITE_SPEED = 4000000;

//import("graph.aystar", "", 4);  - currently unused
//import("queue.binary_heap", "", 1);//################################################## <- external

import("pathfinder.road", "RoadPathFinder", 4);      //################################################## <- external
import("util.superlib", "SuperLib", 28);      //################################################## <- external

require("library/Rail.nut");
require("library/Helper.nut");

Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction
Road <- SuperLib.Road
Money <- SuperLib.Money
DataStore <- SuperLib.DataStore
Town <- SuperLib.Town

require("util/debug.nut")

require("myAPIpatch.nut");
require("path.nut");

require("util/read_save_data_from_names.nut")
require("util/util.nut");
require("util/util_AIAI.nut")
require("util/money.nut")
require("aystar.nut");   //modified to use in passing lanes, it should be done in a other way TODO
require("strategy.nut");
require("autoreplace.nut");
require("classes_enums.nut");
require("findpair.nut");
require("Builder.nut");
require("rail/RailBuilder.nut");
require("road/RoadBuilder.nut");
require("road/BusRoadBuilder.nut");
require("road/TruckRoadBuilder.nut");
require("air/AirBuilder.nut");
require("air/PAXAirBuilder.nut");
require("air/CargoAirBuilder.nut");