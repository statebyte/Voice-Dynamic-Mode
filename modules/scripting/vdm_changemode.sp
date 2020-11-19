#include <vdm_core>

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
	ChangeMode();
}

bool OnItemSelectMenu(int iClient)
{
	ChangeMode();
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	int iMode = VDM_GetVoiceMode();
	FormatEx(szDisplay, iMaxLength, "Текущий режим [ %i ]", iMode);
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

void ChangeMode(int iModeType = 0)
{
	int iMode = VDM_GetVoiceMode();

	if(iMode >= VMODE_COUNT-1) VDM_SetVoiceMode(VMODE_NOVOICE, iModeType);
	else
	{
		iMode++;
		VDM_SetVoiceMode(iMode, iModeType);
	}

	
}