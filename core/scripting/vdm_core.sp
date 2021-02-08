#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
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

#define			VDM_VERSION         "2.0 R" // D - Developer Preview | B - BETA | R - RELEASE
#define			VDM_INT_VERSION 	020000
#define			VDM_DYNAMIC_MENU	1.0 	// Уменьшение этого параметра может привести к лагам на сервере
#define			DEBUG_MODE 			0

#define			MAX_MODES           8
#define			MAX_PLAYERMODES     6
#define			PATH_TO_CONFIG      "configs/vdm_config.ini"
#define			PATH_TO_SORTMENU    "configs/vdm_sortmenu.ini"
#define			PATH_TO_LOGS        "logs/vdm_core.log"
#define			RELOAD_COMMAND      "sm_vdm_reload"
#define			DUMP_COMMAND      	"sm_vdm_dump"

ConVar			g_hCvar1,
				g_hCvar2,
				g_hCvar3,
				g_hCvar4,
				g_hCvar5,
				g_hCvar6;

TopMenu			g_hTopMenu = null;
ArrayList		g_hItems, g_hNameItems, g_hSortItems;
KeyValues		g_kvConfig;

int				g_iMode, // Текущий режим
				g_iMainMode, // Основной режим (может быть изменён)
				g_iDefaultMode, // Стандартный основной режим (изменяется только конфигом)
				g_iLastMode, // Предыдущий режим
				g_iChangeDynamicMode,
				g_iReloadModules,
				g_iDynamicMenu;

bool			g_bCoreIsLoaded = false,
				g_bHookCvars,
				g_bBlockEvents,
				g_bLogs,
				g_bTalkOnWarmup;

char			g_sPathLogs[PLATFORM_MAX_PATH], 
				g_sAdminFlag[2], 
				g_sPrefix[32], g_sPrefixMenu[32];


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

enum struct Player
{
	int		iClient;
	int		iPlayerMode;
	int		iLastPlayerMode;

	bool	bMenuIsOpen;
	bool	bLastAdminMenu;
	int		iMenuType;
	int		iMenuPage;

	bool MenuIsOpen()
	{
		return this.bMenuIsOpen && GetClientMenu(this.iClient) == MenuSource_Normal;
	}

	void ClearData()
	{
		this.iClient = -1;
		this.iPlayerMode = 0;
		this.iMenuType = -1;
		this.iMenuPage = 0;
		this.bMenuIsOpen = false;
		this.bLastAdminMenu = false;
	}
}
Player Players[MAXPLAYERS+1];

#include "VoiceDynamicMode/config.sp"
#include "VoiceDynamicMode/api.sp"
#include "VoiceDynamicMode/menu.sp"
#include "VoiceDynamicMode/cmds.sp"
#include "VoiceDynamicMode/events.sp"

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
	g_hSortItems = new ArrayList(ByteCountToCells(128));
	
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

	CreateTimer(VDM_DYNAMIC_MENU, CheckTime, _, TIMER_REPEAT);

	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i)) OnClientPutInServer(i);

	AddCommandListener(MenuSelectListener, "menuselect");
}

public void OnAllPluginsLoaded()
{
	CallForward_OnCoreIsReady();
}

/* Фикс для динамичного отображения всех пунктов меню на любой странце меню.
Функция AddCommandListner - hook command (menuselect)
*/
Action MenuSelectListener(int iClient, char[] cmd, int argc)
{
	if(Players[iClient].MenuIsOpen())
	{
		char szBuffer[4];
		GetCmdArgString(szBuffer, sizeof(szBuffer));

		switch(szBuffer[0])
		{
			case '7': 
			{
				if(Players[iClient].iMenuPage > 0) Players[iClient].iMenuPage -= 6;
			}
			case '8': Players[iClient].iMenuPage += 6;
		}
	}
	
	return Plugin_Continue;
} 

