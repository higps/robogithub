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

bool g_b_valid_taunt;
public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
        if (tauntid == -1)
		{
		g_b_valid_taunt = true;

        }else
		{
		g_b_valid_taunt = false;
		}	  
  

	}
}


public TF2_OnConditionRemoved(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
        if (g_b_valid_taunt)
        {
		TF2_AddCondition(client, TFCond_Buffed, 6.0);
		g_b_valid_taunt = false;
        }  
		
	}
}
// public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
// {
// 	if (IsValidClient(client)){

// 		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
// 		{
// 		TF2_RemoveCondition(client, TFCond_Taunting);
// 		TF2_AddCondition(client, TFCond_Buffed, 6.0);
// 		}
// 	}
// }