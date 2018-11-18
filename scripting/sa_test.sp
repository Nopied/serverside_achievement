#include <sourcemod>

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

public void OnClientPostAdminCheck(int client)
{
    if(IsFakeClient(client)) return;

    SA_AddProcessMeter(client, "beta_tester", 1);
}
