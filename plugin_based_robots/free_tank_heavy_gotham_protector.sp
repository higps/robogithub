#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Gotham Protector"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Tank"
#define ROBOT_DESCRIPTION "Gain buffs on class punch. Immune to tickle and Uberchain"
#define ROBOT_TIPS "Immune to tickles\nBecomes ubered briefly when hit by an ubercharged medic's ubersaw\nYou can't contest objectives"
#define ROBOT_ON_DEATH "GP cannot be tickled or Uberchained\nTanks can be stunned by shields and stomps\nTanks take double melee damage"
 
#define GDEFLECTORH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"


#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

enum eRuneTypes
{
    Rune_Invalid = -1,
    Rune_Strength,
    Rune_Haste,
    Rune_Regen,
    Rune_Resist,
    Rune_Vampire,
    Rune_Reflect,
    Rune_Precision,
    Rune_Agility,
    Rune_Plague,
    Rune_King,
    Rune_Knockout,
    Rune_Supernova,

    Rune_LENGTH
}

#define RuneTypes                     eRuneTypes
#define RuneTypes_t                 eRuneTypes     // Cuz

#define BLINK_TIME                     10.0

#define RUNE_REPOSITION_TIME         60.0
// In freeforall mode, killed players drop enemy team colored powerups. These powerups reposition quicker
#define RUNE_REPOSITION_TIME_ANY    30.0

#define TF_RUNE_TEMP_RESPAWN_DELAY     90.0
#define TF_RUNE_TEMP_UBER_RESPAWN_DELAY     180.0

#define TF_RUNE_STRENGTH        "models/pickups/pickup_powerup_strength.mdl"
#define TF_RUNE_RESIST            "models/pickups/pickup_powerup_defense.mdl"
#define TF_RUNE_REGEN            "models/pickups/pickup_powerup_regen.mdl"
#define TF_RUNE_HASTE            "models/pickups/pickup_powerup_haste.mdl"
#define TF_RUNE_VAMPIRE            "models/pickups/pickup_powerup_vampire.mdl"
#define TF_RUNE_REFLECT         "models/pickups/pickup_powerup_reflect.mdl"
#define TF_RUNE_PRECISION         "models/pickups/pickup_powerup_precision.mdl"
#define TF_RUNE_AGILITY         "models/pickups/pickup_powerup_agility.mdl"
#define TF_RUNE_KNOCKOUT         "models/pickups/pickup_powerup_knockout.mdl"
#define TF_RUNE_KING            "models/pickups/pickup_powerup_king.mdl"
#define TF_RUNE_PLAGUE            "models/pickups/pickup_powerup_plague.mdl"
#define TF_RUNE_SUPERNOVA        "models/pickups/pickup_powerup_supernova.mdl"

#define TF_RUNE_TEMP_CRIT        "models/pickups/pickup_powerup_crit.mdl"
#define TF_RUNE_TEMP_UBER        "models/pickups/pickup_powerup_uber.mdl"

public Plugin:myinfo =
{
	name = "[TF2] Be the Gotham Protector",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
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

	AddRobot(robot, MakePanCop, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakePanCop", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
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

MakePanCop(client)
{	
	TF2_SetPlayerClass(client, TFClass_Heavy);
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
	SetModel(client, GDEFLECTORH);
	RoboSetHealth(client,TFClass_Heavy, 6000, 1.5);


	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	



	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "head scale", 0.95);
	TF2Attrib_SetByName(client, "damage force reduction", 0.0);

	 

	UpdatePlayerHitbox(client, 1.75);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);




	PrintHintText(client, ROBOT_TIPS);
	
	//Tank stats
    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);


}
 
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGDeflectorH(client);
}

#define BattersBracers 30722
#define CapedCrusader 30727
#define TeufortKnight 30733
 
stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_fists", 5, 6, 2, 2, 0);

		CreateRoboHat(client, BattersBracers, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, CapedCrusader, 10, 6, 0.0, 1.0, 1.0);
		CreateRoboHat(client, TeufortKnight, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.15);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 1.2);
			TF2Attrib_SetByName(Weapon1, "melee range multiplier", 1.35);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon1, "shake on hit", "amplitude=10.0 frequency=2.0 duration=0.5");
			TF2Attrib_SetByName(Weapon1, "move speed penalty", 0.9);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.8);
		}
		CreateRoboHat(client, 111, 10, 6, 0.0, 1.0, 1.0); 
		TF2Attrib_SetByName(client, "attach particle effect", 35.0);
	}
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	// if (!g_Enable)
	//     return Plugin_Continue;
	if(!IsValidClient(victim))
		return Plugin_Continue;    
	if(!IsValidClient(attacker))
		return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{
		float duration = 4.0;
		TF2_AddCondition(attacker, TFCond_RuneHaste, duration);

		switch (TF2_GetPlayerClass(victim))
		{
			
			case TFClass_Soldier, TFClass_DemoMan:{
				//TF2_AddCondition(attacker, TFCond_SmallBlastResist, duration);
				TF2_AddCondition(attacker, TFCond_UberBlastResist, duration, attacker);
				TF2Attrib_AddCustomPlayerAttribute(attacker, "dmg taken from blast reduced", 0.35, duration);
			}
			case TFClass_Pyro:{
			//TF2_AddCondition(attacker, TFCond_SmallFireResist, duration);
			TF2_AddCondition(attacker, TFCond_UberFireResist, duration, attacker);
			TF2Attrib_AddCustomPlayerAttribute(attacker, "dmg taken from fire reduced", 0.35, duration);
			
			}
			case TFClass_Heavy, TFClass_Engineer, TFClass_Sniper, TFClass_Scout:{ 
				
				TF2_AddCondition(attacker, TFCond_UberBulletResist, duration);
				TF2Attrib_AddCustomPlayerAttribute(attacker, "dmg taken from bullets reduced", 0.35, duration);
				//TF2_AddCondition(attacker, TFCond_BulletImmune, duration);
				
			}
			case TFClass_Medic:{
				TF2_AddCondition(attacker, TFCond_RadiusHealOnDamage, duration);
				
			}
			case TFClass_Spy:{
				TF2_AddCondition(attacker, TFCond_Stealthed, duration);
			}
		
			
		}

		// KillRune();
	}

	//Function to add vs uberchaining
	if (IsRobot(victim, ROBOT_NAME))
	{


		switch (TF2_GetPlayerClass(attacker))
		{
			
			case TFClass_Medic:{
				if (TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged))
				{
					TF2_AddCondition(victim, TFCond_UberchargedCanteen, 4.0);
				}

			}
		}
	}

	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	


	if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
	{	
		int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
		if (tauntid == 463 || tauntid == -1)
		{
		TF2_RemoveCondition(client, condition);
		}
	}

}


public void TF2_OnConditionRemoved(int client, TFCond condition)
{

	if (IsRobot(client, ROBOT_NAME)){

	
    if(condition == TFCond_RuneHaste){

		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	}
   }

}
