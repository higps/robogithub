#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sm_logger>
#include <morecolors_newsyntax>
#include <team_round_timer>
#include <berobot_constants>
#include <berobot>
#include <berobot_core_restrictions>

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
	name = "berobot_restrictions_team_death",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_restrictions_team_death started at %i", GetTime());

    if (!IsEnabled())
        return;

    Start();
}

public void MM_OnEnabledChanged(int enabled)
{
    //aSMLOGTag(SML_VERBOSE, "MM_OnEnabledChanged called at %i with value %i", GetTime(), enabled);
    if (enabled == 0)
    {
        UnhookEvent("player_death",    OnDeath,   EventHookMode_PostNoCopy);
        return;
    }

    Start();
}

void Start()
{
    HookEvent("player_death",    OnDeath,   EventHookMode_PostNoCopy);
}

public void OnDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsEnabled())
    {
        return;
    }
    //aSMLOGTag(SML_VERBOSE, "OnDeath called at %i", GetTime());

    
    int victimUserId = event.GetInt("userid", -1);
    int victimClientId = GetClientOfUserId(victimUserId);
    if (!IsValidClient(victimClientId))
    {
        //aSMLOGTag(SML_VERBOSE, "OnDeath canceled, because victim %i is invalid", victimClientId);
        return;
    }

    int attackerUserId = event.GetInt("attacker", -1);
    int attackerClientId = GetClientOfUserId(attackerUserId);
    if (!IsValidClient(attackerClientId))
    {
        //aSMLOGTag(SML_VERBOSE, "OnDeath canceled, because attacker %i is invalid", attackerClientId);
        return;
    }

    if (attackerClientId == victimClientId)
    {
        //aSMLOGTag(SML_VERBOSE, "OnDeath canceled, because victim %L killed themselfs", victimClientId);
        return;
    }

    if (!IsAnyRobot(victimClientId))
    {
        //aSMLOGTag(SML_VERBOSE, "OnDeath canceled, because victim %L was not a robot", victimClientId);
        return;
    }

    char weapon_logname[MAX_NAME_LENGTH];
	
    GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));

    if (StrEqual(weapon_logname, "player", true) || StrEqual(weapon_logname, "trigger", true) || StrEqual(weapon_logname, "world", true))
    {
       // PrintToChatAll("Logname %s", weapon_logname);
        //aSMLOGTag(SML_VERBOSE, "OnDeath canceled, because victim logname was player");
        return;
    }

    char robotName[NAMELENGTH];
    GetRobot(victimClientId, robotName, NAMELENGTH);
    Robot robot;
    GetRobotDefinition(robotName, robot);

    int rewardedRobotCoins = robot.robotCoinsOnDeath;
    //aSMLOGTag(SML_VERBOSE, "adding %i RobotCoins, because robot %L died", rewardedRobotCoins, victimClientId);
    AddRobotCoinsFor(victimClientId, rewardedRobotCoins);
}