#include <vdm_core>

#define PLUGIN_PRIORITY 10

int g_iRoundEndMode;

public void OnPluginStart()
{
    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
}

public void Event_OnRoundEnd(Event hEvent, char[] name, bool dontBroadcast)
{ 
    VDM_SetVoiceMode(g_iRoundEndMode, PLUGIN_PRIORITY);
}