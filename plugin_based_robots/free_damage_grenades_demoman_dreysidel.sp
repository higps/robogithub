#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks.inc>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dreysidel"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Grenades"
#define ROBOT_DESCRIPTION "Mass Scottish Resistance"
#define ROBOT_TIPS "Set up multiple traps!"
#define ROBOT_ON_DEATH "Short circuit, quickie bomb launcher, scorch shot and detonator counters this robot"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

#define LEFTFOOT        ")mvm/giant_demoman/giant_demoman_step_01.wav"
#define LEFTFOOT1       ")mvm/giant_demoman/giant_demoman_step_03.wav"
#define RIGHTFOOT       ")mvm/giant_demoman/giant_demoman_step_02.wav"
#define RIGHTFOOT1      ")mvm/giant_demoman/giant_demoman_step_04.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Toofty",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoknight from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
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
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
	AddRobot(robot, MakeToofty, PLUGIN_VERSION);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeToofty", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnMapStart()
{
	// 
	// PrecacheSound(SPAWN);
	// PrecacheSound(DEATH);
	// PrecacheSound(LOOP);

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

MakeToofty(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GDEKNIGHT);

	RoboSetHealth(client,TFClass_DemoMan, 3000, 1.5);
	
	
	
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	
	TF2Attrib_SetByName(client, "self dmg push force increased", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client, ROBOT_TIPS);
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantToofty(client);
}

#define Bandana 30397
#define SpookySleeves 925
#define AntarcticEyewear 30977


stock GiveGiantToofty(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_pipebomblauncher", 130, 6, 1, 1, 0);

		
		CreateRoboHat(client, Bandana, 10, 6, 0.0, 0.8, 1.0); //Bruiser's Bandana
		CreateRoboHat(client, AntarcticEyewear, 10, 6, 0.0, 0.8, -1.0); //Antarctic Eyewear
		CreateRoboHat(client, SpookySleeves, 10, 6, 2960676.0, 1.1, -1.0); //Spooky Sleeves

		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "Projectile speed increased", 1.25);
			TF2Attrib_SetByName(Weapon3, "Blast radius increased", 1.50);
			TF2Attrib_SetByName(Weapon3, "fire rate bonus", 0.50);
			TF2Attrib_SetByName(Weapon3, "faster reload rate", 3.75);
			TF2Attrib_SetByName(Weapon3, "sticky arm time penalty", 0.5);
			TF2Attrib_SetByName(Weapon3, "max pipebombs increased", 16.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.6);			
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2CustAttr_SetString(Weapon3, "reload full clip at once", "1.0");
		}


	}
}
