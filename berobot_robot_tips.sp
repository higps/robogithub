#include <sourcemod>
#include <sdktools>
#include <berobot_constants>
#include <berobot>


#pragma newdecls required
#pragma semicolon 1

char MENU_CLOSE_SOUND[] = "buttons/button14.wav";

bool g_HasSeenWaitingRoundStart;
bool g_FirstRoundStarted;
bool g_DebugRobotTips = false;

bool g_TipsShown[MAXPLAYERS + 1] = {false, ...};
bool g_TipsHiddenUntilReconnect[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =
{
    name = "berobot_robot_tips",
    author = "icebear",
    description = "Shows one-time robot tips menu after live round start",
    version = "0.1",
    url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    PrecacheSound(MENU_CLOSE_SOUND, true);

    HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    RegConsoleCmd("sm_hiderobottips", Command_HideRobotTips, "Hides robot tips menu until you reconnect");
    RegConsoleCmd("sm_hidetips", Command_HideRobotTips, "Hides robot tips menu until you reconnect");
    RegConsoleCmd("sm_robottipsdebug", Command_RobotTipsDebug, "Toggles robot tips debug messages");
}

public void OnMapStart()
{
    PrecacheSound(MENU_CLOSE_SOUND, true);

    g_HasSeenWaitingRoundStart = false;
    g_FirstRoundStarted = false;
}

public void OnClientPutInServer(int client)
{
    g_TipsShown[client] = false;
    g_TipsHiddenUntilReconnect[client] = false;
}

public void OnClientDisconnect_Post(int client)
{
    g_TipsShown[client] = false;
    g_TipsHiddenUntilReconnect[client] = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    bool inWaitingForPlayers = (GameRules_GetProp("m_bInWaitingForPlayers") != 0);

    if (g_DebugRobotTips)
    {
        PrintToChatAll("[robot_tips] round_start: waiting=%d seen_waiting=%d first_live=%d", inWaitingForPlayers, g_HasSeenWaitingRoundStart, g_FirstRoundStarted);
    }

    if (inWaitingForPlayers)
    {
        g_HasSeenWaitingRoundStart = true;
        g_FirstRoundStarted = false;
    }
    else if (g_HasSeenWaitingRoundStart && !g_FirstRoundStarted)
    {
        g_FirstRoundStarted = true;
    }

    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients)
    {
        return Plugin_Continue;
    }

    if (g_DebugRobotTips)
    {
        PrintToChatAll("[robot_tips] spawn %N: in_game=%d alive=%d any_robot=%d first_live=%d shown=%d hidden=%d", client, IsClientInGame(client), IsPlayerAlive(client), IsAnyRobot(client), g_FirstRoundStarted, g_TipsShown[client], g_TipsHiddenUntilReconnect[client]);
    }

    if (!ShouldEnableTipsForClient(client))
    {
        if (g_DebugRobotTips)
        {
            PrintToChatAll("[robot_tips] spawn %N: not enabling tips", client);
        }
        return Plugin_Continue;
    }

    g_TipsShown[client] = true;
    ShowRobotTipsMenu(client);

    if (g_DebugRobotTips)
    {
        PrintToChatAll("[robot_tips] spawn %N: tips enabled for this connection", client);
    }

    return Plugin_Continue;
}

public Action Command_HideRobotTips(int client, int args)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    g_TipsHiddenUntilReconnect[client] = true;
    g_TipsShown[client] = true;

    PrintToChat(client, "[MM] Robot tips menu hidden until reconnect.");

    return Plugin_Handled;
}

public Action Command_RobotTipsDebug(int client, int args)
{
    g_DebugRobotTips = !g_DebugRobotTips;

    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        PrintToChat(client, "[MM] Robot tips debug: %s", g_DebugRobotTips ? "ON" : "OFF");
    }
    else
    {
        PrintToServer("[MM] Robot tips debug: %s", g_DebugRobotTips ? "ON" : "OFF");
    }

    return Plugin_Handled;
}

void ShowRobotTipsMenu(int client)
{
    Panel panel = new Panel();
    panel.SetTitle("Robot tips:");

    panel.DrawItem("Focus the objective", ITEMDRAW_DISABLED); // 1
    panel.DrawItem("Dying gives the robot team Robot-₡oins", ITEMDRAW_DISABLED); // 2
    panel.DrawItem("Spend Robot-₡oins on MK II Robots", ITEMDRAW_DISABLED); // 3
    panel.DrawItem("Don't chase humans", ITEMDRAW_DISABLED); // 4
    panel.DrawItem("Tanks and ZBosses can't cap", ITEMDRAW_DISABLED); // 5
    panel.DrawItem("Retreating is not optimal, it is better to explode and get Robot-₡oins for your team", ITEMDRAW_DISABLED); // 6
    panel.DrawItem("CLOSE ROBOT TIPS", ITEMDRAW_DEFAULT);       // 7

    panel.Send(client, PanelHandler_RobotTips, MENU_TIME_FOREVER);
    delete panel;
}

public int PanelHandler_RobotTips(Menu menu, MenuAction action, int client, int selection)
{
    if (action == MenuAction_End)
    {
        delete menu;
        return 0;
    }

    if (action == MenuAction_Select)
    {
        if (selection == 7)
        {
            EmitSoundToClient(client, MENU_CLOSE_SOUND, _, _, _, _, 1.0);
        }
        else
        {
            ShowRobotTipsMenu(client);
        }
    }

    return 0;
}

bool ShouldDisplayTips(int client)
{
    return ShouldEnableTipsForClient(client);
}

bool IsClientEligibleForTips(int client)
{
    if (!g_FirstRoundStarted)
    {
        return false;
    }

    if (client <= 0 || client > MaxClients)
    {
        return false;
    }

    if (!IsClientInGame(client))
    {
        return false;
    }

    if (!IsAnyRobot(client))
    {
        return false;
    }

    if (!IsPlayerAlive(client))
    {
        return false;
    }

    return true;
}

bool ShouldEnableTipsForClient(int client)
{
    if (!IsClientEligibleForTips(client))
    {
        return false;
    }

    if (g_TipsHiddenUntilReconnect[client])
    {
        return false;
    }

    if (g_TipsShown[client])
    {
        return false;
    }

    return true;
}

