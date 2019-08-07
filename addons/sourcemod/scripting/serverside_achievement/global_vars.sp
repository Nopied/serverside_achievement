Handle OnLoadedAchievements;
Handle OnCompleted;

SAKeyValues g_KeyValue;

static const char g_QueryColumn[][] = {
	"steam_id",
	"achievement_id",
	"completed_time",
	"last_saved_time",
	"completed",
	"is_completed_by_force",
	"process_integer"
};

static const KvDataTypes g_iQueryColumnDataType[] = {
	KvData_String,
	KvData_String,
	KvData_String,
	KvData_String,
	KvData_Int,
	KvData_Int,
	KvData_Int
};

public void DBS_OnLoadData(DBSData data)
{
	KeyValues tabledata = DBSData.CreateTableData(SA_TABLENAME);
	for(int loop = 0; loop < sizeof(g_QueryColumn); loop++)
	{
		DBSData.PushTableData(tabledata, g_QueryColumn[loop], g_iQueryColumnDataType[loop]);
	}
	data.Add(SADATABASE_CONFIG_NAME, tabledata);
	delete tabledata;
}
