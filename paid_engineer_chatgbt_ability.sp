#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>
#include <tf_ontakedamage>
 
#define ROBOT_NAME	"ChatGBT Guardian"

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] ChatGBT on kill firing speed bonus",
	author = "HiGPS | Bmod.TF",
	description = "ChatGBT guardian ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
} 

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int wepindex = 	GetEventInt(event, "weapon_def_index");
	char weapon_logname[MAX_NAME_LENGTH];
	GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));
	
	if (IsRobot(attacker, ROBOT_NAME) && wepindex == 1153)
	{
		if (StrContains(weapon_logname, "obj_sentrygun") == -1)  // This will account for all obj_sentrygun variations
		{
			// Applying HASTE rune for faster firing speed
			// PrintToChatAll("Adding haste %i", wepindex);
			TF2_AddCondition(attacker, TFCond_RuneHaste, 5.0);  // 5 seconds duration
		}
	}
}

