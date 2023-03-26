#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf_custom_attributes>

#pragma semicolon 1
//#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"NoFungineer"
#define ROBOT_ROLE "Builder"
#define ROBOT_CLASS "Engineer"
#define ROBOT_SUBCLASS ""
#define ROBOT_DESCRIPTION "Ultra Drain Pomson, High Damage Short Circuit"
#define ROBOT_TIPS "Negate spam with Short Circuit\nPomson fully drains cloak and Uber\nBuild up to 3 normal sentries\nExtra dispenser"
#define ROBOT_COST 2.0

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Uncle Dane",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Uncle Dane Bot from MvM",
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
	// robot.subclass = ROBOT_SUBCLASS;
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
    restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    restrictions.RobotCoins.PerRobot = ROBOT_COST;

    AddRobot(robot, MakeUncleDane, PLUGIN_VERSION, restrictions);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{

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

	int iHealth = 2000;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;

	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;
	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	float scale = 1.65;
	
	TF2_SetHealth(client, iHealth);
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	TF2Attrib_SetByName(client, "metal regen", 200.0);
	// TF2Attrib_SetByName(client, "building cost reduction", 2.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 9.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.85);

	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, ROBOT_TIPS);
	//PrintCenterText(client, "Use !stuck if you get stuck in buildings");
	
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

#define THELAW 30362
#define MACHOMANN 30085
#define WILDWEST 30635

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_drg_pomson", 588, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_mechanical_arm", 528, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_robot_arm", 142, 6, 1, 2, 0);


		//CreateWeapon(client, "tf_weapon_wrench", 7, 9, 69, 2, 0);


		CreateRoboHat(client, THELAW, 10, 6, 0.0, 1.5, 2.0);
		CreateRoboHat(client, MACHOMANN, 10, 6, 0.0, 1.25, -1.0);
		CreateRoboHat(client, WILDWEST, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_SetByName(Weapon1, "damage bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 0.25);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.75);
			
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
			
			TF2Attrib_SetByName(Weapon1, "subtract victim medigun charge on hit", 100.0);
			TF2Attrib_SetByName(Weapon1, "subtract victim cloak on hit", 100.0);
			TF2Attrib_SetByName(Weapon1, "engineer building teleporting pickup", 10.0);
		}

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "damage bonus", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size penalty", 1.0);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
		}

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon3, "Construction rate increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.65);
			TF2Attrib_SetByName(Weapon3, "Repair rate increased", 3.0);
			
			TF2Attrib_SetByName(Weapon3, "mod wrench builds minisentry", 0.0);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			// TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			// TF2Attrib_SetByName(Weapon3, "engy sentry radius increased", 100.0);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 3.0);
			// TF2Attrib_SetByName(Weapon3, "engy building health bonus", 1.1);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500");
			TF2Attrib_SetByName(Weapon3, "upgrade rate decrease", 4.0);

			TF2CustAttr_SetString(Weapon3, "owned building phasing", "sentry=1 dispenser=1");
			TF2CustAttr_SetString(Weapon3, "robot engineer", "sentry_scale=1.15 dispenser_scale=1.15 infinite_ammo=1 sentries=3 dispensers=2 remove_all_sappers=1 yeet=0");
			
		}
		
	}
}
