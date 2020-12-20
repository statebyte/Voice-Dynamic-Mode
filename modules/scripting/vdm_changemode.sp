#include <vdm_core>
#include <csgo_colors>

#define FUNC_NAME       "changemode"
#define FUNC_NAMETWO    "change_main_mode"
#define FUNC_PRIORITY   1

#define FUNC_COMMAND    "sm_vochange"

public Plugin myinfo =
{
	name		=	"[VDM] Change Mode",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vdm_core.phrases");

	RegConsoleCmd(FUNC_COMMAND, cmd_VoChange);

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
	VDM_AddFeature(FUNC_NAME, FUNC_PRIORITY, MENUTYPE_ADMINMENU, OnItemSelectMenu, OnItemDisplayMenu, OnItemDrawMenu);
}

Action cmd_VoChange(int iClient, int iArgs)
{
	ChangeMode(iClient);

	return Plugin_Handled
}

bool OnItemSelectMenu(int iClient)
{
	ChangeMode(iClient);
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	int iMode = VDM_GetVoiceMode();
	FormatEx(szDisplay, iMaxLength, "%T", "VDM_CHANGEMODE_Mode", iClient, iMode);
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

void ChangeMode(int iClient, int iModeType = 0)
{
	int iMode = VDM_GetVoiceMode();

	if(iMode >= VMODE_COUNT-1) VDM_SetVoiceMode(VMODE_NOVOICE, iModeType);
	else
	{
		iMode++;
		VDM_SetVoiceMode(iMode, iModeType);
	}

	Notify(iClient);
}

void Notify(int iClient)
{
	char szBuffer[256];

	SetGlobalTransTarget(iClient);

	switch(VDM_GetVoiceMode())
	{
		case VMODE_NOVOICE: 						FormatEx(szBuffer, sizeof(szBuffer), "%t", "Noone");
		case VMODE_ALIVE_OR_DEAD_TEAM: 				FormatEx(szBuffer, sizeof(szBuffer), "ALIVE: %t\nDEAD: %t", "YH_1_2A", "YH_1_3");
		case VMODE_ALIVE_OR_DEAD_ENEMY: 			FormatEx(szBuffer, sizeof(szBuffer), "ALIVE: %t\nDEAD: %t", "YH_1_2A", "YH_2");
		case VMODE_TEAM_ONLY: 						FormatEx(szBuffer, sizeof(szBuffer), "ALIVE: %t\nDEAD: %t", "YH_3_4A", "YH_1_3");
		case VMODE_ALIVE_ONLY: 						FormatEx(szBuffer, sizeof(szBuffer), "ALIVE: %t\nDEAD: %t", "YH_3_4A", "YH_4_5");
		case VMODE_ALIVE_DEAD_WITH_ENEMY: 			FormatEx(szBuffer, sizeof(szBuffer), "ALIVE: %t\nDEAD: %t", "YH_5_6A", "YH_4_5");
		case VMODE_ALIVE_OR_DEAD_TEAM_WITH_ENEMY: 	FormatEx(szBuffer, sizeof(szBuffer), "ALIVE: %t\nDEAD: %t", "YH_5_6A", "YH_6");
		case VMODE_ALLTALK: 						FormatEx(szBuffer, sizeof(szBuffer), "%t", "YH_7");
		case VMODE_FULL_ALLTALK: 					FormatEx(szBuffer, sizeof(szBuffer), "%t", "YH_8");
	}

	CGOPrintToChat(iClient, szBuffer);
}