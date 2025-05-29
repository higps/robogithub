#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <morecolors>
#define ROBOT_NAME	"Megaton"
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[TF2] Megaton",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Ability for Megaton",
	version = PLUGIN_VERSION,
	url = "www.bmod.tf"
}
float amount_stack[MAXPLAYERS + 1] = {0.0,...};

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	// PrintToChatAll("DED");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsRobotWhenDead(client, ROBOT_NAME))
	{
		amount_stack[client] = 0;
	}
	    
}


public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME) )
	{
		IncreaseMaxHealth(attacker, damage);
	}
}

void IncreaseMaxHealth(int client, float amount)
{
    // Check if the client is valid and connected
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

	amount_stack[client] = amount_stack[client] + amount;
	PrintToChatAll("Amount stack %f", amount_stack[client] );
	TF2Attrib_SetByName(client, "max health additive penalty", amount_stack[client]);
}