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
#include <berobot_core_restrictions>
#include <morecolors_newsyntax>
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
    CV_g_Enable,
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
bool g_WaitingForPlayers = true;

bool g_cv_Volunteered[MAXPLAYERS + 1];
char g_cv_RobotPicked[MAXPLAYERS + 1][NAMELENGTH];
bool g_ClientIsRepicking[MAXPLAYERS + 1];
bool g_Voted[MAXPLAYERS + 1];
Menu g_chooseRobotMenus[MAXPLAYERS + 1];

bool g_GoingToDie[MAXPLAYERS + 1] = false;
int g_TimeBombTime[MAXPLAYERS+1] = { 0, ... };

GlobalForward _enabledChangedForward;

float g_CV_flSpyBackStabModifier;

float g_Rtr_percent;

int g_CV_flYoutuberMode;
int g_Enable;
int g_RoboCapTeam;
int g_RoboTeam;
int g_HumanTeam;
int g_RoboCap;
int g_RoboTeamMode;
int g_RoboMode;
int g_iVotes;
int g_iVotesNeeded;

int g_RoundCount;

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
//

    g_cvCvarList[CV_PluginVersion] = CreateConVar("sm_mm_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
    //Gamemode cvar
    g_cvCvarList[CV_g_Enable] = CreateConVar("sm_mm_enable", "0", "0 = Manned Machines disabled, 1 = Manned Machines enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_mm_debug", "0", "Enable Debugging for Manned Machines Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_g_RoboCapTeam] = CreateConVar(CONVAR_ROBOCAP_TEAM, "6", "The total amount of giant robots on a team");  
    g_cvCvarList[CV_g_RoboCap] = CreateConVar("sm_robocap", "1", "The amount of giant robots allowed per robot-type");
    g_cvCvarList[CV_g_RoboTeamMode] = CreateConVar("sm_both_teams_have_robots", "0", "0 = One Team consists only of robots, 1 = Both teams have bots");
    g_cvCvarList[CV_g_RoboMode] = CreateConVar("sm_robo_mode", "0", "0 = Starts the mode when waiting for players is over, 1 = Start game by reaching enough volunteers");

    g_cvCvarList[CV_g_Rtr_precent] = CreateConVar("sm_mm_needed_rtr_ratio", "0.5", "The ratio of votes needed to start the mode with !rtr 1.0 = 100% 0.0 = 0%");

    //Gameplay cvar
    g_cvCvarList[CV_flSpyBackStabModifier] = CreateConVar("sm_robo_backstab_damage", "83.2", "Backstab damage that will be multipled by crit multiplier");
    g_cvCvarList[CV_flYoutuberMode] = CreateConVar("sm_mm_yt_mode", "0", "Uses youtuber mode for the official mode to set youtubers as the proper classes");
    /* Convar global variables init */

    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);
    g_Enable = GetConVarInt(g_cvCvarList[CV_g_Enable]);
    g_CV_flSpyBackStabModifier = GetConVarFloat(g_cvCvarList[CV_flSpyBackStabModifier]);
    
    g_Rtr_percent = GetConVarFloat(g_cvCvarList[CV_g_Rtr_precent]);

    g_RoboCapTeam = GetConVarInt(g_cvCvarList[CV_g_RoboCapTeam]);
    g_RoboCap = GetConVarInt(g_cvCvarList[CV_g_RoboCap]);
    g_RoboTeamMode = GetConVarInt(g_cvCvarList[CV_g_RoboTeamMode]);
    g_RoboMode = GetConVarInt(g_cvCvarList[CV_g_RoboMode]);
    g_CV_flYoutuberMode = GetConVarInt(g_cvCvarList[CV_flYoutuberMode]);
    

    /* Convar Change Hooks */

    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_Enable].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flSpyBackStabModifier].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flYoutuberMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCapTeam].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCap].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboTeamMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_Rtr_precent].AddChangeHook(CvarChangeHook);

    _enabledChangedForward = new GlobalForward("MM_OnEnabledChanged", ET_Ignore, Param_Cell);

    RegAdminCmd("sm_makerobot", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_mr", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_boss_mode", Command_YT_Robot_Start, ADMFLAG_SLAY, "Sets up the team and starts the robot");
    RegAdminCmd("sm_selection_mode", Command_Robot_Selection, ADMFLAG_SLAY, "Forces selection mode");
    
    RegAdminCmd("sm_me_boss", Command_Me_Boss, ADMFLAG_SLAY, "Checks if you are a boss");

    RegConsoleCmd("sm_rtr", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_rocktherobot", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_changerobot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_chngrbt", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_cr", Command_ChangeRobot, "change your robot");


    AddCommandListener(Block_Kill, "kill"); 
	AddCommandListener(Block_Kill, "explode"); 
    
    AddCommandListener(cmd_blocker, "changeclass");
	AddCommandListener(cmd_blocker, "joinclass");
	AddCommandListener(cmd_blocker, "join_class");


    /* Hooks */
    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);

    HookEvent("teamplay_round_start", Event_Waiting_Abouttoend, EventHookMode_Post);
    
    HookEvent("player_death", Event_Death, EventHookMode_Post);

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

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
    CreateNative("GetRobotCountPerTeam", Native_GetRobotCountPerTeam);
    CreateNative("SetVolunteers", Native_SetVolunteers);
    CreateNative("EnsureRobotCount", Native_EnsureRobotCount);
    CreateNative("IsEnabled", Native_IsEnabled);
    CreateNative("IsYTEnabled", Native_IsYTEnabled);
    CreateNative("IsActive", Native_IsActive);
    CreateNative("UnmakeRobot", Native_UnmakeRobot);
    return APLRes_Success;
}

