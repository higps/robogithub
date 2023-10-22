#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
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
int g_Allow_Human_Robot_Creation;
enum //Convar names
{
    CV_g_Allow_Human_Robot_Creation
}

ConVar g_cvCvarList[CV_g_Allow_Human_Robot_Creation + 1];

bool _init;
char _wasRobot[MAXPLAYERS + 1][NAMELENGTH];

//Universal
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define BOSS_SPAWN   "mvm/ambient_mp3/mvm_siren.mp3"
#define TANK_SPAWN	"mvm/mvm_tank_horn.wav"
#define TANK_LOOP	"mvm/mvm_tank_loop.wav"
#define ROBOSTEP1 "^mvm/giant_common/giant_common_step_01.wav"
#define ROBOSTEP2 "^mvm/giant_common/giant_common_step_02.wav"
#define ROBOSTEP3 "^mvm/giant_common/giant_common_step_03.wav"
#define ROBOSTEP4 "^mvm/giant_common/giant_common_step_04.wav"
#define ROBOSTEP5 "^mvm/giant_common/giant_common_step_05.wav"
#define ROBOSTEP6 "^mvm/giant_common/giant_common_step_06.wav"
#define ROBOSTEP7 "^mvm/giant_common/giant_common_step_07.wav"
#define ROBOSTEP8 "^mvm/giant_common/giant_common_step_08.wav"


//SentryBuster
#define SENTRYBUSTER		"models/bots/demo/bot_sentry_buster.mdl"
#define SENTRYBUSTERSPAWN	"#mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define SENTRYBUSTERLOOP	"mvm/sentrybuster/mvm_sentrybuster_loop.wav"
#define SENTRYBUSTER_LEFTFOOT "^mvm/sentrybuster/mvm_sentrybuster_step_01.wav"
#define SENTRYBUSTER_LEFTFOOT1 "^mvm/sentrybuster/mvm_sentrybuster_step_02.wav"
#define SENTRYBUSTER_RIGHTFOOT "^mvm/sentrybuster/mvm_sentrybuster_step_03.wav"
#define SENTRYBUSTER_RIGHTFOOT1 "^mvm/sentrybuster/mvm_sentrybuster_step_04.wav"
#define SENTRYBUSTER_SPIN "mvm/sentrybuster/mvm_sentrybuster_spin.wav"

//Demo
#define DEMO		"models/bots/demo/bot_demo.mdl"
#define DEMO_BOSS		"models/bots/demo_boss/bot_demo_boss.mdl"
#define LOOP_DEMO	"mvm/giant_demoman/giant_demoman_loop.wav"
#define DEMO_LEFTFOOT        ")mvm/giant_demoman/giant_demoman_step_01.wav"
#define DEMO_LEFTFOOT1       ")mvm/giant_demoman/giant_demoman_step_03.wav"
#define DEMO_RIGHTFOOT       ")mvm/giant_demoman/giant_demoman_step_02.wav"
#define DEMO_RIGHTFOOT1      ")mvm/giant_demoman/giant_demoman_step_04.wav"

//Heavy
#define HEAVY      "models/bots/heavy/bot_heavy.mdl"
#define HEAVY_BOSS      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define HEAVY_LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"
#define HEAVY_LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define HEAVY_LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define HEAVY_RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define HEAVY_RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

//Soldier
#define SOLDIER		"models/bots/soldier/bot_soldier.mdl"
#define SOLDIER_BOSS		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SOLDIER_DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define SOLDIER_LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define SOLDIER_LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define SOLDIER_LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define SOLDIER_RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define SOLDIER_RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

//Scout
#define SCOUT		"models/bots/scout_boss/bot_scout_boss.mdl"
#define SCOUT_LOOP	"mvm/giant_scout/giant_scout_loop.wav"
#define SCOUT_LEFTFOOT        ")mvm/giant_scout/giant_scout_step_01.wav"
#define SCOUT_LEFTFOOT1       ")mvm/giant_scout/giant_scout_step_03.wav"
#define SCOUT_RIGHTFOOT       ")mvm/giant_scout/giant_scout_step_02.wav"
#define SCOUT_RIGHTFOOT1      ")mvm/giant_scout/giant_scout_step_04.wav"

//Pyro
#define PYRO		"models/bots/pyro/bot_pyro.mdl"
#define PYRO_BOSS	"models/bots/pyro_boss/bot_pyro_boss.mdl"
#define PYRO_LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

//Sniper
#define SNIPER             "models/bots/Sniper/bot_Sniper.mdl"

//Engineer
#define ENGINEER    "models/bots/engineer/bot_engineer.mdl"

