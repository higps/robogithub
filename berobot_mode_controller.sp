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
    CV_bDebugMode,
    CV_flYoutuberMode,
    CV_g_RoboCapTeam,
    CV_g_RoboCap,
    CV_g_RoboStartTeam,
    CV_PluginVersion
}

enum {
    dmg_method_on_target,
    dmg_method_off_target
}

ConVar g_cvCvarList[CV_PluginVersion + 1];
ConVar g_MannedMachinesModeConVar;
ConVar g_BothTeamsRobotsRatioConVar;
int g_MannedMachinesMode = 1;
bool g_RestoreHumanTeamPermission;
int g_PreviousHumanTeamPermission;
bool g_EnsuringBothTeamsRobots;
int g_StandardRobotCapTeam;

bool g_cv_bDebugMode;

bool g_BossMode = false;
bool g_cv_BlockTeamSwitch = false;
bool g_SpectateSelection = false;
bool g_WaitingForPlayers = true;

bool g_cv_Volunteered[MAXPLAYERS + 1];
char g_cv_RobotPicked[MAXPLAYERS + 1][NAMELENGTH];

GlobalForward _enabledChangedForward;
GlobalForward _clientResetting;
GlobalForward _modeResetRequestedForward;

GlobalForward _wasRandomRobotForward;


int g_CV_flYoutuberMode;
int g_Enable;
int g_RoboCapTeam;
int g_RoboTeam;
int g_HumanTeam;
int g_RoboCap;
int g_RoboStartTeam;
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


    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_mm_debug", "0", "Enable Debugging for Manned Machines Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_g_RoboCapTeam] = CreateConVar(CONVAR_ROBOCAP_TEAM, "6", "The total amount of giant robots on a team");  
    g_cvCvarList[CV_g_RoboCap] = CreateConVar("sm_robocap", "1", "The amount of giant robots allowed per robot-type");
    g_cvCvarList[CV_g_RoboStartTeam] = CreateConVar("sm_robot_random_start_team", "1", "0 = Robots always start on red, 1 = Robot team is randomly picked RED or BLUE, 2 = Robots Always starts on blue");


    g_cvCvarList[CV_flYoutuberMode] = CreateConVar("sm_mm_yt_mode", "0", "Uses youtuber mode for the official mode to set youtubers as the proper classes");


    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);

    g_RoboCapTeam = GetConVarInt(g_cvCvarList[CV_g_RoboCapTeam]);
    g_RoboCap = GetConVarInt(g_cvCvarList[CV_g_RoboCap]);
    g_RoboStartTeam = GetConVarInt(g_cvCvarList[CV_g_RoboStartTeam]);
    g_CV_flYoutuberMode = GetConVarInt(g_cvCvarList[CV_flYoutuberMode]);

    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);

    g_cvCvarList[CV_flYoutuberMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCapTeam].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCap].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboStartTeam].AddChangeHook(CvarChangeHook);

    _enabledChangedForward = new GlobalForward("MM_OnEnabledChanged", ET_Ignore, Param_Cell);
    _clientResetting = new GlobalForward("MM_OnClientResetting", ET_Ignore, Param_Cell);
    _modeResetRequestedForward = new GlobalForward("MM_ModeResetRequested", ET_Ignore);

    _wasRandomRobotForward = new GlobalForward("MM_WasRandomRobotForward", ET_Ignore, Param_Cell);

    RegAdminCmd("sm_makerobot", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_mr", Command_BeRobot, ADMFLAG_SLAY, "Become a robot");
    RegAdminCmd("sm_boss_mode", Command_YT_Robot_Start, ADMFLAG_SLAY, "Starts or stops the selected Manned Machines mode");
    RegAdminCmd("sm_selection_mode", Command_Robot_Selection, ADMFLAG_SLAY, "Forces selection mode");

    RegAdminCmd("sm_me_boss", Command_Me_Boss, ADMFLAG_SLAY, "Checks if you are a boss");
    RegAdminCmd("sm_random_robot", Command_SetRandomRobot, ADMFLAG_SLAY, "Sets a random robot");
    RegAdminCmd("sm_toggle_team_switch", Command_ToggleTeamSwitch, ADMFLAG_SLAY, "Toggles allowing teamswitch");

    RegConsoleCmd("sm_changerobot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_chngrbt", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_cr", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_bot", Command_ChangeRobot, "change your robot");
    RegConsoleCmd("sm_robot", Command_ChangeRobot, "change your robot");

    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_Waiting_Abouttoend, EventHookMode_Post);

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_team", Event_PlayerTeamChanged, EventHookMode_Post);

    g_Volunteers = new ArrayList(ByteCountToCells(g_RoboCapTeam));

    g_Volunteers.Clear();

    g_MannedMachinesModeConVar = CreateConVar("sm_manned_machines_mode", "1", "0 = Off, 1 = Standard, 2 = April (everyone is a robot), 3 = Volunteers distributed across both teams", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    g_BothTeamsRobotsRatioConVar = CreateConVar("both_team_has_robots_ratio", "3", "Total players per robot on each team in mode 3", FCVAR_NOTIFY, true, 1.0);
    g_BothTeamsRobotsRatioConVar.AddChangeHook(BothTeamsRobotsRatioChanged);
    g_MannedMachinesModeConVar.AddChangeHook(MannedMachinesModeChanged);
    ApplyMannedMachinesMode(false);
}

