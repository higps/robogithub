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
#include <sdkhooks>

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
            TF2_AddCondition(client, TFCond_RestrictToMelee);
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
           TF2_RemoveCondition(client, TFCond_RestrictToMelee);
        }
    }
}
bool b_Hooked[MAXPLAYERS + 1] = {false,...};


public void OnPluginStart()
{
        for(int i = 0; i <= MAXPLAYERS; i++)
    {
        if(IsValidClient(i))
        {
            SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
            b_Hooked[i] = true;
        }
    }

    Handle hGameData = LoadGameConfigFile("mm_no_flinch");
    if (!hGameData)
        SetFailState("Failed to load mm_no_flinch gamedata.");

	hApplyPunchImpulseXDetour = DHookCreateFromConf(hGameData, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
	if (!hApplyPunchImpulseXDetour)
		SetFailState("Failed to setup detour for CTFPlayer::TeamFortress_CalculateMaxSpeed ");
	delete hGameData;

	if (!DHookEnableDetour(hApplyPunchImpulseXDetour, false, Detour_TeamFortress_CalculateMaxSpeed))
		SetFailState("Failed to detour CTFPlayer::TeamFortress_CalculateMaxSpeed .");

	// if (!DHookEnableDetour(hApplyPunchImpulseXDetour, true, Detour_TeamFortress_CalculateMaxSpeed_Post))
	// 	SetFailState("Failed to detour CTFPlayer::TeamFortress_CalculateMaxSpeed  post.");

	PrintToServer("TeamFortress_CalculateMaxSpeed  detoured!");

}


Handle hApplyPunchImpulseXDetour;



public MRESReturn Detour_TeamFortress_CalculateMaxSpeed(int client, Handle hParams)
{
	// PrintToChatAll("1 %N", client);
	if(IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Sniper && TF2_IsPlayerInCondition(client, TFCond_Zoomed) || TF2_IsPlayerInCondition(client, TFCond_CritCola))
	{
	DHookSetReturn(hParams, false); 
	return MRES_Supercede;
	}
	return MRES_Ignored;
	
}

public void OnClientPutInServer(int client)
{


	// Hook weapon switching for this client here:
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	b_Hooked[client] = true;
}

public void OnClientDisconnect(int client)
{


	// Unhook our weapon switching:
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnWeaponSwitch(int client, int weapon)
{
	if (ActiveHasChargeSpeedStatPlayer(client) && TF2_IsPlayerInCondition(client, g_TFCond))
	{
        PrintToChatAll("Setting charge speed to %f", g_ChargingSpeed);
        TF2_RemoveCondition(client, g_TFCond);
        SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_ChargingSpeed); 
	}
}





public void OnPluginStart()
{

}

