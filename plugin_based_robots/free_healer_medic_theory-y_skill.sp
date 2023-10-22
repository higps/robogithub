#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Theory-Y"

 
public Plugin:myinfo =
{
	name = "[TF2] Theory-Y vaccinator",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
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

	TF2_AddCondition(healtarget,TFCond_CritCola, 4.0);
	TF2_AddCondition(client, TFCond_CritCola, 4.0);
	}

	if(condition == TFCond_UberBlastResist){

	TF2_AddCondition(healtarget,TFCond_RegenBuffed, 4.0);
	TF2_AddCondition(client,TFCond_RegenBuffed, 4.0);
	}

	if(condition == TFCond_UberFireResist){

	TF2_AddCondition(healtarget,TFCond_DefenseBuffed, 4.0);
	TF2_AddCondition(client,TFCond_DefenseBuffed, 4.0);
	}

	}


	}
}
