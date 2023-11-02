#pragma semicolon 1
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


public Plugin:myinfo =
{
	name = "[TF2] Spawn Bombs on Cond Attribute",
	author = "HiGPS | Bmod.TF",
	description = "Spawn bombs on attributes",
	version = "1.0",
	url = "www.sourcemod.com"
}

// public void OnMapStart()
// {
// 	PrecacheModel(BANANA_MODEL);
// }





#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

bool g_active[MAXPLAYERS + 1] = {false, ...};
int g_TFCond = 0;
float g_skill = 0.0; 
float g_attack_interval = 600.0;
float g_damage;
float g_bomb_scale;
bool ActiveHasAddCondStatPlayer(int attacker)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(attacker, "OnCond-SpawnBomb", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}

	g_TFCond = ReadIntVar(stat_buffer, "oncond", -1);
	g_damage = ReadFloatVar(stat_buffer, "damage", 100.0);
	g_bomb_scale = ReadFloatVar(stat_buffer, "bombscale", 1.0);
	g_attack_interval = ReadFloatVar(stat_buffer, "attackinterval", 0.05);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
}


// public void TF2_OnConditionAdded(int client, TFCond condition)
// {

//     if(ActiveHasAddCondStatPlayer(client))
//     {
//         // PrintToChatAll("Condition was %i , g_TFCOND was %i", condition, g_TFCond);
//         if (condition == g_TFCond)
//         {
//            g_active[client] = true;
//         }
// 		else
// 		{
// 			g_active[client] = false;
// 		}
//     }
// }


// void SetProjectileModel (int iEntity)
// {
// 	SetEntityModel(iEntity, BANANA_MODEL);
// }

void SpawnBombs(int client, int attacker)
{
	int team = GetClientTeam(attacker);
	float pos[3], vel[3], ang[3];
	int children = 1;
	float speed = 50.0;


	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	

	pos[2] += 133.0;
	for (int i = 1; i <= children; i++)
	{
		int child = CreateEntityByName("tf_projectile_pipe");
		
		
		float child_vel[3];
		float child_ang[3];

		//Prevent child grenades from detonating on contact
		SetEntProp(child, Prop_Send, "m_bTouched", 1);

		//Set properties
		//SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
		SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
		SetEntPropFloat(child, Prop_Send, "m_flDamage", g_damage);
		SetEntPropFloat(child, Prop_Send, "m_flModelScale", g_bomb_scale);

		for (int axis = 0; axis < 3; axis++){

			child_vel[axis] = vel[axis] + GetRandomFloat(speed * -1.0, speed);
			child_ang[axis] = ang[axis] + GetRandomFloat(0.0 , 360.0);
		}
		child_vel[2] = FloatAbs(child_vel[2]);

		SetEntProp(child, Prop_Send, "m_iTeamNum", team);
		SetEntProp(child, Prop_Send, "m_bIsLive", 1);
		if(TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
		{
		if (HasEntProp(child, Prop_Send, "m_bCritical"))
			SetEntProp(child, Prop_Send, "m_bCritical", 1);
		}
		DispatchSpawn(child);
		//SDKHook(child, SDKHook_Touch, OnMirvOverlap);
		TeleportEntity(child, pos, child_ang, child_vel);
		//RequestFrame(SetProjectileModel, child);
		PrecacheModel("models/workshop/weapons/c_models/c_quadball/w_quadball_grenade.mdl");
		SetEntityModel(child, "models/workshop/weapons/c_models/c_quadball/w_quadball_grenade.mdl");
	}
}



// float g_skill_time;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (ActiveHasAddCondStatPlayer(client))
	{
		
		if(TF2_IsPlayerInCondition(client, g_TFCond) && g_skill < GetEngineTime())
		{

			// PrintToChatAll("Cond: %i\nDmg:%0.0f\nScl:%f\nIntrvl:%f", g_TFCond, g_damage, g_bomb_scale, g_attack_interval);
			SpawnBombs(client, client);
			g_skill = GetEngineTime() + g_attack_interval;
		}
	}
	return Plugin_Continue;
}




