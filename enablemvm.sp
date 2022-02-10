#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <dhooks>

Handle g_hGameConf;
Handle g_hGameModeUsesUpgrades;

public void OnPluginStart()
{
    //GameConfig
    g_hGameConf = LoadGameConfigFile("mannvsmann");
    
    /* Dhooks */
    // CTFGameRules::GameModeUsesUpgrades
    CreateDynamicDetour(g_hGameConf, "CTFGameRules::GameModeUsesUpgrades", _, OnGameModeUsesUpgrades_Post);
    
    delete g_hGameConf;
}

public MRESReturn OnGameModeUsesUpgrades_Post(DHookReturn hReturn)
{
    hReturn.Value = true;
    return MRES_Supercede;
}

static void CreateDynamicDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
    DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
    if (detour)
    {
        if (callbackPre != INVALID_FUNCTION)
            detour.Enable(Hook_Pre, callbackPre);
        
        if (callbackPost != INVALID_FUNCTION)
            detour.Enable(Hook_Post, callbackPost);
    }
    else
    {
        LogError("Failed to create detour setup handle for %s", name);
    }
}