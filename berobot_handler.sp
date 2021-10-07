#define PLUGIN_NAME "Giant Robot Plugin Handler"
#define PLUGIN_DESCRIPTION "Handles backstab modifier as well as other functions for the giant robot plugins"
#define PLUGIN_AUTHOR "Fragancia & Heavy Is GPS"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "Balancemod.tf"

#define RED 2
#define BLUE 3
#define SPECTATE 1
#define UNASSIGNED 0

#include <berobot_constants>
#include <berobot>
#include <morecolors_newsyntax>
#include <sdkhooks>
#include <sdktools>
#include <sm_logger>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf_ontakedamage>

// #include <stocksoup/memory>
// #include <stocksoup/tf/entity_prop_stocks>
// #include <stocksoup/tf/tempents_stocks>
// #include <stocksoup/tf/weapon>


#include <dhooks>
#include <tf2attributes>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}
#include <berobot_core>

#pragma newdecls required
#pragma semicolon 1



enum //Convar names
{
    CV_flSpyBackStabModifier,
    CV_bDebugMode,
    CV_flYoutuberMode,
    CV_g_RoboCapTeam,
    CV_g_RoboCap,
    CV_g_RoboTeamMode,
    CV_g_RoboMode,
    CV_PluginVersion
}
/* Global Variables */

/* Global Handles */

//Handle g_hGameConf;

/* Dhooks */

/* Convar Handles */

ConVar g_cvCvarList[CV_PluginVersion + 1];

/* Convar related global variables */

bool g_cv_bDebugMode;
bool g_BossMode = false;
bool g_cv_BlockTeamSwitch = false;
bool g_SpectateSelection = false;

bool g_cv_Volunteered[MAXPLAYERS + 1];
char g_cv_RobotPicked[MAXPLAYERS + 1][NAMELENGTH];
bool g_ClientIsRepicking[MAXPLAYERS + 1];
bool g_Voted[MAXPLAYERS + 1];
bool g_VoiceCalloutClamp[MAXPLAYERS + 1];



float g_CV_flSpyBackStabModifier;
float g_CV_flYoutuberMode;

int g_RoboCapTeam;
int g_RoboTeam;
int g_HumanTeam;
int g_RoboCap;
int g_RoboTeamMode;
int g_RoboMode;
int g_iVotes;
int g_iVotesNeeded;

ArrayList g_Volunteers;
StringMap g_RobotCount;


// Handle g_SDKCallInternalGetEffectBarRechargeTime;
// Handle g_SDKCallIsBaseEntityWeapon;

//In Global Scope

Handle g_hRegen;
Handle g_hGameConf;
//Handle g_m_bTeamsSwitched;

//In OnPluginStart


// Global scope


public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};
public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_handler started at %i", GetTime());

    /* Convars */


    g_cvCvarList[CV_PluginVersion] = CreateConVar("sm_yt_v_mvm_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_yt_v_mvm_debug", "0", "Enable Debugging for Market Garden and Reserve Shooter damage", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_flSpyBackStabModifier] = CreateConVar("sm_robo_backstab_damage", "300.0", "Backstab damage");
    g_cvCvarList[CV_flYoutuberMode] = CreateConVar("sm_yt_mode", "0", "Uses youtuber mode for the official mode to set youtubers as the proper classes");
    g_cvCvarList[CV_g_RoboCapTeam] = CreateConVar(CONVAR_ROBOCAP_TEAM, "6", "The total amount of giant robots on a team");
    g_cvCvarList[CV_g_RoboCap] = CreateConVar("sm_robocap", "1", "The amount of giant robots allowed per robot-type");
    g_cvCvarList[CV_g_RoboTeamMode] = CreateConVar("sm_both_teams_have_robots", "0", "0 = One Team consists only of robots, 1 = Both teams have bots");
    g_cvCvarList[CV_g_RoboMode] = CreateConVar("sm_robo_mode", "0", "0 = Needs vote to start boss mode, 1 = Start game by reaching enough volunteers");

    /* Convar global variables init */

    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);
    g_CV_flSpyBackStabModifier = GetConVarFloat(g_cvCvarList[CV_flSpyBackStabModifier]);
    g_CV_flYoutuberMode = GetConVarFloat(g_cvCvarList[CV_flYoutuberMode]);
    g_RoboCapTeam = GetConVarInt(g_cvCvarList[CV_g_RoboCapTeam]);
    g_RoboCap = GetConVarInt(g_cvCvarList[CV_g_RoboCap]);
    g_RoboTeamMode = GetConVarInt(g_cvCvarList[CV_g_RoboTeamMode]);
    g_RoboMode = GetConVarInt(g_cvCvarList[CV_g_RoboMode]);

    /* Convar Change Hooks */

    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flSpyBackStabModifier].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flYoutuberMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCapTeam].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCap].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboTeamMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboMode].AddChangeHook(CvarChangeHook);


    RegAdminCmd("sm_makerobot", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_mr", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_boss_mode", Command_YT_Robot_Start, ADMFLAG_SLAY, "Sets up the team and starts the robot");
    RegAdminCmd("sm_selection_mode", Command_Robot_Selection, ADMFLAG_SLAY, "Forces selection mode");
    
    RegAdminCmd("sm_me_boss", Command_Me_Boss, ADMFLAG_SLAY, "Checks if you are a boss");
    RegAdminCmd("sm_setvolunteer", Command_SetVolunteer, ADMFLAG_SLAY, "sets the volunteer status to true/enabled");
    RegAdminCmd("sm_unsetvolunteer", Command_UnsetVolunteer, ADMFLAG_SLAY, "sets the volunteer status to false/disabled");

    RegConsoleCmd("sm_volunteer", Command_Volunteer, "Volunters you to be a giant robot");
    RegConsoleCmd("sm_vlntr", Command_Volunteer, "Volunters you to be a giant robot");
    RegConsoleCmd("sm_rtr", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_rocktherobot", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_changerobot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_chngrbt", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_cr", Command_ChangeRobot, "change your robot");

    /* Hooks */
    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);

    HookEvent("player_escort_score", Event_player_escort_score, EventHookMode_Post);

    
    HookEvent("player_death", Event_Death, EventHookMode_Post);

    g_Volunteers = new ArrayList(ByteCountToCells(g_RoboCapTeam));
    g_RobotCount = new StringMap();

    g_Volunteers.Clear();

    //Loading code where robots can't use resupply lockers
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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetPickedRobot", Native_GetPickedRobot);
    CreateNative("SetVolunteers", Native_SetVolunteers);
    return APLRes_Success;
}

