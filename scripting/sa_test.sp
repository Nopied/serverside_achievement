#include <sourcemod>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <serverside_achievement>
#define REQUIRE_PLUGIN

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT : TEST",
	author="Nopied",
	description="",
	version="20181118",
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
}

public void OnClientPostAdminCheck(int client)
{
    if(IsFakeClient(client)) return;

    SA_AddProcessMeter(client, "beta_tester", 1);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// int client = GetClientOfUserId(event.GetInt("userid")),
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0)
		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
			SA_AddProcessMeter(attacker, "first_kill", 1);
}
