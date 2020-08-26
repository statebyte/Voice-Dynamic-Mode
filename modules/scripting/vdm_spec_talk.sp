#include <vdm_core>
#include <cstrike>
#include <csgo_colors>

#define FUNC_NAME       "spec_talk"
#define FUNC_PRIORITY   10

char		g_sPrefix[32];
bool        bState[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		=	"[VDM] Spectators Talk",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
}

public void OnPluginStart()
{
	HookEvent("player_team", Event_OnPlayerTeam);

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
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));
}

public Action Event_OnPlayerTeam(Event hEvent, char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    int iTeam = GetEventInt(hEvent, "team");

    if(iTeam == CS_TEAM_SPECTATOR)
    {
        bState[iClient] = true;
        VDM_SetPlayerMode(iClient, 3);
        CGOPrintToChat(iClient, "{GREEN}%s {DEFAULT}Вы перешли в наблюдатели и вам был включён общий голосовой чат.", g_sPrefix);
    }
    else if(iTeam != CS_TEAM_SPECTATOR && bState[iClient])
    {
        bState[iClient] = false;
        VDM_SetPlayerMode(iClient, 0);
        CGOPrintToChat(iClient, "{GREEN}%s {DEFAULT}Вам выключен общий голосовой чат.", g_sPrefix);
    }
}