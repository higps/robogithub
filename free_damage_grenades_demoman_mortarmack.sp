#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Mortar Mack"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Grenades"
#define ROBOT_DESCRIPTION "Multi-Shot"
#define ROBOT_TIPS "Fire and reload the entire clip at once!"
#define ROBOT_ON_DEATH "Attack Mortar Mack during his long reload\nAirblast grenades at close range for massive damage"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

#define GUNFIRE	")mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

#define LEFTFOOT        ")mvm/giant_demoman/giant_demoman_step_01.wav"
#define LEFTFOOT1       ")mvm/giant_demoman/giant_demoman_step_03.wav"
#define RIGHTFOOT       ")mvm/giant_demoman/giant_demoman_step_02.wav"
#define RIGHTFOOT1      ")mvm/giant_demoman/giant_demoman_step_04.wav"

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
	robot.sounds.gunfire = GUNFIRE;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.weaponsound = ROBOT_WEAPON_SOUND_GRENADELAUNCHER;
	robot.difficulty = ROBOT_DIFFICULTY_EASY;



	AddRobot(robot, MakeSolar, PLUGIN_VERSION);
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

	RoboSetHealth(client,TFClass_DemoMan, 3000, 1.5);
	
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantDemoKnight(client);
}

#define ScotchBonnet 306
#define ShrapnellShell 31372
stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_grenadelauncher", 206, 6, 1, 2, 217);

		CreateRoboHat(client, ScotchBonnet, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, ShrapnellShell, 10, 6, 7511618.0, 0.75, -1.0); 


		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		if(IsValidEntity(Weapon1))
		{

			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2Attrib_SetByName(Weapon1, "clip size penalty", 5.0);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 3.7);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg bonus vs buildings", 0.35);
			TF2Attrib_SetByName(Weapon1, "auto fires full clip all at once", 1.0);
			TF2Attrib_SetByName(Weapon1, "projectile spread angle penalty", 10.0);
			TF2Attrib_SetByName(Weapon1, "fuse bonus", 1.4);
			TF2Attrib_SetByName(Weapon1, "rocket jump damage reduction", 0.05);

		}
	}
}