public void OnMapStart()
{

    ResetMode();

}

public void ResetMode()
{
    g_cv_BlockTeamSwitch = false;
    g_BossMode = false;
    g_SpectateSelection = false;
    g_iVotes = 0;
    g_Volunteers.Clear();
    g_RobotCount.Clear();

    for(int i = 0; i < MAXPLAYERS; i++)
    {
        g_cv_Volunteered[i] = false;
        g_cv_RobotPicked[i] = "";
        g_Voted[i] = false;

    }
    //Set more dynamic way of getting the amount of votes needed
    g_iVotesNeeded = g_RoboCapTeam;
    //g_iVotesNeeded = 6;
}

public void OnClientDisconnect(int client)
{
    if(!g_cv_Volunteered[client])
        return;

    char robotName[NAMELENGTH];
    robotName = g_cv_RobotPicked[client];

    int currentCount;
    g_RobotCount.GetValue(robotName, currentCount);
    g_RobotCount.SetValue(robotName, currentCount - 1);
    g_cv_Volunteered[client] = false;
    g_cv_RobotPicked[client] = "";
    int index = FindValueInArray(g_Volunteers, client);
    if (index >= 0)
        g_Volunteers.Erase(index);
    RedrawVolunteerMenu();

    int newVolunteer = GetRandomVolunteer();
    if (IsValidClient(newVolunteer))
    {
        PrintToChat(newVolunteer, "%N has disconnected. You where automatically chosen to fillup the robot-team.", client);
        Volunteer(newVolunteer, true);
    }
    else
    {
        int islots = g_RoboCapTeam - g_Volunteers.Length;
        MC_PrintToChatAllEx(client, "{teamcolor}%N {default}has disconnected. There is now %i available robot slots remains. Type !volunteer to become a giant robot", client, islots);
    }
}

/* Publics */

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int assister = GetClientOfUserId(GetEventInt(event, "assister"));
    TFClassType attackerClass = TF2_GetPlayerClass(attacker);

    TFClassType assisterClass = TFClass_Unknown;
    if(IsValidClient(assister))
    {
        assisterClass = TF2_GetPlayerClass(assister);
    } 
    TFTeam iTeam = TF2_GetClientTeam(victim);
    char szVO[512];

    if (g_BossMode && iTeam == view_as<TFTeam>(g_HumanTeam))
     {
         //Handle respawn for robot teams
       //  CreateTimer(4.5, Timer_Respawn, victim);
         
     }

    //Robot died
    if (IsAnyRobot(victim))
    {
    
      switch(attackerClass)
      {
        case TFClass_Heavy:
        {
            Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot02");
        }
        case TFClass_Medic:
        {
            Format(szVO, sizeof(szVO), "medic_mvm_giant_robot02");
        }
      }
       EmitGameSoundToAll(szVO, attacker);

       if (IsValidClient(assister)){
       switch(assisterClass)
      {
        case TFClass_Heavy:
        {
            Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot02");
        }
        case TFClass_Medic:
        {
            Format(szVO, sizeof(szVO), "medic_mvm_giant_robot02");
        }
      
      }
      EmitGameSoundToAll(szVO, assister);
       }
    }

    //player died to robot

    if (!IsAnyRobot(victim) && IsAnyRobot(attacker))
    {

            for(int i = 1; i < MaxClients; i++)
            {

                if(IsPlayerAlive(i)){
        switch(i)
        {
            case TFClass_Heavy:
            {
                int random = GetRandomInt(1,10);
                if (random == 1){
                Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot01");
                EmitGameSoundToAll(szVO, i);
                }
            }
        }
                }
            }
        }
    

}