public void OnConfigsExecuted()
{
    ApplyMannedMachinesMode(false);
}

public void OnPluginEnd()
{
    if (g_RestoreHumanTeamPermission)
    {
        ConVar permission = FindConVar("sm_allow_robots_on_human_team");
        if (permission != null)
            permission.SetInt(g_PreviousHumanTeamPermission);
    }
}

public void MannedMachinesModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ApplyMannedMachinesMode(true);
}

public void BothTeamsRobotsRatioChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_MannedMachinesMode == 3)
    {
        UpdateBothTeamsRobotTarget();
        EnsureRobotCount();
    }
}

int GetRobotTargetForPlayerCount(int players)
{
    float ratio = g_BothTeamsRobotsRatioConVar.FloatValue;
    if (players == 0)
        return 0;
    if (float(players) <= ratio)
        return 1;
    int target = RoundToFloor(float(players) / ratio) + 1;
    return target > players ? players : target;
}

int GetBothTeamsRobotTarget(int team)
{
    if (team != view_as<int>(TFTeam_Red) && team != view_as<int>(TFTeam_Blue))
        return 0;
    int redPlayers = GetTeamClientCount(TFTeam_Red);
    int bluePlayers = GetTeamClientCount(TFTeam_Blue);
    int redTarget = GetRobotTargetForPlayerCount(redPlayers);
    int blueTarget = GetRobotTargetForPlayerCount(bluePlayers);
    int target = redTarget > blueTarget ? redTarget : blueTarget;
    int smallerTeam = redPlayers < bluePlayers ? redPlayers : bluePlayers;
    return target > smallerTeam ? smallerTeam : target;
}

void UpdateBothTeamsRobotTarget()
{
    g_cvCvarList[CV_g_RoboCapTeam].SetInt(GetBothTeamsRobotTarget(TFTeam_Red) + GetBothTeamsRobotTarget(TFTeam_Blue));
}

int GetAssignedRobotCount(int team)
{
    int count;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client) && g_cv_Volunteered[client] && GetClientTeam(client) == team)
            count++;
    }
    return count;
}

int ChooseBothTeamsRobotTeam(int client)
{
    int redCount = GetAssignedRobotCount(TFTeam_Red);
    int blueCount = GetAssignedRobotCount(TFTeam_Blue);
    bool redAvailable = redCount < GetBothTeamsRobotTarget(TFTeam_Red);
    bool blueAvailable = blueCount < GetBothTeamsRobotTarget(TFTeam_Blue);
    if (!redAvailable && !blueAvailable)
        return TFTeam_Unassigned;
    if (!redAvailable)
        return TFTeam_Blue;
    if (!blueAvailable)
        return TFTeam_Red;
    if (redCount == blueCount)
        return GetClientTeam(client) == TFTeam_Blue ? TFTeam_Blue : TFTeam_Red;
    return redCount < blueCount ? TFTeam_Red : TFTeam_Blue;
}

