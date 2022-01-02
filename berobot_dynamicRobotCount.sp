#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
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

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_dynamicRobotCount started at %i", GetTime());

    _enabledConVar = CreateConVar("sm_berobot_dynamicRobotCount_enable", "1", "enables dynamically setting sm_robocap_team from the ratio of humans-to-robot");
    _enabledConVar.AddChangeHook(EnabledConVarChangeHook);
    _enabled = _enabledConVar.BoolValue;

    _humansPerRobotConVar = CreateConVar("sm_berobot_dynamicRobotCount_humansPerRobot", "3.5", "ratio of humans-to-robot for dynamic robot count calculation");
    _humansPerRobotConVar.AddChangeHook(RoboCapTeamHumansPerRobotConVarChangeHook);
    _humansPerRobot = _humansPerRobotConVar.FloatValue;
}

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

public void OnClientPutInServer(int client)
{
    SetRoboCapTeam();
}

public void OnClientDisconnect_Post(int client)
{
    SetRoboCapTeam();
}

void SetRoboCapTeam()
{
    if (!_enabled)
        return;

    int count = GetClientCount();
    float ratio = _humansPerRobot +1.0;
    int robotCount = RoundToCeil(count/ratio);

    SMLogTag(SML_VERBOSE, "setting %s to %i for %i players", CONVAR_ROBOCAP_TEAM, robotCount, count);
    _roboCapTeamConVar.SetInt(robotCount);

    EnsureRobotCount();
}