#include <sourcemod>
#include <sdktools>
#include <string>

Plugin myinfo =
{
	name = "Teleport Plugin",
	author = "Chromatik Moniker",
	description = "Brings a Client to You, or Teleports You To A Client",
	version = "1.0",
	url = "N/A"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_bring", Command_Bring,ADMFLAG_GENERIC, "Teleports a target to your position.");
    RegAdminCmd("sm_goto", Command_GoTo,ADMFLAG_GENERIC, "Teleports you to the target player's position.");
}

public Action Command_Bring(int client, int args)
{
    // Check for proper command usage
    if (args < 1)
    {
        PrintToChat(client, "Usage: sm_bring <target player name>");
        return Plugin_Handled;
    }

    // Get the target player's name
    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));
    int targetClientIndex = FindClientByName(targetName);

    // Validate the target client index
    if (targetClientIndex == -1)
    {
        PrintToChat(client, "Player not found. Please ensure that you have the correct name.");
        return Plugin_Handled;
    }

    // Get the admin's eye position and view angles
    float clientEyePos[3];
    GetClientEyePosition(client, clientEyePos);
    
    float clientEyeAngles[3];
    GetClientEyeAngles(client, clientEyeAngles);

    // Teleport the target to the admin's eye position and match the view angle
    TeleportTargetToClient(targetClientIndex, clientEyePos, clientEyeAngles);

    // Confirmation message
    PrintToChat(client, "Teleported %s to your position and facing your direction.", targetName);

    return Plugin_Handled;
}

public Action Command_GoTo(int client, int args)
{
    // Check for proper usage
    if (args < 1)
    {
        PrintToChat(client, "Usage: sm_goto <target player name>");
        return Plugin_Handled;
    }

    // Get the target player's name
    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));
    int targetClientIndex = FindClientByName(targetName);

    // Validate the target client index
    if (targetClientIndex == -1)
    {
        PrintToChat(client, "Player not found. Please ensure that you have the correct name.");
        return Plugin_Handled;
    }

    // Get the target's position
    float targetPos[3];
    GetClientAbsOrigin(targetClientIndex, targetPos);

    // Teleport the client to the target
    TeleportClientToTarget(client, targetPos);

    // Confirmation message
    PrintToChat(client, "Teleported to %s's position.", targetName);

    return Plugin_Handled;
}

void TeleportTargetToClient(int target, const float clientPos[3], const float clientAngles[3])
{
    // Teleport the target to the client's eye position and set their view angles
    TeleportEntity(target, clientPos, clientAngles, NULL_VECTOR);
}

void TeleportClientToTarget(int client, const float targetPos[3])
{
    TeleportEntity(client, targetPos, NULL_VECTOR, NULL_VECTOR);
}

int FindClientByName(const char[] name)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i) || !IsClientInGame(i))
        {
            continue;
        }

        char clientName[64];
        GetClientName(i, clientName, sizeof(clientName));
        if (StrEqual(clientName, name, true))
        {
            return i;
        }
    }
    return -1;
}