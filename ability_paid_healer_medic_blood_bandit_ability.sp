#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Blood Bandit"
#define BLEED_HEAL_MULTIPLIER 1.0
#define VAMPIRE_BLEED_DURATION 1.0

public Plugin:myinfo =
{
	name = "[TF2] Blood Bandit Ability",
	author = "HiGPS | Bmod.TF",
	description = "Ability for Blood Bandit healer: bleed damage dealt by robots heals all robots",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if (damagecustom != TF_CUSTOM_BLEEDING || !IsValidClient(victim) || !IsValidClient(attacker) || !IsAnyRobot(attacker))
	{
		return Plugin_Continue;
	}

	if (!IsBloodBanditActive())
	{
		return Plugin_Continue;
	}

	int healAmount = RoundToNearest(damage * BLEED_HEAL_MULTIPLIER);
	if (healAmount <= 0)
	{
		return Plugin_Continue;
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsAnyRobot(client) && IsPlayerAlive(client))
		{
			AddPlayerHealth(client, healAmount, 1, false, true);
		}
	}

	return Plugin_Continue;
}

bool IsBloodBanditActive()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsRobot(client, ROBOT_NAME) && IsPlayerAlive(client))
		{
			return true;
		}
	}
	return false;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition != TFCond_RuneVampire || !IsAnyRobot(client))
	{
		return;
	}

	for (int slot = 0; slot < 6; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (IsValidEntity(weapon))
		{
			TF2Attrib_SetByName(weapon, "bleeding duration", VAMPIRE_BLEED_DURATION);
		}
	}
}
