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
    if(!strcmp(szFeature, "round_start")) CGOPrintToChatAll("%s %t", g_sPrefix, "Voice_Default");
	else if(TranslationPhraseExists(szFeature)) CGOPrintToChatAll("%s %t", g_sPrefix, szFeature);
	else CGOPrintToChatAll("%s %t", g_sPrefix, "Voice_Set", iMode, szFeature);
}