#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"General Crits"
#define ROBOT_ROLE "ZBOSS"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Rockets"
#define ROBOT_DESCRIPTION "Rapid Critical Rockets"
#define ROBOT_TIPS "Firing speed increases as health decreases"
#define ROBOT_ON_DEATH "General Crits's firing speed increases as health decreases\nAttack him during his reload"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN   "mvm/ambient_mp3/mvm_siren.mp3"
#define DEATH   "mvm/mvm_tank_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

#define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"


float scale = 1.75;

public Plugin:myinfo = 
{
	name = "[TF2] Be the Segreant Kritz",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Sergeant kritz",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

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

	//	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	AddNormalSoundHook(BossHomer);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = "Soldier";
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
	restrictions.TeamCoins.Overall = 2;

	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = 4.0;

	AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, restrictions);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantSoldier", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	




	PrecacheSound(GUNFIRE);
	PrecacheSound(GUNFIRE_CRIT);
	PrecacheSound(GUNFIRE_EXPLOSION);
	



	
	
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:BossHomer(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	
	if (strncmp(sample, ")weapons/", 9, false) == 0)
	{
		if (StrContains(sample, "rocket_shoot.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE);
			EmitSoundToAll(sample, entity);
			
		}
		else if (StrContains(sample, "rocket_shoot_crit.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_CRIT);
			EmitSoundToAll(sample, entity);
		}
		
		//Explosion doesnæt quite work
		/* 		else if (StrContains(sample, "explode1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		} */
		return Plugin_Changed;
	}
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Boss Homer");
	TF2_SetPlayerClass(client, TFClass_Soldier);
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
	SetModel(client, GSOLDIER);
	
	int iHealth = 5800;		
	int MaxHealth = 200;
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "healing received penalty", 0.0);
	TF2Attrib_SetByName(client, "health from healers reduced", 0.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.65);
	TF2Attrib_SetByName(client, "hand scale", 1.3);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	// TF2Attrib_SetByName(client, "head scale", 0.75);
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	//SetBossHealth(client);
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
#define Coif 30388
#define Tyrantium_Helmet 30014

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{	
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboHat(client, Tyrantium_Helmet, 10, 6, 0.0, 1.0, -1.0); //Bobby Bonnet
		CreateRoboHat(client, Coif, 10, 6, 0.0, 0.75, -1.0); //Bobby Bonnet
		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 18, 6, 1, 2, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "damage penalty", 0.8);
			TF2Attrib_SetByName(Weapon1, "mod weapon blocks healing", 1.0);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);				
			TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 7.0);
			//TF2Attrib_SetByName(Weapon1, "fire rate bonus", 1.5);
			TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 1.1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "Reload time increased", 1.75);
			// TF2Attrib_SetByName(Weapon1, "fire rate bonus with reduced health", 0.15);
			//TF2Attrib_SetByName(Weapon1, "mini rockets", 5.0);
			//TF2Attrib_SetByName(Weapon1, "auto fires when full", 1.0);
			//TF2Attrib_SetByName(Weapon1, "auto fires full clip", 1.0);
			
			
			 
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2CustAttr_SetString(client, "projectile-size", "size=1.3 update-hitbox=1");
			//TF2CustAttr_SetString(Weapon1, "homing_proj_mvm", "detection_radius=250.0 homing_mode=0 projectilename=tf_projectile_rocket");			
		}
		TF2_AddCondition(client, TFCond_CritCanteen);
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));

	

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
// 		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.25);
// 	}
// }
