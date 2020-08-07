Action cmd_Voice(int iClient, int iArgs)
{
	if(!iClient) return;
	OpenMenu(iClient);
}

Action cmd_Admin(int iClient, int iArgs)
{
	if(!iClient) return;
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

	if(iSize == 0)
	{
		VDM_LogMessage("Модули не загружены...");
		return;
	}

	char szBuffer[128];

	for(int i; i < iSize; i++)
	{
		g_hNameItems.GetString(i, szBuffer, sizeof(szBuffer));
		VDM_LogMessage("%i - %s", i, szBuffer);
	}

	VDM_LogMessage("---");
	VDM_LogMessage("Общее кол-во модулей: %i", iSize);
}

void ReloadConfig(int iClient)
{
	LoadConfig();
	CallForward_OnConfigReloaded();
	CGOPrintToChat(iClient, "{GREEN}[VDM] {DEFAULT}Настройки перезагружены");
}

void ReloadModules(int iClient)
{
	g_hNameItems.Clear();
	g_hItems.Clear();
	
	CallForward_OnCoreIsReady();
	CGOPrintToChat(iClient, "{GREEN}[VDM] {DEFAULT}Модули перезагружены");
}