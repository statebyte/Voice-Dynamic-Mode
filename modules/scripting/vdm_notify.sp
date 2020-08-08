#include <vdm_core>
#include <csgo_colors>

public Plugin myinfo =
{
	name		=	"[VDM] Notify",
	version		=	"1.0",
	author		=	"FIVE",
	url			=	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void VDM_OnSetVoiceModePost(int iMode, bool bRoundStart)
{
    CGOPrintToChatAll("{GREEN}[VDM] {DEFAULT}Change Mode Post - %i (%s)", iMode, bRoundStart ? "RoundStart" : "Other");
}