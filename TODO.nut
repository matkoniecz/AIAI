CHANGE: clear_signs is set to false as default
FIXED: gentleSellVehicle function (everything was wrong)
FIXED: ancient bug that blocked ad (with link to this thread) is fixed 
FIXED: Lowkee33 bug (AIAI goes out of business after replacing trains.)
FIXED: crash caused by vehicle_id getting invalid halway through function
FIXED: merging 2 stations without merging :D
DONE: code translation (ZbudujKawalateczekDrogi -> BuildRoadSegment, CzyNaSprzedaz -> ForSell etc)
DONE: compat_1.0 is limited to fixing pointless change of HasNext() into !IsEnd()
DONE: desperation, GeneralInspection date is saved/loaded
DONE: AICONFIG_AI_DEVELOPER (hides debug options)
DONE: bribes
DONE: Tree planting (from AdmiralAI)
DONE: passing lanes for railways contruction
CHANGE: Both types of rail construction replaced by new (passing lanes)
SAVEGAME COMBATIBILITY: broken
KNOWN PROBLEM: Handling range for airplanes is one giant TODO, for now feature only in the trunk and without any published newgrfs
KNOWN PROBLEM: Passing lanes construction is not finished, sometimes it is possible to add more but AI is stupid and unable to do so

HasNext -> IsEnd 
class Station - multiplatforms
TODO: cargo planes reusing industry
TODO: reuse roads http://www.tt-forums.net/viewtopic.php?p=958414#p958414
TODO: $ menag during pf
TODO: sprawdziæ jak (i czy) dzia³a lista zbanowanych
TODO: foo supplies
TODO: banuj na zawsze, jesli zbanowany zezwalaj z 1%szansy, jeœli lista przelecia³a to czyœæ listê
TODO: networking
TODO: better engine choosing
TODO: better RV choosing (problem with very small)
TODO: error stats

TODO: during heavy competition (more companies that ind + towns) build statues after every connection
TODO: check during pathfinding is it still possible to have station
TODO: supplies
	- supplies - cagos accepted by raw industries
	- big penalty for normal transport
	- special transport
	- by truck, to industry serviced with profit by AIAI with statue with high rating (trains preffered?)
TODO: check jams before RV/train building
 
TODO: check cost before train replacing
TODO: remove empty railway tracks

TODO: passing lanes
TODO: dead ends for busses
TODO: handle bus queues

TODO: long term average for secondaries
TODO: bridge upgrading
TODO: allow replacing small planes by big on big airports!

TODO: 6x ciê¿szy poci¹g jeœli podjazdy s¹ pojedyñcze????
TODO: better findpair
TODO: better busses (managing & construction)
TODO: world scanner and rework main with dynamic strategy
TODO: rebridger over valleys, debridger

TODO: AIAI.GetLastError()
TODO: tourist, mail support
TODO: better RV depot placing (replace double flat by test mode)
TODO: more working depots
TODO: reuse existing roads constructed by another players
TODO: For all newly build routes, check both ways. This way, if one-way roads are build, another road is build next to it so vehicles can go back. //from admiralai
TODO: long bridges sometimes are unavailable!
TODO: helicopters
TODO: dodawanie samolotów zale¿ne od pojemnoœci
TODO: air
//lepsze wybieranie przy a8
//industry - valuate before building
//nie pierwsze lepsze tylko najlepsze, nie masowac budowy (wiek reszty) DONE?
//kasowanie nadmiaru
//sprzedawaæ samoloty z minusem w obu latach (jeœli starsze ni¿ 2 lata) DONE?

TODO: bus scanner
	- construction of 2 bus stops
	- 1 bus
	- go on route WITHOUT pathfinding
	- vehicle is lost
		- route construction is needed
	- vehicle is profitable - we parasited succesfully
	limitation: real players rarely construct intercity routes