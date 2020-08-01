#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <csgo_colors>

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

#define			VDM_VERSION         "2.0"
#define			MAX_MODES           8
#define			MAX_PLAYERMODES     3
#define			PATH_TO_CONFIG      "configs/vdm_core.ini"
#define			PATH_TO_LOGS        "logs/vdm_core.log"

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
				g_iNotify,
				g_iTalkAfterDyingTime;

bool			g_bCoreIsReady = false,
				g_bHookCvars,
				g_bBlockEvents,
				g_bLogs,
				g_bTalkOnWarmup;

char			g_sPathLogs[PLATFORM_MAX_PATH];

enum struct Player
{
	int 	iClient;
	int 	iPlayerMode;
	bool 	bMenuIsOpen;
	int 	iMenuType;

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
	F_MENUTYPE = 1,
	F_PLUGIN,
	F_SELECT,
	F_DISPLAY,
	F_DRAW,
	F_COUNT
}

enum FeatureMenus
{
	MENUTYPE_MAINMENU = 0,	// Секция главного меню
	MENUTYPE_SETTINGSMENU,	// Секция меню настроек
	MENUTYPE_ADMINMENU, 	// Секция админ-меню
	MENUTYPE_SPEAKLIST, 	// Список игроков, которые слышат вас
	MENUTYPE_LISTININGLIST	// Список игроков, которых вы слышите
};

ArrayList		g_hItems;
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
	
	LoadConfig();
	GetCvars();

	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);

	CreateTimer(1.0, CheckTime, _, TIMER_REPEAT);

	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i)) OnClientPutInServer(i);

	CallForward_OnCoreIsReady();
}

Action CheckTime(Handle hTimer, any data)
{
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
		// Динамическое обновление режима (update_time)
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
	if(!IsClientValid(iTarget) || !IsClientValid(iClient)) return false;

	// Проверка на отключение голосового чата
	if(Players[iClient].iPlayerMode == -1) return false;

	if(IsClientMuted(iClient, iTarget)) return false;
	
	if(GetListenOverride(iClient, iTarget) == Listen_No) return false;

	return true;
}


bool SetVoiceMode(int iMode, int iPluginPriority)
{
	switch(CallForward_OnSetVoiceModePre(iMode, iPluginPriority))
	{
		case Plugin_Continue:
		{
			SetMode(iMode);
		}
		case Plugin_Changed:
		{
			if(iPluginPriority >= g_iLastPluginPriority) 
			{
				g_iLastPluginPriority = iPluginPriority;
				SetMode(iMode);
			}
		}
	}

	CallForward_OnSetVoiceModePost(g_iMode, g_iLastPluginPriority);

	if(g_iMode == g_iLastMode) return false;
	
	CGOPrintToChatAll("%t", "");
	return true;
}

void SetMode(int iMode, bool bCallPreForward = false, bool bCallPostForward = false)
{
	switch(iMode)
	{
		case 0: SetCvar(0, 0, 0, 0, 0); // голосовой чат выключен
		case 1: SetCvar(1, 0, 0, 0, 0); // живые игроки могут общатся только с живыми игроками своей команды | мертвые игроки могут общатся только c мертвыми игроками своей команды
		case 2: SetCvar(1, 0, 1, 0, 0); // живые игроки могут общатся только с живыми игроками своей команды | мертвые игроки могут общатся с мертвыми игроками своей и противоположной команды
		case 3: SetCvar(1, 1, 0, 0, 0); // живые игроки могут общатся только со своей командой (живой и мертвой)
		case 4: SetCvar(1, 1, 1, 0, 0); // живые игроки могут общатся только со своей командой (живой и мертвой) | мертвые игроки будут слышать живых игроков своей команды и мертвых игроков своей и противоположной команды
		case 5: SetCvar(1, 0, 0, 1, 0); // живые игроки могут общатся только с живыми игроками своей и противоположной команды | мертвые игроки могут общатся только c мертвыми игроками своей команды
		case 6: SetCvar(1, 0, 1, 1, 0); // живые игроки могут общатся только с живыми игроками своей и противоположной команды | мертвые игроки могут общатся только c мертвыми игроками своей и противоположной команды
		case 7: SetCvar(1, 1, 1, 1, 0); // обший голосовой чат
		case 8: SetCvar(1, 1, 1, 1, 1); // общий голосовой чат | + наблюдатели (спектаторов)
	}

	g_iLastMode = g_iMode;
	g_iMode = iMode;
}

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