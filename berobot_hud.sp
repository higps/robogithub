#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sm_logger>
#include <morecolors_newsyntax>
#include <team_round_timer>
#include <berobot_constants>
#include <berobot_core_restrictions>
#include <berobot>

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

public Plugin myinfo =
{
	name = "berobot_hud",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

Handle _hudSynchronizer;
Handle _timer;

public void OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_hud started at %i", GetTime());

    _hudSynchronizer = CreateHudSynchronizer();
    if (IsEnabled())
        Start();
}

public void MM_OnEnabledChanged(int enabled)
{
    //aSMLOGTag(SML_VERBOSE, "MM_OnEnabledChanged called at %i with value %i", GetTime(), enabled);
    if (enabled == 0)
    {
        Stop();
        return;
    }

    Start();
}

void Start()
{
    if (_timer != null)
    {
        KillTimer(_timer);
    }
    _timer = CreateTimer(1.0, DrawHud, _, TIMER_REPEAT);
}

void Stop()
{    
    if (_timer != null)
    {
        KillTimer(_timer);
        _timer = null;
    }
}

Action DrawHud(Handle timer)
{
    DrawTeamHud(TFTeam_Red, 255, 64, 64, 255);
    DrawTeamHud(TFTeam_Blue, 153, 204, 255, 255);

    return Plugin_Continue;
} 

void DrawTeamHud(TFTeam team, int r, int g, int b, int a)
{
    int robotCoins = GetRobotCoins(team);
    SetHudTextParams(-1.0, 0.05, 4.0, r, g, b, a, 0, 0.0, 0.0, 0.0);
    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;

        if (!IsAnyRobot(i))
            continue;

        TFTeam actualTeam = view_as<TFTeam>(GetClientTeam(i));
        if (actualTeam != team)
            continue;

        ShowSyncHudText(i, _hudSynchronizer, "robot-coins: %i", robotCoins);
    }
}