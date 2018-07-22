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
