#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
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
	name = "berobot_factory",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};


bool _init;
char _isRobot[MAXPLAYERS + 1][NAMELENGTH];

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
	SMLogTag(SML_INFO, "berobot_factory started at %i", GetTime());

	HookEvent("player_spawn", Event_Player_Spawned, EventHookMode_Post);

	for(int i = 0; i <= MaxClients; i++)
	{
		_isRobot[i] = "";
	}
    
	_init = true;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CreateRobot", Native_CreateRobot);

	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
    Reset(client);
}

public void OnClientDisconnect_Post(int client)
{
    Reset(client);
}

public void Event_Player_Spawned(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (_isRobot[client][0] != '\0') 
        CreateTimer(1.0, Timer_Locker, client);
}

public Action Timer_Locker(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    Robot item;
    if (GetRobotDefinition(_isRobot[client], item) != 0)
    {
        SMLogTag(SML_ERROR, "could not create robot. no robot with name '%s' found", _isRobot[client]);
        return Plugin_Handled;
    }
    
    if (item.sounds.loop[0] != '\0')
        StopSound(client, SNDCHAN_AUTO, item.sounds.loop);    
    if (item.sounds.gunfire[0] != '\0')
        StopSound(client, SNDCHAN_AUTO, item.sounds.gunfire);
    if (item.sounds.gunspin[0] != '\0')
        StopSound(client, SNDCHAN_AUTO, item.sounds.gunspin);
    if (item.sounds.windup[0] != '\0')
        StopSound(client, SNDCHAN_AUTO, item.sounds.windup);
    if (item.sounds.winddown[0] != '\0')
        StopSound(client, SNDCHAN_AUTO, item.sounds.winddown);

    CallCreate(client, item.callback);
    return Plugin_Handled;
}

public void Reset(int client)
{
    _isRobot[client] = "";
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

	Robot item;
	if (GetRobotDefinition(name, item) != 0)
	{
		SMLogTag(SML_ERROR, "could not create robot. no robot with name '%s' found", name);
		return 1;
	}

	bool robotWasCreated = false;
	for (int i = 0; i < target_count; i++)
	{
        int targetClientId = target_list[i];
        SMLogTag(SML_VERBOSE, "%i. target: %i", i, targetClientId);
        if (_isRobot[targetClientId][0] == '\0')
        {
            _isRobot[targetClientId] = name;

            SMLogTag(SML_VERBOSE, "calling privateForward %x for robot %s, with client %i and target %s (current %i; count %i)", item.callback, name, client, target, targetClientId, target_count);
            CallCreate(targetClientId, item.callback);

            robotWasCreated = true;
        }
        else
        {
            Reset(target_list[i]);
            PrintToChat(target_list[i], "1. You are no longer %s!", name);
            PrintToChat(target_list[i], "2. You will turn back by changing class or dying!");
            TF2_RegeneratePlayer(target_list[i]);
        }
    }
	if (robotWasCreated)
	{
		SMLogTag(SML_VERBOSE, "playing robot spawn sound %s to all for call by client %i for target %s", item.sounds.spawn, client, target);
		EmitSoundToAll(item.sounds.spawn);
	}

	return 0;
}

void CallCreate(int client, PrivateForward callback)
{
    Call_StartForward(callback);
    Call_PushCell(client);

    Call_Finish();
}