void MoveBothTeamsVolunteer(int client, int team)
{
    int oldTeam = GetClientTeam(client);
    if (oldTeam == team)
        return;
    for (int human = 1; human <= MaxClients; human++)
    {
        if (IsValidClient(human) && !g_cv_Volunteered[human] && !IsAnyRobot(human) && GetClientTeam(human) == team)
        {
            TF2_SwapTeamAndRespawnNoMsg(human, oldTeam);
            TF2_RespawnPlayer(human);
            break;
        }
    }
    TF2_SwapTeamAndRespawnNoMsg(client, team);
    TF2_RespawnPlayer(client);
}

void BalanceBothTeamsPlayers()
{
    while (GetTeamClientCount(TFTeam_Red) > GetTeamClientCount(TFTeam_Blue) + 1
        || GetTeamClientCount(TFTeam_Blue) > GetTeamClientCount(TFTeam_Red) + 1)
    {
        int largerTeam = GetTeamClientCount(TFTeam_Red) > GetTeamClientCount(TFTeam_Blue)
            ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
        int smallerTeam = largerTeam == view_as<int>(TFTeam_Red)
            ? view_as<int>(TFTeam_Blue) : view_as<int>(TFTeam_Red);
        int player;
        for (int pass = 0; pass < 2 && player == 0; pass++)
        {
            for (int client = MaxClients; client >= 1; client--)
            {
                if (!IsValidClient(client) || GetClientTeam(client) != largerTeam)
                    continue;
                if (pass == 0 && (g_cv_Volunteered[client] || IsAnyRobot(client)))
                    continue;
                player = client;
                break;
            }
        }
        if (player == 0)
            break;
        ChangeClientTeam(player, smallerTeam);
        TF2_RespawnPlayer(player);
    }
}

void BalanceBothTeamsRobotAssignments()
{
    while (GetAssignedRobotCount(TFTeam_Red) > GetAssignedRobotCount(TFTeam_Blue) + 1
        || GetAssignedRobotCount(TFTeam_Blue) > GetAssignedRobotCount(TFTeam_Red) + 1)
    {
        int largerTeam = GetAssignedRobotCount(TFTeam_Red) > GetAssignedRobotCount(TFTeam_Blue)
            ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
        int smallerTeam = largerTeam == view_as<int>(TFTeam_Red)
            ? view_as<int>(TFTeam_Blue) : view_as<int>(TFTeam_Red);
        if (GetAssignedRobotCount(smallerTeam) >= GetBothTeamsRobotTarget(smallerTeam))
            break;
        int player;
        for (int client = MaxClients; client >= 1; client--)
        {
            if (IsValidClient(client) && g_cv_Volunteered[client] && GetClientTeam(client) == largerTeam)
            {
                player = client;
                break;
            }
        }
        if (player == 0)
            break;
        MoveBothTeamsVolunteer(player, smallerTeam);
    }
}

void StartBothTeamsRobotMode()
{
    g_BossMode = true;
    g_cv_BlockTeamSwitch = false;
    g_RoboTeam = TFTeam_Unassigned;
    g_HumanTeam = TFTeam_Unassigned;
    ServerCommand("mp_forceautoteam 0");
    ServerCommand("mp_teams_unbalance_limit 1");
    ServerCommand("mp_autoteambalance 0");
    ServerCommand("mp_scrambleteams_auto 0");
    ServerCommand("sm_cvar tf_dropped_weapon_lifetime 0");
    ServerCommand("mp_restartgame 5");

    int redCount;
    int blueCount;
    for (int pass = 0; pass < 2; pass++)
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsValidClient(client) || GetClientTeam(client) < view_as<int>(TFTeam_Red))
                continue;
            if (g_cv_Volunteered[client] != (pass == 0))
                continue;
            int team = redCount <= blueCount ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
            TF2_SwapTeamAndRespawnNoMsg(client, team);
            if (team == view_as<int>(TFTeam_Red)) redCount++;
            else blueCount++;
            if (g_cv_Volunteered[client]) RequestFrame(Internal_SetRandomRobot, client);
        }
    }
    EnsureBothTeamsRobotCount();
}

