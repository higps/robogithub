#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2wearables>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>

float g_Amount = 1.0;

public void OnPluginStart()
{	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("post_inventory_application", Event_PlayerSpawn, EventHookMode_Post);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.6, Timer_StatCheck, client);

}

public Action Timer_StatCheck(Handle timer, int client)
{
    if (HasStats(client))
    { 
        if(HasEntProp(client, Prop_Send, "m_flRageMeter"))
        {
            SetEntPropFloat(client, Prop_Send, "m_flRageMeter", g_Amount);
        }
    }
}

bool HasStats(int client)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "start-with-charge", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}

    g_Amount = ReadFloatVar(stat_buffer, "amount", 1.0);
	return true;
    
	
}

