#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>

#define ROBOT_NAME "Overwrite"

float g_DamageVsPlayers = 1.2;
float g_MoveSpeedPerKill = 0.9;

public Plugin myinfo =
{
	name = "[TF2] Copy Any-Class Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Copies the loadout and cosmetics of any enemy class on kill",
	version = "1.0"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(attacker) || !IsValidClient(victim) || attacker == victim)
		return;

	if (GetClientTeam(attacker) == GetClientTeam(victim)
		|| !IsRobot(attacker, ROBOT_NAME)
		|| !IsPlayerAlive(attacker))
		return;

	TF2Attrib_SetByName(attacker, "move speed penalty", g_MoveSpeedPerKill);
	TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 0.1);
	TFClassType victimClass = TF2_GetPlayerClass(victim);
	TF2_SetPlayerClass(attacker, victimClass, false, true);
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(attacker));
	data.WriteCell(GetClientUserId(victim));
	data.WriteCell(view_as<int>(victimClass));
	RequestFrame(Frame_RegenerateAndCopyLoadout, data);
}

void Frame_RegenerateAndCopyLoadout(DataPack data)
{
	data.Reset();
	int attacker = GetClientOfUserId(data.ReadCell());
	int victim = GetClientOfUserId(data.ReadCell());
	TFClassType victimClass = view_as<TFClassType>(data.ReadCell());
	delete data;

	if (!IsValidClient(attacker) || !IsValidClient(victim) || !IsPlayerAlive(attacker))
		return;

	if (victimClass == TFClass_Engineer)
		RegenerateCopyEngineer(attacker);

	SetCopyModel(attacker, victimClass);

	int lastSlot = TFWeaponSlot_Melee;
	if (victimClass == TFClass_Spy)
		lastSlot = 4;

	for (int slot = TFWeaponSlot_Primary; slot <= 4; slot++)
	{
		TF2_RemoveWeaponSlot(attacker, slot);
	}
	RemoveCopyBuilder(attacker);
	RoboRemoveAllWearables(attacker);

	for (int slot = TFWeaponSlot_Primary; slot <= lastSlot; slot++)
	{
		int victimWeapon = GetPlayerWeaponSlot(victim, slot);
		if (!IsValidEntity(victimWeapon))
			continue;

		char weaponClassname[64];
		if (!GetEntityClassname(victimWeapon, weaponClassname, sizeof(weaponClassname)))
			continue;

		int itemIndex = GetEntProp(victimWeapon, Prop_Send, "m_iItemDefinitionIndex");
		if (itemIndex <= 0)
			continue;

		int quality = GetEntProp(victimWeapon, Prop_Send, "m_iEntityQuality");
		int level = GetEntProp(victimWeapon, Prop_Send, "m_iEntityLevel");
		int paint = RoundToNearest(GetAttributeValue(victimWeapon, 834, 0.0));
		int copiedWeapon = CreateRoboWeapon(attacker, weaponClassname, itemIndex, quality, level, slot, paint);
		if (copiedWeapon > MaxClients && IsValidEntity(copiedWeapon))
			TF2Attrib_SetByName(copiedWeapon, "dmg penalty vs players", g_DamageVsPlayers);
	}

	if (victimClass == TFClass_Engineer)
	{
		CreateRoboWeaponWithAttributes(attacker, "tf_weapon_pda_engineer_build", 25, 6, 1, true, true, "");
		CreateRoboWeaponWithAttributes(attacker, "tf_weapon_pda_engineer_destroy", 26, 6, 1, true, true, "");
		CreateRoboWeaponWithAttributes(attacker, "tf_weapon_builder", 28, 6, 1, true, true, "");
	}

	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != victim)
			continue;

		int itemIndex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
		if (itemIndex <= 0)
			continue;

		int quality = GetEntProp(wearable, Prop_Send, "m_iEntityQuality");
		int level = GetEntProp(wearable, Prop_Send, "m_iEntityLevel");
		int paint = RoundToNearest(GetAttributeValue(wearable, 142, 0.0));
		int paint2 = RoundToNearest(GetAttributeValue(wearable, 261, 0.0));
		float scale = HasEntProp(wearable, Prop_Send, "m_flModelScale")
			? GetEntPropFloat(wearable, Prop_Send, "m_flModelScale")
			: 1.0;
		float style = GetAttributeValue(wearable, 542, -1.0);
		CreateRoboHat(attacker, itemIndex, level, quality, paint, paint2, scale, style);
	}

	HealCopy(attacker);
}

void RegenerateCopyEngineer(int client)
{
	bool wasMiniBoss = view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"));
	int currentHealth = GetClientHealth(client);
	int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");

	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 0);
	SetEntityHealth(client, 25);
	TF2_RegeneratePlayer(client);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", view_as<int>(wasMiniBoss));

	RoboSetHealth(client, view_as<int>(TFClass_Engineer), maxHealth);
	SetEntityHealth(client, currentHealth);

	int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (IsValidEntity(primary))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", primary);
}

void RemoveCopyBuilder(int client)
{
	int builder = GetPlayerWeaponSlot(client, TFWeaponSlot_Building);
	if (!IsValidEntity(builder))
		return;

	RemovePlayerItem(client, builder);
	if (IsValidEntity(builder))
		RemoveEntity(builder);
}

void SetCopyModel(int client, TFClassType class)
{
	char model[PLATFORM_MAX_PATH];
	switch (class)
	{
		case TFClass_Scout:
			strcopy(model, sizeof(model), "models/bots/scout/bot_scout.mdl");
		case TFClass_Soldier:
			strcopy(model, sizeof(model), "models/bots/soldier/bot_soldier.mdl");
		case TFClass_Pyro:
			strcopy(model, sizeof(model), "models/bots/pyro/bot_pyro.mdl");
		case TFClass_DemoMan:
			strcopy(model, sizeof(model), "models/bots/demo/bot_demo.mdl");
		case TFClass_Heavy:
			strcopy(model, sizeof(model), "models/bots/heavy/bot_heavy.mdl");
		case TFClass_Engineer:
			strcopy(model, sizeof(model), "models/bots/engineer/bot_engineer.mdl");
		case TFClass_Medic:
			strcopy(model, sizeof(model), "models/bots/medic/bot_medic.mdl");
		case TFClass_Sniper:
			strcopy(model, sizeof(model), "models/bots/Sniper/bot_Sniper.mdl");
		case TFClass_Spy:
			strcopy(model, sizeof(model), "models/bots/spy/bot_spy.mdl");
		default:
			return;
	}

	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

float GetAttributeValue(int entity, int definitionIndex, float defaultValue)
{
	Address attribute = TF2Attrib_GetByDefIndex(entity, definitionIndex);
	return attribute == Address_Null ? defaultValue : TF2Attrib_GetValue(attribute);
}

void HealCopy(int client)
{
	int maxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	int missingHealth = maxHealth - GetClientHealth(client);
	if (missingHealth <= 0)
		return;

	int healAmount = RoundToNearest(float(missingHealth) * 0.5);
	if (healAmount <= 0)
		healAmount = 1;

	Megaton_HealClientByAmount(client, healAmount);
	Megaton_ShowHealthGain(client, healAmount, client, false);
}