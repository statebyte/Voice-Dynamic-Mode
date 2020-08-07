void OpenMenu(int iClient, FeatureMenus eMenuType = MENUTYPE_MAINMENU, bool bLastAdminMenu = false)
{
	switch(eMenuType)
	{
		case MENUTYPE_MAINMENU:			ShowMainMenu(iClient);
		case MENUTYPE_SETTINGSMENU:		ShowSettingsMenu(iClient);
		case MENUTYPE_ADMINMENU:		ShowAdminMenu(iClient);
		case MENUTYPE_SPEAKLIST:		ShowSpeakList(iClient);
		case MENUTYPE_LISTININGLIST:	ShowListningList(iClient);
	}
	Players[iClient].bMenuIsOpen = true;
	Players[iClient].iMenuType = view_as<int>(eMenuType);
	Players[iClient].bLastAdminMenu = bLastAdminMenu;
}

public void OnLibraryRemoved(const char[] szName)
{
	if (!strcmp(szName, "adminmenu"))
	{
		g_hTopMenu = null;
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

	if (hTopMenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu = hTopMenu;

	TopMenuObject hMyCategory = g_hTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);
	
	if (hMyCategory != INVALID_TOPMENUOBJECT)
	{
		g_hTopMenu.AddItem("voice_dynamic_mode", Handler_MenuVoiceSettings, hMyCategory, "voice_admin", ReadFlagString(g_sAdminFlag), "Settings voice mode");
	}
}

public void Handler_MenuVoiceSettings(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			SetGlobalTransTarget(iClient);
			FormatEx(sBuffer, maxlength, TranslationPhraseExists("ADMINMENU_TitleSettings") ? "%t" : "s", "ADMINMENU_TitleSettings");
		}
		case TopMenuAction_SelectOption:
		{
			OpenMenu(iClient, MENUTYPE_ADMINMENU, true);
		}
	}
}

void ShowMainMenu(int iClient)
{
	NullMenu(iClient);
	
	Menu hMenu = new Menu(Handler_MainMenu);
	SetGlobalTransTarget(iClient);
	hMenu.SetTitle("%t\n \n", "MENU_TITLE");

	char szBuffer[128], szPhrase[128];
	if(CheckAdminAccess(iClient)) FormatEx(szBuffer, sizeof szBuffer, "%t", "SettingsMenu");
	else FormatEx(szBuffer, sizeof szBuffer, "%t\n \n", "SettingsMenu");

	if(GetCountMenuItems(MENUTYPE_SETTINGSMENU) > 0) hMenu.AddItem("settings", szBuffer);
	else hMenu.AddItem("settings", szBuffer, ITEMDRAW_DISABLED);

	if(CheckAdminAccess(iClient))
	{
		FormatEx(szBuffer, sizeof szBuffer, "%t\n \n", "AdminMenu");
		hMenu.AddItem("admin", szBuffer);

		//if(GetCountMenuItems(MENUTYPE_ADMINMENU) > 0) hMenu.AddItem("admin", szBuffer);
		//else hMenu.AddItem("admin", szBuffer, ITEMDRAW_DISABLED);
	}
	
	GetStringVoiceMode(iClient, 0, szPhrase, sizeof(szPhrase));
	FormatEx(szBuffer, sizeof szBuffer, "%t\n%s\n \n", "YouHear", szPhrase);
	hMenu.AddItem("YouHear", szBuffer);

	GetStringVoiceMode(iClient, 1, szPhrase, sizeof(szPhrase));
	FormatEx(szBuffer, sizeof szBuffer, "%t\n%s\n \n", "HearYou", szPhrase);
	hMenu.AddItem("HearYou", szBuffer);


	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void GetStringVoiceMode(int iClient, int iType, char[] szBuffer, int iMaxLength)
{
	if(iType == 0)
	{
		if(GetClientTeam(iClient) > 1)
		{
			switch(g_iMode)
			{
				case 1: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "YH_1_2A" : "YH_1_3");
				case 2: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "YH_1_2A" : "YH_2");
				case 3: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "YH_3_4A" : "YH_1_3");
				case 4: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "YH_3_4A" : "YH_4_5");
				case 5: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "YH_5_6A" : "YH_4_5");
				case 6: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "YH_5_6A" : "YH_6");
				case 7: FormatEx(szBuffer, iMaxLength, "%t", "YH_7");
				case 8: FormatEx(szBuffer, iMaxLength, "%t", "YH_8");
			}
		}
		else FormatEx(szBuffer, iMaxLength, "%t", "YH_8");
	}
	else
	{
		switch(g_iMode)
		{
			case 1: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "HY_1_2_3_4A" : "HY_1_5");
			case 2: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "HY_1_2_3_4A" : "HY_2_6");
			case 3: FormatEx(szBuffer, iMaxLength, "%t", "HY_1_2_3_4A");
			case 4: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "HY_1_2_3_4A" : "HY_4");
			case 5: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "HY_5_6_7_8A" : "HY_1_5");
			case 6: FormatEx(szBuffer, iMaxLength, "%t", IsPlayerAlive(iClient) ? "HY_5_6_7_8A" : "HY_2_6");
			case 7, 8: FormatEx(szBuffer, iMaxLength, "%t", "HY_5_6_7_8A");
		}

		if(GetClientTeam(iClient) < 2 && g_hCvar5.IntValue == 0) FormatEx(szBuffer, iMaxLength, "%t", "OnlySpectators");
	}
}

