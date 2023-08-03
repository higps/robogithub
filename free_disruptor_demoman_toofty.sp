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
#define ROBOT_NAME	"Toofty"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Disruptor"
#define ROBOT_DESCRIPTION "Iron Bomber, Sticky jumper"
#define ROBOT_TIPS "Land on enemies to deal stomp damage"
#define ROBOT_ON_DEATH "Blast jumpers can be countered heavily by the Reserve Shooter"

#define GDEKNIGHT		"models/bots/demo/bot_demo.mdl"
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
	AddRobot(robot, MakeToofty, PLUGIN_VERSION, null, 2);

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

	int iHealth = 1750;
	
	
	int MaxHealth = 175;
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.85);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.3);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "increased jump height", 0.3);

	TF2CustAttr_SetString(client, "fall-damage", "static-damage=1 static-damage-stomp=1 fall-damage=50.0 stomp-damage=500");
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

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
	GiveGiantToofty(client);
}

#define BEARDEDBOMBARDIER 830
#define WELLROUNDEDRIFLEMAN 30067


stock GiveGiantToofty(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		// TF2_RemoveWeaponSlot(client, 3);
		// TF2_RemoveWeaponSlot(client, 4);
		// TF2_RemoveWeaponSlot(client, 5);
		
		CreateRoboWeapon(client, "tf_weapon_grenadelauncher", 1151, 8, 1, 0, 213);
		CreateRoboWeapon(client, "tf_weapon_pipebomblauncher", 265, 6, 1, 1, 0);
		
		CreateRoboHat(client, BEARDEDBOMBARDIER, 10, 6, 0.0, 1.0, -1.0); //Bearded Bombardier
		CreateRoboHat(client, WELLROUNDEDRIFLEMAN, 10, 6, 0.0, 1.0, -1.0); //well rounded rifle man
		CreateRoboHat(client, 1101, 10, 6, 0.0, 5.0, -1.0); //parachute
		CreateRoboWeaponWithAttributes(client, "tf_weapon_parachute", 1101, 6, 77, true, true, "");
		
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{

			// TF2Attrib_SetByName(Weapon1, "damage penalty", 0.85);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.35);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.75);			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.15);	
		
			TF2Attrib_SetByName(Weapon1, "is_festivized", 1.0);
						
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			// TF2CustAttr_SetString(client, "projectile-size", "size=1.75 update-hitbox=1");
		}
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "fire rate bonus", 0.1);
			TF2Attrib_SetByName(Weapon3, "max pipebombs decreased", 0.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2CustAttr_SetString(Weapon3, "reload full clip at once", "1.0");
		}


	}
}