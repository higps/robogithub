#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Stompatron"


#define sBoomNoise  "mvm/mvm_bomb_explode.wav"

public Plugin:myinfo =
{
	name = "boom bullshit",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Stompatron",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnMapStart()
{
	PrecacheSound(sBoomNoise);
}
 

void StunPlayer (int victim)
{
	if (!TF2_IsPlayerInCondition(victim, TFCond_Taunting) && !IsAnyRobot(victim)){
	
		TF2_StunPlayer(victim, 3.5, 0.0, TF_STUNFLAG_BONKSTUCK);
	}	
}


public Action StompBoom(Handle timer, any data)
{
	Handle infokv = data;
	int attacker = KvGetNum(infokv, "attacker");
	int victim = KvGetNum(infokv, "victim");
	float pos1[3];
	float pos22[3];
	float pos2[3];
	GetClientAbsOrigin(attacker, pos1);
	GetClientAbsOrigin(victim, pos22);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "skull_island_explosion");
	AcceptEntityInput(particle, "Start");
	TeleportEntity(particle, pos22, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);

	
	for(int client = 1 ; client <= MaxClients ; client++ )
	{
		if(IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos2);
			if(GetVectorDistance(pos1, pos2) <= 250.0 && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				SDKHooks_TakeDamage(client, 0, attacker, 1500.0, 0, -1);
				
				EmitAmbientSound(sBoomNoise, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);

			}
		}
	}
	return Plugin_Continue;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;


	if(IsRobot(attacker, ROBOT_NAME))
	{
		
		if(TF2_IsPlayerInCondition(victim, TFCond_Taunting) && !IsAnyRobot(victim))
		{
			int tauntid = GetEntProp(victim, Prop_Send, "m_iTauntItemDefIndex");
			if (tauntid != -1)SendVictimToSpace(victim);
		}

		if(!TF2_IsPlayerInCondition(attacker, TFCond_RuneWarlock) && IsPlayerAlive(attacker)) RequestFrame(StunPlayer, victim);

	}  

	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		if (IsRobot(attacker, ROBOT_NAME) && damagecustom == TF_CUSTOM_BOOTS_STOMP)
		{
		Handle infokv = CreateKeyValues("infokv");
		KvSetNum(infokv, "attacker", attacker);
		KvSetNum(infokv, "victim", victim);
		CreateTimer(0.0, StompBoom, infokv);

		}

	}

	return Plugin_Continue;
}
  

void SendVictimToSpace(int victim)
{
	float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
	GetClientEyePosition(victim, vOrigin);
	GetClientEyeAngles(victim, vAngles);
	
	// Get the direction we want to go
	GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	
	// make it usable
	float flDistance = -380.0;

	ScaleVector(vForward, flDistance);	
	
	// add it to the current velocity to avoid just being able to do full 180s
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vVelocity);
	AddVectors(vVelocity, vForward, vVelocity);
	
	float flDistanceVertical = 250.0;
		
	vVelocity[2] += flDistanceVertical; // we always want to go a bit up
	
	// And set it


	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vVelocity);
}