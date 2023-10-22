#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Pancop"


public Plugin:myinfo =
{
	name = "[TF2]Pancop Ability",
	author = "HiGPS | Bmod.TF",
	description = "Ability for Pancop robot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
        if (tauntid == -1)
        {
		TF2_AddCondition(client, TFCond_CritCola, 30.0);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 30.0);
		TF2_AddCondition(client, TFCond_RestrictToMelee, 30.0);
		CreateTimer(2.5, Timer_Taunt_Cancel, client);
        }	  
	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){

		TF2_RemoveCondition(client, TFCond_Taunting);

		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon); 
	}
}
