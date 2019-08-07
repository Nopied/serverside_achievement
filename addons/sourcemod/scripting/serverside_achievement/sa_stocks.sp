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
	int beforeValue = GetProcessMeter(client, achievementId);
	value += beforeValue;
	SetProcessMeter(client, achievementId, value);

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
	return GetPlayerData(client, achievementId, "process_integer");
}

void SetProcessMeter(int client, char[] achievementId, int value)
{
	SetPlayerData(client, achievementId, "process_integer", value);
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
	forced = GetPlayerData(client, achievementId, "is_completed_by_force") > 0;
	return GetPlayerData(client, achievementId, "completed") > 0;
}

public void SetComplete(const int client, const char[] achievementId, bool value, bool forced)
{
	char temp[64];

	SetPlayerData(client, achievementId, "completed", value ? 1 : 0);
	SetPlayerData(client, achievementId, "is_completed_by_force", forced ? 1 : 0);

	FormatTime(temp, sizeof(temp), "%Y-%m-%d %H:%M:%S");
	SetPlayerStringData(client, achievementId, "completed_time", temp);
}

public any GetPlayerData(int client, const char[] achievementId, const char[] key)
{
	return (DBSPlayerData.GetClientData(client)).GetData(SADATABASE_CONFIG_NAME, SA_TABLENAME, achievementId, key);
}

public void GetPlayerStringData(int client, const char[] achievementId, const char[] key, char[] value, int buffer)
{
	(DBSPlayerData.GetClientData(client)).GetData(SADATABASE_CONFIG_NAME, SA_TABLENAME, achievementId, key, value, buffer);
}

public void SetPlayerData(int client, const char[] achievementId, const char[] key, any value)
{
	char temp[64];
	(DBSPlayerData.GetClientData(client)).SetData(SADATABASE_CONFIG_NAME, SA_TABLENAME, achievementId, key, value);

	FormatTime(temp, sizeof(temp), "%Y-%m-%d %H:%M:%S");
	SetPlayerStringData(client, achievementId, "completed_time", temp);
}

public void SetPlayerStringData(int client, const char[] achievementId, const char[] key, char[] value)
{
	char temp[64];
	(DBSPlayerData.GetClientData(client)).SetStringData(SADATABASE_CONFIG_NAME, SA_TABLENAME, achievementId, key, value);

	FormatTime(temp, sizeof(temp), "%Y-%m-%d %H:%M:%S");
	(DBSPlayerData.GetClientData(client)).SetStringData(SADATABASE_CONFIG_NAME, SA_TABLENAME, achievementId, "completed_time", temp);
}

void CreateTemporaryAchievement(char[] achievementId, int maxProcessInteger)
{
	g_KeyValue.Rewind();
	g_KeyValue.JumpToKey(achievementId, true);

	g_KeyValue.SetNum("process_max_meter", maxProcessInteger);
	g_KeyValue.SetNum("notice_disable", 1);
	g_KeyValue.SetNum("menu_display_disable", 1);
}
