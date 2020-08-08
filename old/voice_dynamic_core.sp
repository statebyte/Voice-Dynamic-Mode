#pragma semicolon 1 
#pragma newdecls required

/**
* ----------------------------- INFO ---------------------------------
* Full name:        [CS:GO] Voice Dynamic Mode Core
* Author:           FIVE (Discord: FIVE#3136)
* Source:           https://github.com/theelsaud/Voice-Dynamic-Mode
* Support:          https://discord.gg/ajW69wN
* Official theme:   http://hlmod.ru
*
* -------------------------- CHANGELOGS ------------------------------
* v1.0 - Release
* v1.1 - Add new features, optimization, improvements, and fixes issues...
*
* ----------------------------- TODO ---------------------------------
* - Create a single core
*/

#include <cstrike>
#include <sdktools>
#include <clientprefs>

#include <csgo_colors>
#include <PTaH>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define DEBUG 0
#define MAXMODE 8
#define VDM_VERSION "1.1"

public Plugin myinfo =
{
    name		= "[CS:GO] Voice Dynamic Mode",
    version		= VDM_VERSION,
    description	= "Simple and dynamic changes voice mode for CS:GO servers",
    author		= "FIVE",
    url			= "Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

TopMenu     g_hTopMenu = null;

char        g_sLogPath[PLATFORM_MAX_PATH];

int 		g_iMode, g_iMainMode, g_iDefaultMode, g_iLastMode,
            g_iMaxClients, g_iNotify, g_iNotifyAfterDying, g_iNotifyClutchMode,
            g_iQuota, g_iQuotaMode, g_iQuotaPriority, g_iRoundEndMode,
            g_iTalkAfterDyingTime, g_iForceCameraRoundEnd, g_iForceCameraQuota, g_iClutchMode;

bool		g_bTalkOnWarmup, g_bQuotaEnable, g_bLogs, g_bNotifyVoiceEnable,
            g_bForceCameraMode, g_bBlockEvents, g_bVoiceEnableActivated, g_bNotifyAdminActions,
            g_bVoiceEnable[MAXPLAYERS+1], g_bClutchMode[MAXPLAYERS+1], g_bClutchModeActive[MAXPLAYERS+1];

ConVar 		g_hCvar1, g_hCvar2, g_hCvar3, g_hCvar4,
            g_hCvar5, g_hCvar6, g_hCvar7, g_hCvar8;

Menu		g_hMainMenu, g_hAdminMenu;

KeyValues	g_kvConfig;

Handle      g_hTimerAfterDying[MAXPLAYERS+1], hCookie;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    
    
    if(GetEngineVersion() != Engine_CSGO) SetFailState("[VDM] Core - This plugin is for CS:GO only.");

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadConfig();
    LoadTranslations("voice_dynamic_mode.phrases");

    HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_PostNoCopy);
    HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);

    if(PTaH_Version() < 101000)
	{
		char sBuf[16];
		PTaH_Version(sBuf, sizeof(sBuf));
		SetFailState("VDM Core - PTaH extension needs to be updated. (Installed Version: %s - Required Version: 1.1.0+) [ Download from: https://ptah.zizt.ru ]", sBuf);
	}
    PTaH(PTaH_ClientVoiceToPre, Hook, CVP);

    hCookie = RegClientCookie("VDM_ClutchMode", "VDM_ClutchMode", CookieAccess_Public);
    g_iMaxClients = GetMaxHumanPlayers() + 1;

    GetCvars();
    RegCmds();
    
    LoadMenus();
    CheckMode();
}

