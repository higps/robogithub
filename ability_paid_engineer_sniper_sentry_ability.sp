#include <sourcemod>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>

#define ROBOT_NAME "Engiper"
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "Sentry Self Stun",
	author = "HiGPS",
	description = "Sentry disable self on it, made for sniper sentry",
	version = "1.0",
	url = "http://bmod.tf"
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	//This is sentry fire
	if (damagetype == 2232322 && weapon == -1 && IsRobot(attacker, ROBOT_NAME))
	{
		//RemoveEntity(inflictor);
		RequestFrame(PerformSap, inflictor);
		PrintToChatAll("attacker: %N, Dmgtype %i: inflictor: %i, weapon: %i",attacker, damagetype, inflictor, weapon);
		
		
	}
	return Plugin_Continue;
}


stock void PerformSap(int entity)
{
	// SetVariantInt(2);
	// AcceptEntityInput(entity, "RemoveHealth");
	SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
	CreateTimer(1.0, PerformUnSap, entity);
}

public Action PerformUnSap(Handle timer, int entity)
{
	if(IsValidEntity(entity))SetEntProp(entity, Prop_Send, "m_bDisabled", 0);
}
