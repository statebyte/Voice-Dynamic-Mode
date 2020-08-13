public void Event_OnRoundStart(Event hEvent, char[] name, bool dontBroadcast)
{
	g_iLastPluginPriority = 0;
	SetMode(g_iMainMode);
	CallForward_OnSetVoiceModePost(g_iMainMode, true);
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
	if(hCvar == g_hCvar1 || hCvar == g_hCvar2 || hCvar == g_hCvar3 || hCvar == g_hCvar4 || hCvar == g_hCvar5)
	{
		SetMode(g_iMainMode);
		// Не когда не повторяйте моих ошибок!
		//CallForward_OnSetVoiceModePost(g_iMainMode);
	}
}