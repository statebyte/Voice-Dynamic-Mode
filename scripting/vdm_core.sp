#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <csgo_colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

/**
* ----------------------------- INFO ---------------------------------
* Full name:        [Voice Dynamic Mode] Core
* Support Games:    CS:GO ONLY
* Author:           FIVE (Discord: FIVE#8169)
* Source:           https://github.com/theelsaud/Voice-Dynamic-Mode
* Support:          https://discord.gg/ajW69wN
* Official theme:   http://hlmod.ru
* License:          GNU General Public License v3.0
*
* -------------------------- CHANGELOGS ------------------------------
* v1.0 - Release
* v2.0 - Added API structure
* ----------------------------- TODO ---------------------------------
* - Create modules
*/

#define			VDM_VERSION         "2.0 D" // D - Developer Preview | B - BETA | R - RELEASE
#define 		VDM_INT_VERSION 	020000
#define			DEBUG_MODE 			0

#define			MAX_MODES           8
#define			MAX_PLAYERMODES     4
#define			PATH_TO_CONFIG      "configs/vdm_core.ini"
#define			PATH_TO_LOGS        "logs/vdm_core.log"
#define			RELOAD_COMMAND      "sm_vdm_reload"
#define			DUMP_COMMAND      	"sm_vdm_dump"

#if DEBUG_MODE == 1
	#define VDM_Debug(%0)		LogToFile(g_sPathLogs, %0);
#else
	#define VDM_Debug(%0)
#endif


ConVar			g_hCvar1,
				g_hCvar2,
				g_hCvar3,
				g_hCvar4,
				g_hCvar5,
				g_hCvar6,
				g_hCvar7;

int				g_iMode, // Текущий режим
				g_iMainMode, // Основной режим (может быть изменён)
				g_iDefaultMode, // Стандартный основной режим (изменяется только конфигом)
				g_iLastMode, // Предыдущий режим
				g_iLastPluginPriority, // Предыдущий приоритет выставленный модулем
				g_iChangeDynamicMode,
				g_iTalkAfterDyingTime;

bool			g_bCoreIsLoaded = false,
				g_bHookCvars,
				g_bBlockEvents,
				g_bLogs,
				g_bTalkOnWarmup;

char			g_sPathLogs[PLATFORM_MAX_PATH], g_sAdminFlag[1];

enum struct Player
{
	int 	iClient;
	int 	iPlayerMode;
	int		iLastPluginPriority;
	bool 	bMenuIsOpen;
	int 	iMenuType;
	bool	bLastAdminMenu;

	bool MenuIsOpen()
	{
		return this.bMenuIsOpen && GetClientMenu(this.iClient) == MenuSource_Normal;
	}

	void ClearData()
	{
		this.iClient = -1;
		this.iPlayerMode = 0;
		this.bMenuIsOpen = false;
		this.iMenuType = -1;
	}
}
Player Players[MAXPLAYERS+1];

enum
{
	F_PLUGIN = 0,
	F_MENUTYPE,
	F_PRIORITY_TYPE,
	F_SELECT,
	F_DISPLAY,
	F_DRAW,
	F_COUNT
}

enum FeatureMenus
{
	MENUTYPE_NONE = 0,		// Без секции меню
	MENUTYPE_MAINMENU,		// Секция главного меню
	MENUTYPE_SETTINGSMENU,	// Секция меню настроек
	MENUTYPE_ADMINMENU, 	// Секция админ-меню
	MENUTYPE_SPEAKLIST, 	// Список игроков, которые слышат вас
	MENUTYPE_LISTININGLIST	// Список игроков, которых вы слышите
};

TopMenu     	g_hTopMenu = null;
ArrayList		g_hItems, g_hNameItems;
KeyValues		g_kvConfig;

#include "VoiceDynamicMode/config.sp"
#include "VoiceDynamicMode/api.sp"
#include "VoiceDynamicMode/menu.sp"
#include "VoiceDynamicMode/cmds.sp"

public Plugin myinfo =
{
	name		=	"[Voice Dynamic Mode] Core",
	version		=	VDM_VERSION,
	description	=	"Simple and dynamic api for change voice mode for CS:GO servers",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("[VDM] Core - This plugin is for CS:GO only.");

	CreateNatives();
	CreateGlobalForwards();

	RegPluginLibrary("vdm_core");

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hItems = new ArrayList(ByteCountToCells(128));
	g_hNameItems = new ArrayList(ByteCountToCells(128));
	
	LoadTranslations("vdm_core.phrases");
	LoadConfig();
	GetCvars();
	
	if (LibraryExists("adminmenu"))
    {
        TopMenu hTopMenu;
        if ((hTopMenu = GetAdminTopMenu()) != null)
        {
            OnAdminMenuReady(hTopMenu);
        }
    }

	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);

	CreateTimer(1.0, CheckTime, _, TIMER_REPEAT);

	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i)) OnClientPutInServer(i);

	CallForward_OnCoreIsReady();
}

