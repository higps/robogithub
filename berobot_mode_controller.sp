#define PLUGIN_NAME "berobot_mode_controller"
#define PLUGIN_DESCRIPTION "Manned Machines mode lifecycle, teams, volunteers and robot selection"
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

enum 
{
    CV_g_Rtr_precent,
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

ConVar g_cvCvarList[CV_PluginVersion + 1];

bool g_cv_bDebugMode;

bool g_BossMode = false;
bool g_cv_BlockTeamSwitch = false;
bool g_SpectateSelection = false;
bool g_WaitingForPlayers = true;

bool g_cv_Volunteered[MAXPLAYERS + 1];
char g_cv_RobotPicked[MAXPLAYERS + 1][NAMELENGTH];
bool g_Voted[MAXPLAYERS + 1];

GlobalForward _enabledChangedForward;
GlobalForward _clientResetting;
GlobalForward _modeResetRequestedForward;

GlobalForward _wasRandomRobotForward;

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

float g_cr_cooldown[MAXPLAYERS + 1] = {0.0,...};

bool b_g_high_power = false;
int g_RoundCount;

ArrayList g_Volunteers;

Handle g_hRegen;
Handle g_hGameConf;
Handle g_hIsDeflectable;

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

    g_cvCvarList[CV_PluginVersion] = CreateConVar("sm_mm_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);

    g_cvCvarList[CV_g_Enable] = CreateConVar("sm_mm_enable", "0", "0 = Manned Machines disabled, 1 = Manned Machines enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_g_AprilEnable] = CreateConVar("sm_mm_april_enable", "0", "0 = Manned Machines april fools disabled, 1 = Manned Machines april fools enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_mm_debug", "0", "Enable Debugging for Manned Machines Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_g_RoboCapTeam] = CreateConVar(CONVAR_ROBOCAP_TEAM, "6", "The total amount of giant robots on a team");  
    g_cvCvarList[CV_g_RoboCap] = CreateConVar("sm_robocap", "1", "The amount of giant robots allowed per robot-type");
    g_cvCvarList[CV_g_RoboTeamMode] = CreateConVar("sm_both_teams_have_robots", "0", "0 = One Team consists only of robots, 1 = Both teams have bots");
    g_cvCvarList[CV_g_RoboMode] = CreateConVar("sm_robo_mode", "0", "0 = Starts the mode when waiting for players is over, 1 = Start game by reaching enough volunteers");
    g_cvCvarList[CV_g_RoboStartTeam] = CreateConVar("sm_robot_random_start_team", "1", "0 = Robots always start on red, 1 = Robot team is randomly picked RED or BLUE, 2 = Robots Always starts on blue");

    g_cvCvarList[CV_g_Rtr_precent] = CreateConVar("sm_mm_needed_rtr_ratio", "0.5", "The ratio of votes needed to start the mode with !rtr 1.0 = 100% 0.0 = 0%");

    g_cvCvarList[CV_flYoutuberMode] = CreateConVar("sm_mm_yt_mode", "0", "Uses youtuber mode for the official mode to set youtubers as the proper classes");

    g_Enable = GetConVarInt(g_cvCvarList[CV_g_Enable]);
    g_AprilEnable = GetConVarInt(g_cvCvarList[CV_g_AprilEnable]);

    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);

