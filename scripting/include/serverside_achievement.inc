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

        db.SetCharset("utf8");
        db.Query(TempErrorCheck, "CREATE TABLE IF NOT EXISTS `serverside_achievement` (`steam_id` varchar(25) NOT NULL DEFAULT '0', UNIQUE (`steam_id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;");
        return view_as<SADatabase>(db);
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