int Handler_MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			Players[iClient].bMenuIsOpen = false;
		}
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));

			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			if(!strcmp(szInfo, "settings")) OpenMenu(iClient, MENUTYPE_SETTINGSMENU);
			else if(!strcmp(szInfo, "admin")) OpenMenu(iClient, MENUTYPE_ADMINMENU);
			else if(!strcmp(szInfo, "YouHear")) OpenMenu(iClient, MENUTYPE_LISTININGLIST);
			else if(!strcmp(szInfo, "HearYou")) OpenMenu(iClient, MENUTYPE_SPEAKLIST);
		}
	}
}

void ShowAdminMenu(int iClient)
{
	NullMenu(iClient);
	
	Menu hMenu = new Menu(Handler_AdminMenu, MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);
	SetGlobalTransTarget(iClient);
	hMenu.SetTitle("%t\n \n", "ADMINMENU_TitleSettings");

	char szBuffer[128];
	FormatEx(szBuffer, sizeof szBuffer, "%t", "ReloadConfig");
	hMenu.AddItem("reloadconfig", szBuffer);
	FormatEx(szBuffer, sizeof szBuffer, "%t", "ReloadModules");
	hMenu.AddItem("reloadmodules", szBuffer);

	AddFeatureItemToMenu(hMenu, MENUTYPE_ADMINMENU);

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int Handler_AdminMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			Players[iClient].bMenuIsOpen = false;
			if(iItem == MenuCancel_ExitBack)
			{
				if(!Players[iClient].bLastAdminMenu) OpenMenu(iClient, MENUTYPE_MAINMENU);
				else 
				{
					PrintToChatAll("Возврат в меню админки");
					RedisplayAdminMenu(g_hTopMenu, iClient);
				}
			}
		}
		case MenuAction_Select:
		{
			char szInfo[64];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));

			if(!strcmp(szInfo, "reloadconfig"))
			{
				ReloadConfig(iClient);
				OpenMenu(iClient, MENUTYPE_ADMINMENU);
			}
			if(!strcmp(szInfo, "reloadmodules")) 
			{
				ReloadModules(iClient);
				OpenMenu(iClient, MENUTYPE_ADMINMENU);
			}
		}
	}
	
	return FeatureHandler(hMenu, action, iClient, iItem, MENUTYPE_ADMINMENU);
}

void ShowSettingsMenu(int iClient)
{
	NullMenu(iClient);

	Menu hMenu = new Menu(Handler_SettingsMenu);
	AddFeatureItemToMenu(hMenu, MENUTYPE_SETTINGSMENU);

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int Handler_SettingsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			Players[iClient].bMenuIsOpen = false;
			if(iItem == MenuCancel_ExitBack)
			{
				OpenMenu(iClient, MENUTYPE_MAINMENU);
			}
		}
	}
	
	return FeatureHandler(hMenu, action, iClient, iItem, MENUTYPE_SETTINGSMENU);
}

