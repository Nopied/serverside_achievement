#if defined _serverside_achievement_included
 #endinput
#endif
#define _serverside_achievement_included

native void SA_AddProcessMeter(client)

public SharedPlugin __pl_tutorial_text=
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
    // Mothing.
}
#endif
