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
bool g_b_valid_candidate[MAXPLAYERS + 1] = { false, ... };
bool g_b_found_valid_candidate = false;
int g_i_current_champion = -1;
Handle g_h_checkChampionTimer = INVALID_HANDLE;
Handle g_h_checkChampionCowardTimer = INVALID_HANDLE;
int g_MissingHumans = 0;
int g_CurrentRobots = 0;
float g_dmg_bonus = 1.0;
bool g_b_yap = true;

GlobalForward _currentChampion;

public void OnMapStart()
{
    PrecacheSound(SOUND);
    g_MissingHumans = 0;
    g_b_found_valid_candidate = false;
    g_i_current_champion = -1;
    if (g_h_checkChampionTimer != INVALID_HANDLE)
    {
        CloseHandle(g_h_checkChampionTimer);
        g_h_checkChampionTimer = INVALID_HANDLE;
    }
    if (g_h_checkChampionCowardTimer != INVALID_HANDLE)
    {
        CloseHandle(g_h_checkChampionCowardTimer);
        g_h_checkChampionCowardTimer = INVALID_HANDLE;
    }
}


public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_Death, EventHookMode_Post);

    CreateNative("MM_GetCurrentChampion", Native_GetCurrentChampion);
}

public int Native_GetCurrentChampion(Handle plugin, int numParams)
{
    return g_i_current_champion;
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if(victim == g_i_current_champion)
    {
        MC_PrintToChatAll("{green}The {gold}Champion:{gold} %N{green} has fallen.", victim);
        g_i_current_champion = -1
        g_b_yap = true;
        RequestFrame(CheckChampion);
    }
    return Plugin_Continue;
}

float g_cooldown = 5.0;
float g_last_check = 0.0;

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    
    if (GetEngineTime() >= g_last_check + g_cooldown)
    {
        g_last_check = GetEngineTime();
        if(g_i_current_champion == -1)RequestFrame(CheckChampion);
     
    }
    return Plugin_Continue;
}
void FindValidCandidates()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsAnyRobot(i) && TF2Spawn_IsClientInSpawn(i) && IsPlayerAlive(i))
        {
            g_b_valid_candidate[i] = true;
            g_b_found_valid_candidate = true;
        }
        else
        {
            g_b_valid_candidate[i] = false;
        }
    }
}
void CheckChampion()
{   
    
    if (g_i_current_champion == -1)
    {
        g_CurrentRobots = GetCurrentRobotCount();
        int CurrentHumans = GetCurrentHumanCount();

        ConVar drobotcount = FindConVar("sm_berobot_dynamicRobotCount_humansPerRobot");
        float ratio = drobotcount.FloatValue;

        int TargetHumans = RoundToFloor(float(g_CurrentRobots) * ratio) - g_CurrentRobots;
        g_MissingHumans = TargetHumans - CurrentHumans;


        g_dmg_bonus = 1.0 + (0.35 * float(g_MissingHumans));

        // PrintToChatAll("Current Robots: %i", g_CurrentRobots);
        // PrintToChatAll("Current Humans: %i", CurrentHumans);
        // PrintToChatAll("Target Humans: %i", TargetHumans);
        // PrintToChatAll("Missing Humans: %i", g_MissingHumans);

        if (g_MissingHumans > 0)
        {
            
            if(g_b_yap)
            {
                MC_PrintToChatAll("{green}A champion with the power level of %i will surface soon", g_MissingHumans);
                g_b_yap = false;
            }

            

            FindValidCandidates();

            if (g_b_found_valid_candidate)
            {
                // MC_PrintToChatAll("{green}Next player to leave spawn becomes the {gold}CHAMPION");
                if (g_h_checkChampionTimer == INVALID_HANDLE)
                {
                    g_h_checkChampionTimer = CreateTimer(1.0, Timer_CheckChampionLeaveSpawn, _, TIMER_REPEAT);
                }
            }
        }
        else
        {
            // PrintToChatAll("Removing champion");
            g_i_current_champion = -1;
            g_b_yap = true;
            if (g_h_checkChampionTimer != INVALID_HANDLE)
            {
                CloseHandle(g_h_checkChampionTimer);
                g_h_checkChampionTimer = INVALID_HANDLE;
            }
            for (int i = 1; i <= MaxClients; i++)
            {
                g_b_valid_candidate[i] = false;
            }
        }
    }
}



