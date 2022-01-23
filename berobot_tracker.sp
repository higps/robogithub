#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors_newsyntax>
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
	name = "berobot_tracker",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};


char _isRobot[MAXPLAYERS + 1][NAMELENGTH];
bool _robotIsCreated[MAXPLAYERS + 1];
StringMap _robotCount;

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_tracker started at %i", GetTime());

    ResetMode();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("TrackRobot", Native_TrackRobot);
	CreateNative("GetRobotCount", Native_GetRobotCount);
	CreateNative("IsRobot", Native_IsRobot);
    CreateNative("IsRobotWhenDead", Native_IsRobotWhenDead);
	CreateNative("IsAnyRobot", Native_IsAnyRobot);
    CreateNative("IsBoss", Native_IsBoss);
	CreateNative("GetRobot", Native_GetRobot);

	return APLRes_Success;
}

public void MM_ModeResetRequested()
{
    ResetMode();
}

public void OnClientDisconnect(int clientId)
{
    TrackRobot(clientId, "");
}

public void Event_Player_Spawned(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client))
        return;

    _robotIsCreated[client] = false;
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int deathflags = GetEventInt(event, "death_flags");
    SMLogTag(SML_VERBOSE, "Event_Death for %L received with name %s, dontBroadcast %b and deathflags %i", client, name, dontBroadcast, deathflags);

    if ((deathflags & TF_DEATHFLAG_DEADRINGER))
    {
        SMLogTag(SML_VERBOSE, "skipped Event_Death, because %i is dead-ringering", client);
        return;
    }
    
    if(!IsValidClient(client))
    {
        SMLogTag(SML_VERBOSE, "skipped Event_Death, because %i is not a valid client", client);
        return;
    }
    
    if(_isRobot[client][0] == '\0')
    {
        SMLogTag(SML_VERBOSE, "skipped Event_Death, because %L is no robot", client);
        return;
    }

    Robot item;
    if (GetRobotDefinition(_isRobot[client], item) != 0)
    {
        SMLogTag(SML_ERROR, "skipped Event_Death, because no robot with name '%s' found for %L", _isRobot[client], client);
        return;
    }

    _robotIsCreated[client] = false;    
}

public any Native_TrackRobot(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    char robotname[NAMELENGTH];
    GetNativeString(2, robotname, NAMELENGTH);
    SMLogTag(SML_VERBOSE, "tracking %L as robot '%s'", clientId, robotname);

    bool created = false;
    if (numParams >= 3)
        created = GetNativeCell(3);
    _robotIsCreated[clientId] = created;

    if (strcmp(_isRobot[clientId], robotname) == 0)
        return;

    _isRobot[clientId] = robotname;

    if (robotname[0] == '\0')
        _robotIsCreated[clientId] = false;

    _robotCount.Clear();
    for(int i = 0; i <= MaxClients; i++)
    {
        if (_isRobot[i][0] == '\0')
            continue;

        int value = 0;
        _robotCount.GetValue(_isRobot[i], value);
        _robotCount.SetValue(_isRobot[i], value + 1);
    }

    if (IsLogAllowed(SML_VERBOSE))
    {
        char loggingRobotname[NAMELENGTH];
        int robotCount;
        StringMapSnapshot robotNames = _robotCount.Snapshot();
        for(int i = 0; i <= robotNames.Length; i++)
        {
            robotNames.GetKey(i, loggingRobotname, NAMELENGTH);
            _robotCount.GetValue(loggingRobotname, robotCount);
            SMLogTag(SML_VERBOSE, "tracking %i players as robot '%s'", robotCount, loggingRobotname);
        }
    }
}

public any Native_GetRobotCount(Handle plugin, int numParams)
{
    char robotname[NAMELENGTH];
    GetNativeString(1, robotname, NAMELENGTH);

    int value = 0;
    _robotCount.GetValue(robotname, value);

    SMLogTag(SML_VERBOSE, "returning count %i for '%s'", value, robotname);
    return value;
}

public any Native_IsRobot(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!_robotIsCreated[client])
        return false;

    char name[NAMELENGTH];
    GetNativeString(2, name, NAMELENGTH);

    return strcmp(_isRobot[client], name) == 0;
}

public any Native_IsRobotWhenDead(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char name[NAMELENGTH];
    GetNativeString(2, name, NAMELENGTH);

    return strcmp(_isRobot[client], name) == 0;
}

public any Native_IsAnyRobot(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return _isRobot[client][0] != '\0';
}

public any Native_IsBoss(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char robotName[NAMELENGTH];

    Robot robot;
    GetRobot(client, robotName, NAMELENGTH);
    GetRobotDefinition(robotName, robot);


    if (StrEqual(robot.role,"ZBOSS"))
    {
       // PrintToChatAll("Robot role from factory: %s", robot.role);
        
        return true;
    }else
    {
        return false;
    }
}

public any Native_GetRobot(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int maxDestLength = GetNativeCell(3);

	SetNativeString(2, _isRobot[client], maxDestLength);
}

void ResetMode()
{
    if (_robotCount == null)
        _robotCount = new StringMap();
    _robotCount.Clear();
    for(int i = 0; i <= MaxClients; i++)
    {
        _isRobot[i] = "";
        _robotIsCreated[i] = false;
    }
}
