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
	g_Database = new SADatabase(ConnectionCheck);
}


public void ConnectionCheck(Database db, const char[] error, any data)
{
	if(error[0] != '\0')
    {
        SetFailState("[SA] Ahh.. Something is wrong in ConnectionCheck. check your DB. ERROR: %s", error);
    }
	else
    {
        db = data;
    }
}
