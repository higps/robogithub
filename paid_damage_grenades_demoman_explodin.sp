#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <vphysics>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Expl-Odin"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Grenades"
#define ROBOT_DESCRIPTION "Grenade Launcher Launcher"
#define ROBOT_STATS "Shoots Grenade launchers"
#define ROBOT_ON_DEATH "Reflect or shortcircuit the grenade launchers"
#define ROBOT_COST 2.0
#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

#define GUNFIRE	")mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

// #define GrenadeModel "models/weapons/c_models/c_grenadelauncher/c_grenadelauncher.mdl"


public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Major Bomber lite",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoman",
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
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeSolar, PLUGIN_VERSION, restrictions);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeSolar", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
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

MakeSolar(client)
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

	int iHealth = 4000;
	int MaxHealth = 175;
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	//TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
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
	GiveGiantDemoKnight(client);
}

#define Valhalla 30586
#define BlindJustice 1019

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		// CreateRoboWeapon(client, "tf_weapon_pipebomblauncher", 207, 6, 1, 2, 241);


		CreateRoboHat(client, Valhalla, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, BlindJustice, 10, 6, 0.0, 0.8, -1.0); 
		// CreateRoboHat(client, SubZeroSuit, 10, 6, 0.0, 0.75, -1.0); 

		CreateRoboWeapon(client, "tf_weapon_grenadelauncher", 206, 6, 1, 2, 0);
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		// int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			// TF2Attrib_SetByName(Weapon1, "clip size penalty", 0.25);		
			TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 2.0);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 3.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "fuse bonus", 1.9);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.35);
			TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 1.25);
			
			// TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2CustAttr_SetString(Weapon1, "projectile-fire-self", "projectile-firedelay=0.6 projectile-speed=1500.0 projectile-model=models/weapons/c_models/c_grenadelauncher/c_grenadelauncher.mdl projectile-firesound=weapons/grenade_launcher_shoot.wav");
			// SetEntityRenderColor(Weapon1, 50,205,50,155);
			// //SetEntityRenderFx(Weapon1, RENDERFX_HOLOGRAM);
			// SetEntityRenderMode(Weapon1, RENDER_TRANSTEXTURE);
			
		}
	}
}


