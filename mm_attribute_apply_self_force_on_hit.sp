#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>


// float g_dmg = 1.0;
int g_requiredcond = -1;
float flDistance;
float flDistanceVertical;
float flClamp;
float g_clamptime[MAXPLAYERS + 1] = {0.0,...};

bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "pushforce-on-hit", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	// g_dmg = ReadFloatVar(stat_buffer, "damage", 1.0);
	g_requiredcond = ReadIntVar(stat_buffer, "cond", -1);
	flDistance = ReadFloatVar(stat_buffer, "flDist", 500.0);
	flDistanceVertical = ReadFloatVar(stat_buffer, "flDistVert", 100.0);
	flClamp = ReadFloatVar(stat_buffer, "clamp", -1.0);
	return true;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{

	if(IsValidClient(victim))
	{
		if(IsValidClient(attacker))
		{
			if(ActiveHasStatWeapon(weapon))
			{

			if(g_clamptime[attacker] < GetEngineTime())
			
			if(g_requiredcond == -1){

				DoTeleport(attacker);
			}else if (TF2_IsPlayerInCondition(attacker, view_as<TFCond>(g_requiredcond)))

				DoTeleport(attacker);
			}
		}
	}

	return Plugin_Continue;
}

void DoTeleport(int client)
{

	float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	// Get the direction we want to go
	GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	
	// make it usable
	// flDistance = -1000.0;
	// PrintToChatAll("0: %f1: %f 2: %f",vForward[0],vForward[1],vForward[2]);
	ScaleVector(vForward, flDistance);	
	// PrintToChatAll("0: %f1: %f 2: %f",vForward[0],vForward[1],vForward[2]);
	
	// add it to the current velocity to avoid just being able to do full 180s
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	AddVectors(vVelocity, vForward, vVelocity);
	
	// flDistanceVertical = 800.0;
		
	vVelocity[2] += flDistanceVertical; // we always want to go a bit up
	
	// And set it


	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	g_clamptime[client] = GetEngineTime() + flClamp;
}