    g_Rtr_percent = GetConVarFloat(g_cvCvarList[CV_g_Rtr_precent]);
    g_RoboCapTeam = GetConVarInt(g_cvCvarList[CV_g_RoboCapTeam]);
    g_RoboCap = GetConVarInt(g_cvCvarList[CV_g_RoboCap]);
    g_RoboTeamMode = GetConVarInt(g_cvCvarList[CV_g_RoboTeamMode]);
    g_RoboStartTeam = GetConVarInt(g_cvCvarList[CV_g_RoboStartTeam]);
    g_RoboMode = GetConVarInt(g_cvCvarList[CV_g_RoboMode]);
    g_CV_flYoutuberMode = GetConVarInt(g_cvCvarList[CV_flYoutuberMode]);

    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_Enable].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_AprilEnable].AddChangeHook(CvarChangeHook);

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

    _wasRandomRobotForward = new GlobalForward("MM_WasRandomRobotForward", ET_Ignore, Param_Cell);

    RegAdminCmd("sm_makerobot", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_mr", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_boss_mode", Command_YT_Robot_Start, ADMFLAG_SLAY, "Sets up the team and starts the robot");
    RegAdminCmd("sm_selection_mode", Command_Robot_Selection, ADMFLAG_SLAY, "Forces selection mode");

    RegAdminCmd("sm_me_boss", Command_Me_Boss, ADMFLAG_SLAY, "Checks if you are a boss");
    RegAdminCmd("sm_random_robot", Command_SetRandomRobot, ADMFLAG_SLAY, "Checks if you are a boss");
    RegAdminCmd("sm_toggle_team_switch", Command_ToggleTeamSwitch, ADMFLAG_SLAY, "Toggles allowing teamswitch");

    RegConsoleCmd("sm_rtr", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_rocktherobot", Command_RoboVote, "Votes to begin a mode");
    RegConsoleCmd("sm_changerobot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_chngrbt", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_cr", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_bot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_robot", Command_ChangeRobot, "change your robot");

    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_Waiting_Abouttoend, EventHookMode_Post);

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    g_Volunteers = new ArrayList(ByteCountToCells(g_RoboCapTeam));

    g_Volunteers.Clear();

}

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

    return APLRes_Success;
}

public void OnMapStart()
{
    g_WaitingForPlayers = true;
    g_RoundCount = 0;
    ResetMode();
    g_RoboTeam = -1;
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

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!g_AprilEnable) RequestFrame(RobotTeamCheck, client);
    if (!IsAnyRobot(client) && g_AprilEnable && g_BossMode && g_Enable)
    {
        CreateTimer(0.1, SetRandomRobot_Timer, client);
    }
    return Plugin_Continue;
}

public Action SetRandomRobot_Timer(Handle timer, any client)
{

    if (!IsAnyRobot(client))
    {
        Internal_SetRandomRobot(client);
    }
}

public Action Timer_Regen(Handle timer, any client)
{
    TF2_RegeneratePlayer(client);
}

public Action Event_Waiting_Abouttoend(Event event, const char[] name, bool dontBroadcast)
{

    if(g_Enable && g_RoundCount == 0){

        g_RoundCount++;
        g_WaitingForPlayers = true;

    }else if(g_Enable && g_RoundCount == 1 && !g_BossMode){

        g_WaitingForPlayers = false;
        g_RoundCount++;

        Command_Robot_Selection(1, 1);

    }

    int totalplayers = RoundToCeil(float(GetClientCount(false)) * g_Rtr_percent);
    g_iVotesNeeded = totalplayers;

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

            for(int i = 0; i <= MaxClients; i++)
            {
                if(IsAnyRobot(i))
                {
                    char robotName[NAMELENGTH];
                    GetRobot(i, robotName, sizeof(robotName));
                    if (IsPaidRobot(i, robotName))
                    {
                        TrashRobot(i);
                        Internal_SetRandomRobot(i);
                    }
                }
            }

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

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));

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

        }

        if (iTeam == g_RoboTeam && !IsAnyRobot(client))
        {
            Internal_SetRandomRobot(client);
        }
    }
}

public void MM_OnRestrictionChanged(char name[NAMELENGTH])
{
    SMLogTag(SML_VERBOSE, "MM_OnRestrictionChanged called at %i", GetTime());

    RedrawChooseRobotMenu();
}

