public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	SetMode(g_iMainMode);
	CallForward_OnSetVoiceModePost(g_iMainMode, 0, "round_start");
}

public Action Event_Cvar(Handle hEvent, const char[] name, bool dontBroadcast)
{
	if(!g_bBlockEvents) return Plugin_Continue;
	char cvarname[64]; 
	GetEventString(hEvent, "cvarname", cvarname, sizeof(cvarname));

	if(!strcmp("sv_alltalk", cvarname)) return Plugin_Handled;
	if(!strcmp("sv_deadtalk", cvarname)) return Plugin_Handled;

	return Plugin_Continue;
}

public void Update_CV(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	if(!g_bHookCvars) return;

	char szBuffer[64];
	SetMode(g_iMode);
	GetConVarName(hCvar, szBuffer, sizeof(szBuffer));
	PrintToServer("[VDM] - Hook Convar (%s)", szBuffer);
	// Не когда не повторяйте моих ошибок!
	//CallForward_OnSetVoiceModePost(g_iMainMode);
}