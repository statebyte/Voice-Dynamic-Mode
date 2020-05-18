/**
* Natives:
* - SetMode
* - GetMode
* - SetPlayerMode
* - GetPlayerMode
* - GetPlayerListenStatus (Получение статуса зависимости между игроками)
* - AddFeature
* - RemoveFeature
* - IsFeatureExist
* - MoveToMenu
* - CoreIsReady
* - ReloadConfig
* Forwards:
* - OnCoreIsReady
* - SetModePre
* - SetModePost
* - SetPlayerModePre
* - SetPlayerModePost
* - ConfigIsReloaded
*/

static Handle		g_hGlobalForvard_OnCoreIsReady;

void CreateNatives()
{

	//CreateNative("VDM_SetMode",			Native_SetMode);
	CreateNative("VDM_GetMode",			Native_GetMode);
	//CreateNative("VDM_SetPlayerMode",	Native_SetPlayerMode);
	//CreateNative("VDM_GetPlayerMode",	Native_GetPlayerMode);
	
}

void CreateGlobalForwards()
{
	g_hGlobalForvard_OnCoreIsReady = CreateGlobalForward("VDM_OnCoreIsReady", ET_Ignore);
}

void CallForward_OnCoreIsReady()
{
	g_bCoreIsReady = true;
	Call_StartForward(g_hGlobalForvard_OnCoreIsReady);
	Call_Finish();
}

int Native_GetMode(Handle hPlugin, int iNumParams)
{
	return g_iMode;
}