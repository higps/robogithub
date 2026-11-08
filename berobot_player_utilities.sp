#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "berobot_player_utilities",
    author = "Fragancia & Heavy Is GPS",
    description = "Robot vehicles, human taunts and MvM stats panel",
    version = "1.0.0",
    url = "bmod.tf"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_mount", Command_MountRobot, "get a taunt mount for your robot");
    RegConsoleCmd("sm_mt", Command_MountRobot, "get a taunt mount for your robot");
    RegConsoleCmd("sm_car", Command_MountRobot, "get a taunt mount for your robot");
    RegConsoleCmd("sm_w", Command_TauntHuman, "get a taunt mount for your robot");
    RegConsoleCmd("sm_showstats", Command_ShowStats, "Shows stats in the MvM upgrade menu");
    RegConsoleCmd("sm_showstat", Command_ShowStats, "Shows stats in the MvM upgrade menu");
    RegConsoleCmd("sm_mystat", Command_ShowStats, "Shows stats in the MvM upgrade menu");
    RegConsoleCmd("sm_mystats", Command_ShowStats, "Shows stats in the MvM upgrade menu");
}

public Action Command_ShowStats(int client, int args)
{

    SetEntProp(client, Prop_Send, "m_bInUpgradeZone", true);
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{

	char section[32];
	if (kv.GetSectionName(section, sizeof(section)))
	{

			if (!strcmp(section, "MvM_UpgradesDone"))
			{		
				CancelClientMenu(client);
				SetEntProp(client, Prop_Send, "m_bInUpgradeZone", false);					
		}
	}
	return Plugin_Continue;
}

public Action Command_TauntHuman(int client, int args)
{

    if (!IsEnabled())
    {
        return Plugin_Handled;
    }

    if (!IsAnyRobot(client))
    {
        int playerID = GetClientUserId(client);
        int taunt = 1157;

        ServerCommand("sm_tauntem #%d %i", playerID, taunt);
    }

}

public Action Command_MountRobot(int client, int args)
{

    if (!IsEnabled())
    {
        return Plugin_Handled;
    }

    if (IsAnyRobot(client))
    {
        int playerID = GetClientUserId(client);
        int taunt = 1172;

        ServerCommand("sm_tauntem #%d %i", playerID, taunt);
    }

    return Plugin_Handled;
}