void EnsureBothTeamsRobotCount()
{
    if (g_EnsuringBothTeamsRobots || !g_Enable || !g_BossMode || g_MannedMachinesMode != 3)
        return;
    g_EnsuringBothTeamsRobots = true;
    BalanceBothTeamsPlayers();
    UpdateBothTeamsRobotTarget();
    BalanceBothTeamsRobotAssignments();

    for (int team = view_as<int>(TFTeam_Red); team <= view_as<int>(TFTeam_Blue); team++)
    {
        for (int client = MaxClients; client >= 1 && GetAssignedRobotCount(team) > GetBothTeamsRobotTarget(team); client--)
        {
            if (!IsValidClient(client) || !g_cv_Volunteered[client] || GetClientTeam(client) != team)
                continue;
            g_cv_Volunteered[client] = false;
            g_cv_RobotPicked[client] = "";
            int index = g_Volunteers.FindValue(client);
            if (index >= 0) g_Volunteers.Erase(index);
            TrashRobot(client);
            TF2_RegeneratePlayer(client);
        }
    }

    while (GetAssignedRobotCount(TFTeam_Red) < GetBothTeamsRobotTarget(TFTeam_Red)
        || GetAssignedRobotCount(TFTeam_Blue) < GetBothTeamsRobotTarget(TFTeam_Blue))
    {
        int[] ignored = new int[MaxClients + 1];
        int ignoredCount;
        for (int client = 1; client <= MaxClients; client++)
        {
            if (IsValidClient(client) && (g_cv_Volunteered[client] || GetClientTeam(client) < view_as<int>(TFTeam_Red)))
                ignored[ignoredCount++] = GetClientUserId(client);
        }
        int volunteer = GetRandomVolunteer(ignored, ignoredCount);
        if (!IsValidClient(volunteer))
            break;
        if (GetAssignedRobotCount(TFTeam_Red) == GetAssignedRobotCount(TFTeam_Blue))
        {
            ignored[ignoredCount++] = GetClientUserId(volunteer);
            int partner = GetRandomVolunteer(ignored, ignoredCount);
            if (!IsValidClient(partner))
                break;
            MakeRobot(volunteer, true);
            MakeRobot(partner, true);
        }
        else
        {
            MakeRobot(volunteer, true);
        }
    }

    while (GetAssignedRobotCount(TFTeam_Red) != GetAssignedRobotCount(TFTeam_Blue))
    {
        int largerTeam = GetAssignedRobotCount(TFTeam_Red) > GetAssignedRobotCount(TFTeam_Blue)
            ? view_as<int>(TFTeam_Red) : view_as<int>(TFTeam_Blue);
        int player;
        for (int client = MaxClients; client >= 1; client--)
        {
            if (IsValidClient(client) && g_cv_Volunteered[client] && GetClientTeam(client) == largerTeam)
            {
                player = client;
                break;
            }
        }
        if (player == 0)
            break;
        g_cv_Volunteered[player] = false;
        g_cv_RobotPicked[player] = "";
        int index = g_Volunteers.FindValue(player);
        if (index >= 0) g_Volunteers.Erase(index);
        TrashRobot(player);
        TF2_RegeneratePlayer(player);
    }
    g_EnsuringBothTeamsRobots = false;
}