public Action Command_BeRobot(int client, int numParams)
{
    if (numParams < 1)
    {
        ReplyToCommand(client, "Usage: sm_mr <robot_name> [target]");
        return Plugin_Handled;
    }

    char name[NAMELENGTH];
    GetCmdArg(1, name, NAMELENGTH);

    char target[32];
    int targetFilter = 0;
    if (numParams < 2)
    {
        target = "@me";
        targetFilter = COMMAND_FILTER_NO_IMMUNITY;
    }
    else
        GetCmdArg(2, target, sizeof(target));

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
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

    SMLogTag(SML_VERBOSE, "BeRobot called for %i targets with name %s by %L", target_count, name, client);

    for (int i = 0; i < target_count; i++)
    {
        int targetClientId = target_list[i];
        Internal_SetRobot(name, targetClientId);
        SetEntProp(targetClientId, Prop_Send, "m_bIsMiniBoss", 1);
    }

    return Plugin_Handled;
}

public Action Command_SetRandomRobot(int client, int args)
{
    Internal_SetRandomRobot(client);

}

public Action Command_ToggleTeamSwitch(int client, int args)
{

    g_cv_BlockTeamSwitch = !g_cv_BlockTeamSwitch;

    if (g_cv_BlockTeamSwitch)
    {

        PrintToChat(client, "Team switching is now blocked.");

    }
    else
    {

        PrintToChat(client, "Team switching is now allowed.");
    }

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

    g_cv_BlockTeamSwitch = true;

    StartAutomaticVolunteerVote();
    }

}

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

            switch(g_RoboStartTeam)
            {
                case 0:
                {
                    g_RoboTeam = BLUE;
                    g_HumanTeam = RED;
                }
                case 1:
                {
                    int RandomTeam = GetRandomInt(1, 2);

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
                case 2:
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

                for(int i = 0; i <= MaxClients; i++)
                {

                    if(IsValidClient(i))
                    {

                        if(IsClientInGame(i))
                        {

                            if(g_cv_Volunteered[i])
                            {
                                PrintToChat(i, "You are on the Robot Team");

                                MoveToRobots(i);

                            }
                            else
                            {
                                PrintToChat(i, "You are on the Human team");

                                TF2_SwapTeamAndRespawnNoMsg(i, g_HumanTeam);

                            }
                        }
                    }
                }
            }
        }
    }
    else if (g_Enable  && g_AprilEnable)
    {

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

        if(g_Voted[client])
        {
            MC_PrintToChat(client,"{orange}You have already voted");
            return;
        }

        g_iVotes++;

        MC_PrintToChatAllEx(client, "[{orange}SM{default}] {teamcolor}%N {default}wants to start Giant Robot Boss mode. [{orange}%i{default}/{orange}%i {default}more votes required]", client, g_iVotes, g_iVotesNeeded);

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
        PrintCenterText(client, "You can't change robot, you fool!");
        return Plugin_Handled;
    }

    if (!TF2Spawn_IsClientInSpawn(client) && IsPlayerAlive(client))
    {
        PrintCenterText(client, "You can only change robot when in spawn or dead.");
        return Plugin_Handled;
    }

    if (args >= 1)
    {

        char robotName[128];  
        robotName[0] = '\0';  

        for (int i = 1; i <= args; i++)  
        {
            char part[32];  
            GetCmdArg(i, part, sizeof(part));  

            if (i > 1)
            {
                StrCat(robotName, sizeof(robotName), " ");
            }

            StrCat(robotName, sizeof(robotName), part);
        }

        if (robotName[0] != '\0' && g_cr_cooldown[client] < GetEngineTime())
        {

            CreateRobot(robotName, client, ""); 
            SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 1); 

            PrintCenterText(client, "You have turned into %s!", robotName); 
            g_cr_cooldown[client] = GetEngineTime() + 10.0; 
            return Plugin_Handled;
        }
    }

    int iTeam = GetClientTeam(client);
    if (iTeam == g_RoboTeam || g_AprilEnable)
    {

        SetClientRepicking(client, true); 
        ChooseRobot(client); 
        return Plugin_Handled;
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

        if(g_BossMode)
        {
            SMLogTag(SML_VERBOSE, "volunteering during boss_mode => switch team & show menu");

            if(!g_AprilEnable)MoveToRobots(client);
        }
    }
    else if(!volunteering && g_cv_Volunteered[client]) 
    {
        SMLogTag(SML_VERBOSE, "volunteer-state changed to false for %L", client);

        SetRobot(g_cv_RobotPicked[client], client);
        Reset(client);
        TF2_SwapTeamAndRespawnNoMsg(client, g_HumanTeam);

        int islots = g_RoboCapTeam - g_Volunteers.Length;
        MC_PrintToChatAllEx(client, "{teamcolor}%N {default}is no longer volunteering to be a giant robot. %i more volunteers needed.", client, islots);
    }
    else
    {
        SMLogTag(SML_VERBOSE, "volunteer-state did not change for %L (still %b)", client, g_cv_Volunteered[client]);
    }

    if(g_RoboCapTeam == g_Volunteers.Length)
    {

        if(!g_BossMode)Command_YT_Robot_Start(client, true);

        g_Volunteers.Resize(g_RoboCapTeam);

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

}

