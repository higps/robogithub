
#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dr Zerstorer"

 
public Plugin:myinfo =
{
	name = "[TF2] Theory-Y vaccinator boss edition",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	if (IsRobot(client, ROBOT_NAME)){


	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	int healtarget = -1;

	if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
	{
	healtarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}

	if (IsValidClient(healtarget) && IsPlayerAlive(healtarget))
	{
	if(condition == TFCond_UberBulletResist){

	TF2_AddCondition(healtarget,TFCond_Kritzkrieged, 6.0);
	TF2_AddCondition(client, TFCond_MarkedForDeath, 4.5);
	}

	if(condition == TFCond_UberBlastResist){

	TF2_AddCondition(healtarget, TFCond_HalloweenQuickHeal, 6.0);
	TF2_AddCondition(healtarget, TFCond_MegaHeal, 6.0);
	TF2Attrib_AddCustomPlayerAttribute(healtarget, "healing received bonus", 2, 6.0);
	TF2_AddCondition(client,TFCond_MarkedForDeath, 4.5);
	}

	if(condition == TFCond_UberFireResist){

	TF2_AddCondition(healtarget,TFCond_Ubercharged, 6.0);
	TF2_AddCondition(client,TFCond_MarkedForDeath, 4.5);
	}

	}


	}
}
