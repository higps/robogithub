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
#define ROBOT_NAME	"Kappy"
#define ROBOT_ROLE "Support"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Recon"
#define ROBOT_DESCRIPTION "Recon Remote Rocket"
#define ROBOT_TIPS "Activate Remote Control by pressing M2\nChange camera mode with +attack3 or +use"
#define ROBOT_ON_DEATH "Kappy's rockets take a while to travel\nOut-heal his damage to make him less effective"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"


// #define RED_MODEL "models/workshop/player/items/soldier/taunt_rocket_jockey/taunt_rocket_jockey.mdl"
// #define PMODEL "models/props_td/atom_bomb.mdl"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

#define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Homer Soldier",
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


public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

int g_iTeam;
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
	
	int iHealth = 2000;		
	int MaxHealth = 200;
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "self dmg push force increased", 2.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_iTeam = GetClientTeam(client);
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

#define PublicSpeaker 31095
#define ThousandYardStare 31200
#define ClassifiedCoif 30388

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{	
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		
			
		CreateRoboHat(client, PublicSpeaker, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, ThousandYardStare, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, ClassifiedCoif, 10, 6, 0.0, 1.0, -1.0);


		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 205, 6, 98, 0, 256);
		

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		
		if(IsValidEntity(Weapon1))
		{
			// TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "damage penalty", 1.38);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);				
			// TF2Attrib_SetByName(Weapon1, "Blast radius increased", 1.5);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 2.5);
			TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 0.7);
			// TF2Attrib_SetByName(Weapon1, "clip size penalty", 0.2);
			// TF2Attrib_SetByName(Weapon1, "rocket specialist", 1.0);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2CustAttr_SetString(Weapon1, "mouse-control-rocket", "aim-mode=1 turnspeed=125.0");
			// TF2CustAttr_SetString(Weapon1, "tag last enemy hit", "4.0");
			//TF2CustAttr_SetString(Weapon1, "homing_proj_mvm", "detection_radius=250.0 homing_mode=1 projectilename=tf_projectile_rocket");			
		}

		CreateRoboWeapon(client, "tf_weapon_buff_item", 129, 6, 1, 1, 0);
				int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "increase buff duration", 2.0);
			TF2CustAttr_SetString(Weapon2, "custom buff type", "rocket-aiming-control");
			TF2CustAttr_SetString(Weapon2, "rocket control buff turn rate", "0.9");
		}


		RoboCorrectClipSize(Weapon1);

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));

public OnMapStart()
{
	
	PrecacheSound(GUNFIRE);
	PrecacheSound(GUNFIRE_CRIT);
	PrecacheSound(GUNFIRE_EXPLOSION);

	// PrecacheModel(RED_MODEL);
}

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    //	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);

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
	robot.sounds.gunfire = GUNFIRE;
	robot.sounds.gunfire_crit = GUNFIRE_CRIT;
	robot.weaponsound = ROBOT_WEAPON_SOUND_ROCKETLAUNCHER;
    AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION);


}