public Action CVP(int iClient, int iTarget, bool& bListen)
{
    if(!IsClientValid(iClient) || !IsClientValid(iTarget)) return Plugin_Continue;
    if(g_bVoiceEnable[iTarget]) return Plugin_Handled;
    else if(g_iClutchMode > 0 && g_bClutchMode[iTarget] && g_bClutchModeActive[iTarget])
    {
        if(g_iClutchMode == 1 && !IsPlayerAlive(iClient)) return Plugin_Handled;
        if(g_iClutchMode == 2) return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void OnMapStart()
{
    g_hCvar1.SetInt(1);
    if(g_iTalkAfterDyingTime > 0) g_hCvar7.SetInt(g_iTalkAfterDyingTime);
    if(g_bTalkOnWarmup) g_hCvar6.SetInt(1);

    CheckMode();
}

public void OnClientCookiesCached(int iClient)
{
    char szBuffer[4];
    GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));

    if(szBuffer[0]) g_bClutchMode[iClient] = view_as<bool>(StringToInt(szBuffer));
    else g_bClutchMode[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
    g_bVoiceEnable[iClient] = false;

    if(g_bClutchMode[iClient]) SetClientCookie(iClient, hCookie, "1");
    else SetClientCookie(iClient, hCookie, "0");
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
    CheckMode();

    for(int i = 1; i <= MaxClients; i++)	if(IsClientValid(i) && g_bVoiceEnable[i] && g_bNotifyVoiceEnable)
    {
        CGOPrintToChat(i, "%t", "CHAT_VC_Still_Off");
    }
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast) 
{ 
    if(g_iRoundEndMode > 0 && g_iMode != g_iRoundEndMode) SetMode(g_iRoundEndMode);
    if((g_iNotify == 2 || g_iNotify == 3) && g_iMode != g_iRoundEndMode) CGOPrintToChatAll("%t", "CHAT_Change_Mode");

    if(g_bForceCameraMode) SetForceCamera(g_iForceCameraRoundEnd);

    for(int i = 1; i <= MaxClients; i++)	if(IsClientValid(i))
    {
        g_bClutchModeActive[i] = false;
    }
}

public Action Event_OnPlayerDeath(Event hEvent, char[] name, bool dontBroadcast)
{
    if(IsWarmup()) return;
    if(g_iClutchMode > 0) CheckClutchMode();

    if(g_iMode == 8 || g_iMode == 7 || g_iMode == 4 || g_iMode == 3 || g_hCvar7.IntValue == 0 || g_hCvar5.IntValue == 1 || g_iNotifyAfterDying == 0) return;

    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if(!IsClientValid(iClient)) return;

    float fValue = float(g_hCvar7.IntValue);
    if(g_iNotifyAfterDying == 2 || g_iNotifyAfterDying == 3) CGOPrintToChat(iClient, "%t", "CHAT_Dying_Time", g_hCvar7.IntValue);
    g_hTimerAfterDying[iClient] = CreateTimer(fValue, Timer_CallBack, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_Cvar(Handle hEvent, const char[] name, bool dontBroadcast)
{
    if(!g_bBlockEvents) return Plugin_Continue;
    char cvarname[64]; 
    GetEventString(hEvent, "cvarname", cvarname, sizeof(cvarname));

    if(!strcmp("sv_deadtalk", cvarname)) return Plugin_Handled;

    return Plugin_Continue;
}

void CheckClutchMode()
{
    int iCount_T, iCount_CT, iLastClientCT, iLastClientT;
    for(int i = 1; i <= MaxClients; i++)	if(IsClientValid(i) && IsPlayerAlive(i))
    {
        switch(GetClientTeam(i))
        {
            case CS_TEAM_T: 
            {
                iLastClientT = i;
                iCount_T++;
            }
            case CS_TEAM_CT:
            { 
                iLastClientCT = i;
                iCount_CT++;
            }
        }
    }

    if(iCount_T == 0 || iCount_CT == 0) return;

    if(iCount_CT == 1) SetCluchMode(iLastClientCT);
    if(iCount_T == 1) SetCluchMode(iLastClientT);
}

void SetCluchMode(int iClient)
{
    if(!g_bClutchMode[iClient]) return;

    g_bClutchModeActive[iClient] = true;

    switch(g_iNotifyClutchMode)
    {
        case 1: CGOPrintToChat(iClient, "%t", "CHAT_ClutchMode_IsActivated", g_iClutchMode == 1 ? "TheDead" : "OfAll");
        case 2: CGOPrintToChatAll("%t", "CHAT_ClutchMode_IsActivated_All", iClient, g_iClutchMode == 1 ? "TheDead" : "OfAll");
    }
}

public Action Timer_CallBack(Handle hTimer, any UserId)
{
    int iClient = GetClientOfUserId(UserId);
    if(IsClientValid(iClient) && (g_iNotifyAfterDying == 1 || g_iNotifyAfterDying == 3)) CGOPrintToChat(iClient, "%t", "CHAT_Dying_Time_Timeout");

    return Plugin_Stop;
}

void RegCmds()
{
    RegConsoleCmd("sm_voice", Main_CmdCallBack);
    RegConsoleCmd("sm_voice_info", Main_CmdCallBack);
    RegAdminCmd("sm_voice_admin", Admin_CmdCallBack, ADMFLAG_ROOT);
    RegAdminCmd("sm_voice_mode", SetMode_CmdCallBack, ADMFLAG_ROOT);
    RegAdminCmd("sm_voice_enable", VoiceEnable_CmdCallBack, ADMFLAG_ROOT);
    RegAdminCmd("sm_voice_listen", VoiceListen_CmdCallBack, ADMFLAG_ROOT);
    RegAdminCmd("sm_voice_reload", ReloadConfig_CmdCallBack, ADMFLAG_ROOT);
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
    g_hCvar8 = FindConVar("mp_forcecamera");
}

/*
    HookConVarChange(g_hCvar1, OnConVarChanged);
    HookConVarChange(g_hCvar2, OnConVarChanged);
    HookConVarChange(g_hCvar3, OnConVarChanged);
    HookConVarChange(g_hCvar4, OnConVarChanged);
    HookConVarChange(g_hCvar5, OnConVarChanged);
    HookConVarChange(g_hCvar6, OnConVarChanged);
    HookConVarChange(g_hCvar7, OnConVarChanged);
    HookConVarChange(g_hCvar8, OnConVarChanged);

public void OnConVarChanged(ConVar hCvar, const char[] oldValue, const char[] newValue)
{
    // Что тут будет, знает только хороший программист... :)
    return;
}
*/

void LoadConfig()
{
    //////////////////////////////////////////////////////////////////////////////////
    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/voice_dynamic_mode.log");
    //////////////////////////////////////////////////////////////////////////////////
    
    if(g_kvConfig) delete g_kvConfig;
    
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/voice_dynamic_mode.ini");

    g_kvConfig = new KeyValues("VoiceDynamicMode");

    if(!g_kvConfig.ImportFromFile(sPath))
    {
        SetFailState("VDM - config is not found (%s).", sPath);
    }
    g_kvConfig.Rewind();


    g_iMode = g_kvConfig.GetNum("mode", 0);
    if(g_iMode > MAXMODE) g_iMode = MAXMODE;
    if(g_iMode < 0) g_iMode = 0;
    g_iDefaultMode = g_iMode;
    g_iMainMode = g_iMode;

    g_iTalkAfterDyingTime = g_kvConfig.GetNum("talk_after_dying_time", 0);
    g_bTalkOnWarmup = view_as<bool>(g_kvConfig.GetNum("talk_on_warmup", 0));

    g_iQuota = g_kvConfig.GetNum("quota", 0);

    g_iQuotaMode = g_kvConfig.GetNum("quota_set_mode", 0);
    if(g_iQuotaMode > MAXMODE) g_iQuotaMode = MAXMODE;
    if(g_iQuotaMode < 0) g_iQuotaMode = 0;

    g_iQuotaPriority = g_kvConfig.GetNum("quota_priority", 0);
    
    g_bVoiceEnableActivated = view_as<bool>(g_kvConfig.GetNum("voice_enable_mode", 0));
    g_iClutchMode = g_kvConfig.GetNum("clutch_mode", 0);


    g_bForceCameraMode = view_as<bool>(g_kvConfig.GetNum("forcecamera_mode", 0));
    g_iForceCameraQuota = g_kvConfig.GetNum("quota_forcecamera", 0);
    g_iForceCameraRoundEnd = g_kvConfig.GetNum("roundend_forcecamera", 0);

    g_iRoundEndMode = g_kvConfig.GetNum("roundend_set_mode", 0);

    g_iNotify = g_kvConfig.GetNum("notify", 0);
    g_iNotifyAfterDying = g_kvConfig.GetNum("notify_after_dying", 0);
    g_iNotifyClutchMode = g_kvConfig.GetNum("notify_clutchmode", 0);
    g_bNotifyVoiceEnable = view_as<bool>(g_kvConfig.GetNum("notify_voiceenable", 0));
    g_bNotifyAdminActions = view_as<bool>(g_kvConfig.GetNum("notify_admin_actions", 0));

    g_bBlockEvents = view_as<bool>(g_kvConfig.GetNum("block_events", 0));
    g_bLogs = view_as<bool>(g_kvConfig.GetNum("logs", 0));

    delete g_kvConfig;
}

void LoadMenus()
{
    if (LibraryExists("adminmenu"))
    {
        TopMenu hTopMenu;
        if ((hTopMenu = GetAdminTopMenu()) != null)
        {
            OnAdminMenuReady(hTopMenu);
        }
    }
    
    g_hMainMenu = new Menu(MenuHandler_MainMenu, MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);
    g_hMainMenu.SetTitle("VDM/n /n");
    g_hMainMenu.AddItem("1", "VoiceChat");
    g_hMainMenu.AddItem("4", "ClutchMode", ITEMDRAW_RAWLINE);
    g_hMainMenu.AddItem("2", "YouHear", ITEMDRAW_RAWLINE);
    g_hMainMenu.AddItem("3", "HearYou", ITEMDRAW_RAWLINE);
    

    g_hAdminMenu = new Menu(MenuHandler_AdminMenu, MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);
    g_hAdminMenu.SetTitle("VDM/n /n");
    g_hAdminMenu.AddItem("1", "Enable_Full_AllTalk");
    g_hAdminMenu.AddItem("2", "ChangeQuota");
    g_hAdminMenu.AddItem("3", "ChangeMode");
    g_hAdminMenu.AddItem("4", "ChangeQuotaMode");
    g_hAdminMenu.AddItem("5", "ChangeTalkAfterDyingTime");
    g_hAdminMenu.AddItem("6", "ChangeForceCamera");
    g_hAdminMenu.AddItem("7", "ReloadConfig");
    // TODO: + PlayersOnOffVoiceChat, + OffClutchMode + EditRoundEndSettings

    g_hAdminMenu.ExitBackButton = true;
}

public int MenuHandler_MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
    switch(action)
    {
        case MenuAction_Display:
        {
            char szTitle[128];
            SetGlobalTransTarget(iClient);
            FormatEx(szTitle, sizeof(szTitle), "%t/n /n", "VDM", iClient);
            (view_as<Panel>(iItem)).SetTitle(szTitle);
        }
        case MenuAction_Select:
        {
            char szInfo[64], szTitle[128];
            hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));

            if(!strcmp(szInfo, "1")) 
            {
                g_bVoiceEnable[iClient] = !g_bVoiceEnable[iClient];
                CGOPrintToChat(iClient, "%t", "CHAT_VoiceEnable", g_bVoiceEnable[iClient] ? "DisableOther" : "EnableOther");
            }

            if(!strcmp(szInfo, "4")) 
            {
                g_bClutchMode[iClient] = !g_bClutchMode[iClient];
                CGOPrintToChat(iClient, "%t", "CHAT_ClutchMode", g_bClutchMode[iClient] ? "EnableOther" : "DisableOther");
            }

            g_hMainMenu.Display(iClient, 0);
        }
        case MenuAction_DisplayItem:    
        {
            char szTitleReady[128], szTitle[128], szInfo[64], szBuffer[128];
            hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));

            SetGlobalTransTarget(iClient);

            if(!strcmp(szInfo, "1")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t/n /n", szTitle, g_bVoiceEnable[iClient] ? "Disable" : "Enable");
            else if(!strcmp(szInfo, "4")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t/n /n", szTitle, g_bClutchMode[iClient] ? "Enable" : "Disable");
            else if(!strcmp(szInfo, "2"))
            {
                if(GetClientTeam(iClient) > 1)
                {
                    switch(g_iMode)
                    {
                        case 1: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "YH_1_2A" : "YH_1_3");
                        case 2: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "YH_1_2A" : "YH_2");
                        case 3: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "YH_3_4A" : "YH_1_3");
                        case 4: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "YH_3_4A" : "YH_4_5");
                        case 5: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "YH_5_6A" : "YH_4_5");
                        case 6: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "YH_5_6A" : "YH_6");
                        case 7: FormatEx(szBuffer, sizeof(szBuffer), "%t", "YH_7");
                        case 8: FormatEx(szBuffer, sizeof(szBuffer), "%t", "YH_8");
                    }
                }
                else FormatEx(szBuffer, sizeof(szBuffer), "%t", "YH_8");

                if(g_hCvar5.IntValue == 1) FormatEx(szBuffer, sizeof(szBuffer), "%t", "YH_8");
                if(g_bVoiceEnable[iClient]) FormatEx(szBuffer, sizeof(szBuffer), "%t", "Noone");

                FormatEx(szTitleReady, sizeof(szTitleReady), "%t/n%s/n /n", "YouHear", szBuffer);
            }
            else if(!strcmp(szInfo, "3"))
            {
                switch(g_iMode)
                {
                    case 1: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "HY_1_2_3_4A" : "HY_1_5");
                    case 2: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "HY_1_2_3_4A" : "HY_2_6");
                    case 3: FormatEx(szBuffer, sizeof(szBuffer), "%t", "HY_1_2_3_4A");
                    case 4: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "HY_1_2_3_4A" : "HY_4");
                    case 5: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "HY_5_6_7_8A" : "HY_1_5");
                    case 6: FormatEx(szBuffer, sizeof(szBuffer), "%t", IsPlayerAlive(iClient) ? "HY_5_6_7_8A" : "HY_2_6");
                    case 7, 8: FormatEx(szBuffer, sizeof(szBuffer), "%t", "HY_5_6_7_8A");
                }

                if(GetClientTeam(iClient) < 2 && g_hCvar5.IntValue == 0) FormatEx(szBuffer, sizeof(szBuffer), "%t", "OnlySpectators");

                FormatEx(szTitleReady, sizeof(szTitleReady), "%t/n%s/n /n", "HearYou", szBuffer);
            }
            else FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle);

            return RedrawMenuItem(szTitleReady); 
        }
        case MenuAction_DrawItem:
        {
            char szInfo[64];
            hMenu.GetItem(iItem, szInfo, sizeof(szInfo));

            if(!strcmp(szInfo, "1") && !g_bVoiceEnableActivated) return ITEMDRAW_IGNORE;
            if(!strcmp(szInfo, "4") && g_iClutchMode < 1) return ITEMDRAW_IGNORE;
        }
    }

    return 0;
}

