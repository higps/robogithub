#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
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

char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
}

char ROBOT_KEY_NAME[] = "name";
char ROBOT_KEY_CLASS[] = "class";
char ROBOT_KEY_CALLBACK[] = "callback";
char ROBOT_KEY_SOUNDS[] = "sounds";
char ROBOT_KEY_SOUNDS_SPAWN[] = "spawn";
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
	CreateNative("CreateRobot", Native_CreateRobot);

	return APLRes_Success;
}

public Action Command_DumpRobotStorage(int client, int numParams)
{
	StringMapSnapshot snapshot = _robots.Snapshot();
	for(int i = 0; i < snapshot.Length; i++)
	{
		char name[NAMELENGTH];
		snapshot.GetKey(i, name, NAMELENGTH);

		StringMap item;
		_robots.GetValue(name, item);		
		
		char class[9];
		item.GetString(ROBOT_KEY_CLASS, class, 9);
		PrivateForward privateForward;
		item.GetValue(ROBOT_KEY_CALLBACK, privateForward);

		SMLogTag(SML_INFO, "Robot {%s: %s, callback: %x}", name, class, privateForward);
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

	char soundSpawn[PLATFORM_MAX_PATH];
	GetNativeString(5, soundSpawn, PLATFORM_MAX_PATH);

	SMLogTag(SML_VERBOSE, "adding robot %s from plugin-handle %x", name, plugin);

	char simpleName[NAMELENGTH];
	simpleName = name;
	ReplaceString(simpleName, NAMELENGTH, " ", "");
	
	char versionConVarName[NAMELENGTH+10];
	Format(versionConVarName, NAMELENGTH+10, "be%s_version", simpleName);
	
	char versionConVarDescription[128];
	Format(versionConVarDescription, 128, "[TF2] Be the Giant %s %s version", name, class);
	CreateConVar(versionConVarName, pluginVersion, versionConVarDescription, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY);

	PrivateForward privateForward = new PrivateForward(ET_Ignore, Param_Cell, Param_String);
	privateForward.AddFunction(plugin, callback);

	SMLogTag(SML_VERBOSE, "robot %s uses privateForward %x", name, privateForward);
	SMLogTag(SML_VERBOSE, "robot %s is class %s", name, class);

	StringMap item = new StringMap();
	item.SetString(ROBOT_KEY_NAME, name);
	item.SetString(ROBOT_KEY_CLASS, class);
	item.SetValue(ROBOT_KEY_CALLBACK, privateForward);

	StringMap sounds = new StringMap();
	sounds.SetString(ROBOT_KEY_SOUNDS_SPAWN, soundSpawn);
	item.SetValue(ROBOT_KEY_SOUNDS, sounds);

	_robots.SetValue(name, item);
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

	char class[9];
	
	StringMap item;
	if (!_robots.GetValue(name, item))
	{
		SMLogTag(SML_ERROR, "could not retrieve class. no robot with name '%s' found", name);
		return 1;
	}

	item.GetString(ROBOT_KEY_CLASS, class, 9);
	SetNativeString(2, class, 10, false);
	return 0;
}

public any Native_CreateRobot(Handle plugin, int numParams)
{
	Init();
	
	char name[NAMELENGTH];
	GetNativeString(1, name, NAMELENGTH);
	int client = GetNativeCell(2);
	char target[32];
	GetNativeString(3, target, 32);
    
	int targetFilter = 0;
	if (target[0] == '\0')
	{
		target = "@me";
		targetFilter = COMMAND_FILTER_NO_IMMUNITY;
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|targetFilter,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return 2;
	}

	StringMap item;
	if (!_robots.GetValue(name, item))
	{
		SMLogTag(SML_ERROR, "could not create robot. no robot with name '%s' found", name);
		return 1;
	}

	PrivateForward privateForward;
	item.GetValue(ROBOT_KEY_CALLBACK, privateForward);

	bool robotWasCreated = false;
	for (int i = 0; i < target_count; i++)
	{
        int targetClientId = target_list[i];
        SMLogTag(SML_VERBOSE, "calling privateForward %x for robot %s, with client %i and target %s (current %i; count %i)", privateForward, name, client, target, targetClientId, target_count);
        Call_StartForward(privateForward);
        Call_PushCell(targetClientId);

        bool wasCreated;
        Call_Finish(wasCreated);

        if (wasCreated)
            robotWasCreated = true;
    }
	if (robotWasCreated)
	{
		StringMap sounds;
		item.GetValue(ROBOT_KEY_SOUNDS, sounds);
		char spawnPath[PLATFORM_MAX_PATH];
		sounds.GetString(ROBOT_KEY_SOUNDS_SPAWN, spawnPath, PLATFORM_MAX_PATH);

		SMLogTag(SML_VERBOSE, "playing robot spawn sound %s to all for call by client %i for target %s", spawnPath, client, target);
		EmitSoundToAll(spawnPath);
	}

	return 0;
}