#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <tf2_stocks>
#include <tf2utils>
#include <tf_ontakedamage>
#include <tf2attributes>

#include <berobot_constants>
#include <berobot>


#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Gunslinger"
#define SECONDARY_RELOAD_COOLDOWN 0.05


#pragma semicolon 1



float g_BerserkResetDelay = 4.0;
float g_BerserkFireRatePerHit = 0.90;
float g_BerserkMinFireRate = 0.4; // lowest fire interval multiplier (0.4 = 60% faster)
Handle g_BerserkTimer[MAXPLAYERS + 1];
bool g_BerserkActive[MAXPLAYERS + 1];
int g_BerserkWeaponRef[MAXPLAYERS + 1][2];
bool g_BerserkHadAttribute[MAXPLAYERS + 1][2];
float g_BerserkBaseFireRate[MAXPLAYERS + 1][2];
float g_BerserkFireRate[MAXPLAYERS + 1];

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
	if (!IsValidClient(victim) || !IsValidClient(attacker) || damage <= 0.0)
	{
		return Plugin_Continue;
	}

	if (!IsRobot(attacker, ROBOT_NAME) || GetClientTeam(attacker) == GetClientTeam(victim))
	{
		return Plugin_Continue;
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

	ApplyBerserkHit(attacker);
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	g_NextReloadTime[client][TFWeaponSlot_Primary] = 0.0;
	g_NextReloadTime[client][TFWeaponSlot_Secondary] = 0.0;
	ResetBerserk(client);
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




void ApplyBerserkHit(int client)
{
	// PrintToChatAll("Berserk active");
	if (!g_BerserkActive[client])
	{
		g_BerserkFireRate[client] = 1.0;
		g_BerserkActive[client] = true;
	}

	g_BerserkFireRate[client] *= g_BerserkFireRatePerHit;
	if (g_BerserkFireRate[client] < g_BerserkMinFireRate)
	{
		g_BerserkFireRate[client] = g_BerserkMinFireRate;
	}

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