Action CheckTime(Handle hTimer, any data)
{
	// Динамическое обновление основного режима (update_time)
	if(g_iChangeDynamicMode > 0)
	{
		static int iStep;
		if(iStep > g_iChangeDynamicMode)
		{
			SetMode(g_iMode);
			iStep = 0;
		}
		else iStep++;
	}
	
	for(int i = 1; i <= MaxClients; i++) if(IsClientValid(i))
	{
		// Обновление данных в меню
		if(g_iDynamicMenu > 0 && Players[i].MenuIsOpen())
		{
			//if(view_as<FeatureMenus>(Players[i].iMenuType) == MENUTYPE_MAINMENU)  
			//PrintToChatAll("menupage - %i", Players[i].iMenuPage);
			if(g_iDynamicMenu == 1) OpenMenu(i, MENUTYPE_MAINMENU);
			else OpenMenu(i, view_as<FeatureMenus>(Players[i].iMenuType), Players[i].iMenuPage, Players[i].bLastAdminMenu);
		}
		
		// Обновление режима игрока
		if(Players[i].iPlayerMode > 0)
		{
			SetPlayerMode(i, Players[i].iPlayerMode);
		}
	}
}

public void OnMapStart()
{
	if(g_bTalkOnWarmup) g_hCvar6.SetInt(1);
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

	HookConVarChange(g_hCvar1, Update_CV);
	HookConVarChange(g_hCvar2, Update_CV);
	HookConVarChange(g_hCvar3, Update_CV);
	HookConVarChange(g_hCvar4, Update_CV);
	HookConVarChange(g_hCvar5, Update_CV);
}

void SetPlayerMode(int iClient, int iMode)
{
	if(IsClientValid(iClient))
	{
		if(iMode < -1) iMode = -1;
		if(iMode > MAX_PLAYERMODES) iMode = MAX_PLAYERMODES;

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
			case 3: SetClientListeningFlags(iClient, VOICE_TEAM); // Режим прослушивания только команды
			case 4: SetClientListeningFlags(iClient, VOICE_LISTENTEAM); // Режим разговора только c командой
			case 5: SetClientListeningFlags(iClient, VOICE_TEAM | VOICE_LISTENTEAM); // Режим голосового чата только с командой
			case 6: SetClientListeningFlags(iClient, VOICE_LISTENALL | VOICE_SPEAKALL); // Режим общего голосового чата
		}

		Players[iClient].iPlayerMode = iMode;
	}
}

// Проверка зависимости голосового чата между двумя игроками в данный момент.
// Чтобы проверить что игрок слышит другого или поменять их местами чтобы увидить, кто тебя слышыт :)
// true - iClient слышыт iTarget
// false - iClient не слышыт iTarget
bool CheckPlayerListenStatus(int iClient, int iTarget = 0)
{
	bool bListen = true;
	
	if(iClient == iTarget || !IsClientValid(iTarget) || !IsClientValid(iClient)) 
	{
		return false;
	}

	int iTeam = GetClientTeam(iClient),
		iTeam2 = GetClientTeam(iTarget);

	// Проверка по режимам
	switch(g_iMode)
	{
		case 0: bListen = false;
		case 1:
		{
			bListen = false;
			
			if(iTeam2 != CS_TEAM_SPECTATOR)
			{
				if(iTeam == iTeam2 && ((IsPlayerAlive(iClient) && IsPlayerAlive(iTarget)) || (!IsPlayerAlive(iClient) && !IsPlayerAlive(iTarget)))) bListen = true;
			} 
		}
		case 2: 
		{
			bListen = false;
			if(iTeam2 != CS_TEAM_SPECTATOR)
			{
				if(iTeam == iTeam2 && IsPlayerAlive(iClient) && IsPlayerAlive(iTarget)) bListen = true;
				if(!IsPlayerAlive(iClient)) bListen = true;
			}
		}
		case 3: if(iTeam != iTeam2) bListen = false;
		case 4: 
		{
			bListen = false;
			if(iTeam2 != CS_TEAM_SPECTATOR)
			{
				if(IsPlayerAlive(iClient) && iTeam == iTeam2) bListen = true;
				if(!IsPlayerAlive(iClient))
				{
					bListen = true;
					if(IsPlayerAlive(iTarget) && iTeam != iTeam2) bListen = false;
				}
			}
		}
		case 5:
		{
			bListen = false;
			if(iTeam2 != CS_TEAM_SPECTATOR )
			{
				if(IsPlayerAlive(iClient) && !IsPlayerAlive(iTarget)) bListen = true;
				if(!IsPlayerAlive(iClient) && !IsPlayerAlive(iTarget) && iTeam == iTeam2) bListen = true;
			} 
		}
		case 6: if(iTeam2 == CS_TEAM_SPECTATOR || (IsPlayerAlive(iClient) && !IsPlayerAlive(iTarget))) bListen = false;
		case 7: 
		{
			if(iTeam2 == CS_TEAM_SPECTATOR) bListen = false;
		}
		// case 8: bListen = true; - тут всё ясно)
	}

	// Проверка на отключение голосового чата (или нахождение в другом канале)
	if(Players[iClient].iPlayerMode == -1) bListen = false;

	if(IsClientMuted(iClient, iTarget)) bListen = false;
	
	if(GetListenOverride(iClient, iTarget) == Listen_No) bListen = false;

	CallForward_CheckPlayerListenStatusPre(iClient, iTarget, bListen);

	return bListen;
}

