#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>
#include <sdktools>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Barricade"
#define ROBOT_ROLE "Engineer"
#define ROBOT_CLASS "Engineer"
#define ROBOT_SUBCLASS "SingleClass"
#define ROBOT_DESCRIPTION "Barricade Buildings, Weak LVL 3 sentry, Shotgun, Southern Hospitality"
#define ROBOT_TIPS "Build teamporters to easily teleport your team to the front lines"
#define ROBOT_ON_DEATH "Barricade's sentry has very small range and shoots slowly"

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Zonical",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Play as the Giant Zonical",
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
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
    AddRobot(robot, MakeUncleDane, PLUGIN_VERSION);
	

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{

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

MakeUncleDane(client)
{
	
	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 2)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 2);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, ChangeDane);

	int iHealth = 1250;
	float OverHealRate = 1.5;

	float scale = 1.65;
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "metal regen", 200.0);
	TF2Attrib_SetByName(client, "building cost reduction", 0.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 18.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	

	
	TF2CustAttr_SetString(client, "robot engineer", "sentry_scale=1.35 dispenser_scale=1.5 infinite_ammo=0 sentries=1 dispensers=1 remove_all_sappers=0 yeet=0");
	
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, ROBOT_TIPS);
	
	
	SetEntProp(client, Prop_Send, "m_iAmmo", 500, _, 3);

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
	GiveBigRoboDane(client);
}


#define IronLung 30698
#define Wavefinder 31148

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_shotgun_primary", 199, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_wrench", 155, 6, 1, 2, 0);

		CreateRoboHat(client, IronLung, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, Wavefinder, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);


		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "engineer building teleporting pickup", 10.0);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.85);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);	
			RoboCorrectClipSize(Weapon1);
		}
		if(IsValidEntity(Weapon3))
		{

			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon3, "Construction rate increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.65);
			TF2Attrib_SetByName(Weapon3, "Repair rate increased", 2.0);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			TF2Attrib_SetByName(Weapon3, "engy sentry radius increased", 0.3);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.6);
			
			
			TF2Attrib_SetByName(Weapon3, "upgrade rate decrease", 8.0);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500 dispenser=750");
			TF2CustAttr_SetString(Weapon3, "robot engineer", "dispenser_scale=3.0 upgrade_level_dispenser=3 sentry_scale=3.0");
			TF2CustAttr_SetString(Weapon3, "owned building phasing", "sentry=1 dispenser=1");
			
		}
		
	}
}