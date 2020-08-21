#include <vdm_core>

#define FUNC_NAME       "round_end"
#define FUNC_PRIORITY   10

int g_iRoundEndMode;

public Plugin myinfo =
{
	name		=	"[VDM] RoundEnd",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);

    if(VDM_CoreIsLoaded())
	{
		VDM_OnCoreIsReady();
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
    VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY);
    
    KeyValues kv = VDM_GetConfig();
    g_iRoundEndMode = kv.GetNum("m_roundend", VMODE_FULL_ALLTALK);
    delete kv;
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast)
{ 
    VDM_SetVoiceMode(g_iRoundEndMode);
}