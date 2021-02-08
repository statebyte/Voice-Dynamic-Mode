#include <vdm_core>
#include <sdktools>
#include <csgo_colors>

#define FUNC_NAME       "talk_after_dying_time"
#define FUNC_PRIORITY   10

#define MAX_TIME 		10	
#define STEP_TIME 		1

ConVar 		g_hCvar;
bool		g_bUnHookCvar, 
			g_bFixTimers[MAXPLAYERS+1];
int 		g_iValue;
Handle		g_hTimerAfterDying[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
char		g_sPrefix[32];

public Plugin myinfo =
{
	name		=	"[VDM] Talk After Dying Time",
	version		=	"1.0.3",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	g_hCvar = FindConVar("sv_talk_after_dying_time");
	g_iValue = g_hCvar.IntValue;
	HookConVarChange(g_hCvar, Update_CV);

	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	LoadTranslations("vdm_modules.phrases");

	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
}

public void Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++) StopTimer(i);
}

public Action Event_OnPlayerDeath(Event hEvent, char[] name, bool dontBroadcast)
{
	int iMode = VDM_GetVoiceMode();
	if(!IsWarmup() && g_iValue != 0 && iMode > 0 && iMode < 7)
	{
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
		//PrintToServer("Event_OnPlayerDeath - %i", iClient);
	
		if(IsClientValid(iClient)) 
		{
			StopTimer(iClient);
			CGOPrintToChat(iClient, "{LIGHTGREEN}%s %t", g_sPrefix, "MODULE_TADT", g_iValue);
			g_hTimerAfterDying[iClient] = CreateTimer(float(g_iValue), Timer_CallBack, GetClientUserId(iClient));
			g_bFixTimers[iClient] = true;
		}
	}
}

public void OnClientDisconnect_Post(int iClient)
{
	//PrintToServer("OnClientDisconnect_Post - %i", iClient);
	StopTimer(iClient);
	g_hTimerAfterDying[iClient] = INVALID_HANDLE;
}

public Action Timer_CallBack(Handle hTimer, any UserId)
{
	int iClient = GetClientOfUserId(UserId);

	//PrintToServer("0x%08x - 0x%08x", g_hTimerAfterDying[iClient], hTimer);
	if(IsClientValid(iClient) && !IsPlayerAlive(iClient)) 
	{
		CGOPrintToChat(iClient, "{LIGHTGREEN}%s {DEFAULT}%t", g_sPrefix, "MODULE_TADT2");
	}

	//PrintToChatAll(">>> Зануляем...");
	g_bFixTimers[iClient] = false;
	g_hTimerAfterDying[iClient] = INVALID_HANDLE;
	return Plugin_Stop;
}

void StopTimer(int iClient)
{
	//PrintToChatAll(">>> УДАЛЯЕМ ТАЙМЕР");
	if(g_bFixTimers[iClient])
	{
		g_bFixTimers[iClient] = false;
		//PrintToChatAll(">>> ТАЙМЕР ВАЛИДНЫЙ");
		KillTimer(g_hTimerAfterDying[iClient], false);
		g_hTimerAfterDying[iClient] = INVALID_HANDLE;
	}
}

stock bool IsClientValid(int iClient)
{
	return iClient && IsClientInGame(iClient) && !IsFakeClient(iClient);
	//return iClient && IsClientInGame(iClient);
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
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));
	GetSettings(VDM_GetConfig());
}

public void VDM_OnConfigReloaded(KeyValues kv)
{
	GetSettings(kv);
}

void GetSettings(KeyValues kv)
{
	int iValue = kv.GetNum("m_tadt", 5);
	SetNewValue(iValue);
}

bool OnItemSelectMenu(int iClient)
{
	SetNewValue();
	return true;
}

bool OnItemDisplayMenu(int iClient, char[] szDisplay, int iMaxLength)
{
	if(g_iValue == 0) FormatEx(szDisplay, iMaxLength, "%t [ %t ]", "MODULE_TADT_TITLE", "DISABLED");
	else FormatEx(szDisplay, iMaxLength, "%t [ %i %t ]", "MODULE_TADT_TITLE", g_iValue, "SECONDS");
	return true;
}

int OnItemDrawMenu(int iClient, int iStyle)
{
	if(VDM_GetVoiceMode() > 6) return ITEMDRAW_DISABLED;
	return ITEMDRAW_DEFAULT;
}

void SetNewValue(int iValue = -1)
{
	g_bUnHookCvar = true;

	if(iValue == -1)
	{
		g_hCvar.IntValue += STEP_TIME;
		if(g_hCvar.IntValue > MAX_TIME) g_hCvar.IntValue = 0;
	}
	else g_hCvar.IntValue = iValue;

	g_iValue = g_hCvar.IntValue;

	g_bUnHookCvar = false;
}

bool IsWarmup()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod", 1));
}