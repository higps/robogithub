#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <tf2_stocks>
#include <tf2utils>
#include <tf_ontakedamage>

#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Gunslinger"
#define SECONDARY_RELOAD_COOLDOWN 0.5

int g_HealthBeforeDamage[MAXPLAYERS + 1];
float g_NextReloadTime[MAXPLAYERS + 1][2];

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

	int primary = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
	int secondary = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Secondary);
	if (weapon == primary)
	{
		TryAddRoundToClip(attacker, TFWeaponSlot_Secondary);
	}
	else if (weapon == secondary)
	{
		TryAddRoundToClip(attacker, TFWeaponSlot_Primary);
	}
}

public void OnClientDisconnect(int client)
{
	g_NextReloadTime[client][TFWeaponSlot_Primary] = 0.0;
	g_NextReloadTime[client][TFWeaponSlot_Secondary] = 0.0;
}

void TryAddRoundToClip(int client, int slot)
{
	float currentTime = GetEngineTime();
	if (currentTime < g_NextReloadTime[client][slot])
	{
		return;
	}

	int weapon = GetPlayerWeaponSlot(client, slot);
	if (AddRoundToClip(weapon))
	{
		g_NextReloadTime[client][slot] = currentTime + SECONDARY_RELOAD_COOLDOWN;
	}
}

bool AddRoundToClip(int weapon)
{
	if (weapon <= MaxClients || !IsValidEntity(weapon))
	{
		return false;
	}

	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	int maxClip = TF2Util_GetWeaponMaxClip(weapon);
	if (clip < 0 || maxClip <= 0 || clip >= maxClip)
	{
		return false;
	}

	SetEntProp(weapon, Prop_Send, "m_iClip1", clip + 1);
	return true;
}