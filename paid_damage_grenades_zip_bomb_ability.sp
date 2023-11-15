#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
 
#define ROBOT_NAME	"ZIP Bomb"
#define PLUGIN_VERSION "1.0"
//#define GIFTBRINGER 30747

public Plugin:myinfo =
{
	name = "[TF2] Zip Bomb  Caber Refill Ability",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Zib Bomb Caber Refill",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}


/* Plugin Exclusive Functions */
//Code that stuns players
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	// if (!g_Enable)
	//     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;


	if(IsRobot(attacker, ROBOT_NAME))
	{
		RequestFrame(RefreshStickBomb, attacker);
	}

	return Plugin_Continue;
}

void RefreshStickBomb(int client)
{
	int stickbomb = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	SetEntProp(stickbomb, Prop_Send, "m_bBroken", 0);
	SetEntProp(stickbomb, Prop_Send, "m_iDetonated", 0);
}