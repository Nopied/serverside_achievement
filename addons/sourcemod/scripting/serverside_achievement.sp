#include <sourcemod>
#include <morecolors>
#include <serverside_achievement>

#undef REQUIRE_PLUGIN
#include <db_simple>
#define REQUIRE_PLUGIN

#include "serverside_achievement/stocks.sp"

#include "serverside_achievement/database.sp"
#include "serverside_achievement/configs.sp"

#include "serverside_achievement/global_vars.sp"

#include "serverside_achievement/sa_stocks.sp"
#include "serverside_achievement/menu.sp"

#include "serverside_achievement/natives.sp"

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT",
	author="Nopied",
	description="",
	version="20190302",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// serverside_achievement/configs.sp
	KV_Native_Init();

	// forward and natives.
	OnLoadedAchievements = CreateGlobalForward("SA_OnLoadedAchievements", ET_Ignore);
	OnCompleted = CreateGlobalForward("SA_OnCompleted", ET_Hook, Param_Cell, Param_String);

	CreateNative("SA_CreateTemporaryAchievement", Native_CreateTemporaryAchievement);
	CreateNative("SAPlayer.GetProcessMeter", Native_SAPlayer_GetProcessMeter);
	CreateNative("SAPlayer.AddProcessMeter", Native_SAPlayer_AddProcessMeter);
	CreateNative("SAPlayer.GetComplete", Native_SAPlayer_GetComplete);
	CreateNative("SAPlayer.SetComplete", Native_SAPlayer_SetComplete);

	RegPluginLibrary("serverside_achievement");
}

public void OnPluginStart()
{
	RegConsoleCmd("list", ListCmd);
	RegConsoleCmd("mylist", MyListCmd);

	LoadTranslations("serverside_achievement");
}

public void OnMapStart()
{
	if(g_KeyValue != null)
		delete g_KeyValue;
	g_KeyValue = new SAKeyValues();

	Call_StartForward(OnLoadedAchievements);
	Call_Finish();
}
