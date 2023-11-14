#define PLUGIN_NAME "Giant Robot Plugin Handler"
#define PLUGIN_DESCRIPTION "Handles backstab modifier as well as other functions for the giant robot plugins"
#define PLUGIN_AUTHOR "Fragancia & Heavy Is GPS"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "bmod.tf"

#define RED 3
#define BLUE 2
#define SPECTATE 1
#define UNASSIGNED 0

#include <berobot_constants>
#include <berobot>
#include <berobot_core_restrictions>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <sm_logger>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf_ontakedamage>
#include <tf2_isPlayerInSpawn>
#include <particle>
// #include <stocksoup/memory>
// #include <stocksoup/tf/entity_prop_stocks>
// #include <stocksoup/tf/tempents_stocks>
// #include <stocksoup/tf/weapon>


#include <dhooks>
#include <tf2attributes>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}
#include <berobot_core>

#pragma newdecls required
#pragma semicolon 1


#define RESISTANCE "player/resistance_medium4.wav"

enum //Convar names
{
    CV_g_Rtr_precent,
    CV_flSpyBackStabModifier,
    CV_bDebugMode,
    CV_flYoutuberMode,
    CV_g_RoboCapTeam,
    CV_g_RoboCap,
    CV_g_RoboTeamMode,
    CV_g_RoboMode,
    CV_g_RoboStartTeam,
    CV_g_Enable,
    CV_g_AprilEnable,
    CV_PluginVersion
}

enum {
    dmg_method_on_target,
    dmg_method_off_target
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
bool g_WaitingForPlayers = true;

bool g_cv_Volunteered[MAXPLAYERS + 1];
char g_cv_RobotPicked[MAXPLAYERS + 1][NAMELENGTH];
bool g_Voted[MAXPLAYERS + 1];

bool g_GoingToDie[MAXPLAYERS + 1] = {false, ...};
int g_TimeBombTime[MAXPLAYERS+1] = { 0, ... };
int g_PlayerHealth[MAXPLAYERS +1] = {-1, ...};

GlobalForward _enabledChangedForward;
GlobalForward _clientResetting;
GlobalForward _modeResetRequestedForward;

// float g_CV_flSpyBackStabModifier;

float g_Rtr_percent;

int g_CV_flYoutuberMode;
int g_Enable;
int g_RoboCapTeam;
int g_RoboTeam;
int g_HumanTeam;
int g_RoboCap;
int g_RoboTeamMode;
int g_RoboStartTeam;
int g_RoboMode;
int g_iVotes;
int g_iVotesNeeded;
int g_AprilEnable;

float g_f_Damage_Bonus = 1.0;
float g_f_previous_dmg_bonus = -1.0;
//bool g_IsAprilRTD[MAXPLAYERS + 1] = false;
bool b_g_high_power = false;
int g_RoundCount;
// int g_TankCount;

ArrayList g_Volunteers;


// Handle g_SDKCallInternalGetEffectBarRechargeTime;
// Handle g_SDKCallIsBaseEntityWeapon;

//In Global Scope

Handle g_hRegen;
Handle g_hGameConf;
Handle g_hIsDeflectable;
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
//

    g_cvCvarList[CV_PluginVersion] = CreateConVar("sm_mm_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
    //Gamemode cvar
    g_cvCvarList[CV_g_Enable] = CreateConVar("sm_mm_enable", "0", "0 = Manned Machines disabled, 1 = Manned Machines enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_g_AprilEnable] = CreateConVar("sm_mm_april_enable", "0", "0 = Manned Machines april fools disabled, 1 = Manned Machines april fools enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_mm_debug", "0", "Enable Debugging for Manned Machines Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_g_RoboCapTeam] = CreateConVar(CONVAR_ROBOCAP_TEAM, "6", "The total amount of giant robots on a team");  
    g_cvCvarList[CV_g_RoboCap] = CreateConVar("sm_robocap", "1", "The amount of giant robots allowed per robot-type");
    g_cvCvarList[CV_g_RoboTeamMode] = CreateConVar("sm_both_teams_have_robots", "0", "0 = One Team consists only of robots, 1 = Both teams have bots");
    g_cvCvarList[CV_g_RoboMode] = CreateConVar("sm_robo_mode", "0", "0 = Starts the mode when waiting for players is over, 1 = Start game by reaching enough volunteers");
    g_cvCvarList[CV_g_RoboStartTeam] = CreateConVar("sm_robot_random_start_team", "1", "0 = Robots always start on red, 1 = Robot team is randomly picked RED or BLUE, 2 = Robots Always starts on blue");

    g_cvCvarList[CV_g_Rtr_precent] = CreateConVar("sm_mm_needed_rtr_ratio", "0.5", "The ratio of votes needed to start the mode with !rtr 1.0 = 100% 0.0 = 0%");

    

    //Gameplay cvar
    g_cvCvarList[CV_flSpyBackStabModifier] = CreateConVar("sm_robo_backstab_damage", "83.3", "Backstab damage that will be multipled by crit multiplier");
    g_cvCvarList[CV_flYoutuberMode] = CreateConVar("sm_mm_yt_mode", "0", "Uses youtuber mode for the official mode to set youtubers as the proper classes");
    /* Convar global variables init */

    
    g_Enable = GetConVarInt(g_cvCvarList[CV_g_Enable]);
    g_AprilEnable = GetConVarInt(g_cvCvarList[CV_g_AprilEnable]);

    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);
    //g_CV_flSpyBackStabModifier = GetConVarFloat(g_cvCvarList[CV_flSpyBackStabModifier]);
    g_Rtr_percent = GetConVarFloat(g_cvCvarList[CV_g_Rtr_precent]);
    g_RoboCapTeam = GetConVarInt(g_cvCvarList[CV_g_RoboCapTeam]);
    g_RoboCap = GetConVarInt(g_cvCvarList[CV_g_RoboCap]);
    g_RoboTeamMode = GetConVarInt(g_cvCvarList[CV_g_RoboTeamMode]);
    g_RoboStartTeam = GetConVarInt(g_cvCvarList[CV_g_RoboStartTeam]);
    g_RoboMode = GetConVarInt(g_cvCvarList[CV_g_RoboMode]);
    g_CV_flYoutuberMode = GetConVarInt(g_cvCvarList[CV_flYoutuberMode]);
    
    
    /* Convar Change Hooks */

    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_Enable].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_AprilEnable].AddChangeHook(CvarChangeHook);

    g_cvCvarList[CV_flSpyBackStabModifier].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flYoutuberMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCapTeam].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCap].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboTeamMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboStartTeam].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_Rtr_precent].AddChangeHook(CvarChangeHook);

    

    _enabledChangedForward = new GlobalForward("MM_OnEnabledChanged", ET_Ignore, Param_Cell);
    _clientResetting = new GlobalForward("MM_OnClientResetting", ET_Ignore, Param_Cell);
    _modeResetRequestedForward = new GlobalForward("MM_ModeResetRequested", ET_Ignore);

    RegAdminCmd("sm_makerobot", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_mr", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_boss_mode", Command_YT_Robot_Start, ADMFLAG_SLAY, "Sets up the team and starts the robot");
    RegAdminCmd("sm_selection_mode", Command_Robot_Selection, ADMFLAG_SLAY, "Forces selection mode");
    
    RegAdminCmd("sm_me_boss", Command_Me_Boss, ADMFLAG_SLAY, "Checks if you are a boss");
    RegAdminCmd("sm_random_robot", Command_SetRandomRobot, ADMFLAG_SLAY, "Checks if you are a boss");

    RegConsoleCmd("sm_rtr", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_rocktherobot", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_changerobot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_chngrbt", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_cr", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_bot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_robot", Command_ChangeRobot, "change your robot");


    RegConsoleCmd("sm_mount", Command_MountRobot, "get a taunt mount for your robot");
    RegConsoleCmd("sm_mt", Command_MountRobot, "get a taunt mount for your robot");
    RegConsoleCmd("sm_car", Command_MountRobot, "get a taunt mount for your robot");

    RegConsoleCmd("sm_w", Command_TauntHuman, "get a taunt mount for your robot");
    RegConsoleCmd("sm_showstats", Command_ShowStats, "Shows stats in the MvM upgrade menu");
    RegConsoleCmd("sm_showstat", Command_ShowStats, "Shows stats in the MvM upgrade menu");
    RegConsoleCmd("sm_mystat", Command_ShowStats, "Shows stats in the MvM upgrade menu");
    RegConsoleCmd("sm_mystats", Command_ShowStats, "Shows stats in the MvM upgrade menu");
