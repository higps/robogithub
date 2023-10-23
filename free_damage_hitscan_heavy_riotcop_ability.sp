#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Riotcop"

public Plugin:myinfo =
{
	name = "[TF2] Riot Cop Ability",
	author = "HiGPS | Bmod.TF",
	description = "Riot Cop",
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
        CreateTimer(3.2, Timer_Taunt_Cancel, client);
        }	  

	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){

		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
		TF2_RemoveCondition(client, TFCond_Taunting);
		TF2_AddCondition(client, TFCond_Buffed, 5.0);
		}
	}
}