public Action Timer_CheckChampionLeaveSpawn(Handle timer)
{
    // PrintToChatAll("Timer");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_b_valid_candidate[i] && IsClientInGame(i) && !TF2Spawn_IsClientInSpawn(i))
        {
            g_i_current_champion = i;
            MC_PrintToChatAll("{orange}%N {green}has become the {gold}CHAMPION!", i);
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

void SetScale(int client, float scale)
{
    SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.25);
    UpdatePlayerHitbox(client, 1.25);
}

void CreateChampion(int client)
{
    if (IsValidClient(client) && !IsAnyRobot(client) && IsPlayerAlive(client))
    {
        // SetScale(client, 1.25);
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
                MakeDemomanChampion(Weapon1, Weapon2, Weapon3);

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
        if (g_h_checkChampionCowardTimer == INVALID_HANDLE)
        {
            g_h_checkChampionCowardTimer = CreateTimer(0.3, Timer_CheckChampionCoward, _, TIMER_REPEAT);
        }
    }
}

void RemoveChampion(int client)
{
    MC_PrintToChatAll("{yellow}%N {green}was the champion, but was a {yellow}coward {green}ran in to spawn, and is no more", client);
    SetScale(client, 1.0);
    TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
    g_i_current_champion = -1
    g_b_yap = true;
    TF2_RemoveAllWeapons(client);
    TF2_RespawnPlayer(client);
}

public Action Timer_CheckChampionCoward(Handle timer)
{
    if(TF2Spawn_IsClientInSpawn(g_i_current_champion) &&  IsPlayerAlive(g_i_current_champion))
    {
        // PrintToChatAll("CHAMPION IN SPAWN!");
        g_h_checkChampionCowardTimer = INVALID_HANDLE;
        RemoveChampion(g_i_current_champion);
        RequestFrame(CheckChampion);
        return Plugin_Stop;
    }

    return Plugin_Continue;
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
void MakeDemomanChampion(int Weapon1, int Weapon2, int Weapon3)
{
    // TODO: Add Demoman-specific buffs or logic here
    if (IsDemoKnight(Weapon1, Weapon2))
    {
        TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", g_dmg_bonus); 
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
    TF2Attrib_SetByName(client, "max health additive bonus", (50.0 * (float(g_MissingHumans)))); 
    // TF2Attrib_SetByName(client, "particle effect use head origin", 1.0); 
    //3160 teamwork valorance
    // 3025 enchanted
    // TF2Attrib_SetByName(client, "attach particle effect", 3160.0); 
    TF2Attrib_SetByName(client, "attach particle effect", 3025.0); 
    CreateRoboHat(client, 30808, 5, 8, -1, -1, 1.25, 1.0);
    TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
    // TF2_AddCondition(client, TFCond_KingAura);
    // TF2_AddCondition(client, TFCond_KingRune);
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
        g_b_yap = true;
        CheckChampion();
    }
}

public FindHat(int iClient)
{
	int iWearableItem = -1;
	// PrintToServer("LOOKING HAT 1 !");
	while ((iWearableItem = FindEntityByClassname(iWearableItem, "tf_wearable*")) != -1) // Regular hats.
	{	
		// We check for the wearable's item def index and its owner.
		int iWearableIndex = GetEntProp(iWearableItem, Prop_Send, "m_iItemDefinitionIndex");
		int iWearableOwner = GetEntPropEnt(iWearableItem, Prop_Send, "m_hOwnerEntity");
		// PrintToServer("LOOKING HAT 2 !");
		// If the owners match.
		if (iWearableOwner == iClient)
		{
			// Going through all items. 4 = cosmetics
			for (int i = 0; i < 4; i++)
			{			
				// PrintToServer("LOOKING HAT 3 !");
				// If a weapon's definition index matches with the one stored...
				TF2Attrib_SetByName(iWearableIndex, "attach particle effect", 35.0); 
			}
		}
	}
	// return false;
}