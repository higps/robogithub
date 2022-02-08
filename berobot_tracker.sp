#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors_newsyntax>
//#include <sm_logger>
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
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_tracker started at %i", GetTime());

    ResetMode();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("TrackRobot", Native_TrackRobot);
    CreateNative("TrackRobotCreation", Native_TrackRobotCreation);
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

public any Native_TrackRobot(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    char robotname[NAMELENGTH];
    GetNativeString(2, robotname, NAMELENGTH);
    //aSMLOGTag(SML_VERBOSE, "tracking %i as robot '%s'", clientId, robotname);

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

    // if (IsLogAllowed(SML_VERBOSE))
    // {
    //     char loggingRobotname[NAMELENGTH];
    //     int robotCount;
    //     StringMapSnapshot robotNames = _robotCount.Snapshot();
    //     for(int i = 0; i < robotNames.Length; i++)
    //     {
    //         robotNames.GetKey(i, loggingRobotname, NAMELENGTH);
    //         _robotCount.GetValue(loggingRobotname, robotCount);
    //         //aSMLOGTag(SML_VERBOSE, "tracking %i players as robot '%s'", robotCount, loggingRobotname);
    //     }
    // }
}

public any Native_TrackRobotCreation(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    bool created = GetNativeCell(2);
    //aSMLOGTag(SML_VERBOSE, "tracking client %i robot-creation '%b'", clientId, created);

    _robotIsCreated[clientId] = created;
}

public any Native_GetRobotCount(Handle plugin, int numParams)
{
    char robotname[NAMELENGTH];
    GetNativeString(1, robotname, NAMELENGTH);
    
    if (_robotCount == null)
    {
        int value = 0;
        //aSMLOGTag(SML_VERBOSE, "returning count %i for '%s', because plugin is not yet initialized", value, robotname);
        return value;
    }

    int value = 0;
    _robotCount.GetValue(robotname, value);

    //aSMLOGTag(SML_VERBOSE, "returning count %i for '%s'", value, robotname);
    return value;
}

public any Native_IsRobot(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!IsValidClient(client))
        return false;
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
    //aSMLOGTag(SML_VERBOSE, "resetting mode");

    if (_robotCount == null)
        _robotCount = new StringMap();
    _robotCount.Clear();
    for(int i = 0; i <= MaxClients; i++)
    {
        _isRobot[i] = "";
        _robotIsCreated[i] = false;
    }
}
