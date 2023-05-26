#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_custom_attributes>
#include <tf2utils>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Sky Sweeper"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Anti-Jumpers"
#define ROBOT_COST 1.5
#define ROBOT_STATS "Shoot down jumping soldiers"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"


#define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
// #define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"


// #define MAX_ENTITY_LIMIT 2048

// bool g_bHomingEnabled[MAX_ENTITY_LIMIT + 1];
// float g_flHomingAccuracy[MAX_ENTITY_LIMIT + 1];
// int g_iLauncher[MAX_ENTITY_LIMIT + 1];

// float g_flHomingPoint[MAX_ENTITY_LIMIT + 1][3];
// int g_iLatestProjectile[MAX_ENTITY_LIMIT + 1];

// Handle g_KillTimer[MAX_ENTITY_LIMIT + 1];

// int g_iBlueGlowModelID = -1;
// int g_iRedGlowModelID = -1;

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Rapid Fire soldier",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Homer",
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
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;

	// 	    RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// // restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// // restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	// restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	// restrictions.RobotCoins.Overall = 5;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

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

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}

	
	// if (strncmp(sample, ")weapons/", 9, false) == 0)
	// {
	// 	if (StrContains(sample, "rocket_directhit_shoot.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE);
	// 		EmitSoundToAll(sample, entity);
			
	// 	}
	// 	else if (StrContains(sample, "rocket_directhit_shoot_crit.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_CRIT);
	// 		EmitSoundToAll(sample, entity);
	// 	}
		
	// 	//Explosion doesnæt quite work
	// 	/* 		else if (StrContains(sample, "explode1.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
	// 		EmitSoundToAll(sample, entity);
	// 	}
	// 	else if (StrContains(sample, "explode2.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
	// 		EmitSoundToAll(sample, entity);
	// 	}
	// 	else if (StrContains(sample, "explode3.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
	// 		EmitSoundToAll(sample, entity);
	// 	} */
	// 	return Plugin_Changed;
	// }
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Homer");
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
	
	int iHealth = 3800;
		
	int MaxHealth = 200;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	//TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_STATS);
	
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
#define JumperJeepCap 417
#define ManInSlacks 30392
#define Attire 30983

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		// g_bHomingEnabled[client] = true;
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		// CreateRoboWeapon(client, "tf_weapon_shotgun", 199, 6, 2, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 414, 6, 1, 0, 0);
		CreateRoboWeapon(client, "tf_weapon_shotgun_soldier", 415, 8, 1, 2, 0);
		
		
		CreateRoboHat(client, JumperJeepCap, 10, 6, 0.0, 0.8, -1.0);
		CreateRoboHat(client, ManInSlacks, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, Attire, 10, 6, 0.0, 0.75, -1.0);

	//	CreateHat(client, 30050, 10, 6, true); //Gatebot
		//CreateRoboWeapon(client, "tf_weapon_buff_item", 129, 6, 1, 1, 0);
		//CreateHat(client, 647, 10, 6, true); //The All-Father
		//CreateHat(client, 343, 10, 6, true);//Professor speks

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "weapon spread bonus", 0.85);
			TF2Attrib_SetByName(Weapon1, "Reload time increased", 0.25);
			TF2Attrib_SetByName(Weapon1, "clip size penalty", 0.25);

		}


		if(IsValidEntity(Weapon2))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon2, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "weapon spread bonus", 0.85);
			TF2Attrib_SetByName(Weapon2, "Reload time increased", 0.25);
			TF2Attrib_SetByName(Weapon2, "clip size penalty", 0.1);

		}
		
		RoboCorrectClipSize(Weapon1);
		RoboCorrectClipSize(Weapon2);

	}
}


public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));


