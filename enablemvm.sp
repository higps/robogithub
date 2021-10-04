#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tfobjects>
#include <dhooks>

Handle g_hGameConf;
Handle g_hGameModeUsesUpgrades;

public Plugin:myinfo =
{
	name = "[TF2] Enable mvm upgrades",
	author = "HiGPS",
	description = "Enable mvm upgrades",
	version = "1.0",
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
    //GameConfig
    g_hGameConf = LoadGameConfigFile("mannvsmann");
    
    /* Dhooks */
    
    // CTFGameRules::GameModeUsesUpgrades
    
    g_hGameModeUsesUpgrades = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_Ignore);
    
    if(!DHookSetFromConf(g_hGameModeUsesUpgrades, g_hGameConf, SDKConf_Signature, "CTFGameRules::GameModeUsesUpgrades"))
    SetFailState("Failed to find CTFGameRules::GameModeUsesUpgrades signature in the gamedata!");
    
    if(!DHookEnableDetour(g_hGameModeUsesUpgrades, false, OnGameModeUsesUpgrades))
    SetFailState("Failed to enable CTFGameRules::GameModeUsesUpgrades detour!");
    
    delete g_hGameConf;
}
 
public MRESReturn OnGameModeUsesUpgrades(Handle hReturn)
{
    DHookSetReturn(hReturn, true);
    return MRES_Supercede;
}