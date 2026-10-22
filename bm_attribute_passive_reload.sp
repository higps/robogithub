#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2utils>

#define SYRINGEGUN_CLASSNAME "tf_weapon_syringegun_medic"
#define PASSIVE_RELOAD_DELAY 1.6

int g_PreviousWeaponRef[MAXPLAYERS + 1];
bool g_DebugEnabled = false;

public void OnPluginStart()
{
	RegAdminCmd("sm_passive_reload_debug", Command_PassiveReloadDebug, ADMFLAG_GENERIC,
			"sm_passive_reload_debug <true|false>");
	DebugMessage("[PassiveReload] OnPluginStart: using TF2Utils for weapon clip capacity.");
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public Action Command_PassiveReloadDebug(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[PassiveReload] Usage: sm_passive_reload_debug <true|false>. Current: %s.",
				g_DebugEnabled ? "true" : "false");
		return Plugin_Handled;
	}

	char value[16];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "true", false))
	{
		g_DebugEnabled = true;
	}
	else if (StrEqual(value, "false", false))
	{
		g_DebugEnabled = false;
	}
	else
	{
		ReplyToCommand(client, "[PassiveReload] Expected true or false.");
		return Plugin_Handled;
	}

	ReplyToCommand(client, "[PassiveReload] Debug: %s.", g_DebugEnabled ? "true" : "false");
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	g_PreviousWeaponRef[client] = INVALID_ENT_REFERENCE;
	bool preHooked = SDKHookEx(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	bool postHooked = SDKHookEx(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	DebugMessage("[PassiveReload] Weapon switch hooks: client=%d, pre=%d, post=%d.", client, preHooked, postHooked);
	if (!preHooked || !postHooked)
	{
		SetFailState("Failed to hook weapon switching for client %d", client);
	}
}

public void OnClientDisconnect(int client)
{
	g_PreviousWeaponRef[client] = INVALID_ENT_REFERENCE;
}

public Action OnWeaponSwitch(int client, int weapon)
{
	int previousWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	g_PreviousWeaponRef[client] = INVALID_ENT_REFERENCE;
	if (previousWeapon > MaxClients && IsValidEntity(previousWeapon))
	{
		g_PreviousWeaponRef[client] = EntIndexToEntRef(previousWeapon);
	}
	DebugMessage("[PassiveReload] Switch pre: client=%d, outgoing=%d, requested=%d.", client, previousWeapon, weapon);
	return Plugin_Continue;
}

public void OnWeaponSwitchPost(int client, int weapon)
{
	int syringegun = EntRefToEntIndex(g_PreviousWeaponRef[client]);
	g_PreviousWeaponRef[client] = INVALID_ENT_REFERENCE;
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	DebugMessage("[PassiveReload] Switch post: client=%d, outgoing=%d, requested=%d, active=%d.", client, syringegun, weapon, activeWeapon);
	if (!IsPlayerAlive(client) || activeWeapon != weapon || syringegun == weapon
			|| syringegun <= MaxClients || !IsValidEntity(syringegun))
	{
		DebugMessage("[PassiveReload] Switch skipped: no confirmed change from a valid outgoing weapon.");
		return;
	}

	char classname[64];
	GetEntityClassname(syringegun, classname, sizeof(classname));
	if (!StrEqual(classname, SYRINGEGUN_CLASSNAME))
	{
		DebugMessage("[PassiveReload] Switch skipped: outgoing weapon is %s, not a syringe gun.", classname);
		return;
	}

	DebugMessage("[PassiveReload] Syringe gun holstered: weapon=%d.", syringegun);
	if (ReloadToFull(syringegun))
	{
		SetEntPropFloat(syringegun, Prop_Send, "m_flNextPrimaryAttack",
				GetGameTime() + PASSIVE_RELOAD_DELAY);
		DebugMessage("[PassiveReload] Reload succeeded: applied %.1f-second attack delay.", PASSIVE_RELOAD_DELAY);
	}
	else
	{
		DebugMessage("[PassiveReload] Switch callback: no ammo transferred.");
	}
}

bool ReloadToFull(int weapon)
{
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	DebugMessage("[PassiveReload] ReloadToFull: weapon=%d, owner=%d, ammo type=%d.", weapon, owner, ammoType);
	if (owner < 1 || owner > MaxClients || !IsClientInGame(owner) || ammoType < 0)
	{
		DebugMessage("[PassiveReload] Reload skipped: invalid owner, owner not in game, or invalid ammo type.");
		return false;
	}

	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	int maxClip = TF2Util_GetWeaponMaxClip(weapon);
	int reserve = GetEntProp(owner, Prop_Send, "m_iAmmo", _, ammoType);
	DebugMessage("[PassiveReload] Ammo before reload: clip=%d, max clip=%d, reserve=%d.", clip, maxClip, reserve);
	if (maxClip <= 0)
	{
		DebugMessage("[PassiveReload] Reload skipped: TF2Utils returned invalid clip capacity %d.", maxClip);
		return false;
	}
	if (clip < 0 || clip >= maxClip || reserve <= 0)
	{
		DebugMessage("[PassiveReload] Reload skipped: invalid/full clip or empty reserve.");
		return false;
	}

	int amount = maxClip - clip;
	if (amount > reserve)
	{
		amount = reserve;
	}

	SetEntProp(owner, Prop_Send, "m_iAmmo", reserve - amount, _, ammoType);
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip + amount);
	DebugMessage("[PassiveReload] Transferred %d ammo: clip=%d, reserve=%d.", amount,
			GetEntProp(weapon, Prop_Send, "m_iClip1"), GetEntProp(owner, Prop_Send, "m_iAmmo", _, ammoType));
	return true;
}

void DebugMessage(const char[] format, any ...)
{
	if (!g_DebugEnabled)
	{
		return;
	}

	char message[256];
	VFormat(message, sizeof(message), format, 2);
	PrintToChatAll("%s", message);
}