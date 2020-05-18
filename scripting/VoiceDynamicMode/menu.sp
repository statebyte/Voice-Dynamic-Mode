void OpenMenu(int iClient, FeatureMenus iMenu = MENUTYPE_MAINMENU)
{
	switch(iMenu)
	{
		case MENUTYPE_MAINMENU:			ShowMainMenu(iClient);
		case MENUTYPE_ADMINMENU:		ShowAdminMenu(iClient);
		case MENUTYPE_SETTINGSMENU:		ShowSettingsMenu(iClient);
	}
}

void ShowMainMenu(int iClient)
{
	Menu hMenu = new Menu(Handler_MainMenu);
	SetGlobalTransTarget(iClient);
	hMenu.SetTitle("%t\n \n", "MENU_TITLE");

	char szBuffer[128];
	FormatEx(szBuffer, sizeof szBuffer, "%t", "SettingsMenu");
	hMenu.AddItem("settings", szBuffer);
	FormatEx(szBuffer, sizeof szBuffer, "%t", "AdminMenu");
	hMenu.AddItem("admin", szBuffer);
	FormatEx(szBuffer, sizeof szBuffer, "%t", "YouHear");
	hMenu.AddItem("YouHear", szBuffer);
	FormatEx(szBuffer, sizeof szBuffer, "%t", "HearYou");
	hMenu.AddItem("HearYou", szBuffer);



	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int Handler_MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			if(!strcmp(szInfo, "settings")) OpenMenu(iClient, MENUTYPE_SETTINGSMENU);
			else if(!strcmp(szInfo, "admin")) OpenMenu(iClient, MENUTYPE_ADMINMENU);
			else OpenMenu(iClient, MENUTYPE_MAINMENU);
		}
	}
}

void AddFeatureItemToMenu(Menu hMenu, FeatureMenus eType)
{
	int 	iSize = g_hItems.Length;
	char	szBuffer[128];
	for (int i = 0; i < iSize; i += F_COUNT)
	{
		if (g_hItems.Get(i + F_MENU_TYPE) == view_as<int>(eType))
		{
			g_hItems.GetString(i, SZF(szBuffer));
			hMenu.AddItem(szBuffer, szBuffer);
			FPS_Debug("AddFeatureItemToMenu >> F_TYPE: %i >> F: %s", eType, szBuffer)
		}
	}
}

int FeatureHandler(Menu hMenu, MenuAction action, int iClient, int iItem, FeatureMenus eType)
{
	static char szItem[128];
	
	if (hMenu)
	{
		hMenu.GetItem(iItem, SZF(szItem));
		if (!szItem[0] || szItem[0] == '>')
		{
			return 0;
		}

		int iIndex = g_hItems.FindString(szItem);
		if (iIndex != -1)
		{
			static Function Func;
			switch(action)
			{
				case MenuAction_Select:
				{
					Func = g_hItems.Get(iIndex + F_SELECT);
					if (Func != INVALID_FUNCTION)
					{
						bool bResult;
						Call_StartFunction(g_hItems.Get(iIndex + F_PLUGIN), Func);
						Call_PushCell(iClient);
						Call_Finish(bResult);

						if(bResult)
						{
							switch(eType)
							{
								case FPS_STATS_MENU:	ShowMainStatsMenu(iClient,		GetMenuSelectionPosition());
								case FPS_TOP_MENU:		ShowMainTopMenu(iClient,		GetMenuSelectionPosition());
								case FPS_ADVANCED_MENU:	ShowMainAdditionalMenu(iClient,	GetMenuSelectionPosition());
							}
						}
					}
				}
				case MenuAction_DisplayItem:
				{
					Func = g_hItems.Get(iIndex + F_DISPLAY);
					if (Func != INVALID_FUNCTION)
					{
						bool bResult;
						Call_StartFunction(g_hItems.Get(iIndex + F_PLUGIN), Func);
						Call_PushCell(iClient);
						Call_PushStringEx(SZF(szItem), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
						Call_PushCell(sizeof(szItem));
						Call_Finish(bResult);

						if(bResult)
						{
							return RedrawMenuItem(szItem);
						}
					}
				}
				case MenuAction_DrawItem:
				{
					Func = g_hItems.Get(iIndex + F_DRAW);
					if (Func != INVALID_FUNCTION)
					{
						int iStyle;
						hMenu.GetItem(iItem, "", 0, iStyle);

						Call_StartFunction(g_hItems.Get(iIndex + F_PLUGIN), Func);
						Call_PushCell(iClient);
						Call_PushCell(iStyle);
						Call_Finish(iStyle);

						return iStyle;
					}
				}
			}
		}
	}
	return 0;
}

