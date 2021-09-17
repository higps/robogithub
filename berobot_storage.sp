#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "berobot_storage",
	author = "icebear",
	description = "",
	version = "1.0",
	url = "https://github.com/eisbaer66/robogithub"
};

char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
}

char ROBOT_KEY_NAME[] = "name";
char ROBOT_KEY_CALLBACK[] = "callback";
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
	// SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_VERBOSE|SML_INFO|SML_ERROR, SML_ALL);
	SMLogTag(SML_INFO, "berobot_store started at %i", GetTime());
	
	_robots = new StringMap();
	_init = true;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AddRobot", Native_AddRobot);
	CreateNative("RemoveRobot", Native_RemoveRobot);
	CreateNative("GetRobotNames", Native_GetRobotNames);
	CreateNative("CreateRobot", Native_CreateRobot);

	return APLRes_Success;
}

public any Native_AddRobot(Handle plugin, int numParams)
{ 
	Init();

	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);

	Function callback = GetNativeFunction(2);

	SMLogTag(SML_VERBOSE, "adding robot %s from plugin-handle %x", name, plugin);

	PrivateForward privateForward = new PrivateForward(ET_Ignore, Param_Cell, Param_String);
	privateForward.AddFunction(plugin, callback);

	SMLogTag(SML_VERBOSE, "robot %s uses privateForward %x", name, privateForward);

	StringMap item = new StringMap();
	item.SetString(ROBOT_KEY_NAME, name);
	item.SetValue(ROBOT_KEY_CALLBACK, privateForward);
	_robots.SetValue(name, item);
}

public any Native_RemoveRobot(Handle plugin, int numParams)
{ 
	Init();
	
	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);

	_robots.Remove(name);
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

public any Native_CreateRobot(Handle plugin, int numParams)
{
	Init();
	
	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);
	int client = GetNativeCell(2);
	char target[32];
	GetNativeString(3, target, 32);

	StringMap item;
	_robots.GetValue(name, item);

	PrivateForward privateForward;
	item.GetValue(ROBOT_KEY_CALLBACK, privateForward);

	SMLogTag(SML_VERBOSE, "calling privateForward %x for robot %s, with client %i and target %s", privateForward, name, client, target);
	Call_StartForward(privateForward);
	Call_PushCell(client);
	Call_PushString(target);
	Call_Finish();

	return 0;
}