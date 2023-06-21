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

#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

#define DMG_TYPE_MELEE 134221952
#define DMG_TYPE_MELEE_CRIT 135270528


// bool g_cv_bDebugMode;
// float g_HitTime[MAXPLAYERS + 1] = {0.0, ...};


public void OnPluginStart()
{	
	
	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
}
// public void OnMapStart()
// {	
// 	PrecacheSound(sHealNoise);
// 	PrecacheSound(sExtinguish);
// 	PrecacheSound(sSyringeBuffOn);
// 	// PrecacheSound(sSyringeBuffOff);
// }
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
}

int g_TFCond = 0;
float g_TFCond_duration = 0.0;
int g_TFCond_teammate = 0;
int g_TFCond_self = 0;
int g_bmod_disciplinary = 0;
int g_TFCond_enemy = 0;

bool ActiveHasStatWeapon(int attacker)
{
	int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "on-hit-addcond", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_TFCond = ReadIntVar(stat_buffer, "TFCond", -1);
	g_TFCond_duration = ReadFloatVar(stat_buffer, "duration", 5.0);
    g_TFCond_teammate = ReadIntVar(stat_buffer, "apply-to-teammate", 0);
	g_TFCond_self = ReadIntVar(stat_buffer, "apply-to-self", 0);
	g_TFCond_enemy = ReadIntVar(stat_buffer, "apply-to-enemy", 0);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
}

public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	//TraceAttack fires everytime hitscan is used and in some cases, for syringes and Dragon's fury fireballs etc.	
	if((IsValidEntity(victim) && IsValidEntity(attacker) && IsValidEntity(inflictor)) &&
	(victim <= MaxClients && victim > 0) &&
	(attacker <= MaxClients && attacker > 0) &&
	(inflictor <= MaxClients && inflictor > 0))
	{


	if(IsClientInGame(victim) && IsClientInGame(attacker) && IsClientInGame(inflictor) && ActiveHasStatWeapon(attacker))
	{

	if (TF2_GetClientTeam(attacker) == TF2_GetClientTeam(victim))
	{

            if(g_TFCond_self) TF2_AddCondition(attacker, view_as<TFCond>(g_TFCond), g_TFCond_duration);
            if(g_TFCond_teammate) TF2_AddCondition(victim, view_as<TFCond>(g_TFCond), g_TFCond_duration);

        
	}else
	{
		    if(g_TFCond_self) TF2_AddCondition(attacker, view_as<TFCond>(g_TFCond), g_TFCond_duration);
            if(g_TFCond_enemy) TF2_AddCondition(victim, view_as<TFCond>(g_TFCond), g_TFCond_duration);
	}
	}
    }
	return Plugin_Continue;
}

stock bool IsValidClient(iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}
