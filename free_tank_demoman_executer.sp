#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"EXEcutioner"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "SkullCutter"
#define ROBOT_TIPS "High Damage Axe\nIncreased melee range\nYou can't contest objectives"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"

#define LEFTFOOT        ")mvm/giant_demoman/giant_demoman_step_01.wav"
#define LEFTFOOT1       ")mvm/giant_demoman/giant_demoman_step_03.wav"
#define RIGHTFOOT       ")mvm/giant_demoman/giant_demoman_step_02.wav"
#define RIGHTFOOT1      ")mvm/giant_demoman/giant_demoman_step_04.wav"


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

	AddNormalSoundHook(BossMortar);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	AddRobot(robot, MakeDemoKnight, PLUGIN_VERSION, null, 1);
}

public Action:BossMortar(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			EmitSoundToAll(LEFTFOOT, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			EmitSoundToAll(LEFTFOOT1, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			EmitSoundToAll(RIGHTFOOT, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			EmitSoundToAll(RIGHTFOOT1, entity);
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
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

	int iHealth = 9000;
	
	
	int MaxHealth = 175;
	float OverHealRate = 1.5;
//	PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
//	 PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	//TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	//TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "hand scale", 1.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	// TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	// TF2Attrib_SetByName(client, "increase player capture value", -1.0);
TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	// TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	// 	TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	// TF2_RemoveCondition(client,TFCond_DefenseBuffNoCritBlock);

	PrintHintText(client , ROBOT_TIPS);

    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	// TF2_AddCondition(client, TFCond_MegaHeal);
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

#define Executioner 921
#define Tunic 30373
// #define CoolBreeze 979

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		// CreateRoboWeapon(client, "tf_wearable_demoshield", 131, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_sword", 172, 6, 1, 2, 0);

		CreateRoboHat(client, Executioner, 10, 6, 0.0, 0.75, 1.0); 
		CreateRoboHat(client, Tunic, 10, 6, 0.0, 1.0, 1.0); 
		// CreateRoboHat(client, CoolBreeze, 10, 6, 0.0, 1.0, 1.0); 

		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);				
			//TF2Attrib_SetByName(Weapon3, "charge meter on hit", 0.25);		
			TF2Attrib_SetByName(Weapon3, "charge time increased", 10.0);		
			TF2Attrib_SetByName(Weapon3, "damage bonus", 2.5);			
			// TF2Attrib_SetByName(Weapon3, "critboost on kill", 3.0);		
			// TF2Attrib_SetByName(Weapon3, "mult charge turn control", 2.0);		
			// TF2Attrib_SetByName(Weapon3, "kill refills meter", 0.25);		
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.25);	
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);	
			
			
		}
		
	}
}
