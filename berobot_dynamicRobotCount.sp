#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <morecolors>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
}
#include <berobot_core>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "berobot_dynamicRobotCount",
	author = "icebear",
	description = "sets the number of allowed robots based of a ratio of humans-to-robots",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

ConVar _enabledConVar;
bool _enabled;
ConVar _humansPerRobotConVar;
float _humansPerRobot;
ConVar _roboCapTeamConVar;
//bool g_timer;

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_dynamicRobotCount started at %i", GetTime());

    _enabledConVar = CreateConVar("sm_berobot_dynamicRobotCount_enable", "1", "enables dynamically setting sm_robocap_team from the ratio of humans-to-robot");
    _enabledConVar.AddChangeHook(EnabledConVarChangeHook);
    _enabled = _enabledConVar.BoolValue;

    _humansPerRobotConVar = CreateConVar("sm_berobot_dynamicRobotCount_humansPerRobot", "4.0", "ratio of humans-to-robot for dynamic robot count calculation");
    _humansPerRobotConVar.AddChangeHook(RoboCapTeamHumansPerRobotConVarChangeHook);
    _humansPerRobot = _humansPerRobotConVar.FloatValue;
    

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    //g_timer = false;
}

// public void OnGameFrame()
// {
   
//    if (!g_timer)
//    {
//     CreateTimer(3.0, Timer_Check_Teams);
//    g_timer = true;
//    }
// }


// public Action Timer_Check_Teams(Handle timer)
// {
//     SetRoboCapTeam();
//     g_timer = false;
// }

public void OnConfigsExecuted()
{
    _roboCapTeamConVar = FindConVar(CONVAR_ROBOCAP_TEAM);
}

public void EnabledConVarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _enabled = _enabledConVar.BoolValue;
}

public void RoboCapTeamHumansPerRobotConVarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _humansPerRobot = StringToFloat(sNewValue);
}

// public void OnClientPutInServer(int client)
// {
//     SetRoboCapTeam();
// }

// public void OnClientDisconnect_Post(int client)
// {
//     SetRoboCapTeam();
// }

void SetRoboCapTeam()
{
    if (!_enabled)
        return;

    //int count = GetClientCount();

    // int Spectate = GetTeamClientCount(1);
    int Red = GetTeamClientCount(2);
    int Blue = GetTeamClientCount(3);

    // int count = Red+Blue+Spectate;
    int count = Red+Blue;
    // PrintToChatAll("Red Team had: %i players", Red);
    // PrintToChatAll("Blue Team had: %i players", Blue);
    // PrintToChatAll("Total player count was: %i", count);
    // PrintToChatAll("Spectate Team had: %i players", Spectate);

    // int robotteam = GetRobotTeam();
    // PrintToChatAll("Robot Team was %i", robotteam);

    float ratio = _humansPerRobot;
    int robotCount = RoundToCeil(count/ratio);
    // PrintToChatAll("Robocount was: %i", robotCount);
    if (robotCount == 0){
        robotCount = 1;
    }

// Code to account for low player counts
    // if (robotCount < 3 && count < 7 && count >= 5)
    // {
    //     robotCount ++;
    //     //PrintToChatAll("TRIGGERING LOW PLAYER CHANGE, ROBOT COUNT IS NOW %i", robotCount);
    // }
//    SMLogTag(SML_VERBOSE, "setting %s to %i for %i players", CONVAR_ROBOCAP_TEAM, robotCount, count);
    _roboCapTeamConVar.SetInt(robotCount);

    //RequestFrame(EnsureRobotCountDelay, robotCount);
    EnsureRobotCount();
}

// void EnsureRobotCountDelay(int roboCount){

// EnsureRobotCount();
// }

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    RequestFrame(SetRoboCapFrame);
}

void SetRoboCapFrame()
{
    SetRoboCapTeam();
}