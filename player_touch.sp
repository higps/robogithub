#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Player Touch Detector",
    author = "ChatGPT",
    description = "Outputs which player a human player is touching",
    version = "1.0"
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
    // Must be valid players
    if (!IsClientInGame(toucher) || !IsClientInGame(touched))
    {
        return Plugin_Continue;
    }

    // Ignore bots touching bots
    if (IsFakeClient(toucher))
    {
        return Plugin_Continue;
    }

    char toucherName[64];
    char touchedName[64];

    GetClientName(toucher, toucherName, sizeof(toucherName));
    GetClientName(touched, touchedName, sizeof(touchedName));

    PrintToChat(toucher, "[Touch] You are touching %s", touchedName);

    return Plugin_Continue;
}
