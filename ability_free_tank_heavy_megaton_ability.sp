#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <morecolors>
#include <tf2utils>
#include <smlib>

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
float amount_stack = 0.0;

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}
int g_robot_player = -1;

public void OnRoundStart()
{
	amount_stack = 0.0;
}
public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsAnyRobot(victim))
	{
		
		if(IsValidClient(g_robot_player) && IsPlayerAlive(g_robot_player) && IsRobot(g_robot_player, ROBOT_NAME))
		{
			// PrintToChat(g_robot_player,"Current Max HP %i", TF2Util_GetEntityMaxHealth(g_robot_player));
			int hp_regen = RoundToNearest(float(TF2Util_GetEntityMaxHealth(g_robot_player)) / (4.0 + float(GetCurrentRobotCount())));
			// PrintToChat(g_robot_player, "Entity HP: %i Healing for %i", TF2Util_GetEntityMaxHealth(g_robot_player), hp_regen);
			TF2Attrib_AddCustomPlayerAttribute(g_robot_player, "health regen", float(hp_regen), 1.1);
			TF2_AddCondition(g_robot_player, TFCond_InHealRadius, 1.2);
		}
		
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

	if (IsRobot(attacker, ROBOT_NAME))
	{
		IncreaseMaxHealth(attacker, damage);
		g_robot_player = attacker;
		int bonus_hp_damage = RoundToNearest(float(GetClientHealth(victim)) / 3.0) ;
		// PrintToChatAll("%i",bonus_hp_damage);
		damage = damage + bonus_hp_damage;
		return Plugin_Changed;
	}
}

void IncreaseMaxHealth(int client, float amount)
{
    // Check if the client is valid and connected
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

	amount_stack = amount_stack + amount;
	// PrintToChatAll("Amount stack %f", amount_stack[client] );
	TF2Attrib_SetByName(client, "max health additive penalty", amount_stack);
}