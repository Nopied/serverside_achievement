#if defined __serverside_achievement_included
 #endinput
#endif
#define __serverside_achievement_included

native void SA_AddProcessMeter(int client, const char[] achievementId, int value);

native bool SA_GetComplete(int client, const char[] achievementId, bool &forced);

native bool SA_SetComplete(int client, const char[] achievementId, bool value, bool forced = false);

public SharedPlugin __pl_serverside_achievement=
{
	name="serverside_achievement",
	file="serverside_achievement.smx",
	#if defined REQUIRE_PLUGIN
		required=1,
	#else
		required=0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_serverside_achievement_SetNTVOptional()
{
    MarkNativeAsOptional("SA_AddProcessMeter");
    MarkNativeAsOptional("SA_GetComplete");
    MarkNativeAsOptional("SA_SetComplete");
}
#endif
