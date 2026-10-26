#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>

#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Gunslinger"

int g_HealthBeforeDamage[MAXPLAYERS + 1];
float g_BerserkResetDelay = 1.5;
float g_BerserkFireRatePerHit = 0.96;
Handle g_BerserkTimer[MAXPLAYERS + 1];
bool g_BerserkActive[MAXPLAYERS + 1];
int g_BerserkWeaponRef[MAXPLAYERS + 1][2];
bool g_BerserkHadAttribute[MAXPLAYERS + 1][2];
float g_BerserkBaseFireRate[MAXPLAYERS + 1][2];
float g_BerserkFireRate[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[TF2]Gunslinger Ability",
	author = "HiGPS | Bmod.TF",
	description = "Ability for Gunslinger robot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
};

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

	ApplyBerserkHit(attacker);
}

void ApplyBerserkHit(int client)
{
	// PrintToChatAll("Berserk active");
	if (!g_BerserkActive[client])
	{
		g_BerserkFireRate[client] = 1.0;
		g_BerserkActive[client] = true;
	}

	g_BerserkFireRate[client] *= g_BerserkFireRatePerHit;
	for (int slot = TFWeaponSlot_Primary; slot <= TFWeaponSlot_Secondary; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (weapon <= MaxClients || !IsValidEntity(weapon))
		{
			ResetBerserkWeapon(client, slot);
			continue;
		}

		if (EntRefToEntIndex(g_BerserkWeaponRef[client][slot]) != weapon)
		{
			ResetBerserkWeapon(client, slot);
			g_BerserkWeaponRef[client][slot] = EntIndexToEntRef(weapon);
			Address attribute = TF2Attrib_GetByName(weapon, "fire rate bonus");
			g_BerserkHadAttribute[client][slot] = attribute != Address_Null;
			g_BerserkBaseFireRate[client][slot] = attribute != Address_Null ? TF2Attrib_GetValue(attribute) : 1.0;
		}

		TF2Attrib_SetByName(weapon, "fire rate bonus", g_BerserkBaseFireRate[client][slot] * g_BerserkFireRate[client]);
	}
	// PrintToChatAll("Sat firerate");
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

void ResetBerserkWeapon(int client, int slot)
{
	int weapon = EntRefToEntIndex(g_BerserkWeaponRef[client][slot]);
	if (weapon > MaxClients && IsValidEntity(weapon))
	{
		if (g_BerserkHadAttribute[client][slot])
		{
			TF2Attrib_SetByName(weapon, "fire rate bonus", g_BerserkBaseFireRate[client][slot]);
		}
		else
		{
			TF2Attrib_RemoveByName(weapon, "fire rate bonus");
		}
	}
	g_BerserkWeaponRef[client][slot] = INVALID_ENT_REFERENCE;
}

void ResetBerserk(int client)
{
	if (g_BerserkTimer[client] != null)
	{
		delete g_BerserkTimer[client];
	}

	for (int slot = TFWeaponSlot_Primary; slot <= TFWeaponSlot_Secondary; slot++)
	{
		ResetBerserkWeapon(client, slot);
	}
	g_BerserkActive[client] = false;
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