#include <vdm_core>
#include <csgo_colors>

#define FUNC_NAME       "force_camera"
#define FUNC_PRIORITY   10
#define MESSAGE 		"{GREEN}[VDM] {DEFAULT}Режим Force Camera %s!"

ConVar 		g_hCvar;
int         g_iForceCameraMode,
			g_iForceCameraQuota;
bool        g_bForceCameraEnabled;

public Plugin myinfo =
{
	name		=	"[VDM] Force Camera",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	
	g_hCvar = FindConVar("mp_forcecamera");
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);

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
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_ADMINMENU, OnItemSelectMenu, OnItemDisplayMenu, OnItemDrawMenu);

	GetSettings(VDM_GetConfig());
}

public void VDM_OnConfigReloaded(KeyValues kv)
{
	GetSettings(kv);
}

bool OnItemSelectMenu(int iClient)
{
	g_bForceCameraEnabled = !g_bForceCameraEnabled;
	SetForceCamera(view_as<int>(g_bForceCameraEnabled));
	CGOPrintToChatAll(MESSAGE, g_bForceCameraEnabled ? "включён" : "выключен");
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "Режим ForceCamera [ %s ]", g_bForceCameraEnabled ? "Вкл" : "Выкл");
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) iCount++;

	if(g_iForceCameraQuota >= iCount) SetForceCamera(g_iForceCameraMode);
	else SetForceCamera(!g_iForceCameraMode);
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast) 
{ 
	SetForceCamera(0);
}

void SetForceCamera(int iValue)
{
	if(g_bForceCameraEnabled) g_hCvar.SetInt(iValue);
}

void GetSettings(KeyValues kv)
{
	g_iForceCameraMode = kv.GetNum("m_forcecamera", 1);
	g_iForceCameraQuota = kv.GetNum("m_forcecamera_quota", 8);
}