void ApplyMannedMachinesMode(bool transition)
{
    int mode = g_MannedMachinesModeConVar.IntValue;
    bool changed = mode != g_MannedMachinesMode;
    bool wasActive = g_BossMode;
    int previousEnable = g_Enable;
    int previousMode = g_MannedMachinesMode;

    if (changed && mode == 3)
        g_StandardRobotCapTeam = g_RoboCapTeam;

    if (transition && changed)
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (IsValidClient(client) && IsAnyRobot(client))
            {
                TrashRobot(client);
            }
        }
        ResetMode();
    }

    g_MannedMachinesMode = mode;
    g_AprilEnable = mode == 2 ? 1 : 0;
    g_Enable = mode == 0 ? 0 : 1;
    if (mode == 3)
        UpdateBothTeamsRobotTarget();
    else if (changed && previousMode == 3)
    {
        ConVar dynamicEnabled = FindConVar("sm_berobot_dynamicRobotCount_enable");
        ConVar standardRatio = FindConVar("sm_berobot_dynamicRobotCount_humansPerRobot");
        int target = g_StandardRobotCapTeam;
        if (dynamicEnabled != null && dynamicEnabled.BoolValue && standardRatio != null && standardRatio.FloatValue > 0.0)
        {
            target = RoundToCeil(float(GetTeamClientCount(TFTeam_Red) + GetTeamClientCount(TFTeam_Blue)) / standardRatio.FloatValue);
            if (target < 1) target = 1;
        }
        g_cvCvarList[CV_g_RoboCapTeam].SetInt(target);
    }
    if (previousEnable != g_Enable)
    {
        Call_StartForward(_enabledChangedForward);
        Call_PushCell(g_Enable);
        Call_Finish();
    }

    ConVar permission = FindConVar("sm_allow_robots_on_human_team");
    if (permission != null)
    {
        if (mode == 2 || mode == 3)
        {
            if (!g_RestoreHumanTeamPermission)
            {
                g_PreviousHumanTeamPermission = permission.IntValue;
                g_RestoreHumanTeamPermission = true;
            }
            permission.SetInt(1);
        }
        else if (g_RestoreHumanTeamPermission)
        {
            permission.SetInt(g_PreviousHumanTeamPermission);
            g_RestoreHumanTeamPermission = false;
        }
    }

    if (transition && changed)
    {
        if (mode == 0)
        {
            ServerCommand("mp_forceautoteam 1");
            ServerCommand("sm_cvar tf_dropped_weapon_lifetime 30");
            ServerCommand("mp_teams_unbalance_limit 1");
            ServerCommand("mp_autoteambalance 1");
            ServerCommand("mp_scrambleteams_auto 1");
        }
        else if (wasActive || !g_WaitingForPlayers)
        {
            Command_Robot_Selection(0, 0);
        }
    }
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
    g_Volunteers.Clear();

    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        g_cv_Volunteered[i] = false;
        g_cv_RobotPicked[i] = "";

    }


    Call_StartForward(_modeResetRequestedForward);
    Call_Finish();
}

public void OnClientDisconnect_Post(int client)
{
    Reset(client);
    if (g_MannedMachinesMode == 3)
        RequestFrame(EnsureBothTeamsRobotCountFrame);
}

public void Event_PlayerTeamChanged(Event event, const char[] name, bool dontBroadcast)
{
    if (g_MannedMachinesMode == 3)
        RequestFrame(EnsureBothTeamsRobotCountFrame);
}

void EnsureBothTeamsRobotCountFrame(any data)
{
    EnsureBothTeamsRobotCount();
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
    if (!g_Enable || !IsValidClient(client))
        return Plugin_Continue;
    if (!g_AprilEnable) RequestFrame(RobotTeamCheck, client);
    if (!IsAnyRobot(client) && g_AprilEnable && g_BossMode && g_Enable)
    {
        CreateTimer(0.1, SetRandomRobot_Timer, client);
    }
    return Plugin_Continue;
}

public Action SetRandomRobot_Timer(Handle timer, any client)
{

    if (g_Enable && g_AprilEnable && g_BossMode && IsValidClient(client) && !IsAnyRobot(client))
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


}

public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{
    if (g_Enable && g_MannedMachinesMode == 3)
    {
        if (GameRules_GetProp("m_bSwitchedTeamsThisRound")) ResetCoins();
        EnsureBothTeamsRobotCount();
        return Plugin_Continue;
    }

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


    if(convar == g_cvCvarList[CV_g_RoboCap])
        g_RoboCap = StringToInt(sNewValue);

    if(convar == g_cvCvarList[CV_g_RoboCapTeam])
    {   
        g_RoboCapTeam = StringToInt(sNewValue);
        if (g_Enable) PrintToChatAll("Current Robots: %i", g_RoboCapTeam);
    }

}

public any Native_GetRobotTeam(Handle plugin, int numParams)
{
    return g_RoboTeam;
}

