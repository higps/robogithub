#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Rapidfire"

// "fire rate bonus" value reached when the clip is empty (0.2 = 80% faster than base)
#define FIRE_RATE_CAP 0.2
// Higher values make the ramp stay flat for longer and then accelerate harder
#define RAMP_STEEPNESS 0.01
// Fraction of the clip spent at which the cap is reached (0.6 = cap reached at 60% spent)
#define RAMP_FULL_AT 0.6

public Plugin:myinfo =
{
	name = "[TF2] Rapid Fire Ability",
	author = "HiGPS | Bmod.TF",
	description = "Ability for Rapidfire robot: fire rate increases as the rocket launcher clip empties while firing",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

int g_WeaponRef[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
float g_BaseFireRate[MAXPLAYERS + 1];
int g_MaxClip[MAXPLAYERS + 1];
bool g_FireBlocked[MAXPLAYERS + 1];
float g_DebugNextPrint[MAXPLAYERS + 1]; // DEBUG

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !IsRobot(client, ROBOT_NAME))
	{
		return Plugin_Continue;
	}

	int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (!IsValidEntity(primary))
	{
		return Plugin_Continue;
	}

	if (EntIndexToEntRef(primary) != g_WeaponRef[client])
	{
		g_WeaponRef[client] = EntIndexToEntRef(primary);
		g_BaseFireRate[client] = GetBaseFireRate(primary);
		g_MaxClip[client] = 0;
		g_FireBlocked[client] = false;
	}

	int clip = GetEntProp(primary, Prop_Send, "m_iClip1");
	if (clip > g_MaxClip[client])
	{
		g_MaxClip[client] = clip;
	}

	// Once the clip is empty, firing is blocked until it is fully reloaded
	if (clip == 0 && g_MaxClip[client] > 0)
	{
		g_FireBlocked[client] = true;
	}
	else if (clip >= g_MaxClip[client])
	{
		g_FireBlocked[client] = false;
	}

	bool blocked = g_FireBlocked[client];
	if (blocked)
	{
		if (buttons & IN_ATTACK)
		{
			PrintCenterText(client, "UNABLE TO FIRE UNTIL RELOAD COMPLETE\nRELEASE YOUR FIRE BUTTON");
		}
		buttons &= ~IN_ATTACK;
	}

	float fireRate = g_BaseFireRate[client];
	if ((buttons & IN_ATTACK) && g_MaxClip[client] > 0 && clip < g_MaxClip[client])
	{
		float emptiness = float(g_MaxClip[client] - clip) / float(g_MaxClip[client]);
		fireRate = g_BaseFireRate[client] + (FIRE_RATE_CAP - g_BaseFireRate[client]) * GetRampProgress(emptiness);
	}

	TF2Attrib_SetByName(primary, "fire rate bonus", fireRate);

	// DEBUG: temporary, throttled to avoid flooding chat
	if ((buttons & IN_ATTACK) && GetGameTime() >= g_DebugNextPrint[client])
	{
		g_DebugNextPrint[client] = GetGameTime() + 0.5;
		PrintToChatAll("[Rapidfire DEBUG] missing clip: %d/%d | fire rate applied: %.3f", g_MaxClip[client] - clip, g_MaxClip[client], fireRate);
	}

	return blocked ? Plugin_Changed : Plugin_Continue;
} //when empty-ness is 0 and 1.0 once empty-ness reaches RAMP_FULL_AT, growing faster as the clip empties
float GetRampProgress(float emptiness)
{
	float t = emptiness / RAMP_FULL_AT;
	if (t > 1.0)
	{
		t = 1.0;
	}
	return (Pow(2.0, RAMP_STEEPNESS * t) - 1.0) / (Pow(2.0, RAMP_STEEPNESS) - 1.0);
}

float GetBaseFireRate(int weapon)
{
	Address attribute = TF2Attrib_GetByName(weapon, "fire rate bonus");
	if (attribute == Address_Null)
	{
		return 1.0;
	}
	return TF2Attrib_GetValue(attribute);
}

public void OnClientDisconnect(int client)
{
	g_WeaponRef[client] = INVALID_ENT_REFERENCE;
	g_MaxClip[client] = 0;
	g_FireBlocked[client] = false;
}
