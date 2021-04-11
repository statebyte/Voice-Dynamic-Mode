#include <vdm_core>
#include <csgo_colors>
#include <sdktools_engine>

#define FUNC_NAME       "distance"
#define CLIENTFUNC_NAME "distance_client"
#define FUNC_PRIORITY   1

ConVar 	g_hCvar;
bool 	g_bClientEnable[MAXPLAYERS+1], 
		g_bHookMsg[MAXPLAYERS+1], 
		g_bMode[MAXPLAYERS+1],
		g_bDistanceEnabled;
int		g_iDistance = 1000,
		g_iQuota;

char	g_sPrefix[128];

public Plugin myinfo =
{
	name		=	"[VDM] Distance",
	version		=	"1.2",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vdm_distance.phrases");

	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	g_hCvar = FindConVar("sv_voice_proximity");

	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");

	RegAdminCmd("sm_voice_distance", cmd_OpenMenu, ADMFLAG_CHAT);
	RegConsoleCmd("sm_vo_debugde", cmd_Com);
}

public Action VDM_OnCheckPlayerListenStatusPre(int iClient, int iTarget, bool& bListen)
{
	if(IsPlayerAlive(iClient) && IsPlayerAlive(iTarget) && GetDistance(iClient, iTarget) >= float(g_iDistance)) 
	{
		//PrintToChatAll("%N не слышыт %N (%f)", iClient, iTarget, GetDistance(iClient, iTarget));
		if(GlobalVoiceProximity()) bListen = false;
		if(ClientVoiceProximity(iClient)) bListen = false;
	}
}

stock float GetDistance(int client, int target, bool eye = false)
{
	static float pos1[3], pos2[3];
	if(eye)
	{
		GetClientEyePosition(client, pos1);
		GetClientEyePosition(target, pos2);
	}
	else
	{
		GetClientAbsOrigin(client, pos1);
		GetClientAbsOrigin(target, pos2);
	}
	return GetVectorDistance(pos1, pos2);
}

Action cmd_OpenMenu(int iClient, int iArgs)
{
	OpenMenu(iClient);
	return Plugin_Handled;
}

Action Command_Say(int iClient, const char[] sCommand, int iArgs)
{
	char sValue[32];
	
	if(g_bHookMsg[iClient])
	{
		GetCmdArg(1, sValue, sizeof(sValue));
		
		g_iDistance = StringToInt(sValue);
		CGOPrintToChat(iClient, "%s %t", g_sPrefix, "NewValue", g_iDistance);
		UnHookMsg(iClient);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

Action cmd_Com(int iClient, int iArgs)
{
	ClientCommand(iClient, "cl_player_proximity_debug 1");
}

public void OnClientDisconnect(int iClient)
{
	g_bClientEnable[iClient] = false;
	g_bHookMsg[iClient] = false;
	g_bMode[iClient] = false;
}

public void OnPluginEnd()
{
	if (VDM_IsExistFeature(FUNC_NAME) && CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VDM_RemoveFeature") == FeatureStatus_Available)
	{
		VDM_RemoveFeature(FUNC_NAME);
		VDM_RemoveFeature(CLIENTFUNC_NAME);
	}
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	if(!g_bDistanceEnabled) GlobalVoiceProximity(0);
	int iCount;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) 
	{
		iCount++;
		ClientVoiceProximity(i, 0);
	}

	if(g_iQuota > 0 && iCount >= g_iQuota)
	{
		GlobalVoiceProximity(g_iDistance);
	}
}

public void VDM_OnCoreIsReady()
{
	GetSettings(VDM_GetConfig());
	
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_ADMINMENU, OnItemSelectMenu, OnItemDisplayMenu);
	VDM_AddFeature(CLIENTFUNC_NAME, FUNC_PRIORITY, MENUTYPE_SETTINGSMENU, ClientOnItemSelectMenu, ClientOnItemDisplayMenu);
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));
}

public void VDM_OnConfigReloaded(KeyValues kv)
{
	GetSettings(kv);
}

bool ClientOnItemSelectMenu(int iClient)
{
	bool bState;
	if((bState = ClientVoiceProximity(iClient))) ClientVoiceProximity(iClient, 0);
	else ClientVoiceProximity(iClient, g_iDistance);

	CGOPrintToChat(iClient, "%s %t", g_sPrefix, "SelectMode", bState ? "Mode_Off" : "Mode_On");
	return true;
}

bool ClientOnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	if(ClientVoiceProximity(iClient)) FormatEx(szDisplay, iMaxLength, "%t", "DistanceUser", g_iDistance);
	else FormatEx(szDisplay, iMaxLength, "%t", "DistanceOff");
	return true;
}

bool OnItemSelectMenu(int iClient)
{
	OpenMenu(iClient);

	return false;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "%t", "ModeDistance", g_iDistance);
	return true;
}

