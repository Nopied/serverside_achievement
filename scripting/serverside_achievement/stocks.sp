stock bool IsValidClient(int client)
{
    return (0 < client && client <= MaxClients && IsClientInGame(client));
}

enum DateTimeCheck
{
    Check_None = -1,
    Check_Day = 0,
    Check_Month,
    Check_Year
};

stock bool GetDayChange(DateTimeCheck type, const char[] dateTime, const char[] targetDateTime)
{
    char dateTimeCopy[2][32], dateTimeFirst[3][10], dateTimeLast[3][10];
    char targetDateTimeCopy[2][32], targetDateTimeFirst[3][10], targetDateTimeLast[3][10];
    // char year[12], month[12], date[12], hour[12], month[12], second[12];
    int temp;

    ExplodeString(dateTime, " ", dateTimeCopy, sizeof(dateTimeCopy), sizeof(dateTimeCopy[]));
    ExplodeString(targetDateTime, " ", targetDateTimeCopy, sizeof(targetDateTimeCopy), sizeof(targetDateTimeCopy[]));

    ExplodeString(dateTimeCopy[0], "-", dateTimeFirst, sizeof(dateTimeFirst), sizeof(dateTimeFirst[]));
    ExplodeString(dateTimeCopy[1], ":", dateTimeLast, sizeof(dateTimeLast), sizeof(dateTimeLast[]));

    ExplodeString(targetDateTimeCopy[0], "-", targetDateTimeFirst, sizeof(targetDateTimeFirst), sizeof(targetDateTimeFirst[]));
    ExplodeString(targetDateTimeCopy[1], ":", targetDateTimeLast, sizeof(targetDateTimeLast), sizeof(targetDateTimeLast[]));

    switch(type)
    {
        case Check_Day:
            temp = 2;
        case Check_Month:
            temp = 1;
        case Check_Year:
            temp = 0;
    }

    for(int loop = temp; loop >= 0; loop--)
    {
        if(StringToInt(targetDateTimeFirst[loop]) > StringToInt(dateTimeFirst[loop]))
            return true;
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
