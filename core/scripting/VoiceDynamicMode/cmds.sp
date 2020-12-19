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
		CGOPrintToChat(iClient, "%s %T", g_sPrefix, "NO_ACCESS", iClient);
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

	VDM_LogMessage("VDM Version: %s (ID: %i)", VDM_VERSION, VDM_INT_VERSION);
	VDM_LogMessage("---");

	if(iSize == 0)
	{
		VDM_LogMessage("Modules not loaded...");
		VDM_LogMessage("---");
		return;
	}

	VDM_LogMessage("Feature List:");
	VDM_LogMessage("---");

	char szBuffer[4][128];

	for(int i; i < iSize; i++)
	{
		g_hNameItems.GetString(i, szBuffer[0], sizeof(szBuffer[]));
		VDM_LogMessage("[%i] %s", i, szBuffer[0]);
	}

	VDM_LogMessage("---");

	any aArray[6];
	for(int i; i < iSize; i++)
	{
		g_hItems.GetArray(i, aArray, 6);

		GetPluginFilename(aArray[F_PLUGIN], szBuffer[0], sizeof(szBuffer[]));
		GetPluginInfo(aArray[F_PLUGIN], PlInfo_Name, szBuffer[1], sizeof(szBuffer[]));
		GetPluginInfo(aArray[F_PLUGIN], PlInfo_Version, szBuffer[2], sizeof(szBuffer[]));
		GetPluginInfo(aArray[F_PLUGIN], PlInfo_Author, szBuffer[3], sizeof(szBuffer[]));
		VDM_LogMessage("[%i] [%s] %s (%s) by %s", i, szBuffer[0], szBuffer[1], szBuffer[2], szBuffer[3]);
	}

	VDM_LogMessage("---");

	VDM_LogMessage("All feature count: %i", iSize);
}

void ReloadConfig(int iClient)
{
	LoadConfig();
	CallForward_OnConfigReloaded();
	if(iClient) CGOPrintToChat(iClient, "%s %t", g_sPrefix, "CHAT_SETTINGS_RELOADED");
	PrintToServer("[VDM] - Settings reloaded...");
}

void ReloadModules(int iClient)
{
	if(g_iReloadModules)
	{
		int iSize = g_hNameItems.Length;
		char szBuffer[PLATFORM_MAX_PATH];

		any aArray[6];
		for(int i; i < iSize; i++)
		{
			g_hItems.GetArray(i, aArray, 6);
			GetPluginFilename(aArray[F_PLUGIN], szBuffer, sizeof(szBuffer));
			ServerCommand("sm plugins reload %s", szBuffer);
		}
	}
	
	g_hNameItems.Clear();
	g_hItems.Clear();

	CallForward_OnCoreIsReady();
	if(iClient) CGOPrintToChat(iClient, "%s %t", g_sPrefix, "CHAT_MODULES_RELOADED");
	PrintToServer("[VDM] - Modules reloaded...");
}