public Action Timer_Respawn(Handle timer, int client)
{
    TF2_RespawnPlayer(client);
}

public Action Event_player_escort_score(Event event, char[] name, bool dontBroadcast)
{   
    //Adds voice line if boss mode is active
    if(g_BossMode){
    int iCapper = GetEventInt(event, "player");
    
    char szVO[512];

    

        for(int i = 1; i < MaxClients; i++)
        {
        int iCapperTeam = TF2_GetClientTeam(iCapper);
     //   PrintToChatAll("Capture team was: %i", iCapperTeam);
        if (IsValidClient(i) && IsClientInGame(i)){
         TFClassType iClass = TF2_GetPlayerClass(i);
         TFTeam iPlayerTeam = TF2_GetClientTeam(i);


        // int digit = 1;

        if (iClass == TFClass_Spy && (TF2_IsPlayerInCondition(i, TFCond_Disguised) && GetEntProp(i, Prop_Send, "m_nDisguiseClass") != view_as<int>(iClass))){
            iClass = view_as<TFClassType>(GetEntProp(i, Prop_Send, "m_nDisguiseClass"));
        }
				

     //   If robot was not the capture
        if (!IsAnyRobot(i) && iPlayerTeam != iCapperTeam && IsPlayerAlive(i))
        {
            
            switch(iClass)
            {
                case TFClass_Heavy:
                {
                Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot03");
                }
                case TFClass_Medic:
                {
                Format(szVO, sizeof(szVO), "medic_mvm_giant_robot03");
                }
                case TFClass_Soldier:
                {
                int digit = GetRandomInt(3,4);
                Format(szVO, sizeof(szVO), "soldier_mvm_giant_robot0%i", digit);
                }
                case TFClass_Engineer:
                {
                Format(szVO, sizeof(szVO), "engineer_mvm_giant_robot03");
                }
            }

            if (iClass == TFClass_Heavy || iClass == TFClass_Medic || iClass == TFClass_Soldier || iClass == TFClass_Engineer)
            {
            int change = GetRandomInt(1,3);
            if(change == 1){
                PrintToChatAll("%N said it", i);
                EmitGameSoundToAll(szVO, i);
            }
            }
        }
    }
        }
    }
}
public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{
    for(int i = 1; i < MaxClients; i++)
    {
        if(g_cv_Volunteered[i] == true)
        {
            int iTeam = GetClientTeam(i);
            if(iTeam != g_RoboTeam)
            {
               // PrintToChatAll("Was not the same for %N", i);

                switch(iTeam)
                {
                case BLUE:
                {
                 //   PrintToChatAll("RoboTeam was RED changing to BLUE...");
                    g_RoboTeam = BLUE;
                    g_HumanTeam = RED;
                }
                case RED:
                {
                //    PrintToChatAll("RoboTeam was BLU changing to RED...");
                    g_RoboTeam = RED;
                    g_HumanTeam = BLUE;
                }
                case UNASSIGNED:
                {
                 //   PrintToChatAll("RoboTeam was UNASSIGNED");
                }
                case SPECTATE:
                {
                 //   PrintToChatAll("RoboTeam was Spectate");
                }
                }
                //We found a volunteer that was not on the robo team, no need to check the rest
               // PrintToChatAll("Breaking off the loop on %N", i);
                return Plugin_Handled;
            }
        }
    }

    return Plugin_Continue;
}

public MRESReturn OnRegenerate(int pThis, Handle hReturn, Handle hParams)
{
    //Activates when doing OnRegenerate (touchihng resupply locker) and then ignoring it if you are a boss
    if(isMiniBoss(pThis))
        return MRES_Supercede;

    return MRES_Ignored;
}

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
    if(convar == g_cvCvarList[CV_flSpyBackStabModifier])
        g_CV_flSpyBackStabModifier = StringToFloat(sNewValue);
    if(convar == g_cvCvarList[CV_flYoutuberMode])
        g_CV_flYoutuberMode = StringToFloat(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCap])
        g_RoboCap = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCapTeam])
        g_RoboCapTeam = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboTeamMode])
        g_RoboTeamMode = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboMode])
        g_RoboMode = StringToInt(sNewValue); 
}

