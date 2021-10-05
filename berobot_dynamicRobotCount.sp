#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <sm_logger>
#include <berobot_constants>

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

ConVar _roboCapTeamHumansPerRobotConVar;
float _roboCapTeamHumansPerRobot;
ConVar _roboCapTeamConVar;

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_dynamicRobotCount started at %i", GetTime());

    _roboCapTeamHumansPerRobotConVar = CreateConVar("sm_robocap_team_humansPerRobot", "3.0", "ratio of humans-to-robot for dynamic robot count calculation");
    _roboCapTeamHumansPerRobotConVar.AddChangeHook(RoboCapTeamHumansPerRobotConVarChangeHook);
    _roboCapTeamHumansPerRobot = _roboCapTeamHumansPerRobotConVar.FloatValue;

    _roboCapTeamConVar = FindConVar(CONVAR_ROBOCAP_TEAM);
}

public void RoboCapTeamHumansPerRobotConVarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _roboCapTeamHumansPerRobot = StringToFloat(sNewValue);
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
    int count = GetClientCount();
    float ratio = _roboCapTeamHumansPerRobot +1;
    int robotCount = RoundToCeil(count/ratio);

    SMLogTag(SML_VERBOSE, "setting %s to %i for %i players", CONVAR_ROBOCAP_TEAM, robotCount, count);
    _roboCapTeamConVar.SetInt(robotCount);
}