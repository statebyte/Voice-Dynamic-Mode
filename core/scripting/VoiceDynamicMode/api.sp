/**
* Natives:
* - SetVoiceMode
* - GetVoiceMode
* - SetPlayerMode
* - GetPlayerMode
* - GetPlayerListenStatus (Получение статуса зависимости между игроками)
* - AddFeature
* - RemoveFeature
* - IsFeatureExist
* - MoveToMenu
* - CoreIsLoaded
* - LogMessage
*
* Forwards:
* - OnCoreIsReady
* - OnConfigReloaded
* - OnSetVoiceModePre
* - OnSetVoiceModePost
* - OnSetPlayerModePre
* - OnSetPlayerModePost
*/

static Handle		g_hGlobalForvard_OnCoreIsReady,
					g_hGlobalForvard_OnSetVoiceModePre,
					g_hGlobalForvard_OnSetVoiceModePost,
					g_hGlobalForvard_OnSetPlayerModePre,
					g_hGlobalForvard_OnSetPlayerModePost,
					g_hGlobalForvard_OnConfigReloaded;

void CreateNatives()
{
	CreateNative("VDM_GetVersion",				Native_GetVersion);
	CreateNative("VDM_GetConfig",				Native_GetConfig);
	CreateNative("VDM_GetPluginPrefix",			Native_GetPluginPrefix);

	CreateNative("VDM_SetVoiceMode",			Native_SetVoiceMode);
	CreateNative("VDM_GetVoiceMode",			Native_GetVoiceMode);
	CreateNative("VDM_SetPlayerMode",			Native_SetPlayerMode);
	CreateNative("VDM_GetPlayerMode",			Native_GetPlayerMode);
	CreateNative("VDM_GetPlayerListenStatus",	Native_GetPlayerListenStatus);

	CreateNative("VDM_AddFeature",				Native_AddFeature);
	CreateNative("VDM_RemoveFeature",			Native_RemoveFeature);
	CreateNative("VDM_IsExistFeature",			Native_IsExistFeature);
	CreateNative("VDM_MoveToMenu",				Native_MoveToMenu);

	CreateNative("VDM_CoreIsLoaded",			Native_CoreIsLoaded);
	CreateNative("VDM_LogMessage",				Native_LogMessage);
}

void CreateGlobalForwards()
{
	g_hGlobalForvard_OnCoreIsReady = new GlobalForward("VDM_OnCoreIsReady", ET_Ignore);
	g_hGlobalForvard_OnConfigReloaded = new GlobalForward("VDM_OnConfigReloaded", ET_Ignore, Param_Cell);

	g_hGlobalForvard_OnSetVoiceModePre = new GlobalForward("VDM_OnSetVoiceModePre", ET_Hook, Param_CellByRef, Param_Cell, Param_String);
	g_hGlobalForvard_OnSetVoiceModePost = new GlobalForward("VDM_OnSetVoiceModePost", ET_Ignore, Param_Cell, Param_Cell, Param_String);

	g_hGlobalForvard_OnSetPlayerModePre = new GlobalForward("VDM_OnSetPlayerModePre", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell, Param_String);
	g_hGlobalForvard_OnSetPlayerModePost = new GlobalForward("VDM_OnSetPlayerModePost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);
}

int Native_GetConfig(Handle hPlugin, int numParams)
{
	return view_as<int>(g_kvConfig);
}

int Native_GetPluginPrefix(Handle hPlugin, int numParams)
{
	int iMaxLen = GetNativeCell(2);
	SetNativeString(1, g_sPrefix, iMaxLen, false);
}

int Native_GetVersion(Handle hPlugin, int iArgs)
{
	return VDM_INT_VERSION;
}

int Native_CoreIsLoaded(Handle hPlugin, int iNumParams)
{
	return g_bCoreIsLoaded;
}

// Подумать...
// bool bCallPreForward = false, bool bCallPostForward = false
int Native_SetVoiceMode(Handle hPlugin, int iNumParams)
{
	if(!IsPluginRegister(hPlugin)) 
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] This Plugin not registred...");
		return 0;
	}

	char szFeature[32];
	int m_iMode = view_as<int>(GetNativeCell(1));
	int iModeType = GetNativeCell(2);
	bool IsWarmupCheck = GetNativeCell(3);
	int iPluginPriority = GetPluginPriority(hPlugin);
	GetPluginFeature(hPlugin, szFeature, sizeof(szFeature));

	if(m_iMode > MAX_MODES) m_iMode = MAX_MODES;
	else if(m_iMode < 0) m_iMode = 0;

	if(iModeType != 0)
	{
		switch(iModeType)
		{
			case 1: g_iMainMode = m_iMode;
			case 2: g_iDefaultMode = m_iMode;
			case 3: g_iLastMode = m_iMode;
		}

		return 1;
	}

	if(IsWarmupCheck && IsWarmup()) return 0;

	int iMode = m_iMode;

	switch(CallForward_OnSetVoiceModePre(iMode, iPluginPriority, szFeature))
	{
		case Plugin_Continue: 	SetMode(m_iMode);
		case Plugin_Changed: 	SetMode(iMode);
		case Plugin_Handled: 	return 0;
		case Plugin_Stop: 		return 0;
	}

	if(g_iMode == g_iLastMode) return 0;

	CallForward_OnSetVoiceModePost(g_iMode, iPluginPriority, szFeature);

	return 1;
}

