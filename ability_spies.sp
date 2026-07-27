#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"

Handle g_SpyHealTimer[MAXPLAYERS + 1] = {null, ...};

public Plugin:myinfo =
{
	name = "[TF2] Robot Spy logic",
	author = "HiGPS | Bmod.TF",
	description = "Adds logic for spies",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_changeclass", Event_PlayerChangeClass, EventHookMode_Post);
}

#define sHealNoise "items/medshot4.wav"

public void OnMapStart()
{	
	PrecacheSound(sHealNoise);
}


public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobotSpy(client, condition))
    {
		StartSpyHealTimer(client);
		
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_Cloaked)
	{
		StopSpyHealTimer(client);
	}
}

public void OnClientDisconnect(int client)
{
	StopSpyHealTimer(client);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	StopSpyHealTimer(client);
	return Plugin_Continue;
}

public Action Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && TF2_GetPlayerClass(client) != TFClass_Spy)
	{
		StopSpyHealTimer(client);
	}
	return Plugin_Continue;
}

void StartSpyHealTimer(int client)
{
	if (!ShouldRunSpyHeal(client) || g_SpyHealTimer[client] != null)
	{
		return;
	}

	g_SpyHealTimer[client] = CreateTimer(4.0, Timer_HealSpy, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopSpyHealTimer(int client)
{
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	if (g_SpyHealTimer[client] != null)
	{
		KillTimer(g_SpyHealTimer[client]);
		g_SpyHealTimer[client] = null;
	}
}

bool ShouldRunSpyHeal(int client)
{
	return IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& TF2_GetPlayerClass(client) == TFClass_Spy
		&& IsAnyRobot(client)
		&& TF2_IsPlayerInCondition(client, TFCond_Cloaked);
}

public Action Timer_HealSpy(Handle timer, any userId)
{
	int client = GetClientOfUserId(userId);
	if (!ShouldRunSpyHeal(client))
	{
		if (client > 0 && client <= MaxClients && g_SpyHealTimer[client] == timer)
		{
			g_SpyHealTimer[client] = null;
		}
		return Plugin_Stop;
	}

	HealSpy(client);
	return Plugin_Continue;
}

public void HealSpy(int client)
{
	int maxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	int currentHealth = GetClientHealth(client);
	int missingHealth = maxHealth - currentHealth;

	if (missingHealth <= 0)
	{
		return;
	}
	// heals for 25% of missing health
	int hpHeal = RoundToNearest(float(missingHealth) * 0.25);
	if (hpHeal <= 0)
	{
		hpHeal = 1;
	}

	Megaton_HealClientByAmount(client, hpHeal);
	Megaton_ShowHealthGain(client, hpHeal, client, false);
	EmitSoundToClient(client, sHealNoise);
}

public bool IsRobotSpy(int client, TFCond condition)
{
	if (TF2_GetPlayerClass(client) == TFClass_Spy && IsAnyRobot(client) && condition == TFCond_Cloaked)
	{
		return true;
	}else
	{
		return false;
	}
}