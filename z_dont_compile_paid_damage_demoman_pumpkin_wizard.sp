#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Pumpkin Wizard"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Pumpkin Spell, Tide Turner"
#define ROBOT_TIPS "Use pumpkin spell with +use"
#define ROBOT_COST 0.75
#define ROBOT_ON_DEATH "Use airblast to push this robot away"
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
	name = "[TF2] Be the Giant Demoknight",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoknight from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");


	// HookEvent("player_death", Event_Death, EventHookMode_Post);

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

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;

	AddRobot(robot, MakeDemoKnight, PLUGIN_VERSION, restrictions);
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

	int iHealth = 4000;
	
	float OverHealRate = 1.5;
//	PrintToChatAll("MaxHealth %i", MaxHealth);
	
	
//	 PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	

	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.85);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	//TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.85);
	// TF2Attrib_SetByName(client, "self dmg push force increased", 8.0);
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	
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

#define Cowl 465
#define SevenSees 30480

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_wearable_demoshield", 1099, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_bottle", 880, 6, 1, 2, 0);

		CreateRoboHat(client, Cowl, 10, 6, 0.0, 1.0, 1.0); 
		CreateRoboHat(client, SevenSees, 10, 6, 0.0, 1.0, 1.0); 
		// CreateRoboHat(client, 405, 10, 6, 0.0, 1.0, 1.0); 

		
		int iEntity2 = -1;
		while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
			{				
				TF2Attrib_SetByName(iEntity2, "lose demo charge on damage when charging", 0.0);			
				TF2Attrib_SetByName(iEntity2, "dmg taken from fire reduced", 1.0);			
				TF2Attrib_SetByName(iEntity2, "dmg taken from blast reduced", 1.0);			
				break;
			}
		}
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{			
			TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.25);
			TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", 1.0);

			TF2CustAttr_SetString(client, "Spell-Caster", "Spell=3 Cooldown=3.0");
		}
	}
}
