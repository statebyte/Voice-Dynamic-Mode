#include <vdm_core>
#include <csgo_colors>

#define DISTANCE 		1000
#define FUNC_NAME       "distance"
#define CLIENTFUNC_NAME "distance_client"
#define FUNC_PRIORITY   1

ConVar 	g_hCvar;
bool 	g_bClientEnable[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		=	"[VDM] Distance",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	g_hCvar = FindConVar("sv_voice_proximity");

	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);

	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();

	RegConsoleCmd("sm_vo_debugde", cmd_Com);
}

Action cmd_Com(int iClient, int iArgs)
{
	ClientCommand(iClient, "cl_player_proximity_debug 1");
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
	GlobalVoiceProximity(0);
}

public void VDM_OnCoreIsReady()
{
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_ADMINMENU, OnItemSelectMenu, OnItemDisplayMenu);
	VDM_AddFeature(CLIENTFUNC_NAME, FUNC_PRIORITY, MENUTYPE_SETTINGSMENU, ClientOnItemSelectMenu, ClientOnItemDisplayMenu);
}

bool ClientOnItemSelectMenu(int iClient)
{
	bool bState;
	if((bState = ClientVoiceProximity(iClient))) ClientVoiceProximity(iClient, 0);
	else ClientVoiceProximity(iClient, DISTANCE);

	g_bClientEnable[iClient] = !bState;

	CGOPrintToChatAll("{GREEN}[VDM] {DEFAULT}Вы %s режим дистанции", bState ? "выключил" : "включил");
	return true;
}

bool ClientOnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	if(ClientVoiceProximity(iClient)) FormatEx(szDisplay, iMaxLength, "Дистанция [ %i ]", DISTANCE);
	else FormatEx(szDisplay, iMaxLength, "Дистанция [ Выкл ]");
	return true;
}

bool OnItemSelectMenu(int iClient)
{
	bool bState;
	if((bState = GlobalVoiceProximity())) GlobalVoiceProximity(0);
	else GlobalVoiceProximity(DISTANCE);

	CGOPrintToChat(iClient, "{GREEN}[VDM] {DEFAULT}Администратор %N %s режим дистанции", iClient, bState ? "выключили" : "включили");
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	if(GlobalVoiceProximity()) FormatEx(szDisplay, iMaxLength, "Режим Дистанции [ %i ]", DISTANCE);
	else FormatEx(szDisplay, iMaxLength, "Режим Дистанции [ Выкл ]");
	return true;
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
	return true;
}