int Native_GetVoiceMode(Handle hPlugin, int iNumParams)
{
	int iModeType = GetNativeCell(1);
	if(iModeType > 3) iModeType = 3;
	if(iModeType < 0) iModeType = 0;

	switch(iModeType)
	{
		case 1: return g_iMainMode;
		case 2: return g_iDefaultMode;
		case 3: return g_iLastMode;
	}

	return g_iMode;
}

// void VDM_MoveToMenu(int iClient, );
int Native_GetPlayerListenStatus(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iTarget = GetNativeCell(2);
	return CheckPlayerListenStatus(iClient, iTarget);
}

int Native_SetPlayerMode(Handle hPlugin, int iNumParams)
{
	if(!IsPluginRegister(hPlugin)) 
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] This Plugin not registred...");
		return 0;
	}
	
	char szFeature[32];
	int iClient = GetNativeCell(1);
	int iMode = GetNativeCell(2);
	int iPluginPriority = GetPluginPriority(hPlugin);
	GetPluginFeature(hPlugin, szFeature, sizeof(szFeature));
	
	switch(CallForward_OnSetPlayerModePre(iClient, iMode, iPluginPriority, szFeature))
	{
		case Plugin_Continue:
		{
			SetPlayerMode(iClient, iMode);
		}
		case Plugin_Changed:
		{
			SetPlayerMode(iClient, iMode);
		}
	}

	CallForward_OnSetPlayerModePost(iClient, iMode, iPluginPriority, szFeature);

	return 1;
}

int Native_GetPlayerMode(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return Players[iClient].iPlayerMode;
}

// void VDM_AddFeature(const char[]					szFeature,
//							FeatureMenus			eMenuType,
//							int						iPluginPriority = 0,
// 							ItemSelectCallback		OnItemSelect	= INVALID_FUNCTION,
// 							ItemDisplayCallback		OnItemDisplay	= INVALID_FUNCTION,
// 							ItemDrawCallback		OnItemDraw		= INVALID_FUNCTION);
int Native_AddFeature(Handle hPlugin, int iNumParams)
{
	char szFeature[128];
	GetNativeString(1, szFeature, sizeof szFeature);
	if(szFeature[0])
	{
		if(g_hNameItems.FindString(szFeature) == -1)
		{
			any aArray[6];
			aArray[F_PLUGIN] = 			hPlugin;
			aArray[F_PRIORITY_TYPE] = 	GetNativeCell(2); // iPluginPriority
			aArray[F_MENUTYPE] = 		GetNativeCell(3); // eMenuType
			aArray[F_SELECT] = 			GetNativeCell(4); // OnItemSelect
			aArray[F_DISPLAY] = 		GetNativeCell(5); // OnItemDisplay
			aArray[F_DRAW] = 			GetNativeCell(6); // OnItemDraw

			g_hNameItems.PushString(szFeature);
			g_hItems.PushArray(aArray);
			return 1;
		}

		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Core - Feature '%s' already exists.", szFeature);
		return 0;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Core - Empty feature name.");
		return 0;
	}
}