//April Fools
    //RegConsoleCmd("sm_rtd", Command_RTDRobot, "become random robot");

    


    AddCommandListener(Block_Kill, "kill"); 
    AddCommandListener(Block_Kill, "explode");

    //AddCommandListener(cmd_blocker, "autoteam");
    AddCommandListener(cmd_blocker, "changeclass");
    AddCommandListener(cmd_blocker, "joinclass");
    AddCommandListener(cmd_blocker, "join_class");
    // AddCommandListener(cmd_blocker, "load_itempreset 0");
    // AddCommandListener(cmd_blocker, "load_itempreset 1");
    // AddCommandListener(cmd_blocker, "load_itempreset 2");
    AddCommandListener(cmd_blocker, "tf_respawn_on_loadoutchanges 1");


    /* Hooks */
    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_Waiting_Abouttoend, EventHookMode_Post);

    HookEvent("teamplay_point_captured", Event_Teamplay_Point_Captured, EventHookMode_Post);
    
    HookEvent("player_death", Event_Death, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    

    // HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);

    g_Volunteers = new ArrayList(ByteCountToCells(g_RoboCapTeam));

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

    // g_hGameConf = LoadGameConfigFile("bm_charge_airblast_immunity_data");

    // //IsDeflectable
    // // g_hIsDeflectable = DHookCreate(0, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsPlayerDeflectable);
    // // if(g_hIsDeflectable == null) SetFailState("Failed to setup hook for CTFPlayer::IsDeflectable!"); 

    // if(!DHookSetFromConf(g_hIsDeflectable, g_hGameConf, SDKConf_Virtual, "CTFPlayer::IsDeflectable"))
    // SetFailState("Failed to find CTFPlayer::IsDeflectable offset in the gamedata!");

    // //Finds players to hook for IsDeflectable
    // // FindAndHookPlayers();

    delete g_hGameConf;

}

// void FindAndHookPlayers()
// {
// 	for(int i = 1; i <= MaxClients+1; i++)
// 	{
// 		if(IsValidClient(i))
// 		{
// 			DHookEntity(g_hIsDeflectable, false, i);
// 		}
// 	}
// }

public void OnClientPutInServer(int client)
{
    // DHookEntity(g_hIsDeflectable, false, client);

    g_PlayerHealth[client] = -1;
}

// public MRESReturn IsPlayerDeflectable(int pThis, Handle hReturn, Handle hParams)
// {
//     //PrintToChatAll("Shouldn't airblast target %N", pThis);
//     //int clientID = GetClientOfUserId(pThis);
// 	// if(IsTank(pThis))
// 	// {
// 	// //	PrintToChatAll("Shouldn't airblast target %N", pThis);
		
//     // DHookSetReturn(hReturn, false);
    
//     // EmitSoundToAll(RESISTANCE, pThis);
    
    
//     // return MRES_Override;
// 	// }
// 	return MRES_Ignored;
// }


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GetRobotCap", Native_GetRobotCap);
    CreateNative("GetRobotCountPerTeam", Native_GetRobotCountPerTeam);
    CreateNative("SetVolunteers", Native_SetVolunteers);
    CreateNative("EnsureRobotCount", Native_EnsureRobotCount);
    CreateNative("IsEnabled", Native_IsEnabled);
    CreateNative("IsYTEnabled", Native_IsYTEnabled);
    CreateNative("IsActive", Native_IsActive);
    CreateNative("UnmakeRobot", Native_UnmakeRobot);
    CreateNative("RedrawChooseRobotMenu", Native_RedrawChooseRobotMenu);
    CreateNative("RedrawChooseRobotMenuFor", Native_RedrawChooseRobotMenuFor);
    CreateNative("SetRandomRobot", Native_SetRandomRobot);
    CreateNative("SetRobot", Native_SetRobot);
    CreateNative("ForceRobot", Native_ForceRobot);
    CreateNative("GetRobotTeam", Native_GetRobotTeam);
    CreateNative("AddPlayerHealth", Native_AddPlayerHealth);


    return APLRes_Success;
}

public void OnMapStart()
{
    g_WaitingForPlayers = true;
    g_RoundCount = 0;
    ResetMode();

    PrecacheSound(RESISTANCE);
    

}

public void ResetMode()
{
    g_cv_BlockTeamSwitch = false;
    g_BossMode = false;
    g_SpectateSelection = false;
    g_iVotes = 0;
    g_Volunteers.Clear();

    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        g_cv_Volunteered[i] = false;
        g_cv_RobotPicked[i] = "";
        g_Voted[i] = false;

    }

    int totalplayers = RoundToCeil(float(GetClientCount(false)) * g_Rtr_percent);
    g_iVotesNeeded = totalplayers;
    //g_iVotesNeeded = 6;

    Call_StartForward(_modeResetRequestedForward);
    Call_Finish();
}

public void OnClientDisconnect_Post(int client)
{
    Reset(client);
}

void Reset(int client)
{
    if(!g_cv_Volunteered[client])
        return;

    char robotName[NAMELENGTH];
    robotName = g_cv_RobotPicked[client];

    g_cv_Volunteered[client] = false;
    g_cv_RobotPicked[client] = "";
    int index = FindValueInArray(g_Volunteers, client);
    if (index >= 0)
        g_Volunteers.Erase(index);

    Call_StartForward(_clientResetting);
    Call_PushCell(client);
    Call_Finish();

    RedrawChooseRobotMenu();
    EnsureRobotCount();
}

/* Publics */

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
   // RequestFrame(RobotTeamCheck, client);

    if (IsAnyRobot(client)){ 
        
        //PrintToChatAll("%N spawned, checking if boss", client);

        if (!g_AprilEnable) RequestFrame(RobotTeamCheck, client);//dont check robo teams if april fools mode is on

        
        // else
        // {
        //     MC_PrintToChatEx(client, client, "{teamcolor}You're a robot on the robot team!");
        // }
        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}!bot{teamcolor} or {orange}change class{teamcolor} in spawn to change robot!");
        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}!mt{teamcolor} get a mount to move around faster");
        if(g_cv_bDebugMode)PrintToChatAll("%N spawned, with %i health from previous life", client, g_PlayerHealth[client]);
        //FakeClientCommand(client, "tf_respawn_on_loadoutchanges 0");
        if (g_PlayerHealth[client] > 0){
            //PrintToChatAll("Player didn't die, setting health!");
           CreateTimer(1.0, Timer_SetHealth, client);
        } 

    }

    if (!IsAnyRobot(client)){ 
        if (g_AprilEnable && g_BossMode && g_Enable)
        {
            CreateTimer(0.1, SetRandomRobot_Timer, client);
        }
    }
            // int Humans = GetTeamClientCount(g_HumanTeam);
    // if (!IsBoss(client)){
    //     SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
    //         }        // int Robots = GetTeamClientCount(g_RoboTeam);
            // PrintToChatAll("Human players %i, robot players %i", Humans, Robots);

}

// public Action Boss_check(Handle timer, any client)
// {
    
//     if (IsValidClient(client) && IsPlayerAlive(client))
//     {
//         //int clientId = GetClientUserId(client);

//         if (IsAnyRobot(client))
//         {
//             MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}!cr{teamcolor} to change robot!");

//             if (IsBoss(client))
//             {
//                // PrintToChatAll("Setting boss to %N", client);
//                 ServerCommand("sm_setbosshud #%i", client);
//             }
//             // else
//             // {
//             //     PrintToChatAll("Did not find boss on %N", client);
//             // }
//         }
//     }
// }

// bool IsBoss(client)
// {

//     char robotName[NAMELENGTH];

//     Robot robot;
//     GetRobot(client, robotName, NAMELENGTH);
//     GetRobotDefinition(robotName, robot);

    

//     if (StrEqual(robot.role,"ZBOSS"))
//     {
//         PrintToChatAll("Robot role in handler: %s", robot.role);
        
//         return true;
//     }else
//     {
//         return false;
//     }
// }




