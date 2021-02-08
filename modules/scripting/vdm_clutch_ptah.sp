#include <cstrike>
#include <vdm_core>
#include <csgo_colors>
#include <PTaH>
#include <clientprefs>

#define FUNC_NAME       "clutch_mode_ptah"
#define FUNC_PRIORITY   10

int     g_iClutchMode[MAXPLAYERS+1];
bool    g_bClutchModeActive[MAXPLAYERS+1];

Handle  hCookie;
char	g_sPrefix[32];

public Plugin myinfo =
{
	name		=	"[VDM] Clutch Mode (PTaH Edition)",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vdm_clutch.phrases");

	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	if(PTaH_Version() < 101000) SetFailState("PTaH is older to use this module.");
	
	PTaH(PTaH_ClientVoiceToPre, Hook, CVP);

	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);

	hCookie = RegClientCookie("VDM_ClutchMode", "VDM_ClutchMode", CookieAccess_Public);

	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
}

public void OnClientCookiesCached(int iClient)
{
	char szBuffer[4];
	GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));

	if(szBuffer[0]) g_iClutchMode[iClient] = StringToInt(szBuffer);
	else g_iClutchMode[iClient] = -1;
}

public void OnClientDisconnect(int iClient)
{
	if(g_iClutchMode[iClient] > -1) 
	{
		char sBuf[4];
		IntToString(g_iClutchMode[iClient], sBuf, sizeof(sBuf));
		SetClientCookie(iClient, hCookie, sBuf);
	}
}

public void OnPluginEnd()
{
	if (VDM_IsExistFeature(FUNC_NAME) && CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VDM_RemoveFeature") == FeatureStatus_Available)
	{
		VDM_RemoveFeature(FUNC_NAME);
	}
}

public void VDM_OnCoreIsReady()
{
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_SETTINGSMENU, OnItemSelectMenu, OnItemDisplayMenu, OnItemDrawMenu);
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));
}

bool OnItemSelectMenu(int iClient)
{
	g_iClutchMode[iClient] += 1;
	if(g_iClutchMode[iClient] > 1) g_iClutchMode[iClient] = -1;

	char sBuf[256];

	switch(g_iClutchMode[iClient])
	{
		case -1: FormatEx(sBuf, sizeof(sBuf), "%T", "Clutch_Off", iClient);
		case 0: FormatEx(sBuf, sizeof(sBuf), "%T", "Clutch_On_1", iClient);
		case 1: FormatEx(sBuf, sizeof(sBuf), "%T", "Clutch_On_2", iClient);
	}

	CGOPrintToChat(iClient, "%s %s", g_sPrefix, sBuf);

	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	char sBuf[32];
	switch(g_iClutchMode[iClient])
	{
		case -1: FormatEx(sBuf, sizeof(sBuf), "%T", "Mode_Off", iClient);
		case 0: FormatEx(sBuf, sizeof(sBuf), "%T", "Mode_All", iClient);
		case 1: FormatEx(sBuf, sizeof(sBuf), "%T", "Mode_Dead", iClient);
	}

	FormatEx(szDisplay, iMaxLength, "%T", "Mode", iClient, sBuf);
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

public Action Event_OnPlayerDeath(Event hEvent, char[] name, bool dontBroadcast)
{
	int iCount_T, iCount_CT, iLastClientCT, iLastClientT;
	for(int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i) && IsPlayerAlive(i))
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
	if(g_iClutchMode[iClient] == -1 || g_bClutchModeActive[iClient]) return;

	g_bClutchModeActive[iClient] = true;

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		if(iClient == i) CGOPrintToChat(i, "%s %t", g_sPrefix, "Clutch_Msg_1", g_iClutchMode[iClient] == 1 ? "Mode_Dead" : "Mode_All");
		else CGOPrintToChat(i, "%s %t", g_sPrefix, "Clutch_Msg_2", iClient, g_iClutchMode[iClient] == 1 ? "Mode_Dead" : "Mode_All");
	}
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast) 
{ 
	for(int i = 1; i <= MaxClients; i++) g_bClutchModeActive[i] = false;
}

public Action CVP(int iClient, int iTarget, bool& bListen)
{
	if(!IsClientInGame(iClient) || !IsClientInGame(iTarget)) return Plugin_Continue;

	bListen = VDM_GetPlayerListenStatus(iClient, iTarget);
	
	//PrintHintText(iTarget, "--- Вы слушаете: %N", iClient);

	if(g_iClutchMode[iTarget] > -1 && g_bClutchModeActive[iTarget])
	{
		if(g_iClutchMode[iTarget] == 0) 
		{
			//PrintToConsole(iTarget, "STOP VOICE: %N", iClient);
			return Plugin_Handled;
		}
		if(g_iClutchMode[iTarget] == 1 && !IsPlayerAlive(iClient))
		{
			//PrintToConsole(iTarget, "STOP VOICE: %N", iClient);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}