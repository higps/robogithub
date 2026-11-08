#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <tf2_isPlayerInSpawn>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "berobot_command_restrictions",
    author = "Fragancia & Heavy Is GPS",
    description = "Class-change restrictions and delayed human suicide",
    version = "1.0.0",
    url = "bmod.tf"
};

bool g_GoingToDie[MAXPLAYERS + 1];
int g_TimeBombTime[MAXPLAYERS + 1];

public void OnPluginStart()
{
    AddCommandListener(Block_Kill, "kill");
    AddCommandListener(Block_Kill, "explode");
    AddCommandListener(cmd_blocker, "changeclass");
    AddCommandListener(cmd_blocker, "joinclass");
    AddCommandListener(cmd_blocker, "join_class");
    AddCommandListener(cmd_blocker, "tf_respawn_on_loadoutchanges 1");
    HookEvent("player_death", Event_RestrictionDeath, EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
    g_GoingToDie[client] = false;
    g_TimeBombTime[client] = 0;
}

public void Event_RestrictionDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0) g_GoingToDie[client] = false;
}

public Action Block_Kill(int client, const char[] command, int args){

    if (!IsAnyRobot(client) && IsActive() && !TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    {

        if(!g_GoingToDie[client]){

        g_TimeBombTime[client] = 5;
        CreateTimer(1.0, Timer_Kill, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

        g_GoingToDie[client] = true;
        }else
        {
            g_GoingToDie[client] = false;
        }

        return Plugin_Handled; 
    }

    return Plugin_Continue;
}

public Action Timer_Kill(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;

	if (IsValidClient(client) && IsPlayerAlive(client))
    {
        g_TimeBombTime[client]--;

        if (g_TimeBombTime[client] > 0 && g_GoingToDie[client])
        {
            PrintCenterText(client, "Death in %i", g_TimeBombTime[client]);

        }else
        {
            if (g_GoingToDie[client])
            { 
                PrintCenterText(client, "You are dead");
                ForcePlayerSuicide(client);
                g_GoingToDie[client] = false;
                KillTimer(timer);
            }else{
                PrintCenterText(client, "Cancelled death");
                KillTimer(timer);
            }
        }

    }

}

public Action cmd_blocker(int client, const char[] command, int argc)
{	

    if (!IsAnyRobot(client) && IsActive() && !TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client,"You can only change class in spawn");

        return Plugin_Handled;
    }

    if (IsAnyRobot(client) && IsActive())
    {
        PrintCenterText(client,"Unable to change class. Use !bot to change robot or !stuck if you are stuck");

        SetClientRepicking(client, true);
        Menu_RobotSelection(client, false);

        return Plugin_Handled;

    }

    return Plugin_Continue;
}
