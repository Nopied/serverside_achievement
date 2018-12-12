#include <sourcemod>
#include <morecolors>
#include <serverside_achievement>

#include "serverside_achievement/stocks.sp"

#include "serverside_achievement/database.sp"
#include "serverside_achievement/configs.sp"

#include "serverside_achievement/global_vars.sp"

#include "serverside_achievement/menu.sp"

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT",
	author="Nopied",
	description="",
	version="20181110",
};

Handle OnLoadedAchievements;
Handle OnCompleted;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// serverside_achievement/database.sp
	DB_Native_Init();

	// serverside_achievement/configs.sp
	KV_Native_Init();

	// serverside_achievement/global_vars.sp
	Data_Native_Init();

	// global :3
	CreateNative("SA_CreateTemporaryAchievement", Native_CreateTemporaryAchievement);
	CreateNative("SA_GetProcessMeter", Native_GetProcessMeter);
	CreateNative("SA_AddProcessMeter", Native_AddProcessMeter);
	CreateNative("SA_GetComplete", Native_GetComplete);
	CreateNative("SA_SetComplete", Native_SetComplete);

	OnLoadedAchievements = CreateGlobalForward("SA_OnLoadedAchievements", ET_Ignore);
	OnCompleted = CreateGlobalForward("SA_OnCompleted", ET_Hook, Param_Cell, Param_String);
}

public void OnPluginStart()
{
	RegConsoleCmd("list", ListCmd);
	RegAdminCmd("sadatadump", DumpDataCmd, ADMFLAG_CHEATS);

	LoadTranslations("serverside_achievement");
}

public void OnMapStart()
{
	g_Database = new SADatabase();

	if(g_KeyValue != null)
		delete g_KeyValue;
	g_KeyValue = new SAKeyValues();

	Call_StartForward(OnLoadedAchievements);
	Call_Finish();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if(IsFakeClient(client))	return;

	LoadedPlayerData[client] = new SAPlayerData(client);
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))	return;

	LoadedPlayerData[client].Update();
	delete LoadedPlayerData[client];
}

void AddProcessMeter(int client, char[] achievementId, int value)
{
	char languageId[4], name[80];
	int maxMeter = g_KeyValue.GetValue(achievementId, "process_max_meter", KvData_Int);

	if(maxMeter == -1 || GetComplete(client, achievementId, false) || value <= 0)
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

public int Native_GetProcessMeter(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char achievementId[80];
	GetNativeString(2, achievementId, sizeof(achievementId));

	return GetProcessMeter(client, achievementId);
}

public int Native_AddProcessMeter(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), value = GetNativeCell(3);
	char achievementName[80];
	GetNativeString(2, achievementName, sizeof(achievementName));

	AddProcessMeter(client, achievementName, value);
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

public int Native_GetComplete(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char achievementName[80];
	GetNativeString(2, achievementName, sizeof(achievementName));

	return GetComplete(client, achievementName, GetNativeCellRef(3));
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

public int Native_SetComplete(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool value = GetNativeCell(3), forced = GetNativeCell(4);
	char achievementName[80];
	GetNativeString(2, achievementName, sizeof(achievementName));
	bool noticeDisable = g_KeyValue.GetValue(achievementId, "notice_disable", KvData_Int) > 0;

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

void CreateTemporaryAchievement(char[] achievementId, int maxProcessInteger)
{
	g_KeyValue.Rewind();
	g_KeyValue.JumpToKey(achievementId, true);

	g_KeyValue.SetNum("process_max_meter", maxProcessInteger);
	g_KeyValue.SetNum("notice_disable", 1);
	g_KeyValue.SetNum("menu_display_disable", 1);
}

public int Native_CreateTemporaryAchievement(Handle plugin, int numParams)
{
	char achievementId[80];
	GetNativeString(1, achievementId, sizeof(achievementId));

	CreateTemporaryAchievement(achievementId, GetNativeCell(2));
}