public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    
    //EmitSoundToAll("Announcer.MVM_General_Destruction",victim, 7);
    
    //EmitAmbientGameSound("Announcer.MVM_General_Destruction");
  //  EmitGameSoundToAll("Announcer.MVM_General_Destruction", victim);
    //EmitGameSoundToAll("Announcer.MVM_General_Destruction");
    //EmitGameSoundToAll("Announcer.MVM_Engineer_Teleporter_Activated");
    //PrintToChatAll("You died  %N", victim);
    //GetRobotNames();
    //EmitGameSoundToAll("Announcer.MVM_General_Destruction");
        // if (!IsAnyRobot(victim) && IsAnyRobot(attacker))
        // {
        //     //PrintChatAll("You are not a robot %N", victim);
        //     if (TF2_GetPlayerClass(victim) == TFClass_Scout){
        //         CreateTimer(6.0, Timer_Respawn, victim);
        //     }
        // }

        //Removes the robot ragdoll and causes explosion
       
        if (IsAnyRobot(victim))
        {
            
            //To deal with players using loadout switches to gain health back
            g_PlayerHealth[victim] = -1;

            CreateTimer(0.0, RemoveBody, victim);
            float position[3];
            GetEntPropVector(victim, Prop_Data, "m_vecOrigin", position);	
            int attach = CreateEntityByName("trigger_push");
            TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);

            // if (IsBoss(victim)){
            //     TE_Particle("fireSmokeExplosion2", position, _, _, attach, 1,0);	
            // }else{
                
            TE_Particle("hightower_explosion", position, _, _, attach, 1,0);	
           // EmitGameSoundToAll("Announcer.MVM_General_Destruction");
            // } 

            // }
            // KillRune();
            
        }

            // if (g_AprilEnable && g_IsAprilRTD[victim])
            // {
            //     char weapon_logname[MAX_NAME_LENGTH];
                
            //     GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));

            //     //PrintToChatAll("Weapon_Logname was %s", weapon_logname);
            //     if (StrEqual(weapon_logname, "player", true) || StrEqual(weapon_logname, "trigger", true) || StrEqual(weapon_logname, "world", true))
            //     {
            //      //PrintToChatAll("Logname %s, STILL RTD", weapon_logname);
            //         g_IsAprilRTD[victim] = true;
                    
            //     }else
            //     {
            //         //PrintToChatAll("Logname %s, NO LONGER RTD", weapon_logname);
            //         g_IsAprilRTD[victim] = false;
            //     }
                
            // }
//        fireSmokeExplosion//
// 
        g_GoingToDie[victim] = false;
}




public Action RemoveBody(Handle timer, any client)
{

    if (HasEntProp(client, Prop_Send, "m_hRagdoll"))
    {
        int BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
        if(IsValidEdict(BodyRagdoll))
        {
            AcceptEntityInput(BodyRagdoll, "kill");
             
        }
    }
}

// public Action Timer_Respawn(Handle timer, any client)
// {
//     //PrintToChatAll("Timebomb: %i", g_TimeBombTime[client]);
// 	if (IsValidClient(client) && !IsPlayerAlive(client))
//     {
//         TF2_RespawnPlayer(client);
//         //PrintHintText(client,"You have instant respawn as scout");
//     }
// }

public Action SetRandomRobot_Timer(Handle timer, any client)
{

    if (!IsAnyRobot(client))
    {
        Internal_SetRandomRobot(client);
    }
}
// 

// 
// bool b_TankCheckClamp = false;

// public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
// {

//     int client = GetClientOfUserId(GetEventInt(event, "userid"));
//     if (IsTank(client) && !b_TankCheckClamp)
//     {
//         CreateTimer(3.0, Timer_TankCheck);
//         b_TankCheckClamp = true;
//     }
// }

// public Action Timer_TankCheck(Handle timer)
// {
//     int TankCount = 0;

//     for(int i = 1; i <= MaxClients; i++)
//     {
//         if (IsTank(i))
//         {
//             if(g_cv_bDebugMode)PrintToChatAll("%N was a tank", i);
//             TankCount++;
//         }
//     }

//     if (TankCount == 1)
//     {
//         EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Spawn");
//     }

//     if (TankCount == 2)
//     {
//         EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Another");
//     }

//     if (TankCount > 2)
//     {
//         EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Multiple");
//     }
    

//     if(g_cv_bDebugMode)PrintToChatAll("Tank count was %i", TankCount);
//     b_TankCheckClamp = false;
// }


public Action Timer_Regen(Handle timer, any client)
{
    TF2_RegeneratePlayer(client);
}

public Action Timer_SetHealth(Handle timer, any client)
{
    //PrintToChatAll("Timebomb: %i", g_TimeBombTime[client]);
        int currenthealth = GetClientHealth(client);
        if (g_cv_bDebugMode)PrintToChatAll("Current health %i", currenthealth);
        if (g_cv_bDebugMode)PrintToChatAll("g_Player health for %N was %i", client, g_PlayerHealth[client]);
        if (g_PlayerHealth[client] < currenthealth && g_PlayerHealth[client] != -1)
        { 
        TF2_SetHealth(client, g_PlayerHealth[client]);

        }
        //PrintHintText(client,"You have instant respawn as scout");
}

public Action Event_Waiting_Abouttoend(Event event, const char[] name, bool dontBroadcast)
{


    if(g_Enable && g_RoundCount == 0){
     //   PrintToChatAll("==Waiting for other players==");
        g_RoundCount++;
        g_WaitingForPlayers = true;

        
    }else if(g_Enable && g_RoundCount == 1 && !g_BossMode){
       // PrintToChatAll("== Not waiting for players !rtr available!");
        g_WaitingForPlayers = false;
        g_RoundCount++;

    
        Command_Robot_Selection(1, 1);
        //MC_PrintToChatAll("[{orange}SM{default}]{orange} Type !rtr to vote to start Manned Machines");
        

    }

    int totalplayers = RoundToCeil(float(GetClientCount(false)) * g_Rtr_percent);
    g_iVotesNeeded = totalplayers;

   // PrintToChatAll("Total players: %i", totalplayers);
  //  PrintToChatAll("Total players: %i", GetClientCount(false));
     //view_as<TFTeam>(g_HumanTeam) 
     
    
    //g_iVotesNeeded = int(ivotes_needed);

    // if (g_AprilEnable && g_Enable && g_RoundCount == 1 && !g_BossMode){
    //     CreateTimer(0.5, MakeRobotsApril);     
    // }
    
}

// public Action MakeRobotsApril(Handle timer)
// {
//     Command_YT_Robot_Start(1, true);
// }

public Action Event_Teamplay_Point_Captured(Event event, char[] name, bool dontBroadcast)
{
    //int team = GetEventInt(event, "team");
    //PrintToChatAll("Team wws %i", team);

    if (g_Enable && g_BossMode)
    {
        AddTeamCoins(TFTeam_Blue, 1);
        AddTeamCoins(TFTeam_Red, 1);
        
    }

}

public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{


    if (g_Enable && !g_AprilEnable){

        MC_PrintToChatAll("{Green}Type {orange}!info{Green} to see more info about this gamemode");
        MC_PrintToChatAll("{Green}Visit {orange}bmod.tf/mannedmachines {Green} To get the assetpack to get the most out of this mode");

        if (GameRules_GetProp("m_bSwitchedTeamsThisRound"))
        {
            if(g_cv_bDebugMode) PrintToChatAll("Teamswitch detected!");

            ResetCoins();

            switch(g_RoboTeam)
            {
                
                case RED:
                {
                    if(g_cv_bDebugMode)PrintToChatAll("RoboTeam was RED changing to BLUE...");
                    g_RoboTeam = BLUE;
                    g_HumanTeam = RED;
                }
                case BLUE:
                {
                    if(g_cv_bDebugMode)PrintToChatAll("RoboTeam was BLU changing to RED...");
                    g_RoboTeam = RED;
                    g_HumanTeam = BLUE;
                }
            }
            
        }
    }

    return Plugin_Continue;
}

