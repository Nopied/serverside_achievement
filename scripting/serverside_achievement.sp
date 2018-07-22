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

	char authId[24], queryStr[256];
	GetClientAuthId(client, AuthId_SteamID64, authId, sizeof(authId));

	Format(queryStr, sizeof(queryStr), "INSERT INTO `serverside_achievement` (`steam_id`) SELECT '%s' WHERE NOT EXISTS (SELECT * FROM `serverside_achievement` WHERE `steam_id` = '%s');", authId, authId);
	g_Database.Query(QueryErrorCheck, queryStr);
}
