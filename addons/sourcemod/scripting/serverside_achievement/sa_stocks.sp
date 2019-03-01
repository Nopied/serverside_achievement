void AddProcessMeter(int client, char[] achievementId, int value)
{
	char languageId[4], name[80], eventTime[64], currentTime[64];
	int maxMeter = g_KeyValue.GetValue(achievementId, "process_max_meter", KvData_Int);

	g_KeyValue.GetValue(achievementId, "event_end_datetime", KvData_String, eventTime, sizeof(eventTime));
	FormatTime(currentTime, sizeof(currentTime), "%Y-%m-%d %H:%M:%S");

	if(maxMeter == -1 || GetComplete(client, achievementId, false) || value <= 0
	|| (eventTime[0] != '\0' && GetDayChange(Check_Second, eventTime, currentTime)))
		return;

	bool noticeDisable = g_KeyValue.GetValue(achievementId, "notice_disable", KvData_Int) > 0;
	LoadedPlayerData[client].GoToAchievementData(achievementId, true);

	int beforeValue = LoadedPlayerData[client].GetNum("process_integer", 0);
	value += beforeValue;
	LoadedPlayerData[client].SetNum("process_integer", value);

	// 프로세스 미터가 컨픽의 맥스 프로세스 미터에 충족하면 도전과제 완료.
	if(g_KeyValue.GetValue(achievementId, "only_set_by_plugin", KvData_Int) <= 0
	&& value >= maxMeter)
	{
		SetComplete(client, achievementId, true, false);

		Call_StartForward(OnCompleted);
		Call_PushCell(client);
		Call_PushStringEx(achievementId, 80, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish();

		if(!noticeDisable)
			NoticeCompleteToAll(client, achievementId);
	}
	else if((maxMeter * 0.2) < value && maxMeter % value == 0
	&& !noticeDisable) // FIXME: %
	{
		GetLanguageInfo(GetClientLanguage(client), languageId, 4);
		SetGlobalTransTarget(client);

		g_KeyValue.SetLanguageSet(achievementId, languageId);
		g_KeyValue.GetValue("", "name", KvData_String, name, sizeof(name));

		CPrintToChat(client, "{lime}[SA]{default} %t", "Added Process Meter", name, value, maxMeter);
	}
}

int GetProcessMeter(int client, char[] achievementId)
{
	LoadedPlayerData[client].GoToAchievementData(achievementId);
	return LoadedPlayerData[client].GetNum("process_integer", 0);
}

void NoticeCompleteToAll(int client, char[] achievementId)
{
	char achievementName[80], languageId[4];
	for(int target = 1;  target < MaxClients; target++)
	{
		if(!IsClientInGame(target)) continue;

		GetLanguageInfo(GetClientLanguage(target), languageId, 4);
		SetGlobalTransTarget(target);

		g_KeyValue.SetLanguageSet(achievementId, languageId);
		g_KeyValue.GetValue("", "name", KvData_String, achievementName, sizeof(achievementName));
		CPrintToChat(target, "{lime}[SA]{default} %t", "Just Completed Achievement", client, achievementName);
	}
}

public bool GetComplete(const int client, const char[] achievementId, bool forced)
{
	LoadedPlayerData[client].GoToAchievementData(achievementId);
	forced = LoadedPlayerData[client].GetNum("is_completed_by_force", 0) > 0;
	return LoadedPlayerData[client].GetNum("completed", 0) > 0;
}

public void SetComplete(const int client, const char[] achievementId, bool value, bool forced)
{
	LoadedPlayerData[client].GoToAchievementData(achievementId, true);
	char temp[64];

	LoadedPlayerData[client].SetNum("completed", value ? 1 : 0);
	LoadedPlayerData[client].SetNum("is_completed_by_force", forced ? 1 : 0);

	FormatTime(temp, sizeof(temp), "%Y-%m-%d %H:%M:%S");
	LoadedPlayerData[client].SetString("completed_time", temp);
}

void CreateTemporaryAchievement(char[] achievementId, int maxProcessInteger)
{
	g_KeyValue.Rewind();
	g_KeyValue.JumpToKey(achievementId, true);

	g_KeyValue.SetNum("process_max_meter", maxProcessInteger);
	g_KeyValue.SetNum("notice_disable", 1);
	g_KeyValue.SetNum("menu_display_disable", 1);
}