public MRESReturn OnRegenerate(int pThis, Handle hReturn, Handle hParams)
{
    //Activates when doing OnRegenerate (touchihng resupply locker) and then ignoring it if you are a boss
    

    if(isMiniBoss(pThis) && IsPlayerAlive(pThis)){
        //PrintToChatAll("1");
    PrintCenterText(pThis,"Error: Unable to use human lockers");
    // int args;
    // Command_ShowStats(pThis, 1);
    //sets the robot health when touch
	// int maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, pThis);
    //     SetEntityHealth(pThis, maxhealth);
    //TF2_AddCondition(pThis, TFCond_HalloweenQuickHeal, 10.0);

    return MRES_Supercede; 
    }

    return MRES_Ignored;
}

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
    // if(convar == g_cvCvarList[CV_flSpyBackStabModifier])
    //     g_CV_flSpyBackStabModifier = StringToFloat(sNewValue);
    if(convar == g_cvCvarList[CV_flYoutuberMode])
        g_CV_flYoutuberMode = StringToInt(sNewValue);
        
    if(convar == g_cvCvarList[CV_g_Rtr_precent])
        g_Rtr_percent = StringToFloat(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCap])
        g_RoboCap = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCapTeam])
    {   
        g_RoboCapTeam = StringToInt(sNewValue);
        if (g_Enable) PrintToChatAll("Current Robots: %i", g_RoboCapTeam);
    }

    if(convar == g_cvCvarList[CV_g_RoboTeamMode])
        g_RoboTeamMode = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboMode])
        g_RoboMode = StringToInt(sNewValue); 

    if(convar == g_cvCvarList[CV_g_Enable])
    {
        g_Enable = StringToInt(sNewValue); 
        
        Call_StartForward(_enabledChangedForward);
        Call_PushCell(g_Enable);
        Call_Finish();
    }

    if(convar == g_cvCvarList[CV_g_AprilEnable])
    {
        g_AprilEnable = StringToInt(sNewValue); 
    }
}

// public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
// {

//     if (IsValidClient(attacker) && IsValidClient(victim))
//     {
//         //Damage bonus is not active, no need to do anything

//     }
//     return Plugin_Continue;
// }

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;


    if (IsAnyRobot(victim))
    {      
        RequestFrame(Set_g_PlayerHealth, victim);        
        
    }

    if (g_f_Damage_Bonus != -1.0)
    {
        if(!IsAnyRobot(attacker) && IsAnyRobot(victim))
        {
            // PrintToChatAll("Damage before is %f, g_damagebonus was %f", damage, g_f_Damage_Bonus);
            damage *= g_f_Damage_Bonus;
            // PrintToChatAll("Damage after is %f", damage);
            return Plugin_Changed;
        }
    }


    return Plugin_Continue;
}


public any Native_AddPlayerHealth(Handle plugin, int numParam)
{

    //int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false

    int iClient = GetNativeCell(1);
    int iAdd = GetNativeCell(2);
    int iOverheal = GetNativeCell(3);
    bool bStaticMax = GetNativeCell(4);
    bool bShowHealthGain = GetNativeCell(5);
    
    int iHealth = GetClientHealth(iClient);

    
    int iNewHealth = iHealth + iAdd;
    int iMax = bStaticMax ? iOverheal : GetEntProp(iClient, Prop_Data, "m_iMaxHealth") + iOverheal;

    // PrintToChatAll("Ihealth was: %i iAdd was: %i, iMax was: %i", iHealth, iAdd, iMax);
    if (iNewHealth <= iMax)
    {
        //iNewHealth = min(iNewHealth, iMax);
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


public any Native_GetRobotTeam(Handle plugin, int numParams)
{
    return g_RoboTeam;
}

void RobotTeamCheck(int client)
{
    if(IsClientInGame(client))
    {
        int iTeam = GetClientTeam(client);
        if (iTeam != g_RoboTeam)
        {
            if(g_cv_bDebugMode)MC_PrintToChatEx(client, client, "{teamcolor}You're a robot not on the robot team!");
               
            TrashRobot(client);
            CreateTimer(0.5, Timer_Regen, client);       
        }
    }
}

void Set_g_PlayerHealth(int victim)
{
    int health = GetClientHealth(victim);
    if(g_cv_bDebugMode)PrintToChatAll("Health was %i for %N", health, victim);

    g_PlayerHealth[victim] = health;
    
    if (IsPlayerAlive(victim)){
        if(g_cv_bDebugMode)PrintToChatAll("Setting health for %N to %i", victim, g_PlayerHealth[victim]);
    }else{
        g_PlayerHealth[victim] = -1;
        if(g_cv_bDebugMode)PrintToChatAll("%N is dead, setting g_PlayerHealth to -1", victim);

    }
}


public void MM_OnRestrictionChanged(char name[NAMELENGTH])
{
    SMLogTag(SML_VERBOSE, "MM_OnRestrictionChanged called at %i", GetTime());

    RedrawChooseRobotMenu();
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
    // //Remove the boss healthbar when changing robots, boss health bar is created on boss spawn
    // UnSetBossHealth(client);

    CreateRobot(name, client, target);
    
    SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 1);
    
    return Plugin_Handled;
}

public Action Command_SetRandomRobot(int client, int args)
{
    Internal_SetRandomRobot(client);
    
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

    if (g_AprilEnable && g_Enable){
        Command_YT_Robot_Start(1, true);
           
    }

    if (g_Enable && !g_AprilEnable){
    ServerCommand("mp_forceautoteam  0");
            
    ServerCommand("mp_teams_unbalance_limit 0");
    ServerCommand("sm_cvar tf_dropped_weapon_lifetime 0");
    
    ServerCommand("mp_autoteambalance 0");
    ServerCommand("mp_scrambleteams_auto 0");
    ServerCommand("mp_forceautoteam  0");

/*     for(int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && IsClientInGame(i))
        {
            ChangeClientTeam(i, SPECTATE);
        }
    } */
 //   g_BossMode = true;
    g_cv_BlockTeamSwitch = true;
    //g_SpectateSelection = false;

    StartAutomaticVolunteerVote();
    }


}

// intercept and block client jointeam command if required
public Action Command_YT_Robot_Start(int client, int args)
{

    if (g_Enable  && !g_AprilEnable)
    {

        if(!g_BossMode)
        {
            g_cv_BlockTeamSwitch = true;
            g_SpectateSelection = false;
            PrintCenterTextAll("Starting Manned Machines mode!");
            
            ServerCommand("mp_forceautoteam 0");
            ServerCommand("mp_teams_unbalance_limit 0");
            ServerCommand("sm_cvar tf_dropped_weapon_lifetime 0");
            ServerCommand("mp_restartgame 5");
            ServerCommand("mp_autoteambalance 0");
            ServerCommand("mp_scrambleteams_auto 0");
            ServerCommand("mp_forceautoteam  0");
            

            //Randomly set which team is roboteam and humanteam
            switch(g_RoboStartTeam)
            {
                case 0://Robots starts as blue
                {
                    g_RoboTeam = BLUE;
                    g_HumanTeam = RED;
                }
                case 1://Robots starts as random
                {
                    int RandomTeam = GetRandomInt(1, 2);
                // PrintToChatAll("Randomteam was %i", RandomTeam);
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
                }
                case 2://Robots starts as red
                {
                        g_RoboTeam = RED;
                        g_HumanTeam = BLUE;
                }
            }


            g_BossMode = true;
            if(g_cv_bDebugMode) PrintToChatAll("Robots will be Team %i", g_RoboTeam);
            if(g_cv_bDebugMode) PrintToChatAll("Humans will be Team %i", g_HumanTeam);
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
                ServerCommand("sm_berobot_dynamicRobotCount_enable 0");

            }
            else
            {


                //Everyone is in spectate

                //ServerCommand("sm_ct @all spectate");

                //Make volunteer robots go here
                for(int i = 0; i <= MaxClients; i++)
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
                                //PrintToChatAll("%N is on robot team, which is %i", i, g_RoboTeam);
                                // ServerCommand("sm_begps #%i", playerID);
                                //ServerCommand("sm_ct #%i %i", playerID, g_RoboTeam);
                            //    TF2_RespawnPlayer(i);
                            
                                MoveToRobots(i);
                                
                            }
                            else
                            {
                                PrintToChat(i, "You are on the Human team");
                            //  PrintToChatAll("%N is on robot team, which is %i",i, g_HumanTeam);
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
    else if (g_Enable  && g_AprilEnable)
    {
        //ARPIL FOOLS CODE WHERE EVERYONE IS A ROBOT!
        // PrintCenterTextAll("Everyone can be a robot, who cares.");
        g_BossMode = true;
        for(int i = 0; i <= MaxClients; i++)
        {

            if(IsValidClient(i))
            {
                if(IsClientInGame(i))
                {
                    Internal_SetRandomRobot(i);
                }
            }
        }
    }
    else
    {
        PrintCenterText(client, "Manned Machines is not enabled. Enable with sm_mm_enable 1");
    }
}

public Action Command_RoboVote(int client, int args)
{
    if (g_Enable)
    {
        if (g_WaitingForPlayers)
        {
            MC_PrintToChatEx(client, client,"[{orange}SM{default}]{teamcolor} Still waiting for players, try again once waiting for players is over");
            return;
        }
        //If boss mode is already active
        //PrintToChatAll("%i",CV_g_RoboCapTeam);

        if (g_BossMode)
        {
            MC_PrintToChatEx(client, client,"[{orange}SM{default}]{teamcolor} Giant Boss Mode is already active");
            return;
        }

        if (g_CV_flYoutuberMode)
        {
            MC_PrintToChatEx(client, client,"[{orange}SM{default}]{teamcolor} Giant Boss Mode is already active with Youtubers");
            return;
        }

        if (g_RoboMode == 1)
        {
            MC_PrintToChatEx(client, client,"[{orange}SM{default}]{teamcolor} Voting is disabled. Use {green}!join{green} to become a robot, game starts when enough volunteers are reached");
            return;
        }
        
        //If the client has already voted
        if(g_Voted[client])
        {
            MC_PrintToChat(client,"{orange}You have already voted");
            return;
        }

        g_iVotes++;
        //g_Voted[client] = true;
        MC_PrintToChatAllEx(client, "[{orange}SM{default}] {teamcolor}%N {default}wants to start Giant Robot Boss mode. [{orange}%i{default}/{orange}%i {default}more votes required]", client, g_iVotes, g_iVotesNeeded);

        //Start the robo vote
        if(g_iVotes >= g_iVotesNeeded)
        {
            Command_Robot_Selection(client, args);
        }
    }
    else
    {
        MC_PrintToChatAllEx(client, "[{orange}SM{default}] {teamcolor}%N {default}Manned Machines mode is {red}disabled", client);
    }

    return;

}

public Action Command_ChangeRobot(int client, int args)
{

    if (g_AprilEnable && !g_Enable)
    {
        PrintCenterText(client, "You can't change robot you fool!");
        return Plugin_Handled;
    }

    if (g_cv_bDebugMode)PrintToChatAll("Got to 1");

    if (!TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client, "You can only change robot when in spawn or dead");
        return Plugin_Handled;
    }
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


    //For the times when someone is not a robot, but is on the robot team.
    int iTeam = GetClientTeam(client);
    
    if (g_cv_bDebugMode)PrintToChatAll("Client team was %i:", iTeam);
    if (g_cv_bDebugMode)PrintToChatAll("Robogteam was: %i", g_RoboTeam);

    if (iTeam == g_RoboTeam || g_AprilEnable){
    if (g_cv_bDebugMode)PrintToChatAll("Attempting to allow menu selection for %N", client);
    
    // g_PlayerHealth[client] = -1;

    SetClientRepicking(client, true);
    ChooseRobot(client);
    
    return Plugin_Handled;
    }

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

        g_PlayerHealth[client] = -1;
        g_cv_Volunteered[targetClientId] = true;
        SetClientRepicking(targetClientId, true);
        ChooseRobot(targetClientId);
    }

    return Plugin_Handled;
}

public Action Command_ShowStats(int client, int args)
{
    // SetEntProp(client, Prop_Send, "m_bInUpgradeZone", false);
    SetEntProp(client, Prop_Send, "m_bInUpgradeZone", true);
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	
	char section[32];
	if (kv.GetSectionName(section, sizeof(section)))
	{
        // PrintToChatAll("%s",section);
			if (!strcmp(section, "MvM_UpgradesDone"))
			{		
				CancelClientMenu(client);
				SetEntProp(client, Prop_Send, "m_bInUpgradeZone", false);					
		}
	}
	return Plugin_Continue;
}






public Action Command_TauntHuman(int client, int args)
{

    if (!g_Enable)
    {
        return Plugin_Handled;
    }

    if (!IsAnyRobot(client))
    {
        int playerID = GetClientUserId(client);
        int taunt = 1157;
        // int random = GetRandomInt(1,2);
        // switch (random)
        // {
        //     case 1:
        //     {
        //         taunt = 1172; //victory lap
        //     }
        //     case 2:
        //     {
        //         taunt = 30672; // zoomin broom
        //     }
        // }

        ServerCommand("sm_tauntem #%d %i", playerID, taunt);
    }

}

public Action Command_MountRobot(int client, int args)
{

    if (!g_Enable)
    {
        return Plugin_Handled;
    }

    if (IsAnyRobot(client))
    {
        int playerID = GetClientUserId(client);
        int taunt = 1172;
        // int random = GetRandomInt(1,2);
        // switch (random)
        // {
        //     case 1:
        //     {
        //         taunt = 1172; //victory lap
        //     }
        //     case 2:
        //     {
        //         taunt = 30672; // zoomin broom
        //     }
        // }

        ServerCommand("sm_tauntem #%d %i", playerID, taunt);
    }

    

    return Plugin_Handled;
}


public Action MakeRobotTargets(int client, char target[32], bool volunteering)
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
        MakeRobot(targetClientId, volunteering);
    }

    return Plugin_Handled;
}

