#include <sourcemod>
#include <serverside_achievement>

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
