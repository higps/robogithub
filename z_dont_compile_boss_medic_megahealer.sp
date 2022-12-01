#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Commander Health"
#define ROBOT_ROLE "ZBOSS"
#define ROBOT_DESCRIPTION "Ultra Quick-Fix"
 
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"
 
public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Quick-Shielder",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Medic";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
	
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
    // restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
    // restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
    restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    restrictions.RobotCoins.PerRobot = 3.0;

    AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION, restrictions);
}

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
	
	
   
		
	int iHealth = 4500;
	
	
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
	float scale = 1.85;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "health from healers reduced", 0.0);
	
	TF2Attrib_SetByName(client, "health drain", -4.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	UpdatePlayerHitbox(client, scale);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client , "Mega Heal on Quick-Fix\nNo self healing or regenerating health");
	


}

// public TF2_OnConditionAdded(client, TFCond:condition)
// {
//     if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
//     {
//        TF2_AddCondition(client,TFCond_HalloweenQuickHeal, 2.5);
// 	  // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
//     }
// }
 
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

#define ColdfrontCommander 30939
#define ColdfrontCarapace 30940
 
stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboHat(client, ColdfrontCommander, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, ColdfrontCarapace, 10, 6, 0.0, 1.0, -1.0);
		
		CreateRoboWeapon(client, "tf_weapon_medigun", 411, 6, 1, 2, 0);

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.01);
			TF2Attrib_SetByName(Weapon2, "heal rate bonus", 15.0);
			//TF2Attrib_SetByName(Weapon2, "ubercharge rate penalty", 0.5);
			TF2Attrib_SetByName(Weapon2, "mod weapon blocks healing", 1.0);

			//SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 1.0);
			
		}

		CreateTimer(0.5, set_uber, client);

		SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 1.0);
	}
}

public Action set_uber (Handle timer, int client)
{
	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsRobot(client, ROBOT_NAME))
	{
	SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 1.0);
	} 
}