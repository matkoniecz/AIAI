const INFINITE_DISTANCE = 4000000;
const INFINITE_SPEED = 4000000;
//import("graph.aystar", "", 4);  - currently unused
//import("queue.binary_heap", "", 1);//################################################## <- external

import("pathfinder.road", "RoadPathFinder", 4);      //################################################## <- external
import("util.superlib", "SuperLib", 28);      //################################################## <- external

require("LIBRARY/Rail.nut");
require("LIBRARY/Helper.nut");

Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction
Road <- SuperLib.Road
Money <- SuperLib.Money
DataStore <- SuperLib.DataStore
Town <- SuperLib.Town

require("UTIL/debug.nut")

require("myAPIpatch.nut");
require("path.nut");

require("UTIL/read_save_data_from_names.nut")
require("UTIL/util.nut");
require("UTIL/util_AIAI.nut")
require("UTIL/money.nut")
require("aystar.nut");   //modified to use in passing lanes, it should be done in a other way TODO
require("strategy.nut");
require("autoreplace.nut");
require("classes_enums.nut");
require("findpair.nut");
require("Builder.nut");
require("RAIL/RailBuilder.nut");
require("ROAD/RoadBuilder.nut");
require("ROAD/BusRoadBuilder.nut");
require("ROAD/TruckRoadBuilder.nut");
require("AIR/AirBuilder.nut");
require("AIR/PAXAirBuilder.nut");
require("AIR/CargoAirBuilder.nut");