//Medic
#define MEDIC             "models/bots/medic/bot_medic.mdl"

// SPY
#define SPY             "models/bots/spy/bot_spy.mdl"

// #define Models {SNIPER}
// #define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
// #define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"







public void OnPluginStart()
{
    Init();
   
}

public void OnMapStart()
{
     PrecacheModelsAndSounds();
}

public void Init()
{
    if (_init)
        return;

    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_factory started at %i", GetTime());

    RegAdminCmd("sm_trashrobot", Command_TrashRobot, ADMFLAG_SLAY, "Trash a robot");
    RegAdminCmd("sm_trshrbt", Command_TrashRobot, ADMFLAG_SLAY, "Trash a robot");
    RegAdminCmd("sm_tr", Command_TrashRobot, ADMFLAG_SLAY, "Trash a robot");

    g_cvCvarList[CV_g_Allow_Human_Robot_Creation] = CreateConVar("sm_allow_robots_on_human_team", "0", "0 = blocks humans from ever being robots 1 = allows humans to be robots");
    
    g_Allow_Human_Robot_Creation = GetConVarInt(g_cvCvarList[CV_g_Allow_Human_Robot_Creation]);
    g_cvCvarList[CV_g_Allow_Human_Robot_Creation].AddChangeHook(CvarChangeHook);

    HookEvent("player_death", Event_Death, EventHookMode_Pre);
    HookEvent("player_spawn", Event_Player_Spawned, EventHookMode_Post);

    for(int i = 0; i <= MaxClients; i++)
    {
        _wasRobot[i] = "";
    }

    _init = true;
}
static const char ROBOT_SOUNDS[][256] =
{
SPAWN, DEATH, BOSS_SPAWN,TANK_SPAWN, TANK_LOOP, LOOP_DEMO, DEMO_LEFTFOOT, DEMO_LEFTFOOT1, DEMO_RIGHTFOOT, DEMO_RIGHTFOOT1, HEAVY_LOOP
,HEAVY_LEFTFOOT,HEAVY_LEFTFOOT1, HEAVY_RIGHTFOOT, HEAVY_RIGHTFOOT1, SOLDIER_DEATH, SOLDIER_LOOP, SOLDIER_LEFTFOOT, SOLDIER_LEFTFOOT1
,SOLDIER_RIGHTFOOT1, SOLDIER_RIGHTFOOT, SCOUT_LOOP, SCOUT_LEFTFOOT, SCOUT_LEFTFOOT1,SCOUT_RIGHTFOOT,SCOUT_RIGHTFOOT1,PYRO_LOOP,SENTRYBUSTER, SENTRYBUSTERSPAWN, SENTRYBUSTERLOOP,
ROBOSTEP1, ROBOSTEP2,ROBOSTEP3,ROBOSTEP4,ROBOSTEP5,ROBOSTEP6,ROBOSTEP7,ROBOSTEP8
};

static const char ROBOT_MODELS[][256]= 
{
DEMO, DEMO_BOSS, HEAVY, HEAVY_BOSS, SOLDIER, SOLDIER_BOSS, SCOUT, PYRO, PYRO_BOSS, SNIPER, MEDIC, SPY
};

public void PrecacheModelsAndSounds()
{

    int size = sizeof ROBOT_SOUNDS;
	for (int i = 0; i < size; i++)
		PrecacheSound(ROBOT_SOUNDS[i], true);


   size = sizeof ROBOT_MODELS;
	for (int i = 0; i < size; i++)
		PrecacheSound(ROBOT_MODELS[i], true);
    // for (int i = 0; i < sizeof(Sounds); i++)
    // {
    //     PrecacheSound(Sounds[i]);
    //     PrintToConsoleAll("Precached %s", Sounds[i]);
    // }
    // for (int i = 0; i < sizeof(Models); i++)
    // {
    //     PrecacheModel(Models[i]);
    //     // PrintToConsoleAll("Precached Models %s", Models[i]);
    // }
}

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_g_Allow_Human_Robot_Creation])
        g_Allow_Human_Robot_Creation = StringToInt(sNewValue); 
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("CreateRobot", Native_CreateRobot);
    CreateNative("TrashRobot", Native_TrashRobot);
    CreateNative("IsTank", Native_IsTank);
    CreateNative("IsSentryBuster", Native_IsSentryBuster);
    CreateNative("RoboSetHealth", Native_RoboSetHealth);

    // CreateNative("SetTankStats", Native_SetTankStats);

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

    TrackRobotCreation(client, false);

    // if (IsTank(client))
    //     {
    //         SetTankStats(client);
    //     }
    bool isAlive = IsPlayerAlive(client);
    char robotName[NAMELENGTH];
    GetRobot(client, robotName, NAMELENGTH);
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

