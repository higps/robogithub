#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Riotcop"

public Plugin:myinfo =
{
	name = "[TF2] Carbine Cassidy Ability",
	author = "HiGPS | Bmod.TF",
	description = "Carbine Cassidy Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

Handle hApplyPunchImpulseXDetour;

public void OnPluginStart()
{
    Handle hGameData = LoadGameConfigFile("mm_no_flinch");
    if (!hGameData)
        SetFailState("Failed to load mm_no_flinch gamedata.");

	hApplyPunchImpulseXDetour = DHookCreateFromConf(hGameData, "CTFPlayer::ApplyPunchImpulseX");
	if (!hApplyPunchImpulseXDetour)
		SetFailState("Failed to setup detour for CTFPlayer::ApplyPunchImpulseX");
	delete hGameData;

	if (!DHookEnableDetour(hApplyPunchImpulseXDetour, false, Detour_OnApplyPunchImpulseX))
		SetFailState("Failed to detour CTFPlayer::ApplyPunchImpulseX.");

	// if (!DHookEnableDetour(hApplyPunchImpulseXDetour, true, Detour_OnApplyPunchImpulseX_Post))
	// 	SetFailState("Failed to detour CTFPlayer::ApplyPunchImpulseX post.");

	PrintToServer("ApplyPunchImpulseX detoured!");
}


public MRESReturn Detour_OnApplyPunchImpulseX(int client, Handle hParams)
{
	// PrintToChatAll("1 %N", client);
	if(IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Sniper && TF2_IsPlayerInCondition(client, TFCond_Zoomed) || TF2_IsPlayerInCondition(client, TFCond_CritCola))
	{
	DHookSetReturn(hParams, false); 
	return MRES_Supercede;
	}
	return MRES_Ignored;
	
}

// public TF2_OnConditionAdded(int client, TFCond condition)
// {
// 	PrintToChatAll("%N cond: %i", client, condition);
// }

// public MRESReturn Detour_OnApplyPunchImpulseX_Post(Handle hParams)
// {
//     PrintToServer("2");
//     return MRES_Ignored;
// } 