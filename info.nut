class AIAI extends AIInfo {
  function GetAuthor()      { return "Kogut"; }
  function GetName()        { return "AIAI"; }
  function GetDescription() { return "Automatic Idiot AI Version eta (49). AIAI reuses code from following AIs: WrightAI, CluelessPlus, Chopper, SimpleAI, Rondje, AdmiralAI, ChooChoo and Denver & Rio Grande."; }
  function GetVersion()     { return 49; }
  function GetAPIVersion() { return "1.0"; }
  function GetDate()        { return "2011-10-23"; }
  function CreateInstance() { return "AIAI"; }
  function GetShortName()   { return "AIAI"; }
  function MinVersionToLoad() { return 49; } 
  function GetURL() {return "http://tinyurl.com/ottdaiai or bulwersator@gmail.com. Thanks! [eta (49)]";}

	function GetSettings() {

	AddSetting( {
		name = "use_trucks",
		description = "Trucks allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "use_busses",
		description = "Busses allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});
	
	AddSetting( {
		name = "PAX_plane",
		description = "PAX planes allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "cargo_plane",
		description = "Cargo planes allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "use_stupid_freight_trains",
		description = "Stupid cargo trains allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "use_smart_freight_trains",
		description = "Smart cargo trains allowed",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "clear_signs",
		description = "Clear company signs",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "try_networking",
		description = "dev code",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "use_patch_code",
		description = "use_patch_code",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});
	
	AddSetting( {
		name = "use_trunk_code",
		description = "use_trunk_code",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});
	
	AddSetting( {
		name = "debug_signs_for_airports_load",
		description = "Build debug signs for airports load",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});

	AddSetting( {
		name = "other_debug_signs",
		description = "Build other debug signs",
		easy_value = 0,
		medium_value = 0,
		hard_value = 0,
		custom_value = 0,
		flags = AICONFIG_BOOLEAN + AICONFIG_INGAME
	});
	}
}

RegisterAI(AIAI());