public void OnMapStart()
{
    g_WaitingForPlayers = true;
    g_RoundCount = 0;
    ResetMode();

    PrecacheScriptSound("Announcer.MVM_General_Destruction");
    

}

public void ResetMode()
{
    g_cv_BlockTeamSwitch = false;
    g_BossMode = false;
    g_SpectateSelection = false;
    g_iVotes = 0;
    g_Volunteers.Clear();
    g_RobotCount.Clear();

    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        g_cv_Volunteered[i] = false;
        g_cv_RobotPicked[i] = "";
        g_Voted[i] = false;

    }

    int totalplayers = RoundToCeil(float(GetClientCount(false)) * g_Rtr_percent);
    g_iVotesNeeded = totalplayers;
    //g_iVotesNeeded = 6;
}

public void OnClientDisconnect(int client)
{
    Reset(client);
}

void Reset(int client)
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

    if (g_chooseRobotMenus[client] != null)
    {
        SMLogTag(SML_VERBOSE, "canceling ChooseRobot-menu for %L", client);
        g_chooseRobotMenus[client].Cancel();
        g_chooseRobotMenus[client] = null;
    }

    RedrawChooseRobotMenu();
    EnsureRobotCount();
}

/* Publics */

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (IsAnyRobot(client)){ 
        
        //PrintToChatAll("%N spawned, checking if boss", client);
        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}!cr{teamcolor} to change robot!");

        //CreateTimer(1.0, Boss_check, client);
    }
            // int Humans = GetTeamClientCount(g_HumanTeam);
            // int Robots = GetTeamClientCount(g_RoboTeam);
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

        if (!IsAnyRobot(victim) && IsAnyRobot(attacker))
        {
            //PrintChatAll("You are not a robot %N", victim);
            if (TF2_GetPlayerClass(victim) == TFClass_Scout){
                CreateTimer(4.0, Timer_Respawn, victim);
            }
        }

        //Removes the robot ragdoll and causes explosion
        if (IsAnyRobot(victim))
        {

            CreateTimer(0.0, RemoveBody, victim);
            float position[3];
            GetEntPropVector(victim, Prop_Data, "m_vecOrigin", position);	
            int attach = CreateEntityByName("trigger_push");
            TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);

            // if (IsBoss(victim)){
            //     TE_Particle("fireSmokeExplosion2", position, _, _, attach, 1,0);	
            // }else{
                
            TE_Particle("hightower_explosion", position, _, _, attach, 1,0);	
            // } 

            int irandom = GetRandomInt(1,3);
           // EmitGameSoundToAll("Announcer.MVM_General_Destruction");
            if (irandom == 1)
            {
                CreateTimer(1.5, SayDeathVoiceline);
            }
            // } 
            
        }
//        fireSmokeExplosion//
// 
        g_GoingToDie[victim] = false;
}

