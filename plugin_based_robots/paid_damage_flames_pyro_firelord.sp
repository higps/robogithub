#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"FireLord"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Pyro"
#define ROBOT_SUBCLASS "Flames"
#define ROBOT_DESCRIPTION "Wide Fire"
#define ROBOT_TIPS "Heal 175 on extinguish"
#define ROBOT_ON_DEATH "Stay out of Fire Storms Range"
#define ROBOT_COST 3.0
#define ROBOT_COIN_GENERATION 1

#define GPYRO		"models/bots/pyro_boss/bot_pyro_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

#define SOUND_GUNFIRE	")mvm/giant_pyro/giant_pyro_flamethrower_loop.wav"
#define SOUND_WINDUP	")mvm/giant_pyro/giant_pyro_flamethrower_start.wav"



public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Agro Pyro",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Agro Pyro from Kritzkast",
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

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.sounds.gunfire = SOUND_GUNFIRE;
	robot.sounds.windup = SOUND_WINDUP;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.footstep = ROBOT_FOOTSTEP_GIANTCOMMON;
	robot.difficulty = ROBOT_DIFFICULTY_EASY;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION, restrictions, ROBOT_COIN_GENERATION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantPyro", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
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

MakeGiantPyro(client)
{
	SMLogTag(SML_VERBOSE, "Createing Agro");
	TF2_SetPlayerClass(client, TFClass_Pyro);
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
	SetModel(client, GPYRO);
	
	RoboSetHealth(client,TFClass_Pyro, 5000, 1.5);
		
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	// TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

	
	
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	
	PrintHintText(client , ROBOT_TIPS);
	
	
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}
#define FlameWarrior  31357 


stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_flamethrower", 208, 6, 1, 0, 205);	
		CreateRoboHat(client, FlameWarrior, 10, 6, 0.0, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon1))
		{

			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);				
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.8);				
			TF2Attrib_SetByName(Weapon1, "flame_spread_degree", 35.0);			
			TF2Attrib_SetByName(Weapon1, "flame size bonus", 1.6);
			TF2Attrib_SetByName(Weapon1, "flame_speed", 3600.0);
			TF2Attrib_SetByName(Weapon1, "extinguish restores health", 175.0);
			TF2CustAttr_SetString(Weapon1,"spawn-fireballs", "damage=5.0 range=350.0 projectiles=1 firetime=5.0 angle=0 only-yaw=1 random-spread=0");



		}
	}
}
