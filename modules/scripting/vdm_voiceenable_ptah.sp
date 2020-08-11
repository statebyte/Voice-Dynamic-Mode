#include <vdm_core>
#include <csgo_colors>
#include <PTaH>

#define FUNC_NAME       "voice_enable"
#define FUNC_PRIORITY   10

#define REMIND_MESSAGE  "{GREEN}[VDM] {RED}Не забудьте, что вы выключили голосовой чат!"
#define MESSAGE 		"{GREEN}[VDM] {DEFAULT}Вы %s голосовой чат!"

bool g_bVoiceDisable[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		=	"[VDM] Voice Enable (PTaH Edition)",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	if(PTaH_Version() < 101000) SetFailState("PTaH is older to use this module.");

	PTaH(PTaH_ClientVoiceToPre, Hook, CVP);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);

	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
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
}

bool OnItemSelectMenu(int iClient)
{
	g_bVoiceDisable[iClient] = !g_bVoiceDisable[iClient];
	CGOPrintToChatAll(MESSAGE, g_bVoiceDisable[iClient] ? "выключили" : "включили");
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "Голосовой чат [ %s ]", g_bVoiceDisable[iClient] ? "Выкл" : "Вкл");
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && g_bVoiceDisable[i])
	{
		CGOPrintToChat(i, REMIND_MESSAGE);
	}
}

public Action CVP(int iClient, int iTarget, bool& bListen)
{
	if(!IsClientInGame(iClient) || !IsClientInGame(iTarget)) return Plugin_Continue;
	if(g_bVoiceDisable[iTarget]) return Plugin_Handled;

	return Plugin_Continue;
}