Action CheckTime(Handle hTimer, any data)
{
	// Динамическое обновление основного режима (update_time)
	if(g_iChangeDynamicMode > 0)
	{
		static int iStep;
		if(iStep > g_iChangeDynamicMode)
		{
			SetMode(g_iMainMode);
			iStep = 0;
		}
		else iStep++;
	}
	
	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i))
	{
		// Обновление данных в меню
		if(Players[i].MenuIsOpen())
		{
			OpenMenu(i, view_as<FeatureMenus>(Players[i].iMenuType));
		}
		// Обновление режима игрока
		if(Players[i].iPlayerMode > 0)
		{
			SetPlayerMode(i, Players[i].iPlayerMode);
		}
	}
}

public Action Event_Cvar(Handle hEvent, const char[] name, bool dontBroadcast)
{
    if(!g_bBlockEvents) return Plugin_Continue;
    char cvarname[64]; 
    GetEventString(hEvent, "cvarname", cvarname, sizeof(cvarname));

    if(!strcmp("sv_deadtalk", cvarname)) return Plugin_Handled;

    return Plugin_Continue;
}

public void OnMapStart()
{
	if(g_iTalkAfterDyingTime > 0) g_hCvar7.SetInt(g_iTalkAfterDyingTime);
	if(g_bTalkOnWarmup) g_hCvar6.SetInt(1);
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	g_iLastPluginPriority = 0;
	SetMode(g_iMainMode);

	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i)) Players[i].iLastPluginPriority = 0;
}

public void OnClientPutInServer(int iClient)
{
	Players[iClient].ClearData();
	Players[iClient].iClient = iClient;
}

public void OnClientDisconnect(int iClient)
{
	Players[iClient].ClearData();
}

void GetCvars()
{
	g_hCvar1 = FindConVar("sv_alltalk");

	g_hCvar2 = FindConVar("sv_deadtalk");
	g_hCvar3 = FindConVar("sv_talk_enemy_dead");
	g_hCvar4 = FindConVar("sv_talk_enemy_living");
	g_hCvar5 = FindConVar("sv_full_alltalk");

	g_hCvar6 = FindConVar("sv_auto_full_alltalk_during_warmup_half_end");
	g_hCvar7 = FindConVar("sv_talk_after_dying_time");

	HookConVarChange(g_hCvar1, Update_CV);
	HookConVarChange(g_hCvar2, Update_CV);
	HookConVarChange(g_hCvar3, Update_CV);
	HookConVarChange(g_hCvar4, Update_CV);
	HookConVarChange(g_hCvar5, Update_CV);
	HookConVarChange(g_hCvar7, Update_CV);
}

public void Update_CV(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	if(!g_bHookCvars) return;
	if(hCvar == g_hCvar1 || hCvar == g_hCvar2 || hCvar == g_hCvar3 || hCvar == g_hCvar4 || hCvar == g_hCvar5)
	{
		SetMode(g_iMainMode);
	}
}

/*
TODO: Добавить ивенты pre/post + приоритеты плагинов
*/
void SetPlayerMode(int iClient, int iMode)
{
	if(IsClientValid(iClient))
	{
		if(iMode < -1) iMode = -1;
		if(iMode > 3) iMode = 3;

		switch(iMode)
		{
			case -1: 
			{
				// Для правильной работы модулей...
				// Игрок не слышыт никого...
			}
			case 0: SetClientListeningFlags(iClient, VOICE_NORMAL);     // Стандартный режим
			case 1: SetClientListeningFlags(iClient, VOICE_LISTENALL); // Режим прослушивания
			case 2: SetClientListeningFlags(iClient, VOICE_SPEAKALL); // Режим разговора
			case 3: SetClientListeningFlags(iClient, VOICE_LISTENALL | VOICE_SPEAKALL); // Режим общего голосового чата
		}

		Players[iClient].iPlayerMode = iMode;
	}
}

