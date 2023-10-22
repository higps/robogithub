#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"MrPaladin"

public Plugin:myinfo =
{
	name = "[TF2] Mr Paladin Ability",
	author = "HiGPS | Bmod.TF",
	description = "Play as the Giant Spy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int weaponID = GetEventInt(event, "weapon_def_index");
	int customkill = GetEventInt(event, "customkill");

	if (IsRobot(attacker, ROBOT_NAME) && weaponID == 356 && customkill == 2)
	{
		TF2_AddCondition(attacker, TFCond_Stealthed, 5.0);
	}
}
