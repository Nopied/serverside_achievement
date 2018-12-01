public Action ListCmd(int client, int args)
{
	if(!IsValidClient(client))	return Plugin_Continue;
	SetGlobalTransTarget(client);

	char authId[25], achievementId[80], text[128], languageId[4];
	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	GetLanguageInfo(GetClientLanguage(client), languageId, 4);

	int myScore, maxScore;
	bool completed;
	Menu menu = new Menu(ListMenu_Handler);

	LoadedPlayerData[client].Rewind();
	if(!LoadedPlayerData[client].GotoFirstSubKey())
	{
		Format(text, sizeof(text), "%t", "Item Empty");
		menu.AddItem("empty", text, ITEMDRAW_DISABLED);
	}
	else
	{
		do
		{
			LoadedPlayerData[client].GetSectionName(achievementId, sizeof(achievementId));
			maxScore += g_KeyValue.GetValue(achievementId, "score", KvData_Int);
			completed = LoadedPlayerData[client].GetNum("completed") > 0;

			if(g_KeyValue.GetValue(achievementId, "menu_display_disable", KvData_Int) > 0
			|| (!completed && g_KeyValue.GetValue(achievementId, "hidden", KvData_Int) > 0))
				continue;

			g_KeyValue.SetLanguageSet(achievementId, languageId);
			g_KeyValue.GetValue("", "name", KvData_String, text, sizeof(text));

			if(completed)
			{
				Format(text, sizeof(text), "%s (%t)", text, "Completed");
				myScore += g_KeyValue.GetValue(achievementId, "score", KvData_Int);
			}

			menu.AddItem(achievementId, text);
		}
		while(LoadedPlayerData[client].GotoNextKey());
	}

	menu.SetTitle("%t", "My List Menu Title", myScore, maxScore);
	menu.ExitButton = true;
	menu.Display(client, 60);

	return Plugin_Continue;
}

public int ListMenu_Handler(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_Select)
	{
		char achievementId[80];
		menu.GetItem(selection, achievementId, sizeof(achievementId));

		ViewAchievementInfo(client, achievementId);
	}
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

void ViewAchievementInfo(int client, char[] achievementId)
{
	SetGlobalTransTarget(client);

	char authId[25], languageId[4], text[512], temp[120];
	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	GetLanguageInfo(GetClientLanguage(client), languageId, 4);

	bool hiddenDescription = g_KeyValue.GetValue(achievementId, "hidden_description", KvData_Int);

	g_KeyValue.SetLanguageSet(achievementId, languageId);
	g_KeyValue.GetValue("", "name", KvData_String, temp, sizeof(temp));

	if(!hiddenDescription)
		g_KeyValue.GetValue("", "description", KvData_String, text, sizeof(text));
	else
		Format(text, sizeof(text), "%t", "Hidden Text");

	Menu menu = new Menu(InfoMenu_Handler);
	menu.SetTitle("%s\n - %s", temp, text);

	LoadedPlayerData[client].Rewind();
	LoadedPlayerData[client].JumpToKey(achievementId);

	if(LoadedPlayerData[client].GetNum("completed", 0) > 0)
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
