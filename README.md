# [Voice Dynamic Mode] Core - 2.0 R
**VDM** - это простое и динамическое ядро для изменения голосового режима серверов CS:GO  
Облегчает жизнь администраторам, игрокам и разработчикам.

<details><summary>Скриншоты</summary>
<p>
	
</p>
</details>
⯈ <a href="https://github.com/theelsaud/Voice-Dynamic-Mode/tree/master/modules">Список официальных модулей</a>

## Для администраторов:
После установки плагина по умолчанию будет включен общий голосовой чат (без наблюдателей).  
В категории админ-меню **Управление сервером** появится пункт ***Настройки голосового режима***

### Требования:
***SourceMod 1.10+***  
***[INC] CS:GO Colors*** *(только для компиляции плагина)*

### Команды:
- **sm_voice** - Главное меню плагина
- **sm_voiceadmin** - Меню администратора
- **sm_vdm_reload** - Перезагрузить настройки и модули
- **sm_vdm_dump** - Вывод в консоль дамп данных о всех модулях

### Установка:
- Удалить все файлы прошлой версии
- Скачайте последний стабильный релиз тут -> <a href="https://github.com/theelsaud/Voice-Dynamic-Mode/releases">**\*тык\***</a>
- Распакуйте содержимое архива по папкам.
- Настройте файл: **addons/sourcemod/configs/vdm_core.ini**

## Голосовые режимы:
№|ENUM - VMODE|Описание
-|-----|--------
0|VMODE_NOVOICE|-
1|VMODE_ALIVE_OR_DEAD_TEAM|-
2|VMODE_ALIVE_OR_DEAD_ENEMY|-
3|VMODE_TEAM_ONLY|-
4|VMODE_ALIVE_ONLY|-
5|VMODE_ALIVE_DEAD_WITH_ENEMY|-
6|VMODE_ALIVE_OR_DEAD_TEAM_WITH_ENEMY|-
7|VMODE_ALLTALK|-
8|VMODE_FULL_ALLTALK|-

## Для разработчиков:
Удобное API и динамичное получение данных о голосовом режиме сервера или игрока  
Описано в файле <a href="https://github.com/theelsaud/Voice-Dynamic-Mode/blob/master/core/scripting/include/vdm_core.inc">**core/scripting/include/vdm_core.inc**</a>

----------------------------------------------------------------------------------
### Поддержка на сервере Discord: https://discord.gg/ajW69wN
