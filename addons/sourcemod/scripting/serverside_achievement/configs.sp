methodmap SAKeyValues < KeyValues {
    public SAKeyValues()
    {
        SAKeyValues achievementKv = view_as<SAKeyValues>(LoadDataConfig());
        return achievementKv;
    }

    // NOTE: @value, @buffer is only can use with KvData_String and KvData_Color. and In this case, successful return is always true.
    // And.. It returns String, Int, Float, Color. So, DO NOT set @datatype to anything else.
    // default value is always 0, or "".
    // If @achievementId is empty, this will use current position. (Will good )
    public native any GetValue(const char[] achievementId, const char[] key, KvDataTypes datatype, char[] value = "", int buffer = 0);

    // NOTE: If couldn't find @languageId, return false.
    public native bool SetLanguageSet(const char[] achievementId, const char[] languageId);
}

void KV_Native_Init()
{
    CreateNative("SAKeyValues.GetValue", Native_SAKeyValues_GetValue);
    CreateNative("SAKeyValues.SetLanguageSet", Native_SAKeyValues_SetLanguageSet);
}

public int Native_SAKeyValues_GetValue(Handle plugin, int numParams)
{
    SAKeyValues thisKv = GetNativeCell(1);

    char achievementId[64], key[64], value[256];
    GetNativeString(2, achievementId, sizeof(achievementId));
    GetNativeString(3, key, sizeof(key));

    KvDataTypes datatype = GetNativeCell(4);
    int buffer = GetNativeCell(6);

    if(achievementId[0] != '\0') {
        thisKv.Rewind();
        if(!thisKv.JumpToKey(achievementId)) return -1;
    }

    switch(datatype)
    {
        case KvData_String, KvData_Color:
        {
            thisKv.GetString(key, value, buffer, "");
            SetNativeString(5, value, buffer);

            return 1;
        }
        case KvData_Int:
        {
            return thisKv.GetNum(key, 0);
        }
        case KvData_Float:
        {
            return view_as<int>(thisKv.GetFloat(key, 0.0));
        }
    }

    return -1;
}

public int Native_SAKeyValues_SetLanguageSet(Handle plugin, int numParams)
{
    SAKeyValues thisKv = GetNativeCell(1);

    char achievementId[64], languageId[4];
    GetNativeString(2, achievementId, sizeof(achievementId));
    GetNativeString(3, languageId, 4); // 아무튼 안 늘어날듯함

    thisKv.Rewind();
    return thisKv.JumpToKey(achievementId) && thisKv.JumpToKey(languageId);
}

stock KeyValues LoadDataConfig()
{
    char dirPath[PLATFORM_MAX_PATH], config[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dirPath, sizeof(dirPath), "configs/%s", SADATABASE_CONFIG_NAME);
    FileType filetype;
    DirectoryListing dirListener = OpenDirectory(dirPath);
    KeyValues achievementKv = new KeyValues(SADATABASE_CONFIG_NAME);

    while(dirListener.GetNext(config, PLATFORM_MAX_PATH, filetype))
    {
        Format(config, PLATFORM_MAX_PATH, "%s/%s", dirPath, config);
        if(FileExists(config)) { // FIXME: THINKING
            achievementKv.ImportFromFile(config);
            LogMessage("Added %s To KeyValues!", config);
        }
    }

    // 중복 아이디, 빈 아이디 체크
    char key[64];
    ArrayList array = new ArrayList(64, _);

    achievementKv.Rewind();
    if(achievementKv.GotoFirstSubKey())
    {
        do
        {
            achievementKv.GetSectionName(key, sizeof(key));

            if(key[0] == '\0')    continue;
            else if(array.FindString(key) != -1) { // FIXME?
                LogError("achievement_id ''%s'' has same name in other!", key);
                continue;
            }

            array.PushString(key);
        }
        while(achievementKv.GotoNextKey());
    }
    delete array;
    //

    return achievementKv;
}
