#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Skymin Slash"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "Dmg Reflect Vaccinator"
#define ROBOT_TIPS "Vaccinator: 15 percent passive resist\n 10 percent resistance when deployed\nGet the Reflect Damage rune when deploying uber on teammate"
 
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"
 
public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Skymin Slash",
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
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION);
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
	PrecacheModel(GMEDIC);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
   
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
   
		
	int iHealth = 2500;
	
	
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
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
			GiveGiantMedic(client);
}

#define VintageTyrolean 101
#define HeatofWinter 30356
#define TheMedicineManpurse 30415
 
stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_medigun", 998, 6, 1, 2, 0);
		// CreateRoboWeapon(client, "tf_weapon_syringegun_medic", 36, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_bonesaw", 413, 6, 1, 2, 0);
		
		CreateRoboHat(client, VintageTyrolean, 10, 6, 15132390.0, 1.0, -1.0); 
		CreateRoboHat(client, HeatofWinter, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, TheMedicineManpurse, 10, 6, 0.0, 1.0, -1.0); 
		
		// int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		
		// if(IsValidEntity(Weapon1))
		// {
		// 	TF2Attrib_RemoveAll(Weapon1);
		// 	TF2Attrib_SetByName(Weapon1, "health drain", 0.0);
		// 	TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon1, "damage bonus", 1.15);
		// 	TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
		// }

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.0);
			TF2Attrib_SetByName(Weapon2, "ubercharge rate bonus", 1.1);
			TF2Attrib_SetByName(Weapon2, "medigun bullet resist passive", 0.15);
			TF2Attrib_SetByName(Weapon2, "medigun bullet resist deployed", 0.10);
			TF2Attrib_SetByName(Weapon2, "medigun blast resist passive", 0.15);
			TF2Attrib_SetByName(Weapon2, "medigun blast resist deployed", 0.10);
			TF2Attrib_SetByName(Weapon2, "medigun fire resist passive", 0.15);
			TF2Attrib_SetByName(Weapon2, "medigun fire resist deployed", 0.10);
			TF2Attrib_SetByName(Weapon2, "ubercharge overheal rate penalty", 1.0);
			TF2Attrib_SetByName(Weapon2, "heal rate bonus", 2.0);
		}

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.5);
		}

	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{

	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
	if (IsRobot(client, ROBOT_NAME))
	{
	// PrintToChatAll("Condition was %i", condition);
	if (condition == TFCond_Taunting)
	{
	TF2_AddCondition(client,TFCond_HalloweenQuickHeal, 2.5);
	// TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
	}

	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	int healtarget = -1;

	if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
	{
	healtarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	//PrintToChatAll("Healtarget was: %N", healtarget);
	}

	if (IsValidClient(healtarget) && IsPlayerAlive(healtarget))
	{
	if(condition == TFCond_UberBulletResist || condition == TFCond_UberBlastResist || condition == TFCond_UberFireResist){

	//TF2_AddCondition(healtarget,TFCond_CritCola, 3.5);
	TF2_AddCondition(client, TFCond_RuneWarlock, 3.5);
	TF2_AddCondition(healtarget, TFCond_RuneWarlock, 3.5);
	}
	}

	// if (condition == TFCond_Charging)
	// {	

	// 		SetEntPropFloat(healtarget, Prop_Send, "m_flMaxspeed", 750.0);
	// 		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);

	// }

	}
}


public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    if(IsValidClient(attacker) &&IsValidClient(victim))
    {
		// PrintToChatAll("Attacker was %N , victim was %N weapon was %i", attacker, victim, weapon);
		// PrintToChatAll("damagecustom was %i , damage type was %i", damagecustom, damagetype);

		if(damagecustom == TF_CUSTOM_RUNE_REFLECT)
		{
		// PrintToChatAll("damage before change %f", damage);	
		damage *= 0.4;
		// PrintToChatAll("damage after change %f", damage);	
		//critType = CritType_None;
		damageForce[0] == -10.0;
		damageForce[1] == -10.0;
		damageForce[2] == -10.0;
		return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}