public Action MakeRobot(int client, bool volunteering)
{
    if (!g_Enable)
    {
        MM_PrintToChat(client, "Unable to make robot, robot-mode is not enabled");
        SMLogTag(SML_VERBOSE, "MakeRobot cancled for %L, because robot-mode is not enabled", client);
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
            if(!g_AprilEnable)MoveToRobots(client);
        }
    }
    else if(!volunteering && g_cv_Volunteered[client]) //Remove from volunteer list
    {
        SMLogTag(SML_VERBOSE, "volunteer-state changed to false for %L", client);
    //          if(!TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    // {
    //     PrintCenterText(client, "You have to be in spawn or dead to select a robot");
    //     return;
    // }
        SetRobot(g_cv_RobotPicked[client], client);
        Reset(client);
        TF2_SwapTeamAndRespawnNoMsg(client, g_HumanTeam);

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
        //MC_PrintToChatExAll
        //MC_PrintToChatAllEx(client, "{orange}The max amount of %i volunteers has been reached, use {green}!rtr {orange} to start the mode", g_RoboCapTeam);
        if(!g_BossMode)Command_YT_Robot_Start(client, true);

        g_Volunteers.Resize(g_RoboCapTeam);
       //g_BossMode = true;
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

void MoveToRobots(int client)
{    
    if(!g_AprilEnable)TF2_SwapTeamAndRespawnNoMsg(client, g_RoboTeam);
    
    RequestFrame(Internal_SetRandomRobot,client);
    // CreateTimer(0.5, SetRandomRobot_Timer, client);
    // SetClientRepicking(client, false);
    // ChooseRobot(client);
}

Action ChooseRobot(int client, bool redrawing = false)
{

    //Setting of bots is handled elsewhere
    // if (IsFakeClient(client))
    // {
    //     Internal_SetRandomRobot(client);
    //     return Plugin_Handled;
    // }

    Menu_RobotSelection(client, redrawing);
    return Plugin_Handled;
}

void Internal_SetRandomRobot(int client)
{
    if (!g_Enable)
        return;

    ArrayList robotNames = GetRobotNames();
    if (robotNames.Length <= 0)
    {
        SMLogTag(SML_VERBOSE, "no robots were found. %L will not be turned into a robot.", client);
        return;
    }

    char robotname[NAMELENGTH];  
  //   PrintToChatAll("===");
    for (;;)  
    {
        int i = GetRandomInt(0, robotNames.Length -1);
        //SMLogTag(SML_VERBOSE, "picked random %i (between %i and %i)", i, 0, robotNames.Length -1);

        robotNames.GetString(i, robotname, sizeof(robotname));

        int count = GetRobotCount(robotname);
        if (count < g_RoboCap)
        {
            Robot item;
            
            GetRobotDefinition(robotname, item);
           
        //    PrintToChatAll("Trying: Robot name was %s and difficulty was %i", robotname, item.difficulty);
            //Checks if the robit is Enable and not played by anyone (active), and that the difficulty of the robot is easy or undefined
            if (item.restrictions.IsEnabled() && !item.restrictions.IsActive() && item.difficulty == ROBOT_DIFFICULTY_EASY || item.difficulty == ROBOT_DIFFICULTY_UNDEFINED)
            {
                if(g_cv_bDebugMode)PrintToChatAll("For %N, the robot %s, was enabled, index was: %i", client, robotname, i);
                
         //       PrintToChatAll("BREAKING: Robot name was %s and difficulty was %i", robotname, item.difficulty);
              //  SMLogTag(SML_VERBOSE, "For %N, the robot %s, was enabled & not active, index was: %i", client, robotname, i);
                // Internal_SetRandomRobot(client);
                
                break;
            }else{

                // if(g_cv_bDebugMode);
           //     PrintToChatAll("NO BREAK: For %N, the robot %s, was not enabled & active, index was: %i", client, robotname, i);
                //SMLogTag(SML_VERBOSE, "For %N, the robot %s, was not enabled & active, index was: %i", client, robotname, i);
            }


            

        }        

        robotNames.Erase(i);
        if (robotNames.Length <= 0)
        {
            if(g_cv_bDebugMode)PrintToChatAll("no robot left to choose. %N will not be turned into a robot.", client);
            SMLogTag(SML_VERBOSE, "no robot left to choose. %L will not be turned into a robot.", client);
            return;
        }
    }

    //SMLogTag(SML_VERBOSE, "setting bot %L to be robot '%s'", client, robotname);
    if(g_cv_bDebugMode)PrintToChatAll("setting bot %L to be robot '%s'", client, robotname);
  //  PrintToChatAll("%N: setting bot %L to be robot '%s'",client,  client, robotname);
  //  PrintToChatAll("===");
    ForceRobot(robotname, client);
}


// void SetRandomRobotRTD(int client)
// {
//     // if (!g_Enable)
//     //     return;

//     ArrayList robotNames = GetRobotNames();
//     if (robotNames.Length <= 0)
//     {
//         SMLogTag(SML_VERBOSE, "no robots were found. %L will not be turned into a robot.", client);
//         return;
//     }

//     char robotname[NAMELENGTH];  
//     for (;;)  
//     {
//         int i = GetRandomInt(0, robotNames.Length -1);
//         //SMLogTag(SML_VERBOSE, "picked random %i (between %i and %i)", i, 0, robotNames.Length -1);

//         robotNames.GetString(i, robotname, sizeof(robotname));

//         int count = GetRobotCount(robotname);
//         if (count < g_RoboCap)
//         {
//             Robot item;
            
//             GetRobotDefinition(robotname, item);
//             if (item.restrictions.IsEnabled() && !item.restrictions.IsActive())
//             {
//                 if(g_cv_bDebugMode)PrintToChatAll("For %N, the robot %s, was enabled, index was: %i", client, robotname, i);

//                 SMLogTag(SML_VERBOSE, "For %N, the robot %s, was enabled & not active, index was: %i", client, robotname, i);
//                 //Internal_SetRandomRobot(client);
//                 break;
//             }else{

//                 if(g_cv_bDebugMode)PrintToChatAll("For %N, the robot %s, was not enabled & active, index was: %i", client, robotname, i);

//                 SMLogTag(SML_VERBOSE, "For %N, the robot %s, was not enabled & active, index was: %i", client, robotname, i);
//             }
//         }        

//         robotNames.Erase(i);
//         if (robotNames.Length <= 0)
//         {
//             if(g_cv_bDebugMode)PrintToChatAll("no robot left to choose. %N will not be turned into a robot.", client);
//             SMLogTag(SML_VERBOSE, "no robot left to choose. %L will not be turned into a robot.", client);
//             return;
//         }
//     }

//     SMLogTag(SML_VERBOSE, "setting bot %L to be robot '%s'", client, robotname);
//     if(g_cv_bDebugMode)PrintToChatAll("setting bot %L to be robot '%s'", client, robotname);
//     SetRobot(robotname, client);
// }

any Native_SetRandomRobot(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    Internal_SetRandomRobot(client);
}

any Native_SetRobot(Handle plugin, int numParams)
{
    char robotname[NAMELENGTH];
    GetNativeString(1, robotname, sizeof(robotname));
    int client = GetNativeCell(2);

    if(!TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client, "You have to be in spawn or dead to select a robot");
        //MC_PrintToChatEx(client, client, "{orange}!cr{teamcolor} or {orange}change class{teamcolor} in spawn to change robot!");
        //MC_PrintToChatAllEx(client, "{orange} %N was not alive and in spawn");
        SetClientRepicking(client, false);
        return;
    }

    Internal_SetRobot(robotname, client);
}