/*
// Проверка зависимости голосового чата между двумя игроками в данный момент.
// Чтобы проверить что игрок слышит другого или поменять их местами чтобы увидить, кто тебя слышыт :)
// true - iClient слышыт iTarget
// false - iClient не слышыт iTarget
bool CheckPlayerListenStatus(int iClient, int iTarget = 0)
{
	if(!IsClientValid(iTarget) || !IsClientValid(iClient)) return false;
	
	int iTeam = GetClientTeam(iClient),
		iTeam2 = GetClientTeam(iTarget);

	// Проверка на отключение голосового чата
	if(Players[iClient].iPlayerMode == -1) return false;
	// Проверка на режим разговора
	if(Players[iTarget].iPlayerMode >= 2) return true;
	// Проверка на прослушывание
	if(Players[iClient].iPlayerMode == 1 || Players[iClient].iPlayerMode == 3) return true;

	// Проверка по режимам
	switch(g_iMode)
	{
		case 0: 
		{
			return false;
		}
		case 1:
		{
			if(iTeam == iTeam2)
			{
				if(IsPlayerAlive(iClient) && !IsPlayerAlive(iTarget)) return false;
			}
			else return false;
		}
		case 2, 4: 
		{
			if(iTeam != iTeam2)
			{
				if(IsPlayerAlive(iClient) && !IsPlayerAlive(iTarget)) return false;
			}
		}
		case 6:
		{
			if(IsPlayerAlive(iClient) != IsPlayerAlive(iTarget)) return false;
		}
		case 7:
		{
			if(iTeam2 == CS_TEAM_SPECTATOR) return false;
		}
		// 8 - тут всё ясно)
	}

	return true;
}
*/

// Проверка зависимости голосового чата между двумя игроками в данный момент.
// Чтобы проверить что игрок слышит другого или поменять их местами чтобы увидить, кто тебя слышыт :)
// true - iClient слышыт iTarget
// false - iClient не слышыт iTarget
bool CheckPlayerListenStatus(int iClient, int iTarget = 0)
{
	if(iClient == iTarget || !IsClientValid(iTarget) || !IsClientValid(iClient)) return false;

	// Проверка на отключение голосового чата (или нахождение в другом канале)
	if(Players[iClient].iPlayerMode == -1 && Players[iClient].iPlayerMode != Players[iTarget].iPlayerMode) return false;

	if(IsClientMuted(iClient, iTarget)) return false;
	
	if(GetListenOverride(iClient, iTarget) == Listen_No) return false;

	return true;
}

void SetMode(int iMode)
{
	switch(iMode)
	{
		// Mode_NoVoice
		// голосовой чат выключен
		case 0: SetCvar(0, 0, 0, 0, 0);

		// Mode_Alive_Death_TeamOnly
		// живые игроки могут общатся только с живыми игроками своей команды
		// мертвые игроки могут общатся только c мертвыми игроками своей команды
		case 1: SetCvar(1, 0, 0, 0, 0);

		// Mode_Alive_Death_TeamsOnly
		// живые игроки могут общатся только с живыми игроками своей команды
		// мертвые игроки могут общатся с мертвыми игроками своей и противоположной команды
		case 2: SetCvar(1, 0, 1, 0, 0); 

		// Mode_TeamOnly
		// живые игроки могут общатся только со своей командой (живой и мертвой)
		case 3: SetCvar(1, 1, 0, 0, 0); 

		// Mode_AliveOnly
		// живые игроки могут общатся только со своей командой (живой и мертвой)
		// мертвые игроки будут слышать живых игроков своей команды и мертвых игроков своей и противоположной команды
		case 4: SetCvar(1, 1, 1, 0, 0); 

		// Mode_AliveOnly
		// живые игроки могут общатся только с живыми игроками своей и противоположной команды 
		// мертвые игроки могут общатся только c мертвыми игроками своей команды
		case 5: SetCvar(1, 0, 0, 1, 0); 

		// Mode_AliveToDeathTeams
		// живые игроки могут общатся только с живыми игроками своей и противоположной команды 
		// мертвые игроки могут общатся только c мертвыми игроками своей и противоположной команды
		case 6: SetCvar(1, 0, 1, 1, 0); 

		// Mode_AllTalk
		// обший голосовой чат
		case 7: SetCvar(1, 1, 1, 1, 0); 

		// Mode_FullAllTalk
		// общий голосовой чат | + наблюдатели (спектаторов)
		case 8: SetCvar(1, 1, 1, 1, 1); 
	}

	g_iLastMode = g_iMode;
	g_iMode = iMode;
}

// sv_alltalk, sv_deadtalk, sv_talk_enemy_dead, sv_talk_enemy_living, sv_full_alltalk
void SetCvar(int iValue1, int iValue2, int iValue3, int iValue4, int iValue5)
{
	g_hCvar1.SetInt(iValue1);
	g_hCvar2.SetInt(iValue2);
	g_hCvar3.SetInt(iValue3);
	g_hCvar4.SetInt(iValue4);
	g_hCvar5.SetInt(iValue5);
}

bool IsClientValid(int iClient)
{
	return (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient));
}

bool IsWarmup()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

bool VDM_LogMessage(char[] sBuffer, any ...)
{
	if(g_bLogs)
	{
		LogToFile(g_sPathLogs, sBuffer);
	}
}

bool CheckAdminAccess(int iClient)
{
	int iFlagBits = GetUserFlagBits(iClient);
	
	if(iFlagBits & ReadFlagString("z") || iFlagBits & ReadFlagString(g_sAdminFlag)) return true;
	else return false;
}