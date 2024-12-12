#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <morecolors>
#include <team_round_timer>
#include <berobot_constants>
#include <berobot>
#include <berobot_core_restrictions>
#include <tf2_stocks>

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
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_restrictions_team_death started at %i", GetTime());

    if (!IsEnabled())
        return;

    Start();
}

public void MM_OnEnabledChanged(int enabled)
{
    SMLogTag(SML_VERBOSE, "MM_OnEnabledChanged called at %i with value %i", GetTime(), enabled);
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
    SMLogTag(SML_VERBOSE, "OnDeath called at %i", GetTime());

    
    int victimUserId = event.GetInt("userid", -1);
    int victimClientId = GetClientOfUserId(victimUserId);

    int attackerUserId = event.GetInt("attacker", -1);
    int attackerClientId = GetClientOfUserId(attackerUserId);


        int death_flags = GetEventInt(event, "death_flags");
    if((death_flags & TF_DEATHFLAG_DEADRINGER) != TF_DEATHFLAG_DEADRINGER)
    {
        // PrintToChatAll("Not deadringer");
    }else{
        return;
    } // Not a dead ringer death?
    if (IsAnyRobot(attackerClientId) && IsValidClient(victimClientId))
    {
        
        // int iattackerUserId = event.GetInt("attacker");
        // int iattackerClientId = GetClientOfUserId(attackerUserId);

        DataPack info = new DataPack();
        info.Reset();
        info.WriteCell(victimClientId);
        info.WriteCell(attackerClientId);

        CreateTimer(6.5, Timer_DeathTip, info);
        
    }

    if (!IsValidClient(victimClientId))
    {
        SMLogTag(SML_VERBOSE, "OnDeath canceled, because victim %i is invalid", victimClientId);
        return;
    }


    if (!IsValidClient(attackerClientId))
    {
        SMLogTag(SML_VERBOSE, "OnDeath canceled, because attacker %i is invalid", attackerClientId);
        return;
    }

    if (attackerClientId == victimClientId)
    {
        SMLogTag(SML_VERBOSE, "OnDeath canceled, because victim %L killed themselfs", victimClientId);
        return;
    }

    if (!IsAnyRobot(victimClientId))
    {
        SMLogTag(SML_VERBOSE, "OnDeath canceled, because victim %L was not a robot", victimClientId);
        return;
    }

    char weapon_logname[MAX_NAME_LENGTH];
	
    GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));

    if (StrEqual(weapon_logname, "player", true) || StrEqual(weapon_logname, "trigger", true) || StrEqual(weapon_logname, "world", true))
    {
       // PrintToChatAll("Logname %s", weapon_logname);
        SMLogTag(SML_VERBOSE, "OnDeath canceled, because victim logname was player");
        return;
    }

    char robotName[NAMELENGTH];
    GetRobot(victimClientId, robotName, NAMELENGTH);
    Robot robot;
    GetRobotDefinition(robotName, robot);

    int rewardedRobotCoins = robot.robotCoinsOnDeath;
    SMLogTag(SML_VERBOSE, "adding %i RobotCoins, because robot %L died", rewardedRobotCoins, victimClientId);
    AddRobotCoinsFor(victimClientId, rewardedRobotCoins);

    int rewardedTeamCoins = robot.teamCoinsOnDeath;
    SMLogTag(SML_VERBOSE, "adding %i TeamCoins, because robot %L died", rewardedTeamCoins, victimClientId);
    AddTeamCoinsFor(victimClientId, rewardedTeamCoins);

}

public Action Timer_DeathTip(Handle timer, DataPack info)
{

    info.Reset();
    int victimClientId = info.ReadCell();
    int attackerClientId = info.ReadCell();
    delete info;
    if(IsClientInGame(victimClientId))
    {
    char robotName[NAMELENGTH];
    GetRobot(attackerClientId, robotName, NAMELENGTH);
    Robot robot;
    GetRobotDefinition(robotName, robot);

    PrintHintText(victimClientId,"Tip: %s", robot.deathtip);
    }
    return Plugin_Continue;
}