any Native_ForceRobot(Handle plugin, int numParams)
{
    char robotname[NAMELENGTH];
    GetNativeString(1, robotname, sizeof(robotname));
    int client = GetNativeCell(2);

    Internal_SetRobot(robotname, client);
}

void Internal_SetRobot(char robotname[NAMELENGTH], int client)
{
    int error = CreateRobot(robotname, client, "");
    if (error != 0)
    {
        RedrawChooseRobotMenuFor(client);
        return;
    }

    g_cv_RobotPicked[client] = robotname;
    SetClientRepicking(client, false);

    RedrawChooseRobotMenu();
}

any Native_RedrawChooseRobotMenu(Handle plugin, int numParams)
{
    for(int i = 0; i <= MaxClients; i++)
    {
        RedrawChooseRobotMenuFor(i);
    }
}

any Native_RedrawChooseRobotMenuFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    
    if(!IsValidClient(clientId))
    {
        SMLogTag(SML_VERBOSE, "not redrawing ChooseRobotMenu for client %i, because client is not valid", clientId);
        return;
    }

    if(g_cv_RobotPicked[clientId][0] != '\0' && !IsRepicking(clientId)) //don't open menu for players, who have already picked a robot
    {
        SMLogTag(SML_VERBOSE, "not redrawing ChooseRobotMenu for %L, because client is already robot and not repicking", clientId);
        return;
    }

    if(!IsClientInGame(clientId))
    {
        SMLogTag(SML_VERBOSE, "not redrawing ChooseRobotMenu for %L, because client is not in game", clientId);
        return;
    }

    if(IsFakeClient(clientId))
    {
        SMLogTag(SML_VERBOSE, "not redrawing ChooseRobotMenu for %L, because client is fake", clientId);
        return;
    }

    if(!g_cv_Volunteered[clientId])
    {
        SMLogTag(SML_VERBOSE, "not redrawing ChooseRobotMenu for %L, because client is not a robot", clientId);
        return;
    }

    SMLogTag(SML_VERBOSE, "redrawing ChooseRobotMenu for %L", clientId);
    ChooseRobot(clientId, true);
}

public Action OnClientCommand(int client, int args)
{
    char cmd[16];

    /* Get the argument */
    GetCmdArg(0, cmd, sizeof(cmd));
    if(strcmp(cmd, "jointeam", true) == 0 || strcmp(cmd, "autoteam", true) == 0 || strcmp(cmd, "spectate", true) == 0)
    {
        TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
        
        //PrintToChatAll("Join team triggered. %N's team was %i", client, iTeam);

        if (g_SpectateSelection)
        {
            ChangeClientTeam(client, SPECTATE);
            if(g_cv_bDebugMode) PrintToChatAll("Moving to spectate %N", client);
            return Plugin_Handled;
        }

        if(g_cv_BlockTeamSwitch)
        {
            PrintCenterText(client, "Boss mode is activated: Teams are locked");
            if(g_cv_bDebugMode) PrintToChatAll("Teamswitch is %b ", g_cv_BlockTeamSwitch);
            //If someone joins while the event is going, set correct player team

            if(iTeam == TFTeam_Unassigned || iTeam == TFTeam_Spectator)
            {

                // if(g_CV_flYoutuberMode){
                //     CheckIfYT();
                //     return Plugin_Handled;
                // } 

                //Puts players in the correct team
                if(!IsAnyRobot(client)){
                    if(g_cv_bDebugMode) PrintToChatAll("Was not a robot %N", client);
                    ChangeClientTeam(client, g_HumanTeam);

                    //Set as random class when trying to pick a team
                    int irandomclass = GetRandomInt(1, 9);
                    TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
                    TF2_RespawnPlayer(client);
                    //ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
                }
                    

                if(IsAnyRobot(client))
                {
                    if(g_cv_bDebugMode) PrintToChatAll("Was a robot %N", client);
                    ChangeClientTeam(client, g_RoboTeam);
                    //ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
                }
                    

                //Sets you as random class when you join when boss mode is active
                // int irandomclass = GetRandomInt(1, 9);
                // TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
                // TF2_RespawnPlayer(client);
            }
            return Plugin_Handled;
        }
    }

    //  if(strcmp(cmd, "kill", true) == 0)
    // {
    //     PrintCenterText(client, "kill");
    //     if(g_cv_bDebugMode) PrintToChatAll("attempted to explode %N", client);
    //     return Plugin_Handled;
    // }
    
    //  if(strcmp(cmd, "explode", true) == 0)
    // {
    //     PrintCenterText(client, "explode");
    //     if(g_cv_bDebugMode) PrintToChatAll("attempted to kill %N", client);
    //     return Plugin_Handled;
    // }

    //PrintToChatAll("Team switch trigger");

    return Plugin_Continue;
}

