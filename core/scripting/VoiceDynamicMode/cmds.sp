Action cmd_Voice(int iClient, int iArgs)
{
	if(!iClient) return;
	OpenMenu(iClient, MENUTYPE_MAINMENU);
}

Action cmd_Admin(int iClient, int iArgs)
{
	if(!iClient) return;
	if(!CheckAdminAccess(iClient))
	{
		PrintToConsole(iClient, "[VDM] У вас нет доступа к этой команде!");
		CGOPrintToChat(iClient, "{GREEN}%s {DEFAULT}У вас нет доступа к этой команде!", g_sPrefix);
		return;
	}
	OpenMenu(iClient, MENUTYPE_ADMINMENU);
}

Action cmd_Reload(int iClient, int iArgs)
{
	ReloadConfig(iClient);
	ReloadModules(iClient);
}

Action cmd_Dump(int iClient, int iArgs)
{
	int iSize = g_hNameItems.Length;

	VDM_LogMessage("VDM Version: %s", VDM_VERSION);
	VDM_LogMessage("---");
	VDM_LogMessage("Feature List:");
	VDM_LogMessage("---");

	if(iSize == 0)
	{
		VDM_LogMessage("Modules not loaded...");
		return;
	}

	char szBuffer[128];

	for(int i; i < iSize; i++)
	{
		g_hNameItems.GetString(i, szBuffer, sizeof(szBuffer));
		VDM_LogMessage("[%i] %s", i, szBuffer);
	}

	VDM_LogMessage("---");
	VDM_LogMessage("All modules list: %i", iSize);
}

void ReloadConfig(int iClient)
{
	LoadConfig();
	CallForward_OnConfigReloaded();
	if(iClient) CGOPrintToChat(iClient, "{GREEN}%s {DEFAULT}%t", g_sPrefix, "CHAT_SETTINGS_RELOADED");
	PrintToServer("[VDM] - Settings reloaded...");
}

void ReloadModules(int iClient)
{
	g_hNameItems.Clear();
	g_hItems.Clear();
	
	CallForward_OnCoreIsReady();
	if(iClient) CGOPrintToChat(iClient, "{GREEN}%s {DEFAULT}%t", g_sPrefix, "CHAT_MODULES_RELOADED");
	PrintToServer("[VDM] - Modules reloaded...");
}