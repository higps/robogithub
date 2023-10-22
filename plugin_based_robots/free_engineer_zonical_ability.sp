#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
#pragma semicolon 1
//#pragma newdecls required

#define ROBOT_NAME	"Zonical"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Zonical QuickDraw Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Play as the Giant Zonical",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
bool b_Hooked[MAXPLAYERS + 1] = false;

public void OnClientPutInServer(int client)
{


	// Hook weapon switching for this client here:
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	b_Hooked[client] = true;
}

public void OnClientDisconnect(int client)
{


	// Unhook our weapon switching:
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnWeaponSwitch(int client, int weapon)
{
	// When we switch weapons, we're going to grant a damage bonus
	// based off of the "half second damage bonus" attribute.

	// We'll do the damage calculation in another function. Here we'll see
	// when until we can have this bonus.

	// Do we have "half second damage bonus"?
	if (IsRobot(client, ROBOT_NAME))
	{
		
		//PrintToChatAll("Weapon was %i", weapon);
		if (IsPistol(weapon))
		{
			TF2_AddCondition(client, TFCond_CritHype, 1.0);
			// // TF2Attrib_AddCustomPlayerAttribute(client, "faster reload rate", 0.5, 1.5);
			// // TF2Attrib_AddCustomPlayerAttribute(client, "fire rate bonus", 0.5, 1.5);
		}
	}
}

bool IsPistol(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
	case 22: 
		{
			return true;
		}
	}
	return false;
}



public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME) && TF2_IsPlayerInCondition(attacker, TFCond_CritHype))
	{
		// int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		int Weapon2 = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Secondary);
		if (IsCrit(attacker)) return Plugin_Continue;
		
			// PrintToChatAll("Crittype was %i", critType);
			
				if(weapon == Weapon2)critType = CritType_MiniCrit;
				return Plugin_Changed;
			
			
		
	}
	return Plugin_Continue;
}

public bool IsCrit(int client){

	//Ignores damage reduction if you are kritzed or minicritted with buff banner or winning
	if(IsValidClient(client) && (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_Buffed)) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen))
	{
		return true;
	}
	return false;
}