void OpenMenu(int iClient)
{
	Menu hMenu = new Menu(Handler_Menu);
	SetGlobalTransTarget(iClient);

	hMenu.SetTitle("[VDM] Distance\n \n");

	char szBuffer[256];
	FormatEx(szBuffer, sizeof(szBuffer), "%t", "DistanceValue", g_iDistance);
	hMenu.AddItem("value", szBuffer);
	
	if(GlobalVoiceProximity()) 
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%t", "DistanceGlobalOn");
		hMenu.AddItem("global", szBuffer);
	}
	else 
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%t", "DistanceGlobalOff");
		hMenu.AddItem("global", szBuffer);

		FormatEx(szBuffer, sizeof(szBuffer), "%t", "DistanceDisplay", g_bMode[iClient] ? "PlayersOn" : "PlayersOff");
		hMenu.AddItem("mode", szBuffer);

		AddPlayerList(hMenu, g_bMode[iClient]);
	}

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void AddPlayerList(Menu hMenu, bool bState)
{
	char szBuffer[2][64];

	int iCount;

	for(int i = 1; i < MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) if(ClientVoiceProximity(i) == bState)
	{
		FormatEx(szBuffer[0], sizeof(szBuffer[]), "%N", i);
		IntToString(i, szBuffer[1], sizeof(szBuffer[]));
		hMenu.AddItem(szBuffer[1], szBuffer[0]);
		iCount++;
	}

	if(iCount == 0) hMenu.AddItem(NULL_STRING, "No players...", ITEMDRAW_DISABLED);
}

int Handler_Menu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack) VDM_MoveToMenu(iClient, MENUTYPE_ADMINMENU);
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128], szBuffer[256];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));

			if(!strcmp(szInfo, "value"))
			{
				HookMsg(iClient);
				return 0;
			}

			if(!strcmp(szInfo, "global"))
			{
				bool bState;
				if((bState = GlobalVoiceProximity())) GlobalVoiceProximity(0);
				else GlobalVoiceProximity(g_iDistance);

				CGOPrintToChatAll("%s %t", g_sPrefix, "AdminSetMode", iClient, bState ? "Mode_Off" : "Mode_On", g_iDistance);
				Format(szBuffer, sizeof(szBuffer), "%s %t", g_sPrefix, "AdminSetMode", iClient, bState ? "Mode_Off" : "Mode_On", g_iDistance);
				VDM_LogMessage(szBuffer);
				OpenMenu(iClient);
				return 0;
			}

			if(!strcmp(szInfo, "mode"))
			{
				g_bMode[iClient] = !g_bMode[iClient];
				OpenMenu(iClient);
				return 0;
			}

			int iTarget = StringToInt(szInfo);
			if(ClientVoiceProximity(iTarget)) ClientVoiceProximity(iTarget, 0);
			else ClientVoiceProximity(iTarget, g_iDistance);

			CGOPrintToChatAll("%s %t", g_sPrefix, "AdminSetModeUser", iClient, ClientVoiceProximity(iTarget) ? "Mode_Off" : "Mode_On", iTarget, g_iDistance);
			Format(szBuffer, sizeof(szBuffer), "%s %t", g_sPrefix, "AdminSetModeUser", iClient, ClientVoiceProximity(iTarget) ? "Mode_Off" : "Mode_On", iTarget, g_iDistance);
			VDM_LogMessage(szBuffer);

			OpenMenu(iClient);
		}
	}

	return 0;
}

void HookMsg(int iClient)
{
	g_bHookMsg[iClient] = true;

	Menu hMenu = new Menu(Handler_HookMenu);

	hMenu.SetTitle("[VDM] Distance\n \n");

	hMenu.AddItem(NULL_STRING, "Enter a new value in the chat...", ITEMDRAW_DISABLED);

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void UnHookMsg(int iClient)
{
	g_bHookMsg[iClient] = false;

	OpenMenu(iClient);
}

int Handler_HookMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: UnHookMsg(iClient);
	}
	
	return 0;
}


/*
true - включено
false - выключено
*/
bool GlobalVoiceProximity(int iSet = -1)
{
	if(iSet == -1)
	{
		int iValue = g_hCvar.IntValue;

		if(iValue > 0) return true;
		else return false;
	}

	g_hCvar.IntValue = iSet;
	return true;
}

bool ClientVoiceProximity(int iClient, int iSet = -1)
{
	if(iSet == -1)
	{
		return g_bClientEnable[iClient];
	}

	char sValue[32];
	IntToString(iSet, sValue, sizeof(sValue));
	SendConVarValue(iClient, g_hCvar, sValue);

	if(iSet > 0) g_bClientEnable[iClient] = true;
	else g_bClientEnable[iClient] = false;

	return true;
}

void GetSettings(KeyValues kv)
{
	g_bDistanceEnabled = view_as<bool>(kv.GetNum("m_distance_enabled", 0));
	g_iDistance = kv.GetNum("m_distance", 1000);
	g_iQuota = kv.GetNum("m_distance_quota", 0);

	if(g_bDistanceEnabled) GlobalVoiceProximity(g_iDistance);
	else GlobalVoiceProximity(0);
}