#include <vdm_core>
#include <csgo_colors>

#define FUNC_NAME       "full_alltalk"
#define FUNC_PRIORITY   11

bool g_bFullAllTalk;

char g_sPrefix[128];

public Plugin myinfo =
{
	name		=	"[VDM] Full AllTalk",
	version		=	"1.0.1",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vdm_fullalltalk.phrases");

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

public Action VDM_OnSetVoiceModePre(int& iMode, int iPluginPriority, char[] szFeature)
{
	if(FUNC_PRIORITY > iPluginPriority && g_bFullAllTalk)
	{
		iMode = VMODE_FULL_ALLTALK;
		return Plugin_Changed;
	}	

	return Plugin_Continue;
}

public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	CGOPrintToChatAll("%s %t", g_sPrefix, "FullAlltalk_Msg", g_bFullAllTalk ? "Msg_On" : "Msg_Off");
}

public void VDM_OnCoreIsReady()
{
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_ADMINMENU, OnItemSelectMenu, OnItemDisplayMenu, OnItemDrawMenu);
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));
}

bool OnItemSelectMenu(int iClient)
{
	g_bFullAllTalk = !g_bFullAllTalk;

	if(g_bFullAllTalk) VDM_SetVoiceMode(8);

	CGOPrintToChatAll("%s %t", g_sPrefix, "FullAlltalk_Msg", g_bFullAllTalk ? "Msg_On" : "Msg_Off");
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "%T [%T]", "Mode", iClient, (VDM_GetVoiceMode() == VMODE_FULL_ALLTALK && g_bFullAllTalk) ? "Msg_On" : "Msg_Off", iClient);
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}