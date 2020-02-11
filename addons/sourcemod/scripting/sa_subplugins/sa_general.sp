#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <serverside_achievement>
#define REQUIRE_PLUGIN

bool panKillClasses[MAXPLAYERS+1][10];

int arrowHolder[MAXPLAYERS+1];
int g_iAlive[MAXPLAYERS+1];

float g_flHealLastTime[MAXPLAYERS+1];

public Plugin myinfo=
{
	name="SERVERSIDE ACHIEVEMENT : GENERAL",
	author="Nopied",
	description="",
	version="20181202",
};

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart);

	HookEvent("arrow_impact", OnArrowImpact);
	HookEvent("object_deflected", OnObjectDeflected);

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_healed", OnPlayerHealed);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client)) return;

	SAPlayer playerData = SAPlayer.Load(client);
	arrowHolder[client] = 0;
	g_iAlive[client] = 0;

	g_flHealLastTime[client] = 0.0;

	for(int loop = 0;  loop < 10; loop++)
	{
		panKillClasses[client][loop] = false;
	}

	playerData.AddProcessMeter("daily_stamp", 1);

	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	CreateTimer(1.0, TestTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnTakeDamageAlive(int client, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(IsFakeClient(client)) return Plugin_Continue;

	if(damagecustom == TF_CUSTOM_CHARGE_IMPACT)
		(SAPlayer.Load(attacker)).AddProcessMeter("runaway_train", RoundFloat(damage));

	return Plugin_Continue;
}

public Action TestTimer(Handle timer, any client)
{
	if(!IsClientInGame(client))		return Plugin_Stop;
	SAPlayer playerData = SAPlayer.Load(client);
	float pos[3], targetPos[3];
	bool spyNearCheck = false;

	GetClientEyePosition(client, pos);
	playerData.AddProcessMeter("plz_drop_the_life", 1);

	if(IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Spy) {
		for(int target = 1; target <= MaxClients; target++)
		{
			if(!IsClientInGame(target) || !IsPlayerAlive(client)) continue;

			GetClientEyePosition(target, targetPos);
			if(GetVectorDistance(pos, targetPos) <= 800.0) {
				g_iAlive[client]++;
				spyNearCheck = true;

				if(g_iAlive[client] >= 30)
					(SAPlayer.Load(client)).SetComplete("spy_near", true);
			}
		}

		if(!spyNearCheck)
			g_iAlive[client] = 0;
	}

	return Plugin_Continue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		arrowHolder[client] = 0;
		g_flHealLastTime[client] = 0.0;
		g_iAlive[client] = 0;

		for(int loop = 0; loop < 10; loop++)
		{
		    panKillClasses[client][loop] = false;
		}
	}
}

public Action OnArrowImpact(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("attachedEntity");
    if(!IsValidClient(client) || IsFakeClient(client)) return Plugin_Continue;

    arrowHolder[client]++;
    if(arrowHolder[client] >= 8)
        (SAPlayer.Load(client)).SetComplete("needle_holder", true);

    return Plugin_Continue;
}

public Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    TFTeam team = TF2_GetClientTeam(client);
    // int owner = GetClientOfUserId(event.GetInt("ownerid"));
    int entIndex = event.GetInt("weaponid") != 0 ?
    GetClientOfUserId(event.GetInt("ownerid")) : event.GetInt("object_entindex");

    float entPos[3], playerPos[3];
    GetEntPropVector(entIndex, Prop_Send, "m_vecOrigin", entPos);
    ArrayList array = new ArrayList();

    for(int target = 1; target <= MaxClients; target++)
    {
        if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target) == team)
        {
            GetEntPropVector(target, Prop_Send, "m_vecOrigin", playerPos);
            if(GetVectorDistance(playerPos, entPos) <= 60.0)
                array.Push(target);
        }
    }

    CreateTimer(6.0, DeflectAliveTimer, array);
}

public Action DeflectAliveTimer(Handle timer, ArrayList array)
{
	int target;
	for(int loop = 0; loop < array.Length ; loop++)
	{
		target = array.Get(loop);
		if(IsClientInGame(target) && IsPlayerAlive(target) && !IsFakeClient(target))
			(SAPlayer.Load(target)).AddProcessMeter("saved_by_airblast", 1);
	}

	delete array;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    arrowHolder[client] = 0;

    return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid")), attacker = GetClientOfUserId(event.GetInt("attacker"));
    int weaponId = event.GetInt("weaponid"), weaponIndex = event.GetInt("weapon_def_index");
    int stunFlags = event.GetInt("stun_flags");

    if(attacker > 0 && client != attacker && !IsFakeClient(attacker) && !IsFakeClient(client))
    {
        if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
        {
            if(TF2_GetPlayerClass(client) == TFClass_Scout &&
            (weaponId == TF_WEAPON_FLAMETHROWER || weaponId == TF_WEAPON_FLAME_BALL))
            {
                (SAPlayer.Load(client)).AddProcessMeter("burning_insecticide", 1);
            }
            if(weaponIndex == 264)
                panKillClasses[attacker][view_as<int>(TF2_GetPlayerClass(client))] = true;

            if(stunFlags > 0)
                (SAPlayer.Load(client)).AddProcessMeter("ball_good", 1);

            if(TF2_IsPlayerInDuel(client))
                (SAPlayer.Load(client)).AddProcessMeter("duel_disturb", 1);
        }

        // 완료 확인
        for(int loop = 1;  loop < 10; loop++)
        {
			if(!panKillClasses[client][loop])
				break;

			if(loop == 9)
				(SAPlayer.Load(client)).SetComplete("pan", true);
        }
    }
}

public Action OnPlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	// int client = GetClientOfUserId(event.GetInt("patient"));
	int healer = GetClientOfUserId(event.GetInt("healer"));
	// int healed = event.GetInt("amount");

	if(IsValidClient(healer) && !IsFakeClient(healer) && g_flHealLastTime[healer] <= GetGameTime()) {
		g_flHealLastTime[healer] = GetGameTime() + 1.0;
		(SAPlayer.Load(healer)).AddProcessMeter("heal_master", 1);
	}

	return Plugin_Continue;
}


stock bool IsValidClient(int client)
{
    return (0 < client && client <= MaxClients && IsClientInGame(client));
}