public Action SayDeathVoiceline(Handle timer)
{
    EmitGameSoundToAll("Announcer.MVM_General_Destruction");
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

public Action Timer_Respawn(Handle timer, any client)
{
    //PrintToChatAll("Timebomb: %i", g_TimeBombTime[client]);
	if (IsValidClient(client) && !IsPlayerAlive(client))
    {
        TF2_RespawnPlayer(client);
        //PrintHintText(client,"You have instant respawn as scout");
    }
}

public Action Event_Waiting_Abouttoend(Event event, const char[] name, bool dontBroadcast)
{
    if(g_Enable && g_RoundCount == 0){
        //PrintToChatAll("==Waiting for other players==");
        g_RoundCount++;
        g_WaitingForPlayers = true;

        
    }else if(g_Enable && g_RoundCount == 1 && !g_BossMode){
        //PrintToChatAll("== Not waiting for players !rtr available!");
        Command_Robot_Selection(1, 1);
        //MC_PrintToChatAll("[{orange}SM{default}]{orange} Type !rtr to vote to start Manned Machines");
        
        g_WaitingForPlayers = false;
        g_RoundCount++;
    }

    int totalplayers = RoundToCeil(float(GetClientCount(false)) * g_Rtr_percent);
    g_iVotesNeeded = totalplayers;

   // PrintToChatAll("Total players: %i", totalplayers);
  //  PrintToChatAll("Total players: %i", GetClientCount(false));
     //view_as<TFTeam>(g_HumanTeam) 
     
    
    //g_iVotesNeeded = int(ivotes_needed);
    
}

public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{
    if (g_Enable){

        MC_PrintToChatAll("{Green}Type {orange}!info{Green} to see more info about this gamemode");
        MC_PrintToChatAll("{Green}Visit {orange}balancemod.tf/mannedmachines {Green} To get the assetpack to get the most out of this mode");

    for(int i = 1; i <= MaxClients; i++)
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
    }

    return Plugin_Continue;
}

public MRESReturn OnRegenerate(int pThis, Handle hReturn, Handle hParams)
{
    //Activates when doing OnRegenerate (touchihng resupply locker) and then ignoring it if you are a boss

    if(isMiniBoss(pThis)){
        //PrintToChatAll("1");

    //sets the robot health when touch
	int maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, pThis);
        SetEntityHealth(pThis, maxhealth);
        return MRES_Supercede; 
    }

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
        
    if(convar == g_cvCvarList[CV_g_Rtr_precent])
        g_Rtr_percent = StringToFloat(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCap])
        g_RoboCap = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCapTeam])
    {   
        g_RoboCapTeam = StringToInt(sNewValue);
        if (g_Enable) PrintHintTextToAll("Current Robots: %i", g_RoboCapTeam);
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
}

/* Plugin Exclusive Functions */
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;


    TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);

    //if(g_cv_bDebugMode) PrintToChatAll("On damage happened");
    
    if(IsAnyRobot(victim) && !IsAnyRobot(attacker))
    {
        // Checks if boss is on
            
            if (iClassAttacker == TFClass_Spy)
            
            if(g_cv_bDebugMode) PrintToChatAll("Attacker  %N was aspy and victim %N was robot", attacker, victim);{
                if(damagecustom == TF_CUSTOM_BACKSTAB)
                {
                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                    damage = g_CV_flSpyBackStabModifier;
                    critType = CritType_Crit;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                }
            }  
    }
    return Plugin_Continue;
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;

    TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);

    //if(g_cv_bDebugMode) PrintToChatAll("On damage happened");
    
    if(IsAnyRobot(victim))
    {
            /*Damage code for Heavy*/
            if (iClassAttacker == TFClass_Heavy)
            {
                int iWeapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);

                    
                if (weapon == iWeapon)
                {
                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                    damage *= 0.75;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                    
                }
                    
                    
            }
            
            if (iClassAttacker == TFClass_DemoMan && !IsAnyRobot(attacker))
            {

                if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                damage *= 1.35;
                if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                return Plugin_Changed;
                
                    
            }   
    }
    return Plugin_Continue;
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
    if (g_Enable){
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
    g_SpectateSelection = true;

    StartAutomaticVolunteerVote();
    }
}

// intercept and block client jointeam command if required
public Action Command_YT_Robot_Start(int client, int args)
{

    if (g_Enable){

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

        }else
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
    }else
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
    //g_Voted[client] = true;
    MC_PrintToChatAllEx(client, "[{orange}SM{default}] {teamcolor}%N {default}wants to start Giant Robot Boss mode. [{orange}%i{default}/{orange}%i {default}more votes required]", client, g_iVotes, g_iVotesNeeded);

    //Start the robo vote
    if(g_iVotes >= g_iVotesNeeded)
    {
        Command_Robot_Selection(client, args);
    }
    }else
    {
        MC_PrintToChatAllEx(client, "[{orange}SM{default}] {teamcolor}%N {default}Manned Machines mode is {red}disabled", client);
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
        Menu_ChooseRobot(targetClientId);
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
            MoveToRobots(client);
        }
    }
    else if(!volunteering && g_cv_Volunteered[client]) //Remove from volunteer list
    {
        SMLogTag(SML_VERBOSE, "volunteer-state changed to false for %L", client);
        
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
    TF2_SwapTeamAndRespawnNoMsg(client, g_RoboTeam);
    SetRandomRobot(client);
    g_ClientIsRepicking[client] = false;
    Menu_ChooseRobot(client);
}

int RobotDefinitionComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    Robot a, b;
    list.GetArray(index1, a);
    list.GetArray(index2, b);


    int rolecmp = strcmp(a.role, b.role);
    if (rolecmp != 0)
        return rolecmp;

    int classcmp = strcmp(a.class, b.class);
    if (classcmp != 0)
        return classcmp;

    int namecmp = strcmp(a.name, b.name);
    if (namecmp != 0)
        return namecmp;

    return strcmp(a.shortDescription, b.shortDescription);
}

Action Menu_ChooseRobot(int client)
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

        char notes[15];
        int draw;
        GenerateNotes(item, client, notes, draw);

        char display[128];
        Format(display, sizeof(display), "%s: %s - %s - %s (%s)", item.role, item.class, item.name, item.shortDescription, notes);

        menu.AddItem(item.name, display, draw);

        SMLogTag(SML_VERBOSE, "added option for %s: %s", item.name, display);
    }
    
    if (g_chooseRobotMenus[client] != null)
        g_chooseRobotMenus[client].Cancel();
    g_chooseRobotMenus[client] = menu;

    int timeout = MENU_TIME_FOREVER;
    menu.Display(client, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", client, timeout);

    return Plugin_Handled;
}

void GenerateNotes(Robot item, int client, char notes[15], int& draw)
{
    int count;
    g_RobotCount.GetValue(item.name, count);
    if (count >= g_RoboCap)
    {
        Format(notes, sizeof(notes), "%i / %i", count, g_RoboCap);
        draw = ITEMDRAW_DISABLED;
        return;
    }

    if (!item.restrictions.TimeLeft.Enabled)
    {
        Format(notes, sizeof(notes), "timeleft: %is", item.restrictions.TimeLeft.SecondsBeforeEndOfRound);
        draw = ITEMDRAW_DISABLED;
        return;
    }

    RobotCoins robotCoins = item.restrictions.GetRobotCoinsFor(client);
    if (!robotCoins.Enabled)
    {
        Format(notes, sizeof(notes), "robot-coins: %i", robotCoins.GetPrice());
        draw = ITEMDRAW_DISABLED;
        return;
    }

    Format(notes, sizeof(notes), "%i / %i", count, g_RoboCap);
    draw = ITEMDRAW_DEFAULT;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        if (g_chooseRobotMenus[param1] == null)
            return;
        g_chooseRobotMenus[param1] = null;

        char info[NAMELENGTH];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        SetRobot(info, param1);
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        g_chooseRobotMenus[param1] = null;

        if (param2 == MenuCancel_Exit)
        {
            g_ClientIsRepicking[param1] = false;
        }
        // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        for(int i = 0; i <= MaxClients; i++)
        {
            if (g_chooseRobotMenus[i] == menu)
                g_chooseRobotMenus[i] = null;
        }
        delete menu;
    }
}

void SetRandomRobot(int client)
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
    for (;;)  
    {
        int i = GetRandomInt(0, robotNames.Length -1);
        SMLogTag(SML_VERBOSE, "picked random %i (between %i and %i)", i, 0, robotNames.Length -1);

        robotNames.GetString(i, robotname, sizeof(robotname));

        int count;
        g_RobotCount.GetValue(robotname, count);
        if (count < g_RoboCap)
        {
            Robot item;
            GetRobotDefinition(robotname, item);
            if (item.restrictions.IsEnabled())
            {
                break;
            }
        }        

        robotNames.Erase(i);
        if (robotNames.Length <= 0)
        {
            SMLogTag(SML_VERBOSE, "no robot left to choose. %L will not be turned into a robot.", client);
            return;
        }
    }

    SMLogTag(SML_VERBOSE, "setting bot %L to be robot '%s'", client, robotname);
    SetRobot(robotname, client);
}

