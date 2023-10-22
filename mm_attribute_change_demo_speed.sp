#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>


#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included
float g_ChargingSpeed = 0.0;
TFCond g_TFCond = TFCond_Charging;
bool ActiveHasChargeSpeedStatPlayer(int client)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "ChargeSpeed", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	// g_TFCond = ReadIntVar(stat_buffer, "oncond", -1);
	g_ChargingSpeed = ReadFloatVar(stat_buffer, "speed", 350.0);  // Reading the speed value here
	return true;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
    if(ActiveHasChargeSpeedStatPlayer(client))
    {
        if (condition == g_TFCond)
        {
            SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_ChargingSpeed); // Setting the speed here
        }
    }
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
    if(ActiveHasChargeSpeedStatPlayer(client))
    {
        if (condition == g_TFCond)
        {
           TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
        }
    }
}