float f_SpawnSoundClamp[MAXPLAYERS + 1] = {0.0, ...};

public Action Timer_Locker(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    char robotName[NAMELENGTH];
    GetRobot(client, robotName, NAMELENGTH);
    SMLogTag(SML_VERBOSE, "Event_Player_Spawned for %L received with robot-name %s", client, robotName);


    // if (IsTank(client))
    //     {
    //         SetTankStats(client);
    //     }

    Robot item;
    if (GetRobotDefinition(robotName, item) != 0)
    {
        SMLogTag(SML_ERROR, "could not stop sounds. no robot with name '%s' found for %L", robotName, client);
        return Plugin_Handled;
    }



    // if (IsPlayerAlive(client) && f_SpawnSoundClamp[client] < GetEngineTime())
    // { 
    //     EmitSoundToAll(item.sounds.spawn);
    //     f_SpawnSoundClamp[client] = GetEngineTime() + 15.0;
    // }

    CallCreate(client, item);

    return Plugin_Handled;
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int deathflags = GetEventInt(event, "death_flags");

        // PrintToChatAll("Factory Pre Class was: %i,", TF2_GetPlayerClass(client));

    	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
        if(!IsValidClient(client))
        {
            SMLogTag(SML_VERBOSE, "skipped Event_Death, because %i is not a valid client", client);
            return;
        }
        char robotName[NAMELENGTH];
        GetRobot(client, robotName, NAMELENGTH);
        if(robotName[0] == '\0')
        {
            SMLogTag(SML_VERBOSE, "skipped Event_Death, because %L is no robot", client);
            return;
        }

        Robot item;
        if (GetRobotDefinition(robotName, item) != 0)
        {
            SMLogTag(SML_ERROR, "skipped Event_Death, because no robot with name '%s' found for %L", robotName, client);
            return;
        }

        ResetOnDeath(client, item);
        // CreateTimer(0.5,ResetOnDeath_Timer, info);
	}

}

// public Action ResetOnDeath_Timer(Handle Timer, int client)
// {

//     if(!IsValidClient(client))
//     {
//         SMLogTag(SML_VERBOSE, "skipped Event_Death, because %i is not a valid client", client);
//         return;
//     }
//     char robotName[NAMELENGTH];
//     GetRobot(client, robotName, NAMELENGTH);
//     if(robotName[0] == '\0')
//     {
//         SMLogTag(SML_VERBOSE, "skipped Event_Death, because %L is no robot", client);
//         return;
//     }

//     Robot item;
//     if (GetRobotDefinition(robotName, item) != 0)
//     {
//         SMLogTag(SML_ERROR, "skipped Event_Death, because no robot with name '%s' found for %L", robotName, client);
//         return;
//     }
//     ResetOnDeath(client, item);

// }

void ResetOnDeath(int client, Robot item)
{
    StopSounds(client, item);
    
    TF2Attrib_RemoveAll(client);
    // if (IsPlayerAlive(client)){
    //     EmitSoundToAll(item.sounds.death, client);
    // }
    TrackRobotCreation(client, false);
}

//Stops loops
void StopSounds(int client, Robot item)
{    
    SMLogTag(SML_VERBOSE, "stopping sounds for %L as %s", client, item.name);

    if (item.sounds.loop[0] != '\0')
        StopSound(client, 134, item.sounds.loop);    
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
        char robotName[NAMELENGTH];
        GetRobot(client, robotName, NAMELENGTH);
        Robot item;
        if (GetRobotDefinition(robotName, item) != 0)
        {
            SMLogTag(SML_ERROR, "could not stop sounds. no robot with name '%s' found for %L", robotName, client);
            return;
        }
        else
            StopSounds(client, item);
    }
        
    Reset(client);
}

