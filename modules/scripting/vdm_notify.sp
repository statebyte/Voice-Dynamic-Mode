#include <vdm_core>
#include <csgo_colors>

char g_sPrefix[32];

bool bNotifyAll;

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
    if(!strcmp(szFeature, "round_start")) CGOPrintToChatAll("{GREEN}%s {DEFAULT}Голосовой режим установлен по умолчанию", g_sPrefix);
	else if(TranslationPhraseExists(szFeature)) CGOPrintToChatAll("{GREEN}%s {DEFAULT}%t", g_sPrefix, szFeature);
	else CGOPrintToChatAll("{GREEN}%s {DEFAULT}Изменён голосовой режим на %i (%s)", g_sPrefix, iMode, szFeature);
}