#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"S.A.M."
#define ROBOT_ROLE "Disruptor"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Disruptor"
#define ROBOT_DESCRIPTION "Half-Zatoichi, Splendid Screen"
#define ROBOT_TIPS "Samurai Anti Mann\nCharge refill on hit"
#define ROBOT_ON_DEATH "S.A.M. can still be one-shot by the Half Zatoichi"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Demoknight",
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
	robot.difficulty = ROBOT_DIFFICULTY_EASY;
	AddRobot(robot, MakeDemoKnight, PLUGIN_VERSION, null);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeDemoKnight", Native_SetGiantDemoKnight);
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

MakeDemoKnight(client)
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

	RoboSetHealth(client,TFClass_DemoMan, 2175, 1.5);
	float OverHealRate = 1.5;
	
	

	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 1.25);
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.15);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
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

#define Samureye 359
#define BushiDou 30348
#define SoleSaviors 30358

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_wearable_demoshield", 406, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_katana", 357, 6, 1, 2, 0);

		CreateRoboHat(client, Samureye, 10, 6, 0.0, 0.75, 1.0); 
		CreateRoboHat(client, BushiDou, 10, 6, 0.0, 1.0, 1.0); 
		CreateRoboHat(client, SoleSaviors, 10, 6, 0.0, 1.0, 1.0); 

		
		int iEntity2 = -1;
		while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
			{				
				TF2Attrib_SetByName(iEntity2, "major increased jump height", 1.65);		
				TF2Attrib_SetByName(iEntity2, "lose demo charge on damage when charging", 0.0);			
				TF2Attrib_SetByName(iEntity2, "dmg taken from fire reduced", 1.0);		
				TF2Attrib_SetByName(iEntity2, "dmg taken from blast reduced", 1.0);		
				
				break;
			}
		}
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{

			
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);					
			TF2Attrib_SetByName(Weapon3, "charge time increased", 3.0);		
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);			
			TF2Attrib_SetByName(Weapon3, "mult charge turn control", 10.0);		
			TF2Attrib_SetByName(Weapon3, "charge meter on hit", 1.0);
			TF2Attrib_SetByName(Weapon3, "restore health on kill", 10.0);	
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);	
	
		}
	}
}
