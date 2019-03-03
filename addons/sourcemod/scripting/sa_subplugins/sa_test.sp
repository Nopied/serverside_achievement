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

	(SAPlayer.Load(client)).AddProcessMeter("beta_tester", 1);
	(SAPlayer.Load(client)).AddProcessMeter("event_test", 1);

	CreateTimer(1.0, TestTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TestTimer(Handle timer, any client)
{
	if(!IsClientInGame(client) || IsFakeClient(client))		return Plugin_Stop;

	(SAPlayer.Load(client)).AddProcessMeter("no_life", 1);
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(attacker > 0 && client != attacker
		&& !IsFakeClient(attacker))
		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			(SAPlayer.Load(attacker)).AddProcessMeter("first_kill", 1);
			(SAPlayer.Load(attacker)).AddProcessMeter("kill_spree", 1);
			(SAPlayer.Load(attacker)).AddProcessMeter("kill_spree_2", 1);
		}
}
