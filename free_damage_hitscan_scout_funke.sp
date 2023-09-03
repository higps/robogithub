#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Funke"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Scout"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Cleaver + Batsaber Combo"
#define ROBOT_TIPS "Batsaber deals minicrits to bleeding enemies\nYour cleavers recharge faster"
#define ROBOT_ON_DEATH "This robot takes extreme knockback from pushforces and damage"

#define GSCOUT		"models/bots/scout_boss/bot_scout_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_scout/giant_scout_loop.wav"

// #define BLUE_MODEL "models/workshop/weapons/c_models/c_invasion_bat/c_invasion_bat.mdl"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant <Someone> Scout",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Scout",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

int g_iTeam;
char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

	LoadTranslations("common.phrases");




	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;

	AddRobot(robot, MakeGiantscout, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantscout", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

// public OnMapStart()
// {

// 	PrecacheModel(BLUE_MODEL);
// }

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

MakeGiantscout(client)
{
	SMLogTag(SML_VERBOSE, "Createing ScoutName");
	TF2_SetPlayerClass(client, TFClass_Scout);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GSCOUT);
	
	int iHealth = 1250;
		
	int MaxHealth = 125;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.3);
	TF2Attrib_SetByName(client, "damage force increase", 10.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 2.25);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 2.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, ROBOT_TIPS);
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

#define CoPilot 30576
#define GrayBanns 30104
#define TheMuttonMann 986

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_cleaver", 812, 6, 1, 1, 0);
		CreateRoboWeapon(client, "tf_weapon_bat", 30667, 6, 1, 2, 0);
		
		CreateRoboHat(client, CoPilot, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, GrayBanns, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, TheMuttonMann, 10, 6, 0.0, 0.75, -1.0); 
		

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "effect bar recharge rate increased", 1.5);
			// TF2Attrib_SetByName(Weapon1, "bleeding duration", 0.01);
			
			// TF2Attrib_SetByName(Weapon1, "Projectile speed increased", 10.0);
			// TF2Attrib_SetByName(Weapon1, "mark for death", 10.0);
			
			//TF2Attrib_SetByName(Weapon1, "minicritboost on kill", 5.0);
		}

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2CustAttr_SetString(Weapon2, "mod crit type on target condition", "condition=25 crit_type=1");
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs buildings", 0.25);
		}
		// g_iTeam = GetClientTeam(client);
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantscout(GetNativeCell(1));


// public void OnEntityCreated(int iEntity, const char[] sClassName) 
// {
// 	if (StrContains(sClassName, "tf_projectile") == 0)
// 	{
// 		SDKHook(iEntity, SDKHook_Spawn, Hook_OnProjectileSpawn);
// 	}
	
// }

// public void Hook_OnProjectileSpawn(iEntity) {
// 	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
// 	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {

// 		RequestFrame(SetProjectileModel, iEntity);
// 		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.75);
// 	}
// }


		

// float g_fStockvecMin[3] = {-10.0, -10.0, -10.0};
// float g_fStockvecMax[3] = {10.0, 10.0, 10.0};

// void SetProjectileModel (int iEntity)
// {
// 	if(g_iTeam == 2)
// 	{
// 		//Red
// 		SetEntityModel(iEntity, BLUE_MODEL);
		
// 	}else
// 	{
// 		SetEntityModel(iEntity, BLUE_MODEL);
// 	}


// 	SetEntPropVector(iEntity, Prop_Send, "m_vecMins", g_fStockvecMin);
// 	SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", g_fStockvecMax);

// }