public void Reset(int client)
{
    TrackRobot(client, "");
    TrackRobotCreation(client, false);
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

        bool paid = PayRobotCoin(item.restrictions, targetClientId);
        if (!paid)
        {
            char msg[256];
            Format(msg, 256, "could not pay for robot %s, please try again when you have enough coins.", name);
            MM_PrintToChat(targetClientId, msg);

            SMLogTag(SML_ERROR, "could not create robot '%s'. could not pay robot-coins", name);
            return 3;
        }

        
        //Check to disallow becoming a robot even with commands if you are not on the robot team
        if (GetClientTeam(targetClientId) != GetRobotTeam() && g_Allow_Human_Robot_Creation == 0)
        {
            
            SMLogTag(SML_ERROR, "unable to create robot, you are not on the robot team");
            return 4;
        }
        
        
        char wasRobot[NAMELENGTH];
        int trashError = Trash(targetClientId, wasRobot, name);
        if (trashError > 0)
            return trashError;            

        if (strcmp(name, wasRobot) == 0)    //don't enable robot, if client was already same robot as requested
            continue;

        TrackRobot(targetClientId, name);

        SMLogTag(SML_VERBOSE, "calling privateForward %x for robot %s, with client %i and target %s (current %i; count %i)", item.callback, name, client, target, targetClientId, target_count);
        CallCreate(targetClientId, item);

        robotWasCreated = true;
    }
	if (robotWasCreated)
	{
		SMLogTag(SML_VERBOSE, "playing robot spawn sound %s to all for call by client %i for target %s", item.sounds.spawn, client, target);

        if (IsPlayerAlive(client) && TF2Spawn_IsClientInSpawn(client))
        { 
            // PrintToChatAll("PLAYER %N WAS ALIVE", client);
            EmitSoundToAll(item.sounds.spawn);
            
            // EmitGameSoundToAll(item.sounds.spawn);
            

        }

	}



	return 0;
}

public Action Command_TrashRobot(int client, int numParams)
{
    char target[32];
    if (numParams < 1)
        target[0] = '\0';
    else 
        GetCmdArg(1, target, sizeof(target));

    TrashTargetedRobot(client, target);
    
    return Plugin_Handled;
}

public any Native_TrashRobot(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    char target[32] = "";
    if (numParams >= 2)
        GetNativeString(2, target, 32);

    return TrashTargetedRobot(client, target);
}

public any Native_IsTank(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char robotName[NAMELENGTH];

    Robot robot;
    GetRobot(client, robotName, NAMELENGTH);
    GetRobotDefinition(robotName, robot);


    if (StrEqual(robot.role,"Tank"))
    {
     //  PrintToChatAll("Robot role from factory: %s", robot.role);
        
        return true;
    }else
    {
        return false;
    }
}


public any Native_IsSentryBuster(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char robotName[NAMELENGTH];

    Robot robot;
    GetRobot(client, robotName, NAMELENGTH);
    GetRobotDefinition(robotName, robot);


    if (StrEqual(robot.role,"Sentry Buster"))
    {
     //  PrintToChatAll("Robot role from factory: %s", robot.role);
        
        return true;
    }else
    {
        return false;
    }
}

// void SetTankStats(int client)
// {
//     PrintToChatAll("Setting Tank Stats for %N", client);
//     TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.75);
//     TF2Attrib_SetByName(client, "increase player capture value", -1.0);
// TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
// 	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
// 	TF2_RemoveCondition(client,TFCond_DefenseBuffNoCritBlock);
//     CreateTimer(0.1, Timer_SetDefenseBuff, client);
// }

public any Native_RoboSetHealth(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	TFClassType iClass = GetNativeCell(2);
	int iHealth = GetNativeCell(3);
	float OverHealRate = GetNativeCell(4);
	int ClassHealth;

	switch (iClass) {
        case TFClass_Scout:
            ClassHealth = 125;
        case TFClass_Soldier:
            ClassHealth = 200;
        case TFClass_Pyro:
            ClassHealth = 175;
        case TFClass_DemoMan:
            ClassHealth = 175;
        case TFClass_Heavy:
            ClassHealth = 300;
        case TFClass_Engineer:
            ClassHealth = 125;
        case TFClass_Medic:
            ClassHealth = 150;
        case TFClass_Sniper:
            ClassHealth = 125;
        case TFClass_Spy:
            ClassHealth = 125;
        default:
            ClassHealth = 100; // Default health if class is not recognized
    }
	
    //Set New health before doing the rest
	SetEntProp(client, Prop_Send, "m_iHealth", iHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", iHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", iHealth, 1);

    //Calculate the overheal and health pickup penalty
	int iAdditiveHP = iHealth - ClassHealth;
	float OverHeal = float(ClassHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;
	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));

	float HealthPackPickUpRate =  float(ClassHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

}

// public Action Timer_SetDefenseBuff(Handle timer, any client)
// {
//     if(IsTank(client))
//     {
    //     TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.75);
//     TF2Attrib_SetByName(client, "increase player capture value", -1.0);
// TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
// 	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
//     TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);
//     }
//     return Plugin_Continue;
// }

int TrashTargetedRobot(int clientId, char target[32])
{
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
            clientId,
            target_list,
            MAXPLAYERS,
            targetFilter,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(clientId, target_count);
        return 1024;
    }

    int maxError = 0;
    for (int i = 0; i < target_count; i++)
    {
        int targetClientId = target_list[i];

        int trashError = Trash(targetClientId);
        if (trashError > maxError)
            maxError = trashError;
    }

    return maxError;
}

