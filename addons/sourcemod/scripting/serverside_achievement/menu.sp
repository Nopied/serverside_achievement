public Action ListCmd(int client, int args)
{
	if(!IsValidClient(client))	return Plugin_Continue;
	SetGlobalTransTarget(client);

	char text[128];
	Menu menu = new Menu(ListMenu_Handler);
	menu.SetTitle("%t", "List Menu Title");

	Format(text, sizeof(text), "%t", "My List Menu Title");
	menu.AddItem("", text);

	Format(text, sizeof(text), "%t", "Event Menu Title");
	menu.AddItem("", text);

	menu.ExitButton = true;
	menu.Display(client, 60);

	return Plugin_Continue;
}

public int ListMenu_Handler(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_Select)
	{
		switch(selection)
		{
			case 0:
			{
				MyListCmd(client, 0);
			}
			case 1:
			{
				EventListCmd(client, 0);
			}
		}
	}
}

// 전체 리스트: 내 도전과제 리스트, 이벤트 도전과제 (기간한정)

public Action MyListCmd(int client, int args)
{
	if(!IsValidClient(client))	return Plugin_Continue;
	SetGlobalTransTarget(client);

	char achievementId[80], text[128], languageId[4], eventTime[64], temp[2];
	GetLanguageInfo(GetClientLanguage(client), languageId, 4);

	int myScore, maxScore;
	bool completed;
	Menu menu = new Menu(MyListMenu_Handler);

	LoadedPlayerData[client].Rewind();
	if(!LoadedPlayerData[client].GotoFirstSubKey())
	{
		Format(text, sizeof(text), "%t", "Item Empty");
		menu.AddItem("empty", text, ITEMDRAW_DISABLED);
	}
	else
	{
		Format(text, sizeof(text), "%t", "View Event", args > 0 ? "ON" : "OFF");
		Format(temp, sizeof(temp), "%d", args);
		menu.AddItem(temp, text);

		do
		{
			LoadedPlayerData[client].GetSectionName(achievementId, sizeof(achievementId));

			g_KeyValue.GetValue(achievementId, "event_end_datetime", KvData_String, eventTime, sizeof(eventTime));

			maxScore += g_KeyValue.GetValue(achievementId, "score", KvData_Int);
			completed = LoadedPlayerData[client].GetNum("completed") > 0;

			g_KeyValue.SetLanguageSet(achievementId, languageId);
			g_KeyValue.GetValue("", "name", KvData_String, text, sizeof(text));

			if(completed)
			{
				Format(text, sizeof(text), "%s (%t)", text, "Completed");
				myScore += g_KeyValue.GetValue(achievementId, "score", KvData_Int);
			}

			if(g_KeyValue.GetValue(achievementId, "menu_display_disable", KvData_Int) > 0
			|| (!completed && g_KeyValue.GetValue(achievementId, "hidden", KvData_Int) > 0)
			|| (args <= 0 && eventTime[0] != '\0'))
				continue;

			menu.AddItem(achievementId, text);
		}
		while(LoadedPlayerData[client].GotoNextKey());
	}

	menu.SetTitle("%t\n - %t", "My List Menu Title", "My List Menu Score", myScore, maxScore);
	menu.ExitButton = true;
	menu.Display(client, 60);

	return Plugin_Continue;
}

public int MyListMenu_Handler(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_Select)
	{	// TODO: 개별 정렬 옵션
		char achievementId[80];
		menu.GetItem(selection, achievementId, sizeof(achievementId));

		if(selection == 0)
		{
			int value = StringToInt(achievementId) > 0 ? 0 : 1;
			MyListCmd(client, value);
		}
		else
		{
			ViewAchievementInfo(client, achievementId);
		}
	}
}

