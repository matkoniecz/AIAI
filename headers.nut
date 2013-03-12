const INFINITE_DISTANCE = 4000000;

import("util.superlib", "SuperLib", 24);
Helper <- SuperLib.Helper
Tile <- SuperLib.Tile
Direction <- SuperLib.Direction
Road <- SuperLib.Road
Money <- SuperLib.Money

require("myAPIpatch.nut");
require("path.nut");

require("UTIL/util.nut");
require("UTIL/util_is_allowed.nut");
require("UTIL/UTILtile.nut");
require("UTIL/util_AIAI.nut")
require("aystar.nut");
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