void SetRobot(char robotname[NAMELENGTH], int client)
{
    int error = CreateRobot(robotname, client, "");
    if (error != 0)
    {
        RedrawChooseRobotMenuFor(client);
        return;
    }

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

    RedrawChooseRobotMenu();
}

void RedrawChooseRobotMenu()
{
    for(int i = 0; i <= MaxClients; i++)
    {
        RedrawChooseRobotMenuFor(i);
    }
}

void RedrawChooseRobotMenuFor(int clientId)
{
    if(!IsValidClient(clientId))
    {
        SMLogTag(SML_VERBOSE, "not redrawing ChooseRobotMenu for client %i, because client is not valid", clientId);
        return;
    }

    if(g_cv_RobotPicked[clientId][0] != '\0' && !g_ClientIsRepicking[clientId]) //don't open menu for players, who have already picked a robot
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
    Menu_ChooseRobot(clientId);
}

public Action OnClientCommand(int client, int args)
{
    char cmd[16];

    /* Get the argument */
    GetCmdArg(0, cmd, sizeof(cmd));
    if(strcmp(cmd, "jointeam", true) == 0)
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
                    //ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
                }
                    

                if(IsAnyRobot(client))
                {
                    if(g_cv_bDebugMode) PrintToChatAll("Was a robot %N", client);
                    ChangeClientTeam(client, g_RoboTeam);
                    //ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
                }
                    

                //Sets you as random class when you join when boss mode is active
                int irandomclass = GetRandomInt(1, 9);
                TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
                TF2_RespawnPlayer(client);
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
        g_TimeBombTime[client] = 11;
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
	if (!IsAnyRobot(client) && g_BossMode && !TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
	{
		PrintCenterText(client,"You can only change class in spawn");
		
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
    
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
        MakeRobot(volunteers[i], true);
    }
}

int Native_EnsureRobotCount(Handle plugin, int numParams)
{
    if (!g_BossMode)
        return;
        
    while (g_Volunteers.Length < g_RoboCapTeam)
    {
        bool success = AddRandomVolunteer();
        SMLogTag(SML_VERBOSE, "adding random volunteer succcess: %b", success);
        if (!success)
            break;
    }
    while (g_Volunteers.Length > g_RoboCapTeam)
    {
        bool success = RemoveRandomRobot();
        SMLogTag(SML_VERBOSE, "removing random robot succcess: %b", success);
        if (!success)
            break;
    }
}

int Native_UnmakeRobot(Handle plugin, int numParams)
{
    if (!g_BossMode)
        return;
    
    int clientId = GetNativeCell(1);
    MakeRobot(clientId, false);
}

bool AddRandomVolunteer()
{
    if (!g_BossMode)
    {
        SMLogTag(SML_INFO, "will not add random volunteer, because g_BossMode is not enabled");
        return false;
    }

    int[] ignoredVolunteers = new int[g_Volunteers.Length];
    for(int i = 0; i < g_Volunteers.Length; i++)
    {
        ignoredVolunteers[i] = g_Volunteers.Get(i);
    }
    int newVolunteer = GetRandomVolunteer(ignoredVolunteers, g_Volunteers.Length);
    SMLogTag(SML_VERBOSE, "GetRandomVolunteer returned %i", newVolunteer);
    if (!IsValidClient(newVolunteer))
    {
        SMLogTag(SML_VERBOSE, "no volunteer found notifying players of open spot", newVolunteer);
        int islots = g_RoboCapTeam - g_Volunteers.Length;
        PrintToChatAll("A new robot-slot is available. There is now %i available robot slots remains. Type !volunteer to become a giant robot", islots);

        return false;
    }

    SMLogTag(SML_VERBOSE, "turning %L into a robot", newVolunteer);
    PrintToChatAll("A new robot-slot is available. %N was automatically chosen to fillup the robot-team.", newVolunteer);
    MakeRobot(newVolunteer, true);
    ChangeClientTeam(newVolunteer, g_RoboTeam);

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
    for(;;)
    {
        if (g_Volunteers.Length <= 0)
            return -1;

        int i = GetRandomInt(0, g_Volunteers.Length -1);
        int clientId = g_Volunteers.Get(i);

        if (IsValidClient(clientId) && IsClientInGame(clientId))
            return clientId;
                     
        g_Volunteers.Erase(i);
    }
}

stock void TF2_SwapTeamAndRespawnNoMsg(int client, int team)
{
	//SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	//SetEntProp(client, Prop_Send, "m_lifeState", 0);
    int irandomclass = GetRandomInt(1, 9);
    TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
    TF2_RespawnPlayer(client);
}