void ShowListningList(int iClient)
{
	NullMenu(iClient);
	
	Menu hMenu = new Menu(Handler_ListningListMenu);
	SetGlobalTransTarget(iClient);
	hMenu.SetTitle("%t\n \n", "YouHear");

	char szBuffer[64];
	int iCount;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(CheckPlayerListenStatus(i, iClient))
		{
			FormatEx(szBuffer, sizeof szBuffer, "%N", i);
			hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
			iCount++;
		}
	}

	if(iCount == 0)
	{
		FormatEx(szBuffer, sizeof szBuffer, "Нет игроков...");
		hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	}

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int Handler_ListningListMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			Players[iClient].bMenuIsOpen = false;
			if(iItem == MenuCancel_ExitBack)
			{
				OpenMenu(iClient, MENUTYPE_MAINMENU);
			}
		}
	}
}

void ShowSpeakList(int iClient)
{
	NullMenu(iClient);
	
	Menu hMenu = new Menu(Handler_SpeakListMenu);
	SetGlobalTransTarget(iClient);
	hMenu.SetTitle("%t\n \n", "HearYou");

	char szBuffer[64];
	int iCount;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(CheckPlayerListenStatus(iClient, i))
		{
			FormatEx(szBuffer, sizeof szBuffer, "%N", i);
			hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
			iCount++;
		}
	}

	if(iCount == 0)
	{
		FormatEx(szBuffer, sizeof szBuffer, "Нет игроков...");
		hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	}

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int Handler_SpeakListMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			Players[iClient].bMenuIsOpen = false;
			if(iItem == MenuCancel_ExitBack)
			{
				OpenMenu(iClient, MENUTYPE_MAINMENU);
			}
		}
	}
}

void AddFeatureItemToMenu(Menu hMenu, FeatureMenus eMenuType)
{
	int		iSize = g_hNameItems.Length;
	any		aArray[6];
	char	szBuffer[128];
	for (int i = 0; i < iSize; i++)
	{
		g_hItems.GetArray(i, aArray, 6);

		if(aArray[F_MENUTYPE] == eMenuType)
		{
			g_hNameItems.GetString(i, szBuffer, sizeof szBuffer);
			hMenu.AddItem(szBuffer, szBuffer);
		}
	}
}

void NullMenu(int iClient)
{
	PrintToChat(iClient, "Вызов меню...");
}

int FeatureHandler(Menu hMenu, MenuAction action, int iClient, int iItem, FeatureMenus eMenuType)
{
	static char szItem[128];
	
	if (hMenu)
	{
		hMenu.GetItem(iItem, szItem, sizeof szItem );
		if (!szItem[0] || szItem[0] == '>')
		{
			return 0;
		}

		int iIndex = g_hNameItems.FindString(szItem);
		//PrintToChatAll("%s - %i", szItem, iIndex);
		if (iIndex != -1)
		{
			any aArray[6];
			g_hItems.GetArray(iIndex, aArray, 6);
			static Function Func;

			if(aArray[F_MENUTYPE] == eMenuType)
			{
				switch(action)
				{
					case MenuAction_Select:
					{
						Func = aArray[F_SELECT];
						if (Func != INVALID_FUNCTION)
						{
							bool bResult;
							Call_StartFunction(aArray[F_PLUGIN], Func);
							Call_PushCell(iClient);
							Call_Finish(bResult);

							if(bResult)
							{
								OpenMenu(iClient, eMenuType);
							}
						}
					}
					case MenuAction_DisplayItem:
					{
						Func = aArray[F_DISPLAY];
						if (Func != INVALID_FUNCTION)
						{
							bool bResult;
							Call_StartFunction(aArray[F_PLUGIN], Func);
							Call_PushCell(iClient);
							Call_PushStringEx(szItem, sizeof(szItem), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
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
						Func = aArray[F_DRAW];
						if (Func != INVALID_FUNCTION)
						{
							int iStyle;
							hMenu.GetItem(iItem, "", 0, iStyle);

							Call_StartFunction(aArray[F_PLUGIN], Func);
							Call_PushCell(iClient);
							Call_PushCell(iStyle);
							Call_Finish(iStyle);

							return iStyle;
						}
					}
				}
			}
		}
	}
	return 0;
}

int GetCountMenuItems(FeatureMenus eMenuType)
{
	int iSize = g_hNameItems.Length;

	if(iSize == 0) return 0;

	any aArray[6];
	int iCount = 0;

	for (int i = 0; i < iSize; i++)
	{
		g_hItems.GetArray(i, aArray, 6);

		if(aArray[F_MENUTYPE] == eMenuType) iCount++;
	}

	return iCount;
}