void SetMode(int iMode)
{
	bool bConvar = g_bHookCvars;
	g_bHookCvars = false;
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

	g_bHookCvars = bConvar;
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

bool VDM_LogMessage(char[] sMessage, any ...)
{
	if(g_bLogs)
	{
		char szBuffer[2048];
		VFormat(szBuffer, sizeof szBuffer, sMessage, 2);
		LogToFile(g_sPathLogs, szBuffer);
	}
}

bool CheckAdminAccess(int iClient)
{
	int iFlagBits = GetUserFlagBits(iClient);
	
	if(iFlagBits & ReadFlagString("z") || iFlagBits & ReadFlagString(g_sAdminFlag)) return true;
	else return false;
}

void SetSortItems()
{
	if(g_hSortItems) g_hSortItems.Clear();

	char sPath[PLATFORM_MAX_PATH], szFeature[128];
	BuildPath(Path_SM, sPath, sizeof(sPath), PATH_TO_SORTMENU);
	File hFile = OpenFile(sPath, "r");
	if (hFile != null)
	{
		while (!hFile.EndOfFile() && hFile.ReadLine(szFeature, 128))
		{
			TrimString(szFeature);
			//PrintToChatAll(szFeature);
			if (szFeature[0])
			{
				g_hSortItems.PushString(szFeature);
			}
		}
		
		delete hFile;
		
		if ((g_hSortItems).Length == 0)
		{
			g_hSortItems.Clear();
			g_hSortItems = null;
		}
	}
}

void ResortItems()
{
	if (g_hNameItems.Length < 2 || !g_hSortItems) return;

	int i, x, iSize, index;
	iSize = g_hSortItems.Length;

	x = 0;
	char szItemInfo[128];
	for (i = 0; i < iSize; ++i)
	{
		g_hSortItems.GetString(i, szItemInfo, sizeof(szItemInfo));
		index = g_hNameItems.FindString(szItemInfo);
		if (index != -1)
		{
			if (index != x)
			{
				g_hNameItems.SwapAt(index, x);
				g_hItems.SwapAt(index, x);
			}
			
			++x;
		}
	}
}

/*
int GetMode()
{
	int iValue1 = g_hCvar1.SetInt(iValue1),
		iValue2 = g_hCvar2.SetInt(iValue2),
		iValue3 = g_hCvar3.SetInt(iValue3),
		iValue4 = g_hCvar4.SetInt(iValue4),
		iValue5 = g_hCvar5.SetInt(iValue5);
	
	if(iValue1 == 0 && iValue2 == 0 && iValue3 == 0 && iValue4 == 0 && iValue5 == 0)
	elseif
	etc...
}
*/