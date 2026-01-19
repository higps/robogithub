#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo =
{
    name = "Touch Friendly Dispenser",
    author = "ChatGPT",
    description = "Outputs when a human player touches a friendly dispenser",
    version = "1.1"
};

public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_Touch, OnPlayerTouch);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_Touch, OnPlayerTouch);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_Touch, OnPlayerTouch);
}

public Action OnPlayerTouch(int toucher, int touched)
{
    // Toucher must be a human player
    if (!IsClientInGame(toucher) || IsFakeClient(toucher))
    {
        return Plugin_Continue;
    }

    // Entity must be valid
    if (touched <= MaxClients || !IsValidEntity(touched))
    {
        return Plugin_Continue;
    }

    char classname[64];
    GetEntityClassname(touched, classname, sizeof(classname));

    // Check for dispenser
    if (!StrEqual(classname, "obj_dispenser"))
    {
        return Plugin_Continue;
    }

    // Team check (friendly only)
    int playerTeam = GetClientTeam(toucher);
    int dispenserTeam = GetEntProp(touched, Prop_Send, "m_iTeamNum");

    if (playerTeam != dispenserTeam)
    {
        return Plugin_Continue;
    }

    PrintToChat(toucher, "[Touch] You are touching a friendly Dispenser");

    return Plugin_Continue;
}
