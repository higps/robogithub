#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors_newsyntax>
#include <sm_logger>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <berobot_constants>

char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
}
#include <berobot>
#include <berobot_core>
#include <berobot_core_restrictions>
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
bool _robotIsCreated[MAXPLAYERS + 1];
char _wasRobot[MAXPLAYERS + 1][NAMELENGTH];

public void OnPluginStart()
{
    Init();
}

public void Init()
{
    if (_init)
        return;

    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_factory started at %i", GetTime());

    HookEvent("player_death", Event_Death, EventHookMode_Post);
    HookEvent("player_spawn", Event_Player_Spawned, EventHookMode_Post);

    for(int i = 0; i <= MaxClients; i++)
    {
        _isRobot[i] = "";
        _wasRobot[i] = "";
        _robotIsCreated[i] = false;
    }

    _init = true;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CreateRobot", Native_CreateRobot);
	CreateNative("IsRobot", Native_IsRobot);
	CreateNative("IsAnyRobot", Native_IsAnyRobot);

	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
    FullReset(client);
}

public void OnClientDisconnect_Post(int client)
{
    FullReset(client);
}

public void Event_Player_Spawned(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client))
        return;

    _robotIsCreated[client] = false;

    bool isAlive = IsPlayerAlive(client);
    char robotName[NAMELENGTH];
    robotName = _isRobot[client];
    SMLogTag(SML_VERBOSE, "Event_Player_Spawned for %L (alive: %b) received with robot-name %s", client, isAlive, robotName);

    ResetPreviousRobot(client);
    if (robotName[0] == '\0') 
    {
        return;
    }
        
    Robot item;
    if (GetRobotDefinition(robotName, item) != 0)
    {
        SMLogTag(SML_ERROR, "could not stop sounds. no robot with name '%s' found for %L", robotName, client);
        return;
    }

    StopSounds(client, item);   //moved here, because doing it inside Timer_Locker blocked the loop to start again (don't ask me why)
    CreateTimer(0.1, Timer_Locker, client);
}

public void ResetPreviousRobot(int client)
{
    if (_wasRobot[client][0] == '\0')
    {
        return;
    }
    SMLogTag(SML_VERBOSE, "resetting robot for %L (was %s)", client, _wasRobot[client]);
    Robot item;
    if (GetRobotDefinition(_wasRobot[client], item) != 0)
    {
        SMLogTag(SML_ERROR, "could not stop sounds. no robot with name '%s' found for %L", _wasRobot[client], client);
        return;
    }
    
    StopSounds(client, item);
    _wasRobot[client] = "";
}

public Action Timer_Locker(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    char robotName[NAMELENGTH];
    robotName = _isRobot[client];
    SMLogTag(SML_VERBOSE, "Event_Player_Spawned for %L received with robot-name %s", client, robotName);

    Robot item;
    if (GetRobotDefinition(robotName, item) != 0)
    {
        SMLogTag(SML_ERROR, "could not stop sounds. no robot with name '%s' found for %L", robotName, client);
        return Plugin_Handled;
    }

    CallCreate(client, item);
    return Plugin_Handled;
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathflags = GetEventInt(event, "death_flags");
	SMLogTag(SML_VERBOSE, "Event_Death for %L received with name %s, dontBroadcast %b and deathflags %i", client, name, dontBroadcast, deathflags);

	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
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

        ResetOnDeath(client, item);
	}
}

void ResetOnDeath(int client, Robot item)
{
    StopSounds(client, item);
    
    TF2Attrib_RemoveAll(client);
    EmitSoundToAll(item.sounds.death);
    _robotIsCreated[client] = false;    
}

void StopSounds(int client, Robot item)
{    
    SMLogTag(SML_VERBOSE, "stopping sounds for %L as %s", client, item.name);

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
}

