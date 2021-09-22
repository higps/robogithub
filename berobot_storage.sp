#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <sm_logger>
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

public void OnPluginStart()
{
	Init();
}

public void Init()
{
	if (_init)
		return;

    //TODO: Release
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_VERBOSE|SML_INFO|SML_ERROR, SML_ALL);
    //SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
	SMLogTag(SML_INFO, "berobot_store started at %i", GetTime());

	_robots = new StringMap();
	_init = true;
	
	RegAdminCmd("sm_dumpRobotStorage", Command_DumpRobotStorage, ADMFLAG_ROOT, "Dumps the current Robot-Storage (for debugging)");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AddRobot", Native_AddRobot);
	CreateNative("RemoveRobot", Native_RemoveRobot);
	CreateNative("GetRobotNames", Native_GetRobotNames);
	CreateNative("GetRobotClass", Native_GetRobotClass);
	CreateNative("GetRobotDefinition", Native_GetRobotDefinition);

	return APLRes_Success;
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
		
		SMLogTag(SML_INFO, "Robot {%s: %s, callback: %x, sounds: {spawn: %s}}", item.name, item.class, item.callback, item.sounds.spawn);
	}
}

public any Native_AddRobot(Handle plugin, int numParams)
{ 
	Init();

	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);

	char class[9];
	GetNativeString(2, class, 9);

	Function callback = GetNativeFunction(3);

	char pluginVersion[9];
	GetNativeString(4, pluginVersion, 9);

	RobotSounds sounds;
	GetNativeArray(5, sounds, sizeof(sounds));

	SMLogTag(SML_VERBOSE, "adding robot %s from plugin-handle %x", name, plugin);

	char simpleName[NAMELENGTH];
	simpleName = name;
	ReplaceString(simpleName, NAMELENGTH, " ", "");
	
	char versionConVarName[NAMELENGTH+10];
	Format(versionConVarName, NAMELENGTH+10, "be%s_version", simpleName);
	
	char versionConVarDescription[128];
	Format(versionConVarDescription, 128, "[TF2] Be the Giant %s %s version", name, class);
	CreateConVar(versionConVarName, pluginVersion, versionConVarDescription, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY);

	PrivateForward privateForward = new PrivateForward(ET_Single, Param_Cell);
	privateForward.AddFunction(plugin, callback);

	SMLogTag(SML_VERBOSE, "robot %s uses privateForward %x", name, privateForward);
	SMLogTag(SML_VERBOSE, "robot %s is class %s", name, class);
	SMLogTag(SML_VERBOSE, "robot %s has sounds {spawn: %s; loop: %s", name, sounds.spawn, sounds.loop);

	Robot item;
	item.name = name;
	item.class = class;
	item.callback = privateForward;	
	item.sounds = sounds;

	_robots.SetArray(name, item, sizeof(item));
}

public any Native_RemoveRobot(Handle plugin, int numParams)
{ 
	Init();
	
	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);

	if (!_robots.Remove(name))
	{
		SMLogTag(SML_VERBOSE, "could not remove robot. no robot with name '%s' found", name);
		return 1;
	}

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
		SMLogTag(SML_ERROR, "could not retrieve class. no robot with name '%s' found", name);
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
		SMLogTag(SML_ERROR, "could not retrieve class. no robot with name '%s' found", name);
		return 1;
	}

	SetNativeArray(2, item, sizeof(item));
	return 0;
}