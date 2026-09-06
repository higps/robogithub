#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
//#include <collisionhook>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
#pragma semicolon 1
//#pragma newdecls required

#define ROBOT_NAME	"Zonical"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Zonical QuickDraw Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Play as the Giant Zonical",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
// bool b_Hooked[MAXPLAYERS + 1] = {false,...};

float g_clip_bonus = 0.25;
float g_clip_bonus_increment = 0.03;
float g_clip_bonus_max = 8.0;
float g_current_clip_bonus[MAXPLAYERS + 1] = {1.0, ...};

float g_FanHammerCooldown = 6.0;
float g_FanHammerReady[MAXPLAYERS + 1] = {0.0, ...};
bool g_FanHammerAuraShown[MAXPLAYERS + 1] = {false, ...};

float g_DeployDamageRequirement = 250.0;
float g_DamageAccum[MAXPLAYERS + 1] = {0.0, ...};

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsRobot(client, ROBOT_NAME))
		return Plugin_Continue;

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	bool holdingPistol = IsPistol(activeWeapon);

	if (holdingPistol)
		DrawHUD(client);

	if (holdingPistol && (buttons & IN_ATTACK2) && GetEngineTime() >= g_FanHammerReady[client])
	{
		FanTheHammer(client);
		g_FanHammerReady[client] = GetEngineTime() + g_FanHammerCooldown;
	}

	return Plugin_Continue;
}

void DrawHUD(int client)
{
	char sHUDText[192];
	char sFanText[96];
	int iCountDown = RoundToCeil(g_FanHammerReady[client] - GetEngineTime());

	if (iCountDown <= 0)
	{
		Format(sFanText, sizeof(sFanText), "Fan The Hammer Ready!\nM2 to activate");
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

		if (!g_FanHammerAuraShown[client])
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
			g_FanHammerAuraShown[client] = true;
		}
	}
	else
	{
		Format(sFanText, sizeof(sFanText), "Fan The Hammer: %i", iCountDown);
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		g_FanHammerAuraShown[client] = false;
	}

	float damagePercent = (g_DamageAccum[client] / g_DeployDamageRequirement) * 100.0;
	if (damagePercent > 100.0)
		damagePercent = 100.0;

	Format(sHUDText, sizeof(sHUDText), "%s\nDeploy Bonus: %.0f%%", sFanText, damagePercent);

	ShowHudText(client, -2, sHUDText);
}

void FanTheHammer(int client)
{
	// TODO: implement Fan The Hammer effect
	TF2Attrib_AddCustomPlayerAttribute(client, "fire rate bonus", 0.33, 1.5);
	TF2Attrib_AddCustomPlayerAttribute(client, "weapon spread bonus", 2.0, 1.5);
}

public void OnClientPutInServer(int client)
{


	// Hook weapon switching for this client here:
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	// b_Hooked[client] = true;
}

public void OnClientDisconnect(int client)
{


	// Unhook our weapon switching:
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			// b_Hooked[i] = true;
			// PrintToChatAll("Hooked %N",i);
		}
	}
}

public void OnWeaponSwitch(int client, int weapon)
{
	// When we switch weapons, we're going to grant a damage bonus
	// based off of the "half second damage bonus" attribute.

	// We'll do the damage calculation in another function. Here we'll see
	// when until we can have this bonus.

	// Do we have "half second damage bonus"?
	if (IsRobot(client, ROBOT_NAME))
	{
		
		// PrintToChatAll("Weapon was %i", weapon);
		if (IsPistol(weapon) && g_DamageAccum[client] >= g_DeployDamageRequirement)
		{
			TF2_AddCondition(client, TFCond_CritHype, 1.5);
			g_DamageAccum[client] = 0.0;
			// // TF2Attrib_AddCustomPlayerAttribute(client, "faster reload rate", 0.5, 1.5);
			// // TF2Attrib_AddCustomPlayerAttribute(client, "fire rate bonus", 0.5, 1.5);
		}
	}
}

bool IsPistol(int weapon){
	if (weapon <= MaxClients || !IsValidEntity(weapon)) return false;
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
	case 22,160: 
		{
			return true;
		}
	}
	return false;
}

bool IsSentryInflictor(int inflictor)
{
	if (!IsValidEntity(inflictor))
		return false;

	char inflictorClassname[64];
	GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));

	if (StrEqual(inflictorClassname, "obj_sentrygun") || StrEqual(inflictorClassname, "tf_projectile_sentryrocket"))
		return true;

	return false;
}




public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{
		g_DamageAccum[attacker] += damage;
	}

	if (IsRobot(attacker, ROBOT_NAME) && IsSentryInflictor(inflictor))
	{
		//AddClipSize(attacker);
	}

	if (IsRobot(attacker, ROBOT_NAME) && TF2_IsPlayerInCondition(attacker, TFCond_CritHype))
	{
		// int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		int Weapon2 = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Secondary);
		if (IsCrit(attacker)) return Plugin_Continue;

		// PrintToChatAll("Crittype was %i", critType);
		if (weapon == Weapon2)
		{
			critType = CritType_MiniCrit;
			return Plugin_Changed;
		}
		return Plugin_Continue;
		
	}
	return Plugin_Continue;
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsRobotWhenDead(client, ROBOT_NAME))
	{
		g_current_clip_bonus[client] = 1.0;
		g_DamageAccum[client] = 0.0;
	}

	return Plugin_Continue;
}

// public void AddClipSize(int client)
// {
// 	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
// 	if (!IsValidEntity(Weapon2))
// 		return;

// 	g_current_clip_bonus[client] += g_clip_bonus_increment;
// 	if (g_current_clip_bonus[client] > g_clip_bonus_max)
// 		g_current_clip_bonus[client] = g_clip_bonus_max;
// 	TF2Attrib_SetByName(Weapon2, "clip size bonus", g_clip_bonus + g_current_clip_bonus[client]);
// 	TF2Attrib_AddCustomPlayerAttribute(client, "faster reload rate", 0.5, 1.5);
// 	TF2Attrib_AddCustomPlayerAttribute(client, "fire rate bonus", 0.8, 1.5);

// }

public bool IsCrit(int client){

	//Ignores damage reduction if you are kritzed or minicritted with buff banner or winning
	if(IsValidClient(client) && (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_Buffed)) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritCanteen))
	{
		return true;
	}
	return false;
}