public void FullReset(int client)
{
    if (IsValidClient(client))
    {
        Robot item;
        if (GetRobotDefinition(_isRobot[client], item) != 0)
        {
            SMLogTag(SML_ERROR, "could not stop sounds. no robot with name '%s' found for %L", _isRobot[client], client);
            return;
        }
        else
            StopSounds(client, item);
    }
        
    Reset(client);
}

public void Reset(int client)
{
    _isRobot[client] = "";
    _robotIsCreated[client] = false;
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
			targetFilter,
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
        char wasRobot[NAMELENGTH];
        wasRobot = _isRobot[targetClientId];
        SMLogTag(SML_VERBOSE, "%i. target: %i is currently %s", i, targetClientId, wasRobot);

        bool paid = PayRobotCoin(item.restrictions, targetClientId);
        if (!paid)
        {
            char msg[256];
            Format(msg, 256, "could not pay for robot %s, please try again.", name);
            MM_PrintToChat(targetClientId, msg);

            SMLogTag(SML_ERROR, "could not create robot '%s'. could not pay robot-coins", name);
            return 3;
        }

        if (wasRobot[0] != '\0')            //disable previous robot
        {
            if (_wasRobot[targetClientId][0] == '\0')
                _wasRobot[targetClientId] = wasRobot;

            //notify robots of change
            for(int otherRobotClientIndex = 0; otherRobotClientIndex <= MaxClients; otherRobotClientIndex++)
            {
                if (!IsValidClient(otherRobotClientIndex))
                    continue;
                if (_isRobot[otherRobotClientIndex][0] == '\0')
                    continue;
                
                SMLogTag(SML_VERBOSE, "notifying %L, about %L switch from '%s' to '%s'", otherRobotClientIndex, targetClientId, wasRobot, name);
                MC_PrintToChatEx(otherRobotClientIndex, otherRobotClientIndex, "{teamcolor}%N switching from '%s' to '%s'", targetClientId, wasRobot, name);
            }

            Reset(targetClientId);
            PrintToChat(targetClientId, "1. You are no longer %s!", wasRobot);
            PrintToChat(targetClientId, "2. You will turn back by changing class or dying!");
            
            if (!TF2Spawn_IsClientInSpawn(targetClientId))
            {
                SMLogTag(SML_VERBOSE, "forcing suicide on %L to become robot '%s'", targetClientId, name);
                ForcePlayerSuicide(targetClientId);


                Robot oldRobot;
                if (GetRobotDefinition(wasRobot, oldRobot) != 0)
                {
                    SMLogTag(SML_ERROR, "could not create robot. no robot with name '%s' found", wasRobot);
                    return 1;
                }

                ResetOnDeath(client, oldRobot);
                _isRobot[targetClientId] = name;
                return 0;
            }
            else
                TF2_RespawnPlayer(targetClientId);
        }

        if (strcmp(name, wasRobot) == 0)    //don't enable robot, if client was already same robot as requested
            continue;

        _isRobot[targetClientId] = name;

        SMLogTag(SML_VERBOSE, "calling privateForward %x for robot %s, with client %i and target %s (current %i; count %i)", item.callback, name, client, target, targetClientId, target_count);
        CallCreate(targetClientId, item);

        robotWasCreated = true;
    }
	if (robotWasCreated)
	{
		SMLogTag(SML_VERBOSE, "playing robot spawn sound %s to all for call by client %i for target %s", item.sounds.spawn, client, target);
		EmitSoundToAll(item.sounds.spawn);
	}

	return 0;
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

public any Native_IsAnyRobot(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return _isRobot[client][0] != '\0';
}

void CallCreate(int client, Robot item)
{
    Call_StartForward(item.callback);
    Call_PushCell(client);

    Call_Finish();
    
    SMLogTag(SML_VERBOSE, "starting loop-sound %s for %L as %s", item.sounds.loop, client, item.name);
    EmitSoundToAll(item.sounds.loop, client);

    _isRobot[client] = item.name;
    _robotIsCreated[client] = true;
}