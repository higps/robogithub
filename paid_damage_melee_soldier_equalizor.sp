#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_econ_data>
#include <tf2items>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Equalizor"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Equalizer & Escape Plan fusion, Base Jumper"
#define ROBOT_TIPS "Taunt to get airborne to use the base jumper\nSpeed & damage increase as health decreases"
#define ROBOT_ON_DEATH "Equalizor becomes buffed as health decreases"
#define ROBOT_COST 2.0

#define GSOLDIER		"models/bots/soldier/bot_soldier.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Basic Soldier",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Icebear from Frankfurt",
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
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
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

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}


MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Soldier");
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
	
	RoboSetHealth(client,TFClass_Soldier, 3500, 1.5);
	
	float OverHealRate = 1.5;



	float scale = 1.75;
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.25);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.75);
	TF2Attrib_SetByName(client, "increased air control", 2.0);
	TF2Attrib_SetByName(client, "increase buff duration", 10.0);
	TF2Attrib_SetByName(client, "self dmg push force increased", 4.0);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);

	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);


	UpdatePlayerHitbox(client,scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client , ROBOT_TIPS);

	TF2Attrib_SetByName(client, "rocket jump damage reduction", 0.0);
	TF2Attrib_SetByName(client, "no self blast dmg", 0.0);
	TF2CustAttr_SetString(client, "fall-damage", "static-damage=1 static-damage-stomp=1 fall-damage=100.0 stomp-damage=125.0");

}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

#define DoeBoy 1021
#define FlakCatcher 30853
#define VeteranAttire 30983
// 

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboWeapon(client, "tf_weapon_shovel", 775, 6, 1, 2, 0);


		CreateRoboWeaponWithAttributes(client, "tf_weapon_parachute", 1101, 6, 77, true, true, "");
		// CreateHat(client,775);
		
		CreateRoboHat(client, DoeBoy, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, FlakCatcher, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, VeteranAttire, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, 444, 10, 6, 0.0, 1.0, -1.0); //Mantreads
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);

			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.15);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.25);
			TF2Attrib_SetByName(Weapon3, "dmg bonus while half dead", 1.5);
			TF2Attrib_SetByName(Weapon3, "reduced_healing_from_medics", 1.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.8);	 
			TF2Attrib_SetByName(Weapon3, "rocket jump damage reduction", 0.0);
			TF2Attrib_SetByName(Weapon3, "fire rate bonus with reduced health", 0.2);		
			TF2Attrib_SetByName(Weapon3, "self mark for death", 0.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);		
			TF2Attrib_SetByName(Weapon3, "major increased jump height", 2.7);						
		}
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