void MoveToRobots(int client)
{    
    if(!g_AprilEnable)TF2_SwapTeamAndRespawnNoMsg(client, g_RoboTeam);

    RequestFrame(Internal_SetRandomRobot,client);

}

void ReopenChooseRobotMenuTopLevel(int client)
{

    ChooseRobot(client, false);
}

void RefreshChooseRobotMenuInPlace(int client)
{

    ChooseRobot(client, true);
}

Action ChooseRobot(int client, bool redrawing = false)
{

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

    for (;;)  
    {
        int i = GetRandomInt(0, robotNames.Length -1);

        robotNames.GetString(i, robotname, sizeof(robotname));

        int count = GetRobotCount(robotname);
        if (count < g_RoboCap)
        {
            Robot item;

            GetRobotDefinition(robotname, item);

            if (item.restrictions.IsEnabled() && !item.restrictions.IsActive() && item.difficulty == ROBOT_DIFFICULTY_EASY || item.difficulty == ROBOT_DIFFICULTY_UNDEFINED)
            {
                if(g_cv_bDebugMode)PrintToChatAll("For %N, the robot %s, was enabled, index was: %i", client, robotname, i);

                break;
            }else{

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

    if(g_cv_bDebugMode)PrintToChatAll("setting bot %L to be robot '%s'", client, robotname);

    Call_StartForward(_wasRandomRobotForward);
    Call_PushCell(client);
    Call_Finish();
    ForceRobot(robotname, client);
}

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

        ReopenChooseRobotMenuTopLevel(client);
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

    if(g_cv_RobotPicked[clientId][0] != '\0' && !IsRepicking(clientId)) 
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

    RefreshChooseRobotMenuInPlace(clientId);
}

public Action OnClientCommand(int client, int args)
{
    char cmd[16];

    GetCmdArg(0, cmd, sizeof(cmd));
    if(strcmp(cmd, "jointeam", true) == 0 || strcmp(cmd, "autoteam", true) == 0 || strcmp(cmd, "spectate", true) == 0)
    {
        TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));

        if (g_SpectateSelection)
        {
            ChangeClientTeam(client, SPECTATE);
            if(g_cv_bDebugMode) PrintToChatAll("Moving to spectate %N", client);
            return Plugin_Handled;
        }

        if(g_cv_BlockTeamSwitch)
        {

            if(g_cv_bDebugMode) PrintToChatAll("Teamswitch is %b ", g_cv_BlockTeamSwitch);

            if(iTeam == TFTeam_Unassigned || iTeam == TFTeam_Spectator)
            {

                if(!IsAnyRobot(client)){
                    if(g_cv_bDebugMode) PrintToChatAll("Was not a robot %N", client);
                    ChangeClientTeam(client, g_HumanTeam);

                    int irandomclass = GetRandomInt(1, 9);
                    TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
                    TF2_RespawnPlayer(client);

                }

                if(IsAnyRobot(client))
                {
                    if(g_cv_bDebugMode) PrintToChatAll("Was a robot %N", client);
                    ChangeClientTeam(client, g_RoboTeam);

                }

            }

            if (g_BossMode)
            {
                GetCmdArg(1, cmd, sizeof(cmd));

                TFTeam teampick = TFTeam_Unassigned;

                if(strcmp(cmd, "blue", true) == 0)
                {
                    teampick = TFTeam_Blue;

                }else if (strcmp(cmd, "red", true) == 0)
                {
                    teampick = TFTeam_Red;
                }

                int roboteam = GetRobotTeam();

                int userid = GetClientUserId(client);

                if(!IsAnyRobot(client) && teampick == roboteam)
                {

                    ServerCommand("sm_setvolunteer #%d", GetClientUserId(client));
                    PrintCenterText(client, "Boss mode is activated: Volenteering you to be a robot!");
                }

                else if (IsAnyRobot(client) && teampick != TFTeam_Unassigned && teampick != roboteam)
                {

                    ServerCommand("sm_unsetvolunteer #%d", GetClientUserId(client));
                    PrintCenterText(client, "Boss mode is activated: Unvolunteering you");
                }
                else
                {

                    PrintCenterText(client, "Boss mode is activated: Teams are locked");    
                }
            }

            return Plugin_Handled;
        }
    }

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

    while (g_Volunteers.Length < g_RoboCapTeam)
    {
        bool success = AddRandomVolunteer();
        SMLogTag(SML_VERBOSE, "adding random volunteer succcess: %b", success);

        if (!success)
            break;
    }

}

