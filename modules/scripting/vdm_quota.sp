#include <vdm_core>
#include <cstrike>

#define FUNC_NAME       "quota_mode"
#define FUNC_PRIORITY   10

int     g_iQuota, 
		g_iQuotaMode, 
		g_iQuotaPriority;

public Plugin myinfo =
{
	name		=	"[VDM] Quota Mode Round Start",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	if(VDM_GetVersion() < 020000) SetFailState("VDM Core is older to use this module.");
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
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY);
	GetSettings(VDM_GetConfig());
}

public void VDM_OnConfigReloaded(KeyValues kv)
{
	GetSettings(kv);
}

public void VDM_OnSetVoiceModePost(int iMode, int iPluginPriority, char[] szFeature)
{
	if(!strcmp(szFeature, "round_start")) RequestFrame(CheckQuotaMode);
}

void CheckQuotaMode()
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		if(g_iQuotaPriority == 1 && GetClientTeam(i) == CS_TEAM_CT) iCount++;
		else if(g_iQuotaPriority == 2 && GetClientTeam(i) == CS_TEAM_T) iCount++;
		else if(g_iQuotaPriority == 0) iCount++;
	}

	if(g_iQuota > 0 && g_iQuota <= iCount) VDM_SetVoiceMode(g_iQuotaMode);
}

void GetSettings(KeyValues kv)
{
	g_iQuota = kv.GetNum("m_quota", 8);
	g_iQuotaPriority = kv.GetNum("m_quotapriority", 0);
	g_iQuotaMode = kv.GetNum("m_quotamode", 6);
}