#include <vdm_core>
#include <PTaH>
#include <csgo_colors>

#define FUNC_NAME       "admin_talk"
#define FUNC_PRIORITY   1

int g_iTarget = -1;

public Plugin myinfo =
{
	name		=	"[VDM] Admin Talk (PTaH)",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	PTaH(PTaH_ClientVoiceToPre, Hook, CVP);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);

	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
}

public void OnClientPutInServer(int iClient)
{
	if(g_iTarget == iClient) g_iTarget = -1;
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	g_iTarget = -1;
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
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_ADMINMENU, OnItemSelectMenu, OnItemDisplayMenu, OnItemDrawMenu);
}

bool OnItemSelectMenu(int iClient)
{
	if(g_iTarget == -1) g_iTarget = iClient;
	else g_iTarget = -1;

	CGOPrintToChatAll("{GREEN}[VDM] {DEFAULT}Администратор %N %s админский режим", iClient, g_iTarget == -1 ? "выключил" : "включил");
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	if(g_iTarget != -1) FormatEx(szDisplay, iMaxLength, "Режим Админа [ %N ]", g_iTarget);
	else FormatEx(szDisplay, iMaxLength, "Режим Админа [ Выкл ]");
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	if(g_iTarget == -1 || g_iTarget == iClient) return ITEMDRAW_DEFAULT;
	else return ITEMDRAW_DISABLED;
}

public Action CVP(int iClient, int iTarget, bool& bListen)
{
	if(g_iTarget != -1)
	{
		if(!IsClientInGame(iClient) || !IsClientInGame(iTarget)) return Plugin_Continue;
		if(iClient != g_iTarget) return Plugin_Handled;

		PrintHintTextToAll("Говорит %N | Режим админа", iClient);
	}

	return Plugin_Continue;
}