public int MenuHandler_AdminMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
    switch(action)
    {
        case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack) g_hMainMenu.Display(iClient, 0);
        }
        case MenuAction_Display:
        {
            char szTitle[128];
            SetGlobalTransTarget(iClient);
            FormatEx(szTitle, sizeof(szTitle), TranslationPhraseExists("VDM_settings") ? "%t/n /n" : "%s/n /n", "VDM_settings");
            (view_as<Panel>(iItem)).SetTitle(szTitle);
        }
        case MenuAction_Select:
        {
            char szInfo[2], szTitle[128];
            hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));

            if(!strcmp(szInfo, "1")) ChangeAllTalk(-1, iClient);
            if(!strcmp(szInfo, "2")) 
            {
                if(g_iMaxClients < g_iQuota) g_iQuota = 0;
                else g_iQuota = g_iQuota+2;

                if(g_bNotifyAdminActions) CGOPrintToChatAll("%t", "CHAT_AdminAction_ChangeQuota", iClient, g_iQuota);

                if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N изменил квоту на - (%i)", iClient, g_iQuota);
            }
            if(!strcmp(szInfo, "3")) 
            {
                int iMode;
                if(g_iMode == MAXMODE) iMode = 1;
                else iMode = g_iMode+1;
                g_iMainMode = iMode;
                SetMode(iMode, true);
                if(g_bNotifyAdminActions) CGOPrintToChatAll("%t", "CHAT_AdminAction_ChangeMode", iClient);

                if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N установил голосовой режим на - (%i)", iClient, g_iMode);
            }
            if(!strcmp(szInfo, "4")) 
            {
                int iMode;
                if(g_iQuotaMode == MAXMODE) iMode = 1;
                else iMode = g_iQuotaMode+1;
                g_iQuotaMode = iMode;
                CheckMode();
                if(g_bNotifyAdminActions) CGOPrintToChatAll("%t", "CHAT_AdminAction_ChangeQuotaMode", iClient);

                if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N установил режим квоты для голосового чата на - (%i)", iClient, g_iQuotaMode);
            }
            if(!strcmp(szInfo, "5")) 
            {
                int iValue = g_hCvar7.IntValue + 1;
                if(iValue > 10) iValue = 0;
                g_hCvar7.SetInt(iValue);

                if(g_bNotifyAdminActions) CGOPrintToChatAll("%t", "CHAT_AdminAction_TalkAfterDying", iClient, iValue);

                if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N установил время для общения после смерти на - (%i)", iClient, iValue);
            }
            if(!strcmp(szInfo, "6")) 
            {
                PrintToServer("%i", g_iForceCameraQuota);
                
                switch(g_iForceCameraQuota)
                {
                    case 1: 
                    {
                        g_iForceCameraQuota = 2;
                        SetForceCamera(2);
                    }
                    case 2:
                    {
                        g_iForceCameraQuota = 1;
                        SetForceCamera(1);
                    }
                }
                if(g_bNotifyAdminActions) CGOPrintToChatAll("%t", "CHAT_AdminAction_ChangeForceCameraMode", iClient, g_iForceCameraQuota == 1 ? "EnableOther" : "DisableOther");

                if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N изменил режим просмотра за противоположной командой", iClient);
            }
            if(!strcmp(szInfo, "7")) ReloadConfig(iClient);


            g_hAdminMenu.DisplayAt(iClient, GetMenuSelectionPosition(), 0);
        }
        case MenuAction_DisplayItem:
        {
            char szInfo[2], szTitle[128], szTitleReady[128];
            hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));

            SetGlobalTransTarget(iClient);

            if(!strcmp(szInfo, "1")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t/n /n", szTitle, g_hCvar5.IntValue == 1 ? "Enable" : "Disable");
            else if(!strcmp(szInfo, "2")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle, g_iQuota);
            else if(!strcmp(szInfo, "3")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle, g_iMode);
            else if(!strcmp(szInfo, "4")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle, g_iQuotaMode);
            else if(!strcmp(szInfo, "5")) 
            {
                FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle, g_hCvar7.IntValue);
            }
            else if(!strcmp(szInfo, "6")) FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle, g_iForceCameraQuota == 1 ? "Enable" : "Disable");
            else FormatEx(szTitleReady, sizeof(szTitleReady), "%t", szTitle);
            return RedrawMenuItem(szTitleReady);
        }
        case MenuAction_DrawItem:
        {
            char szInfo[2];
            hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
            if(!strcmp(szInfo, "2") || !strcmp(szInfo, "3") || !strcmp(szInfo, "4") || !strcmp(szInfo, "5"))
            {
                if(g_iMode != 8 && g_hCvar5.IntValue == 1) return ITEMDRAW_DISABLED;
                if(!strcmp(szInfo, "5") && (g_iMode == 8 || g_iMode == 7 || g_iMode == 4 || g_iMode == 3)) return ITEMDRAW_DISABLED;
                if(!strcmp(szInfo, "4") && g_iQuota == 0) return ITEMDRAW_DISABLED;
            }
            if(!strcmp(szInfo, "6") && !g_bForceCameraMode) return ITEMDRAW_IGNORE;

            return ITEMDRAW_DEFAULT;
        }
    }

    return 0;
}

