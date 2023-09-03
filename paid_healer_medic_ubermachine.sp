#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <tf_custom_attributes>
#include <sdkhooks>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Uber Flasher"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "Rapid Uber Build and Debuff remover"
#define ROBOT_TIPS "Uber builds fasts, lasts short and removes all debuffs" 
#define ROBOT_COST 2.0
#define ROBOT_ON_DEATH "Separate this robot from his team and rush him down"
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"

#define DMG_TYPE_MELEE 134221952
#define DMG_TYPE_MELEE_CRIT 135270528
 
public Plugin:myinfo =
{
	name = "[TF2] Be UberMachine",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Be a chad bot",
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
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;

	AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION, restrictions);


	HookEvent("player_chargedeployed", Event_Charge_Deployed); //to trigger a unique ubercharge type
	// for(int client = 1 ; client <= MaxClients ; client++)
	// {
	// 	if(IsClientInGame(client))
	// 	{
	// 		SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	// 	}
	// }
	// AddNormalSoundHook(BossIcebear);
}

public Action:Event_Charge_Deployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "targetid"));
	//LogPlayerEvent(client, "triggered", "a charge was deployed");
	
	if (IsRobot(client, ROBOT_NAME))
	{
		// PrintToChatAll("%N was correct robot on uber deploy", client);
		
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 0.15);

	if(IsValidClient(target))
		TF2_RemoveCondition(target, TFCond_Jarated);
		TF2_RemoveCondition(target, TFCond_Milked);
		TF2_RemoveCondition(target, TFCond_MarkedForDeath);
		TF2_RemoveCondition(target, TFCond_Bleeding);
		TF2_RemoveCondition(target, TFCond_Gas);
	}
	

}

// public void OnClientPutInServer(int client)
// {
// 	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
// }

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantMedic_MakeGiantMedic", Native_SetGiantMedic);
//	CreateNative("BeGiantMedic_IsGiantMedic", Native_IsGiantMedic);
	return APLRes_Success;
}
 
public OnMapStart()
{
//



   
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

MakeGiantMedic(client)
{
	TF2_SetPlayerClass(client, TFClass_Medic);
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
	SetModel(client, GMEDIC);
   	
	int iHealth = 1500;
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.8);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	// TF2_AddCondition(client, TFCond_RadiusHealOnDamage);
	PrintHintText(client, "%s", ROBOT_TIPS);

	// SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
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
			GiveGiantMedic(client);
}


// #define FOPPISH 878
// #define POWDERED 30069

#define HeatOfWinter 30356
#define UberMench 30410
#define Patriot 30743

stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_bonesaw", 37, 6, 1, 0, 214);
		CreateRoboWeapon(client, "tf_weapon_medigun", 211, 6, 1, 99, 214);

		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = 5801378.0;
			
		}
		if (iTeam == TFTeam_Red){
			
			TeamPaint = 12073019.0;
		}

		CreateRoboHat(client, HeatOfWinter, 10, 6, TeamPaint, 1.0, -1.0); 
		CreateRoboHat(client, UberMench, 10, 6, TeamPaint, 1.0, 1.0);
		CreateRoboHat(client, Patriot, 10, 6, TeamPaint, 1.0, -1.0);
		
		// CreateRoboHat(client, FOPPISH, 10, 6, 3100495.0, 1.0, -1.0); 
		// CreateRoboHat(client, POWDERED, 10, 6, 6901050.0, 1.0, -1.0); 
		// CreateRoboHat(client, 30149, 10, 6, 0.0, 1.0, -1.0);

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		//SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 1.0);
		 int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon2))
		{
			// TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			// TF2Attrib_SetByName(Weapon2, "uber duration bonus", 1.5);
			TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.01);
			TF2Attrib_SetByName(Weapon2, "ubercharge rate penalty", 4.0);
			TF2Attrib_SetByName(Weapon2, "heal rate bonus", 2.0);
			
			// TF2Attrib_SetByName(Weapon2, "uber duration bonus", -0.9);
			//SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 1.0);
			
		}
		// if(IsValidEntity(Weapon3))
		// {
		// 	//TF2Attrib_RemoveAll(Weapon3);
		// 	TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon3, "damage bonus", 1.3);
		// 	TF2Attrib_SetByName(Weapon3, "fire rate bonus", 1.25);
		// 	// TF2Attrib_SetByName(Weapon3, "add uber charge on hit", 0.04);
		// 	TF2Attrib_SetByName(Weapon3, "special taunt", 0.0);
			
		// 	TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);	

			
		
		// g_healcount = 0;

		// TF2_AddCondition(client, TFCond_RestrictToMelee);
		// RequestFrame(MakeMediGun, client);

		
		
	}
}
