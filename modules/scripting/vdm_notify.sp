#include <vdm_core>
#include <csgo_colors>

char g_sPrefix[32];

public Plugin myinfo =
{
	name		=	"[VDM] Notify",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vdm_notify.phrases");
	if(VDM_CoreIsLoaded()) VDM_OnCoreIsReady();
}

public void VDM_OnCoreIsReady()
{
	VDM_GetPluginPrefix(g_sPrefix, sizeof(g_sPrefix));
}

public void VDM_OnSetVoiceModePost(int iMode, int iPluginPriority, char[] szFeature)
{
	char sBuf[2][4];

	IntToString(iMode, sBuf[0], sizeof(sBuf[]));
	IntToString(iPluginPriority, sBuf[1], sizeof(sBuf[]));
	
	if(TranslationPhraseExists(szFeature)) NotifyAll(szFeature, sBuf[0], sBuf[1]);
	else if(TranslationPhraseExists("default"))  NotifyAll("default", sBuf[0], sBuf[1]);
}

void NotifyAll(char[] szFeature, char[] sMode, char[] sPluginPriority)
{
	char szBuffer[256];
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		SetGlobalTransTarget(i);
		FormatEx(szBuffer, sizeof(szBuffer), "%t", szFeature);
		ReplaceString(szBuffer, sizeof(szBuffer), "{FUNC}", szFeature);
		ReplaceString(szBuffer, sizeof(szBuffer), "{MODE}", sMode);
		ReplaceString(szBuffer, sizeof(szBuffer), "{PRIORITY}", sPluginPriority);

		CGOPrintToChat(i, "%s %s", g_sPrefix, szBuffer);
	}
}