public Action EventListCmd(int client, int args)
{
	if(!IsValidClient(client))	return Plugin_Continue;
	SetGlobalTransTarget(client);

	char achievementId[80], text[128], languageId[4], eventTime[64], currentTime[64], temp[2];
	GetLanguageInfo(GetClientLanguage(client), languageId, 4);
	FormatTime(currentTime, sizeof(currentTime), "%Y-%m-%d %H:%M:%S");

	bool completed, expired;
	Menu menu = new Menu(EventListMenu_Handler);

	LoadedPlayerData[client].Rewind();
	if(!LoadedPlayerData[client].GotoFirstSubKey())
	{
		Format(text, sizeof(text), "%t", "Item Empty");
		menu.AddItem("empty", text, ITEMDRAW_DISABLED);
	}
	else
	{
		Format(text, sizeof(text), "%t", "View Expired", args > 0 ? "ON" : "OFF");
		Format(temp, sizeof(temp), "%d", args);
		menu.AddItem(temp, text);

		do
		{
			LoadedPlayerData[client].GetSectionName(achievementId, sizeof(achievementId));

			g_KeyValue.GetValue(achievementId, "event_end_datetime", KvData_String, eventTime, sizeof(eventTime));
			if(eventTime[0] == '\0')	continue;

			completed = LoadedPlayerData[client].GetNum("completed") > 0;
			expired = GetDayChange(Check_Second, eventTime, currentTime);

			if(g_KeyValue.GetValue(achievementId, "menu_display_disable", KvData_Int) > 0
			|| (!completed && g_KeyValue.GetValue(achievementId, "hidden", KvData_Int) > 0)
			|| (expired && args <= 0))
				continue;

			g_KeyValue.SetLanguageSet(achievementId, languageId);
			g_KeyValue.GetValue("", "name", KvData_String, text, sizeof(text));

			menu.AddItem(achievementId, text);
		}
		while(LoadedPlayerData[client].GotoNextKey());
	}

	menu.SetTitle("%t", "Event Menu Title");
	menu.ExitButton = true;
	menu.Display(client, 60);

	return Plugin_Continue;
}

public int EventListMenu_Handler(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_Select)
	{	// TODO: 개별 정렬 옵션
		char achievementId[80];
		menu.GetItem(selection, achievementId, sizeof(achievementId));

		if(selection == 0)
		{
			int value = StringToInt(achievementId) > 0 ? 0 : 1;
			EventListCmd(client, value);
		}
		else
		{
			ViewAchievementInfo(client, achievementId);
		}
	}
}



// TODO: 이벤트 도전과제는 기간 명시
void ViewAchievementInfo(int client, char[] achievementId)
{
	SetGlobalTransTarget(client);

	char authId[25], languageId[4], text[512], temp[120], currentTime[64], eventTime[64];
	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	GetLanguageInfo(GetClientLanguage(client), languageId, 4);
	FormatTime(currentTime, sizeof(currentTime), "%Y-%m-%d %H:%M:%S");

	LoadedPlayerData[client].Rewind();
	LoadedPlayerData[client].JumpToKey(achievementId);

	bool completed = LoadedPlayerData[client].GetNum("completed", 0) > 0;
	bool hiddenDescription = g_KeyValue.GetValue(achievementId, "hidden_description", KvData_Int);

	g_KeyValue.GetValue(achievementId, "event_end_datetime", KvData_String, eventTime, sizeof(eventTime));

	g_KeyValue.SetLanguageSet(achievementId, languageId);
	g_KeyValue.GetValue("", "name", KvData_String, temp, sizeof(temp));

	if(!hiddenDescription || completed)
		g_KeyValue.GetValue("", "description", KvData_String, text, sizeof(text));
	else
		Format(text, sizeof(text), "%t", "Hidden Text");

	if(eventTime[0] != '\0')
		Format(text, sizeof(text), "%s\n - %t", text, "Event End Time", eventTime);

	Menu menu = new Menu(InfoMenu_Handler);
	menu.SetTitle("%s\n - %s", temp, text);

	if(completed)
	{
		// 완료한 시각
		LoadedPlayerData[client].GetString("completed_time", temp, sizeof(temp), "EMPTY");
		Format(text, sizeof(text), "%t", "Completed Time", temp);
		menu.AddItem("", text);
	}
	else
	{
		// 현재 달성률
		Format(text, sizeof(text), "%t", "Current Process", LoadedPlayerData[client].GetNum("process_integer", 0), g_KeyValue.GetValue(achievementId, "process_max_meter", KvData_Int));
		menu.AddItem("", text);
	}
	menu.ExitButton = true;
	menu.Display(client, 60);
}

public int InfoMenu_Handler(Menu menu, MenuAction action, int client, int selection)
{

}

public Action DumpDataCmd(int client, int args)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char authId[25], dataFile[PLATFORM_MAX_PATH];
	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	BuildPath(Path_SM, dataFile, sizeof(dataFile), "data/sa_dump_%s.txt", authId);
	// File file = OpenFile(dataFile, "a+");

	LoadedPlayerData[client].Rewind();
	if(LoadedPlayerData[client].ExportToFile(dataFile))
		LogMessage("dumped %s's data.\n%s", authId, dataFile);

	// delete file;
	return Plugin_Continue;
}