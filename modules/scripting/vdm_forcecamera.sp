#include <vdm_core>
#include <csgo_colors>

#define FUNC_NAME       "force_camera"
#define FUNC_PRIORITY   10

ConVar		g_hCvar;
int			g_iForceCameraQuota;

bool		g_bForceCameraDefault,
			g_bForceCamera;

char		g_sPrefix[128];

public Plugin myinfo =
{
	name		=	"[VDM] Force Camera",
	version		=	"1.0.2",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vdm_forcecamera.phrases");

	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
	
	g_hCvar = FindConVar("mp_forcecamera");
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);

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
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));

	GetSettings(VDM_GetConfig());
}

public void VDM_OnConfigReloaded(KeyValues kv)
{
	GetSettings(kv);
	CheckPlayer();
}

bool OnItemSelectMenu(int iClient)
{
	SetForceCamera(!g_bForceCamera);
	CGOPrintToChatAll("%s %t", g_sPrefix, "ForceCamera_Msg", g_bForceCamera ? "Msg_On" : "Msg_Off");
	
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "%T [%T]", "Mode", iClient, g_bForceCamera ? "Msg_On" : "Msg_Off", iClient);

	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	CheckPlayer();
}

void CheckPlayer()
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1) iCount++;

	if(iCount >= g_iForceCameraQuota) SetForceCamera(g_bForceCameraDefault);
	else SetForceCamera(!g_bForceCameraDefault);
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast) 
{ 
	// Фикс, чтобы игроки могли следить за всеми в конце раунда...
	SetForceCamera(false);
}

void SetForceCamera(bool bState)
{
	int iValue = view_as<int>(bState);
	g_bForceCamera = bState;
	g_hCvar.SetInt(iValue);
}

void GetSettings(KeyValues kv)
{
	g_bForceCameraDefault = view_as<bool>(kv.GetNum("m_forcecamera", 1));
	g_iForceCameraQuota = kv.GetNum("m_forcecamera_quota", 8);
}