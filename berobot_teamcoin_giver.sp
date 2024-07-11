#include <berobot_constants>
#include <berobot>
#include <berobot_core_restrictions>
#include <berobot_core>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>

#pragma newdecls required
#pragma semicolon 1

int b_is_koth;
int koth_caps;
float g_last_given_boss_coin;

float first_boss_coin_cooldown = 180.0;
float subsequent_boss_coin_cooldown = 300.0;

float g_last_given_boss_coin_cooldown;

bool g_first_capture = false;

public Plugin myinfo =
{
	name = "berobot_teamcoin_giver",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Gives Boss Coins based on events",
	version = "1.0",
	url = "https://github.com/higps/robogithub"
};

#define get_boss_coin_sound "mvm/mvm_bought_upgrade.wav"

public void OnMapStart()
{    
    b_is_koth = GameRules_GetProp("m_bPlayingKoth");
    koth_caps = 0;
    // g_last_given_boss_coin = first_boss_coin_cooldown;
    g_first_capture = false;
    g_last_given_boss_coin_cooldown = first_boss_coin_cooldown;
    PrecacheSound(get_boss_coin_sound);
}


public void OnPluginStart()
{
    HookEvent("player_death", Event_Death, EventHookMode_Pre);
    HookEvent("teamplay_point_captured", Event_Teamplay_Point_Captured, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);
    HookEvent("teamplay_setup_finished", Event_teamplay_setup_finished, EventHookMode_Post);
}


public Action Event_teamplay_setup_finished(Event event, char[] name, bool dontBroadcast)
{
    g_last_given_boss_coin = GetEngineTime();
}
public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{
        if (GameRules_GetProp("m_bSwitchedTeamsThisRound"))
        {
            //Reset cooldowns on team switch
            g_last_given_boss_coin_cooldown = first_boss_coin_cooldown;
            g_first_capture = false;
        }
        //Set the timer when the round starts
        // PrintToChatAll()
        
        // 100
}
public Action Event_Teamplay_Point_Captured(Event event, char[] name, bool dontBroadcast)
{        

    if(!IsBossPresent())
    {
        if(!g_first_capture)
        {
            g_first_capture = true;
            GiveBossCoin();
        }else
        {
            CheckBossCoin();
        }
    }
    

    return Plugin_Continue;
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    // int assister = GetClientOfUserId(GetEventInt(event, "assister"));
    if(IsAnyRobot(victim) && !IsAnyRobot(attacker))
    {
        CheckBossCoin();
    }


    // if (IsBoss(victim))
    // {
    //     PrintToChatAll("%N was a boss", victim);
    // }
    return Plugin_Continue;
}

void CheckBossCoin()
{
    if(!IsBossPresent())
    {
    // PrintToChatAll("Current gametime: %f\nLast Boss Coin %f\nNext Boss Coin: %f\nNext boss coin in %f seconds",GetEngineTime(),g_last_given_boss_coin, (g_last_given_boss_coin + g_last_given_boss_coin_cooldown), (g_last_given_boss_coin + g_last_given_boss_coin_cooldown)- GetEngineTime());
        if (!b_is_koth)
        {
            int robotteam = GetRobotTeam();

           
            if (GetEngineTime() > (g_last_given_boss_coin + g_last_given_boss_coin_cooldown))
            {
                
                 if (robotteam == TFTeam_Red && !g_first_capture)
                 {
                    // PrintToChatAll("WAS RED TEAM, BUT NO CAP");
                 }else{
                    // PrintToChatAll("WAS T");
                     GiveBossCoin();
                 }
            }
            
        }else
        {
            koth_caps++;
            if (koth_caps > 4)
            {
                GiveBossCoin();
                koth_caps = 0;
            }
        } 
    } 
}

bool IsBossPresent()
{    
    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsBoss(i))
        {
            // PrintToChatAll("Boss is present");
            return true;
        } 
    }
    // PrintToChatAll("No Boss is present");
    return false;
}

void GiveBossCoin()
{
    // bool BossPresent = false;
    for(int i = 1; i <= MaxClients; i++)
    {
        
        if (IsValidClient(i) && IsAnyRobot(i))
        {
            if (GetTeamCoinsFor(i) != 1)
            {
                EmitSoundToClient(i,get_boss_coin_sound);
            }
        }
    }

    SetTeamCoinsFor(TFTeam_Blue, 1);
    SetTeamCoinsFor(TFTeam_Red, 1);
    g_last_given_boss_coin = GetEngineTime();
    // This will make it so the cooldown resets
    // PrintToChatAll("CD was %f", g_last_given_boss_coin_cooldown);
    if (g_last_given_boss_coin_cooldown == first_boss_coin_cooldown)
    {
        g_last_given_boss_coin_cooldown = subsequent_boss_coin_cooldown;
    }


    // For loop, play sound for robots only
    // sound\mvm\mvm_bought_upgrade.wav
}