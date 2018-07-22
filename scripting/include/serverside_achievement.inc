#if defined _SERVERSIDE_ACHIEVEMENT_included
 #endinput
#endif
#define _SERVERSIDE_ACHIEVEMENT_included

#define SADATABASE_CONFIG_NAME "serverside_achievement"

methodmap SADatabase < Database {
    public SADatabase()
    {
        Database database;
        DBDriver driver;
        char driverString[10];
        char errorMessage[64]

        database = SQL_Connect(SADATABASE_CONFIG_NAME, true, errorMessage, sizeof(errorMessage));

        if(database == null)
        {
            SetFailState("[SA] Can't connect to DB! Error: %s", errorMessage);
        }

        driver = database.Driver;
        driver.GetIdentifier(driverString, sizeof(driverString));

        if(!StrEqual("mysql", driverString))
        {
            SetFailState("[SA] This plugin is only allowed to use mysql!");
        }

        database.SetCharset("utf8");
        database.Query(QueryErrorCheck, "CREATE TABLE IF NOT EXISTS `serverside_achievement`(`steam_id` varchar(25) NOT NULL DEFAULT '0', UNIQUE (`steam_id`), `completed_time` DATETIME, `last_save_time` DATETIME, `completed` BOOL NOT NULL DEFAULT '0', `is_completed_by_force` BOOL NOT NULL DEFAULT '0') ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;");

        return view_as<SADatabase>(database);
    }
}

methodmap SAchievementInfo < KeyValues {
    public SAchievementInfo()
    {

    }
}

/////////////////////////////////////////////////////////////////////////////////
/*
public void ConnectionCheck(Database db, const char[] error, any data)
{
	if(db == null || error[0] != '\0')
    {
        SetFailState("[SA] Ahh.. Something is wrong in ConnectionCheck. check your DB. ERROR: %s", error);
    }
	else
    {
		data = db;
    }
}
*/

public void QueryErrorCheck(Database db, DBResultSet results, const char[] error, any data)
{
    if(results == null || error[0] != '\0')
    {
        SetFailState("[SA] Ahh.. Something is wrong in QueryErrorCheck. check your DB. ERROR: %s", error);
    }
}