public Action Block_Kill(int client, const char[] command, int args){


    if (!IsAnyRobot(client) && g_BossMode && !TF2Spawn_IsClientInSpawn(client))
    {
      //  PrintToChatAll("BLOCKED KILL on %N", client);
       // int playerID = GetClientUserId(client);
        if(!g_GoingToDie[client]){

        //PrintCenterText(client, "You will die in 10 seconds");
        g_TimeBombTime[client] = 5;
        CreateTimer(1.0, Timer_Kill, client, TIMER_REPEAT);
        
        g_GoingToDie[client] = true;
        }else
        {
            g_GoingToDie[client] = false;
        }
       // TimeBombPlayer(client, 9000, false);
        //ServerCommand("sm_timebomb #%d", playerID);
        return Plugin_Handled; 
    }else
    {
        return Plugin_Continue;
    }
    
}

public Action Timer_Kill(Handle timer, any client)
{
    //PrintToChatAll("Timebomb: %i", g_TimeBombTime[client]);
	if (IsValidClient(client) && IsPlayerAlive(client))
    {
        g_TimeBombTime[client]--;
	
        if (g_TimeBombTime[client] > 0 && g_GoingToDie[client])
        {
            PrintCenterText(client, "Death in %i", g_TimeBombTime[client]);
            
        }else
        {
            if (g_GoingToDie[client])
            { 
                PrintCenterText(client, "You are dead");
                ForcePlayerSuicide(client);
                g_GoingToDie[client] = false;
                KillTimer(timer);
            }else{
                PrintCenterText(client, "Cancelled death");
                KillTimer(timer);
            }
        }

        
    }
	
}

public Action cmd_blocker(int client, const char[] command, int argc)
{	
    //PrintToChatAll("TEST");

    

    if (!IsAnyRobot(client) && g_BossMode && !TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client,"You can only change class in spawn");
        
        return Plugin_Handled;
    }
    else if (IsAnyRobot(client) && g_BossMode && IsPlayerAlive(client))
    {
        PrintCenterText(client,"Unable to change class. Use !bot to change robot or !stuck if you are stuck");

        SetClientRepicking(client, true);
        ChooseRobot(client);
        
        return Plugin_Handled;

    }

    // if (g_AprilEnable && IsAnyRobot(client))
    // {
    //     PrintCenterText(client,"You can't change class you fool. Die and reroll stupid!");
    //     return Plugin_Handled;
    // }
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
public any Native_IsEnabled(Handle plugin, int numParams)
{
    return g_Enable;
}

public any Native_IsYTEnabled(Handle plugin, int numParams)
{
    return g_CV_flYoutuberMode;
}

public any Native_IsActive(Handle plugin, int numParams)
{
    return g_BossMode;
}

public any Native_GetRobotCountPerTeam(Handle plugin, int numParams)
{
    return g_RoboCapTeam;
}

int Native_SetVolunteers(Handle plugin, int numParams)
{
    int length = GetNativeCell(2);
    int[] volunteers = new int[length];
    GetNativeArray(1, volunteers, length);

    for(int i = 0; i < length; i++)
    {
        int clientId = GetClientOfUserId(volunteers[i]);
        MakeRobot(clientId, true);
    }
}
bool g_b_changed_dmg = false;
bool g_b_broadcast_msg = false;

int Native_EnsureRobotCount(Handle plugin, int numParams)
{
    if (!g_BossMode)
        return;



    while (g_Volunteers.Length == g_RoboCapTeam)
    {
        //Only type this one time when damage value is restarted
      if (g_f_Damage_Bonus == -1.0 && (g_b_changed_dmg || !g_b_broadcast_msg))
      {
        PrintCenterTextAll("Alert: Robot Power Restored\nRobots take normal damage");
        g_b_broadcast_msg = true;
      } 
      

        CalculateDamageModifier(dmg_method_on_target);
        if(g_f_Damage_Bonus != -1.0 && (g_b_changed_dmg || !g_b_broadcast_msg))PrintCenterTextAll("Alert: Low Power!\nRobots take %.0f %% more damage!", (g_f_Damage_Bonus-1.0)*100);
        g_b_broadcast_msg = true;
        break;
    }



    while (g_Volunteers.Length < g_RoboCapTeam)
    {
        bool success = AddRandomVolunteer();
        SMLogTag(SML_VERBOSE, "adding random volunteer succcess: %b", success);
        
        CalculateDamageModifier(dmg_method_off_target);
        // PrintToChatAll("Previous %f, g_f_dmg %f", g_f_previous_dmg_bonus, g_f_Damage_Bonus);

        if((g_b_changed_dmg || !g_b_broadcast_msg) && g_f_Damage_Bonus != -1.0)PrintCenterTextAll("Alert: High Power!\nRobots take %.0f %% less damage!", (g_f_Damage_Bonus-1.0)*100);
        g_b_broadcast_msg = true;
        if (!success)
            break;
    }


    while (g_Volunteers.Length > g_RoboCapTeam)
    {
        CalculateDamageModifier(dmg_method_off_target);
        
        if((g_b_changed_dmg || !g_b_broadcast_msg) && g_f_Damage_Bonus != -1.0)PrintCenterTextAll("Alert v4: Low Power!\nRobots take %.0f %% more damage!", (g_f_Damage_Bonus-1.0)*100);
        g_b_broadcast_msg = true;
        break;
    }



}

void CalculateDamageModifier(int dmg_method)
{
        int CurrentRobots = GetCurrentRobotCount();
        int CurrentHumans = GetCurrentHumanCount();

        ConVar drobotcount = FindConVar("sm_berobot_dynamicRobotCount_humansPerRobot");
        float ratio = drobotcount.FloatValue;

        // Parameters for the exp_decay function
        // float a_value = 1.25;  // Adjust as needed
        // float b_value = 0.2;  // Adjust as needed
        int TargetHumans = RoundToFloor(float(CurrentRobots) * ratio) - CurrentRobots;
        int MissingHumans = TargetHumans - CurrentHumans;

        if (dmg_method == dmg_method_off_target)
        {
            

            g_f_Damage_Bonus = damage_bonus(float(MissingHumans));
           // PrintToChatAll("Missing Humans %i DMG BONUS v1 %f",MissingHumans,g_f_Damage_Bonus);
            //g_f_Damage_Bonus = float(TargetHumans)/float(CurrentHumans); 
        }
        else if (dmg_method == dmg_method_on_target)
        {

            float unrounded = (CurrentRobots+CurrentHumans)/ratio;
            int rounded = RoundToCeil((CurrentRobots+CurrentHumans)/ratio);
            if (unrounded != rounded)
            {
               // float dmg = float(rounded)/unrounded;
               // g_f_Damage_Bonus = dmg;

              g_f_Damage_Bonus =  damage_bonus(float(MissingHumans));
                //PrintToChatAll("Missing Humans %i, DMG BONUS v2 %f",MissingHumans, g_f_Damage_Bonus);
            }
            else //This happens when the ratio is within target, to not go with the offset in human ratio
            {
                g_f_Damage_Bonus = -1.0;      
            }   
        }

        if (g_f_previous_dmg_bonus == g_f_Damage_Bonus)
        {
            g_b_changed_dmg = false;   
        }else
        {
            g_b_changed_dmg = true;    
        }

        g_f_previous_dmg_bonus = g_f_Damage_Bonus;
    
    //Put better calculative formula here if discovered
    // g_f_Damage_Bonus = Logarithm(float(TargetHumans)/float(CurrentHumans), float(CurrentHumans)) + 1.0;
}

float damage_bonus(float x) {
    float base = Pow(2.75/ 1.0, 1.0 / 17.0);
    return 1.0 * Pow(base, x);
}

