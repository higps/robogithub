#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define SPACEGUYONLINE "SpaceGuyOnline"
#define SKEETER "Skeeter"
#define CARBINECASSIDY "Carbine Cassidy"
#define HUNTSBOT "Huntsbot"
// #define SOUND_LEAP  "TFPlayer.AirBlastImpact"
public Plugin:myinfo =
{
	name = "[TF2] Sniper Boosted Buffs Ability",
	author = "HeavyIsGPS",
	description = "Ability for sniper to give some team utility",
	version = PLUGIN_VERSION,
	url = "www.bmod.tf"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}


public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int death_flags = GetEventInt(event, "death_flags");
    if((death_flags & TF_DEATHFLAG_DEADRINGER) != TF_DEATHFLAG_DEADRINGER) 
	{
		if (IsRobot(attacker, SPACEGUYONLINE))
		{
			for(int client = 1 ; client <= MaxClients ; client++ )
			{
				if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client))
				{
					
					TF2_AddCondition(client, TFCond_CritCola, 3.0);

				}
			}
		}	

		if (IsRobot(attacker, CARBINECASSIDY))
		{
			for(int client = 1 ; client <= MaxClients ; client++ )
			{
				if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client))
				{
					
					TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);

				}
			}
		}
		if (IsRobot(attacker, HUNTSBOT))
		{
			for(int client = 1 ; client <= MaxClients ; client++ )
			{
				if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client))
				{
					
					TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 3.0);

				}
			}
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

	if (IsRobot(attacker, SKEETER))
	{
		for(int client = 1 ; client <= MaxClients ; client++ )
		{
			if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client))
			{
				
				if(!IsBoss(client))AddPlayerHealth(client, RoundToNearest(damage/1.5), 1);

			}
		}
	}




	
	return Plugin_Continue;
}
