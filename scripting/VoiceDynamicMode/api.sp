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
*
* Forwards:
* - OnCoreIsReady
* - OnSetVoiceModePre
* - OnSetVoiceModePost
* - OnSetPlayerModePre
* - OnSetPlayerModePost
* - OnConfigIsReloaded
*/

static Handle		g_hGlobalForvard_OnCoreIsReady,
					g_hGlobalForvard_OnSetVoiceModePre,
					g_hGlobalForvard_OnSetVoiceModePost;
					//g_hGlobalForvard_OnSetPlayerModePre,
					//g_hGlobalForvard_OnSetPlayerModePost,
					//g_hGlobalForvard_OnConfigIsReloaded;

void CreateNatives()
{
	CreateNative("VDM_SetVoiceMode",			Native_SetVoiceMode);
	CreateNative("VDM_GetVoiceMode",			Native_GetVoiceMode);
	//CreateNative("VDM_SetPlayerMode",			Native_SetPlayerMode);
	CreateNative("VDM_GetPlayerMode",			Native_GetPlayerMode);
	CreateNative("VDM_GetPlayerListenStatus",	Native_GetPlayerListenStatus);

	CreateNative("VDM_AddFeature",				Native_AddFeature);
	CreateNative("VDM_RemoveFeature",			Native_RemoveFeature);
	CreateNative("VDM_IsFeatureExist",			Native_IsExistFeature);
	CreateNative("VDM_MoveToMenu",				Native_MoveToMenu);

	CreateNative("VDM_CoreIsLoaded",			Native_CoreIsLoaded);
	CreateNative("VDM_LogMessage",				Native_LogMessage);
}

void CreateGlobalForwards()
{
	g_hGlobalForvard_OnCoreIsReady = CreateGlobalForward("VDM_OnCoreIsReady", ET_Ignore);
	g_hGlobalForvard_OnSetVoiceModePre = CreateGlobalForward("VDM_OnSetVoiceModePre", ET_Hook, Param_CellByRef, Param_CellByRef);
	g_hGlobalForvard_OnSetVoiceModePost = CreateGlobalForward("VDM_OnSetVoiceModePost", ET_Ignore, Param_Cell, Param_Cell);
}

int Native_CoreIsLoaded(Handle hPlugin, int iNumParams)
{
	return g_bCoreIsLoaded;
}

// Подумать...
// bool bCallPreForward = false, bool bCallPostForward = false
int Native_SetVoiceMode(Handle hPlugin, int iNumParams)
{
	int iMode = GetNativeCell(1);
	int iPluginPriority = GetPluginPriority(hPlugin);
	bool IsWarmupCheck = GetNativeCell(2);

	if(IsWarmupCheck)
	{
		if(IsWarmup()) return 0;
	}

	switch(CallForward_OnSetVoiceModePre(iMode, iPluginPriority))
	{
		case Plugin_Continue:
		{
			SetMode(iMode);
		}
		case Plugin_Changed:
		{
			if(iPluginPriority >= g_iLastPluginPriority) 
			{
				g_iLastPluginPriority = iPluginPriority;
				SetMode(iMode);
			}
		}
	}

	CallForward_OnSetVoiceModePost(g_iMode, g_iLastPluginPriority);

	if(g_iMode == g_iLastMode) return 0;

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
			aArray[0] = hPlugin;
			aArray[1] = GetNativeCell(2); // eMenuType
			aArray[2] = GetNativeCell(3); // iPluginPriority
			aArray[3] = GetNativeCell(4); // OnItemSelect
			aArray[4] = GetNativeCell(5); // OnItemDisplay
			aArray[5] = GetNativeCell(6); // OnItemDraw

			g_hNameItems.PushString(szFeature);
			g_hItems.PushArray(aArray);
			return 1;
		}

		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Feature '%s' already exists.", szFeature);
		return 0;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Empty feature name.");
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
		
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Feature '%s' not found.", szFeature);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Empty feature name.");
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

	ThrowNativeError(SP_ERROR_NATIVE, "[VDM] Empty feature name.");
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
	for(int i = 0; i <= g_hNameItems.Length; i++)
	{
		g_hItems.GetArray(i, aArray, 6);
		if(hPlugin == aArray[0])
		{
			return aArray[2];
		}
	}

	return -1;
}

// forward Action VDM_OnSetVoiceModePre(int iClient, int &iMode);
Action CallForward_OnSetVoiceModePre(int iMode, int& iPluginPriority = 0)
{
	Action Result = Plugin_Continue;
	Call_StartForward(g_hGlobalForvard_OnSetVoiceModePre);
	Call_PushCellRef(iMode);
	Call_PushCellRef(iPluginPriority);
	Call_Finish(Result);
	return Result;
}

void CallForward_OnSetVoiceModePost(int iMode, int iPluginPriority = 0)
{
	Call_StartForward(g_hGlobalForvard_OnSetVoiceModePost);
	Call_PushCell(iMode);
	Call_PushCell(iPluginPriority);
	Call_Finish();
}

void CallForward_OnCoreIsReady()
{
	g_bCoreIsLoaded = true;
	
	Call_StartForward(g_hGlobalForvard_OnCoreIsReady);
	Call_Finish();
}