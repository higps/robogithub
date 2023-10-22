#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
 
#define ROBOT_NAME	"Skymin Slash"
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[TF2] Skymin slash ability",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
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

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (IsRobot(client, ROBOT_NAME))
	{

		int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int healtarget = -1;

		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
		{
		healtarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		}

		if (IsValidClient(healtarget) && IsPlayerAlive(healtarget))
		{
			if(condition == TFCond_UberBulletResist || condition == TFCond_UberBlastResist || condition == TFCond_UberFireResist){


			TF2_AddCondition(client, TFCond_RuneWarlock, 4.0);
			TF2_AddCondition(healtarget, TFCond_RuneWarlock, 4.0);
			}
		}
	}
}