public void OnLibraryRemoved(const char[] szName)
{
    if (!strcmp(szName, "adminmenu"))
    {
        g_hTopMenu = null;
    }
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

    if (hTopMenu == g_hTopMenu)
    {
        return;
    }

    g_hTopMenu = hTopMenu;

    TopMenuObject hMyCategory = g_hTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);
    
    if (hMyCategory != INVALID_TOPMENUOBJECT)
    {
        g_hTopMenu.AddItem("dynamic_voice_mode", Handler_MenuVoiceSettings, hMyCategory, "voice_admin", ADMFLAG_ROOT, "Settings voice mode");
    }
}

public void Handler_MenuVoiceSettings(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            FormatEx(sBuffer, maxlength, TranslationPhraseExists("ADMINMENU_TitleSettings") ? "%t" : "s", "ADMINMENU_TitleSettings");
        }
        case TopMenuAction_SelectOption:
        {
            g_hAdminMenu.Display(iClient, 0);
        }
    }
}

public Action Admin_CmdCallBack(int iClient, int iArghs)
{
    if(!IsClientValid(iClient)) return;

    g_hAdminMenu.Display(iClient, 0);
}

public Action Main_CmdCallBack(int iClient, int iArghs)
{
    if(!IsClientValid(iClient)) return;
    
    g_hMainMenu.Display(iClient, 0);
}

