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
* - CoreIsReady
* - ReloadConfig
*
* Forwards:
* - OnCoreIsReady
* - SetVoiceModePre
* - SetVoiceModePost
* - SetPlayerModePre
* - SetPlayerModePost
* - ConfigIsReloaded
*/

static Handle		g_hGlobalForvard_OnCoreIsReady,
					g_hGlobalForvard_OnSetVoiceModePre,
					g_hGlobalForvard_OnSetVoiceModePost;

void CreateNatives()
{
	CreateNative("VDM_SetVoiceMode",	Native_SetVoiceMode);
	CreateNative("VDM_GetVoiceMode",	Native_GetVoiceMode);
	//CreateNative("VDM_SetPlayerMode",	Native_SetPlayerMode);
	//CreateNative("VDM_GetPlayerMode",	Native_GetPlayerMode);
	
}

void CreateGlobalForwards()
{
	g_hGlobalForvard_OnCoreIsReady = CreateGlobalForward("VDM_OnCoreIsReady", ET_Ignore);
	g_hGlobalForvard_OnSetVoiceModePre = CreateGlobalForward("VDM_OnSetVoiceModePre", ET_Hook, Param_CellByRef, Param_CellByRef);
	g_hGlobalForvard_OnSetVoiceModePost = CreateGlobalForward("VDM_OnSetVoiceModePost", ET_Hook, Param_Cell, Param_Cell);
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
	Call_StartForward(g_hGlobalForvard_OnCoreIsReady);
	Call_Finish();
}

int Native_SetVoiceMode(Handle hPlugin, int iNumParams)
{
	int iMode = GetNativeCell(1);
	int iPluginPriority = GetNativeCell(2);
	return SetVoiceMode(iMode, iPluginPriority);
}

int Native_GetVoiceMode(Handle hPlugin, int iNumParams)
{
	return g_iMode;
}

int Native_GetPlayerVoiceMode(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return Players[iClient].iPlayerMode;
}