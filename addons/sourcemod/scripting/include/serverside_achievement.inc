#if defined __serverside_achievement_included
 #endinput
#endif
#define __serverside_achievement_included

methodmap SAPlayer {
    public static SAPlayer Load(int client) {
        return view_as<SAPlayer>(client);
    }

    public native int GetProcessMeter(const char[] achievementId);

    public native void AddProcessMeter(const char[] achievementId, int value);


    public native bool GetComplete(const char[] achievementId, bool &forced);

    public native void SetComplete(const char[] achievementId, bool value, bool forced = false);
}

/*
    Create temporary achievement.
    This achievement's KeyValues will add keys "notice_disable" = 1, "menu_display_disable" = 1
*/
native void SA_CreateTemporaryAchievement(const char[] achievementId, int maxProcessInteger);


forward void SA_OnLoadedAchievements();

// SA_AddProcessMeter, SA_SetComplete(@forced is false.)
forward void SA_OnCompleted(int client, const char[] achievementId);

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
    MarkNativeAsOptional("SA_CreateTemporaryAchievement");
    MarkNativeAsOptional("SAPlayer.GetProcessMeter");
    MarkNativeAsOptional("SAPlayer.AddProcessMeter");
    MarkNativeAsOptional("SAPlayer.GetComplete");
    MarkNativeAsOptional("SAPlayer.SetComplete");
}
#endif
