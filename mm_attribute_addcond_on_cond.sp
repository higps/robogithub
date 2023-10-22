#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2wearables>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>


#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

int g_TFCond = 0;
float g_TFCond_duration = 0.0;
int g_TFCond_addcond = 0;
int g_TFCond_removecond = 0;

bool ActiveHasAddCondStatPlayer(int attacker)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(attacker, "OnCondAdd-addcond", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_TFCond = ReadIntVar(stat_buffer, "oncond", -1);
	g_TFCond_duration = ReadFloatVar(stat_buffer, "duration", 5.0);
    g_TFCond_addcond = ReadIntVar(stat_buffer, "addcond", -1);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
}


public void TF2_OnConditionAdded(int client, TFCond condition)
{

    if(ActiveHasAddCondStatPlayer(client))
    {
        // PrintToChatAll("Condition was %i , g_TFCOND was %i", condition, g_TFCond);
        if (condition == g_TFCond)
        {
            TF2_AddCondition(client, g_TFCond_addcond, g_TFCond_duration);
        }
    }
}

bool ActiveHasRemoveCondStatPlayer(int attacker)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(attacker, "OnCondRemoved-addcond", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_TFCond = ReadIntVar(stat_buffer, "oncond", -1);
	g_TFCond_duration = ReadFloatVar(stat_buffer, "duration", 5.0);
    g_TFCond_removecond = ReadIntVar(stat_buffer, "addcond", -1);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{

    if(ActiveHasRemoveCondStatPlayer(client))
    {
        
        if (condition == g_TFCond)
        {
            TF2_AddCondition(client, g_TFCond_addcond, g_TFCond_duration);
        }
    }
}