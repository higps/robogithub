#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <dhooks>
#include <tf_ontakedamage>
#include <morecolors>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "berobot_health",
    author = "Fragancia & Heavy Is GPS",
    description = "Robot health preservation, healing feedback and resupply restrictions",
    version = "1.0.0",
    url = "bmod.tf"
};

int g_PlayerHealth[MAXPLAYERS + 1] = {-1, ...};
int g_PlayerMaxHealth[MAXPLAYERS + 1] = {-1, ...};
Handle g_hRegen;
Handle g_hGameConf;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("AddPlayerHealth", Native_AddPlayerHealth);
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_HealthDeath, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_HealthRoundStart, EventHookMode_Post);

    g_hGameConf = LoadGameConfigFile("sm-tf2.games");
    if(g_hGameConf == null)
        SetFailState("Failed to setup gamedata!");

    g_hRegen = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
    if(g_hRegen == null)
        SetFailState("Failed to setup OnRegenerate hook!");

    if(!DHookSetFromConf(g_hRegen, g_hGameConf, SDKConf_Signature, "Regenerate"))
        SetFailState("Failed to config Regenerate signature!");

    DHookAddParam(g_hRegen, HookParamType_Bool);

    if(!DHookEnableDetour(g_hRegen, false, OnRegenerate))
        SetFailState("Failed to detour OnRegenerate!");

    delete g_hGameConf;
}

public void OnMapStart()
{
    ResetHealthHistory();
}

void ResetHealthHistory()
{
    for (int client = 0; client <= MaxClients; client++)
    {
        g_PlayerHealth[client] = -1;
        g_PlayerMaxHealth[client] = -1;
    }
}

public void Event_HealthRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (IsEnabled() && !IsAprilEnabled()) ResetHealthHistory();
}

public void Event_HealthDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client) && IsAnyRobot(client))
    {
        g_PlayerHealth[client] = -1;
        g_PlayerMaxHealth[client] = -1;
    }
}

bool IsDebugEnabled()
{
    ConVar debug = FindConVar("sm_mm_debug");
    return debug != null && debug.BoolValue;
}

bool IsAprilEnabled()
{
    ConVar april = FindConVar("sm_mm_april_enable");
    return april != null && april.BoolValue;
}

bool isMiniBoss(int client)
{
    return IsValidClient(client) && GetEntProp(client, Prop_Send, "m_bIsMiniBoss") != 0;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsAnyRobot(client)){ 

        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}!bot{teamcolor} or {orange}change class{teamcolor} in spawn to change robot!");
        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}!car{teamcolor} get a car to move faster!");
        if(IsDebugEnabled())PrintToChatAll("%N spawned, with %i health from previous life", client, g_PlayerHealth[client]);

        if (g_PlayerHealth[client] > 0){

           CreateTimer(1.0, Timer_SetHealth, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        } 

    }

}

public void MM_robotChangedInSpawn(int client)
{

    CreateTimer(1.0, Timer_SetHealth_Changed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{

    g_PlayerHealth[client] = -1;
    g_PlayerMaxHealth[client] = -1;
}

public Action GetMaxHealth(int client)
{
    return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

public Action Timer_SetHealth(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;

    SetRoboSpawnHealth(client, false);
}

public Action Timer_SetHealth_Changed(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;

    SetRoboSpawnHealth(client, true);
}

void SetRoboSpawnHealth(int client, bool changed_in_spawn)
{

        int currenthealth = GetClientHealth(client);
        if (IsDebugEnabled())PrintToChatAll("Current health %i", currenthealth);
        if (IsDebugEnabled())PrintToChatAll("g_Player health for %N was %i", client, g_PlayerHealth[client]);
        if (g_PlayerHealth[client] < currenthealth && g_PlayerHealth[client] != -1) 
        { 
            if (!IsBoss(client) || !changed_in_spawn) 
            {

                float ratio = float(g_PlayerHealth[client]) / float(g_PlayerMaxHealth[client]);
                TF2_SetHealth(client, RoundToNearest(ratio * float(GetMaxHealth(client))));
                PrintCenterText(client, "ERROR!:\nRobot Damaged!\nRecycled %.0f%%% health!\nDestruction required!", ratio*100.0);
            }

        }
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{

    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;

    if (IsAnyRobot(victim))
    {      
        if(attacker != victim)RequestFrame(Set_g_PlayerHealth, victim);        

    }

    return Plugin_Continue;
}

public any Native_AddPlayerHealth(Handle plugin, int numParam)
{

    int iClient = GetNativeCell(1);
    int iAdd = GetNativeCell(2);
    int iOverheal = GetNativeCell(3);
    bool bStaticMax = GetNativeCell(4);
    bool bShowHealthGain = GetNativeCell(5);

    int iHealth = GetClientHealth(iClient);

    int iNewHealth = iHealth + iAdd;
    int iMax = bStaticMax ? iOverheal : GetEntProp(iClient, Prop_Data, "m_iMaxHealth") + iOverheal;

    if (iNewHealth <= iMax)
    {

        SetEntityHealth(iClient, iNewHealth);
    }else
    {
        SetEntityHealth(iClient, iMax);
    }
    if (bShowHealthGain)
    {
        ShowHealthGain(iClient, iAdd, iClient);
    }
}

void ShowHealthGain(int iPatient, int iHealth, int iHealer = -1)
{
    int iUserId = GetClientUserId(iPatient);
    Handle hEvent = CreateEvent("player_healed", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "patient", iUserId);
    SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
    SetEventInt(hEvent, "amount", iHealth);
    FireEvent(hEvent);

    hEvent = CreateEvent("player_healonhit", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "amount", iHealth);
    SetEventInt(hEvent, "entindex", iPatient);
    FireEvent(hEvent);
}

void Set_g_PlayerHealth(int victim)
{
    int health = GetClientHealth(victim);
    if(IsDebugEnabled())PrintToChatAll("Health was %i for %N", health, victim);

    g_PlayerHealth[victim] = health;
    g_PlayerMaxHealth[victim] = GetMaxHealth(victim);

    if (IsPlayerAlive(victim)){
        if(IsDebugEnabled())PrintToChatAll("Setting health for %N to %i", victim, g_PlayerHealth[victim]);
    }else{
        g_PlayerHealth[victim] = -1;
        g_PlayerMaxHealth[victim] = -1;
        if(IsDebugEnabled())PrintToChatAll("%N is dead, setting g_PlayerHealth to -1", victim);

    }
}

stock void TF2_SetHealth(int client, int NewHealth)
{
    SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
    SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
    SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

public MRESReturn OnRegenerate(int pThis, Handle hReturn, Handle hParams)
{

    if(isMiniBoss(pThis) && IsPlayerAlive(pThis)){

    PrintCenterText(pThis,"Error: Unable to use human lockers");

    return MRES_Supercede; 
    }

    return MRES_Ignored;
}
