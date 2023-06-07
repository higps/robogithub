#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Theory-Y"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "Multi-Banner Vaccinator"
#define ROBOT_TIPS "Weaker passive resistances\nBullet charge = mini-crits\nExplosive charge = Conch buff\nFire charge = Battalions Buff"
#define ROBOT_ON_DEATH "Use Airblast to separate from the rest of his team"
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
	robot.deathtip = ROBOT_ON_DEATH;
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
TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
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

#define BerlinBrainBowl 30755
#define Flatliner 31121
#define Docholiday 982
 
stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_medigun", 998, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_crossbow", 305, 6, 1, 2, 0);
		

		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		float TeamPaint = 0.0;


		// Waterlogged Lab Coat
// set item tint RGB : 11049612
// set item tint RGB 2 : 8626083

		if (iTeam == TFTeam_Blue){
			TeamPaint = 11049612.0;
			
		}
		if (iTeam == TFTeam_Red){
			
			TeamPaint = 8626083.0;
		}



		CreateRoboHat(client, BerlinBrainBowl, 10, 6, TeamPaint, 1.0, -1.0); 
		CreateRoboHat(client, Flatliner, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, Docholiday, 10, 6, 8208497.0, 1.0, 2.0); 
		
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		

		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			// TF2Attrib_SetByName(Weapon1, "health drain", 0.0);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			// TF2Attrib_SetByName(Weapon1, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "hidden primary max ammo bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "dmg bonus vs buildings", 0.25);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 0.5);
			
		}

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);

			
			// TF2Attrib_SetByName(Weapon2, "lunchbox adds minicrits", 1.0);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.0);
			TF2Attrib_SetByName(Weapon2, "ubercharge rate bonus", 1.5);
			TF2Attrib_SetByName(Weapon2, "medigun bullet resist passive", 0.10);
			TF2Attrib_SetByName(Weapon2, "medigun bullet resist deployed", 0.25);
			TF2Attrib_SetByName(Weapon2, "medigun blast resist passive", 0.10);
			TF2Attrib_SetByName(Weapon2, "medigun blast resist deployed", 0.25);
			TF2Attrib_SetByName(Weapon2, "medigun fire resist passive", 0.10);
			TF2Attrib_SetByName(Weapon2, "medigun fire resist deployed", 0.25);
			TF2Attrib_SetByName(Weapon2, "ubercharge overheal rate penalty", 1.0);
			TF2Attrib_SetByName(Weapon2, "ubercharge rate penalty", 0.75);
			TF2Attrib_SetByName(Weapon2, "heal rate bonus", 2.0);
			TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.01);
			//TF2CustAttr_SetString(Weapon2,"medigun charge is group overheal", "range=500.0 heal_rate=80.0 overheal_ratio=1.05 overheal_duration_mult=0.25");

			
		}

				
		

	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
	if (IsRobot(client, ROBOT_NAME)){


	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	int healtarget = -1;

	if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
	{
	healtarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	//PrintToChatAll("Healtarget was: %N", healtarget);
	}

	if (IsValidClient(healtarget) && IsPlayerAlive(healtarget))
	{
	if(condition == TFCond_UberBulletResist){

	TF2_AddCondition(healtarget,TFCond_CritCola, 3.5);
	TF2_AddCondition(client, TFCond_CritCola, 3.5);
	}

	if(condition == TFCond_UberBlastResist){

	TF2_AddCondition(healtarget,TFCond_RegenBuffed, 3.5);
	TF2_AddCondition(client,TFCond_RegenBuffed, 3.5);
	}

	if(condition == TFCond_UberFireResist){

	TF2_AddCondition(healtarget,TFCond_DefenseBuffed, 3.5);
	TF2_AddCondition(client,TFCond_DefenseBuffed, 3.5);
	}

	}

	// if (condition == TFCond_Charging)
	// {	

	// 		SetEntPropFloat(healtarget, Prop_Send, "m_flMaxspeed", 750.0);
	// 		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);

	// }

	}
}