void RobotTeamCheck(int client)
{
    if (!g_Enable || g_AprilEnable || !g_BossMode || !IsValidClient(client))
        return;
    if (g_MannedMachinesMode == 3)
    {
        if (GetClientTeam(client) < view_as<int>(TFTeam_Red))
        {
            if (g_cv_Volunteered[client]) Reset(client);
            if (IsAnyRobot(client)) TrashRobot(client);
        }
        else if (g_cv_Volunteered[client])
        {
            if (!IsAnyRobot(client)) Internal_SetRandomRobot(client);
        }
        else if (IsAnyRobot(client))
        {
            TrashRobot(client);
        }
        EnsureBothTeamsRobotCount();
        return;
    }
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
    if (g_Enable && g_MannedMachinesMode == 3)
    {
        UpdateBothTeamsRobotTarget();
        g_cv_BlockTeamSwitch = false;
        StartAutomaticVolunteerVote();
        return Plugin_Handled;
    }

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
    if (g_Enable && g_BossMode)
    {
        PrintCenterTextAll("Stopping Manned Machines mode");
        for (int player = 1; player <= MaxClients; player++)
        {
            if (IsValidClient(player) && IsAnyRobot(player))
                TrashRobot(player);
        }
        ServerCommand("mp_forceautoteam 1");
        ServerCommand("sm_cvar tf_dropped_weapon_lifetime 30");
        ServerCommand("mp_teams_unbalance_limit 1");
        ServerCommand("mp_restartgame 5");
        ServerCommand("mp_autoteambalance 1");
        ServerCommand("mp_scrambleteams_auto 1");
        ResetMode();
        return Plugin_Handled;
    }

    if (g_Enable && g_MannedMachinesMode == 3)
    {
        StartBothTeamsRobotMode();
        return Plugin_Handled;
    }

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
        ReplyToCommand(client, "Manned Machines is off. Select a mode with sm_manned_machines_mode 1, 2 or 3.");
    }
    return Plugin_Handled;
}

public Action Command_ChangeRobot(int client, int args)
{
    if (g_MannedMachinesMode == 3 && !g_cv_Volunteered[client])
    {
        MM_PrintToChat(client, "Volunteer with !join to become a robot.");
        return Plugin_Handled;
    }

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
    if (iTeam == g_RoboTeam || g_AprilEnable || (g_MannedMachinesMode == 3 && g_cv_Volunteered[client]))
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
        return Plugin_Handled;
    }

    if (g_MannedMachinesMode == 3)
    {
        if (!IsValidClient(client) || GetClientTeam(client) < view_as<int>(TFTeam_Red))
            return Plugin_Handled;
        if (volunteering && !g_cv_Volunteered[client])
        {
            int team = ChooseBothTeamsRobotTeam(client);
            if (team == view_as<int>(TFTeam_Unassigned))
                return Plugin_Handled;
            if (g_BossMode) MoveBothTeamsVolunteer(client, team);
            g_cv_Volunteered[client] = true;
            g_Volunteers.Push(client);
            if (g_BossMode) RequestFrame(Internal_SetRandomRobot, client);
        }
        else if (!volunteering && g_cv_Volunteered[client])
        {
            g_cv_Volunteered[client] = false;
            int index = g_Volunteers.FindValue(client);
            if (index >= 0) g_Volunteers.Erase(index);
            g_cv_RobotPicked[client] = "";
            TrashRobot(client);
            TF2_RegeneratePlayer(client);
            EnsureBothTeamsRobotCount();
        }
        return Plugin_Handled;
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

        return Plugin_Handled;
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
    if (!g_Enable || !IsValidClient(client) || (g_MannedMachinesMode == 3 && !g_cv_Volunteered[client]))
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
    if (g_MannedMachinesMode == 3 && (!IsValidClient(client) || !g_cv_Volunteered[client] || GetClientTeam(client) < view_as<int>(TFTeam_Red)))
    {
        if (IsValidClient(client)) MM_PrintToChat(client, "Volunteer with !join to become a robot.");
        return;
    }

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
    if (g_MannedMachinesMode == 3)
        return Plugin_Continue;
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
    if (g_MannedMachinesMode == 3 && g_Enable && !g_BossMode)
        StartBothTeamsRobotMode();
}
bool g_b_changed_dmg = false;
bool g_b_broadcast_msg = false;

int Native_EnsureRobotCount(Handle plugin, int numParams)
{
    if (g_MannedMachinesMode == 3)
    {
        EnsureBothTeamsRobotCount();
        return 0;
    }
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