stock void GetDamageWord(char[] word, int maxsize)
{
    if (g_f_Damage_Bonus < 1.0)
    {
        Format(word, maxsize, "less");
    }
    else
    {
        Format(word, maxsize, "more");
    }
}

void CalculateDamageModifier(int dmg_method)
{
        int CurrentRobots = GetCurrentRobotCount();
        int CurrentHumans = GetCurrentHumanCount();

        ConVar drobotcount = FindConVar("sm_berobot_dynamicRobotCount_humansPerRobot");
        float ratio = drobotcount.FloatValue;

        int TargetHumans = RoundToFloor(float(CurrentRobots) * ratio) - CurrentRobots;
        int MissingHumans = TargetHumans - CurrentHumans;

        if (dmg_method == dmg_method_off_target)
        {
            g_f_Damage_Bonus = damage_bonus(float(MissingHumans));

        }
        else if (dmg_method == dmg_method_on_target)
        {
            float unrounded = (CurrentRobots+CurrentHumans)/ratio;
            int rounded = RoundToCeil((CurrentRobots+CurrentHumans)/ratio);
            if (unrounded != rounded)
            {

              g_f_Damage_Bonus =  damage_bonus(float(MissingHumans));

            }
            else 
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

}

float damage_bonus(float x) {
    float base = Pow(2.75/ 1.0, 1.0 / 12.0);
    return 1.0 * Pow(base, x);
}

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

        MC_PrintToChatAll("{green}%i{orange} Robot-slot available! Type {green}!join{orange} to become a giant robot!", islots);

        b_g_high_power = true;
        return false;
    }

    if (!IsClientInGame(newVolunteer)){

        return false;
    }else
    {

    }

    SMLogTag(SML_VERBOSE, "turning %L into a robot", newVolunteer);

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

    ChangeClientTeam(client, team);

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

            TF2_SetPlayerClass(client, TFClass_Heavy);
        }

    }

    SetVariantString(model);
    AcceptEntityInput(client, "SetCustomModel");
    SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

}

bool IsPaidRobot(int clientId, char robotName[NAMELENGTH])
{
    Robot robot;
    GetRobotDefinition(robotName, robot);

    RobotCoins robotCoins = robot.restrictions.GetRobotCoinsFor(clientId);
    return robotCoins.Active;
}