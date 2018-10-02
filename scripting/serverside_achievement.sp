#include <sourcemod>
#include <serverside_achievement>

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT",
	author="POTRY Developer Team",
	description="",
	version="0.0",
};

SADatabase g_Database;

public void OnPluginStart()
{
	g_Database = new SADatabase();
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client)) return;

	SetComplete(client, "test", true, false);
}

public void SetComplete(int client, const char[] achievementId, bool value, bool forced)
{
	char authId[24], queryStr[256], timeStr[64];
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S");
	GetClientAuthId(client, AuthId_SteamID64, authId, sizeof(authId));

	Format(queryStr, sizeof(queryStr), "REPLACE INTO `serverside_achievement` SET `steam_id` = '%s',`achievement_id` = '%s';", authId, achievementId);
	g_Database.Query(QueryErrorCheck, queryStr);

	Format(queryStr, sizeof(queryStr), "UPDATE `serverside_achievement` SET `completed` = %s WHERE `steam_id` = '%s' AND `achievement_id` = '%s';", value ? "1" : "0", authId, achievementId);
	g_Database.Query(QueryErrorCheck, queryStr);

	if(value) {
		Format(queryStr, sizeof(queryStr), "UPDATE `serverside_achievement` SET `completed_time` = '%s' WHERE `steam_id` = '%s' AND `achievement_id` = '%s';", timeStr, authId, achievementId);
		g_Database.Query(QueryErrorCheck, queryStr);
	}

	if(forced) {
		Format(queryStr, sizeof(queryStr), "UPDATE `serverside_achievement` SET `is_completed_by_force` = %s WHERE `steam_id` = '%s' AND `achievement_id` = '%s';", forced ? "1" : "0", authId, achievementId);
		g_Database.Query(QueryErrorCheck, queryStr);
	}
}
