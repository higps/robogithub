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


int g_count;
int g_lucky_sandwich;

bool HasStats(int weapon)
{
    if (weapon == -1)
    {
        return false;
    }

    char stat_buffer[256];
    if (!TF2CustAttr_GetString(weapon, "extra-throwables", stat_buffer, sizeof(stat_buffer))) {
        return false;
    }
    g_count = ReadIntVar(stat_buffer, "throwable-count", 2);

    return true;
}


public Action Timer_StatCheck(Handle timer, int client)
{
    if(IsClientInGame(client))
    {
        int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        if (HasStats(Weapon2))
        {
            ExtraThrowables_SetOnWeapon(client, Weapon2, g_count);
        }
    }
    return Plugin_Continue;
}


//From https://github.com/Phil25/RTD/blob/master/scripting/rtd/perks/extrathrowables.sp
void ExtraThrowables_SetOnWeapon(const int client, const int iWeapon, const int iAmount)
{
    //PrintToChatAll("SETTING");
	int iOffset = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
	int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(client, iAmmoTable + iOffset, iAmount, 4, true);
}

public void OnPluginStart()
{	
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("post_inventory_application", Event_PlayerSpawn, EventHookMode_Post);
}
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.6, Timer_StatCheck, client);
    return Plugin_Continue;

}
