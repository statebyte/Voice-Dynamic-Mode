#if defined _vdm_core_included
 #endinput
#endif
#define _vdm_core_included

public SharedPlugin __pl_vdm_core= 
{
	name = "vdm_core",
	file = "vdm_core.smx",
	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

enum FeatureMenus
{
	VDMTYPE_MAINMENU = 0,	// Только для октрытия меню
	VDMTYPE_ADMINMENU,		// Секция админ-меню
	VDMTYPE_SETTINGSMENU	// Секция меню настроек
};

