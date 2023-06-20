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
#include <tf2utils>

#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

// bool g_cv_bDebugMode;
// float g_HitTime[MAXPLAYERS + 1] = {0.0, ...};


public void OnPluginStart()
{	

	HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);
}


float g_respawn_time;
// int g_weapon_id = -1
public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

	RequestFrame(CheckStat, client);


	return Plugin_Continue;
}


void CheckStat(int client)
{
	if(HasStat(client))
	{
		TF2Util_GetPlayerRespawnTimeOverride(client);		
		TF2Util_SetPlayerRespawnTimeOverride(client, g_respawn_time);
	}else{
		TF2Util_SetPlayerRespawnTimeOverride(client, -1.0);
	}
}

bool HasStat(int client)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "faster-respawn", stat_buffer, sizeof(stat_buffer))) {
		return false;

	}
	g_respawn_time = ReadFloatVar(stat_buffer, "respawn", 5.0);

	return true;
	
}