void EmitSoundWithClamp(int client, char[] voiceline, float clamp){

	if (!g_VoiceCalloutClamp[client] && IsPlayerAlive(client)){
		EmitGameSoundToAll(voiceline, client);

		CreateTimer(clamp, calltimer_reset, client);
		g_VoiceCalloutClamp[client] = true;
	}
	

}
public Action calltimer_reset (Handle timer, int client)
{
	g_VoiceCalloutClamp[client] = false;
	//PrintToChatAll("resetting");
}

/* Plugin Exclusive Functions */
public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    if(IsValidClient(victim))
    {
        if(IsValidClient(attacker))
        {


            TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);
//            TFClassType iClassVictim = TF2_GetPlayerClass(victim);
            char szVO[512];
            int digit = 0;
 
    //IsAnyRobot(attacker)
    if (IsAnyRobot(victim)) 
    {
    
      switch(iClassAttacker)
      {
        case TFClass_Heavy:
        {
            Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot04");
        }
        case TFClass_Medic:
        {
            Format(szVO, sizeof(szVO), "medic_mvm_giant_robot01");
        }
        case TFClass_Soldier:
        {
            digit = GetRandomInt(1,2);
            Format(szVO, sizeof(szVO), "soldier_mvm_giant_robot0%i", digit);
        }
        case TFClass_Engineer:
        {
            digit = GetRandomInt(1,2);
            Format(szVO, sizeof(szVO), "engineer_mvm_giant_robot0%i", digit);
        }
      }

      digit = GetRandomInt(1,4);
      if (digit == 1)
      {
        float random_timer = GetRandomFloat(20.5,60.5);
      //if (!IsAnyRobot(victim))EmitSoundWithClamp(victim, szVO, random_timer);
      if (!IsAnyRobot(attacker))EmitSoundWithClamp(attacker, szVO, random_timer);
      }
    }
      
    

        
    
    


            //Backstab damage and Headshot code below
            if(iClassAttacker == TFClass_Spy)
            {
                // Checks if boss is on
                if(g_cv_bDebugMode) PrintToChatAll("Attacker was spy");

                    if(IsAnyRobot(victim))
                    {
                        if(damagecustom == TF_CUSTOM_BACKSTAB)
                        {
                            damage = g_CV_flSpyBackStabModifier;
                            critType = CritType_Crit;
                            if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);

                            return Plugin_Changed;
                        }
                        if(damagecustom == TF_CUSTOM_HEADSHOT)
                        {
                            damage *= 1.1111;
                            critType = CritType_Crit;
                         if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                            return Plugin_Changed;
                        }
                    }
            }

            if(iClassAttacker == TFClass_Sniper)
            {
                // Checks if boss is on
                if(g_cv_bDebugMode) PrintToChatAll("Attacker was spy");
                    if(IsAnyRobot(victim))
                    {
                        if(damagecustom == TF_CUSTOM_HEADSHOT)
                        {
                            
                            
                            damage *= 1.1111;
                            critType = CritType_Crit;
                            if(g_cv_bDebugMode) PrintToChatAll("Set damage to %f", damage);

                            return Plugin_Changed;
                        }
                    }
            }
        }
    }
    return Plugin_Continue;
}

public Action Command_BeRobot(int client, int numParams)
{
    char name[NAMELENGTH];
    GetCmdArg(1, name, NAMELENGTH);

    char target[32];
    if (numParams < 2)
        target[0] = '\0';
    else 
        GetCmdArg(2, target, sizeof(target));

    SMLogTag(SML_VERBOSE, "BeRobot calling CreateRobot with %s, %i, %s", name, client, target);
    CreateRobot(name, client, target);
    
    SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 1);
    
    return Plugin_Handled;
}

public Action Command_Me_Boss(int client, int args)
{
    if(isMiniBoss(client))
    {

        PrintToChat(client, "You are miniboss");
    }
    else
    {
        PrintToChat(client, "You are not miniboss");
    }
    return Plugin_Handled;
}

public Action Command_Robot_Selection(int client, int args)
{
    ServerCommand("mp_forceautoteam  0");
    
    for(int i = 1; i < MaxClients; i++)
    {
        if (IsValidClient(i) && IsClientInGame(i))
        {
            ChangeClientTeam(i, SPECTATE);
        }
    }

    g_cv_BlockTeamSwitch = true;
    g_SpectateSelection = true;

    StartAutomaticVolunteerVote();
}

