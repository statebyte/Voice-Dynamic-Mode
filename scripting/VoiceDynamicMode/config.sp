
void LoadConfig()
{
	//////////////////////////////////////////////////////////////////////////////////
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), PATH_TO_LOGS);
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

	g_iTalkAfterDyingTime = g_kvConfig.GetNum("talk_after_dying_time", 0);
	g_bTalkOnWarmup = view_as<bool>(g_kvConfig.GetNum("talk_on_warmup", 0));

	g_iNotify = g_kvConfig.GetNum("notify", 0);

	g_bBlockEvents = view_as<bool>(g_kvConfig.GetNum("block_events", 0));
	g_bLogs = view_as<bool>(g_kvConfig.GetNum("logs", 0));

	RegConsoleCmds();

	delete g_kvConfig;
}

void RegConsoleCmds()
{
	if(g_bCoreIsReady) return;

	char szBuffer[256];

	g_kvConfig.GetString("", szBuffer, sizeof szBuffer);
}