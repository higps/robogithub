#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"FATSPY"

public Plugin:myinfo =
{
	name = "[TF2] FATSPY SKILLS",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
public void OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    // Delay slightly to allow model setup
    if(IsRobot(client, ROBOT_NAME))
	{
		CreateTimer(0.1, Timer_ApplyFakeTeam, GetClientUserId(client));
	}
}

public Action Timer_ApplyFakeTeam(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // Example: make BLU look like RED
    if (GetClientTeam(client) == TFTeam_Blue)
        SetEntProp(client, Prop_Send, "m_nSkin", 0);

    return Plugin_Stop;
}