public Action ReloadConfig_CmdCallBack(int iClient, int iArghs)
{
    if(!IsClientValid(iClient)) return;
    
    ReloadConfig(iClient);
}

public Action SetMode_CmdCallBack(int iClient, int iArghs)
{
    if(!IsClientValid(iClient)) return;

    if(iArghs > 0)
    {
        char sArg[128];
        int iMode;
        GetCmdArg(1, sArg, sizeof(sArg));
        iMode = StringToInt(sArg, 10);
        if(iMode > MAXMODE) iMode = MAXMODE;
        if(iMode < 0) iMode = 0;
        SetMode(iMode);
        CGOPrintToChat(iClient, "%t", "CHAT_ChangeModeCmd", iMode);
    }
    else
    {
        SetMode(g_iDefaultMode);
        CGOPrintToChat(iClient, "%t", "CHAT_ChangeModeCmd_Default");
    }

    if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N установил мод (%i)", iClient, g_iMode);
}

public Action VoiceEnable_CmdCallBack(int iClient, int iArghs)
{
    if(!IsClientValid(iClient)) return;

    if(iArghs > 0)
    {
        char sArg[3];
        GetCmdArg(1, sArg, sizeof(sArg));

        if(!strcmp(sArg, "on") || !strcmp(sArg, "1")) ChangeAllTalk(1, iClient);
        if(!strcmp(sArg, "off") || !strcmp(sArg, "0")) ChangeAllTalk(0, iClient);
        return;
    }
    
    ChangeAllTalk(-1, iClient);
}

