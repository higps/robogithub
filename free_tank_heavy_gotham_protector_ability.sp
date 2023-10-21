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
	name = "[TF2] Gotham Protector Rune Skills",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
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
