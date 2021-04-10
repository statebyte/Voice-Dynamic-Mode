/** ----------------------------- INFO -----------------------------
* Plugin Name: 		[Voice Dynamic Mode] Core
* File Name: 		vdm_core.smx
* Support Games:    CS:GO ONLY
* Author:           FIVE (Discord: FIVE#8169)
* Source:           https://github.com/theelsaud/Voice-Dynamic-Mode
* Support:          https://discord.gg/ajW69wN
* Official theme:   http://hlmod.ru
* License:          GNU General Public License v3.0
* ------------------------------------------------------------------
*/

#if defined _vdm_core_included
#endinput
#endif
#define _vdm_core_included

public SharedPlugin __pl_vdm_core= 
{
	name = "vdm_core",
	file = "vdm_core.smx",
	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_vdm_core_SetNTVOptional()
{
	MarkNativeAsOptional("VDM_GetVersion");
	MarkNativeAsOptional("VDM_GetConfig");
	MarkNativeAsOptional("VDM_GetPluginPrefix");

	MarkNativeAsOptional("VDM_SetVoiceMode");
	MarkNativeAsOptional("VDM_GetVoiceMode");
	MarkNativeAsOptional("VDM_SetPlayerMode");
	MarkNativeAsOptional("VDM_GetPlayerMode");
	MarkNativeAsOptional("VDM_GetPlayerListenStatus");
	
	MarkNativeAsOptional("VDM_AddFeature");
	MarkNativeAsOptional("VDM_RemoveFeature");
	MarkNativeAsOptional("VDM_IsExistFeature");
	MarkNativeAsOptional("VDM_MoveToMenu");

	MarkNativeAsOptional("VDM_CoreIsLoaded");
	MarkNativeAsOptional("VDM_LogMessage");
}
#endif

/** Индексы основных режимом
*
* См. описание в конфиге или в функции SetMode
*/
enum 
{
	VMODE_NOVOICE = 0,
	VMODE_ALIVE_OR_DEAD_TEAM,
	VMODE_ALIVE_OR_DEAD_ENEMY,
	VMODE_TEAM_ONLY,
	VMODE_ALIVE_ONLY,
	VMODE_ALIVE_DEAD_WITH_ENEMY,
	VMODE_ALIVE_OR_DEAD_TEAM_WITH_ENEMY,
	VMODE_ALLTALK,
	VMODE_FULL_ALLTALK,
	VMODE_COUNT
};

/** Секции меню
*/
enum FeatureMenus
{
	MENUTYPE_NONE = 0,
	MENUTYPE_MAINMENU,		// Секция главного меню (только для открытия).
	MENUTYPE_SETTINGSMENU,	// Секция меню настроек.
	MENUTYPE_ADMINMENU, 	// Секция админ-меню.
	MENUTYPE_SPEAKLIST, 	// Список игроков, которые слышат вас (только для открытия).
	MENUTYPE_LISTININGLIST	// Список игроков, которых вы слышите (только для открытия).
};

////////////////////////////////// NATIVES //////////////////////////////////////////////

/** Получить номер версии ядра
*
* @return					Номер версии
*/
native int VDM_GetVersion();

/** Получить конфиг
*
* @return					Handle KeyValus
*/
native KeyValues VDM_GetConfig();

/** Получить префикс плагина
*
* @noreturn					
*/
native int VDM_GetPluginPrefix(char[] szBuffer, int iMaxLen);

/** Проверка на готовность ядра
*
* @return					true - загружено.
*							false - не готово.
*/
native bool VDM_CoreIsLoaded();

/** Установить голосовой режим сервера
*
* @param iMode				См. enum VoiceMode
* @param iModeType			См. VDM_GetVoiceMode
* @param bIsWarmupCheck		Проверка на разминку
*
* @return					true - режим был изменён.
*							false - режим не поменялся (приоритет).
*/
native bool VDM_SetVoiceMode(int iMode, int iModeType = 0, bool bIsWarmupCheck = false);

/** Получить голосовой режим сервера
*
* @param iModeType 			0 - текущий режим.
* 							1 - основной режим.
* 							2 - стандартный режим.
* 							3 - предыдущий режим.
*
* @return					Возвращает номер режима.
*/
native int VDM_GetVoiceMode(int iModeType = 0);

/** Проверка зависимостей между двумя игроками.
* Подходит для проверки кикие игроки слышат игрока и наоборот, кого слышыт игрок.
*
* @param iClient			Индекс игрока, который должен слушать
* @param iTarget			Индекс игрока, который должен говорить
*
* @return					true - iClient слышыт iTarget.
*							false - iClient не слышыт iTarget.
*/
native bool VDM_GetPlayerListenStatus(int iClient, int iTarget);

/** Установить голосовой режим игроку
* 
* @param iClient			Индекс игрока.
* @param iMode				См. VDM_GetPlayerMode
*
* @return					true - режим был изменён.
*							false - режим не поменялся (приоритет).
*/
native bool VDM_SetPlayerMode(int iClient, int iMode);

/** Установить голосовой режим игроку
*
* @param iClient			Индекс игрока.
*
* @return					-1 - стандартный голосовой режим отключён.
*							0 - Стандартный режим.
*							1 - Режим прослушивания
*							2 - Режим разговора
*							3 - Режим общего голосового чата
*/
native int VDM_GetPlayerMode(int iClient);

/**	Вызывается, при нажатии пункта.
*
* @param iClient			Индекс игрока.
*
* @return					true - Вернет обратно в меню.
*/
typedef VDM_ItemSelectCallback		= function bool (int iClient);

/**	Вызывается, при отображении пункта.
*
* @param iClient			Индекс игрока.
* @param szDisplay			Буфер с названием пункта.
* @param iMaxLength			Размер буфера.
*
* @return					true - Установит новое название с szDisplay.
*/
typedef VDM_ItemDisplayCallback		= function bool (int iClient, char[] szDisplay, int iMaxLength);

/**	Вызывается, при обращении к пункту.
*
* @param iClient			Индекс игрока.
* @param iStyle				Текущий стиль пункта.
*
* @return					Новый стиль для пункта (ITEMDRAW_DEFAULT, ITEMDRAW_DISABLED, ITEMDRAW_RAWLINE).
*/
typedef VDM_ItemDrawCallback		= function int (int iClient, int iStyle);

/** Зарегистрировать функцию плагина для работы с ядром
* ВАЖНО! Для правильно работы приоритетов, регестрируйте первую функцию для работы с измением режимов.
*
* @param szFeature			Название функции. (Используйте уникальное название)
* @param iPluginPriority	Приоритет функции (-1 - автоматический приоритет выставляемый ядром).
* @param eMenuType			Секция меню.
* @param OnItemSelect		Обратный вызов при нажатии пункта.
* @param OnItemDisplay		Обратный вызов при отображении пункта.
* @param OnItemDraw			Обратный вызов при обращении к пункту.
*
* @return					true - функция зарегистрирована
*							false - функция не зарегистрирована (одинаковое название уже зарегистрированной функци)
*/
native bool VDM_AddFeature(const char[] szFeature, int iPluginPriority = 0, FeatureMenus eMenuType = MENUTYPE_NONE, VDM_ItemSelectCallback OnItemSelect	= INVALID_FUNCTION, VDM_ItemDisplayCallback	OnItemDisplay = INVALID_FUNCTION, VDM_ItemDrawCallback OnItemDraw = INVALID_FUNCTION);

/** Удаляет функцию
*
* @param szFeature			Название функции.
*
* @noreturn
*/
native void VDM_RemoveFeature(const char[] szFeature);

/** Получает статус функции
*
* @param szFeature			Название функции.
*
* @return					true - Существует.
* 							false - Не существует.
*/
native bool VDM_IsExistFeature(const char[] szFeature);

/** Открывает меню
*
* @param iClient			Индекс игрока.
* @param eMenuType			Секция меню.
* @param iPage				Страница меню для открытия (GetMenuSelectionPosition()).
*
* @noreturn
*/
native void VDM_MoveToMenu(int iClient, FeatureMenus eMenuType, int iPage = 0);

/** Логирование в общий файл с ядром.
*
* @noreturn
*/
native void VDM_LogMessage(char[] szBuffer);

////////////////////////////////// FORWARDS //////////////////////////////////////////////

/** Вызывается когда ядро загрузилось
*
* @param g_hConfig			Конфиг в KV структуре.
*
* @noreturn
*/
forward void VDM_OnCoreIsReady();

/** Вызывается когда настройки перезагрузились
*
* @param g_hConfig			Конфиг в KV структуре.
*
* @noreturn
*/
forward void VDM_OnConfigReloaded(KeyValues g_hConfig);

/** Вызывается перед установкой голосового режима сервера
*
* @param iMode				Индекс режима
* @param iPluginPriority	Приоритет плагина, устанавливающий режим.
* @param szFeature			Название первой функции плагина, устанавливающий режим.
*
* @return					Plugin_Stop или Plugin_Handled  - запретит установку режима (плагинам с низким приоритетом);
*							Plugin_Continue  - разрешит установку режима без изменений;
*							Plugin_Changed - разрешит установку режима с изменениями.
*/
forward Action VDM_OnSetVoiceModePre(int& iMode, int iPluginPriority, char[] szFeature);

/** Вызывается после установки голосового режима сервера
*
* @param iMode				Индекс режима
* @param iPluginPriority	Приоритет плагина, устанавливающий режим.
* @param szFeature			Название первой функции плагина, устанавливающий режим.
*
* @noreturn
*/
forward void VDM_OnSetVoiceModePost(int iMode, int iPluginPriority, char[] szFeature);

/** Вызывается перед установкой голосового режима игроку
*
* @param iClient			Индекс игрока
* @param iMode				Индекс режима
* @param iPluginPriority	Приоритет плагина, устанавливающий режим.
* @param szFeature			Название первой функции плагина, устанавливающий режим.
*
* @return					Plugin_Stop или Plugin_Handled  - запретит установку режима (плагинам с низким приоритетом);
*							Plugin_Continue  - разрешит установку режима без изменений;
*							Plugin_Changed - разрешит установку режима с изменениями.
*/
forward Action VDM_OnSetPlayerModePre(int iClient, int& iMode, int iPluginPriority, char[] szFeature);

/** Вызывается после установки голосового режима игроку
*
* @param iClient			Индекс игрока
* @param iMode				Индекс режима
* @param iPluginPriority	Приоритет плагина, устанавливающий режим.
* @param szFeature			Название первой функции плагина, устанавливающий режим.
*
* @noreturn
*/
forward void VDM_OnSetPlayerModePost(int iClient, int iMode, int iPluginPriority, char[] szFeature);

/** Вызывается при проверке, слышыт ли игрок А игрока B
*
* @param iClient			Индекс игрока A
* @param iTarget			Индекс игрока B
*
* @param bListen			true - iClient слышыт iTarget
*							false - iClient не слышыт iTarget
*							Модули могут изменять данный параметр,
*							но это повлияет на работу как и ядра, так и на другие модули...
*
* @noreturn
*/
forward Action VDM_OnCheckPlayerListenStatusPre(int iClient, int iTarget, bool& bListen);