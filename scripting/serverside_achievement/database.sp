#define SADATABASE_CONFIG_NAME "serverside_achievement"

methodmap SADatabase < Database {
    public SADatabase()
    {
        Database database;
        DBDriver driver;
        char driverString[10];
        char errorMessage[256];

        database = SQL_Connect(SADATABASE_CONFIG_NAME, true, errorMessage, sizeof(errorMessage));
        if(database == null)
        {
            SetFailState("Can't connect to DB! Error: %s", errorMessage);
        }

        driver = database.Driver;
        driver.GetIdentifier(driverString, sizeof(driverString));

        if(!StrEqual("mysql", driverString))
        {
            SetFailState("This plugin is only allowed to use mysql!");
        }

        database.SetCharset("utf8");

        return view_as<SADatabase>(database);
    }
    public native int GetValue(const char[] authid, const char[] achievementId, const char[] key, char[] value = "", int buffer = 0);
    public native void SetValue(const char[] authid, const char[] achievementId, const char[] key, const char[] value);

    public native int GetSavedTime(const char[] authid);
}

public void QueryErrorCheck(Database db, DBResultSet results, const char[] error, any data)
{
    if(results == null || error[0] != '\0')
    {
        LogError("Ahh.. Something is wrong in QueryErrorCheck. check your DB. ERROR: %s", error);
    }
}

void DB_Native_Init()
{
    CreateNative("SADatabase.GetValue", Native_SADatabase_GetValue);
    CreateNative("SADatabase.SetValue", Native_SADatabase_SetValue);
    CreateNative("SADatabase.GetSavedTime", Native_SADatabase_GetSavedTime);
}

public int Native_SADatabase_GetValue(Handle plugin, int numParams)
{
    SADatabase thisDB = GetNativeCell(1);

    char authId[24], achievementId[256], keyString[256], queryStr[256], resultStr[64];
    int buffer = GetNativeCell(5);
    GetNativeString(2, authId, 24);
    GetNativeString(3, achievementId, 128);
    GetNativeString(4, keyString, 128);

    thisDB.Escape(achievementId, achievementId, 256);
    thisDB.Escape(keyString, keyString, 256);

    Format(queryStr, sizeof(queryStr), "SELECT `%s` FROM `serverside_achievement` WHERE `steam_id` = '%s' AND `achievement_id` = '%s'", keyString, authId, achievementId);

    DBResultSet query = SQL_Query(thisDB, queryStr);
    if(query == null) return -1;
    else if(!query.HasResults || !query.FetchRow())
    {
        delete query;
        return -1;
    }

    int result;
    if(buffer > 0)
    {
        query.FetchString(0, resultStr, buffer),
        SetNativeString(4, resultStr, buffer);

        result = 1;
    }
    else
    {
        result = query.FetchInt(0);
    }

    delete query;
    return result;
}

public int Native_SADatabase_SetValue(Handle plugin, int numParams)
{
    SADatabase thisDB = GetNativeCell(1);

    char authId[24], achievementId[256], queryStr[512], timeStr[64], keyString[128], valueString[128];
    GetNativeString(2, authId, 24);
    GetNativeString(3, achievementId, 128);
    GetNativeString(4, keyString, 64);
    GetNativeString(5, valueString, 64);

    thisDB.Escape(achievementId, achievementId, 256);
    thisDB.Escape(keyString, keyString, 128);
    thisDB.Escape(valueString, valueString, 128);
    FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S");

    Format(queryStr, sizeof(queryStr),
    "INSERT INTO `serverside_achievement` (`steam_id`, `achievement_id`, `%s`) VALUES ('%s', '%s', '%s') ON DUPLICATE KEY UPDATE `steam_id` = '%s',  `achievement_id` = '%s', `%s` = '%s', `last_saved_time` = '%s'",
    keyString, authId, achievementId, valueString, authId, achievementId, keyString, valueString, timeStr);
    SQL_FastQuery(thisDB, queryStr, strlen(queryStr)+1);
}

public int Native_SADatabase_GetSavedTime(Handle plugin, int numParams)
{
    SADatabase thisDB = GetNativeCell(1);

    char authId[24], queryStr[256];
    GetNativeString(2, authId, 24);

    Format(queryStr, sizeof(queryStr), "SELECT UNIX_TIMESTAMP(`last_saved_time`) FROM `serverside_achievement` WHERE `steam_id` = '%s'", authId);

    DBResultSet query = SQL_Query(thisDB, queryStr);
    if(query == null) return -1;

    if(!query.HasResults || !query.FetchRow())
    {
        delete query;
        return -1;
    }

    int result = query.FetchInt(0);

    delete query;
    return result;
}
