#if defined _SERVERSIDE_ACHIEVEMENT_included
 #endinput
#endif
#define _SERVERSIDE_ACHIEVEMENT_included

#define SADATABASE_CONFIG_NAME "serverside_achievement"

methodmap SADatabase < Database {
    public SADatabase(SQLConnectCallback callback)
    {
        Database db;
        DBDriver driver;
        char driverString[10];

        Database.Connect(callback, SADATABASE_CONFIG_NAME, db);
        driver = db.Driver;
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

public void TempErrorCheck(Database db, DBResultSet results, const char[] error, any data)
{
    if(results == null || error[0] != '\0')
    {
        SetFailState("[SA] Ahh.. Something is wrong in TempErrorCheck. check your DB. ERROR: %s", error);
    }
}
