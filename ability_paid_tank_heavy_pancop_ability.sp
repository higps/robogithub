#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>

#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Pancop"

int g_HealthBeforeDamage[MAXPLAYERS + 1];
float g_BerserkResetDelay = 3.0;
float g_BerserkFireRatePerHit = 0.95;
float g_BerserkMinFireRate = 0.25;
Handle g_BerserkTimer[MAXPLAYERS + 1];
int g_BerserkWeaponRef[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
bool g_BerserkHadAttribute[MAXPLAYERS + 1];
float g_BerserkBaseFireRate[MAXPLAYERS + 1];
float g_BerserkFireRate[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TF2]Pancop Ability",
	author = "HiGPS | Bmod.TF",
	description = "Ability for Pancop robot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
	int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
	int damagecustom, CritType &critType)
{
	if (IsValidClient(victim))
	{
		g_HealthBeforeDamage[victim] = GetClientHealth(victim);
	}

	return Plugin_Continue;
}

public void TF2_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage,
	int damagetype, int weapon, const float damageForce[3], const float damagePosition[3],
	int damagecustom, CritType critType)
{
	if (!IsValidClient(victim) || !IsValidClient(attacker) || damage <= 0.0)
	{
		return;
	}

	if (!IsRobot(attacker, ROBOT_NAME) || GetClientTeam(attacker) == GetClientTeam(victim)
		|| GetClientHealth(victim) >= g_HealthBeforeDamage[victim])
	{
		return;
	}

	float speedBonus = 1.0;
	Address speedAttribute = TF2Attrib_GetByName(attacker, "move speed bonus");
	if (speedAttribute != Address_Null)
	{
		speedBonus = TF2Attrib_GetValue(speedAttribute);
	}
	PrintToChatAll("Speed %f",speedBonus);
	float newSpeedBonus = speedBonus + 0.05;
	if (newSpeedBonus > 2.2)
	{
		newSpeedBonus = 2.2;
	}
	TF2Attrib_SetByName(attacker, "move speed bonus", newSpeedBonus);
	if (speedBonus < 2.2)
	{
		float airblastVulnerability = 1.0;
		Address airblastAttribute = TF2Attrib_GetByName(attacker, "airblast vulnerability multiplier");
		if (airblastAttribute != Address_Null)
		{
			airblastVulnerability = TF2Attrib_GetValue(airblastAttribute);
		}
		PrintToChatAll("Vuln %f", airblastVulnerability);
		TF2Attrib_SetByName(attacker, "airblast vulnerability multiplier", airblastVulnerability + 0.035);
	}
	if (!TF2_IsPlayerInCondition(attacker, TFCond_SpeedBuffAlly))
	{
		TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 0.1);
	}

	int melee = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
	if (melee != -1 && weapon == melee)
	{
		ApplyBerserkHit(attacker, melee);
	}
}

void ApplyBerserkHit(int client, int weapon)
{
	if (EntRefToEntIndex(g_BerserkWeaponRef[client]) != weapon)
	{
		ResetBerserk(client);
		g_BerserkWeaponRef[client] = EntIndexToEntRef(weapon);
		Address attribute = TF2Attrib_GetByName(weapon, "fire rate bonus");
		g_BerserkHadAttribute[client] = attribute != Address_Null;
		g_BerserkBaseFireRate[client] = attribute != Address_Null ? TF2Attrib_GetValue(attribute) : 1.0;
		g_BerserkFireRate[client] = g_BerserkBaseFireRate[client];
	}

	g_BerserkFireRate[client] *= g_BerserkFireRatePerHit;
	if (g_BerserkFireRate[client] < g_BerserkMinFireRate)
	{
		g_BerserkFireRate[client] = g_BerserkMinFireRate;
	}


	TF2Attrib_SetByName(weapon, "fire rate bonus", g_BerserkFireRate[client]);
	// PrintToChatAll("%f",g_BerserkFireRate[client]);
	if (g_BerserkTimer[client] != null)
	{
		delete g_BerserkTimer[client];
	}
	g_BerserkTimer[client] = CreateTimer(g_BerserkResetDelay, Timer_ResetBerserk, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ResetBerserk(Handle timer, any client)
{
	g_BerserkTimer[client] = null;
	ResetBerserk(client);
	return Plugin_Stop;
}

void ResetBerserk(int client)
{
	if (g_BerserkTimer[client] != null)
	{
		delete g_BerserkTimer[client];
	}

	int weapon = EntRefToEntIndex(g_BerserkWeaponRef[client]);
	if (weapon != INVALID_ENT_REFERENCE && IsValidEntity(weapon))
	{
		if (g_BerserkHadAttribute[client])
		{
			TF2Attrib_SetByName(weapon, "fire rate bonus", g_BerserkBaseFireRate[client]);
		}
		else
		{
			TF2Attrib_RemoveByName(weapon, "fire rate bonus");
		}
	}
	g_BerserkWeaponRef[client] = INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect(int client)
{
	ResetBerserk(client);
}

public void OnMapEnd()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		ResetBerserk(client);
	}
}

public void OnPluginEnd()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		ResetBerserk(client);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
        if (tauntid == -1)
        {
		TF2_AddCondition(client, TFCond_Buffed, 30.0);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 30.0);
		
		CreateTimer(3.5, Timer_Taunt_Cancel, client);
        }	  
	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){

		TF2_RemoveCondition(client, TFCond_Taunting);

		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon); 
	}
}
