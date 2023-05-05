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

// #define JUMPSOUND	"misc/gdoomsday_cap_spin_start.wav"

#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included


float g_StandardGrav = 1.0;
float g_Gravity = 1.0;

public void OnPluginStart()
{	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("post_inventory_application", Event_PlayerSpawn, EventHookMode_Post);
}

// public void OnMapStart()
// {	
//     PRECACHESOUND(JUMPSOUND);
// }


public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.6, Timer_StatCheck, client);

}

public Action Timer_StatCheck(Handle timer, int client)
{
    if (HasStats(client))
    { 
        // PrintToChatAll("Setting grav on %N", client);
        SetEntityGravity(client, g_Gravity)
    }else
    {
        // PrintToChatAll("%N Didn't have the stat", client);
        SetEntityGravity(client, g_StandardGrav);
    }
}

bool HasStats(int client)
{
    // int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    // PrintToChatAll("Weapon was %i", Weapon1);
    // if (Weapon1 == -1)
    // {
    //     return false;
    // }

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "Player-Gravity", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}

    g_Gravity = ReadFloatVar(stat_buffer, "amount", 0.5);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
    
	
}

// public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
// {

// }


