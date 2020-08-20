
void LoadConfig()
{
	//////////////////////////////////////////////////////////////////////////////////
	BuildPath(Path_SM, g_sPathLogs, sizeof(g_sPathLogs), PATH_TO_LOGS);
	//////////////////////////////////////////////////////////////////////////////////
	
	if(g_kvConfig) delete g_kvConfig;
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, PATH_TO_CONFIG);

	g_kvConfig = new KeyValues("VoiceDynamicMode");

	if(!g_kvConfig.ImportFromFile(sPath))
	{
		SetFailState("[VDM] Core - config is not found (%s).", sPath);
	}
	g_kvConfig.Rewind();


	g_iMode = g_kvConfig.GetNum("mode", 0);
	if(g_iMode > MAX_MODES) g_iMode = MAX_MODES;
	if(g_iMode < 0) g_iMode = 0;
	g_iDefaultMode = g_iMode;
	g_iMainMode = g_iMode;
	
	g_bTalkOnWarmup = view_as<bool>(g_kvConfig.GetNum("talk_on_warmup", 0));

	g_iChangeDynamicMode = g_kvConfig.GetNum("update_time", 0);

	g_kvConfig.GetString("admin_menu_flag", g_sAdminFlag, sizeof(g_sAdminFlag), "z");
	if(!g_sAdminFlag[0]) g_sAdminFlag[0] = 'z';
	g_kvConfig.GetString("prefix", g_sPrefix, sizeof(g_sPrefix), "VDM");
	//PrintToServer("--- %s", g_sAdminFlag);

	g_iDynamicMenu = g_kvConfig.GetNum("menu_dynamic", 2);

	g_bBlockEvents = view_as<bool>(g_kvConfig.GetNum("block_events", 0));
	g_bHookCvars = view_as<bool>(g_kvConfig.GetNum("hook_events", 0));
	g_bLogs = view_as<bool>(g_kvConfig.GetNum("logs", 0));

	RegConsoleCmds();
	CallForward_OnConfigReloaded();
}

void RegConsoleCmds()
{
	if(g_bCoreIsLoaded) return;
	g_kvConfig.Rewind();

	char szBuffer[256], szCommands[16][16];
	int iSize;
	g_kvConfig.GetString("commands", szBuffer, sizeof szBuffer);
	iSize = ExplodeString(szBuffer, ";", szCommands, sizeof szCommands, sizeof szCommands[]);

	for(int i; i <= iSize; i++)
	{
		RegConsoleCmd(szCommands[i], cmd_Voice);
	}

	g_kvConfig.GetString("admin_commands", szBuffer, sizeof szBuffer);
	iSize = ExplodeString(szBuffer, ";", szCommands, sizeof szCommands, sizeof szCommands[]);

	for(int i; i <= iSize; i++)
	{
		RegConsoleCmd(szCommands[i], cmd_Admin);
	}

	RegConsoleCmd(DUMP_COMMAND, cmd_Dump);
	RegConsoleCmd(RELOAD_COMMAND, cmd_Reload);
}