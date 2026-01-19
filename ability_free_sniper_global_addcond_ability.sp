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

int g_space_guy_kill_count = 0;
int g_space_guy_kill_requirement = 3;

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int death_flags = GetEventInt(event, "death_flags");
    if((death_flags & TF_DEATHFLAG_DEADRINGER) != TF_DEATHFLAG_DEADRINGER) 
	{
		if (IsRobot(attacker, SPACEGUYONLINE))
		{
			g_space_guy_kill_count++;
			if(g_space_guy_kill_count >= g_space_guy_kill_requirement)
			{
				for(int client = 1 ; client <= MaxClients ; client++ )
				{
					if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client))
					{
						
						TF2_AddCondition(client, TFCond_CritCola, 3.0);
						g_space_guy_kill_count = 0;
					}
				}
			}
		}	

		if (IsRobot(attacker, CARBINECASSIDY))
		{
			for(int client = 1 ; client <= MaxClients ; client++ )
			{
				if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client))
				{
					
					PrintCenterText(client,"Speed boost from %N", client);
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
			if(IsAnyRobot(client) && GetClientTeam(attacker) == GetClientTeam(client) && !TF2_IsPlayerInCondition(client, TFCond_Overhealed))
			{
				// (int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false, bShowHealthGain = true)
				
				if(!IsBoss(client))AddPlayerHealth(client, RoundToNearest(damage/1.2), 1, false, true);

			}
		}
	}




	
	return Plugin_Continue;
}
