#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <tf2_isPlayerInSpawn>
#include <tf2attributes>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define SOUND "/items/powerup_pickup_king.wav"
bool b_g_valid_champions[MAXPLAYERS + 1] = { false, ... };
bool g_b_found_valid_champion = false;
int g_i_current_champion = -1;
Handle g_h_checkChampionTimer = INVALID_HANDLE;
int g_MissingHumans = 0;
int g_CurrentRobots = 0;
float g_dmg_bonus = 1.0;
public void OnMapStart()
{
    PrecacheSound(SOUND);
    g_MissingHumans = 0;
    g_b_found_valid_champion = false;
    g_i_current_champion = -1;
    if (g_h_checkChampionTimer != INVALID_HANDLE)
    {
        CloseHandle(g_h_checkChampionTimer);
        g_h_checkChampionTimer = INVALID_HANDLE;
    }
}


public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_Death, EventHookMode_Post);
}
public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if(victim == g_i_current_champion)
    {
        MC_PrintToChatAll("{gold}%N{green} the champion died", victim);
        g_i_current_champion = -1
        CheckChampion();
    }
    return Plugin_Continue;
}
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if(g_i_current_champion == -1)CheckChampion();
    return Plugin_Continue;
}

void CheckChampion()
{
    g_CurrentRobots = GetCurrentRobotCount();
    int CurrentHumans = GetCurrentHumanCount();

    ConVar drobotcount = FindConVar("sm_berobot_dynamicRobotCount_humansPerRobot");
    float ratio = drobotcount.FloatValue;

    int TargetHumans = RoundToFloor(float(g_CurrentRobots) * ratio) - g_CurrentRobots;
    g_MissingHumans = TargetHumans - CurrentHumans;

    // Super straight forward math compulation. The 0.833 is to compensate for the 16.7% faster firing speed the king rune gives
    g_dmg_bonus = 1.0 + (0.20 * float(g_MissingHumans)) * 0.833;

    PrintToChatAll("Current Robots: %i", g_CurrentRobots);
    PrintToChatAll("Current Humans: %i", CurrentHumans);
    PrintToChatAll("Target Humans: %i", TargetHumans);
    PrintToChatAll("Missing Humans: %i", g_MissingHumans);

    if (g_MissingHumans > 0)
    {
        MC_PrintToChatAll("{green}Finding champion with power of %i players", g_MissingHumans);

        g_b_found_valid_champion = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsAnyRobot(i) && TF2Spawn_IsClientInSpawn(i))
            {
                b_g_valid_champions[i] = true;
                g_b_found_valid_champion = true;
            }
            else
            {
                b_g_valid_champions[i] = false;
            }
        }

        if (g_b_found_valid_champion)
        {
            MC_PrintToChatAll("{green}Next player to leave spawn becomes the {gold}CHAMPION");
            if (g_h_checkChampionTimer == INVALID_HANDLE)
            {
                g_h_checkChampionTimer = CreateTimer(0.3, Timer_CheckChampionLeaveSpawn, _, TIMER_REPEAT);
            }
        }
        else
        {
            // PrintToChatAll("Found no valid champion");
        }
    }
    else
    {
        // PrintToChatAll("Removing champion");
        g_i_current_champion = -1;
        if (g_h_checkChampionTimer != INVALID_HANDLE)
        {
            CloseHandle(g_h_checkChampionTimer);
            g_h_checkChampionTimer = INVALID_HANDLE;
        }
        for (int i = 1; i <= MaxClients; i++)
        {
            b_g_valid_champions[i] = false;
        }
    }
}

public Action Timer_CheckChampionLeaveSpawn(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (b_g_valid_champions[i] && IsClientInGame(i) && !TF2Spawn_IsClientInSpawn(i))
        {
            g_i_current_champion = i;
            MC_PrintToChatAll("{orange}%N {green}has left spawn and is now the {gold}CHAMPION!", i);
            CreateChampion(i);
            // Stop checking further
            g_h_checkChampionTimer = INVALID_HANDLE;
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}
// float g_hp_base = 165.0;
// float g_jump_height_base = 1.2;
// float g_moves_speed_base = 1.1;
// float g_scale = 1.25;

void CreateChampion(int client)
{
    if (IsValidClient(client) && !IsAnyRobot(client))
    {
                
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.25);

        int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
        int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
    
        // Determine class and call appropriate class handler
        switch (TF2_GetPlayerClass(client))
        {
            case TFClass_Scout:
                MakeScoutChampion(client);

            case TFClass_Soldier:
                MakeSoldierChampion(client);

            case TFClass_Pyro:
                MakePyroChampion(client);

            case TFClass_DemoMan:
                MakeDemomanChampion(client, Weapon1, Weapon2);

            case TFClass_Heavy:
                MakeHeavyChampion(client);

            case TFClass_Engineer:
                MakeEngineerChampion(client, Weapon3);

            case TFClass_Medic:
                MakeMedicChampion(client, Weapon2);

            case TFClass_Sniper:
                MakeSniperChampion(client);

            case TFClass_Spy:
                MakeSpyChampion(client);

        }

        CreateClassChampion(client, Weapon1, Weapon2, Weapon3);
    }
}

