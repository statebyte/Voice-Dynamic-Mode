#include <vdm_core>
#include <csgo_colors>

#define FUNC_NAME       "talk_after_dying_time"
#define FUNC_PRIORITY   10

#define MAX_TIME 		10
#define STEP_TIME 		1

ConVar 		g_hCvar;
bool		g_bUnHookCvar;
int 		g_iValue;
Handle      g_hTimerAfterDying[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		=	"[VDM] Talk After Dying Time",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	g_hCvar = FindConVar("sv_talk_after_dying_time");
	g_iValue = g_hCvar.IntValue;
	HookConVarChange(g_hCvar, Update_CV);

	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
}

public void Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; ++i) StopTimer(i);
}

public Action Event_OnPlayerDeath(Event hEvent, char[] name, bool dontBroadcast)
{
	int iMode = VDM_GetVoiceMode();
	if(g_iValue != 0 && iMode > 0 && iMode < 7)
	{
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
		if(IsClientValid(iClient)) 
		{
			CGOPrintToChat(iClient, "{LIGHTGREEN}[VDM] {GRAY}У вас есть {DEFAULT}%i {GRAY}сек на общение с живыми игроками...", g_iValue);
			g_hTimerAfterDying[iClient] = CreateTimer(float(g_iValue), Timer_CallBack, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	StopTimer(iClient);
}

public Action Timer_CallBack(Handle hTimer, any UserId)
{
	int iClient = GetClientOfUserId(UserId);
	if(IsClientValid(iClient)) CGOPrintToChat(iClient, "{LIGHTRED}[VDM] {GRAY}Живые игроки вас больше не слышат!!!");

	g_hTimerAfterDying[iClient] = null;
	return Plugin_Stop;
}

public void Update_CV(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	if(g_bUnHookCvar) return;
	g_iValue = StringToInt(szNewValue);
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

bool OnItemSelectMenu(int iClient)
{
	SetNewValue();
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "Общение после смерти [ %i ]", g_iValue);
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	return ITEMDRAW_DEFAULT;
}

void SetNewValue()
{
	g_bUnHookCvar = true;

	g_hCvar.IntValue += STEP_TIME;

	if(g_hCvar.IntValue > MAX_TIME) g_hCvar.IntValue = 0;

	g_iValue = g_hCvar.IntValue;

	g_bUnHookCvar = false;
}

stock bool IsClientValid(int iClient)
{
	return iClient && IsClientInGame(iClient) && !IsFakeClient(iClient);
}

stock void StopTimer(int iClient)
{
	if(g_hTimerAfterDying[iClient])
	{
		KillTimer(g_hTimerAfterDying[iClient]);
		g_hTimerAfterDying[iClient] = null;
	}
}