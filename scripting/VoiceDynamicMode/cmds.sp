Action cmd_Voice(int iClient, int iArgs)
{
	if(!iClient) return;
	OpenMenu(iClient);
}

Action cmd_Admin(int iClient, int iArgs)
{
	if(!iClient) return;
	OpenMenu(iClient, MENUTYPE_ADMINMENU);
}