void MakeScoutChampion(int client)
{
    // TODO: Add Scout-specific buffs or logic here
    
}

void MakeSoldierChampion(int client)
{
    // TODO: Add Soldier-specific buffs or logic here
    
}

void MakePyroChampion(int client)
{
    // TODO: Add Pyro-specific buffs or logic here
    
}
bool IsDemoKnight(int weapon1, int weapon2)
{
    //Demoknights don't have weapons in slot1 or 2
    // PrintToChatAll("Weapon1 was %i", weapon1);
    // PrintToChatAll("Weapon2 was %i", weapon2);
    if (weapon2 == -1)
    {
        if (weapon1 == -1 || GetEntProp(weapon1, Prop_Send, "m_iItemDefinitionIndex") == 1101) //This is a base jumper
        return true;
    }
    return false;
}
void MakeDemomanChampion(int client, int Weapon1, int Weapon2)
{
    // TODO: Add Demoman-specific buffs or logic here
    if (IsDemoKnight(Weapon1, Weapon2))
    {
        
    }
}

void MakeHeavyChampion(int client)
{
    // TODO: Add Heavy-specific buffs or logic here
    
}

void MakeEngineerChampion(int client, int Weapon3)
{
    // TODO: Add Engineer-specific buffs or logic here
    if(Weapon3 != -1)
    {
        
        TF2Attrib_SetByName(Weapon3, "upgrade rate decrease", g_dmg_bonus); 
    }
}

void MakeMedicChampion(int client, int Weapon2)
{
    // TODO: Add Medic-specific buffs or logic here
    if (Weapon2 != -1)
    {
        TF2Attrib_SetByName(Weapon2, "heal rate bonus", g_dmg_bonus); 
    }
}

void MakeSniperChampion(int client)
{
    // TODO: Add Sniper-specific buffs or logic here
    
}

void MakeSpyChampion(int client)
{
    // TODO: Add Spy-specific buffs or logic here
    
}


void CreateClassChampion(int client, int Weapon1, int Weapon2, int Weapon3)
{
    // Shared champion logic goes here
    // Example: give increased speed, HP, or effects common to all champions
    // TF2Attrib_SetByName(client, "increased jump height", 1.25);
    //3160 
    //3025 


    
    if (Weapon1 != -1)
    {
        TF2Attrib_SetByName(Weapon1, "dmg bonus vs buildings", g_dmg_bonus); 
    }
    if (Weapon2 != -1)
    {
        TF2Attrib_SetByName(Weapon2, "dmg bonus vs buildings", g_dmg_bonus); 
    }
    if (Weapon3 != -1)
    {
        TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", g_dmg_bonus); 
    }
    // int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
    // TF2Attrib_SetByName(Weapon1, "attach particle effect", 3160.0);
    // TF2Attrib_SetByName(Weapon1, "attach particle effect static", 3160.0);
    // TF2Attrib_SetByName(client, "move speed bonus", 1.0 + (0.05 * float(g_MissingHumans)) + (0.02 * float(g_CurrentRobots)));
    TF2Attrib_SetByName(client, "max health additive bonus", (30.0 * (float(g_MissingHumans))-100.0) + (20.0 * float(g_CurrentRobots))); 
    
    TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
    TF2_AddCondition(client, TFCond_KingAura);
    TF2_AddCondition(client, TFCond_KingRune);
    // TF2_AddCondition(client, TFCond_CritCanteen, 4.0);
    // TF2_AddCondition(client, TFCond_UberchargedCanteen, 4.0);
    RequestFrame(HealToMax, client);
    EmitSoundToAll(SOUND,client);
    // MC_PrintToChatAll("{green}[Manned Machines]{default} SatParticles stats to the %N CHAMPION!", client);
}


// Callback that runs on the requested frame
void HealToMax(int client)
{
    if (!IsClientInGame(client) || !IsValidClient(client))
        return;
    
    // TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 2.0);
    TF2Attrib_AddCustomPlayerAttribute(client, "health regen", 99999.0, 2.0);
}

public TF2_OnConditionRemoved(client, TFCond condition)
{
    if (!IsAnyRobot(client) && condition == TFCond_KingRune || condition == TFCond_KingAura )
    {	
        if(client == g_i_current_champion)
        {
            MC_PrintToChatAll("{yellow}%N {green}was the champion, but was a {yellow}coward {green}ran in to spawn, and is no more", client);
            SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
            TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
            g_i_current_champion = -1

            TF2_RemoveAllWeapons(client);
            TF2_RespawnPlayer(client);
            

            CheckChampion();
        }
		
	}
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
    // PrintToChatAll("Damage was done");

    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;

    if (attacker == g_i_current_champion)
    {
        damage *= g_dmg_bonus;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{

    if(client == g_i_current_champion)
    {
        g_i_current_champion = -1;
        CheckChampion();
    }
}