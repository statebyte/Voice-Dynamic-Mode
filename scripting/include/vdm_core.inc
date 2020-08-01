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

enum VoiceMode 
{
	Mode_NoVoice = 0, // Голосовой чат отключён
	Mode_Alive_Death_TeamOnly, //
	Mode_Alive_Death_TeamsOnly,
	Mode_TeamOnly,
	Mode_AliveOnly,
	Mode_AliveOnly,
	Mode_AliveToDeathTeams,
	Mode_AllTalk,
	Mode_FullAllTalk
};

enum FeatureMenus
{
	VDMTYPE_MAINMENU = 0,	// Только для октрытия меню
	VDMTYPE_ADMINMENU,		// Секция админ-меню
	VDMTYPE_SETTINGSMENU	// Секция меню настроек
};

/* Установить голосовой режим



@return		true - режим был изменён
			false - режим не поменялся (приоритет)
*/
public bool VDM_SetVoiceMode(VoiceMode iMode, int iPluginPriority = 0);