#include <sourcemod>
#include <morecolors>
#include <serverside_achievement>

#include "serverside_achievement/database.sp"
#include "serverside_achievement/configs.sp"

#include "serverside_achievement/global_vars.sp"

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT",
	author="Nopied",
	description="",
	version="20181110",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// serverside_achievement/database.sp
	DB_Native_Init();

	// serverside_achievement/configs.sp
	KV_Native_Init();

	// global :3
	CreateNative("SA_AddProcessMeter", Native_AddProcessMeter);
	CreateNative("SA_GetComplete", Native_GetComplete);
	CreateNative("SA_SetComplete", Native_SetComplete);
}

public void OnPluginStart()
{
	// g_Database = new SADatabase();
	LoadTranslations("serverside_achievement");
}

public void OnMapStart()
{
	g_Database = new SADatabase();

	if(g_KeyValue != null)
		delete g_KeyValue;
	g_KeyValue = new SAKeyValues();
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client)) return;
	char authId[25];
	GetClientAuthId(client, AuthId_SteamID64, authId, 25);

	AddProcessMeter(client, authId, "beta_tester", 2);
}

void AddProcessMeter(int client, char[] authId, char[] achievementId, int value)
{
	if(GetComplete(authId, achievementId, false))
		return;

	char temp[64];
	int beforeValue = g_Database.GetValue(authId, achievementId, "process_integer");
	value += beforeValue;
	IntToString(value, temp, 64);
	g_Database.SetValue(authId, achievementId, "process_integer", temp);

	// 프로세스 미터가 컨픽의 맥스 프로세스 미터에 충족하면 도전과제 완료.
	if(g_KeyValue.GetValue(achievementId, "only_set_by_plugin", KvData_Int) <= 0
	&& value >= g_KeyValue.GetValue(achievementId, "process_max_meter", KvData_Int))
	{
		SetComplete(authId, "beta_tester", true, false);
		NoticeCompleteToAll(client, achievementId);
	}
}

public int Native_AddProcessMeter(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), value = GetNativeCell(3);
	char achievementName[80], authId[25];
	GetNativeString(2, achievementName, sizeof(achievementName));

	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	AddProcessMeter(client, authId, achievementName, value);
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

public bool GetComplete(const char[] authId, const char[] achievementId, bool forced)
{
	forced = g_Database.GetValue(authId, achievementId, "is_completed_by_force") > 0 ? true : false;
	return g_Database.GetValue(authId, achievementId, "completed") > 0;
}

public int Native_GetComplete(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char achievementName[80], authId[25];
	GetNativeString(2, achievementName, sizeof(achievementName));

	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	return GetComplete(authId, achievementName, GetNativeCellRef(3));
}

public void SetComplete(const char[] authId, const char[] achievementId, bool value, bool forced)
{
	char temp[64];

	IntToString(value ? 1 : 0, temp, 2);
	g_Database.SetValue(authId, achievementId, "completed", temp);

	IntToString(forced ? 1 : 0, temp, 2);
	g_Database.SetValue(authId, achievementId, "is_completed_by_force", temp);

	FormatTime(temp, sizeof(temp), "%Y-%m-%d %H:%M:%S");
	g_Database.SetValue(authId, achievementId, "completed_time", temp);
}

public int Native_SetComplete(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char achievementName[80], authId[25];
	GetNativeString(2, achievementName, sizeof(achievementName));

	GetClientAuthId(client, AuthId_SteamID64, authId, 25);
	SetComplete(authId, achievementName, GetNativeCell(3), GetNativeCell(4));
}