void ReloadConfig(int iClient)
{
    LoadConfig();
    CGOPrintToChat(iClient, "%t", "CHAT_Reload_Config");

    if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N перезагрузил конфиг и восстановил настройки по умолчанию...", iClient);
}

void ChangeAllTalk(int iType, int iClient)
{
    if(iType == -1) iType = !g_hCvar5.IntValue;

    g_hCvar5.SetInt(iType);
    CGOPrintToChatAll("%t", "CHAT_Enable_Full_AllTalk", iClient, iType == 1 ? "EnableOther" : "DisableOther");

    if(g_bLogs) LogToFile(g_sLogPath, "Администратор %N %s общий голосовой чат", iClient, g_hCvar5.IntValue == 1 ? "включил" : "выключил");
}

void VoiceAll(int iClient, bool bAction)
{
    if(!IsClientValid(iClient)) return;
    if(bAction) SetClientListeningFlags(iClient, VOICE_LISTENALL | VOICE_SPEAKALL);
    else SetClientListeningFlags(iClient, VOICE_NORMAL);
}

void CheckMode()
{   
    int iCount;
    for(int i = 1; i <= MaxClients; i++)	if(IsClientValid(i))
    {
        if(g_iQuotaPriority == 1 && GetClientTeam(i) == CS_TEAM_CT) iCount++;
        else if(g_iQuotaPriority == 2 && GetClientTeam(i) == CS_TEAM_T) iCount++;
        else if(g_iQuotaPriority == 0) iCount++;
    }

    if(g_iQuota > 0 && g_iQuota <= iCount) 
    {
        SetMode(g_iQuotaMode);
        if(g_iForceCameraQuota > 0) SetForceCamera(g_iForceCameraQuota);
        if(g_iNotify == 1 || g_iNotify == 3) CGOPrintToChatAll("%t", "CHAT_Change_Mode");
        g_bQuotaEnable = true;
        return;
    }

    SetMode(g_iMainMode);
    if(g_iForceCameraQuota > 0 && g_iForceCameraQuota == 1) SetForceCamera(2);
    if(g_iForceCameraQuota > 0 && g_iForceCameraQuota == 2) SetForceCamera(1);

    if((g_iNotify == 1 || g_iNotify == 3) && g_bQuotaEnable)
    {
        g_bQuotaEnable = false;
        CGOPrintToChatAll("%t", "CHAT_Change_Mode_Default");
    }
}

