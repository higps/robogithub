#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
//#include <sm_logger>
#include <berobot_constants>
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
	name = "berobot_storage",
	author = "icebear",
	description = "",
	version = "1.0",
	url = "https://github.com/higps/robogithub"
};

bool _init;
StringMap _robots;
GlobalForward _robotStorageChangedForward;

public void OnPluginStart()
{
	Init();
}

public void Init()
{
    if (_init)
        return;

    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_store started at %i", GetTime());

    _robots = new StringMap();
    _init = true;

    _robotStorageChangedForward = new GlobalForward("MM_OnRobotStorageChanged", ET_Ignore);
    RegAdminCmd("sm_dumpRobotStorage", Command_DumpRobotStorage, ADMFLAG_ROOT, "Dumps the current Robot-Storage (for debugging)");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AddRobot", Native_AddRobot);
	CreateNative("RemoveRobot", Native_RemoveRobot);
	CreateNative("GetRobotNames", Native_GetRobotNames);
	CreateNative("GetRobotClass", Native_GetRobotClass);
	CreateNative("GetRobotDefinition", Native_GetRobotDefinition);
	CreateNative("GetRobotRestrictions", Native_GetRobotRestrictions);

	return APLRes_Success;
}

void OnRobotStorageChanged()
{
    Call_StartForward(_robotStorageChangedForward);
    Call_Finish();
}

public Action Command_DumpRobotStorage(int client, int numParams)
{
    StringMapSnapshot snapshot = _robots.Snapshot();
    for(int i = 0; i < snapshot.Length; i++)
    {
        char name[NAMELENGTH];
        snapshot.GetKey(i, name, NAMELENGTH);

        Robot item;
        _robots.GetArray(name, item, sizeof(item));
        
        //aSMLOGTag(SML_INFO, "Robot {%s: %s, callback: %x, sounds: {spawn: %s}, restrictions: {timeLeft: %i}}", 
        //    item.name, item.class, item.callback, item.sounds.spawn, item.restrictions.TimeLeft);
    }
    }

public any Native_AddRobot(Handle plugin, int numParams)
{ 
    Init();

    RobotDefinition robotDefinition;
    GetNativeArray(1, robotDefinition, sizeof(robotDefinition));

    Function callback = GetNativeFunction(2);

    char pluginVersion[9];
    GetNativeString(3, pluginVersion, 9);

    RestrictionsDefinition restrictionsDefinition = null;
    if (numParams >= 4)
        restrictionsDefinition = GetNativeCell(4);

    int robotCoinsOnDeath = 1;
    if (numParams >= 5)
        robotCoinsOnDeath = GetNativeCell(5);

    //aSMLOGTag(SML_VERBOSE, "adding robot %s from plugin-handle %x", robotDefinition.name, plugin);

    char simpleName[NAMELENGTH];
    simpleName = robotDefinition.name;
    ReplaceString(simpleName, NAMELENGTH, " ", "");

    char versionConVarName[NAMELENGTH+10];
    Format(versionConVarName, NAMELENGTH+10, "be%s_version", simpleName);

    char versionConVarDescription[128];
    Format(versionConVarDescription, 128, "[TF2] Be the Giant %s %s version", robotDefinition.name, robotDefinition.class);
    CreateConVar(versionConVarName, pluginVersion, versionConVarDescription, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY);

    Robot robot;
    robot.name = robotDefinition.name;
    robot.role = robotDefinition.role;
    robot.class = robotDefinition.class;
    robot.shortDescription = robotDefinition.shortDescription;
    robot.sounds = robotDefinition.sounds;

    PrivateForward privateForward = new PrivateForward(ET_Single, Param_Cell);
    privateForward.AddFunction(plugin, callback);
    robot.callback = privateForward;

    robot.restrictions = new Restrictions();
    robot.restrictions.From(restrictionsDefinition, robot.name);

    robot.robotCoinsOnDeath = robotCoinsOnDeath;

    //aSMLOGTag(SML_VERBOSE, "robot %s uses privateForward %x", robot.name, privateForward);
    //aSMLOGTag(SML_VERBOSE, "robot %s is class %s", robot.name, robot.class);
    //aSMLOGTag(SML_VERBOSE, "robot %s has sounds {spawn: %s; loop: %s; death: %s }", robot.name, robot.sounds.spawn, robot.sounds.loop, robot.sounds.death);
    //aSMLOGTag(SML_VERBOSE, "robot %s has timeleft-restrictions {Active: %b; SecondsBeforeEndOfRound: %i }", robot.name, robot.restrictions.TimeLeft.Active, robot.restrictions.TimeLeft.SecondsBeforeEndOfRound);

    _robots.SetArray(robot.name, robot, sizeof(robot));
    OnRobotStorageChanged();
}

public any Native_RemoveRobot(Handle plugin, int numParams)
{ 
    Init();

    char name[NAMELENGTH];
    GetNativeString(1, name, NAMELENGTH);

    if (!_robots.Remove(name))
    {
        //aSMLOGTag(SML_VERBOSE, "could not remove robot. no robot with name '%s' found", name);
        return 1;
    }

    OnRobotStorageChanged();
    return 0;
}

public any Native_GetRobotNames(Handle plugin, int numParams)
{
	Init();
	
	ArrayList names = new ArrayList(NAMELENGTH);

	StringMapSnapshot snapshot = _robots.Snapshot();
	for(int i = 0; i < snapshot.Length; i++)
	{
		char name[NAMELENGTH];
		snapshot.GetKey(i, name, NAMELENGTH);

		names.PushString(name);
	}

	return names;
}

public any Native_GetRobotClass(Handle plugin, int numParams)
{
	Init();
	
	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);
	
	Robot item;
	if (!_robots.GetArray(name, item, sizeof(item)))
	{
		//aSMLOGTag(SML_ERROR, "could not retrieve class. no robot with name '%s' found", name);
		return 1;
	}

	SetNativeString(2, item.class, 10, false);
	return 0;
}

public any Native_GetRobotDefinition(Handle plugin, int numParams)
{
	Init();
	
	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);
	
	Robot item;
	if (!_robots.GetArray(name, item, sizeof(item)))
	{
		//aSMLOGTag(SML_ERROR, "could not retrieve class. no robot with name '%s' found", name);
		return 1;
	}

	SetNativeArray(2, item, sizeof(item));
	return 0;
}

public any Native_GetRobotRestrictions(Handle plugin, int numParams)
{
    ArrayList restrictions = new ArrayList();

    StringMapSnapshot snapshot = _robots.Snapshot();
    for(int i = 0; i < snapshot.Length; i++)
    {
        char name[NAMELENGTH];
        snapshot.GetKey(i, name, NAMELENGTH);

        Robot item;
        _robots.GetArray(name, item, sizeof(item));
        
        restrictions.Push(item.restrictions);
    }

    return restrictions;
}