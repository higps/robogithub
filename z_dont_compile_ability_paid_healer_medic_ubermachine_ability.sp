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

public Plugin:myinfo =
{
	name = "[TF2] UberMachine Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Be a chad bot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{

	HookEvent("player_chargedeployed", Event_Charge_Deployed); //to trigger a unique ubercharge type
}

public Action:Event_Charge_Deployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "targetid"));
	if (IsRobot(client, ROBOT_NAME))
	{
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