// intercept and block client jointeam command if required
public Action Command_YT_Robot_Start(int client, int args)
{

    if(!g_BossMode)
    {
        g_cv_BlockTeamSwitch = true;
        g_SpectateSelection = false;
        PrintCenterTextAll("Sarting Giant Robot Event mode");
        
        ServerCommand("mp_forceautoteam 0");
        ServerCommand("mp_teams_unbalance_limit 0");
        ServerCommand("sm_cvar tf_dropped_weapon_lifetime 0");
        ServerCommand("mp_restartgame 5");
        ServerCommand("mp_autoteambalance 0");
        ServerCommand("mp_scrambleteams_auto 0");
        ServerCommand("mp_forceautoteam  0");
        

        //Randomly set which team is roboteam and humanteam
        int RandomTeam = GetRandomInt(1, 2);
        PrintToChatAll("Randomteam was %i", RandomTeam);
        if(RandomTeam == 1)
        {

            g_RoboTeam = BLUE;
            g_HumanTeam = RED;
        }
        else
        {

            g_RoboTeam = RED;
            g_HumanTeam = BLUE;
        }


        g_BossMode = true;
        PrintToChatAll("Robots will be Team %i", g_RoboTeam);
        PrintToChatAll("Humans will be Team %i", g_HumanTeam);
    }
    else
    {
        g_cv_BlockTeamSwitch = false;
        PrintCenterTextAll("Stopping Giant Robot Event mode");
        ServerCommand("mp_forceautoteam 1");
        ServerCommand("sm_cvar tf_dropped_weapon_lifetime 30");
        ServerCommand("mp_teams_unbalance_limit 1");
        ServerCommand("mp_restartgame 5");
        ServerCommand("mp_autoteambalance 1");
        ServerCommand("mp_scrambleteams_auto 1");

        ResetMode();
        
    }

    if(g_BossMode)
    {

        if(g_CV_flYoutuberMode)
        {
            ServerCommand("sm_ct @all red");
            ServerCommand("sm_ct @blue red");

            //Loops through all players and checks if the set ID's are present. Then sets them on blue while the rest is red
            g_RoboTeam = BLUE;
            for(int i = 1; i < MaxClients; i++)
            {

                if(IsClientInGame(i) && IsValidClient(i))
                {

                    char sSteamID[64];
                    GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
                    int playerID = GetClientUserId(i);


                    //PrintToChatAll("Looping on %i", playerID);
                    //Hardcoding
                    //GPS
                    if(StrEqual(sSteamID, "76561197963998743"))
                    {
                        CreateRobot("HiGPS", i, "");
                        // CreateRobot("Solar Light", i, "");
                        //ServerCommand("sm_begps #%i", playerID);
                        TF2_SwapTeamAndRespawnNoMsg(playerID, g_RoboTeam);
                    }

                    //Bearded
                    if(StrEqual(sSteamID, "76561198031657211"))
                    {
                        //ServerCommand("sm_bebearded #%i", playerID);
                        CreateRobot("Bearded Expense", i, "");
                        ChangeClientTeam(i, g_RoboTeam);
                        TF2_RespawnPlayer(i);
                    }


                    //ArraySeven
                    if(StrEqual(sSteamID, "76561198013749611"))
                    {
                        //   ServerCommand("sm_bearray #%i", playerID);
                        CreateRobot("Array Seven", i, "");
                        ChangeClientTeam(i, g_RoboTeam);
                        TF2_RespawnPlayer(i);
                    }

                    //Uncle Dane
                    if(StrEqual(sSteamID, "76561198057999536"))
                    {
                        //   ServerCommand("sm_bedane #%i", playerID);
                        CreateRobot("Uncle Dane", i, "");
                        ChangeClientTeam(i, g_RoboTeam);
                        TF2_RespawnPlayer(i);
                    }

                    //Agro
                    if(StrEqual(sSteamID, "76561197970498549"))
                    {
                        //   ServerCommand("sm_beagro #%i", playerID);
                        CreateRobot("Agro", i, "");
                        ChangeClientTeam(i, g_RoboTeam);
                        TF2_RespawnPlayer(i);
                    }

                    //Solar
                    if(StrEqual(sSteamID, "76561198070962612"))
                    {
                        ///     ServerCommand("sm_besolar #%i", playerID);
                        CreateRobot("Solar Light", i, "");
                        ChangeClientTeam(i, g_RoboTeam);
                        TF2_RespawnPlayer(i);
                    }
                }
            }
        }
        else
        {


            //Set everyone to spectate first

            //ServerCommand("sm_ct @all spectate");

            //Make volunteer robots go here
            for(int i = 0; i < MaxClients; i++)
            {

                //PrintToChatAll("Looping players %i", i);
                if(IsValidClient(i))
                {


                    if(IsClientInGame(i))
                    {
                       // TF2_ChangeClientTeam(i, TFTeam_Spectator);
                        // int playerID = GetClientUserId(i);
                        //ServerCommand("sm_ct #%i red", playerID);
                        //int index = FindValueInArray(g_Volunteers, i);

                        if(g_cv_Volunteered[i])
                        {
                            PrintToChat(i, "You are on the Robot Team");
                            // ServerCommand("sm_begps #%i", playerID);
                            //ServerCommand("sm_ct #%i %i", playerID, g_RoboTeam);
                            TF2_SwapTeamAndRespawnNoMsg(i, g_RoboTeam);
                        //    TF2_RespawnPlayer(i);
                            g_ClientIsRepicking[i] = false;
                            Menu_Volunteer(i);
                        }
                        else
                        {
                            PrintToChat(i, "You are on the Human team");
                            // ServerCommand("sm_ct #%i %i", playerID, g_HumanTeam);
                            TF2_SwapTeamAndRespawnNoMsg(i, g_HumanTeam);
                            //TF2_RespawnPlayer(i);
                        }
                    }
                }
            }
        }
    }
}

