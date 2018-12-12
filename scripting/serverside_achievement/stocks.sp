stock bool IsValidClient(int client)
{
    return (0 < client && client <= MaxClients && IsClientInGame(client));
}

enum DateTimeCheck
{
    Check_None = -1,
	Check_Year,
	Check_Month,
	Check_Day,
	Check_Hour,
	Check_Minute,
	Check_Second,

	Check_MaxCount
};

stock bool GetDayChange(DateTimeCheck type, const char[] dateTime, const char[] targetDateTime)
{
    char dateTimeCopy[2][32], dateTimeFirst[3][10], dateTimeLast[3][10];
    char targetDateTimeCopy[2][32], targetDateTimeFirst[3][10], targetDateTimeLast[3][10];
    // int year[12], month[12], date[12], hour[12], month[12], second[12];

    ExplodeString(dateTime, " ", dateTimeCopy, sizeof(dateTimeCopy), sizeof(dateTimeCopy[]));
    ExplodeString(targetDateTime, " ", targetDateTimeCopy, sizeof(targetDateTimeCopy), sizeof(targetDateTimeCopy[]));

    ExplodeString(dateTimeCopy[0], "-", dateTimeFirst, sizeof(dateTimeFirst), sizeof(dateTimeFirst[]));
    ExplodeString(dateTimeCopy[1], ":", dateTimeLast, sizeof(dateTimeLast), sizeof(dateTimeLast[]));

    ExplodeString(targetDateTimeCopy[0], "-", targetDateTimeFirst, sizeof(targetDateTimeFirst), sizeof(targetDateTimeFirst[]));
    ExplodeString(targetDateTimeCopy[1], ":", targetDateTimeLast, sizeof(targetDateTimeLast), sizeof(targetDateTimeLast[]));

    for(int loop = view_as<int>(Check_Year); loop <= view_as<int>(type); loop--)
    {
        // 2018-05-29 17:05:38 -> 2018-06-28 15:08:40
        if(loop > 2) {
            if(StringToInt(targetDateTimeLast[loop-3]) > StringToInt(dateTimeLast[loop-3]))
                return true;
        }
        else {
            if(StringToInt(targetDateTimeFirst[loop]) > StringToInt(dateTimeFirst[loop]))
                return true;
        }
    }
    return false;
}

/*
stock int GetTimeStamp(const char[] dateTime)
{
    char dateTimeCopy[2][32], dateTimeFirst[3][10], dateTimeLast[3][10];
    // char year[12], month[12], date[12], hour[12], month[12], second[12];

    int sec = 0;
    ExplodeString(dateTime, " ", dateTimeCopy, sizeof(dateTimeCopy), sizeof(dateTimeCopy[]));

    ExplodeString(dateTimeCopy[0], "-", dateTimeFirst, sizeof(dateTimeFirst), sizeof(dateTimeFirst[]));
    ExplodeString(dateTimeCopy[1], ":", dateTimeLast, sizeof(dateTimeLast), sizeof(dateTimeLast[]));

    sec += StringToInt(dateTimeLast[2]) + (StringToInt(dateTimeLast[1]) * 60) + (StringToInt(dateTimeLast[0]) * 3600);
    sec += StringToInt(dateTimeFirst[2]) + (StringToInt(dateTimeLast[1]) * 60) + (StringToInt(dateTimeLast[0]) * 3600);
    return sec;
}
*/
