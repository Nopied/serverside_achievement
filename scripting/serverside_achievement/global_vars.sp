SADatabase g_Database;
SAKeyValues g_KeyValue;

methodmap SAPlayerData < KeyValues {
	public SAPlayerData(int client) {
		char authId[25], achievementId[80], queryStr[256], dataFile[PLATFORM_MAX_PATH], timeStr[64], temp[64];
		GetClientAuthId(client, AuthId_SteamID64, authId, 25);
		BuildPath(Path_SM, dataFile, sizeof(dataFile), "data/serverside_achievement/sa_%s.txt", authId);
		FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S");
		SAPlayerData playerData = view_as<SAPlayerData>(new KeyValues("player_data", "authid", authId));

		// 컨픽에 있는 부분만 쿼리 요청 후 콜백에서 빈 key들을 추가

		g_KeyValue.Rewind();
		DateTimeCheck checkType = view_as<DateTimeCheck>(g_KeyValue.GetNum("day_check", -1));

		if(g_KeyValue.GotoFirstSubKey()) {
			if(g_Database == null)
				if(FileExists(dataFile))
					playerData.ImportFromFile(dataFile);

			do {
				playerData.Rewind();
				g_KeyValue.GetSectionName(achievementId, sizeof(achievementId));

				playerData.JumpToKey(achievementId, true);

				if(g_Database == null)
				{
					playerData.GetString("last_saved_time", timeStr, sizeof(timeStr), "");
					if(checkType != Check_None && GetDayChange(checkType, temp, timeStr))
					{
						playerData.SetNum("completed", 0);
						playerData.SetNum("process_integer", 0);
					}
				}
			}
			while(g_KeyValue.GotoNextKey());

			if(g_Database != null)	{
				Format(queryStr, sizeof(queryStr), "SELECT * FROM `serverside_achievement` WHERE `steam_id` = '%s'", authId);
				g_Database.Query(ReadResult, queryStr, client);
			}
		}

		return playerData;
	}

	// NOTE: 값을 수정하려면 update로 true로 바꿔야 해당 키에 'need_update' 서브 키가 생김.
	public native void GoToAchievementData(const char[] achievementId, bool update = false);

	// SQL 서버나 데이터 파일에 모든 데이터를 저장
	public native void Update();
}
SAPlayerData LoadedPlayerData[MAXPLAYERS+1];

enum
{
	Data_SteamId = 0,
	Data_AchievementId,
	Data_CompletedTime,
	Data_LastSavedTime,
	Data_Completed,
	Data_IsCompletedByForce,
	Data_ProcessInteger,

    DataCount_Max
};

static const char g_QueryColumn[][] = {
	"steam_id",
	"achievement_id",
	"completed_time",
	"last_saved_time",
	"completed",
	"is_completed_by_force",
	"process_integer"
}

void Data_Native_Init()
{
	CreateNative("SAPlayerData.GoToAchievementData", Native_SAPlayerData_GoToAchievementData);
	CreateNative("SAPlayerData.Update", Native_SAPlayerData_Update);
}

public void ReadResult(Database db, DBResultSet results, const char[] error, int client)
{
	char temp[120], timeStr[64];
	DateTimeCheck checkType;
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S");

	for(int loop = 0; loop < results.RowCount; loop++)
	{
		if(!results.FetchRow()) {
			if(results.MoreRows) {
				loop--;
				continue;
			}
			break;
		}

		g_KeyValue.Rewind();
		LoadedPlayerData[client].Rewind();

		results.FetchString(Data_AchievementId, temp, 120);

		// 서버에 등록된 도전과제만 로드
		if(!LoadedPlayerData[client].JumpToKey(temp) || !g_KeyValue.JumpToKey(temp)) continue;

		// Initializing PlayerData
		results.FetchString(Data_CompletedTime, temp, 120);
		LoadedPlayerData[client].SetString("completed_time", temp);

		results.FetchString(Data_LastSavedTime, temp, 120);
		LoadedPlayerData[client].SetString("last_saved_time", temp);

		checkType = view_as<DateTimeCheck>(g_KeyValue.GetNum("day_check", -1));
		if(checkType != Check_None && GetDayChange(checkType, temp, timeStr))
		{
			LoadedPlayerData[client].SetNum("completed", 0);
			LoadedPlayerData[client].SetNum("process_integer", 0);
		}
		else
		{
			LoadedPlayerData[client].SetNum("completed", results.FetchInt(Data_Completed));
			LoadedPlayerData[client].SetNum("process_integer", results.FetchInt(Data_ProcessInteger));
		}
		LoadedPlayerData[client].SetNum("is_completed_by_force", results.FetchInt(Data_IsCompletedByForce));
	}
}

public int Native_SAPlayerData_GoToAchievementData(Handle plugin, int numParams)
{
	SAPlayerData playerData = GetNativeCell(1);

	char achievementId[80], timeStr[64];
	bool needUpdate = GetNativeCell(3);

	playerData.Rewind();
	GetNativeString(2, achievementId, sizeof(achievementId));

	if(playerData.JumpToKey(achievementId, needUpdate) && needUpdate)
	{
		FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S");
		playerData.SetString("last_saved_time", timeStr);

		playerData.SetNum("need_update", 1);
	}
	return;
}

public int Native_SAPlayerData_Update(Handle plugin, int numParams)
{
	SAPlayerData playerData = GetNativeCell(1);
	char achievementId[80], queryStr[512], authId[25], temp[120], dataFile[PLATFORM_MAX_PATH];
	Transaction transaction = new Transaction();

	playerData.Rewind();
	if(g_Database != null)
	{
		playerData.GetString("authid", authId, sizeof(authId));
		if(playerData.GotoFirstSubKey())
		{
			do
			{
				playerData.GetSectionName(achievementId, sizeof(achievementId));

				if(playerData.GetNum("need_update", 0) > 0)
				{
					for(int loop = Data_CompletedTime; loop < DataCount_Max; loop++)
					{
						playerData.GetString(g_QueryColumn[loop], temp, sizeof(temp), "");

						if(temp[0] == '\0') continue;

						Format(queryStr, sizeof(queryStr),
						"INSERT INTO `serverside_achievement` (`steam_id`, `achievement_id`, `%s`) VALUES ('%s', '%s', '%s') ON DUPLICATE KEY UPDATE `steam_id` = '%s',  `achievement_id` = '%s', `%s` = '%s'",
						g_QueryColumn[loop], authId, achievementId, temp,
						authId, achievementId, g_QueryColumn[loop], temp);

						transaction.AddQuery(queryStr);
					}
					playerData.DeleteKey("need_update");
				}
			}
			while(playerData.GotoNextKey());
		}

		g_Database.Execute(transaction, _, OnTransactionError);
	}
	else
	{
		BuildPath(Path_SM, dataFile, sizeof(dataFile), "data/serverside_achievement/sa_%s.txt", authId);

		LoadedPlayerData[client].Rewind();
		LoadedPlayerData[client].ExportToFile(dataFile);
	}
}

public void OnTransactionError(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Something is Error while saving data. \n%s", error);
}