// float diff_value(float diff) {
//     float new_diff = -1.0 * diff;
//     PrintToChatAll("new diff%f",new_diff);
//     float mod = -0.147;
//     float val = mod * new_diff;
//     float result = -0.00038 * Pow(val, 3) - 0.03461 * val;
//     PrintToChatAll("diff %f",result);
//     return result;
// }

int Native_UnmakeRobot(Handle plugin, int numParams)
{
    if (!g_BossMode)
        return 0;
    
    int clientId = GetNativeCell(1);
    MakeRobot(clientId, false);
    
    return 1;
}

int Native_GetRobotCap(Handle plugin, int numParams)
{
    if (!g_BossMode)
        return 0;

    return g_RoboCap;
}

bool AddRandomVolunteer()
{
    if (!g_BossMode || g_AprilEnable)
    {
        SMLogTag(SML_INFO, "will not add random volunteer, because g_BossMode is not enabled");
        return false;
    }

    int[] ignoredVolunteers = new int[g_Volunteers.Length];
    for(int i = 0; i < g_Volunteers.Length; i++)
    {
        ignoredVolunteers[i] = GetClientUserId(g_Volunteers.Get(i));
    }
    int newVolunteer = GetRandomVolunteer(ignoredVolunteers, g_Volunteers.Length);
    SMLogTag(SML_VERBOSE, "GetRandomVolunteer returned %i", newVolunteer);
    if (!IsValidClient(newVolunteer))
    {
        SMLogTag(SML_VERBOSE, "no volunteer found notifying players of open spot", newVolunteer);
        int islots = g_RoboCapTeam - g_Volunteers.Length;
        //PrintToChatAll("A new robot-slot is available. There is now %i available robot slots remains. Type !join to become a giant robot", islots);
        MC_PrintToChatAll("{green}%i{orange} Robot-slot available! Type {green}!join{orange} to become a giant robot!", islots);
        b_g_high_power = true;
        return false;
    }

    if (!IsClientInGame(newVolunteer)){
        // PrintToChatAll("%N is not ingame", newVolunteer);
        return false;
    }else
    {
        // PrintToChatAll("%N is ingame", newVolunteer);
    }

    SMLogTag(SML_VERBOSE, "turning %L into a robot", newVolunteer);
    //PrintToChatAll("A new robot-slot is available. %N was automatically chosen to fillup the robot-team.", newVolunteer);
    MC_PrintToChatAllEx(newVolunteer, "{teamcolor}%N{orange} was automatically chosen to fillup the robot-team.", newVolunteer);
    MakeRobot(newVolunteer, true);
    ChangeClientTeam(newVolunteer, g_RoboTeam);
    b_g_high_power = false;
    return true;
}

bool RemoveRandomRobot()
{
    if (!g_BossMode)
    {
        SMLogTag(SML_INFO, "will not remove random robot, because g_BossMode is not enabled");
        return false;
    }
    if (g_Volunteers.Length == 0)
    {
        SMLogTag(SML_INFO, "can't remove random robot, because no volunteers are found");
        return false;
    }

    int clientId = FindRandomVolunteer();
    if (clientId < 0)
    {
        SMLogTag(SML_INFO, "can't remove random robot, because no volunteers are found");
        return false;
    }

    char robotName[NAMELENGTH];
    robotName = g_cv_RobotPicked[clientId];
    CreateRobot(robotName, clientId, "");

    // MakeRobot(clientId, false);

    Reset(clientId);
    ChangeClientTeam(clientId, g_HumanTeam);
    return true;
}

int FindRandomVolunteer()
{
    for(int attempt = 0; attempt < g_Volunteers.Length; ++attempt)
    {
        if (g_Volunteers.Length <= 0)
            return -1;

        int i = GetRandomInt(0, g_Volunteers.Length -1);
        int clientId = g_Volunteers.Get(i);

        if (IsValidClient(clientId) && IsClientInGame(clientId))
            return clientId;
                     
        g_Volunteers.Erase(i);
    }

    return -1;
}

stock void TF2_SwapTeamAndRespawnNoMsg(int client, int team)
{
    //SetEntProp(client, Prop_Send, "m_lifeState", 2);
    ChangeClientTeam(client, team);
    //SetEntProp(client, Prop_Send, "m_lifeState", 0);
    // int irandomclass = GetRandomInt(1, 9);
    // TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));

        //This resets the model back to normal
    TFClassType iClass = TF2_GetPlayerClass(client);
    char model[32];
    
    switch(iClass)
    {
        case TFClass_Scout:
        {
            model = "models/player/scout.mdl";
        }
        case TFClass_Soldier:
        {
            model = "models/player/soldier.mdl";

        }
        case TFClass_Pyro:
        {
            model = "models/player/pyro.mdl";
        }
        case TFClass_DemoMan:
        {
            model = "models/player/demo.mdl";
        }
        case TFClass_Heavy:
        {
           model = "models/player/heavy.mdl";
        }
        case TFClass_Engineer:
        {
          model = "models/player/engineer.mdl";
        }
        case TFClass_Medic:
        {
           model = "models/player/medic.mdl";
        }
        case TFClass_Sniper:
        {
         model = "models/player/sniper.mdl";
        }
        case TFClass_Spy:
        {
           model = "models/player/spy.mdl";
        }
        case TFClass_Unknown:
        {
            //PrintToChatAll("UNKNOWN CLASS!");
            TF2_SetPlayerClass(client, TFClass_Heavy);
        }

    }

    SetVariantString(model);
    AcceptEntityInput(client, "SetCustomModel");
    SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

    // RequestFrame(RespawnPlayer, client);
}

// void RespawnPlayer (int client){
//     TF2_RespawnPlayer(client);
// }

stock void TF2_SetHealth(int client, int NewHealth)
{
    SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
    SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
    SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

public void OnEntityCreated(int iEntity, const char[] sClassName) 
{
	if (StrContains(sClassName, "item_powerup_rune") == 0)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
	
}

// public void KillRune(){

// 			int iEnt = MaxClients + 1;
// 		while ((iEnt = FindEntityByClassname(iEnt, "item_powerup_rune")) != -1)
// 		{
// 			if (IsValidEntity(iEnt))
// 			{
// 				AcceptEntityInput(iEnt, "Kill");
// 			}
// 		} 
// }

//OLD TEAM SWITCH CODE, MAY NOT WORK RIGHT
//HookEvent("teams_changed", Event_Teams_Changed, EventHookMode_Post);
//int g_counter = 0;
// bool b_counter = false;
// public Action Event_Teams_Changed(Event event, const char[] name, bool dontBroadcast)
// {
//     //Only do this if active
//     if (!g_BossMode)
//     return;

//     //This triggers twice per team switch, once goingo off the team and once arriving to the new team
//     g_counter++;

//     if (!b_counter){
//         CreateTimer(0.2, Timer_ResetCounter);
//         b_counter = true;
//     }
    
// }

// public Action Timer_ResetCounter(Handle timer, any client)
// {

//     int Unassigned = GetTeamClientCount(0);
//     int Spectate = GetTeamClientCount(1);
//     int Red = GetTeamClientCount(2);
//     int Blue = GetTeamClientCount(3);
//     int TotalPlayersInATeam = Spectate+Red+Blue+Unassigned;

    

//     if(g_cv_bDebugMode) PrintToChatAll("Total players was %i | counter was %i", TotalPlayersInATeam*2, g_counter); 
//     //Checks if all players have swapped teams, Counter triggers twice.
//     //Ignores players in spectate as they can't be team switched
//     if (g_counter == TotalPlayersInATeam*2-((Spectate*2)-(Unassigned*2))){
        
        
//        if(g_cv_bDebugMode)PrintToChatAll("Teams were switched, robot team is %i", g_RoboTeam);

//         //Changes which team is robot team
//         switch(g_RoboTeam)
//         {
//             case RED:
//             {
//                 if(g_cv_bDebugMode)PrintToChatAll("RoboTeam was RED changing to BLUE...");
//                 g_RoboTeam = BLUE;
//                 g_HumanTeam = RED;
//             }
//             case BLUE:
//             {
//                 if(g_cv_bDebugMode)PrintToChatAll("RoboTeam was BLU changing to RED...");
//                 g_RoboTeam = RED;
//                 g_HumanTeam = BLUE;
//             }
//         }
//     }else{
//        if(g_cv_bDebugMode) PrintToChatAll("Teams were not switched");
//     }


//     g_counter = 0;
//     b_counter = false;

// }