int Trash(int clientId, char wasRobot[NAMELENGTH] = "", char newRobotName[NAMELENGTH] = "")
{
    if (!IsValidClient(clientId) || !IsClientInGame(clientId))
        return 2;
    // PrintToChatAll("TRASHING %N", clientId);
    char robotName[NAMELENGTH];
    GetRobot(clientId, robotName, NAMELENGTH);
    strcopy(wasRobot, NAMELENGTH, robotName);
    if (wasRobot[0] == '\0')            //disable previous robot
        return 0;
    
    SMLogTag(SML_VERBOSE, "disableing old robot %s for %L", wasRobot, clientId);
    if (_wasRobot[clientId][0] == '\0')
        _wasRobot[clientId] = wasRobot;

    //notify robots of change
    for(int otherRobotClientIndex = 0; otherRobotClientIndex <= MaxClients; otherRobotClientIndex++)
    {
        if (!IsValidClient(otherRobotClientIndex))
            continue;
        char otherRobotName[NAMELENGTH];
        GetRobot(otherRobotClientIndex, otherRobotName, NAMELENGTH);
        if (otherRobotName[0] == '\0')
            continue;
        
        SMLogTag(SML_VERBOSE, "notifying %L, about %L switch from '%s' to '%s'", otherRobotClientIndex, clientId, wasRobot, newRobotName);
        if (newRobotName[0] == '\0')
            MC_PrintToChatEx(otherRobotClientIndex, otherRobotClientIndex, "{teamcolor}%N switching from '%s'", clientId, wasRobot);
        else
            MC_PrintToChatEx(otherRobotClientIndex, otherRobotClientIndex, "{teamcolor}%N switched from '%s' to '%s'", clientId, wasRobot, newRobotName);
    }

    Reset(clientId);
    PrintToChat(clientId, "1. You are no longer %s!", wasRobot);
    PrintToChat(clientId, "2. You will turn back by changing class or dying!");
    
    
    //This resets the model back to normal
    TFClassType iClass = TF2_GetPlayerClass(clientId);
    char model[32];
    
    switch(iClass)
    {
        case TFClass_Scout:
        {
            model = "models/player/scout.mdl";
        }
        case TFClass_Soldier:
        {
            model = "models/player/soldier.mdl";

        }
        case TFClass_Pyro:
        {
            model = "models/player/pyro.mdl";
        }
        case TFClass_DemoMan:
        {
            model = "models/player/demo.mdl";
        }
        case TFClass_Heavy:
        {
           model = "models/player/heavy.mdl";
        }
        case TFClass_Engineer:
        {
          model = "models/player/engineer.mdl";
        }
        case TFClass_Medic:
        {
           model = "models/player/medic.mdl";
        }
        case TFClass_Sniper:
        {
         model = "models/player/sniper.mdl";
        }
        case TFClass_Spy:
        {
           model = "models/player/spy.mdl";
        }

    }

    SetVariantString(model);
    AcceptEntityInput(clientId, "SetCustomModel");
    SetEntProp(clientId, Prop_Send, "m_bUseClassAnimations", 1);

    if (TF2Spawn_IsClientInSpawn(clientId))
    {
        
        TF2_RespawnPlayer(clientId);
        //TF2_SetPlayerClass(clientId, TFClass_Heavy);

        return 0;
    }

    SMLogTag(SML_VERBOSE, "forcing suicide on %L to become robot '%s'", clientId, newRobotName);
    ForcePlayerSuicide(clientId);

    Robot oldRobot;
    if (GetRobotDefinition(wasRobot, oldRobot) != 0)
    {
        SMLogTag(SML_ERROR, "could not create robot. no robot with name '%s' found", wasRobot);
        return 1;
    }

    ResetOnDeath(clientId, oldRobot);

    return 0;
}

void CallCreate(int client, Robot item)
{
    Call_StartForward(item.callback);
    Call_PushCell(client);

    Call_Finish();
    
    SMLogTag(SML_VERBOSE, "starting loop-sound %s for %L as %s", item.sounds.loop, client, item.name);

    if (IsPlayerAlive(client)){
        //SNDCHAN_REPLACE WAS OLD, but tank alert kills the sound
        EmitSoundToAll(item.sounds.loop, client, 134,_,_, 0.25);
    }
    TrackRobot(client, item.name);
    TrackRobotCreation(client, true);
    PrintHintText(client, item.tips);
}