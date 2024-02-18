#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
// #include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
// #include <tf_custom_attributes>
// #include <sdkhooks>
#include <tf_ontakedamage>
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Death Negator"

public Plugin:myinfo =
{
	name = "[TF2] UberMachine Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Be a chad bot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

// public OnPluginStart()
// {

// 	HookEvent("player_chargedeployed", Event_Charge_Deployed); //to trigger a unique ubercharge type
// }

// public Action:Event_Charge_Deployed(Handle:event, const String:name[], bool:dontBroadcast)
// {
// 	int client = GetClientOfUserId(GetEventInt(event, "userid"));
// 	int target = GetClientOfUserId(GetEventInt(event, "targetid"));
// 	if (IsRobot(client, ROBOT_NAME))
// 	{
// 		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

// 		if(IsValidClient(target))
// 		TF2_RemoveCondition(target, TFCond_Jarated);
// 		TF2_RemoveCondition(target, TFCond_Milked);
// 		TF2_RemoveCondition(target, TFCond_MarkedForDeath);
// 		TF2_RemoveCondition(target, TFCond_Bleeding);
// 		TF2_RemoveCondition(target, TFCond_Gas);
// 		}
// 		PrintToChatAll("Buddha on");


// 		//This doesn't work right, it doesn't just go down to 1
// 		// SetEntProp(target, Prop_Data, "m_takedamage", 0, 1);
// 		// SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

// 		//Turning off godmode
// 		SetEntProp(target, Prop_Data, "m_takedamage", 2, 1);
// 		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
// }
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	// if (!g_Enable)
	//     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;


	if(IsAnyRobot(victim))
	{
		if (TF2_IsPlayerInCondition(victim, TFCond_PreventDeath))
		{
			int hp = GetClientHealth(victim);
			// PrintToChatAll("HP: %i\ndmg: %f", hp, damage);
			if(float(hp) + damage < 50.0)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}