// void VDM_RemoveFeature(const char[] szFeature);
int Native_RemoveFeature(Handle hPlugin, int iNumParams)
{
	char szFeature[128];
	GetNativeString(1, szFeature, sizeof szFeature);
	if (szFeature[0])
	{
		int iIndex = g_hNameItems.FindString(szFeature);
		if(iIndex != -1)
		{
			g_hNameItems.Erase(iIndex);
			g_hItems.Erase(iIndex);
			return 0;
		}
		
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Core - Feature '%s' not found.", szFeature);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Core - Empty feature name.");
	}
	return 0;
}


// bool VDM_IsExistFeature(const char[] szFeature);
int Native_IsExistFeature(Handle hPlugin, int iNumParams)
{
	char szFeature[128];
	GetNativeString(1, szFeature, sizeof szFeature);
	if (szFeature[0])
	{
		return (g_hNameItems.FindString(szFeature) != -1);
	}

	ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Core - Empty feature name.");
	return 0;
}


// void VDM_MoveToMenu(int iClient, );
int Native_MoveToMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	FeatureMenus eMenyType = GetNativeCell(2);
	if (iClient && IsClientInGame(iClient))
	{
		OpenMenu(iClient, eMenyType);
	}
}

int Native_LogMessage(Handle hPlugin, int iNumParams)
{
	char szBuffer[256];
	GetNativeString(1, szBuffer, sizeof szBuffer);
	VDM_LogMessage(szBuffer);
}

int GetPluginPriority(Handle hPlugin)
{
	any aArray[6];
	for(int i = 0; i < g_hNameItems.Length; i++)
	{
		g_hItems.GetArray(i, aArray, 6);
		if(hPlugin == aArray[F_PLUGIN])
		{
			return aArray[F_PRIORITY_TYPE];
		}
	}

	return 0;
}

void GetPluginFeature(Handle hPlugin, char[] szBuffer, int iMaxLength)
{
	any aArray[6];
	for(int i = 0; i < g_hNameItems.Length; i++)
	{
		g_hItems.GetArray(i, aArray, 6);
		if(hPlugin == aArray[F_PLUGIN])
		{
			g_hNameItems.GetString(i, szBuffer, iMaxLength);
		}
	}
}

bool IsPluginRegister(Handle hPlugin)
{
	any aArray[6];
	for(int i = 0; i < g_hNameItems.Length; i++)
	{
		g_hItems.GetArray(i, aArray, 6);
		if(hPlugin == aArray[F_PLUGIN]) return true;
	}

	return false;
}

// forward Action VDM_OnSetVoiceModePre(int iClient, int &iMode);
Action CallForward_OnSetVoiceModePre(int& iMode, int iPluginPriority, char[] szFeature)
{
	Action Result = Plugin_Continue;
	Call_StartForward(g_hGlobalForvard_OnSetVoiceModePre);
	Call_PushCellRef(iMode);
	Call_PushCell(iPluginPriority);
	Call_PushString(szFeature);
	Call_Finish(Result);
	return Result;
}

void CallForward_OnSetVoiceModePost(int iMode, int iPluginPriority, char[] szFeature)
{
	Call_StartForward(g_hGlobalForvard_OnSetVoiceModePost);
	Call_PushCell(iMode);
	Call_PushCell(iPluginPriority);
	Call_PushString(szFeature);
	Call_Finish();
}

Action CallForward_OnSetPlayerModePre(int iClient, int& iMode, int iPluginPriority, char[] szFeature)
{
	Action Result = Plugin_Continue;
	Call_StartForward(g_hGlobalForvard_OnSetPlayerModePre);
	Call_PushCell(iClient);
	Call_PushCell(iMode);
	Call_PushCell(iPluginPriority);
	Call_PushString(szFeature);
	Call_Finish();
	return Result;
}

void CallForward_OnSetPlayerModePost(int iClient, int iMode, int iPluginPriority, char[] szFeature)
{
	Call_StartForward(g_hGlobalForvard_OnSetPlayerModePost);
	Call_PushCell(iClient);
	Call_PushCell(iMode);
	Call_PushCell(iPluginPriority);
	Call_PushString(szFeature);
	Call_Finish();
}

void CallForward_OnCoreIsReady()
{
	g_bCoreIsLoaded = true;
	
	Call_StartForward(g_hGlobalForvard_OnCoreIsReady);
	Call_Finish();
}

void CallForward_OnConfigReloaded()
{
	Call_StartForward(g_hGlobalForvard_OnConfigReloaded);
	Call_PushCell(g_kvConfig);
	Call_Finish();
}