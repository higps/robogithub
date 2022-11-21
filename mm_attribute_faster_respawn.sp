#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2wearables>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>


#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

// bool g_cv_bDebugMode;
// float g_HitTime[MAXPLAYERS + 1] = {0.0, ...};


public void OnPluginStart()
{	
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
}


float g_respawn_time = 0.0;
// int g_weapon_id = -1

// enum
// {
// 	NotWeaponSpecific,
// 	WeaponSpecific
// }

bool HasStat(int client)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "faster-respawn", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_respawn_time = ReadFloatVar(stat_buffer, "respawn", 5.0);

    //If killed by specific weapon ID
    // g_weapon_id = ReadIntVar(stat_buffer, "weapon_id", -1);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
	
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	// PrintToChat(victim,"You died as sentry buster");
	if (HasStat(victim))
	{
		PrintToChatAll("preparing respawn");
		CreateTimer(g_respawn_time, Timer_Respawn, victim);
	}else
	{
		PrintToChatAll("didn't have stat");
	}

	// int weaponid = GetEventInt(event, "weaponid");

	// // int wepindex = GetEntProp(weaponid, Prop_Send, "m_iItemDefinitionIndex");
	// PrintToChatAll("Weapon ID was %i", weaponid);
	return Plugin_Continue;
}

public Action Timer_Respawn(Handle timer, any client)
{
	if (IsValidClient(client) && !IsPlayerAlive(client) && IsClientInGame(client))
    {
		PrintToChatAll("Respawning");
        TF2_RespawnPlayer(client);
    }
	return Plugin_Continue;
}