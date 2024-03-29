#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Centurion"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Pyro"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Critical Chain Third Degree"
#define ROBOT_TIPS "Rush down medics and kill who ever they are healing"
#define ROBOT_ON_DEATH "Centurion deals crits to anyone who is attached to a heal beam (dispensers included)"

#define GPYRO		"models/bots/pyro/bot_pyro.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Mighty Volcanyro!",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Might Volcanyro!",
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
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
	AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION);
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
	SMLogTag(SML_VERBOSE, "Creating Volcanyro");
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
	
	RoboSetHealth(client,TFClass_Pyro, 3250, 1.5);	
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.0);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	
	TF2Attrib_SetByName(client, "deploy time decreased", 0.05);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
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

#define Centurion 30063
#define SteelSixpack 30062

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_fireaxe", 593, 6, 1, 2, 0);

		CreateRoboHat(client, Centurion, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, SteelSixpack, 10, 6, 0.0, 1.0, -1.0); 

		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.25);
			TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.8);	
			TF2CustAttr_SetString(Weapon3,"third-degree", "critType=2 hitGroup=1");
		}	
	}
}


