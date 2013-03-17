class AIAI extends AIInfo {
  function GetAuthor()      { return "Kogut"; }
  function GetName()        { return "AIAI"; }
  function GetVersion()     { return 87; }
  function GetDescription() { return "Automatic Idiot AI Version iota (" + GetVersion() + "). AIAI reuses code from following AIs: WrightAI, CluelessPlus, Chopper, SimpleAI, Rondje, AdmiralAI, ChooChoo and Denver & Rio Grande."; }
  function GetAPIVersion()  { return "1.3"; }
  function CreateInstance() { return "AIAI"; }
  function GetShortName()   { return "AIAI"; }
  function MinVersionToLoad() { return 87; } 
  function GetDate()        { return "2012-10-1"; }
  function GetURL() {return "http://tinyurl.com/ottdaiai (redirects to http://www.tt-forums.net/viewtopic.php?f=65&t=47298) or bulwersator@gmail.com. Thanks! [iota (" + GetVersion() +")]";}

    function GetParameters() {
	////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	/////////////////////Exporting hardcoded values/////////////////////
	////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////

	AddSetting( {
		name = "max_train_station_length",
		description = "max_train_station_length",
		easy_value = 7,
		medium_value = 7,
		hard_value = 7,
		custom_value = 7,
		min_value = 0,
		max_value = 1000,
		flags = CONFIG_DEVELOPER
	});

	AddSetting( {
		name = "max_train_station_platform_count_city_start",
		description = "max_train_station_platform_count_city_start",
		easy_value = 2,
		medium_value = 2,
		hard_value = 2,
		custom_value = 2,
		min_value = 0,
		max_value = 1000,
		flags = CONFIG_DEVELOPER + CONFIG_INGAME
	});

	AddSetting( {
		name = "max_train_station_platform_count_city_end",
		description = "max_train_station_platform_count_city_end",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		min_value = 0,
		max_value = 1000,
		flags = CONFIG_DEVELOPER + CONFIG_INGAME
	});

	AddSetting( {
		name = "max_train_station_platform_count_end_industry",
		description = "max_train_station_platform_count_end_industry",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		min_value = 0,
		max_value = 1000,
		flags = CONFIG_DEVELOPER + CONFIG_INGAME
	});

	AddSetting( {
		name = "max_train_station_platform_count_start_industry",
		description = "max_train_station_platform_count_start_industry",
		easy_value = 2,
		medium_value = 2,
		hard_value = 2,
		custom_value = 2,
		min_value = 0,
		max_value = 1000,
		flags = CONFIG_DEVELOPER + CONFIG_INGAME
	});
	AddSetting( {
		name = "no_road_cost",
		description = "no_road_cost",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		min_value = 0,
		max_value = 1000,
		flags = CONFIG_INGAME + CONFIG_DEVELOPER
	});
	}

    function GetSettings() {
	AddSetting( {
		name = "use_trucks",
		description = "Trucks allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "use_busses",
		description = "Busses allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "PAX_plane",
		description = "PAX planes allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "cargo_plane",
		description = "Cargo planes allowed",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "use_freight_trains",
		description = "Cargo trains allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "debug_signs",
		description = "debug_signs allowed",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "debug_signs_about_failed_railway_contruction",
		description = "debug_signs_about_failed_railway_contruction allowed",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "debug_signs_about_adding_road_vehicles",
		description = "debug_signs_about_adding_road_vehicles allowed",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		medium_value = 1,
		name = "clear_signs",
		description = "Clear company signs",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "try_networking",
		description = "dev code",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "use_patch_code",
		description = "use_patch_code",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "use_trunk_code",
		description = "use_trunk_code",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "debug_signs_for_airports_load",
		description = "Build debug signs for airports load",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "other_debug_signs",
		description = "Build other debug signs",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "log_rail_pathfinding_time",
		description = "log rail pathfinding time",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "hide_contact_information",
		description = "hide contact information (http://tinyurl.com/ottdaiai or bulwersator@gmail.com)",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "pause_game_on_calling_abort_funtion_and_activated_ai_developer_tools",
		description = "pause_game_on_calling_abort_funtion_and_activated_ai_developer_tools",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "crash_AI_in_strange_situations",
		description = "crash_AI_in_strange_situations",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME + CONFIG_DEVELOPER
	});
	AddSetting( {
		name = "show_pathfinding",
		description = "show pathfinding (using 737474828920202 signs)",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	AddSetting( {
		name = "show_full_pathfinding",
		description = "show full pathfinding (using 737474828273874374374747920202 signs)",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
	});
	
	GetParameters();
	}
}

RegisterAI(AIAI());