public Action Command_RoboVote(int client, int args)
{

    //If boss mode is already active
    //PrintToChatAll("%i",CV_g_RoboCapTeam);
    if (g_BossMode)
    {
        MC_PrintToChatEx(client, client,"[{orange}SM{default}]{teamcolor} Giant Boss Mode is already active");
        return;
    }

    if (g_RoboMode == 1)
    {
        MC_PrintToChatEx(client, client,"[{orange}SM{default}]{teamcolor} Voting is disabled. Use {green}!volunteer{green} to become a robot, game starts when enough volunteers are reached");
        return;
    }
    
    //If the client has already voted
    if(g_Voted[client])
    {
        MC_PrintToChat(client,"{orange}You have already voted");
        return;
    }

    g_iVotes++;
    g_Voted[client] = true;
    MC_PrintToChatAllEx(client, "[{orange}SM{default}] {teamcolor}%N {default}wants to start Giant Robot Boss mode. [{orange}%i{default}/{orange}%i {default}more votes required]", client, g_iVotes, g_iVotesNeeded);

    //Start the robo vote
    if(g_iVotes >= g_iVotesNeeded)
    {
        Command_Robot_Selection(client, args);
    }
    

}

public Action Command_ChangeRobot(int client, int args)
{
    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    int targetFilter = 0;
    if(target[0] == '\0')
    {
        target = "@me";
        targetFilter = COMMAND_FILTER_NO_IMMUNITY;
    }

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if((target_count = ProcessTargetString(
          target,
          client,
          target_list,
          MAXPLAYERS,
          targetFilter,
          target_name,
          sizeof(target_name),
          tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for(int i = 0; i < target_count; i++)
    {
        int targetClientId = target_list[i];
        if (!IsAnyRobot(targetClientId))
            continue;

        g_cv_Volunteered[targetClientId] = true;
        g_ClientIsRepicking[targetClientId] = true;
        Menu_Volunteer(targetClientId);
    }
            
    return Plugin_Handled;
}

public Action Command_SetVolunteer(int client, int args)
{
    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    VolunteerTargets(client, target, true);

    return Plugin_Handled;
}

public Action Command_UnsetVolunteer(int client, int args)
{
    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    VolunteerTargets(client, target, false);

    return Plugin_Handled;
}

public Action Command_Volunteer(int client, int args)
{

    //PrintToChatAll("g_RoboMode was %i", g_RoboMode);
    //PrintToChatAll("CV_g_RoboMode was %i", CV_g_RoboMode);


    if (!g_RoboMode) 
    {
        if (!g_SpectateSelection)MC_PrintToChatEx(client, client, "[ {orange}SM {default}] {teamcolor}Unable to volunteer, robo mode is not started use {green}!robo_vote{green}{teamcolor} to initiate a vote instead. Volunteering will happen later");
        if (!g_SpectateSelection)return Plugin_Handled;
    }

    if (AutomaticVolunteerVoteIsInProgress()) 
    {
        MC_PrintToChatEx(client, client, "[ {orange}SM {default}] {teamcolor}Unable to volunteer, a vote for volunteers is in progress");
        return Plugin_Handled;
    }

    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    VolunteerTargets(client, target, !g_cv_Volunteered[client]);

    return Plugin_Handled;
}

public Action VolunteerTargets(int client, char target[32], bool volunteering)
{
    int targetFilter = 0;
    if(target[0] == '\0')
    {
        target = "@me";
        targetFilter = COMMAND_FILTER_NO_IMMUNITY;
    }

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if((target_count = ProcessTargetString(
          target,
          client,
          target_list,
          MAXPLAYERS,
          targetFilter,
          target_name,
          sizeof(target_name),
          tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for(int i = 0; i < target_count; i++)
    {
        int targetClientId = target_list[i];
        Volunteer(targetClientId, volunteering);
    }

    return Plugin_Handled;
}

public Action Volunteer(int client, bool volunteering)
{
    if(g_BossMode && g_Volunteers.Length >= g_RoboCapTeam)
    {
        MC_PrintToChatEx(client, client, "{teamcolor}Game has already started, volunteering not available.", g_RoboCapTeam);
        return;
    }

    if(volunteering && !g_cv_Volunteered[client])
    {
        SMLogTag(SML_VERBOSE, "volunteer-state changed to true for %L", client);

        g_cv_Volunteered[client] = true;

        g_Volunteers.Push(client);

        //PrintToChat(client, "You have volunteered to be a giant robot");

        if(g_BossMode)
        {
            SMLogTag(SML_VERBOSE, "volunteering during boss_mode => switch team & show menu");
            //int playerID = GetClientUserId(client);
            TF2_SwapTeamAndRespawnNoMsg(client, g_RoboTeam);
            g_ClientIsRepicking[client] = false;
            Menu_Volunteer(client);
        }
    }
    else if(!volunteering && g_cv_Volunteered[client]) //Remove from volunteer list
    {
        SMLogTag(SML_VERBOSE, "volunteer-state changed to false for %L", client);

        g_cv_Volunteered[client] = false;

        int index = FindValueInArray(g_Volunteers, client);
        g_Volunteers.Erase(index);

        //  MC_PrintToChatEx(client, client, "{teamcolor}You are not volunteering to be a giant robot anymore");
        int islots = g_RoboCapTeam - g_Volunteers.Length;
        MC_PrintToChatAllEx(client, "{teamcolor}%N {default}is no longer volunteering to be a giant robot. %i more volunteers needed.", client, islots);
    }
    else
    {
        SMLogTag(SML_VERBOSE, "volunteer-state did not change for %L (still %b)", client, g_cv_Volunteered[client]);
    }

    if(g_RoboCapTeam == g_Volunteers.Length)
    {
        MC_PrintToChatEx(client, client, "{teamcolor}The max amount of %i volunteers has been reached, starting Boss Mode", g_RoboCapTeam);

        if(!g_BossMode)Command_YT_Robot_Start(client, true);

        g_Volunteers.Resize(g_RoboCapTeam);
        g_BossMode = true;
        return;
    }

    for(int i = 0; i < g_Volunteers.Length; i++)
    {

        int clientId = g_Volunteers.Get(i);
        if(IsValidClient(clientId) && IsClientInGame(clientId))
        {

            int islots = g_RoboCapTeam - g_Volunteers.Length;
            MC_PrintToChatAllEx(client, "{teamcolor}%N {default}has volunteered to be a giant robot. %i more volunteers needed.", clientId, islots);
        }
    }

    //Menu Stuff here

    //PrintToChatAll("%i arraylength", g_Volunteers.Length);
}

int RobotDefinitionComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    Robot a, b;
    list.GetArray(index1, a);
    list.GetArray(index2, b);


    int classcmp = strcmp(a.class, b.class);
    if (classcmp != 0)
        return classcmp;

    return strcmp(a.name, b.name);
}

Action Menu_Volunteer(int client)
{
    if (IsFakeClient(client))
    {
        SetRandomRobot(client);
        return Plugin_Handled;
    }

    ArrayList robotNames = GetRobotNames();
    SMLogTag(SML_VERBOSE, "%i robots found", robotNames.Length);

    ArrayList robotDefinitions = new ArrayList(sizeof(Robot));
    for(int i = 0; i < robotNames.Length; i++)
    {
        char name[NAMELENGTH];
        robotNames.GetString(i, name, NAMELENGTH);
        Robot item;
        if (GetRobotDefinition(name, item) != 0)
        {
            SMLogTag(SML_ERROR, "could not volunteer. no robot with name '%s' found", name);
            return Plugin_Handled;
        }

        robotDefinitions.PushArray(item);
    }
    robotDefinitions.SortCustom(RobotDefinitionComparision);

    Menu menu = new Menu(MenuHandler);

    menu.SetTitle("Select Your Robot Type");
    menu.ExitButton = g_ClientIsRepicking[client];

    for(int i = 0; i < robotDefinitions.Length; i++)
    {
        Robot item;
        robotDefinitions.GetArray(i, item, sizeof(item));

        int count;
        g_RobotCount.GetValue(item.name, count);
        int draw = count >= g_RoboCap ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;

        char display[128];
        Format(display, sizeof(display), "%s: %s (%i / %i)", item.class, item.name, count, g_RoboCap);

        menu.AddItem(item.name, display, draw);

        SMLogTag(SML_VERBOSE, "added option for %s: %s", item.name, display);
    }

    int timeout = MENU_TIME_FOREVER;
    menu.Display(client, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", client, timeout);

    return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        char info[NAMELENGTH];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        SetRobot(info, param1);
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        g_ClientIsRepicking[param1] = false;
        // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        delete menu;
    }
}

void SetRandomRobot(int client)
{
    ArrayList robotNames = GetRobotNames();

    char robotname[NAMELENGTH];
    int count;
    do
    {
        int i = GetRandomInt(0, robotNames.Length -1);

        robotNames.GetString(i, robotname, sizeof(robotname));

        g_RobotCount.GetValue(robotname, count);
    }
    while(count >= g_RoboCap);

    SMLogTag(SML_VERBOSE, "setting bot %L to be robot '%s'", client, robotname);
    SetRobot(robotname, client);
}

void SetRobot(char robotname[NAMELENGTH], int client)
{    
    CreateRobot(robotname, client, "");

    //reset count for current robot
    SMLogTag(SML_VERBOSE, "volunteered by %L is currently robot '%s'", client, g_cv_RobotPicked[client]);
    if (g_cv_RobotPicked[client][0] != '\0')
    {
        int count;
        g_RobotCount.GetValue(g_cv_RobotPicked[client], count);

        SMLogTag(SML_VERBOSE, "%L decrements robot-count for robot '%s' from %i", client, g_cv_RobotPicked[client], count);
        g_RobotCount.SetValue(g_cv_RobotPicked[client], count - 1);

    }

    int currentCount;
    g_RobotCount.GetValue(robotname, currentCount);
    g_RobotCount.SetValue(robotname, currentCount + 1);
    g_cv_RobotPicked[client] = robotname;
    g_ClientIsRepicking[client] = false;

    RedrawVolunteerMenu();
}

void RedrawVolunteerMenu()
{
    for(int i = 0; i < MaxClients; i++)
    {
        if(g_cv_RobotPicked[i][0] != '\0' && !g_ClientIsRepicking[i]) //don't open menu for players, who have already picked a robot
            continue;

        if(!IsValidClient(i))
            continue;

        if(!IsClientInGame(i))
            continue;

        if(IsFakeClient(i))
            continue;

        if(!g_cv_Volunteered[i])
            continue;

        Menu_Volunteer(i);
    }
}

public Action OnClientCommand(int client, int args)
{
    char cmd[16];

    /* Get the argument */
    GetCmdArg(0, cmd, sizeof(cmd));

    TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));

    if(strcmp(cmd, "jointeam", true) == 0)
    {

        if (g_SpectateSelection)
        {
            ChangeClientTeam(client, SPECTATE);
            return Plugin_Handled;
        }

        if(g_cv_BlockTeamSwitch)
        {
            PrintCenterText(client, "Boss mode is activated: Teams are locked");

            //If someone joins while the event is going, set correct player team

            if(iTeam == TFTeam_Unassigned)
            {


                //Puts players in the correct team
                if(!isMiniBoss(client))
                    ChangeClientTeam(client, g_HumanTeam);

                if(isMiniBoss(client))
                    ChangeClientTeam(client, g_RoboTeam);

                //Sets you as random class when you join when boss mode is active
                int irandomclass = GetRandomInt(1, 9);
                TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
                TF2_RespawnPlayer(client);
            }

            return Plugin_Handled;
        }
    }

    //PrintToChatAll("Team switch trigger");

    return Plugin_Continue;
}

bool isMiniBoss(int client)
{

    if(IsValidClient(client))
    {

        if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
        {
            if(g_cv_bDebugMode) PrintToChatAll("%N Was mini boss", client);
                return true;
        }
        else
        {
            if(g_cv_bDebugMode)PrintToChatAll("%N Was not mini boss", client);
                return false;
        }
    }
    return false;
}

/* Natives */
public any Native_GetPickedRobot(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int maxDestLength = GetNativeCell(3);

	SetNativeString(2, g_cv_RobotPicked[client], maxDestLength);
}

int Native_SetVolunteers(Handle plugin, int numParams)
{
    int length = GetNativeCell(2);
    int[] volunteers = new int[length];
    GetNativeArray(1, volunteers, length);

    for(int i = 0; i < length; i++)
    {
        Volunteer(volunteers[i], true);
    }
}

stock void TF2_SwapTeamAndRespawnNoMsg(int client, int team)
{
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}
