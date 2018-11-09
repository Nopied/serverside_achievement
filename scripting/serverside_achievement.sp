#include <sourcemod>
#include <serverside_achievement>

#include "serverside_achievement/database.sp"
#include "serverside_achievement/global_vars.sp"

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT",
	author="Nopied",
	description="",
	version="20181108",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// serverside_achievement/database.sp
	DB_Native_Init();
}

public void OnPluginStart()
{
	// g_Database = new SADatabase();
}

public void OnMapStart()
{
	g_Database = new SADatabase();
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client)) return;
	char authId[25];
	GetClientAuthId(client, AuthId_SteamID64, authId, 25);

	SetComplete(authId, "test", true, false);
	LogMessage("%N is %s", client, GetComplete(authId, "test", false) ? "completed" : "no!!!!");
}

public bool GetComplete(const char[] authId, const char[] achievementId, bool forced)
{
	forced = g_Database.GetValue(authId, achievementId, "is_completed_by_force") > 0 ? true : false;
	return g_Database.GetValue(authId, achievementId, "completed") > 1;
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
