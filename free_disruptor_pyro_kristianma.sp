#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Kristianma"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_CLASS "Pyro"
#define ROBOT_SUBCLASS "Disruptor"
#define ROBOT_DESCRIPTION "Detonator, Axtinguisher"
#define ROBOT_ON_DEATH "Blast jumpers can be countered heavily by the Reserve Shooter"

#define GPYRO		"models/bots/pyro/bot_pyro.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

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
	robot.deathtip = ROBOT_ON_DEATH;
	robot.footstep = ROBOT_FOOTSTEP_GIANTCOMMON;
	robot.difficulty = ROBOT_DIFFICULTY_HARD;

	AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION, null);
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
	SMLogTag(SML_VERBOSE, "Createing Kristianma");
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
	
	int iHealth = 1750;
	int MaxHealth = 175;
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	float scale = 1.65;

	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.5);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 1.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "deploy time decreased", 0.75);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
	TF2CustAttr_SetString(client, "fall-damage", "static-damage=1 static-damage-stomp=1 fall-damage=100.0 stomp-damage=125.0");
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

	
	
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	
	PrintHintText(client , "Jump in with detonator and whack enemis with axtinguisher");
	
	
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


#define HEADWARMER 644
#define CUTESUIT 30367
#define FLASHDANCEFOOTIES 30551

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_flaregun", 351, 6, 1, 2, 390);
		CreateRoboWeapon(client, "tf_weapon_fireaxe", 38, 6, 1, 2, 0);

		
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		
		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = 12073019.0;
		}
		if (iTeam == TFTeam_Red){
			TeamPaint = 5801378.0;
		}

		CreateRoboHat(client, HEADWARMER, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, CUTESUIT, 10, 6, TeamPaint, 0.75, -1.0);
		CreateRoboHat(client, FLASHDANCEFOOTIES, 10, 6, 0.0, 0.75, -1.0);

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		
		if(IsValidEntity(Weapon2))
		{

			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 0.5);
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 2.5);
			TF2Attrib_SetByName(Weapon2, "self dmg push force increased", 12.0);
			TF2Attrib_SetByName(Weapon2, "Blast radius increased", 1.75);
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.35);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);	
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs buildings", 0.5);	

		}

		if(IsValidEntity(Weapon3))
		{

			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);		
			TF2Attrib_SetByName(Weapon3, "is australium item", 1.0);
			TF2Attrib_SetByName(Weapon3, "item style override", 1.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.4);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.4);
			TF2Attrib_SetByName(Weapon3, "fire rate penalty", 1.2);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);	

		}
	}
}
