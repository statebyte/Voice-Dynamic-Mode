#include <vdm_core>
#include <csgo_colors>

public Plugin myinfo =
{
	name		=	"[VDM] Notify",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void VDM_OnSetVoiceModePost(int iMode, int iPluginPriority, char[] szFeature)
{
    if(!strcmp(szFeature, "round_start")) CGOPrintToChatAll("{GREEN}[VDM] {DEFAULT}Голосовой режим установлен по умолчанию");
	else if(!strcmp(szFeature, "round_end")) CGOPrintToChatAll("{GREEN}[VDM] {DEFAULT}Общение включено!");
	else CGOPrintToChatAll("{GREEN}[VDM] {DEFAULT}Изменён голосовой режим на %i (%s)", iMode, szFeature);
}