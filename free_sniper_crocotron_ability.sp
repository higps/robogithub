#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Crocotron"

public Plugin:myinfo =
{
	name = "[TF2] Crocoton Ability",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Jbird",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	// if (!g_Enable)
	//     return Plugin_Continue;
	if(!IsValidClient(victim))
		return Plugin_Continue;    
	if(!IsValidClient(attacker))
		return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME) && damagecustom != 0)
	{

		SpawnBombs(victim, attacker);


	}


	return Plugin_Continue;
}

void SpawnBombs(int client, int attacker)
{
    
    int team = GetClientTeam(attacker);
    float pos[3], vel[3];// ang[3];
    int children = 1;
    float speed = 250.0;


    GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
    

    pos[2] += 80.0;
    for (int i = 1; i <= children; i++)
    {
        int child = CreateEntityByName("tf_projectile_jar");
        
        
        float child_vel[3];
        float child_ang[3];

        //Prevent child grenades from detonating on contact
        SetEntProp(child, Prop_Send, "m_bTouched", 1);

        //Set properties
        //SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
        SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
        SetEntPropEnt(child, Prop_Data, "m_hThrower", attacker);

        
        // SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
        // SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);
        
        GetClientEyeAngles(client, child_ang);
        
        GetAngleVectors(child_ang, child_vel, NULL_VECTOR, NULL_VECTOR);
        
        ScaleVector(child_vel, speed);
            
        //child_vel[2] = FloatAbs(child_vel[2]);

        SetEntProp(child, Prop_Send, "m_iTeamNum", team);
        SetEntProp(child, Prop_Send, "m_bIsLive", 1);

        TeleportEntity(child, pos, child_ang, child_vel);
        DispatchSpawn(child);
        //SDKHook(child, SDKHook_Touch, OnMirvOverlap);
    }
}
