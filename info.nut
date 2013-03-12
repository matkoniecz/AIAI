class AIAI extends AIInfo {
  function GetAuthor()      { return "Kogut"; }
  function GetName()        { return "AIAI"; }
  function GetDescription() { return "Automatic Idiot AI Version iota (74). AIAI reuses code from following AIs: WrightAI, CluelessPlus, Chopper, SimpleAI, Rondje, AdmiralAI, ChooChoo and Denver & Rio Grande."; }
  function GetVersion()     { return 74; }
  function GetAPIVersion() { return "1.2"; }
  function CreateInstance() { return "AIAI"; }
  function GetShortName()   { return "AIAI"; }
  function MinVersionToLoad() { return 70; } 
  function GetDate()        { return "2012-06-17"; }
  function GetURL() {return "http://tinyurl.com/ottdaiai or bulwersator@gmail.com. Thanks! [iota (74)]";}

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
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
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
		name = "hide_ad",
		description = "hide_ad",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_BOOLEAN + CONFIG_INGAME
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

	}
}

RegisterAI(AIAI());