void SetMode(int iMode, bool IsMainMode = false)
{
    if(iMode == 0 || g_iMode == iMode) return;

    if(g_iLastMode == 8 && g_iMode != 8 && iMode != 8) g_hCvar5.SetInt(0);

    switch(iMode)
    {
        case 1: SetCvar(0, 0, 0);
        case 2: SetCvar(0, 1, 0);
        case 3: SetCvar(1, 0, 0);
        case 4: SetCvar(1, 1, 0);
        case 5: SetCvar(0, 0, 1);
        case 6: SetCvar(0, 1, 1);
        case 7: SetCvar(1, 1, 1);
        case 8:
        {
            SetCvar(1, 1, 1);
            g_hCvar5.SetInt(1);
        }
    }

    g_iLastMode = g_iMode;
    if(g_iLastMode == 8) g_hCvar5.SetInt(0);
    if(IsMainMode) g_iMainMode = iMode;
    g_iMode = iMode;
}

void SetCvar(int iValue1, int iValue2, int iValue3)
{
    g_hCvar2.SetInt(iValue1);
    g_hCvar3.SetInt(iValue2);
    g_hCvar4.SetInt(iValue3);
}

void SetForceCamera(int iValue)
{
    if(iValue == 0) return;
    if(!g_bForceCameraMode) return;

    switch(iValue)
    {
        case 1: g_hCvar8.SetInt(1);
        case 2: g_hCvar8.SetInt(0);
    }
}

bool IsClientValid(int iClient)
{
    return (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient));
}

bool IsWarmup()
{
    return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}
