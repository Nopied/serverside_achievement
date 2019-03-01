public int Native_CreateTemporaryAchievement(Handle plugin, int numParams)
{
	char achievementId[80];
	GetNativeString(1, achievementId, sizeof(achievementId));

	CreateTemporaryAchievement(achievementId, GetNativeCell(2));
}

public int Native_SAPlayer_GetProcessMeter(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char achievementId[80];
	GetNativeString(2, achievementId, sizeof(achievementId));

	return GetProcessMeter(client, achievementId);
}

public int Native_SAPlayer_AddProcessMeter(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), value = GetNativeCell(3);
	char achievementName[80];
	GetNativeString(2, achievementName, sizeof(achievementName));

	AddProcessMeter(client, achievementName, value);
}

public int Native_SAPlayer_GetComplete(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char achievementName[80];
	GetNativeString(2, achievementName, sizeof(achievementName));

	return GetComplete(client, achievementName, GetNativeCellRef(3));
}

public int Native_SAPlayer_SetComplete(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool value = GetNativeCell(3), forced = GetNativeCell(4);
	char achievementName[80];
	GetNativeString(2, achievementName, sizeof(achievementName));
	bool noticeDisable = g_KeyValue.GetValue(achievementName, "notice_disable", KvData_Int) > 0;

	if(!GetComplete(client, achievementName, false) && value)
	{
		Call_StartForward(OnCompleted);
		Call_PushCell(client);
		Call_PushStringEx(achievementName, 80, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish();

		if(!forced && noticeDisable)
			NoticeCompleteToAll(client, achievementName);
	}

	SetComplete(client, achievementName, value, forced);
}
